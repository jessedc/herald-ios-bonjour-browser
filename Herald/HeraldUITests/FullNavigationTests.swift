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

        let matterDeviceRow = app.staticTexts["Test Light"]
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

    // MARK: - Reverse DNS Info

    func testReverseDNSInfoNavigation() throws {
        // Navigate to All Services tab
        app.tabBars.buttons["All Services"].tap()

        // Tap a service row to reach detail
        let serviceRow = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(
            serviceRow.waitForExistence(timeout: 20),
            "A service row should appear"
        )
        serviceRow.tap()

        // Wait for the detail view to resolve (connection section or resolving indicator)
        let connectionSection = app.staticTexts.matching(
            NSPredicate(format: "identifier == %@", "detail.connection")
        ).firstMatch
        let resolvingIndicator = app.staticTexts.matching(
            NSPredicate(format: "identifier == %@", "detail.resolving")
        ).firstMatch
        let detailReached = connectionSection.waitForExistence(timeout: 10)
            || resolvingIndicator.waitForExistence(timeout: 10)
        XCTAssertTrue(
            detailReached,
            "Service detail should resolve and show connection section"
        )

        // Tap the Reverse DNS info button (may be off-screen on smaller devices)
        let infoButton = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "detail.reverseDNSInfo")
        ).firstMatch
        // Scroll until the button appears in the accessibility hierarchy
        var found = infoButton.waitForExistence(timeout: 2)
        for _ in 0..<5 where !found {
            app.swipeUp()
            found = infoButton.waitForExistence(timeout: 2)
        }
        XCTAssertTrue(found, "Reverse DNS info button should be visible")
        infoButton.tap()

        // Verify the info view appeared
        let infoNavBar = app.navigationBars["About Reverse DNS Lookups"]
        XCTAssertTrue(
            infoNavBar.waitForExistence(timeout: 5),
            "About Reverse DNS Lookups screen should appear"
        )

        // Verify some content is present
        let ptrText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "PTR")
        ).firstMatch
        XCTAssertTrue(
            ptrText.exists,
            "Info view should contain text about PTR lookups"
        )

        // Navigate back to detail
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // Verify we're back on the detail view (info button should be visible again)
        XCTAssertTrue(
            infoButton.waitForExistence(timeout: 5),
            "Should return to service detail"
        )
    }

}
