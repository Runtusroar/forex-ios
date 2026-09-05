import XCTest
@testable import ForexFactoryMVP

final class ImageDataCacheTests: XCTestCase {
    // A real 1 × 1 PNG; invalid responses must not become persistent image entries.
    private let png = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jF9sAAAAASUVORK5CYII=")!

    func testRepeatedImageUsesMemoryWithoutFetchingAgain() async throws {
        let cache = ImageDataCache(directory: directory())
        let source = ImageSource(data: png)
        _ = try await cache.data(key: "image") { try await source.fetch() }
        let result = try await cache.data(key: "image") { try await source.fetch() }
        XCTAssertEqual(result, png)
        let requests = await source.requests
        XCTAssertEqual(requests, 1)
    }

    func testConcurrentRequestsShareOneDownload() async throws {
        let cache = ImageDataCache(directory: directory())
        let source = ImageSource(data: png)
        async let first = cache.data(key: "image") { try await source.fetch() }
        async let second = cache.data(key: "image") { try await source.fetch() }
        _ = try await (first, second)
        let requests = await source.requests
        XCTAssertEqual(requests, 1)
    }

    func testDiskSurvivesCacheRecreationWithoutNetwork() async throws {
        let folder = directory()
        let cache = ImageDataCache(directory: folder)
        let source = ImageSource(data: png)
        _ = try await cache.data(key: "image") { try await source.fetch() }
        let restored = ImageDataCache(directory: folder)
        let data = try await restored.data(key: "image") { throw APIError.server }
        XCTAssertEqual(data, png)
    }

    func testExpiredImageFetchesAgain() async throws {
        let cache = ImageDataCache(directory: directory(), lifetime: 0)
        let source = ImageSource(data: png)
        _ = try await cache.data(key: "image") { try await source.fetch() }
        _ = try await cache.data(key: "image") { try await source.fetch() }
        let requests = await source.requests
        XCTAssertEqual(requests, 2)
    }

    func testFailuresCanRetryAndAreNotCached() async throws {
        let cache = ImageDataCache(directory: directory())
        do {
            _ = try await cache.data(key: "image") { throw APIError.server }
            XCTFail("Expected failure")
        } catch {}
        let image = png
        let result = try await cache.data(key: "image") { image }
        XCTAssertEqual(result, png)
    }

    func testInvalidImageIsNotStored() async throws {
        let cache = ImageDataCache(directory: directory())
        do {
            _ = try await cache.data(key: "image") { Data("not an image".utf8) }
            XCTFail("Invalid image must be rejected")
        } catch {}
        let image = png
        let result = try await cache.data(key: "image") { image }
        XCTAssertEqual(result, png)
    }

    func testDifferentCredentialNamespacesNeverShareContent() async throws {
        let cache = ImageDataCache(directory: directory())
        let source = ImageSource(data: png)
        _ = try await cache.data(key: "server-a:user-a:image") { try await source.fetch() }
        _ = try await cache.data(key: "server-a:user-b:image") { try await source.fetch() }
        _ = try await cache.data(key: "server-b:user-a:image") { try await source.fetch() }
        let requests = await source.requests
        XCTAssertEqual(requests, 3)
    }

    func testRequestKeysSeparateBackendAndCredentialChanges() throws {
        let a = try APIRequestBuilder(baseURL: URL(string: "https://a.example")!, apiKey: "one").media(path: "/api/v2/news/media/1")
        let b = try APIRequestBuilder(baseURL: URL(string: "https://a.example")!, apiKey: "two").media(path: "/api/v2/news/media/1")
        let c = try APIRequestBuilder(baseURL: URL(string: "https://b.example")!, apiKey: "one").media(path: "/api/v2/news/media/1")
        XCTAssertNotEqual(ImageDataCache.requestKey(a), ImageDataCache.requestKey(b))
        XCTAssertNotEqual(ImageDataCache.requestKey(a), ImageDataCache.requestKey(c))
    }

    func testDiskBudgetEvictsOldImages() async throws {
        let folder = directory()
        let cache = ImageDataCache(directory: folder, memoryLimit: 0, diskLimit: 512)
        let source = ImageSource(data: png)
        for index in 0..<6 {
            _ = try await cache.data(key: "image-\(index)") { try await source.fetch() }
        }
        let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.fileSizeKey])
        let bytes = try files.reduce(0) { try $0 + ($1.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) }
        XCTAssertLessThanOrEqual(bytes, 512)
        _ = try await cache.data(key: "image-0") { try await source.fetch() }
        let requests = await source.requests
        XCTAssertEqual(requests, 7)
    }

    func testCorruptDiskEntryRedownloads() async throws {
        let folder = directory()
        let cache = ImageDataCache(directory: folder, memoryLimit: 0)
        let source = ImageSource(data: png)
        _ = try await cache.data(key: "image") { try await source.fetch() }
        let file = try XCTUnwrap(FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil).first)
        try Data("corrupt".utf8).write(to: file)
        let result = try await cache.data(key: "image") { try await source.fetch() }
        XCTAssertEqual(result, png)
        let requests = await source.requests
        XCTAssertEqual(requests, 2)
    }

    func testAPIClientUsesCacheAcrossClientInstances() async throws {
        ImageCacheURLProtocol.state.reset(data: png)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ImageCacheURLProtocol.self]
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let folder = directory()
        let first = APIClient(baseURL: URL(string: "https://test.example")!, apiKey: "one", session: session, imageCache: ImageDataCache(directory: folder))
        _ = try await first.mediaData(path: "/api/v2/news/media/1")
        let reopened = APIClient(baseURL: URL(string: "https://test.example")!, apiKey: "one", session: session, imageCache: ImageDataCache(directory: folder))
        let data = try await reopened.mediaData(path: "/api/v2/news/media/1")
        XCTAssertEqual(data, png)
        XCTAssertEqual(ImageCacheURLProtocol.state.requests, 1)
        let changedKey = APIClient(baseURL: URL(string: "https://test.example")!, apiKey: "two", session: session, imageCache: ImageDataCache(directory: folder))
        _ = try await changedKey.mediaData(path: "/api/v2/news/media/1")
        XCTAssertEqual(ImageCacheURLProtocol.state.requests, 2)
    }

    private func directory() -> URL {
        let path = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        addTeardownBlock { try? FileManager.default.removeItem(at: path) }
        return path
    }
}

private actor ImageSource {
    let data: Data
    var requests = 0
    init(data: Data) { self.data = data }
    func fetch() async throws -> Data {
        requests += 1
        try await Task.sleep(for: .milliseconds(60))
        return data
    }
}

private final class ImageCacheURLProtocol: URLProtocol, @unchecked Sendable {
    static let state = ImageCacheProtocolState()
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let data = Self.state.readAndCount()
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "image/png"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

private final class ImageCacheProtocolState: @unchecked Sendable {
    private let lock = NSLock()
    private var payload = Data()
    private var count = 0
    var requests: Int { lock.withLock { count } }
    func reset(data: Data) { lock.withLock { payload = data; count = 0 } }
    func readAndCount() -> Data { lock.withLock { count += 1; return payload } }
}
