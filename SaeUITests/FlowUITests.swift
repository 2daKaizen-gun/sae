import XCTest

/// 실제 탭으로 사용자 흐름을 지나간다 — 시뮬 합성 탭(CGEvent) 대신 정식 UI 테스트로.
///
/// 문구로 요소를 찾으므로 언어를 영어로 고정한다. 3언어 문구 자체는 String Catalog 검사가 맡는다.
final class FlowUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// 앱을 영어로, 주어진 DEBUG 인자와 함께 띄운다(인자는 README의 DEBUG launch arguments 표).
    static func launch(_ arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"] + arguments
        app.launch()
        return app
    }

    /// 첫 실행: 온보딩 → 시작하기 → 홈 → 측정하기 → 안내 화면.
    func testFirstRunOnboardingLeadsToTheInstructions() {
        let app = Self.launch(["-resetOnboarding"])

        XCTAssertTrue(app.staticTexts["What it is not"].waitForExistence(timeout: 5), "온보딩이 한계를 먼저 말한다")
        app.buttons["Get started"].tap()

        let measure = app.buttons["Measure"]
        XCTAssertTrue(measure.waitForExistence(timeout: 5), "온보딩을 닫으면 홈")
        measure.tap()

        XCTAssertTrue(app.buttons["Start"].waitForExistence(timeout: 5), "측정하기는 안내 화면을 연다")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS '12 rounds'")).firstMatch.exists,
                      "안내의 trial 수는 코드 값(12)")
    }

    /// 온보딩은 한 번만 — 닫은 뒤 다시 띄우면 홈이 바로 나온다.
    func testOnboardingIsShownOnlyOnce() {
        let first = Self.launch(["-resetOnboarding"])
        XCTAssertTrue(first.buttons["Get started"].waitForExistence(timeout: 5))
        first.buttons["Get started"].tap()
        first.terminate()

        let again = Self.launch()
        XCTAssertTrue(again.buttons["Measure"].waitForExistence(timeout: 5))
        XCTAssertFalse(again.buttons["Get started"].exists)
    }
}
