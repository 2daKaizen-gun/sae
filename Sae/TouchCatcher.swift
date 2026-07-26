import SwiftUI
import UIKit

/// 저수준 터치 시각 캡처 — 반응시간의 "응답 시각"을 잡는 측정 계층(timing-engine §4).
///
/// SwiftUI의 고수준 제스처(`TapGesture` 등)는 인식 지연·디바운스가 있어 타이밍 경로엔 쓰지 않는다.
/// 대신 `UIView.touchesBegan`에서 **그 터치의 하드웨어 이벤트 시각(`UITouch.timestamp`)**을 쓴다.
/// 이 값은 콜백이 실행되는 시각이 아니라 터치가 발생한 시각이라, 이벤트 큐→핸들러 디스패치 지연
/// (오차원 ④)을 배제한다. `CADisplayLink.timestamp`와 같은 단조 기준이라 온셋과 직접 뺄 수 있다(§2).
struct TouchCatcher: UIViewRepresentable {
    /// 첫 접촉(터치 다운)의 단조 이벤트 시각(초)을 전달한다. 릴리즈가 아니라 다운 순간이 응답이다(§4).
    var onTouchDown: (TimeInterval) -> Void

    func makeUIView(context: Context) -> TouchCatchingView {
        let view = TouchCatchingView()
        view.onTouchDown = onTouchDown
        return view
    }

    func updateUIView(_ view: TouchCatchingView, context: Context) {
        view.onTouchDown = onTouchDown
    }
}

/// 저수준 `touchesBegan`만 처리하는 최소 `UIView`. 제스처 인식기를 달지 않는다(측정 경로 오염 방지).
final class TouchCatchingView: UIView {
    var onTouchDown: ((TimeInterval) -> Void)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        onTouchDown?(touch.timestamp)
    }
}
