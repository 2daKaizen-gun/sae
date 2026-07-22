import SwiftUI

/// 앱 진입점 — 冴え(Sae).
///
/// 이번 사이클은 순수 코어 `SaeTiming`을 물고 빌드되는 **셸**까지다.
/// 실제 PVT 측정 런타임(CADisplayLink 온셋·UITouch.timestamp 응답)은 다음 사이클에
/// 배선한다(timing-engine §3·§4, 제1조). 여기선 측정 경로를 아직 만들지 않는다.
@main
struct SaeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
