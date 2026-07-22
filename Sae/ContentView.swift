import SwiftUI

/// 셸 플레이스홀더 화면.
///
/// 목적: **국제화 1급 시민**(제5조) — 보이는 문자열은 전부 `Localizable.xcstrings`
/// 키 경유. 하드코딩 없음. 측정 UI·`SaeTiming` 배선은 다음 커밋/사이클.
struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("app.title")
                .font(.largeTitle.bold())
            Text("app.tagline")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
