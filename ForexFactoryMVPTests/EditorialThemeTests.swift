import XCTest
@testable import ForexFactoryMVP

final class EditorialThemeTests: XCTestCase {
    func testPublicationDateUsesUppercaseAbbreviatedEditorialFormat() {
        let value = EditorialDateFormatter.publicationDate(
            Date(timeIntervalSince1970: 1_788_523_200),
            calendar: Calendar(identifier: .gregorian),
            locale: Locale(identifier: "en_US_POSIX"),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )

        XCTAssertEqual(value, "SEP 4, 2026")
    }

    func testNewsTimeUsesFixedUTCPlusEightClock() throws {
        let date = try XCTUnwrap(
            ISO8601DateFormatter().date(from: "2026-09-03T01:05:00Z")
        )

        XCTAssertEqual(EditorialDateFormatter.newsTime(date), "09:05 UTC+8")
    }

    func testCalendarTimeUsesFixedUTCPlusEightClock() throws {
        let date = try XCTUnwrap(
            ISO8601DateFormatter().date(from: "2026-09-03T01:05:00Z")
        )

        XCTAssertEqual(EditorialDateFormatter.calendarTime(date), "09:05")
    }

    func testCalendarDayUsesUTCPlusEightAcrossTheUTCDateBoundary() throws {
        let date = try XCTUnwrap(
            ISO8601DateFormatter().date(from: "2026-09-03T17:05:00Z")
        )
        let expectedStart = try XCTUnwrap(
            ISO8601DateFormatter().date(from: "2026-09-03T16:00:00Z")
        )

        XCTAssertEqual(EditorialDateFormatter.calendarDay(date), expectedStart)
        XCTAssertEqual(EditorialDateFormatter.calendarDayLabel(date), "FRIDAY, SEP 4")
    }

    func testImpactMarkerMapsEveryKnownImpactToAStableLabel() {
        XCTAssertEqual(Impact.high.editorialLabel, "HIGH")
        XCTAssertEqual(Impact.medium.editorialLabel, "MEDIUM")
        XCTAssertEqual(Impact.low.editorialLabel, "LOW")
        XCTAssertEqual(Impact.holiday.editorialLabel, "HOLIDAY")
        XCTAssertEqual(Impact.unknown.editorialLabel, "UNKNOWN")
    }
}
