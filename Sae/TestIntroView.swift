import SwiftUI
import SaeTiming

/// 테스트 안내 — 무엇을 하는지, 얼마나 걸리는지, 무엇이 세션을 무효로 만드는지를 **시작 전에** 말한다.
///
/// 안내에 적는 숫자는 코드의 값과 같아야 한다. trial 수는 `PVTSessionRunner.defaultTrialCount`에서,
/// 무효 기준은 `SessionValidator`에서 그대로 가져온다 — 문구에 숫자를 박아 두면 설정이 바뀔 때 안내만
/// 거짓이 된다(제2조).
/// 시간은 trial 수와 ISI로 정해지는 대략값이라 "약"을 붙인다.
struct TestIntroView: View {
    /// "시작" — 테스트 화면으로 가는 동작은 내비게이션을 가진 쪽이 정한다.
    var onStart: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SaeTheme.Spacing.l) {
                SaeCard {
                    step(number: 1, text: Text("intro.step_tap"))
                    step(number: 2, text: Text("intro.step_wait"))
                    step(number: 3, text: Text(String(
                        format: String(localized: "intro.step_length"), PVTSessionRunner.defaultTrialCount
                    )))
                    step(number: 4, text: Text("intro.step_conditions"))
                }

                NoticeText(text: Text(String(
                    format: String(localized: "intro.note_invalid"),
                    SessionValidator.defaultMaxFalseStarts, SessionValidator.defaultMinValidTrials
                )))

                Button(action: onStart) {
                    Text("intro.start")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(SaeTheme.Palette.onBrand)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(SaeTheme.Spacing.l)
        }
        .background(SaeTheme.Palette.background)
        .navigationTitle("test.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func step(number: Int, text: Text) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SaeTheme.Spacing.m) {
            Text(number, format: .number)
                .font(SaeTheme.Typography.cardTitle.monospacedDigit())
                .foregroundStyle(SaeTheme.Palette.brand)
            text
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack { TestIntroView(onStart: {}) }
}
