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

    /// 차트가 지금 가리키는 x값. 손을 떼면 `nil`로 돌아간다.
    @State private var rawSelection: Date?
    /// 마지막으로 고른 날(자정). 손을 떼도 근거가 화면에 남도록 따로 들고 있는다.
    @State private var selectedDay: Date?

    var body: some View {
        let days = ScoreTrend.days(
            from: scores, day: \.day, endingOn: Date(), windowDays: windowDays, calendar: .current
        )

        ScrollView {
            VStack(alignment: .leading, spacing: SaeTheme.Spacing.l) {
                if days.contains(where: { $0.entry != nil }) {
                    SaeCard {
                        chart(days)
                        Divider()
                        selectionDetail(days)
                    }
                    NoticeText(text: Text("trend.gap_note"))
                } else {
                    SaeCard {
                        NoticeText(text: Text(String(format: String(localized: "trend.empty"), windowDays)))
                    }
                }
            }
            .padding(SaeTheme.Spacing.l)
        }
        .background(SaeTheme.Palette.background)
        .navigationTitle("trend.title")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            #if DEBUG
            // 개발 확인용: `-trendSelect N`으로 N일 전을 미리 골라 근거 표시를 확인한다(시뮬 자동화).
            let args = CommandLine.arguments
            if let i = args.firstIndex(of: "-trendSelect"), i + 1 < args.count, let daysAgo = Int(args[i + 1]) {
                selectedDay = Calendar.current.date(
                    byAdding: .day, value: -daysAgo, to: Calendar.current.startOfDay(for: Date())
                )
            }
            #endif
        }
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
                    .foregroundStyle(SaeTheme.Palette.brand)
                    PointMark(
                        x: .value("trend.axis_day", day.day, unit: .day),
                        y: .value("trend.axis_score", entry.score)
                    )
                    .foregroundStyle(SaeTheme.Palette.brand)
                }
            }
            if let selectedDay {
                RuleMark(x: .value("trend.axis_day", selectedDay, unit: .day))
                    .foregroundStyle(.secondary.opacity(0.4))
            }
        }
        .chartXSelection(value: $rawSelection)
        .onChange(of: rawSelection) { _, value in
            if let value { selectedDay = Calendar.current.startOfDay(for: value) }
        }
        .chartYScale(domain: 0...100)
        .chartXScale(domain: xDomain(days))
        .frame(height: 240)
    }

    /// 고른 날의 근거 — 점수만이 아니라 **그 점수를 만든 원지표**를 보인다(제2조 2항).
    ///
    /// 빈칸을 고르면 "유효한 측정 없음"이라고 말한다. 점수가 없는 날에 숫자를 보이지 않는다.
    @ViewBuilder
    private func selectionDetail(_ days: [TrendDay<DailyScore>]) -> some View {
        if let selectedDay, let day = days.first(where: { $0.day == selectedDay }) {
            let date = day.day.formatted(date: .abbreviated, time: .omitted)
            VStack(alignment: .leading, spacing: SaeTheme.Spacing.xs) {
                if let entry = day.entry {
                    Text(String(format: String(localized: "trend.day_score"), date, entry.score))
                        .font(SaeTheme.Typography.cardTitle.monospacedDigit())
                    Text(String(
                        format: String(localized: "score.evidence"), entry.lapseCount, entry.medianRTms
                    ))
                    .font(SaeTheme.Typography.metric)
                    .foregroundStyle(.secondary)
                } else {
                    Text(String(format: String(localized: "trend.no_measurement"), date))
                        .font(SaeTheme.Typography.metric)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            NoticeText(text: Text("trend.select_hint"))
        }
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
        .modelContainer(for: [PVTSession.self, DailyScore.self, HRVReading.self], inMemory: true)
}
