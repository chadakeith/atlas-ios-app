import Foundation

enum APIError: LocalizedError {
    case notConfigured
    case invalidURL
    /// The request bounced to a login page (Google / Cloudflare Access / oauth2-proxy).
    case needsSignIn
    case http(Int)
    case decoding(String)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Set the dashboard address in Settings."
        case .invalidURL: return "The dashboard address is not a valid URL."
        case .needsSignIn: return "Sign in to the Atlas dashboard to continue."
        case .http(let code): return "The dashboard returned HTTP \(code)."
        case .decoding(let detail): return "Unexpected response from the dashboard. \(detail)"
        case .transport(let detail): return detail
        }
    }
}

/// Thin client for the Atlas dashboard's JSON endpoints. Authentication rides on
/// the cookies the browser sign-in leaves in `HTTPCookieStorage.shared`, or on a
/// Cloudflare Access service token when one is configured.
@MainActor
final class DashboardAPI {
    var baseURL: URL?
    var serviceToken: ServiceToken?

    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURL: URL?, session: URLSession? = nil) {
        self.baseURL = baseURL
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.httpCookieStorage = .shared
            configuration.httpShouldSetCookies = true
            configuration.timeoutIntervalForRequest = 180 // force=true recomputes can be slow
            configuration.waitsForConnectivity = true
            self.session = URLSession(configuration: configuration)
        }
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    // MARK: Endpoints

    func overview(force: Bool = false) async throws -> Overview {
        try await get("/overview", force: force)
    }

    func missingMacs(force: Bool = false) async throws -> [DeviceSection] {
        let payload: ComputerSectionsPayload = try await get("/missing-macs", force: force)
        return payload.sections
    }

    func missingDevices(force: Bool = false) async throws -> [DeviceSection] {
        let payload: MobileSectionsPayload = try await get("/missing-devices", force: force)
        return payload.sections
    }

    func totalMacs() async throws -> CountPayload {
        try await get("/total-macs")
    }

    func totalDevices() async throws -> CountPayload {
        try await get("/total-devices")
    }

    func security(force: Bool = false) async throws -> SecurityPayload {
        try await get("/security", force: force)
    }

    func lifecycle(force: Bool = false) async throws -> LifecyclePayload {
        try await get("/lifecycle-macs", force: force)
    }

    func osVersions(force: Bool = false) async throws -> OSVersionsPayload {
        try await get("/os-versions", force: force)
    }

    func productivitySummary(force: Bool = false) async throws -> ProductivitySummary {
        try await get("/productivity/api/summary", force: force)
    }

    func productivityTeam(force: Bool = false) async throws -> TeamPayload {
        try await get("/productivity/api/team", force: force)
    }

    func accessMe() async throws -> AccessMe {
        try await get("/access-me")
    }

    // MARK: Plumbing

    private func get<T: Decodable>(_ path: String, force: Bool = false) async throws -> T {
        let query = force ? [URLQueryItem(name: "force", value: "true")] : []
        return try await get(path, query: query)
    }

    func get<T: Decodable>(_ path: String, query: [URLQueryItem]) async throws -> T {
        guard let baseURL else { throw APIError.notConfigured }
        guard let url = Self.makeURL(base: baseURL, path: path, query: query) else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let serviceToken, serviceToken.isComplete {
            request.setValue(serviceToken.clientID, forHTTPHeaderField: "CF-Access-Client-Id")
            request.setValue(serviceToken.clientSecret, forHTTPHeaderField: "CF-Access-Client-Secret")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else { throw APIError.transport("No HTTP response.") }

        try Self.checkForLoginWall(http, expectedHost: baseURL.host() ?? "")
        guard (200..<300).contains(http.statusCode) else { throw APIError.http(http.statusCode) }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(Self.describe(error))
        }
    }

    nonisolated static func makeURL(base: URL, path: String, query: [URLQueryItem]) -> URL? {
        var trimmed = path
        while trimmed.hasPrefix("/") { trimmed.removeFirst() }
        guard var components = URLComponents(url: base.appending(path: trimmed), resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.queryItems = query.isEmpty ? nil : query
        return components.url
    }

    /// Both Cloudflare Access and oauth2-proxy redirect unauthenticated JSON requests to an
    /// HTML login page, often on another host. Treat any of those signals as "sign in".
    nonisolated static func checkForLoginWall(_ response: HTTPURLResponse, expectedHost: String) throws {
        if let finalHost = response.url?.host(), !expectedHost.isEmpty,
           finalHost.lowercased() != expectedHost.lowercased() {
            throw APIError.needsSignIn
        }
        if response.statusCode == 401 || response.statusCode == 403 {
            throw APIError.needsSignIn
        }
        let contentType = (response.value(forHTTPHeaderField: "Content-Type") ?? "").lowercased()
        if contentType.contains("text/html") {
            throw APIError.needsSignIn
        }
    }

    nonisolated private static func describe(_ error: Error) -> String {
        guard let decodingError = error as? DecodingError else { return error.localizedDescription }
        switch decodingError {
        case .keyNotFound(let key, let context):
            return "Missing key '\(key.stringValue)' at \(context.codingPath.map(\.stringValue).joined(separator: "."))."
        case .typeMismatch(_, let context):
            return "Type mismatch at \(context.codingPath.map(\.stringValue).joined(separator: "."))."
        case .valueNotFound(_, let context):
            return "Null at \(context.codingPath.map(\.stringValue).joined(separator: "."))."
        case .dataCorrupted(let context):
            return context.debugDescription
        @unknown default:
            return error.localizedDescription
        }
    }
}
