import SwiftUI

struct BloxifyResponse: Decodable {
    let capcut: CapCutInfo
    let website: WebsiteInfo
    let updates: [UpdateInfo]
}
struct CapCutInfo: Decodable {
    let status: String
    let updatedLabel: String
    let message: String
}
struct WebsiteInfo: Decodable {
    let online: Bool
    let detail: String
}
struct UpdateInfo: Decodable, Identifiable {
    let title: String
    let description: String
    let date: String
    var id: String { date + title }
}
@MainActor
final class BloxifyModel: ObservableObject {
    @Published var info: BloxifyResponse?
    @Published var loading = false
    @Published var message = "Tap Check Now to refresh."
    func refresh() async {
        guard !loading else { return }
        loading = true
        defer { loading = false }
        do {
            let url = URL(string: "https://bloxify-updates.vercel.app/api/check")!
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.timeoutInterval = 15
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            info = try JSONDecoder().decode(BloxifyResponse.self, from: data)
            message = "Updated " + DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
        } catch {
            message = "Couldn't refresh. Check your internet connection."
        }
    }
}
struct ContentView: View {
    @StateObject private var model = BloxifyModel()
    private let purple = Color(red: 0.45, green: 0.32, blue: 0.93)
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 11) {
                        Text("B").font(.system(size: 23, weight: .black)).foregroundColor(.white)
                            .frame(width: 43, height: 43).background(purple).cornerRadius(12)
                        Text("Bloxify Updates").font(.headline)
                        Spacer()
                    }
                    .padding(.top, 8)

                    Text("Stay in the loop. 🔔")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("CapCut replies, website status, and Bloxify news.")
                        .font(.subheadline).foregroundColor(.secondary)

                    Button {
                        Task { await model.refresh() }
                    } label: {
                        HStack {
                            Spacer()
                            if model.loading { ProgressView().tint(.white) }
                            else { Image(systemName: "arrow.clockwise") }
                            Text(model.loading ? "Checking..." : "Check Now")
                            Spacer()
                        }
                        .font(.headline).padding(16)
                    }
                    .buttonStyle(.plain).background(purple).foregroundColor(.white).cornerRadius(15)
                    .disabled(model.loading)

                    Text(model.message).font(.caption).foregroundColor(.secondary)
                    Text("Watchlist").font(.title2).bold()
                    VStack(spacing: 12) {
                        statusCard("✂️", "CapCut integration",
                            model.info?.capcut.updatedLabel ?? "Waiting for official reply",
                            model.info?.capcut.message ?? "ChatGPT checks the private Gmail thread separately.")
                        statusCard("🌐", "Bloxify Studio",
                            model.info?.website.online == true ? "LIVE" : "Status not confirmed",
                            model.info?.website.detail ?? "Tap Check Now to test site availability.")
                        statusCard("🤖", "ChatGPT watcher", "Scheduled daily",
                            "CapCut email replies are checked by the existing ChatGPT task.")
                    }
                    Link("Open Bloxify Studio", destination: URL(string: "https://bloxify-studio.vercel.app")!)
                        .foregroundColor(purple)
                    Text("Recent updates").font(.title2).bold()
                    if let updates = model.info?.updates {
                        ForEach(updates) { item in
                            VStack(alignment: .leading, spacing: 7) {
                                Text(item.title).font(.headline)
                                Text(item.description).font(.subheadline).foregroundColor(.secondary)
                                Text(item.date).font(.caption2).foregroundColor(.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                                .padding().background(Color.white).cornerRadius(13)
                        }
                    } else {
                        Text("Press Check Now to load published updates.")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    Text("This app reads only published Bloxify status. It cannot check private Gmail directly.")
                        .font(.caption2).foregroundColor(.secondary)
                }.padding(18)
            }
            .background(Color(red: 0.96, green: 0.96, blue: 0.98).ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .task { await model.refresh() }
    }
    private func statusCard(_ emoji: String, _ title: String, _ subtitle: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 13) {
            Text(emoji).font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundColor(purple)
                Text(detail).font(.caption).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }.padding(15).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white).cornerRadius(14)
    }
}
