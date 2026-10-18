import Foundation
import Testing
@testable import SaeTiming

/// 손떨림 분석 검증 — 알려진 합성 떨림을 되찾는가, 대역 밖·오프셋·드리프트를 걸러내는가, 못 쓰는 기록을 거부하는가.
struct TremorAnalysisTests {
    private let rate = 50.0

    /// 10초 기록. 각 축 값을 시간(초)의 함수로 만든다.
    private func record(
        seconds: Double = 10, rate: Double = 50,
        x: (Double) -> Double = { _ in 0 }, y: (Double) -> Double = { _ in 0 }, z: (Double) -> Double = { _ in 0 }
    ) -> [AccelerationSample] {
        (0..<Int(seconds * rate)).map { i in
            let t = Double(i) / rate
            return AccelerationSample(x: x(t), y: y(t), z: z(t))
        }
    }

    /// 9 Hz, 진폭 0.05 m/s² 사인파 → RMS = 0.05/√2, 정점 9 Hz.
    @Test func recoversAKnownTremor() throws {
        let result = try #require(TremorAnalysis.analyze(record(x: { 0.05 * sin(2 * .pi * 9 * $0) }), sampleRateHz: rate))
        #expect(abs(result.bandRMS - 0.05 / 2.0.squareRoot()) < 0.0005)
        #expect(abs(result.peakFrequencyHz - 9) < 0.2)
        #expect(abs(result.analyzedSeconds - 8) < 1e-9) // 앞뒤 1초씩 잘림
    }

    /// 대역 밖(2 Hz 큰 흔들림·15 Hz)과 오프셋·드리프트는 결과에 들어가지 않는다.
    @Test func ignoresEverythingOutsideTheBand() throws {
        let clean = try #require(TremorAnalysis.analyze(record(x: { 0.05 * sin(2 * .pi * 9 * $0) }), sampleRateHz: rate))
        let noisy = try #require(TremorAnalysis.analyze(record(
            x: { 0.05 * sin(2 * .pi * 9 * $0) + 0.3 },               // 오프셋
            y: { 0.5 * sin(2 * .pi * 2 * $0) },                       // 자세 흔들림(대역 아래)
            z: { 0.04 * $0 + 0.05 * sin(2 * .pi * 15 * $0) }          // 드리프트 + 대역 위
        ), sampleRateHz: rate))
        #expect(abs(noisy.bandRMS - clean.bandRMS) / clean.bandRMS < 0.05)
        #expect(abs(noisy.peakFrequencyHz - 9) < 0.2)
    }

    /// 세 축에 나뉜 떨림은 합산된다(√(a²+b²)/√2).
    @Test func combinesAxes() throws {
        let result = try #require(TremorAnalysis.analyze(record(
            x: { 0.03 * sin(2 * .pi * 8 * $0) }, y: { 0.04 * sin(2 * .pi * 8 * $0) }
        ), sampleRateHz: rate))
        #expect(abs(result.bandRMS - 0.05 / 2.0.squareRoot()) < 0.0005)
    }

    @Test func stillnessGivesNearZero() throws {
        let result = try #require(TremorAnalysis.analyze(record(), sampleRateHz: rate))
        #expect(result.bandRMS < 1e-9)
    }

    /// 6초를 못 채우면(앞뒤 1초 제외) 결과가 없다 — 숫자를 지어내지 않는다.
    @Test func rejectsTooShortRecordings() {
        #expect(TremorAnalysis.analyze(record(seconds: 7.9, x: { 0.05 * sin(2 * .pi * 9 * $0) }), sampleRateHz: rate) == nil)
        #expect(TremorAnalysis.analyze([], sampleRateHz: rate) == nil)
    }

    /// 12 Hz를 담을 수 없는 표본률(나이퀴스트 ≤ 12 Hz)은 거부한다.
    @Test func rejectsSampleRatesThatCannotSeeTheBand() {
        #expect(TremorAnalysis.analyze(record(rate: 20, x: { 0.05 * sin(2 * .pi * 9 * $0) }), sampleRateHz: 20) == nil)
        #expect(TremorAnalysis.analyze(record(rate: 24, x: { 0.05 * sin(2 * .pi * 9 * $0) }), sampleRateHz: 24) == nil)
    }
}
