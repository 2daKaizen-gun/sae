import Foundation

/// 자극 온셋 이벤트 — 하나의 자극이 실제로 켜진 프레임을 나타낸다.
///
/// `onsetTime`은 "그려라"를 호출한 시각이 아니라, **자극이 화면에 표시되는 프레임의
/// 타임스탬프**(단조 시계, 초)다(timing-engine §3). 이 값이 반응시간 계산의 기준점이 된다:
/// `reactionTimeMs = (touch.timestamp − onsetTime) × 1000 − offset`.
public struct StimulusOnset: Equatable {
    /// 세션 내 자극 순번(0-based).
    public let index: Int
    /// 자극이 표시되는 프레임의 단조 타임스탬프(초). 런타임에서는 `CADisplayLink`가 이 값을 채운다.
    public let onsetTime: TimeInterval

    public init(index: Int, onsetTime: TimeInterval) {
        self.index = index
        self.onsetTime = onsetTime
    }
}

/// 자극 스케줄 진행기 — PVT 한 사이클(대기 → 자극 → 응답 → 대기)을 도는 **순수 상태기계**.
///
/// 실제 표시는 `CADisplayLink`가 매 프레임 `advance(frameTime:)`를 호출해 소비한다.
/// `Timer`는 드리프트·합쳐짐이 있어 쓰지 않는다(timing-engine §3). 여기서는 그 판정 로직만
/// 순수·결정적으로 분리해, `CADisplayLink` 런타임 없이 `swift test`로 정확도를 증명한다
/// (제1조 3항, timing-engine §8-1).
///
/// ## 사이클
/// 1. `waiting` — ISI를 소비한다. `frameTime ≥ target`인 **첫 프레임**에서 자극을 켜고,
///    온셋 시각은 목표값이 아니라 **그 프레임의 타임스탬프**로 확정한다.
/// 2. `showingStimulus` — 자극이 켜져 응답을 기다린다. 이 동안은 새 자극이 나오지 않는다.
/// 3. `completeTrial(at:)` — 응답 또는 타임아웃으로 trial이 끝났음을 알리면, 다음 목표를
///    **그 종료 시각 + 다음 ISI**로 세우고 다시 `waiting`으로 돌아간다.
///
/// 다음 목표를 온셋이 아니라 **trial 종료 시각** 기준으로 세우는 것이 핵심이다. 사람의 응답에
/// 걸린 시간만큼 다음 대기가 밀려야, 자극이 응답 전에 겹쳐 뜨지 않고 ISI가 설계대로 2~10초
/// 유지된다.
public struct StimulusSchedule {
    /// 스케줄의 현재 단계.
    public enum State: Equatable {
        /// ISI 소비 중 — `targetTime` 이상인 첫 프레임에서 자극이 켜진다.
        case waiting(targetTime: TimeInterval)
        /// 자극이 켜져 응답을 기다리는 중.
        case showingStimulus(onset: StimulusOnset)
        /// 모든 자극 소진.
        case finished
    }

    private let intervalsMs: [Int]
    private var nextIndex: Int

    /// 현재 단계.
    public private(set) var state: State

    /// - Parameters:
    ///   - intervalsMs: 자극별 간격(ms). 개수 = 자극(=trial) 개수. `ISIScheduler.intervalsMs`가 공급.
    ///   - startTime: 세션 시작 단조 시각(초). 첫 자극은 `startTime + intervalsMs[0]`을 목표로 한다.
    public init(intervalsMs: [Int], startTime: TimeInterval) {
        precondition(intervalsMs.allSatisfy { $0 >= 0 }, "ISI는 음수일 수 없다")
        self.intervalsMs = intervalsMs
        self.nextIndex = 0
        self.state = intervalsMs.isEmpty
            ? .finished
            : .waiting(targetTime: startTime + Self.seconds(intervalsMs[0]))
    }

    /// 다음 자극이 켜질 목표 온셋 시각(단조 시계, 초). 대기 중이 아니면 `nil`.
    public var nextTargetTime: TimeInterval? {
        if case .waiting(let targetTime) = state { return targetTime }
        return nil
    }

    /// 모든 자극을 소진했는가.
    public var isFinished: Bool { state == .finished }

    /// 응답을 기다리는 중인 자극(켜져 있는 자극). 없으면 `nil`.
    public var pendingOnset: StimulusOnset? {
        if case .showingStimulus(let onset) = state { return onset }
        return nil
    }

    /// 프레임 타임스탬프 하나를 흘려보낸다.
    ///
    /// 대기 중이고 이 프레임이 목표에 도달했으면 자극을 켜고 그 온셋을 낸다. 그 외에는 `nil`.
    /// 자극이 이미 켜져 있으면(응답 대기 중) 새 자극을 내지 않는다 — 자극은 겹치지 않는다.
    public mutating func advance(frameTime: TimeInterval) -> StimulusOnset? {
        guard case .waiting(let target) = state, frameTime >= target else { return nil }
        let onset = StimulusOnset(index: nextIndex, onsetTime: frameTime)
        state = .showingStimulus(onset: onset)
        return onset
    }

    /// trial이 끝났음을 알린다(응답 또는 타임아웃).
    ///
    /// 다음 목표를 `endTime + 다음 ISI`로 세우고 대기로 돌아간다. 남은 자극이 없으면 완료다.
    /// 자극이 켜져 있지 않을 때(대기·완료) 호출하면 아무 일도 하지 않는다 — 대기 중의 탭
    /// (false start)은 trial을 끝내지 않기 때문이다.
    public mutating func completeTrial(at endTime: TimeInterval) {
        guard case .showingStimulus = state else { return }
        nextIndex += 1
        state = nextIndex < intervalsMs.count
            ? .waiting(targetTime: endTime + Self.seconds(intervalsMs[nextIndex]))
            : .finished
    }

    private static func seconds(_ ms: Int) -> TimeInterval { TimeInterval(ms) / 1_000 }
}
