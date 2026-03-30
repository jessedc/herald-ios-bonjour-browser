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

    // MARK: - Bluetooth Tab

    func testBluetoothTabLoadsWithMockData() throws {
        app.tabBars.buttons["Bluetooth"].tap()

        let navBar = app.navigationBars["Bluetooth"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 1))

        let deviceRow = app.staticTexts["Test Matter Light"]
        if !deviceRow.waitForExistence(timeout: 1) {
            app.swipeUp()
        }
        XCTAssertTrue(
            deviceRow.waitForExistence(timeout: 1),
            "Mock BLE device should appear"
        )
    }

    func testBluetoothExportShowsPreview() throws {
        app.tabBars.buttons["Bluetooth"].tap()
        let navBar = app.navigationBars["Bluetooth"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 1))

        tapExportButton()
        assertPreviewAppears()
        dismissPreview()

        XCTAssertTrue(navBar.waitForExistence(timeout: 1), "Should return to Bluetooth after dismissing")
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
        let trelPeer = app.staticTexts["Test TREL Peer"]
        if !trelPeer.exists {
            app.swipeUp()
        }
        XCTAssertTrue(
            trelPeer.waitForExistence(timeout: 1),
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
        // Scroll down on smaller screens where tips may push content below the fold
        if !deviceRow.waitForExistence(timeout: 1) {
            app.swipeUp()
        }
        XCTAssertTrue(
            deviceRow.waitForExistence(timeout: 1),
            "Mock matter device should appear"
        )
    }

    func testMatterTabShowsDeviceDetails() throws {
        app.tabBars.buttons["Matter"].tap()
        let navBar = app.navigationBars["Matter Devices"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 1))

        // Scroll down on smaller screens where tips may push content below the fold
        if !app.staticTexts["Test Light"].waitForExistence(timeout: 1) {
            app.swipeUp()
        }
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

    // MARK: - Info Tab

    func testInfoTabLoads() throws {
        app.tabBars.buttons["Info"].tap()

        let navBar = app.navigationBars["Info"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 2))

        let dnssdText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "DNS-SD")
        ).firstMatch
        XCTAssertTrue(dnssdText.exists, "About section should mention DNS-SD")

        app.swipeUp()
        let versionText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "Herald v")
        ).firstMatch
        XCTAssertTrue(
            versionText.waitForExistence(timeout: 1),
            "Version text should be visible"
        )
    }

    func testInfoTabQueriesByTabNavigation() throws {
        app.tabBars.buttons["Info"].tap()
        XCTAssertTrue(app.navigationBars["Info"].waitForExistence(timeout: 2))

        // Navigate to All Services Queries
        app.staticTexts["All Services"].tap()
        XCTAssertTrue(
            app.navigationBars["All Services Queries"].waitForExistence(timeout: 2),
            "All Services Queries detail should appear"
        )
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Info"].waitForExistence(timeout: 2))

        // Navigate to Thread Queries
        app.staticTexts["Thread"].tap()
        XCTAssertTrue(
            app.navigationBars["Thread Queries"].waitForExistence(timeout: 2),
            "Thread Queries detail should appear"
        )
        let meshcopText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "_meshcop._udp")
        ).firstMatch
        XCTAssertTrue(meshcopText.exists, "Thread queries should show _meshcop._udp service type")
    }

    func testInfoTabAppShortcutsNavigation() throws {
        app.tabBars.buttons["Info"].tap()
        XCTAssertTrue(app.navigationBars["Info"].waitForExistence(timeout: 2))

        // Scroll to App Shortcuts section and tap
        let countMatter = app.staticTexts["Count Matter Devices"]
        if !countMatter.waitForExistence(timeout: 1) {
            app.swipeUp()
        }
        XCTAssertTrue(countMatter.waitForExistence(timeout: 1))
        countMatter.tap()

        XCTAssertTrue(
            app.navigationBars["App Shortcuts"].waitForExistence(timeout: 2),
            "App Shortcuts detail should appear"
        )
    }

    func testInfoTabResetTipsConfirmation() throws {
        app.tabBars.buttons["Info"].tap()
        XCTAssertTrue(app.navigationBars["Info"].waitForExistence(timeout: 2))

        // Scroll to Reset Tips button
        let resetButton = app.buttons["Reset Tips"]
        if !resetButton.waitForExistence(timeout: 1) {
            app.swipeUp()
        }
        XCTAssertTrue(resetButton.waitForExistence(timeout: 1))
        resetButton.tap()

        // Verify confirmation dialog appears
        let confirmationText = app.staticTexts["All educational tips will appear again."]
        XCTAssertTrue(
            confirmationText.waitForExistence(timeout: 2),
            "Reset tips confirmation dialog should appear"
        )
    }

    // MARK: - Bluetooth Peripheral Detail

    func testBluetoothPeripheralDetailNavigation() throws {
        app.tabBars.buttons["Bluetooth"].tap()
        XCTAssertTrue(app.navigationBars["Bluetooth"].waitForExistence(timeout: 2))

        let deviceRow = app.buttons["bluetooth.device.row.A1B2C3D4-E5F6-7890-ABCD-EF1234567890"]
        if !deviceRow.waitForExistence(timeout: 1) {
            app.swipeUp()
        }
        XCTAssertTrue(deviceRow.waitForExistence(timeout: 1), "BLE device row should exist")
        deviceRow.tap()

        // Verify detail view loaded with device info
        let navTitle = app.navigationBars["Test Matter Light"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 2), "Detail nav title should show device name")

        let nameLabel = app.staticTexts["Test Matter Light"]
        XCTAssertTrue(nameLabel.exists, "Device name should appear in detail")

        let rssiLabel = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "dBm")
        ).firstMatch
        XCTAssertTrue(rssiLabel.exists, "RSSI value should appear in Signal section")

        // Navigate back
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Bluetooth"].waitForExistence(timeout: 2))
    }

    func testBluetoothPeripheralDetailMatterData() throws {
        app.tabBars.buttons["Bluetooth"].tap()
        XCTAssertTrue(app.navigationBars["Bluetooth"].waitForExistence(timeout: 2))

        let deviceRow = app.buttons["bluetooth.device.row.A1B2C3D4-E5F6-7890-ABCD-EF1234567890"]
        if !deviceRow.waitForExistence(timeout: 1) {
            app.swipeUp()
        }
        deviceRow.tap()
        XCTAssertTrue(app.navigationBars["Test Matter Light"].waitForExistence(timeout: 2))

        // Scroll to Matter Commissioning section
        app.swipeUp()
        let discriminatorLabel = app.staticTexts["Discriminator"]
        XCTAssertTrue(
            discriminatorLabel.waitForExistence(timeout: 1),
            "Discriminator label should appear in Matter Commissioning section"
        )
    }

    func testBluetoothPeripheralDetailExport() throws {
        app.tabBars.buttons["Bluetooth"].tap()
        XCTAssertTrue(app.navigationBars["Bluetooth"].waitForExistence(timeout: 2))

        let deviceRow = app.buttons["bluetooth.device.row.A1B2C3D4-E5F6-7890-ABCD-EF1234567890"]
        if !deviceRow.waitForExistence(timeout: 1) {
            app.swipeUp()
        }
        deviceRow.tap()
        XCTAssertTrue(app.navigationBars["Test Matter Light"].waitForExistence(timeout: 2))

        tapExportButton()
        assertPreviewAppears()
        dismissPreview()
    }

    // MARK: - Thread Detail Navigation

    func testThreadBorderRouterDetailNavigation() throws {
        app.tabBars.buttons["Thread"].tap()
        XCTAssertTrue(app.navigationBars["Thread Network"].waitForExistence(timeout: 2))

        let routerRow = app.buttons["thread.router.row.Test Border Router"]
        XCTAssertTrue(routerRow.waitForExistence(timeout: 2), "Border router row should exist")
        routerRow.tap()

        // Verify detail view loaded — check for the Service section header
        // which is always present, or the connection section which appears after resolution
        let serviceSection = app.staticTexts["Service"]
        let connection = app.otherElements["detail.connection"]
        let detailReached = serviceSection.waitForExistence(timeout: 5)
            || connection.waitForExistence(timeout: 5)
        XCTAssertTrue(detailReached, "Service detail should load for border router")

        // Navigate back
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Thread Network"].waitForExistence(timeout: 2))
    }

    func testThreadTRELPeerDetailNavigation() throws {
        app.tabBars.buttons["Thread"].tap()
        XCTAssertTrue(app.navigationBars["Thread Network"].waitForExistence(timeout: 2))

        let peerRow = app.buttons["thread.trel.row.Test TREL Peer"]
        if !peerRow.waitForExistence(timeout: 1) {
            app.swipeUp()
        }
        XCTAssertTrue(peerRow.waitForExistence(timeout: 1), "TREL peer row should exist")
        peerRow.tap()

        let serviceSection = app.staticTexts["Service"]
        let connection = app.otherElements["detail.connection"]
        let detailReached = serviceSection.waitForExistence(timeout: 5)
            || connection.waitForExistence(timeout: 5)
        XCTAssertTrue(detailReached, "Service detail should load for TREL peer")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Thread Network"].waitForExistence(timeout: 2))
    }

    func testThreadSRPServerDetailNavigation() throws {
        app.tabBars.buttons["Thread"].tap()
        XCTAssertTrue(app.navigationBars["Thread Network"].waitForExistence(timeout: 2))

        let srpRow = app.buttons["thread.srp.row.Test SRP Server"]
        if !srpRow.waitForExistence(timeout: 1) {
            app.swipeUp()
        }
        XCTAssertTrue(srpRow.waitForExistence(timeout: 1), "SRP server row should exist")
        srpRow.tap()

        let serviceSection = app.staticTexts["Service"]
        let connection = app.otherElements["detail.connection"]
        let detailReached = serviceSection.waitForExistence(timeout: 5)
            || connection.waitForExistence(timeout: 5)
        XCTAssertTrue(detailReached, "Service detail should load for SRP server")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Thread Network"].waitForExistence(timeout: 2))
    }

    func testThreadCommissionerDetailNavigation() throws {
        app.tabBars.buttons["Thread"].tap()
        XCTAssertTrue(app.navigationBars["Thread Network"].waitForExistence(timeout: 2))

        let commRow = app.buttons["thread.commissioner.row.Test Commissioner"]
        if !commRow.waitForExistence(timeout: 1) {
            app.swipeUp()
        }
        XCTAssertTrue(commRow.waitForExistence(timeout: 1), "Commissioner row should exist")
        commRow.tap()

        let serviceSection = app.staticTexts["Service"]
        let connection = app.otherElements["detail.connection"]
        let detailReached = serviceSection.waitForExistence(timeout: 5)
            || connection.waitForExistence(timeout: 5)
        XCTAssertTrue(detailReached, "Service detail should load for commissioner")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Thread Network"].waitForExistence(timeout: 2))
    }

    // MARK: - Matter Detail Navigation

    func testMatterCommissionableDeviceDetail() throws {
        app.tabBars.buttons["Matter"].tap()
        XCTAssertTrue(app.navigationBars["Matter Devices"].waitForExistence(timeout: 2))

        let deviceRow = app.buttons["matter.device.row.Test Matter Device"]
        if !deviceRow.waitForExistence(timeout: 1) {
            app.swipeUp()
        }
        XCTAssertTrue(deviceRow.waitForExistence(timeout: 1), "Commissionable device row should exist")
        deviceRow.tap()

        let serviceSection = app.staticTexts["Service"]
        let connection = app.otherElements["detail.connection"]
        let detailReached = serviceSection.waitForExistence(timeout: 5)
            || connection.waitForExistence(timeout: 5)
        XCTAssertTrue(detailReached, "Service detail should load for commissionable Matter device")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Matter Devices"].waitForExistence(timeout: 2))
    }

    func testMatterOperationalDeviceDetail() throws {
        app.tabBars.buttons["Matter"].tap()
        XCTAssertTrue(app.navigationBars["Matter Devices"].waitForExistence(timeout: 2))

        let deviceRow = app.buttons["matter.device.row.38271586BF3DEB06-00000000082931E5"]
        if !deviceRow.waitForExistence(timeout: 1) {
            app.swipeUp()
        }
        XCTAssertTrue(deviceRow.waitForExistence(timeout: 1), "Operational device row should exist")
        deviceRow.tap()

        let serviceSection = app.staticTexts["Service"]
        let connection = app.otherElements["detail.connection"]
        let detailReached = serviceSection.waitForExistence(timeout: 5)
            || connection.waitForExistence(timeout: 5)
        XCTAssertTrue(detailReached, "Service detail should load for operational Matter device")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Matter Devices"].waitForExistence(timeout: 2))
    }

    // MARK: - Service Detail Content

    func testServiceDetailShowsConnectionInfo() throws {
        app.tabBars.buttons["All Services"].tap()
        XCTAssertTrue(app.navigationBars["All Services"].waitForExistence(timeout: 2))

        let row = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.tap()

        let connection = app.staticTexts.matching(
            NSPredicate(format: "identifier == %@", "detail.connection")
        ).firstMatch
        XCTAssertTrue(connection.waitForExistence(timeout: 2), "Connection section should appear")

        let hostname = app.staticTexts["test-host.local."]
        XCTAssertTrue(hostname.exists, "Hostname should appear in connection section")

        let ip = app.staticTexts["192.168.1.100"]
        if !ip.exists {
            app.swipeUp()
        }
        XCTAssertTrue(ip.waitForExistence(timeout: 1), "IPv4 address should appear")
    }

    func testServiceDetailShowsTXTRecord() throws {
        app.tabBars.buttons["All Services"].tap()
        XCTAssertTrue(app.navigationBars["All Services"].waitForExistence(timeout: 2))

        let row = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.tap()

        // Wait for detail to load
        let connection = app.staticTexts.matching(
            NSPredicate(format: "identifier == %@", "detail.connection")
        ).firstMatch
        XCTAssertTrue(connection.waitForExistence(timeout: 2))

        // Scroll to TXT Record section
        for _ in 0..<3 {
            app.swipeUp()
        }
        let txtSection = app.staticTexts["TXT Record"]
        XCTAssertTrue(txtSection.waitForExistence(timeout: 1), "TXT Record section should exist")
    }

    func testServiceDetailExportFormatToggle() throws {
        app.tabBars.buttons["All Services"].tap()
        XCTAssertTrue(app.navigationBars["All Services"].waitForExistence(timeout: 2))

        let row = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 2))
        row.tap()

        // Wait for detail to load
        let connection = app.staticTexts.matching(
            NSPredicate(format: "identifier == %@", "detail.connection")
        ).firstMatch
        XCTAssertTrue(connection.waitForExistence(timeout: 2))

        tapExportButton()
        assertPreviewAppears()

        // Verify format toggle exists and switch to JSON
        let jsonSegment = app.buttons["JSON"]
        XCTAssertTrue(jsonSegment.waitForExistence(timeout: 1), "JSON format option should exist")
        jsonSegment.tap()

        // Preview should still be visible after switching format
        let preview = app.otherElements["export.preview"]
        XCTAssertTrue(preview.exists, "Export preview should remain visible after format toggle")

        dismissPreview()
    }

    // MARK: - Full Navigation (merged from FullNavigationTests)

    func testFullTabCycleNavigation() throws {
        // Thread Tab
        app.tabBars.buttons["Thread"].tap()
        XCTAssertTrue(
            app.navigationBars["Thread Network"].waitForExistence(timeout: 2),
            "Thread Network navigation title should be visible"
        )
        XCTAssertTrue(
            app.staticTexts["Test Border Router"].waitForExistence(timeout: 2),
            "A border router should appear in the Thread tab"
        )

        // Bluetooth Tab
        app.tabBars.buttons["Bluetooth"].tap()
        XCTAssertTrue(
            app.navigationBars["Bluetooth"].waitForExistence(timeout: 2),
            "Bluetooth navigation title should be visible"
        )
        let bleDeviceRow = app.staticTexts["Test Matter Light"]
        if !bleDeviceRow.waitForExistence(timeout: 2) {
            app.swipeUp()
        }
        XCTAssertTrue(bleDeviceRow.waitForExistence(timeout: 2), "A BLE device should appear")

        // Matter Tab
        app.tabBars.buttons["Matter"].tap()
        XCTAssertTrue(
            app.navigationBars["Matter Devices"].waitForExistence(timeout: 2),
            "Matter Devices navigation title should be visible"
        )
        let matterDeviceRow = app.staticTexts["Test Light"]
        if !matterDeviceRow.waitForExistence(timeout: 2) {
            app.swipeUp()
        }
        XCTAssertTrue(matterDeviceRow.waitForExistence(timeout: 2), "A matter device should appear")

        // All Services Tab
        app.tabBars.buttons["All Services"].tap()
        let allServicesNavBar = app.navigationBars["All Services"]
        XCTAssertTrue(allServicesNavBar.waitForExistence(timeout: 2))

        let allServicesRow = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(allServicesRow.waitForExistence(timeout: 2), "An All Services row should appear")

        // Navigate to detail and back
        allServicesRow.tap()
        let detailConnection = app.staticTexts.matching(
            NSPredicate(format: "identifier == %@", "detail.connection")
        ).firstMatch
        let detailResolving = app.staticTexts.matching(
            NSPredicate(format: "identifier == %@", "detail.resolving")
        ).firstMatch
        let detailReached = detailConnection.waitForExistence(timeout: 2)
            || detailResolving.waitForExistence(timeout: 2)
        XCTAssertTrue(detailReached, "Should reach detail from All Services")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(allServicesNavBar.waitForExistence(timeout: 2), "Should return to All Services")
    }

    func testReverseDNSInfoNavigation() throws {
        app.tabBars.buttons["All Services"].tap()

        let serviceRow = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        XCTAssertTrue(serviceRow.waitForExistence(timeout: 2), "A service row should appear")
        serviceRow.tap()

        // Wait for detail to resolve
        let connectionSection = app.staticTexts.matching(
            NSPredicate(format: "identifier == %@", "detail.connection")
        ).firstMatch
        let resolvingIndicator = app.staticTexts.matching(
            NSPredicate(format: "identifier == %@", "detail.resolving")
        ).firstMatch
        let detailReached = connectionSection.waitForExistence(timeout: 2)
            || resolvingIndicator.waitForExistence(timeout: 2)
        XCTAssertTrue(detailReached, "Service detail should load")

        // Scroll to find Reverse DNS info button
        let infoButton = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "detail.reverseDNSInfo")
        ).firstMatch
        var found = infoButton.waitForExistence(timeout: 2)
        for _ in 0..<5 where !found {
            app.swipeUp()
            found = infoButton.waitForExistence(timeout: 1)
        }
        XCTAssertTrue(found, "Reverse DNS info button should be visible")
        infoButton.tap()

        let infoNavBar = app.navigationBars["About Reverse DNS Lookups"]
        XCTAssertTrue(infoNavBar.waitForExistence(timeout: 2), "About Reverse DNS screen should appear")

        let ptrText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "PTR")
        ).firstMatch
        XCTAssertTrue(ptrText.exists, "Info view should contain text about PTR lookups")

        // Navigate back
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(infoButton.waitForExistence(timeout: 2), "Should return to service detail")
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
