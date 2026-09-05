import Foundation
import Observation
import WebKit

/// App-wide state: where the dashboard lives, whether we are signed in, and the
/// API client every screen shares.
@MainActor
@Observable
final class AppModel {
    static let defaultServer = "https://dashboard.atlassolutions.tech"

    private enum Keys {
        static let server = "serverURL"
        static let serviceToken = "cloudflareServiceToken"
    }

    private let defaults: UserDefaults
    let api: DashboardAPI

    /// Dashboard origin as typed by the user. Normalized before use.
    var serverURLString: String {
        didSet {
            defaults.set(serverURLString, forKey: Keys.server)
            api.baseURL = Self.normalizeServer(serverURLString)
        }
    }

    /// Optional Cloudflare Access service token. Lets the app skip the browser
    /// sign-in entirely when the dashboard host is fronted by Cloudflare Access.
    var serviceToken: ServiceToken? {
        didSet {
            api.serviceToken = serviceToken
            if let serviceToken, let data = try? JSONEncoder().encode(serviceToken) {
                try? Keychain.save(data, account: Keys.serviceToken)
            } else {
                Keychain.delete(account: Keys.serviceToken)
            }
        }
    }

    var isShowingSignIn = false
    var isShowingSettings = false

    /// Email reported by `/access-me`, when the proxy forwards one.
    var accountEmail: String?

    /// Incremented after a sign-in or server change so every screen reloads.
    private(set) var sessionGeneration = 0

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.string(forKey: Keys.server) ?? Self.defaultServer
        serverURLString = stored
        api = DashboardAPI(baseURL: Self.normalizeServer(stored))

        if let data = Keychain.load(account: Keys.serviceToken),
           let token = try? JSONDecoder().decode(ServiceToken.self, from: data) {
            serviceToken = token
            api.serviceToken = token
        }
    }

    var baseURL: URL? { api.baseURL }

    /// Accepts "dashboard.example.com", "https://dashboard.example.com/", etc.
    nonisolated static func normalizeServer(_ raw: String) -> URL? {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if !text.lowercased().hasPrefix("http://") && !text.lowercased().hasPrefix("https://") {
            text = "https://" + text
        }
        while text.hasSuffix("/") { text.removeLast() }
        guard let url = URL(string: text), url.host() != nil else { return nil }
        return url
    }

    // MARK: Session

    /// Called by screens when a request fails. Surfaces the sign-in sheet for auth errors.
    func handle(_ error: Error) {
        if let apiError = error as? APIError, case .needsSignIn = apiError {
            isShowingSignIn = true
        }
    }

    /// After the web sign-in completes: copy cookies to URLSession, verify, reload.
    func completeSignIn(from webView: WKWebView) async -> Bool {
        let cookies = await webView.configuration.websiteDataStore.httpCookieStore.allCookies()
        for cookie in cookies {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
        return await refreshIdentity()
    }

    /// Returns true when the dashboard answers JSON (i.e. we are past the login wall).
    @discardableResult
    func refreshIdentity() async -> Bool {
        do {
            let me = try await api.accessMe()
            accountEmail = me.email.isEmpty ? nil : me.email
            sessionGeneration += 1
            isShowingSignIn = false
            return true
        } catch {
            return false
        }
    }

    func signOut() async {
        if let host = baseURL?.host() {
            for cookie in HTTPCookieStorage.shared.cookies ?? [] where cookie.domain.contains(host) {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        let store = WKWebsiteDataStore.default()
        let records = await store.dataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes())
        await store.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records)
        accountEmail = nil
        sessionGeneration += 1
    }

    func serverChanged() {
        accountEmail = nil
        sessionGeneration += 1
    }
}

/// Cloudflare Access service token (Zero Trust → Access → Service Auth).
struct ServiceToken: Codable, Equatable {
    var clientID: String
    var clientSecret: String

    var isComplete: Bool { !clientID.isEmpty && !clientSecret.isEmpty }
}

#if DEBUG
extension UserDefaults {
    /// Isolated defaults for previews and tests.
    static let preview: UserDefaults = {
        let suite = "com.atlascarolina.AtlasDashboard.preview"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }()
}
#endif
