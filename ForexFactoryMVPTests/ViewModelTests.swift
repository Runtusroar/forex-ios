import Foundation
import XCTest
@testable import ForexFactoryMVP

private actor StubForexAPI: ForexAPI {
    struct ArticleCall: Equatable, Sendable {
        let section: NewsSectionID
        let impact: Impact?
        let cursor: String?
    }

    private var calendarEnvelope: CalendarEnvelope
    private var articlePages: [String: NewsArticlesEnvelope] = [:]
    private var commentsEnvelope = NewsCommentsEnvelope(
        items: [], nextCursor: nil, commentsComplete: false, generatedAt: Date(timeIntervalSince1970: 1)
    )
    private(set) var articleCalls: [ArticleCall] = []
    private(set) var latestCommentCalls = 0
    private var shouldFail = false

    init(calendar: CalendarEnvelope) {
        calendarEnvelope = calendar
    }

    func setShouldFail(_ value: Bool) { shouldFail = value }

    func setArticlePage(
        section: NewsSectionID,
        impact: Impact? = nil,
        cursor: String? = nil,
        envelope: NewsArticlesEnvelope
    ) {
        articlePages[key(section: section, impact: impact, cursor: cursor)] = envelope
    }

    func setLatestComments(_ envelope: NewsCommentsEnvelope) {
        commentsEnvelope = envelope
    }

    func calls() -> [ArticleCall] { articleCalls }

    func latestCommentCallCount() -> Int { latestCommentCalls }

    func calendar(from start: Date, to end: Date) async throws -> CalendarEnvelope {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return calendarEnvelope
    }

    func news(limit: Int) async throws -> NewsEnvelope {
        NewsEnvelope(items: [], generatedAt: Date(timeIntervalSince1970: 1))
    }

    func newsDetail(id: String) async throws -> NewsItem { throw APIError.notFound }

    func newsSections() async throws -> NewsSectionsEnvelope {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return NewsSectionsEnvelope(items: sampleSections(), generatedAt: Date(timeIntervalSince1970: 300))
    }

    func news(
        section: NewsSectionID,
        impact: Impact?,
        limit: Int,
        cursor: String?
    ) async throws -> NewsArticlesEnvelope {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        articleCalls.append(ArticleCall(section: section, impact: impact, cursor: cursor))
        return articlePages[key(section: section, impact: impact, cursor: cursor)]
            ?? NewsArticlesEnvelope(
                items: [], nextCursor: nil, generatedAt: Date(timeIntervalSince1970: 300)
            )
    }

    func newsV2Detail(id: String) async throws -> NewsArticleDetail { throw APIError.notFound }

    func latestComments(limit: Int, cursor: String?) async throws -> NewsCommentsEnvelope {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        latestCommentCalls += 1
        return commentsEnvelope
    }

    func articleComments(
        id: String,
        limit: Int,
        cursor: String?
    ) async throws -> NewsCommentsEnvelope {
        commentsEnvelope
    }

    func mediaData(path: String) async throws -> Data { Data() }

    func status() async throws -> ServiceStatus {
        ServiceStatus(status: "ok", model: "k3-256k")
    }

    private func key(section: NewsSectionID, impact: Impact?, cursor: String?) -> String {
        "\(section.rawValue)|\(impact?.rawValue ?? "all")|\(cursor ?? "first")"
    }
}

final class ViewModelTests: XCTestCase {
    @MainActor
    func testCalendarFailurePreservesLastGoodRows() async throws {
        let event = sampleEvent(id: "calendar-1")
        let api = StubForexAPI(
            calendar: CalendarEnvelope(items: [event], generatedAt: event.updatedAt)
        )
        let cache = ResponseCache(directory: temporaryDirectory())
        let model = CalendarViewModel(api: api, cache: cache)

        await model.refresh()
        await api.setShouldFail(true)
        await model.refresh()

        XCTAssertEqual(model.events, [event])
        XCTAssertEqual(model.errorMessage, "Unable to refresh. Showing saved data.")
    }

    @MainActor
    func testNewsSectionsKeepIndependentVisibleRows() async throws {
        let api = StubForexAPI(calendar: CalendarEnvelope(items: [], generatedAt: .distantPast))
        let latest = sampleArticle(id: "latest", date: 200)
        let technical = sampleArticle(id: "technical", date: 100)
        await api.setArticlePage(
            section: .latest,
            envelope: NewsArticlesEnvelope(
                items: [latest], nextCursor: nil, generatedAt: latest.publishedAt!
            )
        )
        await api.setArticlePage(
            section: .technical,
            envelope: NewsArticlesEnvelope(
                items: [technical], nextCursor: nil, generatedAt: technical.publishedAt!
            )
        )
        let model = NewsViewModel(api: api, cache: ResponseCache(directory: temporaryDirectory()))

        await model.refresh()
        XCTAssertEqual(model.currentArticles.map(\.sourceID), ["latest"])
        await model.select(.technical)
        XCTAssertEqual(model.currentArticles.map(\.sourceID), ["technical"])
        await model.select(.latest)
        XCTAssertEqual(model.currentArticles.map(\.sourceID), ["latest"])
        XCTAssertEqual(model.sections.count, 8)
    }

    @MainActor
    func testNewsPaginationUsesOpaqueCursorAndDeduplicatesRows() async throws {
        let api = StubForexAPI(calendar: CalendarEnvelope(items: [], generatedAt: .distantPast))
        let a = sampleArticle(id: "a", date: 300)
        let b = sampleArticle(id: "b", date: 200)
        let c = sampleArticle(id: "c", date: 100)
        await api.setArticlePage(
            section: .latest,
            envelope: NewsArticlesEnvelope(items: [a, b], nextCursor: "opaque-next", generatedAt: .now)
        )
        await api.setArticlePage(
            section: .latest,
            cursor: "opaque-next",
            envelope: NewsArticlesEnvelope(items: [b, c], nextCursor: nil, generatedAt: .now)
        )
        let model = NewsViewModel(api: api, cache: ResponseCache(directory: temporaryDirectory()))

        await model.refresh()
        await model.loadMore()
        await model.loadMore()

        XCTAssertEqual(model.currentArticles.map(\.sourceID), ["a", "b", "c"])
        XCTAssertFalse(model.canLoadMore)
        let cursors = await api.calls().map(\.cursor)
        XCTAssertEqual(cursors, [nil, "opaque-next"])
    }

    @MainActor
    func testLatestCommentsAndImpactFilterUseSeparateEndpoints() async throws {
        let api = StubForexAPI(calendar: CalendarEnvelope(items: [], generatedAt: .distantPast))
        await api.setLatestComments(
            NewsCommentsEnvelope(
                items: [sampleComment()],
                nextCursor: nil,
                commentsComplete: false,
                generatedAt: .now
            )
        )
        let high = sampleArticle(id: "high", date: 400, impact: .high)
        await api.setArticlePage(
            section: .latest,
            impact: .high,
            envelope: NewsArticlesEnvelope(items: [high], nextCursor: nil, generatedAt: .now)
        )
        let model = NewsViewModel(api: api, cache: ResponseCache(directory: temporaryDirectory()))

        await model.select(.latestComments)
        XCTAssertEqual(model.currentComments.map(\.commentID), ["comment-1"])
        await model.select(.latest)
        await model.setImpactFilter(.high)

        XCTAssertEqual(model.currentArticles.map(\.sourceID), ["high"])
        let latestCommentCalls = await api.latestCommentCallCount()
        let lastImpact = await api.calls().last?.impact
        XCTAssertEqual(latestCommentCalls, 1)
        XCTAssertEqual(lastImpact, .high)
    }

    @MainActor
    func testNewsRefreshFailurePreservesLastGoodRows() async throws {
        let api = StubForexAPI(calendar: CalendarEnvelope(items: [], generatedAt: .distantPast))
        let article = sampleArticle(id: "saved", date: 100)
        await api.setArticlePage(
            section: .latest,
            envelope: NewsArticlesEnvelope(items: [article], nextCursor: nil, generatedAt: .now)
        )
        let model = NewsViewModel(api: api, cache: ResponseCache(directory: temporaryDirectory()))

        await model.refresh()
        await api.setShouldFail(true)
        await model.refresh()

        XCTAssertEqual(model.currentArticles.map(\.sourceID), ["saved"])
        XCTAssertEqual(model.errorMessage, "Unable to refresh. Showing saved data.")
    }
}

private func temporaryDirectory() -> URL {
    FileManager.default.temporaryDirectory
        .appending(path: UUID().uuidString, directoryHint: .isDirectory)
}

private func sampleEvent(id: String) -> CalendarEvent {
    CalendarEvent(
        sourceID: id,
        eventAt: Date(timeIntervalSince1970: 200),
        currency: "USD",
        impact: .high,
        titleEN: "Employment report",
        titleZH: "就业报告",
        actual: nil,
        forecast: "100K",
        previous: "90K",
        updatedAt: Date(timeIntervalSince1970: 201)
    )
}

private func sampleArticle(
    id: String,
    date: TimeInterval,
    impact: Impact? = nil
) -> NewsArticleSummary {
    NewsArticleSummary(
        sourceID: id,
        ffURL: URL(string: "https://www.forexfactory.com/news/\(id)")!,
        title: LocalizedText(en: "Article \(id)", zhHans: "新闻 \(id)"),
        teaser: LocalizedText(en: "Summary", zhHans: "摘要"),
        sourceName: "Reuters",
        sourceURL: nil,
        publishedAt: Date(timeIntervalSince1970: date),
        publishedAtSourceText: nil,
        sourceTimezone: "Asia/Shanghai",
        breakingImpact: impact,
        commentCount: 2,
        detailState: .complete,
        isExcerpt: false,
        thumbnailURL: nil,
        categories: []
    )
}

private func sampleComment() -> NewsComment {
    NewsComment(
        commentID: "comment-1",
        articleID: "article-1",
        parentCommentID: nil,
        authorName: "Alice",
        publishedAt: Date(timeIntervalSince1970: 100),
        publishedAtSourceText: nil,
        text: LocalizedText(en: "Useful", zhHans: "有用"),
        permalink: URL(string: "https://www.forexfactory.com/comment/1")!,
        reactionCount: 3
    )
}

private func sampleSections() -> [NewsSection] {
    NewsSectionID.allCases.map {
        NewsSection(
            id: $0,
            name: LocalizedText(en: $0.rawValue, zhHans: nil),
            itemCount: 1,
            supportsImpactFilter: $0 != .latestComments
        )
    }
}
