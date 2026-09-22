import Foundation

/// 冴え度 한 건 — 점수와 **그 점수를 설명하는 데이터 전부**.
///
/// §5의 "왜 이 점수인가"를 **문장이 아니라 구조**로 들고 있는 게 핵심이다. 문장을 여기서
/// 만들면 3언어(제5조)가 코어에 새고, さえちゃん이 톤을 입힐 여지도 사라진다(제4조: 캐릭터는
/// 숫자를 읽기만 한다). 표시 계층이 이 값을 받아 String Catalog로 문장을 만든다.
public struct SaeScore: Equatable {
    /// 冴え度 0~100 (정수 — 사용자에게 보이는 값).
    public let score: Int
    /// 각성 성분(0~100)과 그 재료. MVP에서는 이것이 점수의 전부다.
    public let arousal: ArousalScore
    /// 이 점수에 실제로 들어간 성분들과 정규화된 가중치. MVP에서는 `[.arousal: 1.0]`.
    public let appliedWeights: [Component: Double]
    /// 데이터가 없어 빠진 성분들. **숨기지 않고 남긴다**(§5, 제2조 3항).
    public let missingComponents: [Component]
    /// 설명에 필요한 원지표 — 표시 계층이 문장을 만들 재료(§5).
    public let evidence: Evidence

    /// 冴え度의 성분(§4).
    public enum Component: String, Equatable, Sendable, CaseIterable {
        case arousal, autonomic, fatigue

        /// 기본 가중치(모든 신호가 있을 때, §4 표).
        public var defaultWeight: Double {
            switch self {
            case .arousal: return 0.60
            case .autonomic: return 0.25
            case .fatigue: return 0.15
            }
        }
    }

    /// 점수의 근거가 되는 원지표(§5의 보간 변수들).
    public struct Evidence: Equatable {
        public let lapseCount: Int
        public let respondedCount: Int
        public let medianRTms: Double
        public let fastest10PctMeanRTms: Double
        public let falseStartCount: Int
    }
}

/// 冴え度 산출 — 성분 점수를 0~100 한 숫자로 합친다(score-algorithm §4).
///
/// **MVP는 PVT 단독**(Phase 2 확정 ①): HRV·손떨림은 앵커 근거가 약해 점수에 넣지 않는다.
/// 그래도 §4의 재정규화 규칙을 그대로 구현해 둔다 — 결측을 **벌점이 아니라 가중치 재정규화**로
/// 다루는 게 이 알고리즘의 설계이고, 각성 단독은 그 규칙의 한 경우(가중치 0.60 → 1.00)다.
public enum SaeScorer {
    /// 세션 하나에서 冴え度를 만든다.
    ///
    /// - Parameters:
    ///   - summary: 완료된 PVT 세션 요약.
    ///   - validity: 타당도 판정. **무효면 점수를 만들지 않는다.**
    /// - Returns: 점수. 세션이 무효이거나 각성 성분을 계산할 수 없으면 `nil`.
    ///
    /// 무효 세션에 억지 점수를 붙이지 않는 것이 이 함수의 첫 번째 책임이다(§1-3, 제2조 1항).
    /// "오늘은 못 쟀어요"가 가짜 숫자보다 정직하다.
    public static func score(
        from summary: PVTSessionSummary,
        validity: SessionValidity
    ) -> SaeScore? {
        guard validity == .valid,
              let arousal = ArousalScorer.score(from: summary),
              let medianRTms = summary.medianRTms,
              let fastest10PctMeanRTms = summary.fastest10PctMeanRTms
        else { return nil }

        // MVP에서 사용 가능한 성분은 각성뿐이다. 나머지는 결측으로 명시한다(숨기지 않는다).
        let available: [SaeScore.Component: Double] = [.arousal: arousal.score]
        let missing = SaeScore.Component.allCases.filter { available[$0] == nil }

        let weights = normalizedWeights(for: Array(available.keys))
        let weighted = available.reduce(0.0) { sum, entry in
            sum + (weights[entry.key] ?? 0) * entry.value
        }

        return SaeScore(
            score: Int(weighted.rounded()),
            arousal: arousal,
            appliedWeights: weights,
            missingComponents: missing,
            evidence: SaeScore.Evidence(
                lapseCount: summary.lapseCount,
                respondedCount: summary.respondedCount,
                medianRTms: medianRTms,
                fastest10PctMeanRTms: fastest10PctMeanRTms,
                falseStartCount: summary.falseStartCount
            )
        )
    }

    /// 존재하는 성분들의 기본 가중치만 남겨 **합이 1이 되도록 다시 나눈다**(§4).
    ///
    /// 결측을 0점으로 치면 "못 잰 날"이 "나쁜 날"이 된다 — 그래서 벌점이 아니라 재정규화다.
    public static func normalizedWeights(for components: [SaeScore.Component]) -> [SaeScore.Component: Double] {
        let total = components.reduce(0.0) { $0 + $1.defaultWeight }
        guard total > 0 else { return [:] }
        return Dictionary(uniqueKeysWithValues: components.map { ($0, $0.defaultWeight / total) })
    }
}
