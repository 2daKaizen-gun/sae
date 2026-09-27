import SwiftUI

/// 앱 내 이동 목적지.
enum Route: Hashable {
    case timingLab
    case trend
}

/// 첫 화면 — 앱 이름·태그라인과 타이밍 랩으로 가는 입구.
///
/// 보이는 문자열은 전부 `Localizable.xcstrings` 키를 거친다(제5조). 사용자용 홈 화면의
/// 디자인은 뒤 단계(`CONCEPT.md` §7) 몫이다.
struct ContentView: View {
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 16) {
                Text("app.title")
                    .font(.largeTitle.bold())
                Text("app.tagline")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                NavigationLink(value: Route.trend) {
                    Text("trend.link")
                }
                .padding(.top, 8)

                NavigationLink(value: Route.timingLab) {
                    Text("timinglab.link")
                }
            }
            .padding()
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .timingLab: TimingLabView()
                case .trend: TrendView()
                }
            }
        }
        .onAppear {
            #if DEBUG
            // 개발 확인용 실행 인자(시뮬 자동화). `-autolab`: 타이밍 랩에 바로 진입.
            if CommandLine.arguments.contains("-autolab") { path = [.timingLab] }
            // `-trendDemo`: 메모리 전용 데모 데이터로 추이 화면에 바로 진입(SaeApp·TrendDemo).
            if TrendDemo.isRequested { path = [.trend] }
            #endif
        }
    }
}

#Preview {
    ContentView()
}
