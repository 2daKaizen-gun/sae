import SwiftUI
import SwiftData
import SaeTiming

/// 타이밍 런타임 검증 화면(개발용).
///
/// PVT 한 세션을 실제로 돌려서 확인한다: `CADisplayLink`가 자극을 켜고, 저수준 터치가 응답
/// 시각을 잡고, 순수 코어가 반응시간·요약·타당도를 낸다. 측정 조건(주사율·시계 계약·보정 오프셋)을
/// 숨기지 않고 화면에 그대로 띄우는 것도 이 화면의 목적이다(제2조).
///
/// 사용자용 PVT 화면의 디자인·카피는 뒤 단계(`CONCEPT.md` §7 3주차) 몫이다. 여기는 엔진을
/// 눈으로 검증하는 계측 화면이다.
struct TimingLabView: View {
    @StateObject private var runner = PVTSessionRunner()
    /// 터치 타임스탬프가 공통 기준과 같은 단조 기준인지의 확인 결과(timing-engine §8-2).
    @State private var touchClockCheck: ClockContractResult?
    /// 저장 실패를 삼키지 않기 위한 플래그 — 실패했으면 실패했다고 화면에 말한다(제9조 6항).
    @State private var didSaveFail = false

    @Environment(\.modelContext) private var modelContext
    /// 저장된 세션들. 앱을 다시 켜도 남아 있는지가 영속화의 관찰 가능한 증거다.
    @Query(sort: \PVTSession.startedAt, order: .reverse) private var savedSessions: [PVTSession]

    var body: some View {
        VStack(spacing: 12) {
            measurementConditions

            stimulusArea

            trialList

            if let result = runner.result {
                summaryView(result)
            }

            storageRow

            Button {
                touchClockCheck = nil
                didSaveFail = false
                runner.run()
            } label: {
                Text("timinglab.run")
            }
            .buttonStyle(.borderedProminent)
            .disabled(runner.isRunning)
        }
        .padding()
        .navigationTitle("timinglab.title")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { runner.run() }
        .onDisappear { runner.stop() }
        // 저장은 세션이 끝난 뒤에만 — 측정 중 디스크 접근은 타이밍 경로를 오염시킨다(제1조 1항).
        .onChange(of: runner.result) { _, result in
            guard let result else { return }
            do {
                try PVTSessionStore.save(result, in: modelContext)
            } catch {
                didSaveFail = true
            }
        }
    }

    /// 저장 상태 — 지금까지 남은 세션 수. 실패했으면 실패했다고 말한다.
    private var storageRow: some View {
        Text(didSaveFail
             ? String(localized: "timinglab.save_failed")
             : String(format: String(localized: "timinglab.saved_sessions"), savedSessions.count))
            .font(.caption.monospacedDigit())
            .foregroundStyle(didSaveFail ? Color.red : Color.secondary)
    }

    /// 측정 조건 — 주사율·시계 계약·보정 오프셋. 재현에 필요한 값을 공개한다(timing-engine §9).
    private var measurementConditions: some View {
        VStack(spacing: 4) {
            Text(String(format: String(localized: "timinglab.refresh"), runner.displayRefreshHz))
                .font(.headline.monospacedDigit())

            Text(String(format: String(localized: "timinglab.uncalibrated"), PVTSessionRunner.calibrationOffsetMs))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            // 두 시계가 같은 단조 기준인지 — 이 설계의 전제(timing-engine §2). 깨지면 반응시간이
            // 통째로 무의미해지므로 실측값을 그대로 보여준다.
            clockCheckRow(titleKey: "timinglab.clock_display", result: runner.displayClockCheck)
            clockCheckRow(titleKey: "timinglab.clock_touch", result: touchClockCheck)
        }
    }

    /// 자극 영역 — 표시는 **색 플래그 토글 하나**뿐이고, 탭은 저수준 경로로 받는다.
    ///
    /// 애니메이션을 명시적으로 끈다(`animation(nil)`): 페이드·스케일이 끼면 "자극이 켜진 시각"이
    /// 흐려져 온셋 기준이 무너진다(제1조 1항, timing-engine §6). 레이아웃도 바뀌지 않게
    /// 크기를 고정해, 자극 프레임에서 레이아웃 패스가 돌지 않도록 한다.
    private var stimulusArea: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(runner.isStimulusVisible ? Color.green : Color.gray.opacity(0.15))
            .frame(height: 180)
            .animation(nil, value: runner.isStimulusVisible)
            .overlay {
                Text(runner.isStimulusVisible ? "timinglab.stimulus_tap" : "timinglab.stimulus_wait")
                    .font(.title3.bold())
                    .foregroundStyle(runner.isStimulusVisible ? Color.white : Color.secondary)
                    .animation(nil, value: runner.isStimulusVisible)
            }
            .overlay {
                TouchCatcher { sample in
                    runner.recordTouch(sample)
                    touchClockCheck = RuntimeClockCheck.verify(
                        sampleTs: sample.timestamp,
                        referenceTs: sample.referenceTime,
                        source: "UITouch.timestamp"
                    )
                }
                .accessibilityIdentifier("touchCatcher")
            }
    }

    /// trial 원자료 — 판정과 반응시간을 그대로 나열한다(요약만 보여주지 않는다, 제1·2조).
    private var trialList: some View {
        List(Array(runner.trials.enumerated()), id: \.offset) { position, record in
            HStack {
                Text(String(format: "#%lld", record.index))
                Spacer()
                Text(label(for: record.outcome))
            }
            .font(.footnote.monospacedDigit())
            .id(position)
        }
        .listStyle(.plain)
        .frame(maxHeight: 160)
    }

    /// 세션 요약 + 타당도. 무효면 사유까지 말한다 — 억지 숫자보다 "못 쟀다"가 정직하다(제2조).
    private func summaryView(_ result: PVTSessionResult) -> some View {
        VStack(spacing: 4) {
            Text(String(
                format: String(localized: "timinglab.summary_line"),
                result.summary.medianRTms ?? 0,
                result.summary.lapseCount,
                result.summary.falseStartCount
            ))
            .font(.subheadline.monospacedDigit())

            Text(validityLabel(result.validity))
                .font(.caption)
                .foregroundStyle(result.validity == .valid ? Color.secondary : Color.red)
        }
    }

    /// 시계 계약 한 줄 — 실측 차이(ms)와 판정을 함께 보인다. 아직 안 쟀으면 "미측정"이라고 말한다(제2조).
    private func clockCheckRow(titleKey: LocalizedStringKey, result: ClockContractResult?) -> some View {
        HStack {
            Text(titleKey)
            Spacer()
            if let result {
                Text(String(
                    format: String(localized: "timinglab.clock_value"),
                    result.deltaSeconds * 1_000,
                    String(localized: result.holds ? "timinglab.clock_ok" : "timinglab.clock_broken")
                ))
                .foregroundStyle(result.holds ? Color.secondary : Color.red)
            } else {
                Text("timinglab.clock_pending")
                    .foregroundStyle(.tertiary)
            }
        }
        .font(.caption.monospacedDigit())
    }

    private func label(for outcome: TrialOutcome) -> String {
        switch outcome {
        case .valid(let rt):
            return String(format: String(localized: "timinglab.outcome_rt"), rt)
        case .lapse(let rt):
            return String(format: String(localized: "timinglab.outcome_lapse"), rt)
        case .falseStart:
            return String(localized: "timinglab.outcome_false_start")
        case .noResponse:
            return String(localized: "timinglab.outcome_no_response")
        }
    }

    private func validityLabel(_ validity: SessionValidity) -> String {
        switch validity {
        case .valid:
            return String(localized: "timinglab.summary_valid")
        case .invalid(.tooManyFalseStarts):
            return String(localized: "timinglab.summary_invalid_false_starts")
        case .invalid(.tooFewValidTrials):
            return String(localized: "timinglab.summary_invalid_few_trials")
        }
    }
}

#Preview {
    NavigationStack { TimingLabView() }
}
