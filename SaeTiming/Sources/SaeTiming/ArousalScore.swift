import Foundation

/// 각성 성분 계산 결과 — 점수와 **그 점수가 나온 재료**를 함께 들고 있다.
///
/// 성분값만 돌려주면 "왜 60점인가"에 답할 수 없다(제2조 2항). 하위지표 3개와 벌점까지
/// 남겨야 화면·`DailyScore.explanation`이 근거를 그대로 옮길 수 있다.
public struct ArousalScore: Equatable {
    /// lapse율 하위지표(0~100).
    public let lapseRateScore: Double
    /// 중앙값 RT 하위지표(0~100).
    public let medianRTScore: Double
    /// 최속 10% 하위지표(0~100).
    public let fastest10PctScore: Double
    /// 가중합(벌점 적용 전, 0~100).
    public let rawScore: Double
    /// false start 곱셈 벌점(0~1).
    public let falseStartFactor: Double
    /// 최종 각성 성분(0~100) = `rawScore × falseStartFactor`.
    public let score: Double

    /// 계산에 쓰인 lapse율(0~1). 표시·설명용 원지표.
    public let lapseRate: Double
}

/// 각성 성분 — PVT 세션 요약에서 0~100을 만든다(score-algorithm §1).
///
/// **점수의 주(主) 성분이자, MVP에서는 유일한 성분**이다(Phase 2 확정 ①).
/// 입력은 `PVTSessionSummary` 하나뿐이고 부작용이 없으므로 `swift test`로 전부 증명된다.
public enum ArousalScorer {
    /// v0 가중치 — lapse율이 수면부채에 가장 민감하므로 가장 크다(§1-2). 합 = 1.0.
    public static let lapseRateWeight = 0.50
    public static let medianRTWeight = 0.35
    public static let fastest10PctWeight = 0.15

    /// false start 곱셈 벌점(§1-2 표). 3회 이상은 벌점이 아니라 **세션 무효**이므로
    /// (`SessionValidator`) 여기서는 0·1·2회만 의미가 있다.
    public static func falseStartFactor(_ count: Int) -> Double {
        switch count {
        case 0: return 1.00
        case 1: return 0.97
        default: return 0.92 // 2회. 3회 이상은 무효 세션이라 점수 자체를 만들지 않는다
        }
    }

    /// 세션 요약에서 각성 성분을 계산한다.
    ///
    /// - Returns: 응답(valid+lapse)이 하나도 없으면 `nil`. 분모가 없어 lapse율도 RT 통계도
    ///   정의되지 않으므로, 0점이라는 **숫자를 지어내지 않고** 계산 불가를 그대로 알린다(제2조 1항).
    ///   타당도 게이트(`SessionValidator`)는 이 함수가 아니라 호출부가 본다 — 여기는 "계산"만 한다.
    public static func score(from summary: PVTSessionSummary) -> ArousalScore? {
        guard summary.respondedCount > 0,
              let medianRTms = summary.medianRTms,
              let fastest10PctMeanRTms = summary.fastest10PctMeanRTms
        else { return nil }

        // lapse율의 분모는 **응답 수**다. 무응답·false start는 RT 통계에 들어가지 않으므로
        // 같은 분모를 쓰는 편이 지표 간 해석이 일관된다(§1-1: lapse수 / 유효 trial수).
        let lapseRate = Double(summary.lapseCount) / Double(summary.respondedCount)

        let lapseRateScore = ArousalSubIndex.lapseRate.score(for: lapseRate)
        let medianRTScore = ArousalSubIndex.medianRT.score(for: medianRTms)
        let fastest10PctScore = ArousalSubIndex.fastest10Pct.score(for: fastest10PctMeanRTms)

        let rawScore = lapseRateWeight * lapseRateScore
            + medianRTWeight * medianRTScore
            + fastest10PctWeight * fastest10PctScore
        let factor = falseStartFactor(summary.falseStartCount)

        return ArousalScore(
            lapseRateScore: lapseRateScore,
            medianRTScore: medianRTScore,
            fastest10PctScore: fastest10PctScore,
            rawScore: rawScore,
            falseStartFactor: factor,
            score: rawScore * factor,
            lapseRate: lapseRate
        )
    }
}
