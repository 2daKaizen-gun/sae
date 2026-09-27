#if DEBUG
import Foundation
import SwiftData
import SaeTiming

/// 추이 화면 검증용 데모 데이터 — **DEBUG 빌드에서, `-trendDemo` 실행 인자가 있을 때만** 쓴다.
///
/// 여러 날의 기록은 실제로 며칠을 측정해야 생기므로, 시뮬레이터에서 빈칸·구간 분리·선택을
/// 확인하려면 데이터를 만들어야 한다. 대신 두 가지를 지킨다:
/// 1. **메모리에만 둔다.** 기기의 실제 저장소(`default.store`)에는 한 줄도 쓰지 않는다.
/// 2. 점수를 손으로 적지 않는다. 가짜 trial로 세션 요약을 만들고 **실제 `SaeScorer`로 계산**해,
///    화면의 점수와 근거(lapse·중앙값)가 서로 맞게 한다. 릴리스 빌드에는 이 파일이 없다.
enum TrendDemo {
    static var isRequested: Bool { CommandLine.arguments.contains("-trendDemo") }

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
            for: PVTSession.self, DailyScore.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let today = Calendar.current.startOfDay(for: Date())

        for spec in days {
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
}
#endif
