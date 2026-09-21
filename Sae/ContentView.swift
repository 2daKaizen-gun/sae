import SwiftUI
import SaeTiming

/// 셸 플레이스홀더 화면.
///
/// 두 가지를 증명하는 것이 이 뷰의 목적이다:
/// 1. **국제화 1급 시민**(제5조) — 보이는 문자열은 전부 `Localizable.xcstrings` 키 경유. 하드코딩 없음.
/// 2. **`SaeTiming` 링크** — 순수 코어의 기본 상수(`TrialClassifier.defaultLapseThresholdMs`)를
///    실제로 참조해, 로컬 패키지 의존이 진짜로 붙어 링크됨을 보인다.
/// 앱 내 이동 목적지.
enum Route: Hashable {
    case timingLab
}

struct ContentView: View {
    /// SaeTiming 순수 코어에서 온 값. 아직 측정은 아니고, 의존이 링크됐음을 보이는 용도.
    private let lapseThresholdMs = Int(TrialClassifier.defaultLapseThresholdMs)

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
                Text(String(format: String(localized: "app.lapse_threshold_ms"), lapseThresholdMs))
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.tertiary)

                NavigationLink(value: Route.timingLab) {
                    Text("timinglab.link")
                }
                .padding(.top, 8)
            }
            .padding()
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .timingLab: TimingLabView()
                }
            }
        }
        .onAppear {
            #if DEBUG
            // 개발 확인용: `-autolab` 실행 인자로 타이밍 랩에 바로 진입(시뮬 자동화).
            if CommandLine.arguments.contains("-autolab") { path = [.timingLab] }
            #endif
        }
    }
}

#Preview {
    ContentView()
}
