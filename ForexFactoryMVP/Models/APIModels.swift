import Foundation

enum Impact: String, Codable, Sendable {
    case low
    case medium
    case high
    case holiday
    case unknown
}

struct CalendarEvent: Codable, Identifiable, Equatable, Sendable {
    let sourceID: String
    let eventAt: Date
    let currency: String
    let impact: Impact
    let titleEN: String
    let titleZH: String?
    let actual: String?
    let forecast: String?
    let previous: String?
    let updatedAt: Date

    var id: String { sourceID }

    enum CodingKeys: String, CodingKey {
        case sourceID = "source_id"
        case eventAt = "event_at"
        case currency, impact
        case titleEN = "title_en"
        case titleZH = "title_zh"
        case actual, forecast, previous
        case updatedAt = "updated_at"
    }
}

struct NewsItem: Codable, Identifiable, Equatable, Sendable {
    let sourceID: String
    let url: URL
    let source: String?
    let publishedAt: Date?
    let firstSeenAt: Date
    let titleEN: String
    let titleZH: String?
    let summaryEN: String?
    let summaryZH: String?
    let bodyEN: String?
    let bodyZH: String?
    let imageURL: URL?
    let updatedAt: Date

    var id: String { sourceID }

    enum CodingKeys: String, CodingKey {
        case sourceID = "source_id"
        case url, source
        case publishedAt = "published_at"
        case firstSeenAt = "first_seen_at"
        case titleEN = "title_en"
        case titleZH = "title_zh"
        case summaryEN = "summary_en"
        case summaryZH = "summary_zh"
        case bodyEN = "body_en"
        case bodyZH = "body_zh"
        case imageURL = "image_url"
        case updatedAt = "updated_at"
    }
}

struct ListEnvelope<Item: Codable & Sendable>: Codable, Sendable {
    let items: [Item]
    let generatedAt: Date

    enum CodingKeys: String, CodingKey {
        case items
        case generatedAt = "generated_at"
    }
}

typealias CalendarEnvelope = ListEnvelope<CalendarEvent>
typealias NewsEnvelope = ListEnvelope<NewsItem>

struct ServiceStatus: Codable, Equatable, Sendable {
    let status: String
    let model: String
}

extension JSONDecoder {
    static var api: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let value = try decoder.singleValueContainer().decode(String.self)
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
                in: try decoder.singleValueContainer(),
                debugDescription: "Invalid ISO-8601 date"
            )
        }
        return decoder
    }
}

extension JSONEncoder {
    static var api: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}
