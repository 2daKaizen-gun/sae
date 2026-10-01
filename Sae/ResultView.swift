import SwiftUI
import SwiftData
import SaeTiming

/// 세션 결과 화면 — 측정이 **끝난 뒤** 시트로 뜬다.
///
/// 이 화면이 뜰 때 `CADisplayLink`는 이미 멈춰 있다(`PVTSessionRunner.finishSession`). 그래서 시트
/// 애니메이션·레이아웃이 측정을 오염시킬 수 없다(제1조 1항).
///
/// 보여주는 순서가 곧 설명 순서다: 점수 → 그 점수를 만든 원지표 → 빠진 신호 → 점수 밖의 참고 지표.
/// 무효 세션이면 점수 자리에 **점수가 없다는 사실과 이유**를 둔다(제2조 — 가짜 숫자보다 빈칸).
struct ResultView: View {
    let result: PVTSessionResult
    /// "완료"를 누르면 할 일. 없으면 이 화면을 닫는다(시트로 뜬 경우).
    var onDone: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    /// 건강 앱 접근을 한 번 요청했는가. 요청 전에는 이유와 버튼만 보인다(제3조 3항).
    @AppStorage("hrv.accessRequested") private var hrvAccessRequested = false
    @State private var hrvOutcome: HealthKitHRV.Outcome?
    @State private var didHRVFail = false

    var body: some View {
        ScrollView {
            VStack(spacing: SaeTheme.Spacing.l) {
                scoreSection
                hrvSection
            }
            .padding(SaeTheme.Spacing.l)
        }
        .background(SaeTheme.Palette.background)
        .navigationTitle("result.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button { if let onDone { onDone() } else { dismiss() } } label: { Text("result.done") }
            }
        }
        // 이미 동의를 구한 사용자에게만 자동으로 읽는다. 측정은 이미 끝났다.
        .task { if hrvAccessRequested { await readHRV() } }
    }

    // MARK: 점수

    @ViewBuilder
    private var scoreSection: some View {
        if let sae = SaeScorer.score(from: result.summary, validity: result.validity) {
            ScoreCard(score: sae.score) {
                MetricRow(title: "result.arousal", value: sae.arousal.score.formatted(.number.precision(.fractionLength(1))))
                Divider()
                MetricRow(title: "result.lapses", value: "\(sae.evidence.lapseCount)")
                MetricRow(title: "result.median", value: milliseconds(sae.evidence.medianRTms))
                MetricRow(title: "result.fastest", value: milliseconds(sae.evidence.fastest10PctMeanRTms))
                MetricRow(title: "result.false_starts", value: "\(sae.evidence.falseStartCount)")
                // 결측 신호를 숨기지 않는다 — MVP 점수는 PVT 단독이다(제2조 3항).
                NoticeText(text: Text("score.missing_signals"))
            }
        } else {
            SaeCard {
                Text("score.unavailable")
                    .font(SaeTheme.Typography.cardTitle)
                NoticeText(text: Text(result.validity.localizedDescription), isProblem: true)
            }
        }
    }

    private func milliseconds(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(0)))) ms"
    }

    // MARK: HRV (참고 지표 — 점수 밖)

    private var hrvSection: some View {
        ReferenceBlock(title: "hrv.title") {
            if !hrvAccessRequested {
                NoticeText(text: Text("hrv.explain"))
                Button {
                    Task {
                        do {
                            try await HealthKitHRV.requestReadAccess()
                            hrvAccessRequested = true
                            await readHRV()
                        } catch {
                            didHRVFail = true
                        }
                    }
                } label: {
                    Text("hrv.read_button")
                }
                .buttonStyle(.bordered)
            } else if didHRVFail {
                NoticeText(text: Text("hrv.failed"), isProblem: true)
            } else if let hrvOutcome {
                switch hrvOutcome {
                case .unavailable:
                    NoticeText(text: Text("hrv.unavailable"))
                case .none:
                    NoticeText(text: Text("hrv.none"))
                case .reading(let sample):
                    Text(String(
                        format: String(localized: "hrv.value"),
                        sample.sdnnMs,
                        sample.measuredAt.formatted(date: .abbreviated, time: .shortened)
                    ))
                    .font(SaeTheme.Typography.metric)
                }
            }
        }
    }

    private func readHRV() async {
        do {
            hrvOutcome = try await HealthKitHRV.refresh(in: modelContext)
            didHRVFail = false
        } catch {
            didHRVFail = true
        }
    }
}
