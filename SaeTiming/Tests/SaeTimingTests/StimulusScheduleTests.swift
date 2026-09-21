import Testing
@testable import SaeTiming

/// 자극 스케줄 진행기 검증 — 합성 프레임 타임스탬프 주입으로 온셋 판정과 trial 사이클을 증명한다
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
        #expect(schedule.state == .showingStimulus(onset: StimulusOnset(index: 0, onsetTime: 102.008)))
    }

    /// 목표와 정확히 같은 프레임 타임스탬프도 온셋이다(경계 포함, ≥).
    @Test func frameExactlyAtTargetFiresOnset() {
        var schedule = StimulusSchedule(intervalsMs: [3_000], startTime: 0.0)
        let onset = schedule.advance(frameTime: 3.0)
        #expect(onset == StimulusOnset(index: 0, onsetTime: 3.0))
    }

    /// 자극이 켜져 있는 동안은 프레임이 아무리 흘러도 새 자극이 나오지 않는다(자극은 겹치지 않는다).
    @Test func noSecondOnsetWhileStimulusIsShowing() {
        var schedule = StimulusSchedule(intervalsMs: [1_000, 1_000], startTime: 0.0)
        #expect(schedule.advance(frameTime: 1.0) != nil)
        #expect(schedule.advance(frameTime: 5.0) == nil)
        #expect(schedule.advance(frameTime: 50.0) == nil)
        #expect(schedule.nextTargetTime == nil) // 대기 중이 아니다
        #expect(schedule.pendingOnset?.index == 0)
    }

    /// 다음 목표는 **trial 종료 시각 + 다음 ISI**다 — 응답에 걸린 시간만큼 다음 대기가 밀린다.
    @Test func nextTargetIsMeasuredFromTrialEnd() {
        var schedule = StimulusSchedule(intervalsMs: [2_000, 4_000], startTime: 0.0)
        _ = schedule.advance(frameTime: 2.05)   // 온셋 2.05
        schedule.completeTrial(at: 2.35)        // 300ms 뒤 응답
        #expect(schedule.nextTargetTime == 6.35) // 2.35 + 4.0 (온셋 기준이 아니다)
    }

    /// 대기 중(자극 꺼짐)의 `completeTrial`은 아무 일도 하지 않는다 — false start는 trial을 끝내지 않는다.
    @Test func completingTrialWhileWaitingIsIgnored() {
        var schedule = StimulusSchedule(intervalsMs: [2_000, 4_000], startTime: 0.0)
        schedule.completeTrial(at: 1.0)
        #expect(schedule.nextTargetTime == 2.0) // 목표 그대로
        #expect(schedule.advance(frameTime: 2.0)?.index == 0) // 첫 자극이 소비되지 않았다
    }

    /// 마지막 trial이 끝나면 완료 상태가 되고 더 이상 자극이 나오지 않는다.
    @Test func finishesAfterLastTrialCompletes() {
        var schedule = StimulusSchedule(intervalsMs: [1_000], startTime: 0.0)
        _ = schedule.advance(frameTime: 1.0)
        #expect(schedule.isFinished == false) // 응답 대기 중이라 아직 끝이 아니다
        schedule.completeTrial(at: 1.3)
        #expect(schedule.isFinished)
        #expect(schedule.advance(frameTime: 100.0) == nil)
    }

    /// 여러 자극을 프레임 스트림으로 순서대로 소진한다(매 trial 200ms 뒤 응답 가정).
    @Test func consumesAllStimuliInOrder() {
        var schedule = StimulusSchedule(intervalsMs: [2_000, 2_000, 2_000], startTime: 0.0)
        var onsets: [StimulusOnset] = []
        // 0.1초 간격 프레임을 충분히 흘려보내고, 온셋 200ms 뒤에 응답한 것으로 처리한다.
        for i in 0..<200 {
            let t = Double(i) * 0.1
            if let onset = schedule.advance(frameTime: t) { onsets.append(onset) }
            if let pending = schedule.pendingOnset, t >= pending.onsetTime + 0.2 {
                schedule.completeTrial(at: t)
            }
        }
        #expect(onsets.count == 3)
        #expect(onsets.map(\.index) == [0, 1, 2])
        // 각 자극은 직전 trial 종료보다 최소 2초(ISI) 뒤에 떠야 한다.
        #expect(onsets[1].onsetTime - onsets[0].onsetTime >= 2.2)
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
