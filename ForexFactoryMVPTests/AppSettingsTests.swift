import XCTest
@testable import ForexFactoryMVP

private final class MemoryKeyStore: APIKeyStoring, @unchecked Sendable {
    var value: String?

    func read() throws -> String? { value }
    func save(_ value: String) throws { self.value = value }
    func delete() throws { value = nil }
}

final class AppSettingsTests: XCTestCase {
    @MainActor
    func testDefaultBaseURLUsesPublicTunnelHost() {
        let settings = AppSettings(
            defaults: UserDefaults(suiteName: UUID().uuidString)!,
            keyStore: MemoryKeyStore()
        )

        XCTAssertEqual(settings.baseURLText, "https://api.juezhou.cc")
    }

    @MainActor
    func testHTTPSURLAndKeyAreSaved() throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let keys = MemoryKeyStore()
        let settings = AppSettings(defaults: defaults, keyStore: keys)

        try settings.save(baseURLText: "https://zhenmei.shop/", apiKeyText: "phone-secret")
        let credentials = try settings.credentials()

        XCTAssertEqual(credentials.baseURL.absoluteString, "https://zhenmei.shop/")
        XCTAssertEqual(credentials.apiKey, "phone-secret")
        XCTAssertEqual(keys.value, "phone-secret")
    }

    @MainActor
    func testRemoteHTTPURLIsRejected() {
        let settings = AppSettings(
            defaults: UserDefaults(suiteName: UUID().uuidString)!,
            keyStore: MemoryKeyStore()
        )

        XCTAssertThrowsError(
            try settings.save(baseURLText: "http://zhenmei.shop", apiKeyText: "secret")
        ) { error in
            XCTAssertEqual(error as? APIError, .invalidConfiguration)
        }
    }
}
