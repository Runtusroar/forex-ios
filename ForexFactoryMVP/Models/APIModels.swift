import Foundation

enum Impact: String, Codable, Hashable, Sendable {
    case low
    case medium
    case high
    case holiday
    case unknown

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = Impact(rawValue: value) ?? .unknown
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct LocalizedText: Codable, Equatable, Sendable {
    let en: String?
    let zhHans: String?

    enum CodingKeys: String, CodingKey {
        case en
        case zhHans = "zh_hans"
    }
}

enum NewsSectionID: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case latest
    case hot
    case fundamental
    case technical
    case industry
    case entertainment
    case educational
    case latestComments = "latest-comments"

    var id: String { rawValue }
}

struct NewsSection: Codable, Identifiable, Equatable, Sendable {
    let id: NewsSectionID
    let name: LocalizedText
    let itemCount: Int
    let supportsImpactFilter: Bool

    enum CodingKeys: String, CodingKey {
        case id, name
        case itemCount = "item_count"
        case supportsImpactFilter = "supports_impact_filter"
    }
}

enum NewsDetailState: String, Codable, Sendable {
    case pending
    case complete
    case partial
    case failed
    case unknown

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = NewsDetailState(rawValue: value) ?? .unknown
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct NewsArticleSummary: Codable, Identifiable, Equatable, Sendable {
    let sourceID: String
    let ffURL: URL
    let title: LocalizedText
    let teaser: LocalizedText
    let sourceName: String?
    let sourceURL: URL?
    let publishedAt: Date?
    let publishedAtSourceText: String?
    let sourceTimezone: String?
    let breakingImpact: Impact?
    let commentCount: Int
    let detailState: NewsDetailState
    let isExcerpt: Bool
    let thumbnailURL: URL?
    let categories: [NewsSectionID]

    var id: String { sourceID }

    enum CodingKeys: String, CodingKey {
        case sourceID = "source_id"
        case ffURL = "ff_url"
        case title, teaser
        case sourceName = "source_name"
        case sourceURL = "source_url"
        case publishedAt = "published_at"
        case publishedAtSourceText = "published_at_source_text"
        case sourceTimezone = "source_timezone"
        case breakingImpact = "breaking_impact"
        case commentCount = "comment_count"
        case detailState = "detail_state"
        case isExcerpt = "is_excerpt"
        case thumbnailURL = "thumbnail_url"
        case categories
    }
}

struct NewsFeedPlacement: Codable, Equatable, Sendable {
    let feedType: NewsSectionID
    let rank: Int

    enum CodingKeys: String, CodingKey {
        case feedType = "feed_type"
        case rank
    }
}

enum NewsSegmentType: String, Codable, Sendable {
    case article
    case social
    case update
    case quote
    case link
    case unknown

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = NewsSegmentType(rawValue: value) ?? .unknown
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum NewsMediaType: String, Codable, Sendable {
    case image
    case chart
    case attachment
    case unknown

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = NewsMediaType(rawValue: value) ?? .unknown
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum NewsMediaState: String, Codable, Sendable {
    case pending
    case processing
    case complete
    case failed
    case unknown

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = NewsMediaState(rawValue: value) ?? .unknown
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct NewsMedia: Codable, Identifiable, Equatable, Sendable {
    let id: Int
    let position: Int
    let type: NewsMediaType
    let caption: String?
    let originalURL: URL
    let downloadState: NewsMediaState
    let url: String?
    let mimeType: String?
    let byteSize: Int?

    enum CodingKeys: String, CodingKey {
        case id, position, type, caption, url
        case originalURL = "original_url"
        case downloadState = "download_state"
        case mimeType = "mime_type"
        case byteSize = "byte_size"
    }
}

struct NewsSegment: Codable, Identifiable, Equatable, Sendable {
    let id: Int
    let stableKey: String
    let position: Int
    let type: NewsSegmentType
    let authorName: String?
    let authorHandle: String?
    let publishedAt: Date?
    let publishedAtSourceText: String?
    let text: LocalizedText
    let sourceURL: URL?
    let isExcerpt: Bool
    let media: [NewsMedia]

    enum CodingKeys: String, CodingKey {
        case id, position, type, text, media
        case stableKey = "stable_key"
        case authorName = "author_name"
        case authorHandle = "author_handle"
        case publishedAt = "published_at"
        case publishedAtSourceText = "published_at_source_text"
        case sourceURL = "source_url"
        case isExcerpt = "is_excerpt"
    }
}

struct NewsArticleDetail: Codable, Identifiable, Equatable, Sendable {
    let sourceID: String
    let ffURL: URL
    let title: LocalizedText
    let teaser: LocalizedText
    let sourceName: String?
    let sourceURL: URL?
    let publishedAt: Date?
    let publishedAtSourceText: String?
    let sourceTimezone: String?
    let breakingImpact: Impact?
    let commentCount: Int
    let detailState: NewsDetailState
    let isExcerpt: Bool
    let thumbnailURL: URL?
    let categories: [NewsSectionID]
    let feeds: [NewsFeedPlacement]
    let segments: [NewsSegment]
    let commentCountCollected: Int
    let commentsComplete: Bool
    let generatedAt: Date

    var id: String { sourceID }

    enum CodingKeys: String, CodingKey {
        case sourceID = "source_id"
        case ffURL = "ff_url"
        case title, teaser
        case sourceName = "source_name"
        case sourceURL = "source_url"
        case publishedAt = "published_at"
        case publishedAtSourceText = "published_at_source_text"
        case sourceTimezone = "source_timezone"
        case breakingImpact = "breaking_impact"
        case commentCount = "comment_count"
        case detailState = "detail_state"
        case isExcerpt = "is_excerpt"
        case thumbnailURL = "thumbnail_url"
        case categories, feeds, segments
        case commentCountCollected = "comment_count_collected"
        case commentsComplete = "comments_complete"
        case generatedAt = "generated_at"
    }
}

struct NewsComment: Codable, Identifiable, Equatable, Sendable {
    let commentID: String
    let articleID: String
    let parentCommentID: String?
    let authorName: String
    let publishedAt: Date?
    let publishedAtSourceText: String?
    let text: LocalizedText
    let permalink: URL
    let reactionCount: Int?

    var id: String { commentID }

    enum CodingKeys: String, CodingKey {
        case commentID = "comment_id"
        case articleID = "article_id"
        case parentCommentID = "parent_comment_id"
        case authorName = "author_name"
        case publishedAt = "published_at"
        case publishedAtSourceText = "published_at_source_text"
        case text, permalink
        case reactionCount = "reaction_count"
    }
}

struct CursorEnvelope<Item: Codable & Equatable & Sendable>: Codable, Equatable, Sendable {
    let items: [Item]
    let nextCursor: String?
    let generatedAt: Date

    enum CodingKeys: String, CodingKey {
        case items
        case nextCursor = "next_cursor"
        case generatedAt = "generated_at"
    }
}

struct NewsSectionsEnvelope: Codable, Equatable, Sendable {
    let items: [NewsSection]
    let generatedAt: Date

    enum CodingKeys: String, CodingKey {
        case items
        case generatedAt = "generated_at"
    }
}

struct NewsCommentsEnvelope: Codable, Equatable, Sendable {
    let items: [NewsComment]
    let nextCursor: String?
    let commentsComplete: Bool
    let generatedAt: Date

    enum CodingKeys: String, CodingKey {
        case items
        case nextCursor = "next_cursor"
        case commentsComplete = "comments_complete"
        case generatedAt = "generated_at"
    }
}

typealias NewsArticlesEnvelope = CursorEnvelope<NewsArticleSummary>

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
