import XCTest

final class PracticeTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    private func show(_ element: XCUIElement) {
        for _ in 0..<8 {
            if element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }

    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testNativeLearningFlowAndPersistence() {
        app.tabBars.buttons["Library"].tap()
        let first = app.buttons["passage0"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        first.tap()
        XCTAssertTrue(app.staticTexts["passageTitle"].waitForExistence(timeout: 5))
        screenshot("practice-light")
        app.buttons["listenLine0"].tap()
        XCTAssertTrue(app.buttons["Stop audio"].waitForExistence(timeout: 3))
        app.buttons["listenLine0"].tap()
        app.segmentedControls.buttons["Hints"].tap()
        XCTAssertTrue(app.buttons["Hidden word 2, line 1"].exists)
        screenshot("hints-light")
        app.buttons["Hidden word 2, line 1"].tap()
        app.segmentedControls.buttons["Recall"].tap()
        screenshot("recall-light")
        let reveal = app.buttons["practiceStep"]
        show(reveal)
        reveal.tap()
        let remembered = app.buttons["remembered"]
        show(remembered)
        remembered.tap()
        XCTAssertTrue(app.staticTexts["assessmentResult"].waitForExistence(timeout: 3))
        app.tabBars.buttons["Progress"].tap()
        XCTAssertTrue(app.staticTexts["of 43 recalled"].exists)
        screenshot("progress-light")
        app.tabBars.buttons["Library"].tap()
        app.buttons["passage2"].tap()
        XCTAssertTrue(app.staticTexts["passageTitle"].isHittable)
        app.terminate()
        app.launch()
        XCTAssertEqual(app.staticTexts["passageTitle"].label, "Verse 1")
        screenshot("verse-light")
    }

    func testLibrarySearchAndSettings() {
        app.tabBars.buttons["Library"].tap()
        let search = app.searchFields.firstMatch
        if !search.isHittable { app.swipeDown() }
        search.tap()
        search.typeText("Bajrangi")
        XCTAssertTrue(app.buttons["passage4"].waitForExistence(timeout: 3))
        screenshot("library-search")
        app.buttons["passage4"].tap()
        XCTAssertEqual(app.staticTexts["passageTitle"].label, "Verse 3")
        app.tabBars.buttons["Progress"].tap()
        app.buttons["Settings and about"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        app.buttons["Done"].tap()
    }

    func testLargestTextLayout() {
        app.terminate()
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL", "-AppleInterfaceStyle", "Dark"]
        app.launch()
        XCTAssertTrue(app.buttons["accessibleMode"].waitForExistence(timeout: 5))
        screenshot("largest-text-top")
        app.buttons["accessibleMode"].tap()
        app.buttons["Recall"].tap()
        let reveal = app.buttons["practiceStep"]
        show(reveal)
        reveal.tap()
        let assessment = app.buttons["needsPractice"]
        show(assessment)
        screenshot("largest-text-assessment")
        assessment.tap()
        XCTAssertTrue(app.staticTexts["assessmentResult"].waitForExistence(timeout: 5))
    }
}
