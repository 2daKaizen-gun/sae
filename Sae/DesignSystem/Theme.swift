import SwiftUI

/// 冴え 디자인 토큰 — 색·여백·모서리·글자 역할을 **한곳에서** 정한다.
///
/// 원칙(제7조 네이티브 우선): 표면·글자색은 **시스템 시맨틱 색**을 써서 다크 모드를 공짜로 얻고,
/// 브랜드 색은 `AccentColor` 에셋 하나(라이트/다크 두 값)만 둔다. 글꼴은 SF이며 Dynamic Type을
/// 깨지 않도록 크기 대신 **텍스트 스타일**로 지정한다.
///
/// 점수에 좋음/나쁨 색 구간을 두지 않는다. 구간은 출처 없는 새 분류가 되고(제2조), 나쁜 결과를
/// 색으로 포장할 여지를 만든다(제4조). 점수는 브랜드 색 하나로, 의미는 옆의 근거가 전한다.
enum SaeTheme {
    /// 여백 단계(pt). 4의 배수로만 쓴다.
    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
    }

    /// 모서리 반경(pt).
    enum Radius {
        static let card: CGFloat = 16
    }

    /// 색 역할. 브랜드 색 외에는 시스템 시맨틱 색이다.
    enum Palette {
        /// 브랜드 색 — `AccentColor` 에셋(라이트 #1D6BC7 / 다크 #66B0FA).
        static let brand = Color.accentColor
        /// 화면 바탕.
        static let background = Color(uiColor: .systemGroupedBackground)
        /// 카드 표면.
        static let surface = Color(uiColor: .secondarySystemGroupedBackground)
        /// 문제를 알리는 색(저장 실패·무효 사유). 점수 평가에는 쓰지 않는다.
        static let problem = Color(uiColor: .systemRed)
    }

    /// 글자 역할 — 모두 텍스트 스타일 기반이라 Dynamic Type을 따른다.
    enum Typography {
        /// 冴え度 숫자. 둥근 SF + 고정폭 숫자로 자릿수가 바뀌어도 흔들리지 않게.
        static let score = Font.system(.largeTitle, design: .rounded).weight(.bold).monospacedDigit()
        static let cardTitle = Font.headline
        static let metric = Font.subheadline.monospacedDigit()
        static let notice = Font.caption
    }
}
