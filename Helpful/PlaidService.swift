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
    var backendBaseURL: String = "https://us-central1-helpfulapp-962b1.cloudfunctions.net"

    private init() {}

    /// TEMP: use a hard-coded link_token so Plaid reliably opens while backend behavior is investigated.
    func presentLink(
        userId: String,
        onSuccess: @escaping (String) -> Void,
        onExit: @escaping () -> Void,
        onFailure: @escaping (String) -> Void
    ) {
        let linkToken = "link-sandbox-25c717c3-20b2-4707-8c3e-fb2507975c70"
        print("PlaidService.presentLink (hard-coded): opening Link with token length \(linkToken.count)")
        openLink(
            linkToken: linkToken,
            userId: userId,
            onSuccess: onSuccess,
            onExit: onExit,
            onFailure: onFailure
        )
    }

    private func fetchLinkToken(userId: String) async -> String? {
        print("PlaidService.fetchLinkToken: start for userId=\(userId)")
        guard let url = URL(string: "\(backendBaseURL)/plaidLinkToken") else {
            print("PlaidService.fetchLinkToken: bad URL from base=\(backendBaseURL)")
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["userId": userId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        let session = URLSession(configuration: config)

        do {
            print("PlaidService.fetchLinkToken: sending request to \(url.absoluteString)")
            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                print("PlaidService.fetchLinkToken HTTP \(http.statusCode)")
                if let bodyString = String(data: data, encoding: .utf8) {
                    print("PlaidService.fetchLinkToken body: \(bodyString)")
                }
                return nil
            }
            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let token = json["link_token"] as? String
            else {
                print("PlaidService.fetchLinkToken: JSON parse failed")
                return nil
            }
            print("PlaidService.fetchLinkToken: success, got link_token length \(token.count)")
            return token
        } catch {
            print("PlaidService.fetchLinkToken error: \(error)")
            return nil
        }
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
            // Show a tiny debug alert before opening; this path is known to work reliably.
            let alert = UIAlertController(
                title: "Debug",
                message: "Opening Plaid Link…",
                preferredStyle: .alert
            )
            alert.addAction(
                UIAlertAction(
                    title: "OK",
                    style: .default,
                    handler: { _ in
                        handler.open(presentUsing: PresentationMethod.viewController(topVC))
                    }
                )
            )
            topVC.present(alert, animated: true, completion: nil)
        }
        #else
        print("PlaidService.openLink: LinkKit not available")
        onFailure("Add the LinkKit package (plaid-link-ios-spm) to use Plaid")
        #endif
    }

    private func sendPublicToken(_ publicToken: String, userId: String, completion: @escaping (Bool) -> Void) {
        print("PlaidService.sendPublicToken: start for userId=\(userId)")
        guard let url = URL(string: "\(backendBaseURL)/plaidExchange") else {
            print("PlaidService.sendPublicToken: bad URL from base=\(backendBaseURL)")
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["public_token": publicToken, "userId": userId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        print("PlaidService.sendPublicToken: sending request to \(url.absoluteString)")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("PlaidService.sendPublicToken error: \(error)")
            }
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("PlaidService.sendPublicToken response status=\(status)")
            if let data = data, let body = String(data: data, encoding: .utf8) {
                print("PlaidService.sendPublicToken body: \(body)")
            }
            let ok = status == 200
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
