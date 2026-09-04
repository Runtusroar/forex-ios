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

    func testImpactMarkerMapsEveryKnownImpactToAStableLabel() {
        XCTAssertEqual(Impact.high.editorialLabel, "HIGH")
        XCTAssertEqual(Impact.medium.editorialLabel, "MEDIUM")
        XCTAssertEqual(Impact.low.editorialLabel, "LOW")
        XCTAssertEqual(Impact.holiday.editorialLabel, "HOLIDAY")
        XCTAssertEqual(Impact.unknown.editorialLabel, "UNKNOWN")
    }
}
