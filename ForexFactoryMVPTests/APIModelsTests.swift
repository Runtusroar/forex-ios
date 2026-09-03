import XCTest
@testable import ForexFactoryMVP

final class APIModelsTests: XCTestCase {
    func testCalendarEventDecodesWithoutChineseTranslation() throws {
        let json = #"{"source_id":"1","event_at":"2026-09-01T12:00:00Z","currency":"USD","impact":"high","title_en":"ISM Manufacturing PMI","title_zh":null,"actual":"51.2","forecast":"50.5","previous":"49.8","updated_at":"2026-09-01T12:01:00Z"}"#
        let event = try JSONDecoder.api.decode(CalendarEvent.self, from: Data(json.utf8))

        XCTAssertEqual(event.titleEN, "ISM Manufacturing PMI")
        XCTAssertNil(event.titleZH)
        XCTAssertEqual(event.impact, .high)
    }

    func testNewsV2DetailDecodesOrderedBilingualSegmentsAndMedia() throws {
        let json = #"{"source_id":"1416171","ff_url":"https://www.forexfactory.com/news/1416171-yen-rises","title":{"en":"Yen rises","zh_hans":"日元上涨"},"teaser":{"en":"BOJ watched markets.","zh_hans":null},"source_name":"Reuters","source_url":"https://reuters.example/story","published_at":"2026-09-03T01:00:00Z","published_at_source_text":"Sep 3, 2026 9:00am","source_timezone":"Asia/Shanghai","breaking_impact":"high","comment_count":12,"detail_state":"complete","is_excerpt":true,"thumbnail_url":"https://assets.example/thumb.png","categories":["fundamental"],"feeds":[{"feed_type":"latest","rank":0}],"segments":[{"id":3,"stable_key":"social-1","position":0,"type":"social","author_name":"Market Wire","author_handle":"@wire","published_at":"2026-09-03T01:01:00Z","published_at_source_text":"Sep 3, 2026 9:01am","text":{"en":"First alert","zh_hans":"第一条快讯"},"source_url":"https://x.com/wire/1","is_excerpt":false,"media":[]},{"id":4,"stable_key":"body-1","position":1,"type":"article","author_name":null,"author_handle":null,"published_at":null,"published_at_source_text":null,"text":{"en":"Full story","zh_hans":null},"source_url":"https://reuters.example/story","is_excerpt":true,"media":[{"id":7,"position":0,"type":"image","caption":null,"original_url":"https://assets.example/image.png","download_state":"complete","url":"/api/v2/news/media/7","mime_type":"image/png","byte_size":18151}]}],"comment_count_collected":4,"comments_complete":false,"generated_at":"2026-09-03T01:02:00Z"}"#

        let detail = try JSONDecoder.api.decode(NewsArticleDetail.self, from: Data(json.utf8))

        XCTAssertEqual(detail.sourceID, "1416171")
        XCTAssertEqual(detail.title.en, "Yen rises")
        XCTAssertEqual(detail.title.zhHans, "日元上涨")
        XCTAssertNil(detail.teaser.zhHans)
        XCTAssertEqual(detail.breakingImpact, .high)
        XCTAssertEqual(detail.segments.map(\.position), [0, 1])
        XCTAssertEqual(detail.segments[0].type, .social)
        XCTAssertEqual(detail.segments[1].media[0].url, "/api/v2/news/media/7")
        XCTAssertFalse(detail.commentsComplete)
    }

    func testUnknownImpactDecodesWithoutDiscardingArticle() throws {
        let json = #"{"source_id":"1","ff_url":"https://www.forexfactory.com/news/1","title":{"en":"Title","zh_hans":null},"teaser":{"en":null,"zh_hans":null},"source_name":null,"source_url":null,"published_at":null,"published_at_source_text":"now","source_timezone":null,"breaking_impact":"future-value","comment_count":0,"detail_state":"pending","is_excerpt":false,"thumbnail_url":null,"categories":[]}"#

        let item = try JSONDecoder.api.decode(NewsArticleSummary.self, from: Data(json.utf8))

        XCTAssertEqual(item.breakingImpact, .unknown)
    }

    func testNewsSegmentDecodesStructuredFullStoryLinkAndSourceDocument() throws {
        let json = #"{"id":4,"stable_key":"body-1","position":1,"type":"article","author_name":null,"author_handle":null,"published_at":null,"published_at_source_text":null,"text":{"en":"Forex Factory excerpt","zh_hans":"外汇工厂摘要"},"source_url":"https://publisher.example/story","is_excerpt":true,"media":[],"links":[{"id":11,"position":0,"kind":"full_story","label":"full story","url":"https://publisher.example/story","source_document":{"id":7,"state":"complete","title":{"en":"Publisher headline","zh_hans":"出版方标题"},"author_name":"News Desk","source_host":"publisher.example","published_at_source_text":"Sep 3, 2026","lead_image_url":"https://publisher.example/lead.jpg","has_native_content":true}}]}"#

        let segment = try JSONDecoder.api.decode(NewsSegment.self, from: Data(json.utf8))

        XCTAssertEqual(segment.text.en, "Forex Factory excerpt")
        XCTAssertEqual(segment.links.count, 1)
        XCTAssertEqual(segment.links[0].kind, .fullStory)
        XCTAssertEqual(segment.links[0].sourceDocument?.state, .complete)
        XCTAssertEqual(segment.links[0].sourceDocument?.title.zhHans, "出版方标题")
        XCTAssertTrue(segment.links[0].sourceDocument?.hasNativeContent == true)
    }

    func testSourceDocumentDecodesBilingualNativeArticle() throws {
        let json = #"{"id":7,"state":"complete","original_url":"https://publisher.example/story","final_url":"https://publisher.example/story?canonical=1","source_host":"publisher.example","title":{"en":"Publisher headline","zh_hans":"出版方标题"},"author_name":"News Desk","published_at_source_text":"Sep 3, 2026","lead_image_url":"https://publisher.example/lead.jpg","body":{"en":"First paragraph.\n\nSecond paragraph.","zh_hans":"第一段。\n\n第二段。"},"paragraphs":["First paragraph.","Second paragraph."],"extraction_method":"json_ld","last_fetched_at":"2026-09-03T01:02:00Z"}"#

        let document = try JSONDecoder.api.decode(SourceDocument.self, from: Data(json.utf8))

        XCTAssertEqual(document.state, .complete)
        XCTAssertEqual(document.paragraphs, ["First paragraph.", "Second paragraph."])
        XCTAssertEqual(document.body.zhHans, "第一段。\n\n第二段。")
        XCTAssertEqual(document.extractionMethod, "json_ld")
    }

    func testBlockedSourceDocumentKeepsOriginalPublisherURL() throws {
        let json = #"{"id":8,"state":"blocked","original_url":"https://publisher.example/blocked","final_url":null,"source_host":"publisher.example","title":{"en":null,"zh_hans":null},"author_name":null,"published_at_source_text":null,"lead_image_url":null,"body":{"en":null,"zh_hans":null},"paragraphs":[],"extraction_method":null,"last_fetched_at":null}"#

        let document = try JSONDecoder.api.decode(SourceDocument.self, from: Data(json.utf8))

        XCTAssertEqual(document.state, .blocked)
        XCTAssertEqual(document.originalURL.absoluteString, "https://publisher.example/blocked")
        XCTAssertNil(document.body.en)
    }
}
