import SwiftUI
import UIKit
import XCTest
@testable import ForexFactoryMVP

final class NewsReaderScrollingTests: XCTestCase {
    @MainActor
    func testReturningFromBottomDoesNotChangeLoadedArticleHeightOrReloadImages() async throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 900))
        let imageData = try XCTUnwrap(renderer.image { context in
            UIColor.lightGray.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 600, height: 900))
        }.pngData())
        let api = ScrollFixtureAPI(imageData: imageData)
        let model = NewsViewModel(api: api, cache: ResponseCache(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)))
        let host = UIHostingController(rootView: NavigationStack {
            NewsDetailView(articleID: "scroll", summary: nil, model: model)
        })
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        try await Task.sleep(for: .seconds(1))
        window.layoutIfNeeded()
        let scroll = try XCTUnwrap(findScroll(in: host.view))
        // Warm both ends so the comparison concerns already-loaded content.
        for fraction in [1.0, 0.0, 1.0, 0.0] {
            scroll.setContentOffset(CGPoint(x: 0, y: max(0, scroll.contentSize.height - scroll.bounds.height) * fraction), animated: false)
            try await Task.sleep(for: .milliseconds(250))
            window.layoutIfNeeded()
        }
        let loadedHeight = scroll.contentSize.height
        var measuredHeights: [CGFloat] = []
        for fraction in [1.0, 0.85, 0.65, 0.4, 0.15, 0.0] {
            let target = max(0, loadedHeight - scroll.bounds.height) * fraction
            scroll.setContentOffset(CGPoint(x: 0, y: target), animated: false)
            try await Task.sleep(for: .milliseconds(250))
            window.layoutIfNeeded()
            measuredHeights.append(scroll.contentSize.height)
        }
        print("READER_HEIGHTS initial=\(loadedHeight) reverse=\(measuredHeights)")
        XCTAssertLessThan((measuredHeights.max() ?? 0) - (measuredHeights.min() ?? 0), 2,
                          "Loaded content must not change height as the reader scrolls back up")
        XCTAssertLessThanOrEqual(abs(scroll.contentOffset.y), 2, "The reader must be able to return to the top")
        let counts = await api.requestCounts()
        print("READER_MEDIA_REQUESTS \(counts)")
        XCTAssertTrue(counts.values.allSatisfy { $0 == 1 }, "Scrolling must not restart loaded image requests")
    }

    @MainActor
    private func findScroll(in view: UIView) -> UIScrollView? {
        if let scroll = view as? UIScrollView { return scroll }
        return view.subviews.lazy.compactMap { self.findScroll(in: $0) }.first
    }
}

private actor ScrollFixtureAPI: ForexAPI {
    let imageData: Data
    private var counts: [String: Int] = [:]
    init(imageData: Data) { self.imageData = imageData }
    func requestCounts() -> [String: Int] { counts }
    func calendar(from start: Date, to end: Date) async throws -> CalendarEnvelope { throw APIError.notFound }
    func status() async throws -> ServiceStatus { ServiceStatus(status: "ok", model: "fixture") }
    func mediaData(path: String) async throws -> Data {
        counts[path, default: 0] += 1
        try await Task.sleep(for: .milliseconds(80))
        return imageData
    }
    func articleComments(id: String, limit: Int, cursor: String?) async throws -> NewsCommentsEnvelope {
        NewsCommentsEnvelope(items: [], nextCursor: nil, commentsComplete: true, generatedAt: .distantPast)
    }
    func newsV2Detail(id: String) async throws -> NewsArticleDetail {
        let segments: [[String: Any]] = (0..<36).map { index in
            let media: [[String: Any]] = index.isMultiple(of: 4) ? [[
                "id": index, "position": 0, "type": "image", "original_url": "https://example.com/image",
                "download_state": "complete", "url": "/media/\(index)"
            ]] : []
            return ["id": index, "stable_key": "s\(index)", "position": index, "type": "article",
                    "text": ["en": String(repeating: "A market report includes text, charts and source context. ", count: 2 + index % 6)],
                    "is_excerpt": false, "media": media, "links": []]
        }
        let payload: [String: Any] = [
            "source_id": "scroll", "ff_url": "https://www.forexfactory.com/news/scroll", "title": ["en": "Long article scroll regression"],
            "teaser": ["en": ""], "comment_count": 0, "detail_state": "complete", "is_excerpt": false,
            "categories": [], "feeds": [], "segments": segments, "comment_count_collected": 0,
            "comments_complete": true, "generated_at": "2026-09-05T08:45:12Z"
        ]
        return try JSONDecoder.api.decode(NewsArticleDetail.self, from: JSONSerialization.data(withJSONObject: payload))
    }
}
