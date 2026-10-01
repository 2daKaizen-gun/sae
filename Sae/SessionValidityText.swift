import SaeTiming

extension SessionValidity {
    /// 타당도 문장 — 타이밍 랩과 결과 화면이 **같은 문구**를 쓴다.
    ///
    /// 무효 사유를 화면마다 따로 적으면 같은 판정이 다른 말로 나온다. 판정(`SessionValidator`)이
    /// 하나이듯 그 문장도 하나로 둔다. 문장은 String Catalog로 3언어(제5조).
    var localizedDescription: String {
        switch self {
        case .valid:
            return String(localized: "session.valid")
        case .invalid(.tooManyFalseStarts):
            return String(localized: "session.invalid_false_starts")
        case .invalid(.tooFewValidTrials):
            return String(localized: "session.invalid_few_trials")
        }
    }
}
