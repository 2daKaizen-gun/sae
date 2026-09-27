import Foundation
import Testing
@testable import SaeTiming

/// 일별 추이 펼치기 검증 — 창 경계·빈칸·같은 날 중복·구간 분리.
struct ScoreTrendTests {
    private struct Entry: Equatable {
        let day: Date
        let score: Int
    }

    /// 서머타임이 없는 고정 시간대 — 날짜 경계가 실행 환경에 따라 흔들리지 않게 한다.
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return calendar
    }()

    private func date(_ day: Int, hour: Int = 9) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour))!
    }

    private func trend(_ entries: [Entry], today: Int = 14, window: Int = 7) -> [TrendDay<Entry>] {
        ScoreTrend.days(
            from: entries, day: \.day, endingOn: date(today), windowDays: window, calendar: calendar
        )
    }

    @Test func coversEveryDayOfTheWindowEndingToday() {
        let days = trend([], today: 14, window: 7)
        #expect(days.count == 7)
        #expect(days.first?.day == calendar.startOfDay(for: date(8)))
        #expect(days.last?.day == calendar.startOfDay(for: date(14)))
        #expect(days.allSatisfy { $0.entry == nil && $0.segment == nil })
    }

    /// 기록 없는 날은 0점도 보간값도 아닌 **빈칸**이다(제2조).
    @Test func keepsMissingDaysAsGaps() {
        let days = trend([Entry(day: date(10), score: 60), Entry(day: date(12), score: 80)])
        #expect(days.map { $0.entry?.score } == [nil, nil, 60, nil, 80, nil, nil])
    }

    @Test func dropsEntriesOutsideTheWindow() {
        let days = trend([
            Entry(day: date(7), score: 10),  // 창 시작 전날
            Entry(day: date(8), score: 20),  // 창 첫날(포함)
            Entry(day: date(14, hour: 23), score: 30), // 오늘 밤(포함)
            Entry(day: date(15, hour: 0), score: 40),  // 내일 자정
        ])
        #expect(days.compactMap { $0.entry?.score } == [20, 30])
    }

    /// 같은 날 둘이면 입력에서 나중 것이 그날을 차지한다.
    @Test func laterEntryWinsOnTheSameDay() {
        let days = trend([Entry(day: date(11, hour: 8), score: 50), Entry(day: date(11, hour: 20), score: 70)])
        #expect(days.compactMap { $0.entry?.score } == [70])
    }

    /// 빈칸을 사이에 두면 구간 번호가 바뀐다 — 차트가 빈칸 위로 선을 잇지 않게 하는 근거.
    @Test func splitsSegmentsAtGaps() {
        let days = trend([
            Entry(day: date(8), score: 1), Entry(day: date(9), score: 2),
            Entry(day: date(11), score: 3),
            Entry(day: date(13), score: 4), Entry(day: date(14), score: 5),
        ])
        #expect(days.map(\.segment) == [0, 0, nil, 1, nil, 2, 2])
    }

    @Test func singleDayWindowHoldsOnlyToday() {
        let days = trend([Entry(day: date(14), score: 90), Entry(day: date(13), score: 10)], window: 1)
        #expect(days.map { $0.entry?.score } == [90])
        #expect(days.first?.segment == 0)
    }
}
