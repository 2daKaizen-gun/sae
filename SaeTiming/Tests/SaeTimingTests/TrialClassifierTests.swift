import Testing
@testable import SaeTiming

/// trial 분류 경계값 검증(timing-engine §8-1: 오프셋·음수 방지·타임아웃·lapse 문턱).
struct TrialClassifierTests {
    /// 정상 응답 300ms → valid.
    @Test func classifiesValidResponse() {
        let outcome = TrialClassifier.classify(stimulusTs: 0, touchTs: 0.3)
        #expect(outcome == .valid(reactionTimeMs: 300.0))
    }

    /// lapse 경계: 정확히 500ms는 lapse가 아니다(> 500만 lapse).
    @Test func lapseThresholdIsExclusive() {
        let atThreshold = TrialClassifier.classify(stimulusTs: 0, touchTs: 0.5)
        #expect(atThreshold == .valid(reactionTimeMs: 500.0))

        let overThreshold = TrialClassifier.classify(stimulusTs: 0, touchTs: 0.6)
        #expect(overThreshold == .lapse(reactionTimeMs: 600.0))
    }

    /// 자극 전 탭 → falseStart. 음수 RT를 만들지 않는다("음수 방지").
    @Test func classifiesPreStimulusTapAsFalseStart() {
        let outcome = TrialClassifier.classify(stimulusTs: 10.0, touchTs: 9.9)
        #expect(outcome == .falseStart)
    }

    /// 탭 없음(nil) → noResponse.
    @Test func classifiesMissingTapAsNoResponse() {
        let outcome = TrialClassifier.classify(stimulusTs: 0, touchTs: nil)
        #expect(outcome == .noResponse)
    }

    /// 타임아웃 창을 넘겨 들어온 탭 → noResponse.
    @Test func classifiesTapPastTimeoutAsNoResponse() {
        let outcome = TrialClassifier.classify(stimulusTs: 0, touchTs: 2.0, timeoutMs: 1_000)
        #expect(outcome == .noResponse)
    }

    /// 보정 오프셋이 lapse 경계를 넘나드는지: 520ms 원간격 − 30ms 보정 = 490ms → valid.
    @Test func calibrationOffsetMovesAcrossLapseBoundary() {
        let outcome = TrialClassifier.classify(stimulusTs: 0, touchTs: 0.52, calibrationOffsetMs: 30)
        #expect(outcome == .valid(reactionTimeMs: 490.0))
    }
}
