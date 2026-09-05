import XCTest
@testable import ForexFactoryMVP

// Optional real-network probe; archived outside the normal test suite after the run.
final class ImageCacheLiveProbeTests: XCTestCase {
    func testPublicImageColdMemoryAndDiskReads() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let cache = ImageDataCache(directory: folder)
        var request = URLRequest(url: URL(string: "https://assets.faireconomy.media/nfs/npd/2025/01/20/npd_12_30_34.v2.png")!, timeoutInterval: 20)
        request.setValue("image/*", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let imageRequest = request
        let key = ImageDataCache.requestKey(imageRequest)
        let cold = Date()
        let data = try await cache.data(key: key) {
            let (data, response) = try await URLSession.shared.data(for: imageRequest)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            print("LIVE_IMAGE_HTTP status=\(status) bytes=\(data.count)")
            guard status == 200 else { throw APIError.invalidResponse }
            return data
        }
        let coldMS = Date().timeIntervalSince(cold) * 1000
        let memoryStart = Date()
        let memory = try await cache.data(key: key) { throw APIError.server }
        let memoryMS = Date().timeIntervalSince(memoryStart) * 1000
        let restored = ImageDataCache(directory: folder)
        let diskStart = Date()
        let disk = try await restored.data(key: key) { throw APIError.server }
        let diskMS = Date().timeIntervalSince(diskStart) * 1000
        XCTAssertEqual(memory, data)
        XCTAssertEqual(disk, data)
        print("LIVE_IMAGE_TIMING cold_ms=\(coldMS) memory_ms=\(memoryMS) disk_ms=\(diskMS)")
    }
}
