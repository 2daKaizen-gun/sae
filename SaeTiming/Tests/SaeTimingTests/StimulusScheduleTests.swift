import Testing
@testable import SaeTiming

/// 자극 스케줄 진행기 검증 — 합성 프레임 타임스탬프 주입으로 온셋 판정을 증명한다
/// (timing-engine §8-1: CADisplayLink 없이 순수 로직으로 정확도 증명).
struct StimulusScheduleTests {
    /// 첫 목표는 `startTime + 첫 ISI`(초 변환)다.
    @Test func firstTargetIsStartPlusFirstInterval() {
        let schedule = StimulusSchedule(intervalsMs: [2_000, 5_000], startTime: 100.0)
        #expect(schedule.nextTargetTime == 102.0) // 100 + 2000ms
        #expect(schedule.isFinished == false)
    }

    /// 목표 이전 프레임은 온셋을 내지 않고, 목표도 그대로 유지한다.
    @Test func framesBeforeTargetYieldNothing() {
        var schedule = StimulusSchedule(intervalsMs: [2_000], startTime: 100.0)
        #expect(schedule.advance(frameTime: 100.5) == nil)
        #expect(schedule.advance(frameTime: 101.9) == nil)
        #expect(schedule.nextTargetTime == 102.0)
    }

    /// 목표 이상인 첫 프레임에서 온셋이 확정되고, 온셋 시각은 그 프레임 타임스탬프다(목표값 아님).
    @Test func firstFrameAtOrPastTargetFiresOnset() {
        var schedule = StimulusSchedule(intervalsMs: [2_000], startTime: 100.0)
        // 목표 102.0을 살짝 넘긴 프레임(디스플레이가 정확히 목표에 오지 않는다).
        let onset = schedule.advance(frameTime: 102.008)
        #expect(onset == StimulusOnset(index: 0, onsetTime: 102.008))
        #expect(schedule.isFinished) // 자극 1개 소진
    }

    /// 목표와 정확히 같은 프레임 타임스탬프도 온셋이다(경계 포함, ≥).
    @Test func frameExactlyAtTargetFiresOnset() {
        var schedule = StimulusSchedule(intervalsMs: [3_000], startTime: 0.0)
        let onset = schedule.advance(frameTime: 3.0)
        #expect(onset == StimulusOnset(index: 0, onsetTime: 3.0))
    }

    /// 다음 목표는 **실제 온셋 시각 + 다음 ISI**로 전진한다(목표값이 아니라 온셋 기준).
    @Test func nextTargetIsMeasuredFromActualOnset() {
        var schedule = StimulusSchedule(intervalsMs: [2_000, 4_000], startTime: 0.0)
        // 목표 2.0을 넘겨 2.05에 온셋 → 다음 목표 = 2.05 + 4.0
        _ = schedule.advance(frameTime: 2.05)
        #expect(schedule.nextTargetTime == 6.05)
    }

    /// 여러 자극을 프레임 스트림으로 순서대로 소진한다.
    @Test func consumesAllStimuliInOrder() {
        var schedule = StimulusSchedule(intervalsMs: [2_000, 2_000, 2_000], startTime: 0.0)
        var onsets: [StimulusOnset] = []
        // 0.5초 간격 프레임을 충분히 흘려보낸다.
        for i in 0..<40 {
            let t = Double(i) * 0.5
            if let onset = schedule.advance(frameTime: t) { onsets.append(onset) }
        }
        #expect(onsets.count == 3)
        #expect(onsets.map(\.index) == [0, 1, 2])
        #expect(schedule.isFinished)
    }

    /// 자극이 없으면 처음부터 완료 상태고 어떤 프레임도 온셋을 내지 않는다.
    @Test func emptyScheduleIsImmediatelyFinished() {
        var schedule = StimulusSchedule(intervalsMs: [], startTime: 100.0)
        #expect(schedule.isFinished)
        #expect(schedule.nextTargetTime == nil)
        #expect(schedule.advance(frameTime: 200.0) == nil)
    }
}
