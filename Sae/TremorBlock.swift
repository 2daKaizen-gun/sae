import SwiftUI
import SwiftData
import SaeTiming

/// 손떨림 참고 블록 — 결과 화면에서 사용자가 시작하는 10초 측정(score-algorithm §3).
///
/// 점수 밖 정보라 HRV와 같은 테두리 블록에 담는다. 결과에는 **같은 기기끼리만 비교할 수 있다**는 말을 붙인다
/// — 기기 질량이 스펙트럼을 바꾼다(Santos et al. 2022, 제2조 3항). 센서가 없는 기기는 버튼 대신
/// "사용할 수 없음"을 바로 보인다.
struct TremorBlock: View {
    @Environment(\.modelContext) private var modelContext

    private enum Phase: Equatable {
        case idle
        case recording(progress: Double)
        case done(TremorRecorder.Outcome)
        case failed
    }

    @State private var phase: Phase = .idle
    /// 진행 중인 10초 기록. 화면이 사라지면 취소한다 — 끝까지 보지 않은 기록을 측정으로 남기지 않는다(#31).
    @State private var recording: Task<Void, Never>?

    var body: some View {
        ReferenceBlock(title: "tremor.title") {
            if !TremorRecorder.isAvailable {
                NoticeText(text: Text("tremor.unavailable"))
            } else {
                content
            }
        }
        // 취소되면 `TremorRecorder.record`의 대기가 `CancellationError`로 끝나고, 센서를 멈춘 뒤 저장 없이 빠져나온다.
        .onDisappear { recording?.cancel() }
    }

    // 보조 버튼 글자는 기본 레이블색 — 옅은 브랜드 틴트 바탕 위 브랜드색 글자는 AA 미달(3.88:1, #24).
    @ViewBuilder
    private var content: some View {
        switch phase {
        case .idle:
            NoticeText(text: Text("tremor.explain"))
            Button { start() } label: { Text("tremor.start").foregroundStyle(Color.primary) }
                .buttonStyle(.bordered)
        case .recording(let progress):
            let remaining = Int((TremorRecorder.recordingSeconds * (1 - progress)).rounded(.up))
            Text(String(format: String(localized: "tremor.recording"), remaining))
                .font(SaeTheme.Typography.metric)
            ProgressView(value: progress)
        case .done(.reading(let result)):
            Text(String(format: String(localized: "tremor.value"), result.bandRMS, result.peakFrequencyHz))
                .font(SaeTheme.Typography.metric)
            NoticeText(text: Text("tremor.same_device_note"))
        case .done(.unusable):
            NoticeText(text: Text("tremor.unusable"), isProblem: true)
            Button { start() } label: { Text("tremor.start").foregroundStyle(Color.primary) }
                .buttonStyle(.bordered)
        case .done(.unavailable):
            NoticeText(text: Text("tremor.unavailable"))
        case .failed:
            NoticeText(text: Text("tremor.failed"), isProblem: true)
        }
    }

    private func start() {
        phase = .recording(progress: 0)
        recording = Task {
            do {
                let outcome = try await TremorRecorder.record(in: modelContext) { value in
                    phase = .recording(progress: value)
                }
                phase = .done(outcome)
            } catch is CancellationError {
                phase = .idle // 사용자가 떠났다 — 실패가 아니다
            } catch {
                phase = .failed
            }
        }
    }
}
