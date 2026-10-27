import XCTest

/// 측정 → 점수 → 저장 → 홈 — 실제 흐름 전체를 한 번에 지나간다.
///
/// 메모리 전용 빈 저장소(`-homeDemo -demoNoHistory`)에서 시작해 이전 실행의 상태에 기대지 않고, 기기의 실제
/// 기록을 남기지 않는다. 자극은 진짜 `PVTSessionRunner`가 띄우고, 테스트는 패드에 "TAP!"이 뜨면 누른다 —
/// 측정 엔진은 그대로이고, 사람 대신 UI 테스트가 반응할 뿐이다. UI 테스트의 반응은 사람보다 느릴 수 있으므로
/// **점수 값은 검사하지 않는다**(낮게 나올 수 있다). 검사하는 것은 "유효한 세션이 점수가 되어 저장되고 홈에
/// 오늘 점수로 보인다"는 흐름이다.
final class EndToEndSessionUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testAValidSessionBecomesTodaysScore() {
        let app = FlowUITests.launch(["-homeDemo", "-demoNoHistory", "-hrv.accessRequested", "NO"])

        XCTAssertTrue(app.staticTexts["Not measured today"].waitForExistence(timeout: 5), "빈 저장소에서 시작")
        app.buttons["Measure"].tap()
        XCTAssertTrue(app.buttons["Start"].waitForExistence(timeout: 5))
        app.buttons["Start"].tap()

        // 12번의 자극마다: "TAP!"이 뜨면 패드를 누르고, 꺼질 때까지 기다린다. ISI는 최대 10초.
        let pad = app.descendants(matching: .any)["touchCatcher"]
        let lit = app.staticTexts["TAP!"]
        XCTAssertTrue(pad.waitForExistence(timeout: 5), "테스트 화면의 자극 패드")
        for round in 1...12 {
            XCTAssertTrue(lit.waitForExistence(timeout: 15), "자극 \(round)이 켜진다")
            pad.tap()
            let off = NSPredicate(format: "exists == false")
            let gone = expectation(for: off, evaluatedWith: lit)
            wait(for: [gone], timeout: 5)
        }

        // 결과: 무효("점수 없음")가 아니라 점수와 사에짱 대사가 있다.
        XCTAssertTrue(app.navigationBars["Result"].waitForExistence(timeout: 10), "12번째 응답 뒤 결과 화면")
        XCTAssertTrue(app.staticTexts["Saechaan"].exists, "사에짱 한마디")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH 'Sae score'")).firstMatch.exists,
                      "점수 카드(라벨+숫자 한 요소)")
        XCTAssertFalse(app.staticTexts["no score — the session was not valid"].exists, "유효 세션이어야 한다")

        // 완료 → 홈: 오늘 점수로 저장돼 보인다.
        app.navigationBars["Result"].buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Today's latest valid measurement."].waitForExistence(timeout: 5),
                      "홈에 오늘 점수 카드")
        XCTAssertFalse(app.staticTexts["Not measured today"].exists)
    }
}
