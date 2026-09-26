import Foundation
import SwiftData

/// 하루의 冴え度 — 점수와 **그 점수의 근거**를 온디바이스에 남긴다(data-model `DailyScore`).
///
/// ## 왜 문장이 아니라 원지표를 저장하나
/// 처음 설계(data-model)는 `explanation`을 "점수 근거 요약" 문자열로 두었지만, 문장을 저장하면 **저장 시점의
/// 언어가 박제**된다. 사용자가 언어를 바꾸면 점수 설명만 옛 언어로 남고, 카피를 고치면 과거 기록이
/// 새 카피와 어긋난다(제5조 2항 — 세 언어를 동등하게).
/// 그래서 문장 대신 **문장을 만들 재료**(lapse 수·중앙값 RT 등)를 저장하고, 문장은 표시 계층이
/// String Catalog로 만든다. 설명 가능성(제2조 2항)은 오히려 더 강해진다 — 저장된 건 요약문이 아니라
/// 검증 가능한 숫자다.
@Model
final class DailyScore {
    var id: UUID
    /// 하루 키(자정 기준). 하루에 하나만 둔다(data-model: "일 단위, 하루 1개").
    var day: Date
    /// 冴え度 0~100.
    var score: Int

    /// 각성 성분(PVT). MVP에서는 이 성분만으로 점수가 난다.
    var arousalComponent: Double
    /// 자율신경 성분 — MVP에서는 항상 nil(측정하지 않음, 점수에도 넣지 않음).
    var autonomicComponent: Double?
    /// 피로 성분 — MVP에서는 항상 nil.
    var fatigueComponent: Double?

    // MARK: 설명 재료(제2조 2항) — "왜 이 점수인가"에 답하는 원지표

    var lapseCount: Int
    var respondedCount: Int
    var medianRTms: Double
    var fastest10PctMeanRTms: Double
    var falseStartCount: Int

    /// 이 점수를 만든 세션. 원자료까지 거슬러 올라갈 수 있어야 사후 검증이 된다(제1조 3항).
    var session: PVTSession?

    init(
        id: UUID = UUID(),
        day: Date,
        score: Int,
        arousalComponent: Double,
        autonomicComponent: Double? = nil,
        fatigueComponent: Double? = nil,
        lapseCount: Int,
        respondedCount: Int,
        medianRTms: Double,
        fastest10PctMeanRTms: Double,
        falseStartCount: Int,
        session: PVTSession? = nil
    ) {
        self.id = id
        self.day = day
        self.score = score
        self.arousalComponent = arousalComponent
        self.autonomicComponent = autonomicComponent
        self.fatigueComponent = fatigueComponent
        self.lapseCount = lapseCount
        self.respondedCount = respondedCount
        self.medianRTms = medianRTms
        self.fastest10PctMeanRTms = fastest10PctMeanRTms
        self.falseStartCount = falseStartCount
        self.session = session
    }
}
