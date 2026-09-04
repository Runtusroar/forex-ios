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

enum CalendarValueState: String, Codable, Hashable, Sendable {
    case better
    case worse
    case unknown

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = CalendarValueState(rawValue: value) ?? .unknown
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

enum NewsSegmentLinkKind: String, Codable, Sendable {
    case fullStory = "full_story"
    case unknown

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = NewsSegmentLinkKind(rawValue: value) ?? .unknown
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum NewsSegmentDisplayMode: String, Codable, Sendable {
    case full
    case clamped
    case unknown

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = NewsSegmentDisplayMode(rawValue: value) ?? .unknown
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct NewsSegmentPresentation: Codable, Equatable, Sendable {
    let mode: NewsSegmentDisplayMode
    let maxLines: Int?
    let actionLabel: String?

    static let full = NewsSegmentPresentation(
        mode: .full,
        maxLines: nil,
        actionLabel: nil
    )

    enum CodingKeys: String, CodingKey {
        case mode
        case maxLines = "max_lines"
        case actionLabel = "action_label"
    }
}

struct NewsSegmentLink: Codable, Identifiable, Equatable, Sendable {
    let id: Int
    let position: Int
    let kind: NewsSegmentLinkKind
    let label: String
    let url: URL
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
    let links: [NewsSegmentLink]
    let presentation: NewsSegmentPresentation

    enum CodingKeys: String, CodingKey {
        case id, position, type, text, media, links, presentation
        case stableKey = "stable_key"
        case authorName = "author_name"
        case authorHandle = "author_handle"
        case publishedAt = "published_at"
        case publishedAtSourceText = "published_at_source_text"
        case sourceURL = "source_url"
        case isExcerpt = "is_excerpt"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        stableKey = try container.decode(String.self, forKey: .stableKey)
        position = try container.decode(Int.self, forKey: .position)
        type = try container.decode(NewsSegmentType.self, forKey: .type)
        authorName = try container.decodeIfPresent(String.self, forKey: .authorName)
        authorHandle = try container.decodeIfPresent(String.self, forKey: .authorHandle)
        publishedAt = try container.decodeIfPresent(Date.self, forKey: .publishedAt)
        publishedAtSourceText = try container.decodeIfPresent(
            String.self, forKey: .publishedAtSourceText
        )
        text = try container.decode(LocalizedText.self, forKey: .text)
        sourceURL = try container.decodeIfPresent(URL.self, forKey: .sourceURL)
        isExcerpt = try container.decode(Bool.self, forKey: .isExcerpt)
        media = try container.decode([NewsMedia].self, forKey: .media)
        links = try container.decodeIfPresent([NewsSegmentLink].self, forKey: .links) ?? []
        presentation = try container.decodeIfPresent(
            NewsSegmentPresentation.self,
            forKey: .presentation
        ) ?? .full
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
    let sourceTimeText: String?
    let sourcePosition: Int
    let updatedAt: Date

    var id: String { sourceID }

    enum CodingKeys: String, CodingKey {
        case sourceID = "source_id"
        case eventAt = "event_at"
        case currency, impact
        case titleEN = "title_en"
        case titleZH = "title_zh"
        case actual, forecast, previous
        case sourceTimeText = "source_time_text"
        case sourcePosition = "source_position"
        case updatedAt = "updated_at"
    }

    init(
        sourceID: String,
        eventAt: Date,
        currency: String,
        impact: Impact,
        titleEN: String,
        titleZH: String?,
        actual: String?,
        forecast: String?,
        previous: String?,
        updatedAt: Date,
        sourceTimeText: String? = nil,
        sourcePosition: Int = 0
    ) {
        self.sourceID = sourceID
        self.eventAt = eventAt
        self.currency = currency
        self.impact = impact
        self.titleEN = titleEN
        self.titleZH = titleZH
        self.actual = actual
        self.forecast = forecast
        self.previous = previous
        self.sourceTimeText = sourceTimeText
        self.sourcePosition = sourcePosition
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sourceID = try container.decode(String.self, forKey: .sourceID)
        eventAt = try container.decode(Date.self, forKey: .eventAt)
        currency = try container.decode(String.self, forKey: .currency)
        impact = try container.decode(Impact.self, forKey: .impact)
        titleEN = try container.decode(String.self, forKey: .titleEN)
        titleZH = try container.decodeIfPresent(String.self, forKey: .titleZH)
        actual = try container.decodeIfPresent(String.self, forKey: .actual)
        forecast = try container.decodeIfPresent(String.self, forKey: .forecast)
        previous = try container.decodeIfPresent(String.self, forKey: .previous)
        sourceTimeText = try container.decodeIfPresent(String.self, forKey: .sourceTimeText)
        sourcePosition = try container.decodeIfPresent(Int.self, forKey: .sourcePosition) ?? 0
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

struct CalendarHistoryEntry: Codable, Identifiable, Equatable, Sendable {
    let releaseDateText: String
    let eventURL: URL?
    let actual: String?
    let forecast: String?
    let previous: String?
    let actualState: CalendarValueState?
    let previousState: CalendarValueState?
    let previousRevisedFrom: String?

    var id: String { [releaseDateText, eventURL?.absoluteString ?? ""].joined(separator: "|") }

    enum CodingKeys: String, CodingKey {
        case releaseDateText = "release_date_text"
        case eventURL = "event_url"
        case actual, forecast, previous
        case actualState = "actual_state"
        case previousState = "previous_state"
        case previousRevisedFrom = "previous_revised_from"
    }
}

struct CalendarRelatedStory: Codable, Identifiable, Equatable, Sendable {
    let titleEN: String
    let ffURL: URL
    let sourceName: String?
    let sourceURL: URL?
    let publishedAtSourceText: String?
    let preview: String?

    var id: URL { ffURL }

    enum CodingKeys: String, CodingKey {
        case titleEN = "title_en"
        case ffURL = "ff_url"
        case sourceName = "source_name"
        case sourceURL = "source_url"
        case publishedAtSourceText = "published_at_source_text"
        case preview
    }
}

struct CalendarDetail: Codable, Identifiable, Equatable, Sendable {
    let sourceID: String
    let titleEN: String
    let currency: String?
    let currencyName: String?
    let impact: Impact?
    let actual: String?
    let forecast: String?
    let previous: String?
    let actualState: CalendarValueState?
    let previousState: CalendarValueState?
    let previousRevisedFrom: String?
    let ffURL: URL?
    let sourceName: String?
    let sourceURL: URL?
    let latestReleaseURL: URL?
    let measures: String?
    let usualEffect: String?
    let frequency: String?
    let nextReleaseText: String?
    let nextReleaseURL: URL?
    let ffNotes: String?
    let whyTradersCare: String?
    let history: [CalendarHistoryEntry]
    let relatedStories: [CalendarRelatedStory]
    let updatedAt: Date

    var id: String { sourceID }

    enum CodingKeys: String, CodingKey {
        case sourceID = "source_id"
        case titleEN = "title_en"
        case currency
        case currencyName = "currency_name"
        case impact
        case actual, forecast, previous
        case actualState = "actual_state"
        case previousState = "previous_state"
        case previousRevisedFrom = "previous_revised_from"
        case ffURL = "ff_url"
        case sourceName = "source_name"
        case sourceURL = "source_url"
        case latestReleaseURL = "latest_release_url"
        case measures
        case usualEffect = "usual_effect"
        case frequency
        case nextReleaseText = "next_release_text"
        case nextReleaseURL = "next_release_url"
        case ffNotes = "ff_notes"
        case whyTradersCare = "why_traders_care"
        case history
        case relatedStories = "related_stories"
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
typealias BinanceContractsEnvelope = ListEnvelope<BinanceFuturesContract>

enum ContractMarketFilter: String, CaseIterable, Identifiable, Codable, Sendable {
    case all
    case crypto
    case traditional

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .crypto: "Crypto"
        case .traditional: "Traditional"
        }
    }
}

struct BinanceFuturesContract: Codable, Identifiable, Equatable, Sendable {
    let symbol: String
    let pair: String
    let contractType: String
    let marketType: String
    let underlyingType: String
    let underlyingSubtypes: [String]
    let status: String
    let baseAsset: String
    let quoteAsset: String
    let marginAsset: String
    let lastPrice: Double
    let weightedAvgPrice: Double
    let priceChange: Double
    let priceChangePercent: Double
    let highPrice: Double
    let lowPrice: Double
    let openPrice: Double
    let volume: Double
    let quoteVolume: Double
    let count: Int
    let volatilityPercent: Double?
    let updatedAt: Date

    var id: String { symbol }

    enum CodingKeys: String, CodingKey {
        case symbol, pair, status, count
        case contractType = "contract_type"
        case marketType = "market_type"
        case underlyingType = "underlying_type"
        case underlyingSubtypes = "underlying_subtypes"
        case baseAsset = "base_asset"
        case quoteAsset = "quote_asset"
        case marginAsset = "margin_asset"
        case lastPrice = "last_price"
        case weightedAvgPrice = "weighted_avg_price"
        case priceChange = "price_change"
        case priceChangePercent = "price_change_percent"
        case highPrice = "high_price"
        case lowPrice = "low_price"
        case openPrice = "open_price"
        case volume
        case quoteVolume = "quote_volume"
        case volatilityPercent = "volatility_percent"
        case updatedAt = "updated_at"
    }
}

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
