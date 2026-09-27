import Foundation

/// 추이의 하루 칸 — 그날의 기록이 있으면 담고, 없으면 **빈칸으로 남긴다.**
///
/// 기록 없는 날을 0점으로 채우거나 앞뒤 값으로 보간하면 "못 잰 날"이 없는 숫자로 바뀐다
/// (제2조 1항). 그래서 빈칸은 값이 아니라 `entry == nil`이라는 **사실**로 표현한다.
public struct TrendDay<Entry> {
    /// 그날의 시작 시각(달력 기준 자정).
    public let day: Date
    /// 그날의 기록. 측정하지 않았거나 무효였던 날은 `nil`.
    public let entry: Entry?
    /// 기록이 이어지는 구간의 번호. 빈칸을 사이에 둔 두 구간은 번호가 다르다 — 차트는 같은
    /// 번호끼리만 선을 이어, 빈칸 위로 선이 **건너가지 않게** 한다. 빈칸 자신은 `nil`.
    public let segment: Int?
}

extension TrendDay: Equatable where Entry: Equatable {}

/// 일별 점수 추이 — 저장된 기록을 **연속된 달력 날짜 칸**으로 펼친다(순수 함수).
///
/// 입력은 날짜가 띄엄띄엄한 기록 목록이고, 출력은 창(window) 안의 모든 날짜를 빠짐없이 담은
/// 칸 목록이다. 이 변환을 순수하게 분리해 두면 경계(창 끝, 빈칸, 같은 날 중복)를 차트 없이
/// `swift test`로 증명할 수 있다. 타이밍 경로와는 무관하다 — 저장된 점수만 읽는다(제1조).
public enum ScoreTrend {
    /// 기본 창 길이 14일 — 주중·주말이 두 번씩 들어가 요일 영향과 추세를 함께 볼 수 있는 폭.
    /// 튜닝 대상이며 근거 있는 값이 아니라 표시상의 선택이다(제2조 1항).
    public static let defaultWindowDays = 14

    /// 기록들을 `today`로 끝나는 `windowDays`일 칸으로 펼친다(오래된 날 → 오늘 순).
    ///
    /// - Parameters:
    ///   - entries: 기록 목록. 순서는 상관없다.
    ///   - day: 기록이 속한 날짜를 꺼내는 함수. 값은 `calendar`의 자정으로 다시 맞춘다.
    ///   - today: 창의 마지막 날(이 날을 포함한다).
    ///   - windowDays: 창 길이(일). 1 이상.
    ///   - calendar: 날짜 경계를 정하는 달력(시간대 포함). 테스트에서는 고정 시간대를 넣는다.
    /// - Returns: 정확히 `windowDays`개의 칸. 창 밖의 기록은 버린다.
    ///
    /// 같은 날에 기록이 둘 이상이면 **입력에서 나중 것**이 그날을 차지한다. 저장 계층은 하루에
    /// 하나만 두므로(data-model `DailyScore`) 정상적으로는 일어나지 않는 경우이고, 방어적으로
    /// 규칙만 고정해 둔다.
    public static func days<Entry>(
        from entries: [Entry],
        day: (Entry) -> Date,
        endingOn today: Date,
        windowDays: Int = defaultWindowDays,
        calendar: Calendar
    ) -> [TrendDay<Entry>] {
        precondition(windowDays >= 1, "창 길이는 1일 이상이어야 한다")

        let lastDay = calendar.startOfDay(for: today)
        guard let firstDay = calendar.date(byAdding: .day, value: -(windowDays - 1), to: lastDay) else {
            return []
        }

        var byDay: [Date: Entry] = [:]
        for entry in entries {
            let key = calendar.startOfDay(for: day(entry))
            guard key >= firstDay, key <= lastDay else { continue }
            byDay[key] = entry
        }

        var result: [TrendDay<Entry>] = []
        var segment = -1
        var previousHadEntry = false
        for offset in 0..<windowDays {
            guard let date = calendar.date(byAdding: .day, value: offset, to: firstDay) else { continue }
            let entry = byDay[date]
            if entry != nil, !previousHadEntry { segment += 1 }
            previousHadEntry = entry != nil
            result.append(TrendDay(day: date, entry: entry, segment: entry == nil ? nil : segment))
        }
        return result
    }
}
