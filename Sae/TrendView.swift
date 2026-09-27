import SwiftUI
import SwiftData
import Charts
import SaeTiming

/// 冴え度 일별 추이 — 저장된 `DailyScore`를 최근 14일 창에 그린다.
///
/// 유효한 측정이 없던 날은 **빈칸으로 둔다.** 0점으로 채우면 "못 잰 날"이 "나쁜 날"이 되고,
/// 앞뒤를 선으로 이으면 재지 않은 값을 그리는 셈이 된다(제2조 1항). 그래서 선은
/// `ScoreTrend`가 매긴 **구간 번호 안에서만** 이어지고, 빈칸 위로는 건너가지 않는다.
///
/// 저장된 점수만 읽는다 — 타이밍 경로와 무관하다(제1조).
struct TrendView: View {
    @Query(sort: \DailyScore.day) private var scores: [DailyScore]

    private let windowDays = ScoreTrend.defaultWindowDays

    var body: some View {
        let days = ScoreTrend.days(
            from: scores, day: \.day, endingOn: Date(), windowDays: windowDays, calendar: .current
        )

        VStack(alignment: .leading, spacing: 12) {
            if days.contains(where: { $0.entry != nil }) {
                chart(days)
                Text("trend.gap_note")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(String(format: String(localized: "trend.empty"), windowDays))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("trend.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// 점수 있는 날만 표시한다. 빈칸은 마크가 없다는 것 자체로 드러난다.
    private func chart(_ days: [TrendDay<DailyScore>]) -> some View {
        Chart {
            ForEach(days, id: \.day) { day in
                if let entry = day.entry, let segment = day.segment {
                    LineMark(
                        x: .value("trend.axis_day", day.day, unit: .day),
                        y: .value("trend.axis_score", entry.score),
                        // 같은 구간끼리만 선을 잇는다 — 빈칸을 건너 이어 그리지 않는다.
                        series: .value("segment", segment)
                    )
                    PointMark(
                        x: .value("trend.axis_day", day.day, unit: .day),
                        y: .value("trend.axis_score", entry.score)
                    )
                }
            }
        }
        .chartYScale(domain: 0...100)
        .chartXScale(domain: xDomain(days))
        .frame(height: 240)
    }

    /// 창 전체를 x축에 고정한다. 데이터가 있는 날만으로 축을 잡으면 빈칸이 축 밖으로 사라진다.
    private func xDomain(_ days: [TrendDay<DailyScore>]) -> ClosedRange<Date> {
        let first = days.first?.day ?? Date()
        let last = days.last?.day ?? first
        let end = Calendar.current.date(byAdding: .day, value: 1, to: last) ?? last
        return first...end
    }
}

#Preview {
    NavigationStack { TrendView() }
        .modelContainer(for: [PVTSession.self, DailyScore.self], inMemory: true)
}
