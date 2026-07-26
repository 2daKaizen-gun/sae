import SwiftUI
import SaeTiming

/// 타이밍 런타임 확인 화면(개발용).
///
/// `CADisplayLink`가 자극 스케줄을 실제로 구동해 온셋을 프레임 타임스탬프로 캡처하는지,
/// 주사율이 실측되는지 눈으로 확인한다. 정식 PVT 인터랙션(자극 시각화·터치 응답)은 다음 사이클.
struct TimingLabView: View {
    @StateObject private var runner = StimulusRunner()

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
}

#Preview {
    NavigationStack { TimingLabView() }
}
