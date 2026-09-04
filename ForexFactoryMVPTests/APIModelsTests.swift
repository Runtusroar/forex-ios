import XCTest
@testable import ForexFactoryMVP

final class APIModelsTests: XCTestCase {
    func testCalendarEventDecodesWithoutChineseTranslation() throws {
        let json = #"{"source_id":"1","event_at":"2026-09-01T12:00:00Z","currency":"USD","impact":"high","title_en":"ISM Manufacturing PMI","title_zh":null,"actual":"51.2","forecast":"50.5","previous":"49.8","updated_at":"2026-09-01T12:01:00Z"}"#
        let event = try JSONDecoder.api.decode(CalendarEvent.self, from: Data(json.utf8))

        XCTAssertEqual(event.titleEN, "ISM Manufacturing PMI")
        XCTAssertNil(event.titleZH)
        XCTAssertEqual(event.impact, .high)
        XCTAssertNil(event.sourceTimeText)
        XCTAssertEqual(event.sourcePosition, 0)
    }

    func testCalendarEventDecodesForexFactoryTimeLabelAndPosition() throws {
        let json = #"{"source_id":"151045","event_at":"2026-09-08T16:00:00Z","currency":"USD","impact":"low","title_en":"ADP Weekly Employment Change","title_zh":null,"actual":null,"forecast":null,"previous":"11.8K","source_time_text":"Aug 23rd","source_position":9,"updated_at":"2026-09-04T15:30:00Z"}"#
        let event = try JSONDecoder.api.decode(CalendarEvent.self, from: Data(json.utf8))

        XCTAssertEqual(event.sourceTimeText, "Aug 23rd")
        XCTAssertEqual(event.sourcePosition, 9)
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

    func testNewsSegmentDecodesFaithfulTextLinkAndPresentation() throws {
        let json = #"{"id":4,"stable_key":"body-1","position":1,"type":"article","author_name":null,"author_handle":null,"published_at":null,"published_at_source_text":null,"text":{"en":"Forex Factory excerpt...","zh_hans":"外汇工厂摘要……"},"source_url":"https://publisher.example/story","is_excerpt":true,"presentation":{"mode":"clamped","max_lines":10,"action_label":"Show More"},"media":[],"links":[{"id":11,"position":0,"kind":"full_story","label":"full story","url":"https://publisher.example/story"}]}"#

        let segment = try JSONDecoder.api.decode(NewsSegment.self, from: Data(json.utf8))

        XCTAssertEqual(segment.text.en, "Forex Factory excerpt...")
        XCTAssertEqual(segment.links.count, 1)
        XCTAssertEqual(segment.links[0].kind, .fullStory)
        XCTAssertEqual(segment.links[0].label, "full story")
        XCTAssertEqual(segment.links[0].url.absoluteString, "https://publisher.example/story")
        XCTAssertEqual(segment.presentation.mode, .clamped)
        XCTAssertEqual(segment.presentation.maxLines, 10)
        XCTAssertEqual(segment.presentation.actionLabel, "Show More")
    }

    func testPresentationModelBuildsInlineLinkAndExternalAction() throws {
        let json = #"{"id":4,"stable_key":"body-1","position":1,"type":"social","author_name":"Donald J. Trump","author_handle":"@realDonaldTrump","published_at":null,"published_at_source_text":null,"text":{"en":"Forex Factory excerpt...","zh_hans":"外汇工厂摘要……"},"source_url":"https://truthsocial.com/post/1","is_excerpt":true,"presentation":{"mode":"clamped","max_lines":10,"action_label":"Show More"},"media":[],"links":[{"id":11,"position":0,"kind":"full_story","label":"full story","url":"https://publisher.example/story"}]}"#
        let segment = try JSONDecoder.api.decode(NewsSegment.self, from: Data(json.utf8))

        let presentation = NewsSegmentPresentationModel(segment: segment)

        XCTAssertEqual(
            presentation.attributedEnglish.map { String($0.characters) },
            "Forex Factory excerpt... (full story)"
        )
        let linkedLabels = presentation.attributedEnglish?.runs.compactMap { run in
            run.link == nil ? nil : String(presentation.attributedEnglish![run.range].characters)
        }
        XCTAssertEqual(linkedLabels, ["full story"])
        XCTAssertEqual(
            presentation.attributedEnglish?.runs.compactMap(\.link),
            [URL(string: "https://publisher.example/story")!]
        )
        XCTAssertEqual(presentation.lineLimit, 10)
        XCTAssertEqual(presentation.externalAction?.label, "Show More")
        XCTAssertEqual(
            presentation.externalAction?.url,
            URL(string: "https://truthsocial.com/post/1")
        )
        XCTAssertEqual(
            presentation.primaryExternalURL,
            URL(string: "https://publisher.example/story")
        )
    }

    func testBinanceFuturesContractDecodesMarketMetrics() throws {
        let json = #"{"symbol":"BTCUSDT","pair":"BTCUSDT","contract_type":"PERPETUAL","market_type":"crypto","underlying_type":"COIN","underlying_subtypes":["Layer 1"],"status":"TRADING","base_asset":"BTC","quote_asset":"USDT","margin_asset":"USDT","last_price":102000.0,"weighted_avg_price":101000.0,"price_change":100.0,"price_change_percent":2.5,"high_price":110000.0,"low_price":95000.0,"open_price":100000.0,"volume":1000.0,"quote_volume":102000000.0,"count":100,"volatility_percent":15.0,"updated_at":"2026-09-04T12:20:00Z"}"#
        let contract = try JSONDecoder.api.decode(BinanceFuturesContract.self, from: Data(json.utf8))

        XCTAssertEqual(contract.symbol, "BTCUSDT")
        XCTAssertEqual(contract.contractType, "PERPETUAL")
        XCTAssertEqual(contract.marketType, "crypto")
        XCTAssertEqual(contract.underlyingType, "COIN")
        XCTAssertEqual(contract.underlyingSubtypes, ["Layer 1"])
        XCTAssertEqual(contract.lastPrice, 102_000)
        XCTAssertEqual(contract.quoteVolume, 102_000_000)
        XCTAssertEqual(contract.volatilityPercent, 15.0)
    }
}
