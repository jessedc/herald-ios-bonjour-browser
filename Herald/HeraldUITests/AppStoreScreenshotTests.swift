import XCTest

/// Screenshot tests that use realistic mock data for deterministic App Store screenshots.
///
/// Run with the "AppStore Screenshots" test plan:
///
/// ```
/// xcodebuild -project Herald/Herald.xcodeproj \
///   -scheme Herald -destination 'platform=iOS Simulator,name=iPhone 17' \
///   -testPlan 'AppStore Screenshots' test
/// ```
final class AppStoreScreenshotTests: XCTestCase {

    // MARK: - Configuration

    /// Name of the service to tap on the All Services list for the detail screenshot.
    /// Set to nil to tap the first available row.
    static let allServicesItemName: String? = "HP LaserJet Pro"

    // MARK: - Setup

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = true
        app.launchArguments += ["-UITestingScreenshots"]
        app.launch()
    }

    // MARK: - Screenshots

    func test01_AllServices() throws {
        guard tapTab(named: "All Services") else {
            XCTFail("All Services tab not found")
            return
        }

        let navBar = app.navigationBars["All Services"]
        guard navBar.waitForExistence(timeout: 5) else {
            XCTFail("All Services nav bar did not appear")
            return
        }

        // Mock data loads instantly, just wait for layout
        let anyRow = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        guard anyRow.waitForExistence(timeout: 5) else {
            XCTFail("No services appeared")
            return
        }

        captureScreenshot(named: "01_AllServices")
    }

    func test02_ServiceDetail() throws {
        guard tapTab(named: "All Services") else {
            XCTFail("All Services tab not found")
            return
        }

        let anyRow = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        guard anyRow.waitForExistence(timeout: 5) else {
            XCTFail("No services appeared")
            return
        }

        // Tap the configured item or fall back to first row
        let rowToTap: XCUIElement
        if let name = Self.allServicesItemName {
            let namedRow = app.buttons.matching(NSPredicate(
                format: "identifier == %@ AND label CONTAINS[cd] %@",
                "allServices.row", name
            )).firstMatch
            if namedRow.waitForExistence(timeout: 3) {
                rowToTap = namedRow
            } else {
                let namedText = app.staticTexts[name]
                if namedText.waitForExistence(timeout: 3) {
                    namedText.tap()
                    waitForDetailAndCapture()
                    return
                }
                rowToTap = anyRow
            }
        } else {
            rowToTap = anyRow
        }

        rowToTap.tap()
        waitForDetailAndCapture()
    }

    func test03_ThreadNetwork() throws {
        guard tapTab(named: "Thread") else {
            XCTFail("Thread tab not found")
            return
        }

        let navBar = app.navigationBars["Thread Network"]
        guard navBar.waitForExistence(timeout: 5) else {
            XCTFail("Thread Network nav bar did not appear")
            return
        }

        // Mock data loads on viewModel.start() triggered by onAppear
        // NavigationLinks appear as buttons in the accessibility hierarchy
        let routerRow = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "thread.router.row.")
        ).firstMatch
        guard routerRow.waitForExistence(timeout: 5) else {
            captureScreenshot(named: "03_ThreadNetwork_debug")
            XCTFail("Thread border routers did not appear")
            return
        }

        captureScreenshot(named: "03_ThreadNetwork")
    }

    func test04_MatterDevices() throws {
        guard tapTab(named: "Matter") else {
            XCTFail("Matter tab not found")
            return
        }

        let navBar = app.navigationBars["Matter Devices"]
        guard navBar.waitForExistence(timeout: 5) else {
            XCTFail("Matter Devices nav bar did not appear")
            return
        }

        // Mock data loads on viewModel.start() triggered by onAppear
        // NavigationLinks appear as buttons in the accessibility hierarchy
        let deviceRow = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "matter.device.row.")
        ).firstMatch
        guard deviceRow.waitForExistence(timeout: 10) else {
            captureScreenshot(named: "04_MatterDevices_debug")
            XCTFail("Matter devices did not appear")
            return
        }

        captureScreenshot(named: "04_MatterDevices")
    }

    func test05_TextExport() throws {
        guard tapTab(named: "All Services") else {
            XCTFail("All Services tab not found")
            return
        }

        let anyRow = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "allServices.row")
        ).firstMatch
        guard anyRow.waitForExistence(timeout: 5) else {
            XCTFail("No services appeared")
            return
        }

        // Navigate to the configured service's detail view
        let rowToTap: XCUIElement
        if let name = Self.allServicesItemName {
            let namedRow = app.buttons.matching(NSPredicate(
                format: "identifier == %@ AND label CONTAINS[cd] %@",
                "allServices.row", name
            )).firstMatch
            rowToTap = namedRow.waitForExistence(timeout: 3) ? namedRow : anyRow
        } else {
            rowToTap = anyRow
        }
        rowToTap.tap()

        // Wait for the detail view to resolve
        let connection = app.staticTexts.matching(
            NSPredicate(format: "identifier == %@", "detail.connection")
        ).firstMatch
        guard connection.waitForExistence(timeout: 5) else {
            XCTFail("Detail view did not load")
            return
        }

        // Tap the export button in the detail toolbar
        let exportButton = app.buttons["export.button"]
        guard exportButton.waitForExistence(timeout: 3) else {
            XCTFail("Export button not found")
            return
        }
        exportButton.tap()

        // Wait for the full-screen export preview to appear
        let preview = app.otherElements["export.preview"]
        guard preview.waitForExistence(timeout: 5) else {
            XCTFail("Export preview did not appear")
            return
        }

        captureScreenshot(named: "05_TextExport")
    }

    // MARK: - Helpers

    /// Taps a tab by name. On iPhone, tabs live in the bottom tab bar. On iPad (iOS 18+),
    /// the floating tab bar uses `_UIFloatingTabBarItemView` which XCTest may report as
    /// "Other" rather than "Button", so we fall back to a label-based query across all types.
    private func tapTab(named name: String) -> Bool {
        // iPhone: standard bottom tab bar
        let tabBarButton = app.tabBars.buttons[name]
        if tabBarButton.waitForExistence(timeout: 3) {
            tabBarButton.tap()
            return true
        }
        // iPad fallback: floating tab bar items may be typed as "Other"
        let predicate = NSPredicate(format: "label == %@", name)
        let match = app.descendants(matching: .any).matching(predicate).firstMatch
        if match.waitForExistence(timeout: 3) {
            match.tap()
            return true
        }
        return false
    }

    private func waitForDetailAndCapture() {
        let connection = app.staticTexts.matching(
            NSPredicate(format: "identifier == %@", "detail.connection")
        ).firstMatch

        // Mock resolution is instant
        guard connection.waitForExistence(timeout: 5) else {
            XCTFail("Detail view did not load")
            captureScreenshot(named: "02_ServiceDetail")
            return
        }

        captureScreenshot(named: "02_ServiceDetail")
    }

    private func captureScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
