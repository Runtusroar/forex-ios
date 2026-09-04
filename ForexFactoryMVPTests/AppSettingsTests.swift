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
    func testMissingAndLegacyDefaultURLsMigrateToCurrentBackend() {
        for storedValue in [nil, "https://zhenmei.shop", "https://zhenmei.shop/"] as [String?] {
            let defaults = UserDefaults(suiteName: UUID().uuidString)!
            if let storedValue {
                defaults.set(storedValue, forKey: "api.baseURL")
            }

            let settings = AppSettings(defaults: defaults, keyStore: MemoryKeyStore())

            XCTAssertEqual(settings.baseURLText, "https://api.juezhou.cc")
            XCTAssertEqual(defaults.string(forKey: "api.baseURL"), "https://api.juezhou.cc")
        }
    }

    @MainActor
    func testCustomBackendURLIsNotMigrated() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set("https://private.example", forKey: "api.baseURL")

        let settings = AppSettings(defaults: defaults, keyStore: MemoryKeyStore())

        XCTAssertEqual(settings.baseURLText, "https://private.example")
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
