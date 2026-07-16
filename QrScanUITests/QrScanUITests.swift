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
        XCUIDevice.shared.orientation = .portrait
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
    func testGeneratorUsesAdaptiveLayoutSizes() throws {
        XCUIDevice.shared.orientation = .portrait
        defer {
            XCUIDevice.shared.orientation = .portrait
        }

        let app = XCUIApplication()
        app.launch()

        let editor = app.textViews["home.payload.editor"]
        let qrPreview = app.descendants(matching: .any)["home.qr.preview"]

        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertTrue(qrPreview.waitForExistence(timeout: 5))
        waitUntilFrameMatches(qrPreview, width: 240, height: 240)
        XCTAssertGreaterThanOrEqual(editor.frame.height, 140)
        let portraitEditorHeight = editor.frame.height

        XCUIDevice.shared.orientation = .landscapeLeft

        waitUntilFrameMatches(qrPreview, width: 180, height: 180)
        waitUntilHeightMatches(
            editor,
            minimumHeight: 100,
            maximumHeight: portraitEditorHeight - 1
        )
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

    @MainActor
    private func waitUntilFrameMatches(
        _ element: XCUIElement,
        width: CGFloat,
        height: CGFloat,
        tolerance: CGFloat = 2,
        timeout: TimeInterval = 5
    ) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { object, _ in
                guard let element = object as? XCUIElement else { return false }

                return abs(element.frame.width - width) <= tolerance
                    && abs(element.frame.height - height) <= tolerance
            },
            object: element
        )
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed)
    }

    @MainActor
    private func waitUntilHeightMatches(
        _ element: XCUIElement,
        minimumHeight: CGFloat,
        maximumHeight: CGFloat,
        timeout: TimeInterval = 5
    ) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { object, _ in
                guard let element = object as? XCUIElement else { return false }

                return element.frame.height >= minimumHeight
                    && element.frame.height <= maximumHeight
            },
            object: element
        )
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed)
    }
}
