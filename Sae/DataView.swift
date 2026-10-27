import SwiftUI
import SwiftData

/// 이 기기의 데이터 — 저장된 기록의 수와, 전부 지우기(헌법 제3조).
///
/// 지우기 전에 확인을 받고, 무엇이 지워지고 무엇이 남는지(건강 앱 데이터는 그대로)를 먼저 말한다.
/// 되돌릴 수 없는 동작이라 버튼은 파괴적 역할(빨강)로 둔다.
struct DataView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var counts = MeasurementData.Counts()
    @State private var isConfirming = false
    @State private var didDelete = false
    @State private var didFail = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SaeTheme.Spacing.l) {
                SaeCard {
                    MetricRow(title: "data.sessions", value: "\(counts.sessions)")
                    MetricRow(title: "data.daily_scores", value: "\(counts.dailyScores)")
                    MetricRow(title: "data.hrv", value: "\(counts.hrvReadings)")
                    MetricRow(title: "data.tremor", value: "\(counts.tremorReadings)")
                    NoticeText(text: Text("data.note"))
                }

                Button(role: .destructive) {
                    isConfirming = true
                } label: {
                    Text("data.delete")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(SaeTheme.Palette.problem) // 시스템 빨강은 틴트 위 2.63:1

                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(counts.isEmpty)

                if didDelete {
                    NoticeText(text: Text("data.deleted"))
                }
                if didFail {
                    NoticeText(text: Text("data.delete_failed"), isProblem: true)
                }
            }
            .padding(SaeTheme.Spacing.l)
        }
        .background(SaeTheme.Palette.background)
        .navigationTitle("data.title")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            Text("data.confirm_title"),
            isPresented: $isConfirming,
            titleVisibility: .visible
        ) {
            Button(role: .destructive) { deleteAll() } label: { Text("data.confirm_delete") }
            Button(role: .cancel) {} label: { Text("data.confirm_cancel") }
        } message: {
            Text(String(format: String(localized: "data.confirm_message"), counts.sessions))
        }
        .task { refresh() }
    }

    private func refresh() {
        counts = (try? MeasurementData.counts(in: modelContext)) ?? MeasurementData.Counts()
    }

    private func deleteAll() {
        do {
            try MeasurementData.deleteAll(in: modelContext)
            didDelete = true
            didFail = false
        } catch {
            // 저장에 실패하면 메모리에 남은 삭제를 되돌린다 — "아무것도 바뀌지 않았다"는 안내가 사실이 되게.
            modelContext.rollback()
            didFail = true
        }
        refresh()
    }
}

#Preview {
    NavigationStack { DataView() }
        .modelContainer(for: [PVTSession.self, DailyScore.self, HRVReading.self, TremorReading.self], inMemory: true)
}
