import SwiftUI

/// 첫 실행 안내 — さえちゃん의 자기소개와, 이 앱이 **무엇이고 무엇이 아닌지**.
///
/// 세 가지를 시작 전에 말한다(character-voice §7 "첫 사용"):
/// 1. 무엇을 재는가 — 90초 반응시간 테스트로 오늘의 각성도를 숫자로.
/// 2. 무엇이 아닌가 — 의학적 진단이 아니고, 수면 시간을 알려 주지 않는다(제2조 4항).
/// 3. 데이터는 어디에 — 이 기기 안에만. 서버·광고·추적 없음(제3조).
///
/// 넘기는 페이지 대신 한 화면에 둔다 — 세 문단이면 충분하고, 건너뛴 페이지에 중요한 말이
/// 묻히지 않는다(제7조).
struct OnboardingView: View {
    var onFinish: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SaeTheme.Spacing.l) {
                VStack(alignment: .leading, spacing: SaeTheme.Spacing.xs) {
                    Text("voice.name")
                        .font(SaeTheme.Typography.cardTitle)
                        .foregroundStyle(SaeTheme.Palette.brand)
                    Text("onboarding.hello")
                        .font(.title2.bold())
                        .fixedSize(horizontal: false, vertical: true)
                }

                item(title: "onboarding.what_title", body: "onboarding.what_body")
                item(title: "onboarding.not_title", body: "onboarding.not_body")
                item(title: "onboarding.privacy_title", body: "onboarding.privacy_body")

                Button(action: onFinish) {
                    Text("onboarding.start")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(SaeTheme.Palette.onBrand)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(SaeTheme.Spacing.l)
        }
        .background(SaeTheme.Palette.background)
    }

    private func item(title: LocalizedStringKey, body: LocalizedStringKey) -> some View {
        SaeCard {
            Text(title)
                .font(SaeTheme.Typography.cardTitle)
            Text(body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
