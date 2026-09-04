import Foundation

protocol ForexAPI: Sendable {
    func calendar(from start: Date, to end: Date) async throws -> CalendarEnvelope
    func calendarDetail(id: String) async throws -> CalendarDetail
    func newsSections() async throws -> NewsSectionsEnvelope
    func news(
        section: NewsSectionID,
        impact: Impact?,
        limit: Int,
        cursor: String?
    ) async throws -> NewsArticlesEnvelope
    func newsV2Detail(id: String) async throws -> NewsArticleDetail
    func latestComments(limit: Int, cursor: String?) async throws -> NewsCommentsEnvelope
    func articleComments(id: String, limit: Int, cursor: String?) async throws -> NewsCommentsEnvelope
    func mediaData(path: String) async throws -> Data
    func topContracts(limit: Int, marketType: ContractMarketFilter) async throws -> BinanceContractsEnvelope
    func status() async throws -> ServiceStatus
}

extension ForexAPI {
    func calendarDetail(id: String) async throws -> CalendarDetail {
        throw APIError.invalidConfiguration
    }

    func newsSections() async throws -> NewsSectionsEnvelope { throw APIError.invalidConfiguration }

    func news(
        section: NewsSectionID,
        impact: Impact?,
        limit: Int,
        cursor: String?
    ) async throws -> NewsArticlesEnvelope {
        throw APIError.invalidConfiguration
    }

    func newsV2Detail(id: String) async throws -> NewsArticleDetail {
        throw APIError.invalidConfiguration
    }

    func latestComments(limit: Int, cursor: String?) async throws -> NewsCommentsEnvelope {
        throw APIError.invalidConfiguration
    }

    func articleComments(
        id: String,
        limit: Int,
        cursor: String?
    ) async throws -> NewsCommentsEnvelope {
        throw APIError.invalidConfiguration
    }

    func mediaData(path: String) async throws -> Data { throw APIError.invalidConfiguration }

    func topContracts(limit: Int, marketType: ContractMarketFilter) async throws -> BinanceContractsEnvelope {
        throw APIError.invalidConfiguration
    }
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

    func calendarDetail(id: String) throws -> URLRequest {
        try request(path: "/api/v1/calendar/\(id)")
    }

    func newsSections() throws -> URLRequest {
        try request(path: "/api/v2/news/sections")
    }

    func news(
        section: NewsSectionID,
        impact: Impact?,
        limit: Int,
        cursor: String?
    ) throws -> URLRequest {
        var queryItems = [
            URLQueryItem(name: "section", value: section.rawValue),
            URLQueryItem(name: "limit", value: String(limit)),
        ]
        if let impact, impact != .unknown, impact != .holiday {
            queryItems.append(URLQueryItem(name: "impact", value: impact.rawValue))
        }
        if let cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        return try request(path: "/api/v2/news", queryItems: queryItems)
    }

    func newsV2Detail(id: String) throws -> URLRequest {
        try request(path: "/api/v2/news/\(id)")
    }

    func latestComments(limit: Int, cursor: String?) throws -> URLRequest {
        try pagedRequest(path: "/api/v2/news/comments/latest", limit: limit, cursor: cursor)
    }

    func articleComments(id: String, limit: Int, cursor: String?) throws -> URLRequest {
        try pagedRequest(path: "/api/v2/news/\(id)/comments", limit: limit, cursor: cursor)
    }

    func media(path: String) throws -> URLRequest {
        guard path.hasPrefix("/api/v2/news/media/"),
              !path.contains(".."),
              URL(string: path)?.scheme == nil
        else {
            throw APIError.invalidConfiguration
        }
        return try request(path: path)
    }

    func topContracts(limit: Int, marketType: ContractMarketFilter) throws -> URLRequest {
        try request(
            path: "/api/v1/binance/futures/top-contracts",
            queryItems: [
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "market_type", value: marketType.rawValue),
            ]
        )
    }

    func status() throws -> URLRequest {
        try request(path: "/api/v1/status")
    }

    private func pagedRequest(path: String, limit: Int, cursor: String?) throws -> URLRequest {
        var queryItems = [URLQueryItem(name: "limit", value: String(limit))]
        if let cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        return try request(path: path, queryItems: queryItems)
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

    func calendarDetail(id: String) async throws -> CalendarDetail {
        try await send(builder.calendarDetail(id: id))
    }

    func newsSections() async throws -> NewsSectionsEnvelope {
        try await send(builder.newsSections())
    }

    func news(
        section: NewsSectionID,
        impact: Impact?,
        limit: Int,
        cursor: String?
    ) async throws -> NewsArticlesEnvelope {
        try await send(
            builder.news(section: section, impact: impact, limit: limit, cursor: cursor)
        )
    }

    func newsV2Detail(id: String) async throws -> NewsArticleDetail {
        try await send(builder.newsV2Detail(id: id))
    }

    func latestComments(limit: Int, cursor: String?) async throws -> NewsCommentsEnvelope {
        try await send(builder.latestComments(limit: limit, cursor: cursor))
    }

    func articleComments(
        id: String,
        limit: Int,
        cursor: String?
    ) async throws -> NewsCommentsEnvelope {
        try await send(builder.articleComments(id: id, limit: limit, cursor: cursor))
    }

    func mediaData(path: String) async throws -> Data {
        let (data, response) = try await session.data(for: builder.media(path: path))
        try validate(response)
        return data
    }

    func topContracts(
        limit: Int = 20,
        marketType: ContractMarketFilter = .all
    ) async throws -> BinanceContractsEnvelope {
        try await send(builder.topContracts(limit: limit, marketType: marketType))
    }

    func status() async throws -> ServiceStatus {
        try await send(builder.status())
    }

    private func send<Value: Decodable & Sendable>(_ request: URLRequest) async throws -> Value {
        let (data, response) = try await session.data(for: request)
        try validate(response)
        do {
            return try JSONDecoder.api.decode(Value.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        switch http.statusCode {
        case 200 ..< 300: break
        case 401: throw APIError.unauthorized
        case 404: throw APIError.notFound
        case 429: throw APIError.rateLimited
        case 500 ... 599: throw APIError.server
        default: throw APIError.invalidResponse
        }
    }
}
