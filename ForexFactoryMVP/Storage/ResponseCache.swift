import Foundation

enum CacheKey: Sendable {
    case calendar
    case contracts(marketType: ContractMarketFilter)
    case news(section: NewsSectionID, impact: Impact?)

    var fileName: String {
        switch self {
        case .calendar:
            "calendar-v1.json"
        case let .contracts(marketType):
            "binance-futures-contracts-\(marketType.rawValue)-v1.json"
        case let .news(section, impact):
            "news-v2-\(section.rawValue)-\(impact?.rawValue ?? "all").json"
        }
    }
}

actor ResponseCache {
    private let directory: URL
    private let fileManager: FileManager

    init(directory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.directory = directory ?? fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appending(path: "ForexFactoryMVP", directoryHint: .isDirectory)
    }

    func load<Value: Decodable & Sendable>(
        _ key: CacheKey,
        as type: Value.Type
    ) throws -> Value? {
        let fileURL = url(for: key)
        guard fileManager.fileExists(atPath: fileURL.path()) else { return nil }
        do {
            return try JSONDecoder.api.decode(Value.self, from: Data(contentsOf: fileURL))
        } catch is DecodingError {
            quarantine(fileURL)
            return nil
        }
    }

    func save<Value: Encodable & Sendable>(_ value: Value, as key: CacheKey) throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder.api.encode(value).write(to: url(for: key), options: .atomic)
    }

    func remove(_ key: CacheKey) throws {
        let fileURL = url(for: key)
        if fileManager.fileExists(atPath: fileURL.path()) {
            try fileManager.removeItem(at: fileURL)
        }
    }

    private func url(for key: CacheKey) -> URL {
        directory.appending(path: key.fileName)
    }

    private func quarantine(_ fileURL: URL) {
        let corruptURL = fileURL.deletingPathExtension()
            .appendingPathExtension("corrupt-\(UUID().uuidString).json")
        try? fileManager.moveItem(at: fileURL, to: corruptURL)
    }
}
