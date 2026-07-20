import Foundation

/// 반응시간 계산 — 순수 함수 (제1조: 타이밍 수학은 부작용·UI 없이 테스트로 증명한다).
///
/// 입력 타임스탬프는 **단조 고정밀 시계(초 단위)** 값이라고 가정한다:
/// 자극 온셋은 `CADisplayLink.timestamp`, 응답은 `UITouch.timestamp` — 둘은 같은 단조 기준이라
/// 직접 뺄 수 있다(timing-engine §2·§4). 벽시계(`Date`)는 여기에 넣지 않는다.
public enum ReactionTime {
    /// 반응시간(ms) = (탭 시각 − 자극 온셋 시각) × 1000 − 보정 오프셋.
    ///
    /// timing-engine §4의 공식 그대로다. **부호를 그대로 보존한다** — 음수가 나오면
    /// 자극 전 탭(false start)이라는 신호이고, 그 판정은 `TrialClassifier`가 한다.
    /// 정밀도를 지키기 위해 여기서 반올림하지 않는다(제1조).
    public static func milliseconds(stimulusTs: Double, touchTs: Double, calibrationOffsetMs: Double) -> Double {
        (touchTs - stimulusTs) * 1000.0 - calibrationOffsetMs
    }
}
