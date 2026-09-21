import SwiftUI
import SaeTiming

/// 타이밍 런타임 확인 화면(개발용).
///
/// `CADisplayLink`가 자극 스케줄을 실제로 구동해 온셋을 프레임 타임스탬프로 캡처하는지,
/// 주사율이 실측되는지 눈으로 확인한다. 정식 PVT 인터랙션(자극 시각화·터치 응답)은 다음 사이클.
struct TimingLabView: View {
    @StateObject private var runner = StimulusRunner()
    /// 저수준 경로로 캡처한 마지막 터치 다운의 단조 시각(초).
    @State private var lastTapTime: TimeInterval?
    /// 터치 타임스탬프가 공통 기준과 같은 단조 기준인지의 확인 결과(timing-engine §8-2).
    @State private var touchClockCheck: ClockContractResult?

    var body: some View {
        VStack(spacing: 20) {
            Text(String(format: String(localized: "timinglab.refresh"), runner.displayRefreshHz))
                .font(.headline.monospacedDigit())

            Text(String(format: String(localized: "timinglab.onsets"), runner.onsets.count))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)

            if runner.isRunning {
                ProgressView().padding(.vertical, 4)
            }

            // 캡처된 온셋 원자료(개발용 — 숫자 위주라 로컬라이즈하지 않는다).
            List(runner.onsets, id: \.index) { onset in
                Text(String(format: "#%d   %.3f s", onset.index, onset.onsetTime))
                    .font(.footnote.monospacedDigit())
            }
            .frame(maxHeight: 220)

            // 두 시계가 같은 단조 기준인지 — 이 설계의 전제(timing-engine §2). 깨지면 반응시간이
            // 통째로 무의미해지므로 랩 화면에서 실측값을 그대로 보여준다(제2조: 조건을 공개한다).
            clockCheckRow(titleKey: "timinglab.clock_display", result: runner.displayClockCheck)
            clockCheckRow(titleKey: "timinglab.clock_touch", result: touchClockCheck)

            // 저수준 터치 캡처 확인 영역(사이클 B). D에서 자극 영역과 결합해 반응시간을 낸다.
            TouchCatcher { sample in
                lastTapTime = sample.timestamp
                touchClockCheck = RuntimeClockCheck.verify(
                    sampleTs: sample.timestamp,
                    referenceTs: sample.referenceTime,
                    source: "UITouch.timestamp"
                )
            }
                .frame(height: 96)
                .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                .overlay {
                    Text("timinglab.tap_area")
                        .font(.subheadline)
                        .foregroundStyle(.tint)
                }
                .accessibilityIdentifier("touchCatcher")

            Text(lastTapTime.map { String(format: String(localized: "timinglab.last_tap"), $0) }
                 ?? String(localized: "timinglab.no_tap"))
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.secondary)

            Button {
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
}

#Preview {
    NavigationStack { TimingLabView() }
}
