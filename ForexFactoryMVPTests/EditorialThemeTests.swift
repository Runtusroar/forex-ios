import XCTest
@testable import ForexFactoryMVP

final class EditorialThemeTests: XCTestCase {
    func testPreciseTimestampUsesUTCPlusEightAndCrossesDateBoundary() throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-09-04T16:05:09Z"))
        XCTAssertEqual(EditorialDateFormatter.timestamp(date), "2026-09-05 00:05:09 UTC+8")
    }

    func testDelayedLastUpdatedLabelStaysOnTheTimestampLine() throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-09-04T16:05:09Z"))

        XCTAssertEqual(
            LastUpdatedText.label(date: date, isDelayed: true),
            "Last updated 2026-09-05 00:05:09 UTC+8 · Delayed"
        )
    }

    func testPublicationDateUsesSameUTCPlusEightDayAsCalendar() throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-09-04T16:30:00Z"))
        XCTAssertEqual(EditorialDateFormatter.publicationDate(date), "SEP 5, 2026")
        XCTAssertEqual(EditorialDateFormatter.calendarTime(date), "00:30")
        XCTAssertEqual(EditorialDateFormatter.calendarDayLabel(date), "SATURDAY, SEP 5")
    }

    func testUTCAndOffsetAPIValuesDecodeToTheSameInstant() throws {
        struct Timestamp: Decodable { let time: Date }
        let utc = try JSONDecoder.api.decode(Timestamp.self, from: Data(#"{"time":"2026-09-04T16:30:00.123456Z"}"#.utf8))
        let offset = try JSONDecoder.api.decode(Timestamp.self, from: Data(#"{"time":"2026-09-05T00:30:00.123456+08:00"}"#.utf8))
        XCTAssertEqual(utc.time, offset.time)
        XCTAssertEqual(EditorialDateFormatter.newsTime(offset.time), "00:30")
    }

    func testPublicationDateUsesUppercaseAbbreviatedEditorialFormat() {
        let value = EditorialDateFormatter.publicationDate(
            Date(timeIntervalSince1970: 1_788_523_200),
            calendar: Calendar(identifier: .gregorian),
            locale: Locale(identifier: "en_US_POSIX"),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )

        XCTAssertEqual(value, "SEP 4, 2026")
    }

    func testNewsTimeUsesCompactClockBecauseTimezoneLivesInHeader() throws {
        let date = try XCTUnwrap(
            ISO8601DateFormatter().date(from: "2026-09-03T01:05:00Z")
        )

        XCTAssertEqual(EditorialDateFormatter.newsTime(date), "09:05")
    }

    func testNewsImpactFilterOptionsMapToAPIValuesInEditorialOrder() {
        XCTAssertEqual(
            NewsImpactFilterOption.allCases.map(\.impact),
            [nil, .high, .medium, .low]
        )
    }

    func testNewsImpactFilterSelectionMarksOnlyCurrentChoice() {
        XCTAssertFalse(NewsImpactFilterOption.all.isSelected(filter: .high))
        XCTAssertTrue(NewsImpactFilterOption.high.isSelected(filter: .high))
        XCTAssertFalse(NewsImpactFilterOption.medium.isSelected(filter: .high))
        XCTAssertFalse(NewsImpactFilterOption.low.isSelected(filter: .high))
    }

    func testCalendarTimeUsesFixedUTCPlusEightClock() throws {
        let date = try XCTUnwrap(
            ISO8601DateFormatter().date(from: "2026-09-03T01:05:00Z")
        )

        XCTAssertEqual(EditorialDateFormatter.calendarTime(date), "09:05")
    }

    func testCalendarTimePreservesForexFactoryUntimedLabel() throws {
        let json = #"{"source_id":"151045","event_at":"2026-09-08T16:00:00Z","currency":"USD","impact":"low","title_en":"ADP Weekly Employment Change","title_zh":null,"actual":null,"forecast":null,"previous":"11.8K","source_time_text":"Aug 23rd","source_position":9,"updated_at":"2026-09-04T15:30:00Z"}"#
        let event = try JSONDecoder.api.decode(CalendarEvent.self, from: Data(json.utf8))

        XCTAssertEqual(EditorialDateFormatter.calendarTime(event), "Aug 23rd")
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
