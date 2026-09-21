import UIKit
import SaeTiming

/// PVT 세션 런타임 — 순수 코어(`SaeTiming`)에 실제 프레임·터치 타임스탬프를 물려 한 번의 측정을 돌린다.
///
/// 한 사이클: **대기(ISI) → 자극 켜짐 → 탭(또는 타임아웃) → 반응시간 산출 → 다음 대기.**
/// 자극 온셋은 `CADisplayLink`, 응답은 `UITouch.timestamp`에서 오고(timing-engine §3·§4),
/// 판정·집계는 전부 순수 코어가 한다. 이 계층은 **타임스탬프를 정확히 전달**하는 배선만 책임진다
/// (제1조 3항 — 정확도는 `swift test`가 증명한 순수층에서 나온다).
///
/// 타이밍 루프에 애니메이션·비동기·디스크 I/O를 넣지 않는다(제1조 1항, timing-engine §6).
/// 자극 표시는 `isStimulusVisible` 플래그 토글 하나뿐이다.
@MainActor
final class PVTSessionRunner: NSObject, ObservableObject {
    /// 적용 중인 보정 오프셋(ms) — **미보정(0)**.
    ///
    /// 디스플레이 점등·터치 스캔의 계통 지연은 포토다이오드 실측(timing-engine §8-3, 하드웨어 필요)
    /// 전까지 값을 알 수 없다. 추정치를 지어내는 대신 0으로 두고 "미보정"임을 데이터와 화면에
    /// 그대로 남긴다(제2조 3항 — 한계를 숨기지 않는다).
    nonisolated static let calibrationOffsetMs: Double = 0

    /// 기본 trial 수. 90초 세션의 최종 trial 수는 아직 확정 전이라(score-algorithm 열린 결정),
    /// 지금은 검증을 빠르게 돌릴 수 있는 값으로 둔다.
    nonisolated static let defaultTrialCount = 5

    /// 측정이 도는 중인가.
    @Published private(set) var isRunning = false
    /// 자극이 켜져 있는가. **이 플래그 토글이 자극 표시의 전부다** — 페이드·스케일 금지(제1조 1항).
    @Published private(set) var isStimulusVisible = false
    /// 실측 주사율(Hz). 프레임 간격에서 계산해 측정 조건으로 남긴다(timing-engine §3, §9).
    @Published private(set) var displayRefreshHz: Int = 0
    /// 캡처한 자극 온셋 원자료(표시 프레임 타임스탬프 기준).
    @Published private(set) var onsets: [StimulusOnset] = []
    /// trial 판정 결과 원자료. false start는 trial을 소비하지 않으므로 자극 수보다 많을 수 있다.
    @Published private(set) var outcomes: [TrialOutcome] = []
    /// 세션 종료 후의 요약 지표(data-model `PVTSession` 요약 필드).
    @Published private(set) var summary: PVTSessionSummary?
    /// 세션 타당도 판정(score-algorithm §1-3). 무효면 사유를 함께 보여준다.
    @Published private(set) var validity: SessionValidity?
    /// 프레임 타임스탬프가 공통 기준과 같은 단조 기준인지의 확인 결과(timing-engine §8-2).
    /// 첫 프레임에서 한 번 확인한다 — 기준이 다르면 차이가 초 단위 이상이라 한 번으로 드러난다.
    @Published private(set) var displayClockCheck: ClockContractResult?

    private var displayLink: CADisplayLink?
    private var schedule: StimulusSchedule?
    private var pendingIntervals: [Int] = []

    /// 시드 고정 ISI로 한 세션을 시작한다. 같은 시드는 같은 자극 간격 수열을 준다(재현 가능성).
    func run(trialCount: Int = defaultTrialCount, seed: UInt64 = 20_260_726) {
        stop()
        onsets = []
        outcomes = []
        summary = nil
        validity = nil
        isStimulusVisible = false
        schedule = nil
        pendingIntervals = ISIScheduler.intervalsMs(count: trialCount, seed: seed)
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
        isStimulusVisible = false
    }

    /// 저수준 경로로 들어온 탭 하나를 이 세션의 응답으로 처리한다.
    ///
    /// 자극이 켜져 있으면 반응시간을, 대기 중이면 false start를 기록한다. 두 판정 모두 순수
    /// `TrialClassifier`에 맡긴다 — 분류 규칙이 앱과 코어로 갈라지면 테스트가 증명한 것과
    /// 실제 동작이 달라진다(제1조 3항).
    func recordTouch(_ sample: TouchSample) {
        guard isRunning, let schedule else { return }

        if let pending = schedule.pendingOnset {
            let outcome = TrialClassifier.classify(
                stimulusTs: pending.onsetTime,
                touchTs: sample.timestamp,
                calibrationOffsetMs: Self.calibrationOffsetMs
            )
            finishTrial(outcome: outcome, at: sample.timestamp)
        } else if let target = schedule.nextTargetTime {
            // 대기 중의 탭 = 아직 오지 않은 자극보다 먼저 누른 것 → false start.
            // 아직 자극이 없으므로 trial을 끝내지 않는다. 기록만 하고 대기를 계속한다.
            let outcome = TrialClassifier.classify(
                stimulusTs: target,
                touchTs: sample.timestamp,
                calibrationOffsetMs: Self.calibrationOffsetMs
            )
            outcomes.append(outcome)
        }
    }

    /// 매 프레임 호출. 스케줄은 첫 프레임을 시작 시각으로 삼아 생성된다.
    @objc private func tick(_ link: CADisplayLink) {
        // 자극 온셋의 기준은 **이 콜백이 그리는 프레임이 표시될 시각**(`targetTimestamp`)이다.
        // 여기서 플래그를 켜면 그 변경은 지금 준비 중인 프레임에 실려 나가므로, 직전 프레임
        // 시각(`timestamp`)을 온셋으로 쓰면 온셋을 한 프레임(60Hz에서 16.7ms) 이르게 잡아
        // 반응시간이 그만큼 부풀려진다(timing-engine §3).
        //
        // 전제: 이 콜백의 상태 변경이 그 프레임에 실린다. 프레임이 드랍되면 실제 점등은 더
        // 늦어지며, 이 잔여 오차는 상수로 없앨 수 없다(timing-engine §7, 제2조 3항).
        let frameTime = link.targetTimestamp

        if schedule == nil {
            // 측정을 시작하기 전에 시계 계약부터 확인한다 — 프레임 타임스탬프가 터치와 다른
            // 기준에서 오면 이후 계산한 반응시간이 전부 무의미해진다(timing-engine §2·§8-2).
            displayClockCheck = RuntimeClockCheck.verify(
                sampleTs: link.timestamp, referenceTs: CACurrentMediaTime(), source: "CADisplayLink.timestamp"
            )
            schedule = StimulusSchedule(intervalsMs: pendingIntervals, startTime: frameTime)
            let period = link.targetTimestamp - link.timestamp
            if period > 0 { displayRefreshHz = Int((1.0 / period).rounded()) }
        }

        if let onset = schedule?.advance(frameTime: frameTime) {
            onsets.append(onset)
            isStimulusVisible = true
        }

        // 타임아웃: 자극이 떠 있는데 정해진 창을 넘기면 무응답으로 확정하고 다음 대기로 넘어간다.
        if let pending = schedule?.pendingOnset {
            let elapsedMs = (frameTime - pending.onsetTime) * 1_000
            if elapsedMs >= TrialClassifier.defaultTimeoutMs {
                finishTrial(outcome: .noResponse, at: frameTime)
            }
        }
    }

    /// trial 하나를 닫고 다음 대기로 넘어간다. 마지막이면 세션을 마감한다.
    private func finishTrial(outcome: TrialOutcome, at endTime: TimeInterval) {
        outcomes.append(outcome)
        isStimulusVisible = false
        schedule?.completeTrial(at: endTime)
        if schedule?.isFinished == true { finishSession() }
    }

    /// 세션 마감 — 원자료에서 요약과 타당도를 파생한다.
    ///
    /// 집계는 측정이 **끝난 뒤** 한다. 타이밍 루프 안에서 계산·저장하지 않는다(timing-engine §6).
    private func finishSession() {
        stop()
        let summary = PVTSessionSummary.make(from: outcomes)
        self.summary = summary
        validity = SessionValidator.evaluate(summary)
    }
}
