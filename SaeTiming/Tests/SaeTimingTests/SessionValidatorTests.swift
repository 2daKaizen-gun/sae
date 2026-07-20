import Testing
@testable import SaeTiming

/// 세션 타당도 게이트 검증(score-algorithm §1-3: 억지 점수보다 "못 쟀어요"가 정직).
struct SessionValidatorTests {
    /// 헬퍼: 유효 응답 n개 + false start f개로 요약을 만든다.
    private func summary(valid: Int, falseStarts: Int) -> PVTSessionSummary {
        let outcomes =
            Array(repeating: TrialOutcome.valid(reactionTimeMs: 300), count: valid)
            + Array(repeating: TrialOutcome.falseStart, count: falseStarts)
        return PVTSessionSummary.make(from: outcomes)
    }

    /// 충분한 응답 + false start 적음 → valid.
    @Test func acceptsCleanSession() {
        #expect(SessionValidator.evaluate(summary(valid: 10, falseStarts: 1)) == .valid)
    }

    /// false start 3개 이상 → 무효(응답이 충분해도).
    @Test func rejectsTooManyFalseStarts() {
        let result = SessionValidator.evaluate(summary(valid: 20, falseStarts: 3))
        #expect(result == .invalid(reason: .tooManyFalseStarts))
    }

    /// false start 2개는 아직 유효(경계: 3 미만).
    @Test func twoFalseStartsStillValid() {
        #expect(SessionValidator.evaluate(summary(valid: 10, falseStarts: 2)) == .valid)
    }

    /// 유효 응답 5개 미만 → 무효.
    @Test func rejectsTooFewValidTrials() {
        let result = SessionValidator.evaluate(summary(valid: 4, falseStarts: 0))
        #expect(result == .invalid(reason: .tooFewValidTrials))
    }

    /// 정확히 5개면 유효(경계).
    @Test func exactlyMinValidTrialsIsValid() {
        #expect(SessionValidator.evaluate(summary(valid: 5, falseStarts: 0)) == .valid)
    }

    /// false start 과다가 응답 부족보다 우선 판정된다.
    @Test func falseStartsTakePrecedence() {
        let result = SessionValidator.evaluate(summary(valid: 2, falseStarts: 4))
        #expect(result == .invalid(reason: .tooManyFalseStarts))
    }
}
