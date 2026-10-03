#if DEBUG
import Foundation
import SwiftData
import SaeTiming

/// 화면 검증용 데모 데이터 — **DEBUG 빌드에서, 데모 실행 인자가 있을 때만** 쓴다.
///
/// - `-trendDemo`: 데모 저장소 + 추이 화면으로 바로 진입
/// - `-homeDemo`: 데모 저장소 + 홈(오늘 점수가 있는 상태)
/// - `-resultDemo`: 데모 저장소 + 유효 세션의 결과 화면(`-demoLapses N`·`-demoInvalid`·`-demoNoHistory`로 조절)
///
/// 여러 날의 기록이나 12번을 제때 누른 유효 세션은 실제로 만들기 어렵다. 그래서 시뮬레이터에서
/// 화면을 확인하려면 데이터를 만들어야 한다. 대신 두 가지를 지킨다:
/// 1. **메모리에만 둔다.** 기기의 실제 저장소(`default.store`)에는 한 줄도 쓰지 않는다.
/// 2. 점수를 손으로 적지 않는다. 가짜 trial로 세션 요약을 만들고 **실제 `SaeScorer`로 계산**해,
///    화면의 점수와 근거(lapse·중앙값)가 서로 맞게 한다. 릴리스 빌드에는 이 파일이 없다.
enum DemoData {
    private static let arguments = ["-trendDemo", "-homeDemo", "-resultDemo"]

    /// 데모 저장소를 쓸지.
    static var isRequested: Bool { arguments.contains(where: CommandLine.arguments.contains) }
    static var opensTrend: Bool { CommandLine.arguments.contains("-trendDemo") }
    static var opensResult: Bool { CommandLine.arguments.contains("-resultDemo") }

    /// 오늘부터 며칠 전인지 · lapse 수 · 가장 빠른 RT(ms). 빠진 날(2, 5, 6, 10일 전)은 빈칸이다.
    private static let days: [(daysAgo: Int, lapses: Int, fastestMs: Double)] = [
        (13, 1, 250), (12, 0, 240), (11, 2, 270), (9, 3, 290), (8, 1, 260),
        (7, 0, 235), (4, 4, 300), (3, 2, 275), (1, 1, 255), (0, 0, 245),
    ]

    /// 한 번만 만든다 — `App.body`가 다시 평가될 때마다 새 저장소가 생기면 데이터가 초기화된다.
    @MainActor static let container: ModelContainer = makeContainer()

    @MainActor
    private static func makeContainer() -> ModelContainer {
        let container = try! ModelContainer(
            for: PVTSession.self, DailyScore.self, HRVReading.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let today = Calendar.current.startOfDay(for: Date())

        // `-demoNoHistory`: 기록 없는 상태(첫 측정 대사 확인용).
        let specs = CommandLine.arguments.contains("-demoNoHistory") ? [] : days
        for spec in specs {
            // 12 trial: 응답은 가장 빠른 값에서 8ms씩 늘어나고, lapse는 500ms를 넘긴다.
            let responses = (0..<(12 - spec.lapses)).map { TrialOutcome.valid(reactionTimeMs: spec.fastestMs + Double($0) * 8) }
            let lapses = (0..<spec.lapses).map { TrialOutcome.lapse(reactionTimeMs: 560 + Double($0) * 40) }
            let summary = PVTSessionSummary.make(from: responses + lapses)
            guard let sae = SaeScorer.score(from: summary, validity: SessionValidator.evaluate(summary)),
                  let day = Calendar.current.date(byAdding: .day, value: -spec.daysAgo, to: today)
            else { continue }

            context.insert(DailyScore(
                day: day,
                score: sae.score,
                arousalComponent: sae.arousal.score,
                lapseCount: sae.evidence.lapseCount,
                respondedCount: sae.evidence.respondedCount,
                medianRTms: sae.evidence.medianRTms,
                fastest10PctMeanRTms: sae.evidence.fastest10PctMeanRTms,
                falseStartCount: sae.evidence.falseStartCount
            ))
        }
        return container
    }

    /// 유효한 12-trial 세션 결과 — 결과 화면 확인용. 판정·요약·타당도는 **실제 코어**가 낸다.
    ///
    /// `-demoLapses N`으로 랩스 수(0~12)를, `-demoInvalid`로 무효 세션을 만든다 — 대사 밴드별 화면 확인용.
    static func sampleResult() -> PVTSessionResult {
        let args = CommandLine.arguments
        let lapses = args.firstIndex(of: "-demoLapses").flatMap { i in
            i + 1 < args.count ? Int(args[i + 1]) : nil
        }.map { min(max($0, 0), 12) } ?? 1
        let responses = args.contains("-demoInvalid") ? 3 - min(lapses, 3) : 12 - lapses
        let outcomes = (0..<responses).map { TrialOutcome.valid(reactionTimeMs: 255 + Double($0) * 9) }
            + (0..<lapses).map { TrialOutcome.lapse(reactionTimeMs: 540 + Double($0) * 30) }
        let summary = PVTSessionSummary.make(from: outcomes)
        return PVTSessionResult(
            startedAt: Date(),
            startTime: 0,
            endTime: 78,
            displayRefreshHz: 60,
            calibrationOffsetMs: 0,
            trials: [],
            summary: summary,
            validity: SessionValidator.evaluate(summary)
        )
    }
}
#endif
