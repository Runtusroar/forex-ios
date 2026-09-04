import Foundation
import XCTest
@testable import ForexFactoryMVP

final class ResponseCacheTests: XCTestCase {
    func testCacheRoundTripsCalendarEnvelope() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let cache = ResponseCache(directory: directory)
        let event = CalendarEvent(
            sourceID: "event-1",
            eventAt: Date(timeIntervalSince1970: 1_788_220_800),
            currency: "USD",
            impact: .high,
            titleEN: "ISM Manufacturing PMI",
            titleZH: "ISM 制造业采购经理指数",
            actual: nil,
            forecast: "50.5",
            previous: "49.8",
            updatedAt: Date(timeIntervalSince1970: 1_788_220_860)
        )
        let envelope = CalendarEnvelope(items: [event], generatedAt: event.updatedAt)

        try await cache.save(envelope, as: .calendar)
        let loaded = try await cache.load(.calendar, as: CalendarEnvelope.self)

        XCTAssertEqual(loaded?.items, [event])
        XCTAssertEqual(loaded?.generatedAt, envelope.generatedAt)
    }

    func testCorruptCacheReturnsNil() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("{".utf8).write(to: directory.appending(path: "news-v2-latest-all.json"))
        let cache = ResponseCache(directory: directory)

        let loaded = try await cache.load(
            .news(section: .latest, impact: nil),
            as: NewsArticlesEnvelope.self
        )

        XCTAssertNil(loaded)
    }

    func testNewsSectionAndImpactCachesDoNotOverwriteEachOther() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let cache = ResponseCache(directory: directory)
        let all = NewsArticlesEnvelope(
            items: [],
            nextCursor: "all-cursor",
            generatedAt: Date(timeIntervalSince1970: 100)
        )
        let high = NewsArticlesEnvelope(
            items: [],
            nextCursor: "high-cursor",
            generatedAt: Date(timeIntervalSince1970: 200)
        )

        try await cache.save(all, as: .news(section: .latest, impact: nil))
        try await cache.save(high, as: .news(section: .latest, impact: .high))

        let loadedAll = try await cache.load(
            .news(section: .latest, impact: nil),
            as: NewsArticlesEnvelope.self
        )
        let loadedHigh = try await cache.load(
            .news(section: .latest, impact: .high),
            as: NewsArticlesEnvelope.self
        )
        XCTAssertEqual(loadedAll?.nextCursor, "all-cursor")
        XCTAssertEqual(loadedHigh?.nextCursor, "high-cursor")
    }

    func testContractMarketCachesDoNotOverwriteEachOther() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let cache = ResponseCache(directory: directory)
        let all = BinanceContractsEnvelope(
            items: [],
            generatedAt: Date(timeIntervalSince1970: 100)
        )
        let traditional = BinanceContractsEnvelope(
            items: [],
            generatedAt: Date(timeIntervalSince1970: 200)
        )

        try await cache.save(all, as: .contracts(marketType: .all))
        try await cache.save(traditional, as: .contracts(marketType: .traditional))

        let loadedAll = try await cache.load(
            .contracts(marketType: .all),
            as: BinanceContractsEnvelope.self
        )
        let loadedTraditional = try await cache.load(
            .contracts(marketType: .traditional),
            as: BinanceContractsEnvelope.self
        )
        XCTAssertEqual(loadedAll?.generatedAt, all.generatedAt)
        XCTAssertEqual(loadedTraditional?.generatedAt, traditional.generatedAt)
    }
}
