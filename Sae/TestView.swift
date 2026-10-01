import SwiftUI
import SwiftData
import UIKit
import SaeTiming

/// 사용자용 PVT 테스트 화면 — 자극 패드 하나와 진행 정도만 보인다. 끝나면 같은 자리에 결과가 뜬다.
///
/// ## 측정은 랩과 같은 엔진으로
/// `PVTSessionRunner`·`StimulusPad`를 **그대로** 쓴다. 이 화면은 측정 방식을 새로 만들지 않는다
/// — 검증한 엔진과 사용자가 쓰는 엔진이 같아야 한다(제1조 3항).
///
/// ## 테스트 중에는 반응시간을 보이지 않는다
/// 매 trial의 RT를 보여주면 사용자가 그 숫자에 반응해 다음 응답이 달라질 수 있다. 진행 정도만 보이고,
/// 숫자는 결과에서 한 번에 보인다(제2조).
///
/// ## 중간에 나가면 저장하지 않는다
/// 저장은 세션이 **끝났을 때만** 일어난다. 도중에 뒤로 가면 런너를 멈추고 아무것도 남기지 않는다
/// — 반쪽 세션을 측정으로 기록하지 않는다.
struct TestView: View {
    /// 결과 화면의 "완료" — 홈으로 돌아가는 동작은 내비게이션을 가진 쪽이 정한다.
    var onDone: () -> Void

    @StateObject private var runner = PVTSessionRunner()
    @Environment(\.modelContext) private var modelContext
    @State private var didSaveFail = false

    /// 화면 전환이 끝난 뒤 측정을 시작하기까지의 여유. 푸시 애니메이션(약 0.35초)이 도는 동안
    /// 첫 프레임을 잡지 않도록 한다. ISI가 최소 2초라 이 지연은 측정값에 들어가지 않는다(제1조 1항).
    private static let startDelay: Duration = .milliseconds(600)

    var body: some View {
        Group {
            if let result = runner.result {
                ResultView(result: result, onDone: onDone)
                    .navigationBarBackButtonHidden()
                    .overlay(alignment: .bottom) {
                        if didSaveFail {
                            NoticeText(text: Text("session.save_failed"), isProblem: true)
                                .padding(SaeTheme.Spacing.l)
                        }
                    }
            } else {
                testContent
            }
        }
        .task {
            try? await Task.sleep(for: Self.startDelay)
            guard !Task.isCancelled else { return }
            UIApplication.shared.isIdleTimerDisabled = true // 테스트 중 화면이 꺼지지 않게
            runner.run()
        }
        .onDisappear {
            runner.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        // 저장은 세션이 끝난 뒤에만 — 측정 중 디스크 접근은 타이밍 경로를 오염시킨다(제1조 1항).
        .onChange(of: runner.result) { _, result in
            guard let result else { return }
            UIApplication.shared.isIdleTimerDisabled = false
            do {
                try PVTSessionStore.save(result, in: modelContext)
            } catch {
                didSaveFail = true
            }
        }
    }

    private var testContent: some View {
        VStack(spacing: SaeTheme.Spacing.l) {
            Text(String(
                format: String(localized: "test.progress"),
                completedStimuli, PVTSessionRunner.defaultTrialCount
            ))
            .font(SaeTheme.Typography.metric)
            .foregroundStyle(.secondary)

            StimulusPad(isStimulusVisible: runner.isStimulusVisible, height: 420) { sample in
                runner.recordTouch(sample)
                // 시계 계약은 사용자 화면에서도 확인한다(DEBUG에서 위반 시 멈춤). 응답 시각을 읽은 뒤라
                // 측정에는 영향이 없다(timing-engine §8-2).
                RuntimeClockCheck.verify(
                    sampleTs: sample.timestamp, referenceTs: sample.referenceTime, source: "UITouch.timestamp"
                )
            }

            NoticeText(text: Text("test.hint"))
            Spacer()
        }
        .padding(SaeTheme.Spacing.l)
        .background(SaeTheme.Palette.background)
        .navigationTitle("test.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// 지금까지 켜진 자극 수. false start는 자극을 소비하지 않으므로 세지 않는다.
    private var completedStimuli: Int {
        runner.trials.filter { $0.onsetTime != nil }.count
    }
}
