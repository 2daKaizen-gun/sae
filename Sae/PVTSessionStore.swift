import Foundation
import QuartzCore
import SwiftData
import SaeTiming

/// 측정 결과를 온디바이스에 남긴다 — 서버로 보내지 않는다(제3조).
///
/// 저장은 **측정이 끝난 뒤**에만 일어난다. 타이밍 루프 안에서 디스크를 건드리면 측정이 오염된다
/// (제1조 1항, timing-engine §6).
enum PVTSessionStore {
    /// 세션 한 건과 그 trial 원자료를 저장한다.
    static func save(_ result: PVTSessionResult, in context: ModelContext) throws {
        // 단조 시각 → 벽시계 변환은 **여기서 한 번만** 한다. 측정은 끝까지 단조 시계로 했고,
        // 벽시계 값은 "언제 쟀나"를 사람이 읽기 위한 것이다(timing-engine §2). 반응시간은 이미
        // 계산돼 저장되므로, 저장된 벽시계 값을 다시 빼서 RT를 구하는 일은 없다.
        let now = Date()
        let nowMonotonic = CACurrentMediaTime()
        func wallClock(_ monotonic: TimeInterval?) -> Date? {
            monotonic.map { now.addingTimeInterval($0 - nowMonotonic) }
        }

        let summary = result.summary
        let session = PVTSession(
            startedAt: result.startedAt,
            durationMs: Int(((result.endTime - result.startTime) * 1_000).rounded()),
            stimulusCount: result.trials.count(where: { $0.onsetTime != nil }),
            meanRTms: summary.meanRTms,
            medianRTms: summary.medianRTms,
            fastest10PctMeanRTms: summary.fastest10PctMeanRTms,
            lapseCount: summary.lapseCount,
            falseStartCount: summary.falseStartCount,
            displayRefreshHz: result.displayRefreshHz,
            calibrationOffsetMs: result.calibrationOffsetMs,
            isValid: result.validity == .valid,
            invalidReason: invalidReasonCode(result.validity)
        )
        context.insert(session)

        for record in result.trials {
            let trial = PVTTrial(
                index: record.index,
                interStimulusMs: record.interStimulusMs,
                reactionTimeMs: record.outcome.reactionTimeMs,
                isLapse: isLapse(record.outcome),
                isFalseStart: record.outcome == .falseStart,
                stimulusAt: wallClock(record.onsetTime),
                respondedAt: wallClock(record.responseTime)
            )
            trial.session = session
            context.insert(trial)
        }

        try upsertDailyScore(for: result, session: session, in: context)

        try context.save()
    }

    /// 세션에서 冴え度를 계산해 그날의 `DailyScore`에 반영한다.
    ///
    /// **무효 세션이면 아무것도 쓰지 않는다** — `SaeScorer`가 `nil`을 주고, 그 경우 그날 점수는
    /// 만들어지지 않는다(score-algorithm §1-3). 억지 숫자를 남기는 것보다 빈칸이 정직하다(제2조 1항).
    ///
    /// 하루에 여러 번 측정하면 **같은 날의 기존 점수를 갱신**한다(data-model: 하루 1개).
    /// "그날의 마지막 유효 측정"이 그날의 점수라는 뜻이다 — 최고 기록만 남기면 좋은 날만 모은
    /// 기록이 되어 추이가 왜곡된다. 어떤 규칙이 맞는지는 실사용 뒤 재검토할 열린 결정이다.
    private static func upsertDailyScore(
        for result: PVTSessionResult, session: PVTSession, in context: ModelContext
    ) throws {
        guard let sae = SaeScorer.score(from: result.summary, validity: result.validity) else { return }

        let day = Calendar.current.startOfDay(for: result.startedAt)
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: day) ?? day
        let sameDay = FetchDescriptor<DailyScore>(
            predicate: #Predicate { $0.day >= day && $0.day < nextDay }
        )

        if let existing = try context.fetch(sameDay).first {
            existing.score = sae.score
            existing.arousalComponent = sae.arousal.score
            existing.lapseCount = sae.evidence.lapseCount
            existing.respondedCount = sae.evidence.respondedCount
            existing.medianRTms = sae.evidence.medianRTms
            existing.fastest10PctMeanRTms = sae.evidence.fastest10PctMeanRTms
            existing.falseStartCount = sae.evidence.falseStartCount
            existing.session = session
            return
        }

        let daily = DailyScore(
            day: day,
            score: sae.score,
            arousalComponent: sae.arousal.score,
            lapseCount: sae.evidence.lapseCount,
            respondedCount: sae.evidence.respondedCount,
            medianRTms: sae.evidence.medianRTms,
            fastest10PctMeanRTms: sae.evidence.fastest10PctMeanRTms,
            falseStartCount: sae.evidence.falseStartCount,
            session: session
        )
        context.insert(daily)
    }

    /// 무효 사유를 **안정된 코드**로 남긴다. 화면에 보일 문장은 String Catalog가 만든다(제5조 1항).
    private static func invalidReasonCode(_ validity: SessionValidity) -> String? {
        switch validity {
        case .valid: return nil
        case .invalid(.tooManyFalseStarts): return "tooManyFalseStarts"
        case .invalid(.tooFewValidTrials): return "tooFewValidTrials"
        }
    }

    private static func isLapse(_ outcome: TrialOutcome) -> Bool {
        if case .lapse = outcome { return true }
        return false
    }
}
