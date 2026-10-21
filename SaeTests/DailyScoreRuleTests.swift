import Foundation
import SwiftData
import Testing
import SaeTiming
@testable import Sae

/// 하루 점수 규칙 — 하루 1개, 그날의 **마지막 유효 측정**, 무효 세션은 점수를 지우지 않는다(data-model `DailyScore`).
@MainActor
struct DailyScoreRuleTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        container = try ModelContainer(
            for: PVTSession.self, DailyScore.self, HRVReading.self, TremorReading.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    /// 오늘 정해진 시각 — 테스트가 실행 시각(예: 자정 직후)에 따라 날짜를 넘지 않게 고정한다.
    private func today(hour: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hour, to: Calendar.current.startOfDay(for: Date()))!
    }

    private func score(of result: PVTSessionResult) throws -> Int {
        try #require(SaeScorer.score(from: result.summary, validity: result.validity)).score
    }

    @Test func theLastValidSessionOfTheDayIsTheDaysScore() throws {
        let morning = PVTSessionStoreTests.result(valid: true, startedAt: today(hour: 10), lapses: 0)
        let later = PVTSessionStoreTests.result(valid: true, startedAt: today(hour: 11), lapses: 4)
        #expect(try score(of: morning) != score(of: later)) // 두 점수가 실제로 달라야 검증이 의미 있다

        try PVTSessionStore.save(morning, in: context)
        try PVTSessionStore.save(later, in: context)

        let daily = try context.fetch(FetchDescriptor<DailyScore>())
        #expect(daily.count == 1)
        #expect(daily.first?.score == (try score(of: later)))
        #expect(daily.first?.lapseCount == 4)
    }

    /// 나중의 무효 세션은 아무것도 쓰지 않는다 — 그날의 유효 점수가 지워지지 않는다.
    @Test func aLaterInvalidSessionDoesNotEraseTheDaysScore() throws {
        let valid = PVTSessionStoreTests.result(valid: true, startedAt: today(hour: 10))
        try PVTSessionStore.save(valid, in: context)
        try PVTSessionStore.save(PVTSessionStoreTests.result(valid: false, startedAt: today(hour: 11)), in: context)

        let daily = try context.fetch(FetchDescriptor<DailyScore>())
        #expect(daily.count == 1)
        #expect(daily.first?.score == (try score(of: valid)))
        #expect(try context.fetch(FetchDescriptor<PVTSession>()).count == 2) // 무효 세션 자체는 남는다
    }

    @Test func differentDaysKeepSeparateScores() throws {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today(hour: 10))!
        try PVTSessionStore.save(PVTSessionStoreTests.result(valid: true, startedAt: yesterday), in: context)
        try PVTSessionStore.save(PVTSessionStoreTests.result(valid: true, startedAt: today(hour: 10)), in: context)
        #expect(try context.fetch(FetchDescriptor<DailyScore>()).count == 2)
    }
}

/// "첫 측정" 규칙 — さえちゃん이 비교 없이 출발점이라고 말하는 조건(character-voice §7).
struct FirstMeasurementRuleTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private var hourAgo: Date { now.addingTimeInterval(-3_600) }
    private var twoDaysAgo: Date { now.addingTimeInterval(-2 * 86_400) }

    @Test func noHistoryIsFirst() {
        #expect(VoiceCard.isFirstMeasurement(startedAt: now, earlierSessions: [], scoreDays: []))
    }

    @Test func anEarlierValidSessionMeansNotFirst() {
        #expect(!VoiceCard.isFirstMeasurement(startedAt: now, earlierSessions: [(hourAgo, true)], scoreDays: []))
    }

    /// 앞선 측정이 전부 무효였다면 아직 첫 측정이다.
    @Test func onlyEarlierInvalidSessionsStillFirst() {
        #expect(VoiceCard.isFirstMeasurement(startedAt: now, earlierSessions: [(hourAgo, false)], scoreDays: []))
    }

    /// 이 세션 자신(같은 시각)이나 이후의 세션은 "앞선" 것이 아니다.
    @Test func thisOrLaterSessionsDoNotCount() {
        #expect(VoiceCard.isFirstMeasurement(
            startedAt: now, earlierSessions: [(now, true), (now.addingTimeInterval(60), true)], scoreDays: []
        ))
    }

    /// 세션 기록 없이 앞선 날 점수만 있어도(데모 저장소 등) 첫 측정이 아니다.
    @Test func anEarlierDaysScoreMeansNotFirst() {
        #expect(!VoiceCard.isFirstMeasurement(startedAt: now, earlierSessions: [], scoreDays: [twoDaysAgo]))
    }
}
