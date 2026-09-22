import SwiftUI
import SwiftData

/// 앱 진입점 — 冴え(Sae).
///
/// 측정 원자료는 **온디바이스 SwiftData**에만 쌓인다. 서버·계정·동기화는 없다(제3조).
@main
struct SaeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // trial은 세션과의 관계로 함께 담기지만, `DailyScore`는 세션에서 역참조가 없어
        // 스키마에 직접 넣어야 한다(data-model).
        .modelContainer(for: [PVTSession.self, DailyScore.self])
    }
}
