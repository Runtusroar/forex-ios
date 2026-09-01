import XCTest
@testable import ForexFactoryMVP

final class APIModelsTests: XCTestCase {
    func testCalendarEventDecodesWithoutChineseTranslation() throws {
        let json = #"{"source_id":"1","event_at":"2026-09-01T12:00:00Z","currency":"USD","impact":"high","title_en":"ISM Manufacturing PMI","title_zh":null,"actual":"51.2","forecast":"50.5","previous":"49.8","updated_at":"2026-09-01T12:01:00Z"}"#
        let event = try JSONDecoder.api.decode(CalendarEvent.self, from: Data(json.utf8))

        XCTAssertEqual(event.titleEN, "ISM Manufacturing PMI")
        XCTAssertNil(event.titleZH)
        XCTAssertEqual(event.impact, .high)
    }
}
