import SwiftUI
import SwiftData

/// 앱 내 이동 목적지.
enum Route: Hashable {
    case timingLab
    case trend
    case testIntro
    case test
}

/// 홈 — 오늘의 冴え度(또는 아직 재지 않았다는 사실)와, 측정·추이로 가는 입구.
///
/// 오늘 점수는 `DailyScore`의 오늘 행, 즉 **그날의 마지막 유효 측정**이다(data-model). 없으면
/// 숫자 대신 "아직 측정하지 않았다"고 말한다 — 어제 점수를 오늘처럼 보이지 않는다(제2조).
///
/// 측정 버튼은 안내 → 테스트 → 결과로 이어지는 사용자용 흐름을 연다. 엔진 계측 화면(타이밍 랩)은
/// 개발용이라 **DEBUG 빌드에서만** 입구를 보인다.
struct ContentView: View {
    @State private var path: [Route] = []
    /// 첫 실행 안내를 마쳤는가. 한 번 보면 다시 뜨지 않는다.
    @AppStorage("onboarding.completed") private var onboardingCompleted = false
    #if DEBUG
    /// `-resultDemo`로 띄우는 결과 화면(DemoData).
    @State private var isShowingDemoResult = false
    #endif
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
                case .testIntro: TestIntroView(onStart: { path.append(.test) })
                case .test: TestView(onDone: { path = [] })
                }
            }
        }
        // 첫 실행에만 뜬다. 개발용 자동 진입 인자로 띄운 실행에서는 가리지 않는다(시뮬 자동화).
        .fullScreenCover(isPresented: Binding(
            get: { !onboardingCompleted && !Self.isDevLaunch },
            set: { if !$0 { onboardingCompleted = true } }
        )) {
            OnboardingView { onboardingCompleted = true }
        }
        .onAppear {
            #if DEBUG
            // `-resetOnboarding`: 첫 실행 안내를 다시 보이게 한다.
            if CommandLine.arguments.contains("-resetOnboarding") { onboardingCompleted = false }
            // 개발 확인용 실행 인자(시뮬 자동화). `-autolab`: 타이밍 랩에 바로 진입.
            if CommandLine.arguments.contains("-autolab") { path = [.timingLab] }
            // `-autotest`: 사용자용 테스트 화면에 바로 진입.
            if CommandLine.arguments.contains("-autotest") { path = [.test] }
            // `-autointro`: 테스트 안내 화면에 바로 진입.
            if CommandLine.arguments.contains("-autointro") { path = [.testIntro] }
            // 데모 인자(`DemoData`): 메모리 전용 데모 데이터로 추이 또는 결과 화면을 바로 연다.
            if DemoData.opensTrend { path = [.trend] }
            if DemoData.opensResult { isShowingDemoResult = true }
            #endif
        }
        #if DEBUG
        .sheet(isPresented: $isShowingDemoResult) {
            NavigationStack { ResultView(result: DemoData.sampleResult()) }
        }
        #endif
    }

    /// 개발용 자동 진입 인자로 띄운 실행인가(DEBUG 전용). 릴리스에서는 항상 `false`.
    private static var isDevLaunch: Bool {
        #if DEBUG
        let devArguments = ["-autolab", "-autotest", "-autointro"]
        return DemoData.isRequested || devArguments.contains(where: CommandLine.arguments.contains)
        #else
        return false
        #endif
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
            NavigationLink(value: Route.testIntro) {
                Text("home.measure")
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(SaeTheme.Palette.onBrand)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            NavigationLink(value: Route.trend) {
                Text("trend.link")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            #if DEBUG
            NavigationLink(value: Route.timingLab) {
                Text("home.lab_link")
            }
            .font(SaeTheme.Typography.notice)
            #endif
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PVTSession.self, DailyScore.self, HRVReading.self], inMemory: true)
}
