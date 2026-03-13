import XCTest

final class LiveNetworkNavigationTests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = true
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

    // MARK: - All Services Tab

    func testAllServicesShowsServicesOnLoad() throws {
        let allServicesNavBar = app.navigationBars["All Services"]
        XCTAssertTrue(
            allServicesNavBar.waitForExistence(timeout: 5),
            "All Services title should be visible"
        )

        let allServicesRow = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(
            allServicesRow.waitForExistence(timeout: 20),
            "A service row should appear in All Services"
        )

        let errorChip = app.buttons["stats.errorChip"]
        XCTAssertFalse(
            errorChip.waitForExistence(timeout: 3),
            "No error chip should be present on All Services"
        )
    }

    func testAllServicesNavigateToDetailAndResolve() throws {
        let allServicesRow = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(
            allServicesRow.waitForExistence(timeout: 20),
            "A service row should appear"
        )

        allServicesRow.tap()

        // Detail should show either resolved connection info or a resolving indicator
        let connection = app.staticTexts.matching(
            NSPredicate(format: "identifier == %@", "detail.connection")
        ).firstMatch
        let resolving = app.staticTexts.matching(
            NSPredicate(format: "identifier == %@", "detail.resolving")
        ).firstMatch
        let detailReached = connection.waitForExistence(timeout: 10)
            || resolving.waitForExistence(timeout: 3)
        XCTAssertTrue(detailReached, "Should reach service detail view")

        // If resolving, wait for it to complete
        if resolving.exists {
            XCTAssertTrue(
                connection.waitForExistence(timeout: 15),
                "Resolution should complete and show connection info"
            )
        }

        // Navigate back
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let allServicesNavBar = app.navigationBars["All Services"]
        XCTAssertTrue(
            allServicesNavBar.waitForExistence(timeout: 5),
            "Should return to All Services"
        )
    }

    func testAllServicesExportWithLiveData() throws {
        let allServicesRow = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(
            allServicesRow.waitForExistence(timeout: 20),
            "Services should appear before exporting"
        )

        let exportButton = app.buttons["export.button"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5), "Export button should exist")
        exportButton.tap()

        let preview = app.otherElements["export.preview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5), "Export preview should appear with live data")

        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5))
        doneButton.tap()
    }

    func testAllServicesPullToRefresh() throws {
        let allServicesRow = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(
            allServicesRow.waitForExistence(timeout: 20),
            "Services should appear before refresh"
        )

        // Pull to refresh
        let list = app.tables.firstMatch.exists ? app.tables.firstMatch : app.collectionViews.firstMatch
        list.swipeDown()

        // Services should still appear after refresh
        XCTAssertTrue(
            allServicesRow.waitForExistence(timeout: 20),
            "Services should reappear after pull-to-refresh"
        )
    }

    // MARK: - Thread Tab

    func testThreadTabLoads() throws {
        app.tabBars.buttons["Thread"].tap()

        let threadNavBar = app.navigationBars["Thread Network"]
        XCTAssertTrue(
            threadNavBar.waitForExistence(timeout: 5),
            "Thread Network title should be visible"
        )

        // Thread devices may or may not be present on the network.
        // Verify either content appears or the empty/searching state shows.
        let routerRow = app.staticTexts.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "thread.router.row.")
        ).firstMatch
        let searchingText = app.staticTexts["Searching for Thread devices..."]
        let noDevicesText = app.staticTexts["No Thread devices found"]

        let threadLoaded = routerRow.waitForExistence(timeout: 15)
            || searchingText.exists
            || noDevicesText.waitForExistence(timeout: 10)
        XCTAssertTrue(threadLoaded, "Thread tab should show content, searching, or empty state")
    }

    func testThreadTabExportWithLiveData() throws {
        app.tabBars.buttons["Thread"].tap()

        let threadNavBar = app.navigationBars["Thread Network"]
        XCTAssertTrue(threadNavBar.waitForExistence(timeout: 5))

        let exportButton = app.buttons["export.button"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5), "Export button should exist on Thread tab")
        exportButton.tap()

        let preview = app.otherElements["export.preview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5), "Export preview should appear")

        app.buttons["Done"].tap()
    }

    // MARK: - Matter Tab

    func testMatterTabLoads() throws {
        app.tabBars.buttons["Matter"].tap()

        let matterNavBar = app.navigationBars["Matter Devices"]
        XCTAssertTrue(
            matterNavBar.waitForExistence(timeout: 5),
            "Matter Devices title should be visible"
        )

        let deviceRow = app.staticTexts.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "matter.device.row.")
        ).firstMatch
        let searchingText = app.staticTexts["Searching for Matter devices..."]
        let noDevicesText = app.staticTexts["No Matter devices found"]

        let matterLoaded = deviceRow.waitForExistence(timeout: 15)
            || searchingText.exists
            || noDevicesText.waitForExistence(timeout: 10)
        XCTAssertTrue(matterLoaded, "Matter tab should show content, searching, or empty state")
    }

    func testMatterTabExportWithLiveData() throws {
        app.tabBars.buttons["Matter"].tap()

        let matterNavBar = app.navigationBars["Matter Devices"]
        XCTAssertTrue(matterNavBar.waitForExistence(timeout: 5))

        let exportButton = app.buttons["export.button"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5), "Export button should exist on Matter tab")
        exportButton.tap()

        let preview = app.otherElements["export.preview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5), "Export preview should appear")

        app.buttons["Done"].tap()
    }

    // MARK: - Cross-Tab Navigation

    func testTabCyclingThenAllServicesShowsServices() throws {
        // Visit Thread
        app.tabBars.buttons["Thread"].tap()
        let threadNavBar = app.navigationBars["Thread Network"]
        XCTAssertTrue(threadNavBar.waitForExistence(timeout: 5))

        // Visit Matter
        app.tabBars.buttons["Matter"].tap()
        let matterNavBar = app.navigationBars["Matter Devices"]
        XCTAssertTrue(matterNavBar.waitForExistence(timeout: 5))

        // Return to All Services
        app.tabBars.buttons["All Services"].tap()
        let allServicesNavBar = app.navigationBars["All Services"]
        XCTAssertTrue(allServicesNavBar.waitForExistence(timeout: 5))

        let allServicesRow = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(
            allServicesRow.waitForExistence(timeout: 20),
            "Services should still appear after cycling through all tabs"
        )

        let errorChip = app.buttons["stats.errorChip"]
        XCTAssertFalse(
            errorChip.waitForExistence(timeout: 3),
            "No error chip should be present after tab cycling"
        )
    }

    func testFullTabNavigationRoundTrip() throws {
        // All Services -> detail -> back -> Thread -> Matter -> All Services
        let allServicesRow = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(allServicesRow.waitForExistence(timeout: 20))
        allServicesRow.tap()

        let connection = app.staticTexts.matching(
            NSPredicate(format: "identifier == %@", "detail.connection")
        ).firstMatch
        let resolving = app.staticTexts.matching(
            NSPredicate(format: "identifier == %@", "detail.resolving")
        ).firstMatch
        let detailReached = connection.waitForExistence(timeout: 10)
            || resolving.waitForExistence(timeout: 3)
        XCTAssertTrue(detailReached, "Should reach detail view")

        // Back
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let allServicesNavBar = app.navigationBars["All Services"]
        XCTAssertTrue(allServicesNavBar.waitForExistence(timeout: 5))

        // Thread
        app.tabBars.buttons["Thread"].tap()
        XCTAssertTrue(app.navigationBars["Thread Network"].waitForExistence(timeout: 5))

        // Matter
        app.tabBars.buttons["Matter"].tap()
        XCTAssertTrue(app.navigationBars["Matter Devices"].waitForExistence(timeout: 5))

        // Back to All Services - services should still be there
        app.tabBars.buttons["All Services"].tap()
        XCTAssertTrue(allServicesNavBar.waitForExistence(timeout: 5))
        XCTAssertTrue(
            allServicesRow.waitForExistence(timeout: 10),
            "Services should persist after full navigation round trip"
        )
    }
}
