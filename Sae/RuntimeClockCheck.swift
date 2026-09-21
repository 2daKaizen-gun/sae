import QuartzCore
import SaeTiming

/// 런타임 시계 계약 확인 — 앱이 실제로 받는 타임스탬프에 순수 명세(`ClockContract`)를 적용한다.
///
/// 이 설계는 `touch.timestamp − frameTimestamp` **직접 뺄셈** 위에 서 있고, 그 뺄셈은 두 값이
/// 같은 단조 기준일 때만 성립한다(timing-engine §2). 그 전제를 믿기만 하지 않고,
/// 두 타임스탬프를 각각 공통 기준 `CACurrentMediaTime()`과 대조해 **런타임에서 확인**한다(§8-2).
///
/// 판정 규칙 자체는 `SaeTiming`의 순수 `ClockContract`가 `swift test`로 증명했다. 여기는
/// 실제 값을 그 규칙에 **정확히 전달**하는 배선만 책임진다(제1조 3항).
enum RuntimeClockCheck {
    /// 샘플 타임스탬프를 공통 기준과 대조하고, DEBUG에서는 계약 위반 시 즉시 멈춘다.
    ///
    /// - Parameters:
    ///   - sampleTs: 검증할 타임스탬프(`CADisplayLink.timestamp` 또는 `UITouch.timestamp`).
    ///   - referenceTs: 샘플을 얻은 **직후** 읽은 `CACurrentMediaTime()` 값.
    ///   - source: 실패 메시지에 남길 출처 이름.
    ///
    /// 기준 시각은 호출자가 읽어 넘긴다 — 여기서 읽으면 호출 지연만큼 차이가 부풀어
    /// 무엇을 쟀는지 흐려지기 때문이다.
    @discardableResult
    static func verify(sampleTs: TimeInterval, referenceTs: TimeInterval, source: String) -> ClockContractResult {
        let result = ClockContract.verify(sampleTs: sampleTs, referenceTs: referenceTs)
        #if DEBUG
        // 계약이 깨지면 반응시간 전체가 무의미해진다. 조용히 넘기지 않고 개발 중에 터뜨린다(제1조).
        assert(
            result.holds,
            "Clock contract broken (\(source)): Δ=\(result.deltaSeconds)s exceeds \(result.toleranceSeconds)s. "
                + "Reaction time is only valid if stimulus and touch timestamps share one monotonic base."
        )
        #endif
        return result
    }
}
