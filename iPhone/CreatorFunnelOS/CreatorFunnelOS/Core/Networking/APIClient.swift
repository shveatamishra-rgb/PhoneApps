import Foundation

private struct APIErrorEnvelope: Decodable {
    let message: String?
}

private struct RefreshRequest: Encodable {
    let refreshToken: String
}

private struct RefreshResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}

actor APIClient {
    private let configuration: AppConfiguration
    private let sessionStore: KeychainSessionStore
    private let urlSession: URLSession
    private var session: StoredSession?

    init(
        configuration: AppConfiguration,
        sessionStore: KeychainSessionStore,
        urlSession: URLSession = .shared
    ) {
        self.configuration = configuration
        self.sessionStore = sessionStore
        self.urlSession = urlSession
        self.session = sessionStore.load()
    }

    func storedSession() -> StoredSession? {
        session
    }

    func setSession(_ newSession: StoredSession) throws {
        session = newSession
        try sessionStore.save(newSession)
    }

    func clearSession() {
        session = nil
        sessionStore.clear()
    }

    func send<Response: Decodable>(
        _ path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        authenticated: Bool = true
    ) async throws -> Response {
        let request = try makeRequest(
            path,
            method: method,
            body: body,
            authenticated: authenticated
        )
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ServiceError.unavailable }

        if http.statusCode == 401, authenticated, try await refreshTokens() {
            return try await send(path, method: method, body: body, authenticated: true)
        }
        guard (200..<300).contains(http.statusCode) else {
            let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data)
            if http.statusCode == 401 { throw ServiceError.notAuthenticated }
            if http.statusCode == 403 { throw ServiceError.permissionDenied }
            throw ServiceError.validation(envelope?.message ?? "The server returned an error.")
        }
        return try decoder.decode(Response.self, from: data)
    }

    func sendWithoutResponse(
        _ path: String,
        method: String,
        body: (any Encodable)? = nil,
        authenticated: Bool = true
    ) async throws {
        let request = try makeRequest(
            path,
            method: method,
            body: body,
            authenticated: authenticated
        )
        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ServiceError.unavailable }
        if http.statusCode == 401, authenticated, try await refreshTokens() {
            return try await sendWithoutResponse(path, method: method, body: body)
        }
        guard (200..<300).contains(http.statusCode) else {
            let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data)
            throw ServiceError.validation(envelope?.message ?? "The server returned an error.")
        }
    }

    private func makeRequest(
        _ path: String,
        method: String,
        body: (any Encodable)?,
        authenticated: Bool
    ) throws -> URLRequest {
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        guard let url = URL(string: cleanPath, relativeTo: configuration.apiBaseURL.appendingPathComponent("/")) else {
            throw ServiceError.configuration("The API request URL could not be created.")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("CreatorFunnelOS-iOS/1.0", forHTTPHeaderField: "X-Client")
        if authenticated, let token = session?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }
        return request
    }

    private func refreshTokens() async throws -> Bool {
        guard let current = session else { return false }
        let request = RefreshRequest(refreshToken: current.refreshToken)
        do {
            let refreshed: RefreshResponse = try await send(
                "/v1/auth/refresh",
                method: "POST",
                body: request,
                authenticated: false
            )
            let updated = StoredSession(
                user: current.user,
                accessToken: refreshed.accessToken,
                refreshToken: refreshed.refreshToken,
                isEmailVerified: current.isEmailVerified
            )
            try setSession(updated)
            return true
        } catch {
            clearSession()
            return false
        }
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractional.date(from: value) {
                return date
            }
            let standard = ISO8601DateFormatter()
            standard.formatOptions = [.withInternetDateTime]
            if let date = standard.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO-8601 date: \(value)"
            )
        }
        return decoder
    }
}

private struct AnyEncodable: Encodable {
    private let encodeValue: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        encodeValue = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeValue(encoder)
    }
}
