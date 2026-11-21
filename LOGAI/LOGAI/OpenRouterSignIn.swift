import Foundation
import AuthenticationServices
import CryptoKit
import UIKit

/// OpenRouter OAuth PKCE: no password or shared API key ever enters this repository.
final class OpenRouterSignIn: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    @Published var connecting = false
    @Published var lastError: String?
    private var session: ASWebAuthenticationSession?
    private var verifier: String?
    private var expectedState: String?
    private let callbackURL = "https://logai-connect.vercel.app/"

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? ASPresentationAnchor()
    }

    func connect(completion: @escaping (Result<String, Error>) -> Void) {
        guard !connecting else { return }
        let random = (0..<32).map { _ in UInt8.random(in: .min ... .max) }
        let codeVerifier = Data(random).base64URLEncoded()
        let digest = SHA256.hash(data: Data(codeVerifier.utf8))
        let challenge = Data(digest).base64URLEncoded()
        let nonce = Data((0..<24).map { _ in UInt8.random(in: .min ... .max) }).base64URLEncoded()
        verifier = codeVerifier
        expectedState = nonce

        var url = URLComponents(string: "https://openrouter.ai/auth")!
        url.queryItems = [
            URLQueryItem(name: "callback_url", value: callbackURL),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: nonce),
            URLQueryItem(name: "key_label", value: "LOG AI iPhone"),
            URLQueryItem(name: "expiration", value: "1-year")
        ]
        guard let destination = url.url else { return }
        connecting = true
        lastError = nil
        let session = ASWebAuthenticationSession(url: destination, callbackURLScheme: "logai") { [weak self] callback, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    self.connecting = false
                    self.verifier = nil
                    self.expectedState = nil
                    self.lastError = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                guard let callback = callback,
                      let params = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems,
                      let code = params.first(where: { $0.name == "code" })?.value,
                      let state = params.first(where: { $0.name == "state" })?.value,
                      let expected = self.expectedState, state == expected,
                      let codeVerifier = self.verifier else {
                    let failure = NSError(domain: "LOGAI", code: -2, userInfo: [NSLocalizedDescriptionKey: "Sign-in verification failed. Please try again."])
                    self.connecting = false
                    self.lastError = failure.localizedDescription
                    completion(.failure(failure))
                    return
                }
                self.verifier = nil
                self.expectedState = nil
                Task {
                    do {
                        var request = URLRequest(url: URL(string: "https://openrouter.ai/api/v1/auth/keys")!)
                        request.httpMethod = "POST"
                        request.timeoutInterval = 30
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.httpBody = try JSONSerialization.data(withJSONObject: [
                            "code": code, "code_verifier": codeVerifier, "code_challenge_method": "S256"
                        ])
                        let (data, response) = try await URLSession.shared.data(for: request)
                        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let key = json["key"] as? String, !key.isEmpty else {
                            throw NSError(domain: "LOGAI", code: -3, userInfo: [NSLocalizedDescriptionKey: "OpenRouter didn't complete sign-in. Try again."])
                        }
                        await MainActor.run {
                            self.connecting = false
                            completion(.success(key))
                        }
                    } catch {
                        await MainActor.run {
                            self.connecting = false
                            self.lastError = error.localizedDescription
                            completion(.failure(error))
                        }
                    }
                }
            }
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        self.session = session
        if !session.start() {
            connecting = false
            let error = NSError(domain: "LOGAI", code: -4, userInfo: [NSLocalizedDescriptionKey: "Could not open OpenRouter sign-in."])
            lastError = error.localizedDescription
            completion(.failure(error))
        }
    }
}
private extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
