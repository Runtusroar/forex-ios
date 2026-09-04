import Foundation
import XCTest
@testable import ForexFactoryMVP

private actor StubForexAPI: ForexAPI {
    var calendarEnvelope: CalendarEnvelope
    var newsEnvelope: NewsEnvelope
    var topContractsEnvelope: BinanceContractsEnvelope
    var shouldFail = false

    init(calendar: CalendarEnvelope, news: NewsEnvelope) {
        calendarEnvelope = calendar
        newsEnvelope = news
        topContractsEnvelope = BinanceContractsEnvelope(items: [], generatedAt: Date(timeIntervalSince1970: 0))
    }

    init(
        calendar: CalendarEnvelope,
        news: NewsEnvelope,
        topContracts: BinanceContractsEnvelope
    ) {
        calendarEnvelope = calendar
        newsEnvelope = news
        topContractsEnvelope = topContracts
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

    func topContracts(limit: Int) async throws -> BinanceContractsEnvelope {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return topContractsEnvelope
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

    @MainActor
    func testContractsRefreshSortsByQuoteVolumeAndCaches() async throws {
        let small = sampleContract(symbol: "BTCUSDT", quoteVolume: 102_000_000)
        let large = sampleContract(symbol: "ETHUSDT", quoteVolume: 197_500_000)
        let generatedAt = Date(timeIntervalSince1970: 1_788_524_400)
        let api = StubForexAPI(
            calendar: CalendarEnvelope(items: [], generatedAt: generatedAt),
            news: NewsEnvelope(items: [], generatedAt: generatedAt),
            topContracts: BinanceContractsEnvelope(items: [small, large], generatedAt: generatedAt)
        )
        let cache = ResponseCache(directory: temporaryDirectory())
        let model = ContractsViewModel(api: api, cache: cache)

        await model.refresh()
        let cached = try await cache.load(.contracts, as: BinanceContractsEnvelope.self)

        XCTAssertEqual(model.contracts.map(\.symbol), ["ETHUSDT", "BTCUSDT"])
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

    private func sampleContract(symbol: String, quoteVolume: Double) -> BinanceFuturesContract {
        BinanceFuturesContract(
            symbol: symbol,
            pair: symbol,
            contractType: "PERPETUAL",
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
}
