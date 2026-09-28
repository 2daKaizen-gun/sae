import Foundation

/// HRV 샘플 한 건 — HealthKit의 SDNN(ms)과 그 측정 시각.
///
/// HealthKit이 주는 HRV는 **SDNN**이다(RMSSD 아님, score-algorithm §2). 이름에 지표를 박아 두어
/// 다른 통계량과 섞이지 않게 한다(제2조 1항).
public struct HRVSample: Equatable, Sendable {
    public let measuredAt: Date
    public let sdnnMs: Double

    public init(measuredAt: Date, sdnnMs: Double) {
        self.measuredAt = measuredAt
        self.sdnnMs = sdnnMs
    }
}

/// 여러 HRV 샘플 중 **지금 보여줄 한 건**을 고른다(순수 함수).
///
/// 애플워치는 HRV를 하루 몇 번 띄엄띄엄 기록한다. 오래된 값을 "오늘의 HRV"처럼 보여주면 사실이
/// 아니므로, 신선한 창 안에 값이 없으면 **없다고 답한다**(제2조 3항 — 한계를 숨기지 않는다).
public enum HRVSelection {
    /// 신선도 창 24시간. 수면 중 기록까지 "오늘 아침의 상태"로 담는 폭이다.
    /// **문헌값이 아니라 표시상의 선택**이며 튜닝 대상이다(제2조 1항).
    public static let defaultMaxAge: TimeInterval = 24 * 60 * 60

    /// `now` 기준 `maxAge` 안(경계 포함)의 샘플 중 가장 최근 것. 없으면 `nil`.
    ///
    /// - 미래 시각의 샘플은 버린다 — 시계가 어긋난 기록을 "최신"으로 믿지 않는다.
    /// - 유한한 양수가 아닌 값은 버린다 — SDNN은 0 이하일 수 없다.
    public static func latestFresh(
        _ samples: [HRVSample],
        now: Date,
        maxAge: TimeInterval = defaultMaxAge
    ) -> HRVSample? {
        samples
            .filter { sample in
                let age = now.timeIntervalSince(sample.measuredAt)
                return age >= 0 && age <= maxAge && sample.sdnnMs.isFinite && sample.sdnnMs > 0
            }
            .max { $0.measuredAt < $1.measuredAt }
    }
}
