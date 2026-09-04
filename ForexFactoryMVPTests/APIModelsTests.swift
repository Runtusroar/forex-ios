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

    func testBinanceFuturesContractDecodesMarketMetrics() throws {
        let json = #"{"symbol":"BTCUSDT","pair":"BTCUSDT","contract_type":"PERPETUAL","status":"TRADING","base_asset":"BTC","quote_asset":"USDT","margin_asset":"USDT","last_price":102000.0,"weighted_avg_price":101000.0,"price_change":100.0,"price_change_percent":2.5,"high_price":110000.0,"low_price":95000.0,"open_price":100000.0,"volume":1000.0,"quote_volume":102000000.0,"count":100,"volatility_percent":15.0,"updated_at":"2026-09-04T12:20:00Z"}"#
        let contract = try JSONDecoder.api.decode(BinanceFuturesContract.self, from: Data(json.utf8))

        XCTAssertEqual(contract.symbol, "BTCUSDT")
        XCTAssertEqual(contract.contractType, "PERPETUAL")
        XCTAssertEqual(contract.lastPrice, 102_000)
        XCTAssertEqual(contract.quoteVolume, 102_000_000)
        XCTAssertEqual(contract.volatilityPercent, 15.0)
    }
}
