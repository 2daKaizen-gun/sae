import XCTest

/// 데이터 화면 — 취소하면 그대로, 확인하면 0. 메모리 전용 데모 저장소(점수 10일치)에서 돈다.
final class DataDeletionUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func openDataScreen() -> XCUIApplication {
        let app = FlowUITests.launch(["-homeDemo"])
        XCTAssertTrue(app.buttons["Data on this device"].waitForExistence(timeout: 5))
        app.buttons["Data on this device"].tap()
        XCTAssertTrue(app.navigationBars["Data on this device"].waitForExistence(timeout: 5))
        return app
    }

    /// "Daily scores" 줄의 값(세로/가로 배치와 무관하게 같은 줄의 두 번째 글자 요소).
    private func dailyScoreCount(_ app: XCUIApplication) -> String {
        let texts = app.staticTexts.allElementsBoundByIndex.map(\.label)
        guard let i = texts.firstIndex(of: "Daily scores"), i + 1 < texts.count else { return "?" }
        return texts[i + 1]
    }

    func testCancellingKeepsEverything() {
        let app = openDataScreen()
        XCTAssertEqual(dailyScoreCount(app), "10")
        app.buttons["Delete all measurement records"].tap()
        let confirm = app.buttons["Delete"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "확인 창")
        // iOS 26의 확인 창은 별도 취소 버튼을 보이지 않고, 창 밖을 누르면 취소된다 — 사용자가 하듯이 한다.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)).tap()
        wait(for: [expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: confirm)], timeout: 5)
        XCTAssertEqual(dailyScoreCount(app), "10", "취소하면 아무것도 지워지지 않는다")
        XCTAssertFalse(app.staticTexts["All measurement records were deleted."].exists)
    }

    func testConfirmingDeletesEverything() {
        let app = openDataScreen()
        app.buttons["Delete all measurement records"].tap()
        let confirm = app.buttons["Delete"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        XCTAssertTrue(app.staticTexts["All measurement records were deleted."].waitForExistence(timeout: 5))
        XCTAssertEqual(dailyScoreCount(app), "0")
        XCTAssertFalse(app.buttons["Delete all measurement records"].isEnabled, "지울 것이 없으면 버튼이 꺼진다")
    }
}
