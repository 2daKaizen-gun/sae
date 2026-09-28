import Foundation
import SwiftData

/// HRV 한 건 — 온디바이스 저장 모델(data-model `HRVReading`).
///
/// 값은 **SDNN(ms)**이다. HealthKit이 주는 HRV가 SDNN뿐이기 때문이다(score-algorithm §2). 이 값은
/// **冴え度에 들어가지 않는 참고 지표**다 — SDNN 앵커에 근거가 없어서다(제2조 1항).
/// 건강 앱에서 읽기만 하고, 서버로 보내지 않는다(제3조).
@Model
final class HRVReading {
    var id: UUID
    /// 원래 측정 시각(HealthKit 샘플의 시작 시각). 앱이 읽은 시각이 아니다.
    var measuredAt: Date
    /// 심박 변이도 SDNN(ms).
    var sdnnMs: Double
    /// 출처 — 지금은 `"healthKit"`뿐. 카메라 PPG(스트레치)를 들이면 `"cameraPPG"`가 된다.
    var source: String
    /// 추정치 여부. HealthKit(애플워치) 값은 측정값이라 `false`, 카메라 PPG는 `true`(제2조 3항).
    var isEstimated: Bool
    /// HealthKit 샘플의 UUID. 같은 샘플을 다시 읽어도 **한 번만 저장**하기 위한 키다.
    var healthKitSampleID: UUID?

    init(
        id: UUID = UUID(),
        measuredAt: Date,
        sdnnMs: Double,
        source: String,
        isEstimated: Bool,
        healthKitSampleID: UUID?
    ) {
        self.id = id
        self.measuredAt = measuredAt
        self.sdnnMs = sdnnMs
        self.source = source
        self.isEstimated = isEstimated
        self.healthKitSampleID = healthKitSampleID
    }
}
