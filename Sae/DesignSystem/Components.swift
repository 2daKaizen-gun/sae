import SwiftUI

/// 카드 — 화면의 정보 묶음 단위. 표면 색·여백·모서리를 토큰으로만 정한다.
struct SaeCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: SaeTheme.Spacing.s) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SaeTheme.Spacing.l)
        .background(SaeTheme.Palette.surface, in: RoundedRectangle(cornerRadius: SaeTheme.Radius.card))
    }
}

/// 冴え度 카드 — 큰 숫자 하나와, **그 숫자를 만든 근거**를 같은 카드 안에 둔다(제2조 2항).
///
/// 숫자 색은 브랜드 색 하나다. 점수 구간별 색은 쓰지 않는다(`SaeTheme` 참고).
/// 근거·결측 안내는 호출부가 `details`로 넣는다 — 숫자만 떨어져 있는 카드는 만들지 않는다.
struct ScoreCard<Details: View>: View {
    let score: Int
    @ViewBuilder var details: Details

    var body: some View {
        SaeCard {
            // 라벨과 숫자를 VoiceOver에 한 요소로 묶는다("Sae score, 92"). 숫자에 긴 접근성 라벨을 따로 붙이면
            // 화면에 보이는 "92"보다 라벨이 길어 자동 점검이 잘린 텍스트로 본다(#24).
            VStack(alignment: .leading, spacing: SaeTheme.Spacing.s) {
                Text("score.label")
                    .font(SaeTheme.Typography.cardTitle)
                    .foregroundStyle(SaeTheme.Palette.secondaryText)
                Text(score, format: .number)
                    .font(SaeTheme.Typography.score)
                    .foregroundStyle(SaeTheme.Palette.brand)
            }
            .accessibilityElement(children: .combine)
            details
        }
    }
}

/// 지표 한 줄 — 이름과 값. 값은 고정폭 숫자라 줄끼리 자릿수가 맞는다.
///
/// 접근성 글자 크기(AX1~AX5)에서는 이름 위, 값 아래로 **세로로** 놓는다. 가로로 두면 이름이 단어 중간에서
/// 끊긴다("reac-tion time", #24). 보통 크기에서는 그대로 한 줄이다.
struct MetricRow: View {
    let title: LocalizedStringKey
    let value: String

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let stacked = typeSize.isAccessibilitySize
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: SaeTheme.Spacing.xs))
            : AnyLayout(HStackLayout())
        layout {
            Text(title)
            if !stacked { Spacer() }
            Text(value)
                .foregroundStyle(SaeTheme.Palette.secondaryText)
        }
        .font(SaeTheme.Typography.metric)
    }
}

/// 참고 블록 — 점수에 들어가지 않는 정보(HRV 등)를 담는다.
///
/// 점수 카드와 **시각적으로 다르게**(테두리만, 채움 없음) 그려 "이건 점수가 아니다"를 모양으로도
/// 말한다. 제목에 참고용이라는 사실이 먼저 온다(제2조).
struct ReferenceBlock<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: SaeTheme.Spacing.xs) {
            Text(title)
                .font(SaeTheme.Typography.cardTitle)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SaeTheme.Spacing.l)
        .overlay(
            RoundedRectangle(cornerRadius: SaeTheme.Radius.card)
                .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
        )
    }
}

/// 안내 문구 — 한계·결측·실패를 말하는 작은 글씨. 문제일 때만 경고색을 쓴다.
struct NoticeText: View {
    let text: Text
    var isProblem = false

    var body: some View {
        text
            .font(SaeTheme.Typography.notice)
            .foregroundStyle(isProblem ? SaeTheme.Palette.problem : SaeTheme.Palette.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: SaeTheme.Spacing.l) {
            ScoreCard(score: 60) {
                MetricRow(title: "score.label", value: "60")
                NoticeText(text: Text("score.missing_signals"))
            }
            ReferenceBlock(title: "hrv.title") {
                NoticeText(text: Text("hrv.none"))
            }
        }
        .padding()
    }
    .background(SaeTheme.Palette.background)
}
