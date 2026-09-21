import UIKit
import SaeTiming

/// 자극 온셋 런타임 드라이버 — 순수 `StimulusSchedule`을 실제 `CADisplayLink`에 물린다.
///
/// `CADisplayLink`는 디스플레이 리프레시에 동기해 매 프레임 콜백을 주고, 각 콜백에 그 프레임의
/// 단조 타임스탬프를 준다. 이 타임스탬프를 `StimulusSchedule`에 흘려보내 **자극이 켜진 프레임의
/// 시각**을 온셋으로 캡처한다(timing-engine §3). `Timer`는 드리프트가 있어 쓰지 않는다.
///
/// 여기는 측정 **런타임**이라 `swift test`로 증명할 수 없다. 온셋 판정의 정확도는 이미
/// 순수 `StimulusSchedule`(swift test)이 증명했고, 이 계층은 그 순수 로직에 실제 프레임
/// 타임스탬프를 **정확히 전달**하는 배선만 책임진다. 응답(터치)·자극 시각화는 다음 사이클.
@MainActor
final class StimulusRunner: NSObject, ObservableObject {
    /// 측정이 도는 중인가.
    @Published private(set) var isRunning = false
    /// 실측 주사율(Hz). 프레임 간격에서 계산해 측정 조건으로 남긴다(timing-engine §3, §9).
    @Published private(set) var displayRefreshHz: Int = 0
    /// 지금까지 캡처한 자극 온셋들(프레임 타임스탬프 기준).
    @Published private(set) var onsets: [StimulusOnset] = []
    /// 프레임 타임스탬프가 공통 기준과 같은 단조 기준인지의 확인 결과(timing-engine §8-2).
    /// 첫 프레임에서 한 번 확인한다 — 기준이 다르면 차이가 초 단위 이상이라 한 번으로 드러난다.
    @Published private(set) var displayClockCheck: ClockContractResult?

    private var displayLink: CADisplayLink?
    private var schedule: StimulusSchedule?
    private var pendingIntervals: [Int] = []

    /// 시드 고정 ISI로 자극 스케줄을 CADisplayLink로 구동한다(개발 확인용 런).
    func run(count: Int = 5, seed: UInt64 = 20_260_726) {
        stop()
        onsets = []
        schedule = nil
        pendingIntervals = ISIScheduler.intervalsMs(count: count, seed: seed)
        guard !pendingIntervals.isEmpty else { return }
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
        isRunning = true
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        isRunning = false
    }

    /// 매 프레임 호출. 스케줄은 첫 프레임 타임스탬프를 시작 시각으로 삼아 생성된다.
    @objc private func tick(_ link: CADisplayLink) {
        // 자극 온셋의 기준은 이 프레임의 타임스탬프(직전 프레임 스캔아웃 시각).
        let frameTime = link.timestamp
        if schedule == nil {
            // 측정을 시작하기 전에 시계 계약부터 확인한다 — 프레임 타임스탬프가 터치와 다른
            // 기준에서 오면 이후 계산한 반응시간이 전부 무의미해진다(timing-engine §2·§8-2).
            displayClockCheck = RuntimeClockCheck.verify(
                sampleTs: frameTime, referenceTs: CACurrentMediaTime(), source: "CADisplayLink.timestamp"
            )
            schedule = StimulusSchedule(intervalsMs: pendingIntervals, startTime: frameTime)
            let period = link.targetTimestamp - link.timestamp
            if period > 0 { displayRefreshHz = Int((1.0 / period).rounded()) }
        }
        if let onset = schedule?.advance(frameTime: frameTime) {
            onsets.append(onset)
        }
        if schedule?.isFinished == true {
            stop()
        }
    }
}
