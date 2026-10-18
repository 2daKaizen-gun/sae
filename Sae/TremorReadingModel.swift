import Foundation
import SwiftData

/// 손떨림 한 건 — 온디바이스 저장 모델(data-model `TremorReading`).
///
/// 값은 5–12 Hz 대역 RMS(m/s²)와 정점 주파수다(score-algorithm §3-1, Santos et al. 2022).
/// **冴え度에 들어가지 않는 참고 지표**이고, 기기 질량이 스펙트럼을 바꾸므로 **같은 기기끼리만** 비교한다
/// — 그래서 어느 기종에서 쟀는지(`deviceModel`)를 함께 남긴다. 서버로 보내지 않는다(제3조).
@Model
final class TremorReading {
    var id: UUID
    var measuredAt: Date
    /// 실제로 기록한 시간(ms). 앞뒤를 잘라내기 **전**.
    var durationMs: Int
    /// 실측 표본률(Hz).
    var sampleRateHz: Double
    /// 5–12 Hz 대역 가속도 RMS(m/s², 세 축 합산).
    var bandRMS: Double
    /// 대역 안 정점 주파수(Hz).
    var peakFrequencyHz: Double
    /// 기종 식별자(예: `iPhone17,1`). 다른 기기와 값을 섞지 않기 위한 키.
    var deviceModel: String

    init(
        id: UUID = UUID(),
        measuredAt: Date,
        durationMs: Int,
        sampleRateHz: Double,
        bandRMS: Double,
        peakFrequencyHz: Double,
        deviceModel: String
    ) {
        self.id = id
        self.measuredAt = measuredAt
        self.durationMs = durationMs
        self.sampleRateHz = sampleRateHz
        self.bandRMS = bandRMS
        self.peakFrequencyHz = peakFrequencyHz
        self.deviceModel = deviceModel
    }
}
