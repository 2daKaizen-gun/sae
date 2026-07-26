import Foundation

/// 자극 온셋 이벤트 — 하나의 자극이 실제로 켜진 프레임을 나타낸다.
///
/// `onsetTime`은 "그려라"를 호출한 시각이 아니라, **자극을 표시로 전환한 프레임의
/// 타임스탬프**(단조 시계, 초)다(timing-engine §3). 이 값이 반응시간 계산의 기준점이 된다:
/// `reactionTimeMs = (touch.timestamp − onsetTime) × 1000 − offset`.
public struct StimulusOnset: Equatable {
    /// 세션 내 자극 순번(0-based).
    public let index: Int
    /// 자극이 켜진 프레임의 단조 타임스탬프(초). `CADisplayLink.timestamp`가 이 값을 채운다.
    public let onsetTime: TimeInterval

    public init(index: Int, onsetTime: TimeInterval) {
        self.index = index
        self.onsetTime = onsetTime
    }
}

/// 자극 스케줄 진행기 — ISI를 소비해 "언제 자극을 켤지"를 결정하는 **순수 상태기계**.
///
/// 실제 표시는 `CADisplayLink`가 매 프레임 `advance(frameTime:)`를 호출해 소비한다.
/// `Timer`는 드리프트·합쳐짐이 있어 쓰지 않는다(timing-engine §3). 여기서는 그 판정 로직만
/// 순수·결정적으로 분리해, `CADisplayLink` 런타임 없이 `swift test`로 정확도를 증명한다
/// (제1조 3항, timing-engine §8-1).
///
/// 규칙: **목표 온셋 시각을 정해두고, 들어오는 프레임 타임스탬프 중 `frameTime ≥ target`인
/// 첫 프레임을 온셋으로 확정**한다. 온셋 시각은 그 프레임의 타임스탬프이며(목표값이 아니다),
/// 다음 목표는 **실제 온셋 + 다음 ISI**로 세워 자극 간 간격을 온셋 기준으로 잡는다.
public struct StimulusSchedule {
    private let intervalsMs: [Int]
    private var nextIndex: Int

    /// 다음 자극이 켜질 목표 온셋 시각(단조 시계, 초). 모든 자극을 소진하면 `nil`.
    public private(set) var nextTargetTime: TimeInterval?

    /// - Parameters:
    ///   - intervalsMs: 자극별 간격(ms). 개수 = 자극(=trial) 개수. `ISIScheduler.intervalsMs`가 공급.
    ///   - startTime: 세션 시작 단조 시각(초). 첫 자극은 `startTime + intervalsMs[0]`을 목표로 한다.
    public init(intervalsMs: [Int], startTime: TimeInterval) {
        precondition(intervalsMs.allSatisfy { $0 >= 0 }, "ISI는 음수일 수 없다")
        self.intervalsMs = intervalsMs
        self.nextIndex = 0
        self.nextTargetTime = intervalsMs.isEmpty ? nil : startTime + Self.seconds(intervalsMs[0])
    }

    /// 프레임 타임스탬프 하나를 흘려보낸다.
    ///
    /// 이 프레임에서 자극이 켜지면(=목표 온셋 시각에 도달) 그 온셋을, 아직 아니면 `nil`을 낸다.
    /// 온셋이 나면 내부 목표가 다음 자극(있다면)으로 전진한다.
    public mutating func advance(frameTime: TimeInterval) -> StimulusOnset? {
        guard let target = nextTargetTime, frameTime >= target else { return nil }
        let onset = StimulusOnset(index: nextIndex, onsetTime: frameTime)
        nextIndex += 1
        nextTargetTime = nextIndex < intervalsMs.count
            ? frameTime + Self.seconds(intervalsMs[nextIndex])
            : nil
        return onset
    }

    /// 모든 자극을 소진했는가(더 켤 자극이 없는가).
    public var isFinished: Bool { nextTargetTime == nil }

    private static func seconds(_ ms: Int) -> TimeInterval { TimeInterval(ms) / 1_000 }
}
