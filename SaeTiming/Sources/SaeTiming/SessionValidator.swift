import Foundation

/// 세션 타당도 판정 결과 — 무효면 이유를 함께 남긴다(설명 가능성, 제2조).
public enum SessionValidity: Equatable {
    case valid
    case invalid(reason: InvalidReason)

    /// 무효 사유. data-model `PVTSession.isValid=false`의 근거이자, さえちゃん의 "측정이 흔들렸어요"
    /// 안내(character-voice §7)의 입력이 된다.
    public enum InvalidReason: Equatable {
        /// false start 과다 — 충동·꼼수로 측정 신뢰도가 무너짐.
        case tooManyFalseStarts
        /// 유효 응답 부족 — 표본이 너무 적어 지표를 신뢰할 수 없음.
        case tooFewValidTrials
    }
}

/// 세션 타당도 게이트 — score-algorithm §1-3.
///
/// 제2조(가짜 숫자 금지): 억지로 점수를 만들기보다 "오늘은 못 쟀어요"가 정직하다.
/// 무효 세션은 `DailyScore`를 만들지 않거나 "측정 불충분"으로 표시하는 근거가 된다.
/// 임계값은 문서의 예시값이며 튜닝 대상(score-algorithm 열린 결정).
public enum SessionValidator {
    /// 이 수 **이상**의 false start면 무효(score-algorithm §1-2 표: 3+ → 세션 무효).
    public static let defaultMaxFalseStarts = 3
    /// 유효 응답이 이 수 **미만**이면 무효(score-algorithm §1-3 예시: 최소 5).
    public static let defaultMinValidTrials = 5

    /// 요약 지표로 세션의 타당도를 판정한다. false start 과다를 먼저 본다(신뢰도 우선).
    ///
    /// - Parameter minValidTrials: `respondedCount`(valid+lapse, RT가 있는 응답)의 하한.
    ///   lapse도 "느리지만 응답한" 유효 측정이므로 포함한다.
    public static func evaluate(
        _ summary: PVTSessionSummary,
        maxFalseStarts: Int = defaultMaxFalseStarts,
        minValidTrials: Int = defaultMinValidTrials
    ) -> SessionValidity {
        if summary.falseStartCount >= maxFalseStarts {
            return .invalid(reason: .tooManyFalseStarts)
        }
        if summary.respondedCount < minValidTrials {
            return .invalid(reason: .tooFewValidTrials)
        }
        return .valid
    }
}
