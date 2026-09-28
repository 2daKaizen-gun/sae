import Foundation
import HealthKit
import SwiftData
import SaeTiming

/// 건강 앱에서 HRV(SDNN)를 **읽기만** 하는 계층 — 쓰지 않고, 기기 밖으로 보내지 않는다(제3조).
///
/// ## 호출 시점
/// 측정이 **끝난 뒤**에만 부른다. HealthKit 조회는 비동기라 타이밍 루프 안에서 돌면 측정을
/// 오염시킬 수 있다(제1조 1항, timing-engine §6).
///
/// ## 거부와 "데이터 없음"은 구분할 수 없다
/// HealthKit은 개인정보 보호를 위해 **읽기 권한이 거부됐는지 앱에 알려주지 않는다** — 거부되면
/// 그냥 샘플이 0건으로 온다. 그래서 이 계층은 "거부됨"을 판정하지 않고, 결과를 "값 있음 / 값 없음"
/// 둘로만 낸다. 모르는 것을 아는 척하지 않는다(제2조 3항).
@MainActor
enum HealthKitHRV {
    /// 조회 결과.
    enum Outcome: Equatable {
        /// 기기에 건강 데이터 저장소가 없다(예: 일부 iPad).
        case unavailable
        /// 신선도 창 안에 쓸 수 있는 값이 없다 — 기록이 없거나, 권한이 없거나(구분 불가).
        case none
        /// 표시할 값. 저장까지 끝난 상태다.
        case reading(HRVSample)
    }

    private static let store = HKHealthStore()
    private static let hrvType = HKQuantityType(.heartRateVariabilitySDNN)

    /// 읽기 권한을 요청한다. 시스템 시트에는 `NSHealthShareUsageDescription`(3언어)이 뜬다.
    ///
    /// 이미 한 번 답한 사용자에게는 시트가 다시 뜨지 않는다 — 호출해도 해가 없다.
    /// 쓰기 권한은 요청하지 않는다(`toShare: []`).
    static func requestReadAccess() async throws {
        try await store.requestAuthorization(toShare: [], read: [hrvType])
    }

    /// 신선도 창 안의 HRV 샘플을 읽어 가장 최근 것을 고르고, `HRVReading`으로 저장한다.
    ///
    /// 고르는 규칙은 순수 `HRVSelection.latestFresh`가 정한다(테스트로 증명됨). 같은 HealthKit
    /// 샘플은 UUID로 한 번만 저장한다.
    static func refresh(in context: ModelContext, now: Date = Date()) async throws -> Outcome {
        guard HKHealthStore.isHealthDataAvailable() else { return .unavailable }

        let since = now.addingTimeInterval(-HRVSelection.defaultMaxAge)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: hrvType, predicate: HKQuery.predicateForSamples(
                withStart: since, end: now, options: .strictStartDate
            ))],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)]
        )
        let samples = try await descriptor.result(for: store)

        let candidates = samples.map { sample in
            (id: sample.uuid, value: HRVSample(
                measuredAt: sample.startDate,
                sdnnMs: sample.quantity.doubleValue(for: .secondUnit(with: .milli))
            ))
        }
        guard let picked = HRVSelection.latestFresh(candidates.map(\.value), now: now),
              let pickedID = candidates.first(where: { $0.value == picked })?.id
        else { return .none }

        try save(picked, sampleID: pickedID, in: context)
        return .reading(picked)
    }

    /// 같은 샘플이 이미 있으면 그대로 두고, 없을 때만 넣는다.
    private static func save(_ sample: HRVSample, sampleID: UUID, in context: ModelContext) throws {
        let existing = FetchDescriptor<HRVReading>(predicate: #Predicate { $0.healthKitSampleID == sampleID })
        guard try context.fetch(existing).isEmpty else { return }
        context.insert(HRVReading(
            measuredAt: sample.measuredAt,
            sdnnMs: sample.sdnnMs,
            source: "healthKit",
            isEstimated: false,
            healthKitSampleID: sampleID
        ))
        try context.save()
    }
}
