import Foundation
#if canImport(LinkKit)
import LinkKit
#endif

/// Coordinates with your backend to get a link_token, presents Plaid Link, and sends the public_token back.
/// Add the LinkKit package first: File → Add Package → https://github.com/plaid/plaid-link-ios-spm
final class PlaidService {

    static let shared = PlaidService()

    /// Base URL of your backend (e.g. Cloud Functions base URL). Must end without trailing slash.
    /// Example: "https://us-central1-YOUR_PROJECT.cloudfunctions.net"
    var backendBaseURL: String = "https://YOUR_BACKEND_BASE_URL"

    private init() {}

    /// Fetches a link_token from your backend and presents Plaid Link.
    /// - Parameters:
    ///   - userId: Current user ID (your backend may use this when creating the link_token and when exchanging).
    ///   - onSuccess: Called with the public_token after a successful link (backend should exchange and sync; you can refresh UI here).
    ///   - onExit: Called when the user exits Link without linking.
    ///   - onFailure: Called when creating the link_token or the Link handler fails.
    func presentLink(
        userId: String,
        onSuccess: @escaping (String) -> Void,
        onExit: @escaping () -> Void,
        onFailure: @escaping (String) -> Void
    ) {
        Task {
            guard let linkToken = await fetchLinkToken(userId: userId) else {
                await MainActor.run { onFailure("Could not get link token from server") }
                return
            }
            await MainActor.run {
                openLink(
                    linkToken: linkToken,
                    userId: userId,
                    onSuccess: onSuccess,
                    onExit: onExit,
                    onFailure: onFailure
                )
            }
        }
    }

    private func fetchLinkToken(userId: String) async -> String? {
        guard let url = URL(string: "\(backendBaseURL)/plaidLinkToken") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["userId": userId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let result = try? await URLSession.shared.data(for: request)
        guard let data = result?.0,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["link_token"] as? String else { return nil }
        return token
    }

    private func openLink(
        linkToken: String,
        userId: String,
        onSuccess: @escaping (String) -> Void,
        onExit: @escaping () -> Void,
        onFailure: @escaping (String) -> Void
    ) {
        #if canImport(LinkKit)
        let configuration = LinkTokenConfiguration(
            token: linkToken,
            onSuccess: { success in
                self.sendPublicToken(success.publicToken, userId: userId) { sent in
                    if sent {
                        onSuccess(success.publicToken)
                    } else {
                        onFailure("Linked but failed to sync with server")
                    }
                }
            },
            onExit: { _ in
                onExit()
            }
        )

        switch Plaid.create(configuration) {
        case .failure(let error):
            onFailure(error.localizedDescription)
        case .success(let handler):
            guard let topVC = topViewController() else {
                onFailure("Could not present Link")
                return
            }
            handler.open(presentUsing: .viewController(topVC))
        }
        #else
        onFailure("Add the LinkKit package (plaid-link-ios-spm) to use Plaid")
        #endif
    }

    private func sendPublicToken(_ publicToken: String, userId: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(backendBaseURL)/plaidExchange") else {
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["public_token": publicToken, "userId": userId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, response, _ in
            let ok = (response as? HTTPURLResponse)?.statusCode == 200
            DispatchQueue.main.async { completion(ok) }
        }.resume()
    }

    private func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController ?? windowScene.windows.first?.rootViewController
        else { return nil }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        return top
    }
}

import UIKit
