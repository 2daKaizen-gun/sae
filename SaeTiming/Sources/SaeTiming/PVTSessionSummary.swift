import Foundation

/// 한 세션의 trial 결과 리스트에서 뽑은 요약 지표 — 순수 집계.
///
/// data-model `PVTSession`의 요약 필드(meanRTms/medianRTms/fastest10PctMeanRTms/
/// lapseCount/falseStartCount)를 만든다. 원자료(`TrialOutcome`)는 그대로 두고 여기서
/// 파생만 하므로, 나중에 문턱·보정이 바뀌어도 재집계할 수 있다(제1·2조).
/// 이 지표들이 score-algorithm §1(각성 성분)의 입력이 된다.
public struct PVTSessionSummary: Equatable {
    /// 전체 trial 수.
    public let trialCount: Int
    /// RT가 있는 응답 수(valid + lapse). RT 통계·타당도의 분모.
    public let respondedCount: Int
    /// lapse 수(응답했으나 임계값 초과).
    public let lapseCount: Int
    /// false start 수(자극 전 탭).
    public let falseStartCount: Int
    /// 무응답 수(타임아웃).
    public let noResponseCount: Int
    /// 응답 RT 평균(ms). 응답이 하나도 없으면 nil.
    public let meanRTms: Double?
    /// 응답 RT 중앙값(ms). RT 분포는 우측 꼬리가 길어 중앙값이 강건하다(score-algorithm §1-1). 응답 없으면 nil.
    public let medianRTms: Double?
    /// 가장 빠른 10% 응답의 평균(ms) — 능력 상한 지표(score-algorithm §1-1). 응답 없으면 nil.
    public let fastest10PctMeanRTms: Double?
}

public extension PVTSessionSummary {
    /// trial 결과들을 세션 요약으로 집계한다. 순수 함수 — 같은 입력은 같은 요약을 낸다.
    static func make(from outcomes: [TrialOutcome]) -> PVTSessionSummary {
        var lapseCount = 0
        var falseStartCount = 0
        var noResponseCount = 0
        var reactionTimes: [Double] = []

        for outcome in outcomes {
            switch outcome {
            case .valid(let rt):
                reactionTimes.append(rt)
            case .lapse(let rt):
                reactionTimes.append(rt)
                lapseCount += 1
            case .falseStart:
                falseStartCount += 1
            case .noResponse:
                noResponseCount += 1
            }
        }

        let sorted = reactionTimes.sorted()
        return PVTSessionSummary(
            trialCount: outcomes.count,
            respondedCount: reactionTimes.count,
            lapseCount: lapseCount,
            falseStartCount: falseStartCount,
            noResponseCount: noResponseCount,
            meanRTms: mean(of: sorted),
            medianRTms: median(of: sorted),
            fastest10PctMeanRTms: fastest10PctMean(of: sorted)
        )
    }

    private static func mean(of values: [Double]) -> Double? {
        values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }

    /// 정렬된 값의 중앙값. 짝수 개면 가운데 두 값의 평균(표준 정의).
    private static func median(of sorted: [Double]) -> Double? {
        guard !sorted.isEmpty else { return nil }
        let mid = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
    }

    /// 정렬된 값 중 가장 빠른 10%의 평균. 개수는 반올림하되 **최소 1개**(응답이 있으면 항상 산출).
    /// 10% 표본수 규칙은 튜닝 대상(score-algorithm 열린 결정).
    private static func fastest10PctMean(of sorted: [Double]) -> Double? {
        guard !sorted.isEmpty else { return nil }
        let count = max(1, Int((Double(sorted.count) * 0.1).rounded()))
        let fastest = sorted.prefix(count)
        return fastest.reduce(0, +) / Double(fastest.count)
    }
}
