import Foundation
import Observation
import Security

protocol APIKeyStoring: Sendable {
    func read() throws -> String?
    func save(_ value: String) throws
    func delete() throws
}

struct KeychainAPIKeyStore: APIKeyStoring {
    private let service = "shop.zhenmei.ForexFactoryMVP"
    private let account = "backend-api-key"

    func read() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw APIError.invalidConfiguration
        }
        return String(data: data, encoding: .utf8)
    }

    func save(_ value: String) throws {
        guard let data = value.data(using: .utf8), !value.isEmpty else {
            throw APIError.invalidConfiguration
        }
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let update = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if update == errSecItemNotFound {
            var item = baseQuery
            attributes.forEach { item[$0.key] = $0.value }
            guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else {
                throw APIError.invalidConfiguration
            }
        } else if update != errSecSuccess {
            throw APIError.invalidConfiguration
        }
    }

    func delete() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw APIError.invalidConfiguration
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}

struct APICredentials: Equatable, Sendable {
    let baseURL: URL
    let apiKey: String
}

@Observable
@MainActor
final class AppSettings {
    private static let baseURLKey = "api.baseURL"
    private let defaults: UserDefaults
    private let keyStore: any APIKeyStoring

    var baseURLText: String
    var apiKeyText = ""
    var message: String?

    init(defaults: UserDefaults = .standard, keyStore: any APIKeyStoring = KeychainAPIKeyStore()) {
        self.defaults = defaults
        self.keyStore = keyStore
        baseURLText = defaults.string(forKey: Self.baseURLKey) ?? "https://zhenmei.shop"
    }

    var hasStoredAPIKey: Bool {
        (try? keyStore.read()) != nil
    }

    func save(baseURLText: String? = nil, apiKeyText: String? = nil) throws {
        let urlText = (baseURLText ?? self.baseURLText).trimmingCharacters(in: .whitespacesAndNewlines)
        let keyText = (apiKeyText ?? self.apiKeyText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: urlText),
              url.host != nil,
              url.scheme == "https" || (url.scheme == "http" && url.host == "127.0.0.1")
        else {
            throw APIError.invalidConfiguration
        }
        if !keyText.isEmpty {
            try keyStore.save(keyText)
        }
        guard try keyStore.read()?.isEmpty == false else {
            throw APIError.invalidConfiguration
        }
        defaults.set(url.absoluteString, forKey: Self.baseURLKey)
        self.baseURLText = url.absoluteString
        self.apiKeyText = ""
        message = "Saved"
    }

    func credentials() throws -> APICredentials {
        guard let url = URL(string: baseURLText), let key = try keyStore.read(), !key.isEmpty else {
            throw APIError.invalidConfiguration
        }
        return APICredentials(baseURL: url, apiKey: key)
    }

    func removeKey() throws {
        try keyStore.delete()
        apiKeyText = ""
        message = "API key removed"
    }
}
