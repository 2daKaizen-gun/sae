import SwiftUI

/// 자극 패드 — PVT 자극을 보여주고 응답 터치를 받는 **유일한** 뷰. 타이밍 랩과 테스트 화면이 함께 쓴다.
///
/// 측정에 직접 닿는 뷰라 구현을 한 벌만 둔다. 두 화면이 각자 그리면 한쪽만 바뀌어도 "검증한 화면"과
/// "사용자가 쓰는 화면"의 측정 조건이 갈라진다(제1조 3항).
///
/// 표시는 **색 플래그 토글 하나**뿐이고, 탭은 저수준 경로(`TouchCatcher`)로 받는다.
/// 애니메이션을 명시적으로 끈다(`animation(nil)`): 페이드·스케일이 끼면 "자극이 켜진 시각"이
/// 흐려져 온셋 기준이 무너진다(제1조 1항, timing-engine §6). 레이아웃도 바뀌지 않게
/// 크기를 고정해, 자극 프레임에서 레이아웃 패스가 돌지 않도록 한다.
struct StimulusPad: View {
    /// 자극이 켜져 있는가 — `PVTSessionRunner.isStimulusVisible`.
    let isStimulusVisible: Bool
    /// 고정 높이(pt). 화면마다 크기는 달라도 **한 세션 안에서는 바뀌지 않는다.**
    let height: CGFloat
    /// 터치 다운 한 건 — 응답 시각은 `UITouch.timestamp`(timing-engine §4).
    let onTouchDown: (TouchSample) -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(isStimulusVisible ? Color.green : Color.gray.opacity(0.15))
            .frame(height: height)
            .animation(nil, value: isStimulusVisible)
            .overlay {
                Text(isStimulusVisible ? "stimulus.tap" : "stimulus.wait")
                    .font(.title3.bold())
                    .foregroundStyle(isStimulusVisible ? Color.white : Color.secondary)
                    .animation(nil, value: isStimulusVisible)
            }
            .overlay {
                TouchCatcher(onTouchDown: onTouchDown)
                    .accessibilityIdentifier("touchCatcher")
            }
    }
}
