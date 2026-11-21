import SwiftUI
import Security

struct ChatMessage: Codable, Identifiable {
    var id: UUID = UUID()
    let role: String
    let content: String
    var isUser: Bool { role == "user" }
}

enum SecureKey {
    private static let account = "openrouter.api.key"
    private static let service = "app.log67.ai"
    static func load() -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }
    static func save(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        guard !key.isEmpty else { return }
        let values: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: Data(key.utf8)
        ]
        SecItemAdd(values as CFDictionary, nil)
    }
}

struct OpenRouterRequest: Encodable {
    let model: String
    let messages: [OpenRouterMessage]
    let max_tokens: Int
}
struct OpenRouterMessage: Codable {
    let role: String
    let content: String
}
struct OpenRouterResult: Decodable {
    struct Choice: Decodable {
        struct Reply: Decodable { let content: String? }
        let message: Reply
    }
    let choices: [Choice]
}
struct OpenRouterFailure: Decodable {
    struct Info: Decodable { let message: String }
    let error: Info?
}

@MainActor
final class ChatStore: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var busy = false
    @Published var errorText: String?
    @Published var hasKey = false
    init() {
        if let data = UserDefaults.standard.data(forKey: "LOG.history"),
           let restored = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            messages = restored
        }
        hasKey = !SecureKey.load().isEmpty
    }
    func saveHistory() {
        if let data = try? JSONEncoder().encode(Array(messages.suffix(100))) {
            UserDefaults.standard.set(data, forKey: "LOG.history")
        }
    }
    func clear() {
        messages.removeAll()
        errorText = nil
        saveHistory()
    }
    func saveKey(_ value: String) {
        SecureKey.save(value.trimmingCharacters(in: .whitespacesAndNewlines))
        hasKey = !SecureKey.load().isEmpty
    }
    func send(_ content: String) async {
        let text = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !busy, !text.isEmpty else { return }
        guard let key = Optional(SecureKey.load()), !key.isEmpty else {
            errorText = "Add your free OpenRouter key in Settings before chatting."
            return
        }
        messages.append(ChatMessage(role: "user", content: text))
        saveHistory()
        busy = true
        errorText = nil
        defer { busy = false }
        do {
            let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 60
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer " + key, forHTTPHeaderField: "Authorization")
            request.setValue("LOG AI iOS", forHTTPHeaderField: "X-Title")
            let context = Array(messages.suffix(24)).map {
                OpenRouterMessage(role: $0.role, content: $0.content)
            }
            let prompt = OpenRouterMessage(role: "system", content: "You are LOG AI, a friendly, playful, helpful assistant. Be accurate, natural, and concise. You are powered by a third-party free model selected by OpenRouter; never claim to be ChatGPT or a specific model. If you do not know, say so.")
            request.httpBody = try JSONEncoder().encode(OpenRouterRequest(
                model: "openrouter/free",
                messages: [prompt] + context,
                max_tokens: 750
            ))
            let (data, response) = try await URLSession.shared.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(code) else {
                let msg = (try? JSONDecoder().decode(OpenRouterFailure.self, from: data).error?.message)
                    ?? "Server returned error " + String(code)
                throw NSError(domain: "LOGAI", code: code, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            let result = try JSONDecoder().decode(OpenRouterResult.self, from: data)
            guard let reply = result.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !reply.isEmpty else {
                throw NSError(domain: "LOGAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "The AI service returned no text. Try again."])
            }
            messages.append(ChatMessage(role: "assistant", content: reply))
            saveHistory()
        } catch {
            errorText = error.localizedDescription
        }
    }
}

struct ChatView: View {
    @StateObject private var chat = ChatStore()
    @State private var draft = ""
    @State private var showSettings = false
    private let purple = Color(red: 0.41, green: 0.29, blue: 0.92)
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if chat.messages.isEmpty {
                    Spacer()
                    Text("🤖").font(.system(size: 67))
                    Text("Hey, I'm LOG!").font(.system(size: 27, weight: .bold, design: .rounded))
                    Text("Your own AI chatbot. Ask me anything!").font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                    if !chat.hasKey {
                        Button("Connect Free AI") { showSettings = true }
                            .font(.headline).padding().foregroundColor(.white)
                            .background(purple).cornerRadius(13).padding(.top, 12)
                    }
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 13) {
                                ForEach(chat.messages) { message in
                                    HStack {
                                        if message.isUser { Spacer(minLength: 40) }
                                        Text(message.content)
                                            .font(.system(size: 15))
                                            .foregroundColor(message.isUser ? .white : .primary)
                                            .padding(13)
                                            .background(message.isUser ? purple : Color(.secondarySystemBackground))
                                            .cornerRadius(16)
                                            .textSelection(.enabled)
                                        if !message.isUser { Spacer(minLength: 40) }
                                    }.id(message.id)
                                }
                                if chat.busy {
                                    HStack {
                                        ProgressView()
                                        Text("LOG is thinking…").font(.caption).foregroundColor(.secondary)
                                        Spacer()
                                    }.padding(.top, 8).id("thinking")
                                }
                            }.padding(14)
                        }
                        .onChange(of: chat.messages.count) { _ in
                            if let id = chat.messages.last?.id {
                                withAnimation { proxy.scrollTo(id, anchor: .bottom) }
                            }
                        }
                    }
                }
                if let error = chat.errorText {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack(spacing: 10) {
                    TextField("Message LOG…", text: $draft)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(15)
                    Button {
                        let text = draft
                        draft = ""
                        Task { await chat.send(text) }
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.headline).frame(width: 40, height: 40)
                            .foregroundColor(.white).background(purple).clipShape(Circle())
                    }.disabled(chat.busy || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !chat.hasKey)
                    .opacity(chat.busy || draft.isEmpty || !chat.hasKey ? 0.45 : 1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color(.systemBackground))
            }
            .navigationTitle("LOG AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { chat.clear() } label: { Image(systemName: "square.and.pencil") }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showSettings) { SettingsView(chat: chat) }
    }
}

struct SettingsView: View {
    @ObservedObject var chat: ChatStore
    @Environment(\.dismiss) private var dismiss
    @State private var key = ""
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Real AI Connection")) {
                    Text("LOG uses OpenRouter's FREE model router. Create a free account and API key, then paste it here. No key is included in the app.")
                        .font(.subheadline)
                    Link("Get a free API key", destination: URL(string: "https://openrouter.ai/settings/keys")!)
                    SecureField("OpenRouter API key", text: $key)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Save Key on This iPhone") {
                        chat.saveKey(key)
                        key = ""
                        dismiss()
                    }.disabled(key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if chat.hasKey {
                        Label("A key is stored in iPhone Keychain", systemImage: "checkmark.shield")
                        Button("Remove Saved Key", role: .destructive) {
                            chat.saveKey("")
                            dismiss()
                        }
                    }
                }
                Section(header: Text("Privacy & Limits")) {
                    Text("Free models have limits and may be unavailable. Your chat messages go to OpenRouter and its selected AI model provider. Chat history stays in this app on your iPhone. Your API key is stored in the iPhone Keychain.")
                    Text("Only the free route (openrouter/free) is used. The app does not automatically select paid models.")
                }
            }
            .navigationTitle("LOG Settings")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
            }}
        }
        .navigationViewStyle(.stack)
    }
}
