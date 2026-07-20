import Testing
@testable import SaeTiming

/// ISI 스케줄러 검증 — 결정성·범위·개수(timing-engine §8-1: 시드 고정 재현 가능성).
struct ISISchedulerTests {
    /// 같은 시드+개수는 항상 같은 수열을 낸다(재현 가능성).
    @Test func sameSeedProducesSameSequence() {
        let a = ISIScheduler.intervalsMs(count: 20, seed: 42)
        let b = ISIScheduler.intervalsMs(count: 20, seed: 42)
        #expect(a == b)
    }

    /// 다른 시드는 (거의 확실히) 다른 수열을 낸다.
    @Test func differentSeedsProduceDifferentSequences() {
        let a = ISIScheduler.intervalsMs(count: 20, seed: 1)
        let b = ISIScheduler.intervalsMs(count: 20, seed: 2)
        #expect(a != b)
    }

    /// 모든 간격이 지정 범위 [2000, 10000] 안에 있다.
    @Test func allIntervalsWithinRange() {
        let intervals = ISIScheduler.intervalsMs(count: 500, seed: 7)
        #expect(intervals.allSatisfy { (2_000...10_000).contains($0) })
    }

    /// 요청한 개수만큼 정확히 낸다. 0개는 빈 배열.
    @Test func returnsRequestedCount() {
        #expect(ISIScheduler.intervalsMs(count: 30, seed: 0).count == 30)
        #expect(ISIScheduler.intervalsMs(count: 0, seed: 0).isEmpty)
    }
}
