import Foundation

/// 시계 계약 검증 결과 — 어떤 타임스탬프가 기준 시계와 같은 단조 기준에서 왔는가.
///
/// 판정(`holds`)만이 아니라 **실제 차이(`deltaSeconds`)를 함께 남긴다.** 계약이 깨졌을 때
/// "얼마나 어긋났나"를 봐야 원인(다른 시계인지, 지연이 큰 건지)을 알 수 있기 때문이다(제2조).
public struct ClockContractResult: Equatable {
    /// 기준 시각 − 샘플 시각(초). 샘플이 과거일수록 양수다.
    public let deltaSeconds: TimeInterval
    /// 판정에 쓴 허용오차(초).
    public let toleranceSeconds: TimeInterval

    public init(deltaSeconds: TimeInterval, toleranceSeconds: TimeInterval) {
        self.deltaSeconds = deltaSeconds
        self.toleranceSeconds = toleranceSeconds
    }

    /// 계약이 성립하는가 — 차이가 허용오차 안(경계 포함)인가.
    public var holds: Bool { abs(deltaSeconds) <= toleranceSeconds }
}

/// 시계 계약 — **자극 온셋과 응답 시각이 같은 단조 기준에서 온다**는 이 설계의 전제를 검증한다
/// (timing-engine §2·§8-2).
///
/// 반응시간은 `touch.timestamp − stimulusFrameTimestamp`로 **직접 뺄셈**해서 나온다. 이 뺄셈은
/// 두 값이 같은 단조 기준(`mach_absolute_time` 기반 CoreAnimation/이벤트 시계)일 때만 의미가 있다.
/// 전제가 깨지면 반응시간 전체가 무의미해지므로, 가정을 암묵적으로 믿지 않고 **명시적으로 확인**한다.
///
/// ## 왜 순수 함수인가
/// `CADisplayLink.timestamp`·`UITouch.timestamp`를 실제로 얻는 것은 런타임 사실이라
/// `swift test`로 만들 수 없다. 그래서 **판정 규칙만** 여기 순수하게 분리해 경계까지 테스트하고,
/// 앱은 실제 타임스탬프와 공통 기준(`CACurrentMediaTime()`)을 이 함수에 넣어 확인한다
/// (제1조 3항 — 증명할 수 있는 것은 테스트로, 런타임층은 값 전달만 책임).
///
/// ## 이 계약이 증명하는 것과 아닌 것 (제2조 3항)
/// - ✅ 증명: 두 타임스탬프가 **같은 시간 기준**에서 왔다. 기준이 다르면(예: 벽시계 epoch는
///   단조 시계와 10⁹초 규모로 벌어진다) 어떤 현실적 허용오차로도 걸러진다.
/// - ❌ 증명 아님: 밀리초 단위 **정렬 정확도**. 온셋의 반프레임 불확실성은 상수 보정으로 없앨 수
///   없는 잔여 오차로 남는다(timing-engine §7).
public enum ClockContract {
    /// 기본 허용오차 0.25초.
    ///
    /// 이 값의 목적은 정밀도 판정이 아니라 **기준 식별**이다. 샘플을 얻고 기준 시각을 읽기까지의
    /// 프레임·핸들러 디스패치 지연(수~수십 ms)은 넉넉히 덮고, 기준이 다른 경우(초 단위 이상 차이)는
    /// 확실히 걸러내는 폭으로 잡았다. 더 조인다고 얻는 것이 없고, 부하 상황에서 거짓 실패만 는다.
    public static let defaultToleranceSeconds: TimeInterval = 0.25

    /// 샘플 타임스탬프가 기준 시계와 같은 단조 기준인지 판정한다.
    ///
    /// - Parameters:
    ///   - sampleTs: 검증할 타임스탬프(초). 앱에서는 `CADisplayLink.timestamp` 또는 `UITouch.timestamp`.
    ///   - referenceTs: 그 직후에 읽은 공통 기준 시각(초). 앱에서는 `CACurrentMediaTime()`.
    ///   - toleranceSeconds: 허용오차(초).
    /// - Returns: 차이와 판정을 담은 결과.
    ///
    /// 샘플은 보통 기준보다 **과거**(양수 delta)지만, 판정은 절댓값으로 대칭 처리한다.
    /// 방향까지 강제하면 미세한 순서 역전에 거짓 실패가 나는데, 계약의 목적(기준 식별)에는
    /// 방향이 필요 없기 때문이다.
    public static func verify(
        sampleTs: TimeInterval,
        referenceTs: TimeInterval,
        toleranceSeconds: TimeInterval = defaultToleranceSeconds
    ) -> ClockContractResult {
        ClockContractResult(
            deltaSeconds: referenceTs - sampleTs,
            toleranceSeconds: toleranceSeconds
        )
    }
}
