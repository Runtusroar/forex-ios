import Foundation
import XCTest
@testable import ForexFactoryMVP

private actor StubForexAPI: ForexAPI {
    struct CalendarCall: Equatable, Sendable {
        let start: Date
        let end: Date
    }

    struct ArticleCall: Equatable, Sendable {
        let section: NewsSectionID
        let impact: Impact?
        let cursor: String?
    }

    private var calendarEnvelope: CalendarEnvelope
    private var calendarDetails: [String: CalendarDetail] = [:]
    private var topContractsEnvelopes: [ContractMarketFilter: BinanceContractsEnvelope]
    private var articlePages: [String: NewsArticlesEnvelope] = [:]
    private var newsDelays: [NewsSectionID: Duration] = [:]
    private var commentsEnvelope = NewsCommentsEnvelope(
        items: [], nextCursor: nil, commentsComplete: false, generatedAt: Date(timeIntervalSince1970: 1)
    )
    private(set) var articleCalls: [ArticleCall] = []
    private(set) var calendarCalls: [CalendarCall] = []
    private(set) var contractCalls: [ContractMarketFilter] = []
    private(set) var latestCommentCalls = 0
    private var shouldFail = false

    init(
        calendar: CalendarEnvelope,
        topContracts: BinanceContractsEnvelope = BinanceContractsEnvelope(
            items: [], generatedAt: Date(timeIntervalSince1970: 0)
        )
    ) {
        calendarEnvelope = calendar
        topContractsEnvelopes = [.all: topContracts]
    }

    func setShouldFail(_ value: Bool) { shouldFail = value }

    func setTopContracts(
        _ envelope: BinanceContractsEnvelope,
        for marketType: ContractMarketFilter
    ) {
        topContractsEnvelopes[marketType] = envelope
    }

    func setCalendarDetail(_ detail: CalendarDetail) {
        calendarDetails[detail.sourceID] = detail
    }

    func setArticlePage(
        section: NewsSectionID,
        impact: Impact? = nil,
        cursor: String? = nil,
        envelope: NewsArticlesEnvelope
    ) {
        articlePages[key(section: section, impact: impact, cursor: cursor)] = envelope
    }

    func setNewsDelay(_ delay: Duration, for section: NewsSectionID) {
        newsDelays[section] = delay
    }

    func setLatestComments(_ envelope: NewsCommentsEnvelope) {
        commentsEnvelope = envelope
    }

    func calls() -> [ArticleCall] { articleCalls }

    func requestedCalendarRanges() -> [CalendarCall] { calendarCalls }

    func latestCommentCallCount() -> Int { latestCommentCalls }

    func requestedContractMarkets() -> [ContractMarketFilter] { contractCalls }

    func calendar(from start: Date, to end: Date) async throws -> CalendarEnvelope {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        calendarCalls.append(CalendarCall(start: start, end: end))
        return calendarEnvelope
    }

    func calendarDetail(id: String) async throws -> CalendarDetail {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        guard let detail = calendarDetails[id] else { throw APIError.notFound }
        return detail
    }

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
        if let delay = newsDelays[section] {
            try await Task.sleep(for: delay)
        }
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

    func topContracts(limit: Int, marketType: ContractMarketFilter) async throws -> BinanceContractsEnvelope {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        contractCalls.append(marketType)
        return topContractsEnvelopes[marketType]
            ?? BinanceContractsEnvelope(items: [], generatedAt: Date(timeIntervalSince1970: 0))
    }

    func status() async throws -> ServiceStatus {
        ServiceStatus(status: "ok", model: "k3-256k")
    }

    private func key(section: NewsSectionID, impact: Impact?, cursor: String?) -> String {
        "\(section.rawValue)|\(impact?.rawValue ?? "all")|\(cursor ?? "first")"
    }
}

final class ViewModelTests: XCTestCase {
    @MainActor
    func testCalendarRequestAlwaysUsesEightUTCPlusEightDays() async throws {
        let api = StubForexAPI(
            calendar: CalendarEnvelope(items: [], generatedAt: .distantPast)
        )
        let now = ISO8601DateFormatter().date(from: "2026-09-04T18:30:00Z")!
        let expectedStart = ISO8601DateFormatter().date(from: "2026-09-04T16:00:00Z")!
        let expectedEnd = ISO8601DateFormatter().date(from: "2026-09-12T16:00:00Z")!
        let model = CalendarViewModel(
            api: api,
            cache: ResponseCache(directory: temporaryDirectory()),
            now: { now }
        )

        await model.refresh()

        let requestedRanges = await api.requestedCalendarRanges()
        let call = try XCTUnwrap(requestedRanges.first)
        XCTAssertEqual(call.start, expectedStart)
        XCTAssertEqual(call.end, expectedEnd)
    }

    @MainActor
    func testCalendarDetailLoadsThroughInjectedAPI() async throws {
        let api = StubForexAPI(
            calendar: CalendarEnvelope(
                items: [sampleEvent(id: "149673")],
                generatedAt: Date(timeIntervalSince1970: 300)
            )
        )
        await api.setCalendarDetail(sampleCalendarDetail(id: "149673"))
        let model = CalendarViewModel(api: api, cache: ResponseCache(directory: temporaryDirectory()))

        let detail = try await model.detail(for: sampleEvent(id: "149673"))

        XCTAssertEqual(detail.sourceID, "149673")
        XCTAssertEqual(detail.sourceName, "METI")
        XCTAssertEqual(detail.history[0].releaseDateText, "Aug 31, 2026")
    }

    @MainActor
    func testCalendarCachedTimestampDoesNotAdvanceOnFailedRefresh() async throws {
        let stamp = Date(timeIntervalSince1970: 1_788_590_109)
        let api = StubForexAPI(calendar: CalendarEnvelope(items: [], generatedAt: .now))
        await api.setShouldFail(true)
        let cache = ResponseCache(directory: temporaryDirectory())
        try await cache.save(CalendarEnvelope(items: [], generatedAt: stamp), as: .calendar)
        let model = CalendarViewModel(api: api, cache: cache)
        XCTAssertNil(model.lastUpdatedAt)
        await model.loadCachedData()
        XCTAssertEqual(model.lastUpdatedAt, stamp)
        await model.refresh()
        XCTAssertEqual(model.lastUpdatedAt, stamp)
    }

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
        XCTAssertEqual(model.lastUpdatedAt, event.updatedAt)
        XCTAssertEqual(model.errorMessage, "Unable to refresh. Showing saved data.")
    }

    @MainActor
    func testNewsTimestampRetainsCachedDataAgeOnFailureAndChangesWithCommentFeed() async throws {
        let cachedDate = Date(timeIntervalSince1970: 100)
        let commentDate = Date(timeIntervalSince1970: 200)
        let api = StubForexAPI(calendar: CalendarEnvelope(items: [], generatedAt: .distantPast))
        let cache = ResponseCache(directory: temporaryDirectory())
        try await cache.save(NewsArticlesEnvelope(items: [], nextCursor: nil, generatedAt: cachedDate), as: .news(section: .latest, impact: nil))
        let model = NewsViewModel(api: api, cache: cache)
        XCTAssertNil(model.lastUpdatedAt)
        await model.loadCachedData()
        XCTAssertEqual(model.lastUpdatedAt, cachedDate)
        await api.setShouldFail(true)
        await model.refresh()
        XCTAssertEqual(model.lastUpdatedAt, cachedDate)
        await api.setShouldFail(false)
        await api.setLatestComments(NewsCommentsEnvelope(items: [], nextCursor: nil, commentsComplete: true, generatedAt: commentDate))
        await model.select(.latestComments)
        XCTAssertEqual(model.lastUpdatedAt, commentDate)
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
        XCTAssertEqual(model.lastUpdatedAt, latest.publishedAt)
        await model.select(.technical)
        XCTAssertEqual(model.currentArticles.map(\.sourceID), ["technical"])
        XCTAssertEqual(model.lastUpdatedAt, technical.publishedAt)
        await model.select(.latest)
        XCTAssertEqual(model.currentArticles.map(\.sourceID), ["latest"])
        XCTAssertEqual(model.lastUpdatedAt, latest.publishedAt)
        XCTAssertEqual(model.sections.count, 8)
    }

    @MainActor
    func testNewsPreservesServerRankingForArticlesAndComments() async throws {
        let api = StubForexAPI(calendar: CalendarEnvelope(items: [], generatedAt: .distantPast))
        let rankedFirst = sampleArticle(id: "rank-1", date: 100)
        let newerSecond = sampleArticle(id: "rank-2", date: 200)
        await api.setArticlePage(
            section: .latest,
            envelope: NewsArticlesEnvelope(
                items: [rankedFirst, newerSecond], nextCursor: nil, generatedAt: .now
            )
        )
        await api.setLatestComments(
            NewsCommentsEnvelope(
                items: [
                    sampleComment(id: "comment-rank-1", date: 100),
                    sampleComment(id: "comment-rank-2", date: 200),
                ],
                nextCursor: nil,
                commentsComplete: false,
                generatedAt: .now
            )
        )
        let model = NewsViewModel(api: api, cache: ResponseCache(directory: temporaryDirectory()))

        await model.refresh()
        XCTAssertEqual(model.currentArticles.map(\.sourceID), ["rank-1", "rank-2"])
        await model.select(.latestComments)
        XCTAssertEqual(
            model.currentComments.map(\.commentID),
            ["comment-rank-1", "comment-rank-2"]
        )
    }

    @MainActor
    func testNewsSectionCanRefreshWhilePreviousSectionRequestIsInFlight() async throws {
        let api = StubForexAPI(calendar: CalendarEnvelope(items: [], generatedAt: .distantPast))
        await api.setArticlePage(
            section: .latest,
            envelope: NewsArticlesEnvelope(
                items: [sampleArticle(id: "latest", date: 100)],
                nextCursor: nil,
                generatedAt: .now
            )
        )
        await api.setArticlePage(
            section: .technical,
            envelope: NewsArticlesEnvelope(
                items: [sampleArticle(id: "technical", date: 200)],
                nextCursor: nil,
                generatedAt: .now
            )
        )
        await api.setNewsDelay(.milliseconds(100), for: .latest)
        let model = NewsViewModel(api: api, cache: ResponseCache(directory: temporaryDirectory()))

        let latestRefresh = Task { await model.refresh() }
        while await api.calls().isEmpty { await Task.yield() }
        await model.select(.technical)
        await latestRefresh.value

        XCTAssertEqual(model.currentArticles.map(\.sourceID), ["technical"])
        let sections = await api.calls().map(\.section)
        XCTAssertEqual(sections, [.latest, .technical])
    }

    func testRootTabRefreshPolicyOnlyActivatesVisibleDataTab() {
        XCTAssertEqual(
            RootTabRefreshPolicy.activeDataTab(selected: .news, appIsActive: true),
            .news
        )
        XCTAssertNil(
            RootTabRefreshPolicy.activeDataTab(selected: .settings, appIsActive: true)
        )
        XCTAssertNil(
            RootTabRefreshPolicy.activeDataTab(selected: .calendar, appIsActive: false)
        )
    }

    @MainActor
    func testContractsRefreshSortsByQuoteVolumeAndCaches() async throws {
        let small = sampleContract(symbol: "BTCUSDT", quoteVolume: 102_000_000)
        let large = sampleContract(symbol: "ETHUSDT", quoteVolume: 197_500_000)
        let generatedAt = Date(timeIntervalSince1970: 1_788_524_400)
        let api = StubForexAPI(
            calendar: CalendarEnvelope(items: [], generatedAt: generatedAt),
            topContracts: BinanceContractsEnvelope(items: [small, large], generatedAt: generatedAt)
        )
        let cache = ResponseCache(directory: temporaryDirectory())
        let model = ContractsViewModel(api: api, cache: cache)

        await model.refresh()
        let cached = try await cache.load(
            .contracts(marketType: .all),
            as: BinanceContractsEnvelope.self
        )

        XCTAssertEqual(model.contracts.map(\.symbol), ["ETHUSDT", "BTCUSDT"])
        XCTAssertEqual(model.lastUpdatedAt, generatedAt)
        XCTAssertEqual(cached?.items.count, 2)
        let requestedMarkets = await api.requestedContractMarkets()
        XCTAssertEqual(requestedMarkets, [.all])
    }

    @MainActor
    func testContractsMarketSelectionRequestsSeparateMarketTypeAndCachesEmptyTraditional() async throws {
        let all = BinanceContractsEnvelope(
            items: [sampleContract(symbol: "BTCUSDT", quoteVolume: 102_000_000)],
            generatedAt: Date(timeIntervalSince1970: 1_788_524_400)
        )
        let traditional = BinanceContractsEnvelope(
            items: [],
            generatedAt: Date(timeIntervalSince1970: 1_788_524_500)
        )
        let api = StubForexAPI(
            calendar: CalendarEnvelope(items: [], generatedAt: all.generatedAt),
            topContracts: all
        )
        await api.setTopContracts(traditional, for: .traditional)
        let cache = ResponseCache(directory: temporaryDirectory())
        let model = ContractsViewModel(api: api, cache: cache)

        await model.refresh()
        await model.select(.traditional)
        let cached = try await cache.load(
            .contracts(marketType: .traditional),
            as: BinanceContractsEnvelope.self
        )

        XCTAssertEqual(model.selectedMarket, .traditional)
        XCTAssertTrue(model.contracts.isEmpty)
        XCTAssertEqual(model.lastUpdatedAt, traditional.generatedAt)
        XCTAssertEqual(cached?.generatedAt, traditional.generatedAt)
        let requestedMarkets = await api.requestedContractMarkets()
        XCTAssertEqual(requestedMarkets, [.all, .traditional])
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

private func sampleCalendarDetail(id: String) -> CalendarDetail {
    CalendarDetail(
        sourceID: id,
        titleEN: "Prelim Industrial Production m/m",
        currency: "JPY",
        currencyName: "Japanese yen",
        impact: .low,
        actual: "0.1%",
        forecast: "-0.7%",
        previous: "1.9%",
        actualState: .better,
        previousState: .better,
        previousRevisedFrom: "1.3%",
        ffURL: URL(string: "https://www.forexfactory.com/calendar/225-jn-prelim-industrial-production-mm"),
        sourceName: "METI",
        sourceURL: URL(string: "https://www.meti.go.jp/english/"),
        latestReleaseURL: nil,
        measures: "Change in total output;",
        usualEffect: "'Actual' greater than 'Forecast' is good for currency;",
        frequency: "Released monthly;",
        nextReleaseText: "Sep 30, 2026",
        nextReleaseURL: URL(string: "https://www.forexfactory.com/calendar?day=sep30.2026#detail=149674"),
        ffNotes: nil,
        whyTradersCare: "It is a leading indicator;",
        history: [
            CalendarHistoryEntry(
                releaseDateText: "Aug 31, 2026",
                eventURL: URL(string: "https://www.forexfactory.com/calendar?day=aug31.2026#detail=149673"),
                actual: "0.1%",
                forecast: "-0.7%",
                previous: "1.9%",
                actualState: .better,
                previousState: .better,
                previousRevisedFrom: "1.3%"
            )
        ],
        relatedStories: [],
        updatedAt: Date(timeIntervalSince1970: 400)
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

private func sampleComment(
    id: String = "comment-1",
    date: TimeInterval = 100
) -> NewsComment {
    NewsComment(
        commentID: id,
        articleID: "article-1",
        parentCommentID: nil,
        authorName: "Alice",
        publishedAt: Date(timeIntervalSince1970: date),
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

private func sampleContract(symbol: String, quoteVolume: Double) -> BinanceFuturesContract {
    BinanceFuturesContract(
        symbol: symbol,
        pair: symbol,
        contractType: "PERPETUAL",
        marketType: "crypto",
        underlyingType: "COIN",
        underlyingSubtypes: ["Layer 1"],
        status: "TRADING",
        baseAsset: String(symbol.dropLast(4)),
        quoteAsset: "USDT",
        marginAsset: "USDT",
        lastPrice: 102_000,
        weightedAvgPrice: 101_000,
        priceChange: 100,
        priceChangePercent: 2.5,
        highPrice: 110_000,
        lowPrice: 95_000,
        openPrice: 100_000,
        volume: 1_000,
        quoteVolume: quoteVolume,
        count: 100,
        volatilityPercent: 15.0,
        updatedAt: Date(timeIntervalSince1970: 1_788_524_400)
    )
}
