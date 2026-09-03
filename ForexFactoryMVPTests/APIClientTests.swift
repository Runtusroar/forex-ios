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

    func testNewsV2RequestIncludesSectionImpactCursorAndAPIKey() throws {
        let request = try APIRequestBuilder(
            baseURL: XCTUnwrap(URL(string: "https://api.juezhou.cc")),
            apiKey: "secret"
        ).news(section: .technical, impact: .high, limit: 25, cursor: "opaque")
        let components = try XCTUnwrap(URLComponents(url: XCTUnwrap(request.url), resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.path, "/api/v2/news")
        XCTAssertEqual(
            Dictionary(uniqueKeysWithValues: components.queryItems?.map { ($0.name, $0.value ?? "") } ?? []),
            ["section": "technical", "impact": "high", "limit": "25", "cursor": "opaque"]
        )
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-API-Key"), "secret")
    }

    func testProtectedMediaAcceptsOnlyBackendRelativePath() throws {
        let builder = APIRequestBuilder(
            baseURL: try XCTUnwrap(URL(string: "https://api.juezhou.cc")),
            apiKey: "secret"
        )

        let request = try builder.media(path: "/api/v2/news/media/7")

        XCTAssertEqual(request.url?.absoluteString, "https://api.juezhou.cc/api/v2/news/media/7")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-API-Key"), "secret")
        XCTAssertThrowsError(try builder.media(path: "https://assets.example/image.png")) { error in
            XCTAssertEqual(error as? APIError, .invalidConfiguration)
        }
    }
}
