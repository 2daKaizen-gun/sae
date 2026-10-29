import Accessibility
import Foundation
import SwiftData
import Testing
import SaeTiming
@testable import Sae

/// 오디오 그래프 데이터 — 화면과 같은 점, 빈 날은 0이 아니라 요약 문장으로.
@MainActor
struct TrendChartDescriptorTests {
    let container: ModelContainer

    init() throws {
        container = try ModelContainer(
            for: PVTSession.self, DailyScore.self, HRVReading.self, TremorReading.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func score(_ value: Int, daysAgo: Int) -> DailyScore {
        let day = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Calendar.current.startOfDay(for: Date()))!
        let s = DailyScore(day: day, score: value, arousalComponent: Double(value), lapseCount: 0,
                           respondedCount: 12, medianRTms: 300, fastest10PctMeanRTms: 260, falseStartCount: 0)
        container.mainContext.insert(s)
        return s
    }

    @Test func plotsOnlyScoredDaysAndStatesTheGaps() throws {
        let scores = [score(70, daysAgo: 0), score(55, daysAgo: 3), score(90, daysAgo: 4)]
        let days = ScoreTrend.days(from: scores, day: \.day, endingOn: Date(), windowDays: 14, calendar: .current)

        let chart = TrendChartDescriptor(days: days).makeChartDescriptor()
        let points = try #require(chart.series.first).dataPoints

        // Objective-C의 AXDataPointValue.number는 Swift에서 `__number`로 보인다(NS_REFINED_FOR_SWIFT).
        let values = points.compactMap { $0.yValue?.__number }
        #expect(points.count == 3, "빈 날은 데이터 점이 아니다")
        #expect(values == [90, 55, 70], "날짜 순, 화면과 같은 값")
        #expect(!values.contains(0), "0으로 채우지 않는다")
        #expect(chart.summary?.contains("3") == true && chart.summary?.contains("14") == true)
        let y = try #require(chart.yAxis as? AXNumericDataAxisDescriptor)
        #expect(y.range == 0...100)
    }
}
