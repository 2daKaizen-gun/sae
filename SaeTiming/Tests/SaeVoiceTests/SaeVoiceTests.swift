import Testing
import SaeTiming
@testable import SaeVoice

/// 대사 선택 검증 — 밴드 경계·무효·첫 측정·변주·사실 보존.
struct SaeVoiceTests {
    /// 경계값은 임시지만, 정한 이상 정확히 그 자리에서 갈라져야 한다.
    @Test func bandBoundaries() {
        let cases: [(Int, ToneBand)] = [
            (100, .sharp), (80, .sharp), (79, .steady), (60, .steady), (59, .dull),
            (40, .dull), (39, .slow), (20, .slow), (19, .low), (0, .low),
        ]
        for (score, band) in cases { #expect(ToneBand(score: score) == band, "score \(score)") }
    }

    @Test func outOfRangeScoresFallToTheNearestEnd() {
        #expect(ToneBand(score: 120) == .sharp)
        #expect(ToneBand(score: -5) == .low)
    }

    /// 사실은 엔진의 산출물 그대로 — 실제 스코어러를 거친 값과 대사의 사실이 같아야 한다(제4조 1항).
    @Test func factsAreTheEnginesOwnNumbers() throws {
        let outcomes = (0..<10).map { TrialOutcome.valid(reactionTimeMs: 300 + Double($0) * 10) }
            + [TrialOutcome.lapse(reactionTimeMs: 620), .lapse(reactionTimeMs: 700)]
        let summary = PVTSessionSummary.make(from: outcomes)
        let sae = try #require(SaeScorer.score(from: summary, validity: SessionValidator.evaluate(summary)))

        let line = SaeVoice.line(facts: .init(sae), isFirstMeasurement: false, rotation: 0)
        #expect(line.facts == VoiceLine.Facts(score: sae.score, lapseCount: 2))
        #expect(line.kind == .scored(ToneBand(score: sae.score)))
    }

    /// 무효 세션에는 숫자가 없다 — 재시도 대사만.
    @Test func invalidSessionCarriesNoNumbers() {
        let line = SaeVoice.line(facts: nil, isFirstMeasurement: false, rotation: 3)
        #expect(line.kind == .invalidSession)
        #expect(line.facts == nil)
    }

    /// 첫 측정은 밴드보다 앞선다(비교 자제). 사실은 그대로 담는다.
    @Test func firstMeasurementOverridesTheBand() {
        let facts = VoiceLine.Facts(score: 15, lapseCount: 6)
        let line = SaeVoice.line(facts: facts, isFirstMeasurement: true, rotation: 7)
        #expect(line.kind == .firstMeasurement)
        #expect(line.variant == 0)
        #expect(line.facts == facts)
    }

    /// 무효여도 "첫 측정" 대사가 되지 않는다 — 점수가 없으면 무조건 재시도.
    @Test func invalidWinsOverFirstMeasurement() {
        #expect(SaeVoice.line(facts: nil, isFirstMeasurement: true, rotation: 0).kind == .invalidSession)
    }

    @Test func rotationIsDeterministicAndInRange() {
        let facts = VoiceLine.Facts(score: 70, lapseCount: 1)
        for rotation in [-7, -1, 0, 1, 2, 3, 275] {
            let line = SaeVoice.line(facts: facts, isFirstMeasurement: false, rotation: rotation)
            #expect((0..<2).contains(line.variant))
            #expect(line == SaeVoice.line(facts: facts, isFirstMeasurement: false, rotation: rotation))
        }
        #expect(SaeVoice.line(facts: facts, isFirstMeasurement: false, rotation: 0).variant
            != SaeVoice.line(facts: facts, isFirstMeasurement: false, rotation: 1).variant)
    }

    @Test func catalogKeysAreCompleteAndUnique() {
        let keys = SaeVoice.allCatalogKeys
        #expect(keys.count == 13) // 밴드 5×2 + 첫 측정 1 + 무효 2
        #expect(Set(keys).count == keys.count)
        #expect(keys.contains("voice.sharp.0") && keys.contains("voice.first.0") && keys.contains("voice.invalid.1"))
    }
}
