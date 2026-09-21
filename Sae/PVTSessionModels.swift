import Foundation
import SwiftData

/// 한 번의 PVT 측정 — 온디바이스 저장 모델(data-model `PVTSession`).
///
/// 요약 지표를 담되 **원자료는 `trials`에** 둔다. 요약만 남기면 나중에 보정 오프셋이나 lapse
/// 문턱이 바뀌었을 때 재계산·재검증을 할 수 없다(제1조 3항, 제2조 1항).
/// `displayRefreshHz`·`calibrationOffsetMs`는 "어떤 조건에서 쟀는가"를 데이터로 남기는 필드다
/// (제1조 2항, timing-engine §9). 서버로 보내지 않는다(제3조).
@Model
final class PVTSession {
    var id: UUID
    /// 측정 시작 벽시계 시각. **표시·정렬용이며 반응시간 계산에 쓰지 않는다**(timing-engine §2).
    var startedAt: Date
    /// 첫 자극 대기부터 마지막 trial 종료까지 걸린 시간(ms). 단조 시계로 잰 값이다.
    var durationMs: Int
    /// 실제로 켜진 자극 수. false start는 자극을 소비하지 않아 trial 수와 다를 수 있다.
    var stimulusCount: Int
    var meanRTms: Double?
    var medianRTms: Double?
    var fastest10PctMeanRTms: Double?
    var lapseCount: Int
    var falseStartCount: Int
    /// 측정 시 주사율(Hz) — 온셋 불확실성이 주사율에 달려 있어 해석에 필요하다(timing-engine §7).
    var displayRefreshHz: Int
    /// 적용한 보정 오프셋(ms). 지금은 0이며 **미보정**이라는 사실 자체가 기록이다(§8-3, 제2조 3항).
    var calibrationOffsetMs: Double
    /// 타당도 게이트 통과 여부(score-algorithm §1-3).
    var isValid: Bool
    /// 무효 사유. "왜 무효인가"에 답할 수 있어야 하므로 판정과 함께 남긴다(제2조 2항).
    var invalidReason: String?

    @Relationship(deleteRule: .cascade, inverse: \PVTTrial.session)
    var trials: [PVTTrial]

    init(
        id: UUID = UUID(),
        startedAt: Date,
        durationMs: Int,
        stimulusCount: Int,
        meanRTms: Double?,
        medianRTms: Double?,
        fastest10PctMeanRTms: Double?,
        lapseCount: Int,
        falseStartCount: Int,
        displayRefreshHz: Int,
        calibrationOffsetMs: Double,
        isValid: Bool,
        invalidReason: String?,
        trials: [PVTTrial] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.durationMs = durationMs
        self.stimulusCount = stimulusCount
        self.meanRTms = meanRTms
        self.medianRTms = medianRTms
        self.fastest10PctMeanRTms = fastest10PctMeanRTms
        self.lapseCount = lapseCount
        self.falseStartCount = falseStartCount
        self.displayRefreshHz = displayRefreshHz
        self.calibrationOffsetMs = calibrationOffsetMs
        self.isValid = isValid
        self.invalidReason = invalidReason
        self.trials = trials
    }
}

/// 한 번의 자극-반응 원자료(data-model `PVTTrial`).
///
/// 반응시간은 여기 저장된 값이 **단조 시계로 잰 결과**이고, `stimulusAt`·`respondedAt`은 같은
/// 사건을 사람이 읽을 수 있게 벽시계로 옮긴 것이다. 둘의 차이로 반응시간을 다시 구하지 않는다
/// — 벽시계는 조정될 수 있다(timing-engine §2).
@Model
final class PVTTrial {
    var id: UUID
    /// 세션 내 순번. false start는 아직 오지 않은 자극의 순번을 가리킨다.
    var index: Int
    /// 이 trial에 쓰인 자극 대기 시간(ms, 2~10초).
    var interStimulusMs: Int
    /// 보정 적용된 반응시간(ms). 무응답·false start면 nil(data-model: null).
    var reactionTimeMs: Double?
    var isLapse: Bool
    var isFalseStart: Bool
    /// 자극이 표시된 시각(벽시계). **자극 전에 눌러버린 false start는 자극이 없어 nil**이다.
    var stimulusAt: Date?
    /// 응답 시각(벽시계). 무응답이면 nil.
    var respondedAt: Date?

    var session: PVTSession?

    init(
        id: UUID = UUID(),
        index: Int,
        interStimulusMs: Int,
        reactionTimeMs: Double?,
        isLapse: Bool,
        isFalseStart: Bool,
        stimulusAt: Date?,
        respondedAt: Date?
    ) {
        self.id = id
        self.index = index
        self.interStimulusMs = interStimulusMs
        self.reactionTimeMs = reactionTimeMs
        self.isLapse = isLapse
        self.isFalseStart = isFalseStart
        self.stimulusAt = stimulusAt
        self.respondedAt = respondedAt
    }
}
