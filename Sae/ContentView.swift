import SwiftUI
import SwiftData

/// 앱 내 이동 목적지.
enum Route: Hashable {
    case timingLab
    case trend
}

/// 홈 — 오늘의 冴え度(또는 아직 재지 않았다는 사실)와, 측정·추이로 가는 입구.
///
/// 오늘 점수는 `DailyScore`의 오늘 행, 즉 **그날의 마지막 유효 측정**이다(data-model). 없으면
/// 숫자 대신 "아직 측정하지 않았다"고 말한다 — 어제 점수를 오늘처럼 보이지 않는다(제2조).
///
/// 측정 버튼은 아직 엔진 계측 화면(타이밍 랩)으로 간다. 사용자용 측정 흐름은 온보딩과 함께
/// 4주차 몫이라(`CONCEPT.md` §7), 그 사실을 화면에서 숨기지 않는다.
struct ContentView: View {
    @State private var path: [Route] = []
    @Query(sort: \DailyScore.day, order: .reverse) private var scores: [DailyScore]

    /// 오늘 날짜의 점수. `DailyScore.day`는 자정으로 저장된다.
    private var today: DailyScore? {
        let start = Calendar.current.startOfDay(for: Date())
        return scores.first { $0.day == start }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: SaeTheme.Spacing.l) {
                    header
                    todayCard
                    actions
                }
                .padding(SaeTheme.Spacing.l)
            }
            .background(SaeTheme.Palette.background)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .timingLab: TimingLabView()
                case .trend: TrendView()
                }
            }
        }
        .onAppear {
            #if DEBUG
            // 개발 확인용 실행 인자(시뮬 자동화). `-autolab`: 타이밍 랩에 바로 진입.
            if CommandLine.arguments.contains("-autolab") { path = [.timingLab] }
            // `-trendDemo`: 메모리 전용 데모 데이터로 추이 화면에 바로 진입(SaeApp·TrendDemo).
            if TrendDemo.isRequested { path = [.trend] }
            #endif
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: SaeTheme.Spacing.xs) {
            Text("app.title")
                .font(.largeTitle.bold())
            Text("app.tagline")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var todayCard: some View {
        if let today {
            ScoreCard(score: today.score) {
                MetricRow(title: "result.lapses", value: "\(today.lapseCount)")
                MetricRow(
                    title: "result.median",
                    value: "\(today.medianRTms.formatted(.number.precision(.fractionLength(0)))) ms"
                )
                NoticeText(text: Text("home.today_note"))
            }
        } else {
            SaeCard {
                Text("home.not_measured")
                    .font(SaeTheme.Typography.cardTitle)
                NoticeText(text: Text("home.not_measured_note"))
            }
        }
    }

    private var actions: some View {
        VStack(alignment: .leading, spacing: SaeTheme.Spacing.m) {
            NavigationLink(value: Route.timingLab) {
                Text("home.measure")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            NavigationLink(value: Route.trend) {
                Text("trend.link")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            NoticeText(text: Text("home.lab_note"))
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PVTSession.self, DailyScore.self, HRVReading.self], inMemory: true)
}
