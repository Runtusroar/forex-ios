import Foundation

protocol ForexAPI: Sendable {
    func calendar(from start: Date, to end: Date) async throws -> CalendarEnvelope
    func news(limit: Int) async throws -> NewsEnvelope
    func newsDetail(id: String) async throws -> NewsItem
    func status() async throws -> ServiceStatus
}

enum APIError: LocalizedError, Equatable {
    case invalidConfiguration
    case unauthorized
    case notFound
    case rateLimited
    case server
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration: "Check the API URL and key in Settings."
        case .unauthorized: "The API key was rejected."
        case .notFound: "The requested item is no longer available."
        case .rateLimited: "The server is busy. Try again shortly."
        case .server: "The server could not complete the request."
        case .invalidResponse: "The server returned unreadable data."
        }
    }
}

struct APIRequestBuilder: Sendable {
    let baseURL: URL
    let apiKey: String

    func calendar(from start: Date, to end: Date) throws -> URLRequest {
        try request(
            path: "/api/v1/calendar",
            queryItems: [
                URLQueryItem(name: "from", value: Self.iso8601(start)),
                URLQueryItem(name: "to", value: Self.iso8601(end)),
            ]
        )
    }

    func news(limit: Int) throws -> URLRequest {
        try request(
            path: "/api/v1/news",
            queryItems: [URLQueryItem(name: "limit", value: String(limit))]
        )
    }

    func newsDetail(id: String) throws -> URLRequest {
        try request(path: "/api/v1/news/\(id)")
    }

    func status() throws -> URLRequest {
        try request(path: "/api/v1/status")
    }

    private func request(path: String, queryItems: [URLQueryItem] = []) throws -> URLRequest {
        guard baseURL.scheme == "https" || baseURL.host == "127.0.0.1" else {
            throw APIError.invalidConfiguration
        }
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidConfiguration
        }
        components.path = path
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url, !apiKey.isEmpty else {
            throw APIError.invalidConfiguration
        }
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        return request
    }

    private static func iso8601(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}

actor APIClient: ForexAPI {
    private let builder: APIRequestBuilder
    private let session: URLSession

    init(baseURL: URL, apiKey: String, session: URLSession = .shared) {
        builder = APIRequestBuilder(baseURL: baseURL, apiKey: apiKey)
        self.session = session
    }

    func calendar(from start: Date, to end: Date) async throws -> CalendarEnvelope {
        try await send(builder.calendar(from: start, to: end))
    }

    func news(limit: Int = 50) async throws -> NewsEnvelope {
        try await send(builder.news(limit: limit))
    }

    func newsDetail(id: String) async throws -> NewsItem {
        try await send(builder.newsDetail(id: id))
    }

    func status() async throws -> ServiceStatus {
        try await send(builder.status())
    }

    private func send<Value: Decodable & Sendable>(_ request: URLRequest) async throws -> Value {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        switch http.statusCode {
        case 200 ..< 300: break
        case 401: throw APIError.unauthorized
        case 404: throw APIError.notFound
        case 429: throw APIError.rateLimited
        case 500 ... 599: throw APIError.server
        default: throw APIError.invalidResponse
        }
        do {
            return try JSONDecoder.api.decode(Value.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }
}
