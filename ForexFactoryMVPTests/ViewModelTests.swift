import Foundation
import XCTest
@testable import ForexFactoryMVP

private actor StubForexAPI: ForexAPI {
    var calendarEnvelope: CalendarEnvelope
    var newsEnvelope: NewsEnvelope
    var shouldFail = false

    init(calendar: CalendarEnvelope, news: NewsEnvelope) {
        calendarEnvelope = calendar
        newsEnvelope = news
    }

    func setShouldFail(_ value: Bool) { shouldFail = value }

    func calendar(from start: Date, to end: Date) async throws -> CalendarEnvelope {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return calendarEnvelope
    }

    func news(limit: Int) async throws -> NewsEnvelope {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return newsEnvelope
    }

    func newsDetail(id: String) async throws -> NewsItem {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        guard let item = newsEnvelope.items.first(where: { $0.sourceID == id }) else {
            throw APIError.notFound
        }
        return item
    }

    func status() async throws -> ServiceStatus {
        ServiceStatus(status: "ok", model: "kimi-k2.6")
    }
}

final class ViewModelTests: XCTestCase {
    @MainActor
    func testCalendarFailurePreservesLastGoodRows() async throws {
        let event = sampleEvent(id: "calendar-1")
        let api = StubForexAPI(
            calendar: CalendarEnvelope(items: [event], generatedAt: event.updatedAt),
            news: NewsEnvelope(items: [], generatedAt: event.updatedAt)
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
    func testNewsRefreshSortsNewestFirstAndCaches() async throws {
        let old = sampleNews(id: "old", date: Date(timeIntervalSince1970: 100))
        let new = sampleNews(id: "new", date: Date(timeIntervalSince1970: 200))
        let api = StubForexAPI(
            calendar: CalendarEnvelope(items: [], generatedAt: new.updatedAt),
            news: NewsEnvelope(items: [old, new], generatedAt: new.updatedAt)
        )
        let cache = ResponseCache(directory: temporaryDirectory())
        let model = NewsViewModel(api: api, cache: cache)

        await model.refresh()
        let cached = try await cache.load(.news, as: NewsEnvelope.self)

        XCTAssertEqual(model.items.map(\.sourceID), ["new", "old"])
        XCTAssertEqual(cached?.items.count, 2)
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

    private func sampleNews(id: String, date: Date) -> NewsItem {
        NewsItem(
            sourceID: id,
            url: URL(string: "https://www.forexfactory.com/news/\(id)")!,
            source: "Reuters",
            publishedAt: date,
            firstSeenAt: date,
            titleEN: "Dollar update \(id)",
            titleZH: "美元更新",
            summaryEN: "English summary",
            summaryZH: "中文摘要",
            bodyEN: "English body",
            bodyZH: "中文正文",
            imageURL: nil,
            updatedAt: date
        )
    }
}
