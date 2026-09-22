import Foundation

/// 원지표 하나를 0~100 하위지표로 옮기는 **구간 선형 매핑**(score-algorithm §1-1).
///
/// 두 앵커 사이를 선형 보간하고 바깥은 잘라낸다(clamp). 앵커는 "100점을 주는 값"과
/// "0점을 주는 값"이며, 지표에 따라 **좋은 쪽이 작은 값**일 수도 있다(반응시간·lapse율처럼
/// 낮을수록 좋음) — 그 방향까지 앵커가 표현하므로 별도 플래그가 필요 없다.
///
/// 왜 선형인가: 제2조 2항(설명 가능성). "왜 62점인가"에 답하려면 매핑이 한 줄로 설명돼야 한다.
/// 곡선(로지스틱)은 열린 결정으로 남아 있고, 바꾸더라도 **설명 가능성을 유지**하는 게 조건이다.
public struct SubIndex: Equatable, Sendable {
    /// 100점을 주는 원지표 값.
    public let bestAnchor: Double
    /// 0점을 주는 원지표 값.
    public let worstAnchor: Double

    /// - Precondition: 두 앵커는 달라야 한다(같으면 기울기가 정의되지 않는다).
    public init(bestAnchor: Double, worstAnchor: Double) {
        precondition(bestAnchor != worstAnchor, "앵커가 같으면 매핑을 정의할 수 없다")
        self.bestAnchor = bestAnchor
        self.worstAnchor = worstAnchor
    }

    /// 원지표 값을 0~100으로 옮긴다. 앵커 바깥은 0 또는 100으로 잘린다.
    public func score(for value: Double) -> Double {
        let ratio = (worstAnchor - value) / (worstAnchor - bestAnchor)
        return min(100, max(0, ratio * 100))
    }
}

/// 각성(PVT) 성분이 쓰는 세 하위지표의 v0 앵커(score-algorithm §1-1).
///
/// 값은 **튜닝 대상**이다. 문서의 근거를 그대로 옮겨 적되, 실데이터로 조정되면
/// 문서와 이 상수를 같이 고친다(제2조 — 문서와 코드가 어긋나면 둘 중 하나는 틀린 것이다).
public enum ArousalSubIndex {
    /// lapse율(0~1) — 0%면 100점, 30% 이상이면 0점.
    /// 수면부족에 가장 민감한 지표라 각성 성분에서 가중치가 가장 크다.
    public static let lapseRate = SubIndex(bestAnchor: 0.0, worstAnchor: 0.30)

    /// 중앙값 반응시간(ms) — 250ms 이하 100점, 500ms 이상 0점.
    /// 500ms는 lapse 문턱과 같은 값이다(그 지점이면 절반이 lapse라는 뜻).
    public static let medianRT = SubIndex(bestAnchor: 250, worstAnchor: 500)

    /// 최속 10% 평균(ms) — 220ms 이하 100점, 400ms 이상 0점. 능력 상한을 본다.
    public static let fastest10Pct = SubIndex(bestAnchor: 220, worstAnchor: 400)
}
