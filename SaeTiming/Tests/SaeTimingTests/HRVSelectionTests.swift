import Foundation
import Testing
@testable import SaeTiming

/// HRV 표시값 고르기 — 신선도 경계·최신 우선·빈 입력·이상값.
struct HRVSelectionTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let hour: TimeInterval = 60 * 60

    private func sample(hoursAgo: Double, sdnn: Double) -> HRVSample {
        HRVSample(measuredAt: now.addingTimeInterval(-hoursAgo * hour), sdnnMs: sdnn)
    }

    @Test func picksTheLatestFreshSample() {
        let picked = HRVSelection.latestFresh(
            [sample(hoursAgo: 10, sdnn: 40), sample(hoursAgo: 2, sdnn: 55), sample(hoursAgo: 5, sdnn: 30)],
            now: now
        )
        #expect(picked?.sdnnMs == 55)
    }

    /// 창 경계는 포함, 한 순간이라도 넘으면 제외 — 오래된 값을 오늘 값처럼 보이지 않는다.
    @Test func freshnessBoundaryIsInclusive() {
        #expect(HRVSelection.latestFresh([sample(hoursAgo: 24, sdnn: 42)], now: now)?.sdnnMs == 42)
        let stale = HRVSample(measuredAt: now.addingTimeInterval(-24 * hour - 1), sdnnMs: 42)
        #expect(HRVSelection.latestFresh([stale], now: now) == nil)
    }

    @Test func onlyStaleSamplesMeansNone() {
        #expect(HRVSelection.latestFresh([sample(hoursAgo: 30, sdnn: 60), sample(hoursAgo: 48, sdnn: 70)], now: now) == nil)
    }

    @Test func emptyInputMeansNone() {
        #expect(HRVSelection.latestFresh([], now: now) == nil)
    }

    @Test func ignoresFutureAndNonPositiveValues() {
        let picked = HRVSelection.latestFresh(
            [sample(hoursAgo: -1, sdnn: 80), sample(hoursAgo: 1, sdnn: 0), sample(hoursAgo: 1, sdnn: .nan),
             sample(hoursAgo: 3, sdnn: 35)],
            now: now
        )
        #expect(picked?.sdnnMs == 35)
    }

    @Test func customWindowIsHonoured() {
        let samples = [sample(hoursAgo: 3, sdnn: 50)]
        #expect(HRVSelection.latestFresh(samples, now: now, maxAge: 2 * hour) == nil)
        #expect(HRVSelection.latestFresh(samples, now: now, maxAge: 4 * hour)?.sdnnMs == 50)
    }
}
