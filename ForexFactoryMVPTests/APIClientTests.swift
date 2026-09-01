import XCTest
@testable import ForexFactoryMVP

final class APIClientTests: XCTestCase {
    func testCalendarRequestUsesVersionedPathDatesAndAPIKey() throws {
        let start = Date(timeIntervalSince1970: 1_788_220_800)
        let end = start.addingTimeInterval(86_400)

        let request = try APIRequestBuilder(
            baseURL: XCTUnwrap(URL(string: "https://zhenmei.shop")),
            apiKey: "secret"
        ).calendar(from: start, to: end)
        let components = try XCTUnwrap(URLComponents(url: XCTUnwrap(request.url), resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.path, "/api/v1/calendar")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-API-Key"), "secret")
        XCTAssertEqual(Set(components.queryItems?.map(\.name) ?? []), Set(["from", "to"]))
    }

    func testNewsLimitIsIncluded() throws {
        let request = try APIRequestBuilder(
            baseURL: XCTUnwrap(URL(string: "https://zhenmei.shop/api")),
            apiKey: "secret"
        ).news(limit: 50)
        let components = try XCTUnwrap(URLComponents(url: XCTUnwrap(request.url), resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.path, "/api/v1/news")
        XCTAssertEqual(components.queryItems?.first?.value, "50")
    }
}
