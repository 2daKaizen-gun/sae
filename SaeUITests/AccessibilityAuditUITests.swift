import XCTest

/// 화면마다 애플의 자동 접근성 점검(`performAccessibilityAudit`)을 돌린다.
///
/// 점검 항목: 대비, 요소 설명, 히트 영역, Dynamic Type 지원, 잘린 텍스트 등. 예외는 하나뿐이다(아래 `audit`).
/// 데모 데이터 화면은
/// DEBUG 인자로 띄운다(메모리 전용 저장소, 실제 저장소는 건드리지 않는다).
final class AccessibilityAuditUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = true
    }

    private func audit(_ arguments: [String], waitFor element: (XCUIApplication) -> XCUIElement) throws {
        let app = FlowUITests.launch(arguments)
        XCTAssertTrue(element(app).waitForExistence(timeout: 5), "점검할 화면이 떴다")
        try app.performAccessibilityAudit { issue in
            // 유일한 예외 — 내비게이션 바의 시스템 버튼(결과 시트의 "완료")에 대한 Dynamic Type 경고.
            // 바 버튼의 글자 크기는 시스템이 정하고, 큰 글자 크기에서는 길게 누르면 뜨는 Large Content Viewer로
            // 보여 준다. 앱 코드로 키울 수 있는 요소가 아니므로 이 조합(유형 + 내비게이션 바 버튼)만 넘긴다.
            if issue.auditType == .dynamicType, let label = issue.element?.label,
               app.navigationBars.buttons[label].exists {
                return true
            }
            // 나머지는 전부 실패로 남기되, 어느 요소인지 메시지에 적는다(점검 결과를 고칠 수 있게).
            XCTFail("Audit: \(issue.compactDescription) — '\(issue.element?.label ?? "-")'")
            return true
        }
    }

    func testOnboarding() throws {
        try audit(["-resetOnboarding"]) { $0.buttons["Get started"] }
    }

    func testHomeWithTodaysScore() throws {
        try audit(["-homeDemo"]) { $0.buttons["Measure"] }
    }

    func testInstructions() throws {
        try audit(["-autointro"]) { $0.buttons["Start"] }
    }

    func testResult() throws {
        try audit(["-resultDemo"]) { $0.buttons["Done"] }
    }

    func testTrend() throws {
        try audit(["-trendDemo", "-trendSelect", "3"]) { $0.staticTexts["Trend"] }
    }

    // MARK: 가장 큰 접근성 글자 크기(AX5)에서 같은 점검

    /// UIKit가 읽는 기본 설정 키로 앱의 글자 크기를 AX5로 띄운다(시스템 설정은 건드리지 않는다).
    private let largestText = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]

    func testHomeAtTheLargestTextSize() throws {
        try audit(["-homeDemo"] + largestText) { $0.buttons["Measure"] }
    }

    func testInstructionsAtTheLargestTextSize() throws {
        try audit(["-autointro"] + largestText) { $0.buttons["Start"] }
    }

    func testResultAtTheLargestTextSize() throws {
        try audit(["-resultDemo"] + largestText) { $0.buttons["Done"] }
    }

    func testTrendAtTheLargestTextSize() throws {
        try audit(["-trendDemo", "-trendSelect", "3"] + largestText) { $0.staticTexts["Trend"] }
    }
}
