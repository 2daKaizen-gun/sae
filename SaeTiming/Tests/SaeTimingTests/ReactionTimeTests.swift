import Testing
@testable import SaeTiming

/// 반응시간 공식 검증 — 알려진 합성 입력 → 기대 출력(timing-engine §8-1).
struct ReactionTimeTests {
    /// 온셋 10.0s, 탭 10.3s → 300ms (보정 없음).
    @Test func computesPlainInterval() {
        let rt = ReactionTime.milliseconds(stimulusTs: 10.0, touchTs: 10.3, calibrationOffsetMs: 0)
        #expect(abs(rt - 300.0) < 1e-6)
    }

    /// 보정 오프셋을 빼는지: 300ms − 20ms = 280ms.
    @Test func subtractsCalibrationOffset() {
        let rt = ReactionTime.milliseconds(stimulusTs: 10.0, touchTs: 10.3, calibrationOffsetMs: 20)
        #expect(abs(rt - 280.0) < 1e-6)
    }

    /// 분수 밀리초 정밀도를 반올림 없이 보존한다(제1조).
    @Test func preservesSubMillisecondPrecision() {
        let rt = ReactionTime.milliseconds(stimulusTs: 5.0, touchTs: 5.2505, calibrationOffsetMs: 0)
        #expect(abs(rt - 250.5) < 1e-6)
    }

    /// 탭이 온셋보다 이르면 음수 부호를 그대로 보존한다(분류는 상위 계층 몫).
    @Test func preservesNegativeSignForPreStimulusTap() {
        let rt = ReactionTime.milliseconds(stimulusTs: 10.0, touchTs: 9.9, calibrationOffsetMs: 0)
        #expect(abs(rt - (-100.0)) < 1e-6)
    }
}
