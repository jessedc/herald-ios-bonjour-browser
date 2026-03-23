import XCTest

final class MockDataTests: XCTestCase {

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

    // MARK: - Helpers

    private func tapExportButton() {
        let exportButton = app.buttons["export.button"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 1), "Export button should exist")
        exportButton.tap()
    }

    private func assertPreviewAppears() {
        let preview = app.otherElements["export.preview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 1), "Export preview should appear")
    }

    private func dismissPreview() {
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 1), "Done button should exist")
        doneButton.tap()
    }

    // MARK: - All Services Tab

    func testAllServicesTabLoadsWithMockData() throws {
        app.tabBars.buttons["All Services"].tap()

        let navBar = app.navigationBars["All Services"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 1))

        let row = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(
            row.waitForExistence(timeout: 1),
            "Mock service rows should appear in All Services"
        )
    }

    func testAllServicesExportShowsPreview() throws {
        app.tabBars.buttons["All Services"].tap()
        let navBar = app.navigationBars["All Services"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 1))

        tapExportButton()
        assertPreviewAppears()
        dismissPreview()

        XCTAssertTrue(navBar.waitForExistence(timeout: 1), "Should return to All Services after dismissing")
    }

    // MARK: - Search

    func testSearchFiltersServicesByName() throws {
        app.tabBars.buttons["All Services"].tap()
        let navBar = app.navigationBars["All Services"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 1))

        // Wait for mock data to load
        let row = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 1))

        // Verify multiple rows exist before searching
        let allRowsBefore = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        )
        XCTAssertGreaterThan(allRowsBefore.count, 1, "Should have multiple mock services before filtering")

        // Search for a specific service name
        let searchField = app.searchFields["Search services"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 1))
        searchField.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2))
        searchField.typeText("Printer")

        // Wait for filtered results
        let filteredRow = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(filteredRow.waitForExistence(timeout: 2))

        let filteredRows = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        )
        XCTAssertEqual(filteredRows.count, 1, "Only the printer service should match")
    }

    func testSearchFiltersServicesByType() throws {
        app.tabBars.buttons["All Services"].tap()
        let navBar = app.navigationBars["All Services"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 1))

        let row = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 1))

        let searchField = app.searchFields["Search services"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 1))
        searchField.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2))
        searchField.typeText("_airplay")

        // Wait for filtered results
        let filteredRow = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(filteredRow.waitForExistence(timeout: 2))

        let filteredRows = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        )
        XCTAssertEqual(filteredRows.count, 2, "Both airplay services should match")
    }

    func testSearchFiltersByTxtRecordValue() throws {
        app.tabBars.buttons["All Services"].tap()
        let navBar = app.navigationBars["All Services"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 1))

        let row = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 1))

        let searchField = app.searchFields["Search services"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 1))
        searchField.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2))
        searchField.typeText("HomePod")

        // Wait for filtered results
        let filteredRow = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(filteredRow.waitForExistence(timeout: 2))

        let filteredRows = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        )
        XCTAssertEqual(filteredRows.count, 1, "Only the HomePod service should match the TXT record value")
    }

    func testSearchIsCaseInsensitive() throws {
        app.tabBars.buttons["All Services"].tap()
        let navBar = app.navigationBars["All Services"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 1))

        let row = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 1))

        let searchField = app.searchFields["Search services"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 1))
        searchField.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2))
        searchField.typeText("office printer")

        // Wait for filtered results
        let filteredRow = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(filteredRow.waitForExistence(timeout: 2))

        let filteredRows = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        )
        XCTAssertEqual(filteredRows.count, 1, "Case-insensitive search should match 'Office Printer'")
    }

    func testSearchWithNoResultsShowsEmptyList() throws {
        app.tabBars.buttons["All Services"].tap()
        let navBar = app.navigationBars["All Services"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 1))

        let row = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 1))

        let searchField = app.searchFields["Search services"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 1))
        searchField.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2))
        searchField.typeText("zzz_nonexistent_service")

        // Wait for search to filter results
        let filteredRow = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        _ = filteredRow.waitForExistence(timeout: 2)

        let filteredRows = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        )
        XCTAssertEqual(filteredRows.count, 0, "No services should match a nonsense query")
    }

    func testClearingSearchRestoresAllResults() throws {
        app.tabBars.buttons["All Services"].tap()
        let navBar = app.navigationBars["All Services"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 1))

        let rowQuery = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        )
        XCTAssertTrue(rowQuery.firstMatch.waitForExistence(timeout: 1))

        // Search to filter
        let searchField = app.searchFields["Search services"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 1))
        searchField.tap()
        searchField.typeText("Printer")

        // Wait for search to filter results
        XCTAssertTrue(rowQuery.firstMatch.waitForExistence(timeout: 2))

        // Verify search filtered to 1 result
        XCTAssertEqual(rowQuery.count, 1, "Search should filter to one result")

        // Clear the search by using the clear button
        let clearButton = app.buttons["Clear text"]
        if clearButton.waitForExistence(timeout: 1) {
            clearButton.tap()
        }

        // Cancel search
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 1) {
            cancelButton.tap()
        }

        // Verify all 4 mock services are restored by scrolling to make them all visible
        // On small screens not all rows may be visible without scrolling
        app.swipeUp()
        app.swipeDown()
        XCTAssertGreaterThanOrEqual(
            rowQuery.count, 4,
            "All 4 mock services should be restored after clearing search"
        )
    }

    // MARK: - Thread Tab

    func testThreadTabLoadsWithMockData() throws {
        app.tabBars.buttons["Thread"].tap()

        let navBar = app.navigationBars["Thread Network"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 1))

        let routerRow = app.staticTexts["Test Border Router"]
        XCTAssertTrue(
            routerRow.waitForExistence(timeout: 1),
            "Mock border router should appear"
        )
    }

    func testThreadTabShowsAllSections() throws {
        app.tabBars.buttons["Thread"].tap()
        let navBar = app.navigationBars["Thread Network"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 1))

        XCTAssertTrue(
            app.staticTexts["Test Border Router"].waitForExistence(timeout: 1),
            "Border router should appear"
        )
        XCTAssertTrue(
            app.staticTexts["Test TREL Peer"].waitForExistence(timeout: 1),
            "TREL peer should appear"
        )

        let srpServer = app.staticTexts["Test SRP Server"]
        if !srpServer.exists {
            app.swipeUp()
        }
        XCTAssertTrue(
            srpServer.waitForExistence(timeout: 1),
            "SRP server should appear"
        )

        let commissioner = app.staticTexts["Test Commissioner"]
        if !commissioner.exists {
            app.swipeUp()
        }
        XCTAssertTrue(
            commissioner.waitForExistence(timeout: 1),
            "Commissioner should appear"
        )
    }

    func testThreadExportShowsPreview() throws {
        app.tabBars.buttons["Thread"].tap()
        let navBar = app.navigationBars["Thread Network"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 1))

        tapExportButton()
        assertPreviewAppears()
        dismissPreview()

        XCTAssertTrue(navBar.waitForExistence(timeout: 1), "Should return to Thread after dismissing")
    }

    // MARK: - Matter Tab

    func testMatterTabLoadsWithMockData() throws {
        app.tabBars.buttons["Matter"].tap()

        let navBar = app.navigationBars["Matter Devices"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 1))

        let deviceRow = app.staticTexts["Test Light"]
        XCTAssertTrue(
            deviceRow.waitForExistence(timeout: 1),
            "Mock matter device should appear"
        )
    }

    func testMatterTabShowsDeviceDetails() throws {
        app.tabBars.buttons["Matter"].tap()
        let navBar = app.navigationBars["Matter Devices"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 1))

        XCTAssertTrue(
            app.staticTexts["Test Light"].waitForExistence(timeout: 1),
            "Device name should appear"
        )

        let deviceRow = app.cells.containing(.staticText, identifier: "Test Light").firstMatch
        XCTAssertTrue(deviceRow.exists, "Device row should exist")

        let serviceTypeLabel = deviceRow.staticTexts["Service"]
        XCTAssertTrue(serviceTypeLabel.exists, "Service label should be visible in device details")
    }

    func testMatterExportShowsPreview() throws {
        app.tabBars.buttons["Matter"].tap()
        let navBar = app.navigationBars["Matter Devices"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 1))

        tapExportButton()
        assertPreviewAppears()
        dismissPreview()

        XCTAssertTrue(navBar.waitForExistence(timeout: 1), "Should return to Matter after dismissing")
    }
}

// MARK: - Error Display Tests (uses -UITestingErrors)

final class MockErrorTests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments.append("-UITestingErrors")
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

    // MARK: - Helpers

    private func openErrorSheet() {
        let errorChip = app.buttons["stats.errorChip"]
        XCTAssertTrue(errorChip.waitForExistence(timeout: 1), "Error chip should appear")
        errorChip.tap()

        let errorsNavBar = app.navigationBars["Errors"]
        XCTAssertTrue(errorsNavBar.waitForExistence(timeout: 1), "Error list sheet should present")
    }

    private func dismissErrorSheet() {
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.exists, "Done button should be visible")
        doneButton.tap()
    }

    // MARK: - All Services Error Display

    func testAllServicesTabShowsErrorChip() throws {
        app.tabBars.buttons["All Services"].tap()

        let navBar = app.navigationBars["All Services"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 1))

        let errorChip = app.buttons["stats.errorChip"]
        XCTAssertTrue(
            errorChip.waitForExistence(timeout: 1),
            "Error chip should appear on the All Services tab"
        )
    }

    func testAllServicesErrorChipShowsErrorList() throws {
        app.tabBars.buttons["All Services"].tap()
        openErrorSheet()

        let sourceLabel = app.staticTexts["Bonjour Discovery"]
        XCTAssertTrue(sourceLabel.exists, "Error source 'Bonjour Discovery' should be visible")
    }

    func testAllServicesErrorSheetDismisses() throws {
        app.tabBars.buttons["All Services"].tap()
        openErrorSheet()
        dismissErrorSheet()

        let navBar = app.navigationBars["All Services"]
        XCTAssertTrue(
            navBar.waitForExistence(timeout: 1),
            "Should return to All Services after dismissing error sheet"
        )
    }
}
