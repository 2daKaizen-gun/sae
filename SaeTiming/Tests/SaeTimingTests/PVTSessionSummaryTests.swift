import Testing
@testable import SaeTiming

/// 세션 요약 집계 검증 — 순수 파생(data-model PVTSession, score-algorithm §1 입력).
struct PVTSessionSummaryTests {
    /// 유효 응답만: 평균·중앙값·최속10%·카운트.
    @Test func aggregatesValidResponses() {
        let outcomes: [TrialOutcome] = [
            .valid(reactionTimeMs: 500),
            .valid(reactionTimeMs: 100),
            .valid(reactionTimeMs: 300),
            .valid(reactionTimeMs: 200),
            .valid(reactionTimeMs: 400),
        ]
        let s = PVTSessionSummary.make(from: outcomes)
        #expect(s.trialCount == 5)
        #expect(s.respondedCount == 5)
        #expect(s.meanRTms == 300)
        #expect(s.medianRTms == 300)
        // 5개의 10% = 0.5 → 반올림 1개 → 가장 빠른 100.
        #expect(s.fastest10PctMeanRTms == 100)
    }

    /// lapse는 RT 통계에 포함되되 lapseCount로 따로 센다.
    @Test func lapsesCountedAndIncludedInStats() {
        let outcomes: [TrialOutcome] = [
            .valid(reactionTimeMs: 200),
            .lapse(reactionTimeMs: 600),
        ]
        let s = PVTSessionSummary.make(from: outcomes)
        #expect(s.lapseCount == 1)
        #expect(s.respondedCount == 2)
        #expect(s.meanRTms == 400)      // (200+600)/2
        #expect(s.medianRTms == 400)    // 짝수 → 가운데 두 값 평균
    }

    /// false start·무응답은 RT 통계에서 제외되고 각각 카운트된다.
    @Test func falseStartAndNoResponseExcludedFromStats() {
        let outcomes: [TrialOutcome] = [
            .valid(reactionTimeMs: 250),
            .falseStart,
            .noResponse,
            .falseStart,
        ]
        let s = PVTSessionSummary.make(from: outcomes)
        #expect(s.trialCount == 4)
        #expect(s.respondedCount == 1)
        #expect(s.falseStartCount == 2)
        #expect(s.noResponseCount == 1)
        #expect(s.meanRTms == 250)
    }

    /// 응답이 하나도 없으면 RT 지표는 모두 nil.
    @Test func noResponsesYieldsNilStats() {
        let s = PVTSessionSummary.make(from: [.falseStart, .noResponse])
        #expect(s.respondedCount == 0)
        #expect(s.meanRTms == nil)
        #expect(s.medianRTms == nil)
        #expect(s.fastest10PctMeanRTms == nil)
    }

    /// 빈 세션도 안전하게 0/nil로 집계한다.
    @Test func emptySessionAggregatesToZero() {
        let s = PVTSessionSummary.make(from: [])
        #expect(s.trialCount == 0)
        #expect(s.respondedCount == 0)
        #expect(s.medianRTms == nil)
    }

    /// 홀수 개 중앙값은 가운데 값 그대로.
    @Test func oddCountMedianIsMiddleValue() {
        let s = PVTSessionSummary.make(from: [
            .valid(reactionTimeMs: 100),
            .valid(reactionTimeMs: 900),
            .valid(reactionTimeMs: 300),
        ])
        #expect(s.medianRTms == 300)
    }
}
