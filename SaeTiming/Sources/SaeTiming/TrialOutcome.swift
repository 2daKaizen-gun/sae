import Foundation

/// 한 trial(자극-반응 1회)의 판정 결과 — 순수 분류(score-algorithm §1, data-model `PVTTrial`).
public enum TrialOutcome: Equatable {
    /// 유효 응답. 보정 적용된 반응시간(ms).
    case valid(reactionTimeMs: Double)
    /// lapse — 응답은 했으나 임계값(기본 500ms) 초과. 수면부족에 가장 민감한 지표(score-algorithm §1-1).
    case lapse(reactionTimeMs: Double)
    /// false start — 자극 온셋 **전에** 탭. 충동·부주의·꼼수 신호(score-algorithm §1-2).
    case falseStart
    /// 무응답 — 타임아웃까지 탭 없음. RT는 null(data-model: `reactionTimeMs` nil).
    case noResponse
}

/// trial 판정 로직 — 순수 함수(제1조 3항: 정확도는 테스트로 증명, "나중에 테스트" 없음).
public enum TrialClassifier {
    /// 기본 lapse 임계값 500ms (CONCEPT §1, score-algorithm §1-1, timing-engine §8-1).
    public static let defaultLapseThresholdMs = 500.0

    /// 기본 무응답 타임아웃 30초 — PVT 표준. 확정값은 아니며(score-algorithm §1-3 열린 결정),
    /// 원자료(timestamp)를 보존하므로 나중에 다른 문턱으로 재계산할 수 있다.
    public static let defaultTimeoutMs = 30_000.0

    /// trial 하나를 분류한다. `touchTs == nil`이면 무응답으로 본다.
    ///
    /// 판정 순서(경계 정의를 명확히 하기 위해 고정):
    /// 1. 탭 없음 → `.noResponse`
    /// 2. 자극 온셋 전 탭(`touchTs < stimulusTs`) → `.falseStart` (음수 RT를 만들지 않는다)
    /// 3. 타임아웃 창 초과 → `.noResponse`
    /// 4. 보정 RT > lapse 임계값 → `.lapse`, 그 외 → `.valid`
    public static func classify(
        stimulusTs: Double,
        touchTs: Double?,
        calibrationOffsetMs: Double = 0,
        lapseThresholdMs: Double = defaultLapseThresholdMs,
        timeoutMs: Double = defaultTimeoutMs
    ) -> TrialOutcome {
        guard let touchTs else { return .noResponse }

        // 자극 전 탭 = false start. 보정 오프셋과 무관하게 온셋 이전인지로만 판정한다.
        if touchTs < stimulusTs { return .falseStart }

        // 타임아웃 창을 넘겨 들어온 탭은 무응답으로 본다(보정 전 원간격 기준).
        let rawIntervalMs = (touchTs - stimulusTs) * 1000.0
        if rawIntervalMs >= timeoutMs { return .noResponse }

        let rt = ReactionTime.milliseconds(
            stimulusTs: stimulusTs, touchTs: touchTs, calibrationOffsetMs: calibrationOffsetMs
        )
        return rt > lapseThresholdMs ? .lapse(reactionTimeMs: rt) : .valid(reactionTimeMs: rt)
    }
}
