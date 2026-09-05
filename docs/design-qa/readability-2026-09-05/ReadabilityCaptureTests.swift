import SwiftUI
import UIKit
import XCTest
@testable import ForexFactoryMVP

// Temporary native rendering harness. Sample values are illustrative, not live market data.
final class ReadabilityCaptureTests: XCTestCase {
    @MainActor
    func testExportReadabilityScreens() async throws {
        let cache = ResponseCache(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
        let api = CaptureAPI()
        let model = CalendarViewModel(api: api, cache: cache)
        let day = ISO8601DateFormatter().date(from: "2026-09-04T12:30:00Z")!
        model.events = [
            event("1", day, "USD", .high, "Non-Farm Employment Change", "非农就业人数变化", "142K", "165K", "89K"),
            event("2", day, "USD", .high, "Unemployment Rate", "失业率", "4.2%", "4.2%", "4.3%"),
            event("3", day, "USD", .high, "Average Hourly Earnings m/m", "平均每小时工资月率", "0.4%", "0.3%", "0.2%"),
            event("4", day.addingTimeInterval(86400 * 3), "JPY", .medium, "Final GDP q/q", "最终国内生产总值季率", nil, "0.5%", "0.3%")
        ]
        try await capture(CalendarView(model: model), name: "01-calendar-light", style: .light)
        try await capture(CalendarView(model: model), name: "02-calendar-dark", style: .dark)
        try await capture(CalendarView(model: model).environment(\.dynamicTypeSize, .accessibility1), name: "03-calendar-large-text", style: .light, width: 375)

        let news = NewsViewModel(api: api, cache: cache)
        let items = [
            article("1", "Markets look ahead to the next round of economic data", "市场关注下一轮经济数据", "Investors are watching employment and inflation releases for clues about the path of interest rates.", "投资者关注就业与通胀数据，寻找未来利率路径的线索。", day),
            article("2", "Dollar holds steady as traders assess the outlook", "交易员评估市场前景，美元保持稳定", "Major currencies traded in a narrow range ahead of the next policy update.", "下一次政策更新前，主要货币在窄幅区间内交易。", day)
        ]
        try await cache.save(NewsArticlesEnvelope(items: items, nextCursor: nil, generatedAt: day), as: .news(section: .latest, impact: nil))
        await news.loadCachedData()
        news.staleSince = nil
        try await capture(NewsListView(model: news), name: "04-news-light", style: .light)
        let defaults = UserDefaults(suiteName: "readability-capture-\(UUID().uuidString)")!
        let settings = AppSettings(defaults: defaults, keyStore: CaptureKeyStore())
        try await capture(SettingsView(settings: settings), name: "05-settings-light", style: .light)

        let longEvent = event("5", day, "USD", .unknown, "A long economic event name with an extended bilingual translation", "较长的经济事件名称以及用于验证换行和阅读顺序的中文翻译", "123,456.789B", "123,456.789B", "123,456.789B", "Tentative")
        try await capture(
            ScrollView {
                CalendarEventRow(event: longEvent)
                    .padding(16)
                    .background(EditorialTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                    .padding(20)
            }.background(EditorialTheme.paper).environment(\.dynamicTypeSize, .accessibility3),
            name: "06-long-event-large-text", style: .light, width: 375
        )
        let empty = CalendarViewModel(api: api, cache: cache)
        empty.errorMessage = "Unable to load the calendar."
        try await capture(CalendarView(model: empty), name: "07-calendar-empty-error", style: .light)
        try await capture(NavigationStack { CalendarDetailView(event: model.events[0], model: model) }, name: "08-calendar-detail", style: .light)
    }

    @MainActor
    private func capture<V: View>(_ view: V, name: String, style: UIUserInterfaceStyle, width: CGFloat = 402) async throws {
        let root = UIHostingController(rootView: view.environment(\.colorScheme, style == .dark ? .dark : .light))
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: width, height: 874)
        window.overrideUserInterfaceStyle = style
        window.rootViewController = root
        window.makeKeyAndVisible()
        root.view.frame = window.bounds
        window.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(400))
        window.layoutIfNeeded()
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
        print("READABILITY_CAPTURE \(output.path)")
        window.isHidden = true
    }

    private func event(_ id: String, _ date: Date, _ currency: String, _ impact: Impact, _ en: String, _ zh: String, _ actual: String?, _ forecast: String?, _ previous: String?, _ sourceTimeText: String? = nil) -> CalendarEvent {
        CalendarEvent(sourceID: id, eventAt: date, currency: currency, impact: impact, titleEN: en, titleZH: zh, actual: actual, forecast: forecast, previous: previous, updatedAt: date, sourceTimeText: sourceTimeText)
    }

    private func article(_ id: String, _ en: String, _ zh: String, _ teaserEN: String, _ teaserZH: String, _ date: Date) -> NewsArticleSummary {
        NewsArticleSummary(sourceID: id, ffURL: URL(string: "https://www.forexfactory.com")!, title: LocalizedText(en: en, zhHans: zh), teaser: LocalizedText(en: teaserEN, zhHans: teaserZH), sourceName: "Sample news", sourceURL: nil, publishedAt: date, publishedAtSourceText: nil, sourceTimezone: nil, breakingImpact: nil, commentCount: 12, detailState: .complete, isExcerpt: true, thumbnailURL: nil, categories: [.latest])
    }
}

private struct CaptureAPI: ForexAPI {
    func calendarDetail(id: String) async throws -> CalendarDetail {
        let json = #"{"source_id":"1","title_en":"Non-Farm Employment Change","currency":"USD","currency_name":"US dollar","impact":"high","actual":"142K","forecast":"165K","previous":"89K","actual_state":"worse","previous_state":"better","source_name":"Sample release","frequency":"Monthly","history":[{"release_date_text":"Aug 7, 2026","actual":"89K","forecast":"100K","previous":"104K","actual_state":"worse"}],"related_stories":[],"updated_at":"2026-09-04T12:30:00Z"}"#
        return try JSONDecoder.api.decode(CalendarDetail.self, from: Data(json.utf8))
    }
    func calendar(from start: Date, to end: Date) async throws -> CalendarEnvelope { throw APIError.invalidConfiguration }
    func status() async throws -> ServiceStatus { throw APIError.invalidConfiguration }
}

private struct CaptureKeyStore: APIKeyStoring {
    func read() throws -> String? { nil }
    func save(_ value: String) throws {}
    func delete() throws {}
}
