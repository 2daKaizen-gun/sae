import Testing
@testable import SaeTiming

/// 冴え度 산출 검증 — 무효 세션 차단·재정규화·설명 데이터(score-algorithm §4·§5·§1-3).
struct SaeScoreTests {
    private func summary(
        responded: Int, lapses: Int, falseStarts: Int, median: Double?, fastest: Double?
    ) -> PVTSessionSummary {
        PVTSessionSummary(
            trialCount: responded + falseStarts,
            respondedCount: responded,
            lapseCount: lapses,
            falseStartCount: falseStarts,
            noResponseCount: 0,
            meanRTms: median,
            medianRTms: median,
            fastest10PctMeanRTms: fastest
        )
    }

    /// **문서 §6 워크드 예시 전체**: 각성 60.4 · HRV/손떨림 없음 → 재정규화 → 冴え度 **60**.
    @Test func reproducesTheDocumentedFinalScore() {
        let result = SaeScorer.score(
            from: summary(responded: 24, lapses: 3, falseStarts: 1, median: 342, fastest: 268),
            validity: .valid
        )
        #expect(result?.score == 60)
        #expect(result?.appliedWeights == [.arousal: 1.0])
    }

    /// 무효 세션(false start 과다)은 **점수를 만들지 않는다** — 억지 숫자보다 "못 쟀다"가 정직하다.
    @Test func invalidSessionProducesNoScore() {
        let result = SaeScorer.score(
            from: summary(responded: 12, lapses: 0, falseStarts: 5, median: 300, fastest: 250),
            validity: .invalid(reason: .tooManyFalseStarts)
        )
        #expect(result == nil)
    }

    /// 응답 부족으로 무효인 세션도 마찬가지다.
    @Test func tooFewResponsesProducesNoScore() {
        let result = SaeScorer.score(
            from: summary(responded: 3, lapses: 0, falseStarts: 0, median: 300, fastest: 280),
            validity: .invalid(reason: .tooFewValidTrials)
        )
        #expect(result == nil)
    }

    /// 각성만 있는 날: 가중치 0.60이 **1.00으로 재정규화**된다(§4). 결측은 벌점이 아니다.
    @Test func arousalOnlyRenormalizesToOne() {
        let weights = SaeScorer.normalizedWeights(for: [.arousal])
        #expect(weights == [.arousal: 1.0])
    }

    /// 각성+피로만 있는 날: 0.60/0.75 = 0.80 · 0.15/0.75 = 0.20 (§4의 예시 그대로).
    @Test func renormalizationMatchesDocumentedExample() {
        let weights = SaeScorer.normalizedWeights(for: [.arousal, .fatigue])
        #expect(abs((weights[.arousal] ?? 0) - 0.80) < 1e-9)
        #expect(abs((weights[.fatigue] ?? 0) - 0.20) < 1e-9)
    }

    /// 기본 가중치는 문서 §4 표와 같고 셋을 합하면 1.0이다.
    @Test func defaultWeightsMatchTheDocument() {
        #expect(SaeScore.Component.arousal.defaultWeight == 0.60)
        #expect(SaeScore.Component.autonomic.defaultWeight == 0.25)
        #expect(SaeScore.Component.fatigue.defaultWeight == 0.15)
        let all = SaeScore.Component.allCases.reduce(0.0) { $0 + $1.defaultWeight }
        #expect(abs(all - 1.0) < 1e-12)
    }

    /// 빠진 성분을 **숨기지 않고 남긴다** — MVP에서는 자율신경·피로가 항상 결측이다(제2조 3항).
    @Test func missingComponentsAreReported() {
        let result = SaeScorer.score(
            from: summary(responded: 12, lapses: 1, falseStarts: 0, median: 330, fastest: 270),
            validity: .valid
        )
        #expect(result?.missingComponents.sorted { $0.rawValue < $1.rawValue } == [.autonomic, .fatigue])
    }

    /// 설명 데이터가 원지표를 그대로 들고 있다 — 표시 계층이 문장을 만들 재료(§5).
    @Test func evidenceCarriesTheRawMetrics() {
        let result = SaeScorer.score(
            from: summary(responded: 24, lapses: 3, falseStarts: 1, median: 342, fastest: 268),
            validity: .valid
        )
        #expect(result?.evidence == SaeScore.Evidence(
            lapseCount: 3, respondedCount: 24, medianRTms: 342,
            fastest10PctMeanRTms: 268, falseStartCount: 1
        ))
    }

    /// 점수는 0~100 정수 범위를 벗어나지 않는다(양 극단).
    @Test func scoreStaysWithinBounds() {
        let best = SaeScorer.score(
            from: summary(responded: 12, lapses: 0, falseStarts: 0, median: 200, fastest: 180),
            validity: .valid
        )
        let worst = SaeScorer.score(
            from: summary(responded: 12, lapses: 8, falseStarts: 0, median: 900, fastest: 800),
            validity: .valid
        )
        #expect(best?.score == 100)
        #expect(worst?.score == 0)
    }
}
