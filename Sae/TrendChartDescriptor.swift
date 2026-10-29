import Accessibility
import SwiftUI
import Foundation
import SaeTiming

/// 추이 차트의 VoiceOver 오디오 그래프 — 화면의 선과 **같은 데이터**를 소리 그래프로 들려준다.
///
/// 점수가 있는 날만 데이터 점으로 넣는다. 빈 날을 0으로 채우면 소리로도 "나쁜 날"이 되어 버리므로(제2조),
/// 대신 요약에 "14일 중 N일에 유효한 점수"라고 말해 빈 날이 있다는 사실을 전한다.
struct TrendChartDescriptor: AXChartDescriptorRepresentable {
    let days: [TrendDay<DailyScore>]

    func makeChartDescriptor() -> AXChartDescriptor {
        let scored = days.compactMap { day in day.entry.map { (day.day, $0.score) } }
        let dateLabels = scored.map { $0.0.formatted(date: .abbreviated, time: .omitted) }

        let xAxis = AXCategoricalDataAxisDescriptor(
            title: String(localized: "trend.axis_day"),
            categoryOrder: dateLabels
        )
        let yAxis = AXNumericDataAxisDescriptor(
            title: String(localized: "trend.axis_score"),
            range: 0...100,
            gridlinePositions: [0, 25, 50, 75, 100]
        ) { value in "\(Int(value))" }

        let series = AXDataSeriesDescriptor(
            name: String(localized: "trend.axis_score"),
            isContinuous: false,
            dataPoints: zip(dateLabels, scored).map { label, point in
                AXDataPoint(x: label, y: Double(point.1))
            }
        )

        return AXChartDescriptor(
            title: String(format: String(localized: "trend.chart_label"), days.count),
            summary: String(format: String(localized: "trend.chart_summary"), scored.count, days.count),
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: [series]
        )
    }
}
