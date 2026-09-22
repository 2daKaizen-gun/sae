import Testing
@testable import SaeTiming

/// 하위지표 매핑 검증 — 앵커·경계·clamp·역방향(score-algorithm §1-1).
///
/// 이 매핑이 점수의 첫 단계다. 여기서 틀리면 그 위의 모든 숫자가 조용히 틀린다.
struct SubIndexTests {
    /// 앵커 자리에서는 정확히 100점·0점이 나온다.
    @Test func anchorsMapToFullAndZero() {
        let index = SubIndex(bestAnchor: 250, worstAnchor: 500)
        #expect(index.score(for: 250) == 100)
        #expect(index.score(for: 500) == 0)
    }

    /// 앵커 사이는 선형 보간이다: 중간값이면 50점.
    @Test func midpointIsFifty() {
        let index = SubIndex(bestAnchor: 250, worstAnchor: 500)
        #expect(index.score(for: 375) == 50)
    }

    /// 앵커 바깥은 잘린다 — 200점이나 음수 점수는 나오지 않는다.
    @Test func valuesOutsideAnchorsAreClamped() {
        let index = SubIndex(bestAnchor: 250, worstAnchor: 500)
        #expect(index.score(for: 100) == 100)  // 앵커보다 빨라도 100이 상한
        #expect(index.score(for: 5_000) == 0)  // 아무리 느려도 0이 하한
    }

    /// "좋은 쪽이 큰 값"인 지표도 앵커 순서만으로 표현된다(방향 플래그 불필요).
    @Test func ascendingAnchorsWorkToo() {
        let index = SubIndex(bestAnchor: 60, worstAnchor: 20) // 예: 높을수록 좋은 지표
        #expect(index.score(for: 60) == 100)
        #expect(index.score(for: 20) == 0)
        #expect(index.score(for: 40) == 50)
    }

    /// 문서(§1-1)에 적힌 예시가 그대로 나온다: 중앙값 291ms → 83.6점.
    @Test func matchesDocumentedMedianExample() {
        let score = ArousalSubIndex.medianRT.score(for: 291)
        #expect(abs(score - 83.6) < 0.05)
    }

    /// 문서(§6) 워크드 예시의 세 하위지표 값을 재현한다.
    /// 코드와 문서가 어긋나면 둘 중 하나가 틀린 것이고, 이 테스트가 그걸 잡는다(제2조).
    @Test func reproducesWorkedExampleSubIndices() {
        #expect(abs(ArousalSubIndex.lapseRate.score(for: 3.0 / 24.0) - 58.3) < 0.05)
        #expect(abs(ArousalSubIndex.medianRT.score(for: 342) - 63.2) < 0.05)
        #expect(abs(ArousalSubIndex.fastest10Pct.score(for: 268) - 73.3) < 0.05)
    }

    /// v0 앵커 상수가 문서 표와 같은지 못 박는다 — 조용히 바뀌면 점수 전체가 달라진다.
    @Test func anchorsMatchTheDocumentedTable() {
        #expect(ArousalSubIndex.lapseRate == SubIndex(bestAnchor: 0.0, worstAnchor: 0.30))
        #expect(ArousalSubIndex.medianRT == SubIndex(bestAnchor: 250, worstAnchor: 500))
        #expect(ArousalSubIndex.fastest10Pct == SubIndex(bestAnchor: 220, worstAnchor: 400))
    }
}
