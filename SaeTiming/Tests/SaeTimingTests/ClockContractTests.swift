import Foundation
import Testing
@testable import SaeTiming

/// 시계 계약 판정 검증 — 합성 타임스탬프로 경계까지 증명한다(timing-engine §8-2).
///
/// 런타임에서 실제 `CADisplayLink.timestamp`·`UITouch.timestamp`가 같은 기준인지는 앱에서
/// 확인하고, 여기서는 **그 판정 규칙 자체**가 정확한지를 시뮬레이터 없이 증명한다.
struct ClockContractTests {
    /// 프레임 한 장(60Hz ≈ 16.7ms) 뒤에 기준을 읽은 정상 상황 → 계약 성립.
    @Test func sampleOneFrameInThePastHolds() {
        let result = ClockContract.verify(sampleTs: 23_427.100, referenceTs: 23_427.1167)
        #expect(result.holds)
        #expect(abs(result.deltaSeconds - 0.0167) < 0.0001)
    }

    /// 허용오차와 정확히 같은 차이도 성립한다(경계 포함).
    @Test func differenceExactlyAtToleranceHolds() {
        let result = ClockContract.verify(sampleTs: 100.0, referenceTs: 100.25, toleranceSeconds: 0.25)
        #expect(result.deltaSeconds == 0.25)
        #expect(result.holds)
    }

    /// 허용오차를 넘기면 성립하지 않는다.
    @Test func differencePastToleranceFails() {
        let result = ClockContract.verify(sampleTs: 100.0, referenceTs: 100.26, toleranceSeconds: 0.25)
        #expect(result.holds == false)
    }

    /// 샘플이 기준보다 미세하게 미래여도(음수 delta) 허용오차 안이면 성립한다 — 판정은 대칭이다.
    @Test func sampleSlightlyAheadOfReferenceStillHolds() {
        let result = ClockContract.verify(sampleTs: 100.01, referenceTs: 100.0)
        #expect(result.deltaSeconds < 0)
        #expect(result.holds)
    }

    /// 음수 쪽도 허용오차를 넘기면 실패한다(대칭 경계).
    @Test func sampleTooFarAheadFails() {
        let result = ClockContract.verify(sampleTs: 101.0, referenceTs: 100.0, toleranceSeconds: 0.25)
        #expect(result.deltaSeconds == -1.0)
        #expect(result.holds == false)
    }

    /// 이 계약이 진짜로 잡아야 하는 실패: 벽시계(`Date` epoch) 값을 단조 시계와 섞는 경우.
    /// 기준이 다르면 차이가 10⁹초 규모라 어떤 현실적 허용오차로도 걸러진다(timing-engine §2).
    @Test func wallClockSampleAgainstMonotonicReferenceFails() {
        let wallClockTs = Date(timeIntervalSince1970: 1_784_000_000).timeIntervalSince1970
        let monotonicTs = 23_427.1
        let result = ClockContract.verify(sampleTs: wallClockTs, referenceTs: monotonicTs)
        #expect(result.holds == false)
        #expect(result.deltaSeconds < -1_000_000_000)
    }

    /// 부팅 시각이 다른 단조 시계처럼 기준만 어긋난 경우도 실패로 잡는다.
    @Test func differentMonotonicBaseFails() {
        let result = ClockContract.verify(sampleTs: 23_427.1, referenceTs: 91_842.7)
        #expect(result.holds == false)
    }

    /// 보고되는 차이는 항상 `기준 − 샘플`이다(부호 정의 고정 — 저장·로그 해석의 기준).
    @Test func deltaIsReferenceMinusSample() {
        let result = ClockContract.verify(sampleTs: 10.0, referenceTs: 10.125)
        #expect(result.deltaSeconds == 0.125)
        #expect(result.toleranceSeconds == ClockContract.defaultToleranceSeconds)
    }

    /// 허용오차 0이면 완전히 같은 시각만 성립한다(퇴화 경계).
    @Test func zeroToleranceRequiresExactMatch() {
        #expect(ClockContract.verify(sampleTs: 5.0, referenceTs: 5.0, toleranceSeconds: 0).holds)
        #expect(ClockContract.verify(sampleTs: 5.0, referenceTs: 5.001, toleranceSeconds: 0).holds == false)
    }
}
