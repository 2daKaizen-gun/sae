import Foundation

/// 시드 고정 결정적 난수 생성기(SplitMix64).
///
/// 시스템 기본 RNG는 재현 불가라 테스트할 수 없다. ISI 수열을 **시드로 재현 가능**하게
/// 만들어 테스트 용이성을 확보한다(timing-engine §8-1). 측정 자체엔 쓰지 않고, 자극 간격
/// 스케줄 생성에만 쓴다.
public struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64) { self.state = seed }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// 자극 간격(ISI) 스케줄러 — 시드 고정으로 결정적(timing-engine §3·§8-1).
///
/// 실제 표시는 `Timer`가 아니라 `CADisplayLink`로 이 값을 소비한다(드리프트 회피, timing-engine §3).
/// 다만 **값 생성 자체는 순수·테스트 가능하게** 분리해 둔다.
public enum ISIScheduler {
    /// 표준 ISI 범위 2~10초 (CONCEPT §1, timing-engine §3).
    public static let defaultRangeMs = 2_000...10_000

    /// 시드와 개수가 같으면 **항상 같은 수열**을 돌려준다(재현 가능성).
    public static func intervalsMs(
        count: Int, seed: UInt64, range: ClosedRange<Int> = defaultRangeMs
    ) -> [Int] {
        precondition(count >= 0, "trial 개수는 음수일 수 없다")
        var generator = SeededGenerator(seed: seed)
        return (0..<count).map { _ in Int.random(in: range, using: &generator) }
    }
}
