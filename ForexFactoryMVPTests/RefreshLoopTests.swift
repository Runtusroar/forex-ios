import Foundation
import XCTest
@testable import ForexFactoryMVP

private actor RefreshProbe {
    private(set) var calls = 0
    private(set) var active = 0
    private(set) var maximumActive = 0

    func run(delay: Duration = .zero) async {
        calls += 1
        active += 1
        maximumActive = max(maximumActive, active)
        try? await Task.sleep(for: delay)
        active -= 1
    }

    func snapshot() -> (calls: Int, maximumActive: Int) {
        (calls, maximumActive)
    }
}

final class RefreshLoopTests: XCTestCase {
    @MainActor
    func testStartRefreshesImmediatelyAndRepeats() async {
        let probe = RefreshProbe()
        let loop = RefreshLoop(interval: .milliseconds(10))

        loop.start { await probe.run() }
        try? await Task.sleep(for: .milliseconds(45))
        loop.stop()

        let snapshot = await probe.snapshot()
        XCTAssertGreaterThanOrEqual(snapshot.calls, 2)
    }

    @MainActor
    func testManualRefreshJoinsSlowInFlightRefresh() async {
        let probe = RefreshProbe()
        let loop = RefreshLoop(interval: .seconds(10))

        loop.start { await probe.run(delay: .milliseconds(40)) }
        async let first: Void = loop.refreshNow()
        async let second: Void = loop.refreshNow()
        _ = await (first, second)
        loop.stop()

        let snapshot = await probe.snapshot()
        XCTAssertEqual(snapshot.maximumActive, 1)
    }
}
