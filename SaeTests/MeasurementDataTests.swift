import Foundation
import SwiftData
import Testing
import SaeTiming
@testable import Sae

/// 측정 기록 지우기 — 앱이 만든 기록은 남김없이, 나머지는 건드리지 않고(헌법 제3조).
@MainActor
struct MeasurementDataTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        container = try ModelContainer(
            for: PVTSession.self, DailyScore.self, HRVReading.self, TremorReading.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    /// 세션 2개(유효·무효), 하루 점수, HRV, 손떨림을 하나씩 채운다.
    private func fill() throws {
        try PVTSessionStore.save(PVTSessionStoreTests.result(valid: true), in: context)
        try PVTSessionStore.save(PVTSessionStoreTests.result(valid: false), in: context)
        context.insert(HRVReading(measuredAt: Date(), sdnnMs: 48, source: "healthKit", isEstimated: false,
                                  healthKitSampleID: UUID()))
        context.insert(TremorReading(measuredAt: Date(), durationMs: 10_000, sampleRateHz: 50,
                                     bandRMS: 0.02, peakFrequencyHz: 8.5, deviceModel: "test"))
        try context.save()
    }

    @Test func countsWhatIsStored() throws {
        try fill()
        let counts = try MeasurementData.counts(in: context)
        #expect(counts == MeasurementData.Counts(sessions: 2, trials: 24, dailyScores: 1, hrvReadings: 1, tremorReadings: 1))
        #expect(!counts.isEmpty)
    }

    /// 지우면 세션·trial 원자료·하루 점수·HRV·손떨림이 전부 0이 된다.
    @Test func deleteAllLeavesNothingBehind() throws {
        try fill()
        try MeasurementData.deleteAll(in: context)
        let counts = try MeasurementData.counts(in: context)
        #expect(counts.isEmpty)
        #expect(try context.fetch(FetchDescriptor<PVTTrial>()).isEmpty) // cascade로 trial까지
    }

    @Test func deletingAnEmptyStoreIsHarmless() throws {
        try MeasurementData.deleteAll(in: context)
        #expect(try MeasurementData.counts(in: context).isEmpty)
    }

    /// 지운 뒤에도 앱은 정상적으로 다시 기록한다.
    @Test func recordingWorksAgainAfterDeletion() throws {
        try fill()
        try MeasurementData.deleteAll(in: context)
        try PVTSessionStore.save(PVTSessionStoreTests.result(valid: true), in: context)
        let counts = try MeasurementData.counts(in: context)
        #expect(counts.sessions == 1 && counts.dailyScores == 1 && counts.trials == 12)
    }
}
