import Foundation
import Testing
@testable import Sae

/// 홈의 "오늘 점수" 규칙 — 오늘 저장된 점수를 찾고, 어제 점수를 오늘처럼 보이지 않는다(제2조).
struct TodaysScoreRuleTests {
    private static func calendar(_ identifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier)!
        return calendar
    }

    /// 앱이 저장하듯, 그 시간대의 자정을 하루 키로 둔 점수.
    private static func score(day: Date, in calendar: Calendar) -> DailyScore {
        DailyScore(
            day: calendar.startOfDay(for: day), score: 70, arousalComponent: 70,
            lapseCount: 1, respondedCount: 12, medianRTms: 300, fastest10PctMeanRTms: 240, falseStartCount: 0
        )
    }

    private let tokyo = calendar("Asia/Tokyo")
    private let losAngeles = calendar("America/Los_Angeles")
    /// 2027-01-15 12:00 UTC — 도쿄 21:00, LA 04:00. 두 도시 모두 1월 15일.
    private let now = Date(timeIntervalSince1970: 1_800_014_400)

    @Test func findsTodaysScore() {
        let today = Self.score(day: now, in: tokyo)
        #expect(ContentView.todaysScore(in: [today], now: now, calendar: tokyo) === today)
    }

    @Test func yesterdaysScoreIsNotToday() {
        let yesterday = Self.score(day: now.addingTimeInterval(-86_400), in: tokyo)
        #expect(ContentView.todaysScore(in: [yesterday], now: now, calendar: tokyo) == nil)
    }

    /// LA에서 잰 오늘 점수(키 = LA 자정 = 도쿄 같은 날 17:00)를 도쿄로 옮긴 뒤에도 오늘 점수로 찾는다.
    /// 정확히 같은 `Date`로 찾던 이전 규칙은 여기서 점수를 잃었다(#31).
    @Test func survivesMovingEastAfterMeasuring() {
        let measuredInLA = Self.score(day: now, in: losAngeles)
        #expect(measuredInLA.day != tokyo.startOfDay(for: now)) // 키가 도쿄 자정과 다르다 — 옛 규칙이 실패하던 조건
        #expect(ContentView.todaysScore(in: [measuredInLA], now: now, calendar: tokyo) === measuredInLA)
    }
}
