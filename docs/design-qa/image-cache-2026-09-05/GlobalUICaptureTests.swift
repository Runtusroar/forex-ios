import SwiftUI
import UIKit
import XCTest
@testable import ForexFactoryMVP

// Optional native rendering harness. Fixture data, isolated defaults/cache, no credentials/network.
final class GlobalUICaptureTests: XCTestCase {
    @MainActor
    func testCaptureGlobalDesign() async throws {
        let api = DesignAPI()
        let cache = ResponseCache(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
        let calendar = CalendarViewModel(api: api, cache: cache)
        calendar.events = DesignFixtures.events
        calendar.lastUpdatedAt = DesignFixtures.date
        let news = NewsViewModel(api: api, cache: cache)
        try await cache.save(NewsArticlesEnvelope(items: DesignFixtures.articles, nextCursor: nil, generatedAt: DesignFixtures.date), as: .news(section: .latest, impact: nil))
        await news.loadCachedData()
        news.staleSince = nil
        let contracts = ContractsViewModel(api: api, cache: cache)
        contracts.contracts = DesignFixtures.contracts
        contracts.lastUpdatedAt = DesignFixtures.date
        let defaults = UserDefaults(suiteName: "design-capture-\(UUID().uuidString)")!
        let settings = AppSettings(defaults: defaults, keyStore: DesignKeyStore())
        settings.baseURLText = "https://api.example.com"
        func app(_ tab: RootTab) -> some View {
            RootTabView(settings: settings, calendarModel: calendar, newsModel: news, contractsModel: contracts, initialTab: tab)
                .environment(\.scenePhase, .inactive)
        }
        for (index, tab) in RootTab.allCases.enumerated() {
            try await capture(app(tab), name: "0\(index + 1)-\(tab.rawValue)-light")
            try await capture(app(tab), name: "0\(index + 1)-\(tab.rawValue)-dark", dark: true)
        }
        func article(_ model: NewsViewModel) -> some View {
            NavigationStack(path: .constant(["article"])) {
                Text("News").navigationTitle("News")
                    .navigationDestination(for: String.self) { _ in
                        NewsDetailView(articleID: "1", summary: DesignFixtures.articles[0], model: model)
                    }
            }
        }
        try await capture(article(news), name: "05-news-article")
        try await capture(article(news), name: "06-news-comments", scrollOffset: 540)
        try await capture(article(news), name: "06-news-comments-dark", dark: true, scrollOffset: 540)
        try await capture(NavigationStack(path: .constant(["event"])) {
            Text("Calendar").navigationTitle("Calendar")
                .navigationDestination(for: String.self) { _ in CalendarDetailView(event: calendar.events[0], model: calendar) }
        }, name: "07-calendar-detail")
        try await capture(app(.calendar).environment(\.dynamicTypeSize, .accessibility1), name: "08-calendar-large-text", width: 375)
        try await capture(app(.contracts).environment(\.dynamicTypeSize, .accessibility1), name: "09-contracts-large-text", width: 375)
        try await capture(app(.settings).environment(\.dynamicTypeSize, .accessibility1), name: "10-settings-large-text", width: 375)
        try await capture(ScrollView {
            NewsCommentCard(comment: DesignFixtures.comments[1], parentAuthor: "Alex Morgan", showsPermalink: true)
                .padding(20)
        }.background(EditorialTheme.paper).environment(\.dynamicTypeSize, .accessibility3), name: "11-comment-large-text", width: 375)
        try await capture(NewsImpactFilterDialog(selectedImpact: .high, onSelect: { _ in }, onDismiss: {})
            .padding(24).frame(maxHeight: .infinity).background(EditorialTheme.subtleSurface), name: "12-impact-filter")
        let empty = CalendarViewModel(api: api, cache: cache)
        empty.errorMessage = "Unable to load the calendar."
        try await capture(CalendarView(model: empty), name: "13-calendar-empty-error")
        let errorNews = NewsViewModel(api: DesignAPI(commentMode: .failed), cache: cache)
        try await capture(article(errorNews), name: "14-comments-error", scrollOffset: 800)
        let emptyNews = NewsViewModel(api: DesignAPI(commentMode: .empty), cache: cache)
        try await capture(article(emptyNews), name: "15-comments-empty", scrollOffset: 800)
        let feed = NewsViewModel(api: api, cache: cache)
        await feed.select(.latestComments)
        try await capture(NewsListView(model: feed), name: "16-comment-feed")
        try await capture(app(.news).environment(\.dynamicTypeSize, .accessibility1), name: "17-news-large-text", width: 375)
        let mismatchNews = NewsViewModel(api: DesignAPI(commentMode: .countMismatch), cache: cache)
        try await capture(article(mismatchNews), name: "18-comments-count-mismatch", scrollOffset: 1200)
    }

    @MainActor
    func testCaptureArticleBoundary() async throws {
        let api = DesignAPI()
        let model = NewsViewModel(api: api, cache: ResponseCache(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)))
        let article = NavigationStack {
            NewsDetailView(articleID: "1", summary: DesignFixtures.articles[0], model: model)
        }
        try await capture(article, name: "19-article-discussion-boundary", scrollOffset: 320)
        try await capture(article, name: "19-article-discussion-boundary-dark", dark: true, scrollOffset: 320)
        try await capture(ScrollView {
            NewsCommentCard(comment: DesignFixtures.comments[1], parentAuthor: "Alex Morgan", showsPermalink: true, bodyFont: .subheadline)
                .padding(20)
        }.background(EditorialTheme.subtleSurface).environment(\.dynamicTypeSize, .accessibility3), name: "20-discussion-large-text", width: 375)
    }

    @MainActor
    func testCaptureBranchingThreads() async throws {
        let comments = [
            DesignFixtures.comment("root", "Alex Morgan", "The revisions are worth watching.", nil, 8),
            DesignFixtures.comment("a", "Taylor Chen", "Agreed. They add context.", "root", 3),
            DesignFixtures.comment("deep", "Jamie Park", "Especially this month.", "a", 1),
            DesignFixtures.comment("b", "Jordan Lee", "I am also watching wages.", "root", 2),
            DesignFixtures.comment("next", "Chris Smith", "The next report will help.", nil, 0)
        ]
        let view = ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SectionBand(title: "Comments", detail: "5")
                NewsCommentThreadView(comments: comments).padding(.horizontal, 20)
            }
        }.background(EditorialTheme.paper)
        try await capture(view, name: "21-branching-thread", width: 393)
        try await capture(view, name: "22-branching-thread-dark", dark: true, width: 393)
        try await capture(view.environment(\.dynamicTypeSize, .accessibility1), name: "23-branching-thread-large", width: 375, scrollOffset: 500)
    }

    @MainActor
    private func capture<V: View>(_ view: V, name: String, dark: Bool = false, width: CGFloat = 402, scrollOffset: CGFloat = 0) async throws {
        let root = UIHostingController(rootView: view.environment(\.colorScheme, dark ? .dark : .light))
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: width, height: 874)
        window.overrideUserInterfaceStyle = dark ? .dark : .light
        window.rootViewController = root
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        root.view.frame = window.bounds
        window.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(650))
        window.layoutIfNeeded()
        if scrollOffset > 0, let scroll = scrollView(in: root.view) {
            let maximum = max(0, scroll.contentSize.height - scroll.bounds.height + scroll.adjustedContentInset.bottom)
            scroll.setContentOffset(CGPoint(x: 0, y: min(scrollOffset, maximum)), animated: false)
            window.layoutIfNeeded()
            try await Task.sleep(for: .milliseconds(200))
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        let output = FileManager.default.temporaryDirectory.appending(path: name + ".png")
        try XCTUnwrap(image.pngData()).write(to: output)
        print("GLOBAL_UI_CAPTURE \(output.path)")
    }

    @MainActor
    private func scrollView(in view: UIView) -> UIScrollView? {
        if let scroll = view as? UIScrollView, scroll.contentSize.height > scroll.bounds.height { return scroll }
        return view.subviews.lazy.compactMap { self.scrollView(in: $0) }.first
    }
}

private enum DesignFixtures {
    static let date = ISO8601DateFormatter().date(from: "2026-09-04T12:30:47Z")!
    static let events: [CalendarEvent] = [
        event("1", "Non-Farm Employment Change", "142K", "165K", "89K"),
        event("2", "Unemployment Rate", "4.2%", "4.2%", "4.3%"),
        event("3", "Average Hourly Earnings m/m", "0.4%", "0.3%", "0.2%"),
        CalendarEvent(sourceID: "4", eventAt: date.addingTimeInterval(86400 * 3), currency: "JPY", impact: .medium, titleEN: "Final GDP q/q", titleZH: "最终国内生产总值季率", actual: nil, forecast: "0.5%", previous: "0.3%", updatedAt: date)
    ]
    static func event(_ id: String, _ title: String, _ actual: String, _ forecast: String, _ previous: String) -> CalendarEvent {
        CalendarEvent(sourceID: id, eventAt: date, currency: "USD", impact: .high, titleEN: title, titleZH: "保留翻译，不显示", actual: actual, forecast: forecast, previous: previous, updatedAt: date)
    }
    static let articles: [NewsArticleSummary] = [
        article("1", "Markets await the next inflation report", "Investors are watching key economic data for signs of the path of interest rates."),
        article("2", "Dollar steadies as traders assess rate outlook", "Major currencies traded in a narrow range as markets weighed the latest employment figures."),
        article("3", "Central banks enter a quieter policy week", "Attention turns to the next round of economic releases and policy speeches.")
    ]
    static func article(_ id: String, _ title: String, _ teaser: String) -> NewsArticleSummary {
        NewsArticleSummary(sourceID: id, ffURL: URL(string: "https://www.forexfactory.com/news/1")!, title: LocalizedText(en: title, zhHans: "保留翻译"), teaser: LocalizedText(en: teaser, zhHans: "保留翻译"), sourceName: "Sample news", sourceURL: nil, publishedAt: date, publishedAtSourceText: nil, sourceTimezone: nil, breakingImpact: nil, commentCount: 12, detailState: .complete, isExcerpt: true, thumbnailURL: nil, categories: [.latest])
    }
    static let contracts: [BinanceFuturesContract] = [
        contract("BTC", 64280.50, 1.42, 24_630_000_000),
        contract("ETH", 2740.80, -0.68, 13_300_000_000),
        contract("SOL", 148.32, 2.16, 6_870_000_000)
    ]
    static func contract(_ base: String, _ price: Double, _ change: Double, _ turnover: Double) -> BinanceFuturesContract {
        BinanceFuturesContract(symbol: base + "USDT", pair: base + "USDT", contractType: "PERPETUAL", marketType: "crypto", underlyingType: "COIN", underlyingSubtypes: [], status: "TRADING", baseAsset: base, quoteAsset: "USDT", marginAsset: "USDT", lastPrice: price, weightedAvgPrice: price, priceChange: 12, priceChangePercent: change, highPrice: price * 1.02, lowPrice: price * 0.98, openPrice: price, volume: turnover / price, quoteVolume: turnover, count: 152834, volatilityPercent: 3.12, updatedAt: date)
    }
    static let comments: [NewsComment] = [
        comment("c1", "Alex Morgan", "The headline matters, but I am watching the revisions and the participation rate before drawing a conclusion.", nil, 8),
        comment("c2", "Taylor Chen", "Agreed. Wage growth adds another piece to the picture, especially when the monthly numbers are volatile.", "c1", 3),
        comment("c3", "Jordan Lee", "A single release rarely changes the broader trend. The next inflation report should offer more context.", nil, 0)
    ]
    static func comment(_ id: String, _ author: String, _ body: String, _ parent: String?, _ reactions: Int) -> NewsComment {
        NewsComment(commentID: id, articleID: "1", parentCommentID: parent, authorName: author, publishedAt: date.addingTimeInterval(600), publishedAtSourceText: nil, text: LocalizedText(en: body, zhHans: "保留翻译"), permalink: URL(string: "https://www.forexfactory.com/news/1#" + id)!, reactionCount: reactions)
    }
}

private struct DesignAPI: ForexAPI {
    enum CommentMode { case loaded, failed, empty, countMismatch }
    var commentMode: CommentMode = .loaded
    func calendar(from start: Date, to end: Date) async throws -> CalendarEnvelope { throw APIError.invalidConfiguration }
    func status() async throws -> ServiceStatus { ServiceStatus(status: "ok", model: "sample") }
    func calendarDetail(id: String) async throws -> CalendarDetail {
        try JSONDecoder.api.decode(CalendarDetail.self, from: Data(#"{"source_id":"1","title_en":"Non-Farm Employment Change","currency":"USD","currency_name":"US dollar","impact":"high","actual":"142K","forecast":"165K","previous":"89K","actual_state":"worse","previous_state":"better","source_name":"Sample release","frequency":"Monthly","measures":"Change in the number of employed people during the previous month, excluding the farming industry.","history":[{"release_date_text":"Aug 7, 2026","actual":"89K","forecast":"100K","previous":"104K","actual_state":"worse"}],"related_stories":[],"updated_at":"2026-09-04T12:30:47Z"}"#.utf8))
    }
    func newsV2Detail(id: String) async throws -> NewsArticleDetail {
        let text = #"{"source_id":"1","ff_url":"https://www.forexfactory.com/news/1","title":{"en":"Markets await the next inflation report","zh_hans":"保留翻译"},"teaser":{"en":"Investors are watching key economic data for signs of the path of interest rates."},"source_name":"Sample news","published_at":"2026-09-04T12:30:47Z","comment_count":12,"detail_state":"complete","is_excerpt":true,"categories":["latest"],"feeds":[],"segments":[{"id":1,"stable_key":"p1","position":0,"type":"article","text":{"en":"Investors are turning their attention to the next inflation report after a mixed set of employment figures. The details of the release may prove more informative than the headline number alone."},"is_excerpt":false,"media":[],"links":[]},{"id":2,"stable_key":"q1","position":1,"type":"quote","text":{"en":"The direction of travel matters more than a single month of data."},"is_excerpt":false,"media":[],"links":[]},{"id":3,"stable_key":"p2","position":2,"type":"article","text":{"en":"Wage growth, participation and revisions will remain in focus. Traders are also watching how the latest figures fit alongside broader measures of demand and price pressure."},"is_excerpt":false,"media":[],"links":[]}],"comment_count_collected":3,"comments_complete":false,"generated_at":"2026-09-04T12:30:47Z"}"#
        let payload = commentMode == .empty ? text.replacingOccurrences(of: "\"comment_count\":12", with: "\"comment_count\":0") : text
        return try JSONDecoder.api.decode(NewsArticleDetail.self, from: Data(payload.utf8))
    }
    func articleComments(id: String, limit: Int, cursor: String?) async throws -> NewsCommentsEnvelope {
        if commentMode == .failed { throw APIError.server }
        return NewsCommentsEnvelope(items: commentMode == .empty ? [] : DesignFixtures.comments, nextCursor: nil, commentsComplete: commentMode == .empty || commentMode == .countMismatch, generatedAt: DesignFixtures.date)
    }
    func latestComments(limit: Int, cursor: String?) async throws -> NewsCommentsEnvelope {
        NewsCommentsEnvelope(items: DesignFixtures.comments, nextCursor: nil, commentsComplete: true, generatedAt: DesignFixtures.date)
    }
}

private struct DesignKeyStore: APIKeyStoring {
    func read() throws -> String? { "illustrative-key-not-a-credential" }
    func save(_ value: String) throws {}
    func delete() throws {}
}
