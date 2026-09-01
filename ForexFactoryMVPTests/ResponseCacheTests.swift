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
        try Data("{".utf8).write(to: directory.appending(path: "news-v1.json"))
        let cache = ResponseCache(directory: directory)

        let loaded = try await cache.load(.news, as: NewsEnvelope.self)

        XCTAssertNil(loaded)
    }
}
