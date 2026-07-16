//
//  QrScanUITests.swift
//  QrScanUITests
//
//  Created by Junjie Qin on 2025/11/26.
//

import XCTest

final class QrScanUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSwipeBetweenGeneratorAndHistoryPages() throws {
        let app = XCUIApplication()
        app.launch()

        let pager = app.descendants(matching: .any)["home.page.pager"]
        let editor = app.textViews["home.payload.editor"]
        let pageIndicator = app.pageIndicators.firstMatch
        let historyTitle = app.staticTexts["home.history.title"]
        let clearHistoryButton = app.buttons["home.history.clear"]

        XCTAssertTrue(pager.waitForExistence(timeout: 5))
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertTrue(editor.isHittable)
        XCTAssertTrue(pageIndicator.waitForExistence(timeout: 5))
        XCTAssertFalse(historyTitle.isHittable)

        app.swipeLeft()

        waitUntilHittable(historyTitle)
        waitUntilHittable(clearHistoryButton)

        app.swipeRight()

        waitUntilHittable(editor)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    private func waitUntilHittable(_ element: XCUIElement, timeout: TimeInterval = 5) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND hittable == true"),
            object: element
        )
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed)
    }
}
