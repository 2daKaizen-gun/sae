import Testing
@testable import SaeTiming

/// 각성 성분 검증 — 가중합·false start 벌점·계산 불가 경계(score-algorithm §1).
struct ArousalScoreTests {
    /// 테스트용 요약 생성기(집계 로직이 아니라 **점수 로직**만 보기 위해 값을 직접 주입한다).
    private func summary(
        responded: Int, lapses: Int, falseStarts: Int,
        median: Double?, fastest: Double?, mean: Double? = nil
    ) -> PVTSessionSummary {
        PVTSessionSummary(
            trialCount: responded + falseStarts,
            respondedCount: responded,
            lapseCount: lapses,
            falseStartCount: falseStarts,
            noResponseCount: 0,
            meanRTms: mean ?? median,
            medianRTms: median,
            fastest10PctMeanRTms: fastest
        )
    }

    /// 완벽한 세션: lapse 0·아주 빠른 RT → 세 하위지표 모두 100 → 100점(상한을 넘지 않는다).
    @Test func perfectSessionScoresOneHundred() {
        let result = ArousalScorer.score(from: summary(
            responded: 12, lapses: 0, falseStarts: 0, median: 200, fastest: 180
        ))
        #expect(result?.score == 100)
    }

    /// 무너진 세션: lapse율 50%·아주 느린 RT → 전부 0점(하한 아래로 내려가지 않는다).
    @Test func collapsedSessionScoresZero() {
        let result = ArousalScorer.score(from: summary(
            responded: 12, lapses: 6, falseStarts: 0, median: 900, fastest: 700
        ))
        #expect(result?.score == 0)
    }

    /// 가중치는 문서 v0 값이고 합이 1.0이다 — 조용히 바뀌면 모든 점수가 달라진다.
    @Test func weightsMatchTheDocumentAndSumToOne() {
        #expect(ArousalScorer.lapseRateWeight == 0.50)
        #expect(ArousalScorer.medianRTWeight == 0.35)
        #expect(ArousalScorer.fastest10PctWeight == 0.15)
        let sum = ArousalScorer.lapseRateWeight + ArousalScorer.medianRTWeight + ArousalScorer.fastest10PctWeight
        #expect(abs(sum - 1.0) < 1e-12)
    }

    /// false start 벌점표(§1-2): 0회 1.00 · 1회 0.97 · 2회 0.92.
    @Test func falseStartFactorMatchesTheTable() {
        #expect(ArousalScorer.falseStartFactor(0) == 1.00)
        #expect(ArousalScorer.falseStartFactor(1) == 0.97)
        #expect(ArousalScorer.falseStartFactor(2) == 0.92)
    }

    /// 벌점은 곱셈으로 적용된다: 같은 세션에 false start만 1회 늘면 정확히 0.97배.
    @Test func falseStartPenaltyIsMultiplicative() {
        let clean = ArousalScorer.score(from: summary(
            responded: 12, lapses: 1, falseStarts: 0, median: 320, fastest: 260
        ))
        let oneFalseStart = ArousalScorer.score(from: summary(
            responded: 12, lapses: 1, falseStarts: 1, median: 320, fastest: 260
        ))
        #expect(clean?.rawScore == oneFalseStart?.rawScore) // 원점수는 같고
        #expect(abs((oneFalseStart?.score ?? 0) - (clean?.score ?? 0) * 0.97) < 1e-9) // 벌점만 다르다
    }

    /// **문서 §6 워크드 예시를 그대로 재현한다.** 문서가 "왜 60점인가"로 공개한 숫자다.
    /// 유효 trial 24 · lapse 3 · 중앙값 342ms · 최속10% 268ms · false start 1회 → 각성 60.4.
    @Test func reproducesTheDocumentedWorkedExample() {
        let result = ArousalScorer.score(from: summary(
            responded: 24, lapses: 3, falseStarts: 1, median: 342, fastest: 268
        ))
        #expect(abs((result?.rawScore ?? 0) - 62.3) < 0.1)
        #expect(result?.falseStartFactor == 0.97)
        #expect(abs((result?.score ?? 0) - 60.4) < 0.1)
    }

    /// 설명에 쓸 재료(하위지표·lapse율)가 결과에 그대로 남는다(제2조 2항).
    @Test func keepsTheIngredientsThatExplainTheScore() {
        let result = ArousalScorer.score(from: summary(
            responded: 24, lapses: 3, falseStarts: 0, median: 342, fastest: 268
        ))
        #expect(abs((result?.lapseRate ?? 0) - 0.125) < 1e-9)
        #expect(abs((result?.lapseRateScore ?? 0) - 58.3) < 0.05)
        #expect(abs((result?.medianRTScore ?? 0) - 63.2) < 0.05)
        #expect(abs((result?.fastest10PctScore ?? 0) - 73.3) < 0.05)
    }

    /// 응답이 하나도 없으면 **점수를 만들지 않는다** — 0점이라는 가짜 숫자를 내지 않는다(제2조 1항).
    @Test func noResponsesYieldsNoScore() {
        let result = ArousalScorer.score(from: summary(
            responded: 0, lapses: 0, falseStarts: 2, median: nil, fastest: nil
        ))
        #expect(result == nil)
    }
}
