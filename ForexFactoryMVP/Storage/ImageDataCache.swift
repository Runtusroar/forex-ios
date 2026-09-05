import CryptoKit
import Foundation
import ImageIO

/// Bounded, credential-scoped image storage. News JSON remains in ResponseCache.
actor ImageDataCache {
    static let shared = ImageDataCache()
    private struct Entry: Codable {
        let data: Data
        let expiresAt: Date
    }
    private let directory: URL
    private let lifetime: TimeInterval
    private let memoryLimit: Int
    private let diskLimit: Int
    private var memory: [String: Entry] = [:]
    private var access: [String: Date] = [:]
    private var pending: [String: Task<Data, Error>] = [:]
    private var memoryBytes = 0

    init(directory: URL? = nil, lifetime: TimeInterval = 86400,
         memoryLimit: Int = 16 * 1024 * 1024, diskLimit: Int = 128 * 1024 * 1024) {
        self.directory = directory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appending(path: "NewsImages", directoryHint: .isDirectory)
        self.lifetime = lifetime
        self.memoryLimit = max(0, memoryLimit)
        self.diskLimit = max(0, diskLimit)
    }

    nonisolated static func requestKey(_ request: URLRequest) -> String {
        let headers = (request.allHTTPHeaderFields ?? [:]).map { ($0.key.lowercased(), $0.value) }
            .sorted { $0.0 < $1.0 }.map { $0.0 + ":" + $0.1 }.joined(separator: "\n")
        return digest((request.url?.absoluteString ?? "") + "\n" + headers)
    }

    func data(key: String, fetch: @escaping @Sendable () async throws -> Data) async throws -> Data {
        let id = Self.digest(key)
        if let entry = memory[id] {
            if entry.expiresAt > Date() {
                access[id] = Date()
                return entry.data
            }
            removeMemory(id)
        }
        let file = directory.appending(path: id)
        if let encoded = try? Data(contentsOf: file) {
            if let entry = try? JSONDecoder().decode(Entry.self, from: encoded), entry.expiresAt > Date() {
                remember(entry, id: id)
                try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: file.path)
                return entry.data
            }
            try? FileManager.default.removeItem(at: file)
        }
        if let download = pending[id] { return try await download.value }
        // View cancellation does not cancel a download another visible row may share.
        let download = Task {
            let data = try await fetch()
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  CGImageSourceGetCount(source) > 0 else { throw APIError.invalidResponse }
            return data
        }
        pending[id] = download
        do {
            let data = try await download.value
            let entry = Entry(data: data, expiresAt: Date().addingTimeInterval(lifetime))
            if lifetime > 0 {
                remember(entry, id: id)
                persist(entry, to: file)
            }
            pending[id] = nil
            return data
        } catch {
            pending[id] = nil
            throw error
        }
    }

    private func remember(_ entry: Entry, id: String) {
        guard entry.data.count <= memoryLimit else { return }
        removeMemory(id)
        while memoryBytes + entry.data.count > memoryLimit,
              let oldest = access.min(by: { $0.value < $1.value })?.key {
            removeMemory(oldest)
        }
        memory[id] = entry
        access[id] = Date()
        memoryBytes += entry.data.count
    }

    private func removeMemory(_ id: String) {
        if let removed = memory.removeValue(forKey: id) { memoryBytes -= removed.data.count }
        access[id] = nil
    }

    private func persist(_ entry: Entry, to file: URL) {
        guard let encoded = try? JSONEncoder().encode(entry), encoded.count <= diskLimit else { return }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try encoded.write(to: file, options: .atomic)
            let files = try FileManager.default.contentsOfDirectory(
                at: directory, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
            ).compactMap { url -> (url: URL, size: Int, date: Date)? in
                guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]) else { return nil }
                return (url, values.fileSize ?? 0, values.contentModificationDate ?? .distantPast)
            }.sorted { $0.date < $1.date }
            var bytes = files.reduce(0) { $0 + $1.size }
            for item in files where bytes > diskLimit {
                try FileManager.default.removeItem(at: item.url)
                bytes -= item.size
            }
        } catch {
            // Cache I/O is best effort; a downloaded image remains usable.
        }
    }

    private nonisolated static func digest(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
