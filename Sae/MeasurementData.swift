import Foundation
import SwiftData

/// 앱이 이 기기에 저장한 측정 기록 — 무엇이 몇 개 있는지 세고, 사용자가 원하면 전부 지운다(헌법 제3조).
///
/// 지우는 대상은 **이 앱이 만든 사본**뿐이다: 세션과 trial 원자료, 하루 점수, 앱이 저장한 HRV·손떨림 값.
/// 건강 앱(HealthKit)의 원본 데이터는 앱이 쓴 적이 없고 지우지도 않는다.
/// 화면과 분리해 두어 앱 테스트가 메모리 저장소로 증명한다.
@MainActor
enum MeasurementData {
    struct Counts: Equatable {
        var sessions = 0
        var trials = 0
        var dailyScores = 0
        var hrvReadings = 0
        var tremorReadings = 0

        var isEmpty: Bool { self == Counts() }
    }

    static func counts(in context: ModelContext) throws -> Counts {
        Counts(
            sessions: try context.fetchCount(FetchDescriptor<PVTSession>()),
            trials: try context.fetchCount(FetchDescriptor<PVTTrial>()),
            dailyScores: try context.fetchCount(FetchDescriptor<DailyScore>()),
            hrvReadings: try context.fetchCount(FetchDescriptor<HRVReading>()),
            tremorReadings: try context.fetchCount(FetchDescriptor<TremorReading>())
        )
    }

    /// 모든 측정 기록을 지운다. 하나씩 지워 SwiftData의 관계 규칙(세션→trial cascade)을 그대로 따르고,
    /// trial은 남는 것이 없도록 마지막에 한 번 더 확인해 지운다.
    static func deleteAll(in context: ModelContext) throws {
        for score in try context.fetch(FetchDescriptor<DailyScore>()) { context.delete(score) }
        for session in try context.fetch(FetchDescriptor<PVTSession>()) { context.delete(session) }
        for trial in try context.fetch(FetchDescriptor<PVTTrial>()) { context.delete(trial) }
        for reading in try context.fetch(FetchDescriptor<HRVReading>()) { context.delete(reading) }
        for reading in try context.fetch(FetchDescriptor<TremorReading>()) { context.delete(reading) }
        try context.save()
    }
}
