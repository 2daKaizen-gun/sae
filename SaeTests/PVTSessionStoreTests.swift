import Foundation
import SwiftData
import Testing
import SaeTiming
@testable import Sae

/// 저장 규칙 검증 — 측정 결과가 기기에 **무엇으로** 남는가(data-model, score-algorithm §1-3).
///
/// 시뮬레이터에서 눈으로만 확인하던 규칙을 메모리 전용 SwiftData 저장소로 고정한다.
@MainActor
struct PVTSessionStoreTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        container = try ModelContainer(
            for: PVTSession.self, DailyScore.self, HRVReading.self, TremorReading.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    /// 유효 세션: 12회 응답(랩스 1). 무효 세션: 응답 2회 + 무응답 10회.
    static func result(valid: Bool, startedAt: Date = Date(), lapses: Int = 1) -> PVTSessionResult {
        let outcomes: [TrialOutcome] = valid
            ? (0..<(12 - lapses)).map { .valid(reactionTimeMs: 260 + Double($0) * 10) }
                + (0..<lapses).map { _ in .lapse(reactionTimeMs: 620) }
            : [.valid(reactionTimeMs: 300), .valid(reactionTimeMs: 320)] + Array(repeating: .noResponse, count: 10)
        let trials = outcomes.enumerated().map { index, outcome in
            TrialRecord(
                index: index,
                interStimulusMs: 3_000,
                onsetTime: 100 + Double(index) * 5,
                responseTime: outcome.reactionTimeMs.map { 100 + Double(index) * 5 + $0 / 1_000 },
                outcome: outcome
            )
        }
        let summary = PVTSessionSummary.make(from: outcomes)
        return PVTSessionResult(
            startedAt: startedAt, startTime: 100, endTime: 180,
            displayRefreshHz: 60, calibrationOffsetMs: 0,
            trials: trials, summary: summary, validity: SessionValidator.evaluate(summary)
        )
    }

    @Test func validSessionStoresSessionTrialsAndTheDaysScore() throws {
        let result = Self.result(valid: true)
        try PVTSessionStore.save(result, in: context)

        let sessions = try context.fetch(FetchDescriptor<PVTSession>())
        #expect(sessions.count == 1)
        #expect(sessions.first?.isValid == true)
        #expect(sessions.first?.trials.count == 12)
        #expect(sessions.first?.calibrationOffsetMs == 0) // 미보정 사실이 기록된다

        let daily = try context.fetch(FetchDescriptor<DailyScore>())
        let expected = try #require(SaeScorer.score(from: result.summary, validity: result.validity))
        #expect(daily.count == 1)
        #expect(daily.first?.score == expected.score)
        #expect(daily.first?.lapseCount == 1)
        #expect(daily.first?.day == Calendar.current.startOfDay(for: result.startedAt))
        #expect(daily.first?.session === sessions.first)
    }

    /// 무효 세션은 저장하되 **점수를 만들지 않는다** — 억지 숫자보다 빈칸(score-algorithm §1-3).
    @Test func invalidSessionStoresNoScore() throws {
        try PVTSessionStore.save(Self.result(valid: false), in: context)

        let sessions = try context.fetch(FetchDescriptor<PVTSession>())
        #expect(sessions.count == 1)
        #expect(sessions.first?.isValid == false)
        #expect(sessions.first?.invalidReason == "tooFewValidTrials")
        #expect(try context.fetch(FetchDescriptor<DailyScore>()).isEmpty)
    }

    /// 무응답 trial은 반응시간이 없고 lapse도 아니다(data-model `PVTTrial`).
    @Test func noResponseTrialsHaveNoReactionTimeAndAreNotLapses() throws {
        try PVTSessionStore.save(Self.result(valid: false), in: context)
        let trials = try context.fetch(FetchDescriptor<PVTTrial>())
        let noResponses = trials.filter { $0.reactionTimeMs == nil }
        #expect(noResponses.count == 10)
        #expect(noResponses.allSatisfy { !$0.isLapse && !$0.isFalseStart && $0.respondedAt == nil })
    }
}
