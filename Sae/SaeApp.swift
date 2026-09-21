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
        // trial은 세션과의 관계로 함께 담기므로 세션 하나만 지정하면 된다(data-model).
        .modelContainer(for: PVTSession.self)
    }
}
