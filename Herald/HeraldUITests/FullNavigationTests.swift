import XCTest

final class FullNavigationTests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments.append("-UITesting")
        app.launch()

        addUIInterruptionMonitor(withDescription: "Local Network Permission") { alert in
            let allowButton = alert.buttons["Allow"]
            if allowButton.exists {
                allowButton.tap()
                return true
            }
            return false
        }
    }

    // MARK: - Full Hierarchy Navigation

    func testFullViewHierarchyNavigation() throws {
        // 1. Thread Tab
        app.tabBars.buttons["Thread"].tap()

        let threadNavBar = app.navigationBars["Thread Network"]
        XCTAssertTrue(
            threadNavBar.waitForExistence(timeout: 5),
            "Thread Network navigation title should be visible"
        )

        // Verify a border router row appears
        let borderRouterRow = app.staticTexts["Test Border Router"]
        XCTAssertTrue(
            borderRouterRow.waitForExistence(timeout: 10),
            "A border router should appear in the Thread tab"
        )

        // 2. Matter Tab
        app.tabBars.buttons["Matter"].tap()

        let matterNavBar = app.navigationBars["Matter Devices"]
        XCTAssertTrue(
            matterNavBar.waitForExistence(timeout: 5),
            "Matter Devices navigation title should be visible"
        )

        let matterDeviceRow = app.staticTexts["Test Matter Device"]
        XCTAssertTrue(
            matterDeviceRow.waitForExistence(timeout: 10),
            "A matter device should appear in the Matter tab"
        )

        // 3. All Services Tab
        app.tabBars.buttons["All Services"].tap()

        let allServicesNavBar = app.navigationBars["All Services"]
        XCTAssertTrue(
            allServicesNavBar.waitForExistence(timeout: 5),
            "All Services navigation title should be visible"
        )

        let allServicesRow = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(
            allServicesRow.waitForExistence(timeout: 20),
            "An All Services row should appear"
        )

        // 4. All Services — Detail
        allServicesRow.tap()

        let allServicesDetail = app.staticTexts.matching(
            NSPredicate(format: "identifier == %@", "detail.connection")
        ).firstMatch
        let allServicesResolving = app.staticTexts.matching(
            NSPredicate(format: "identifier == %@", "detail.resolving")
        ).firstMatch
        let allServicesDetailReached = allServicesDetail.waitForExistence(timeout: 5)
            || allServicesResolving.waitForExistence(timeout: 5)
        XCTAssertTrue(allServicesDetailReached, "Should reach detail from All Services")

        // Navigate back
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(
            allServicesNavBar.waitForExistence(timeout: 5),
            "Should return to All Services"
        )
    }

}
