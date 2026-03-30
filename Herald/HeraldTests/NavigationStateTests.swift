import XCTest
@testable import Herald

@MainActor
final class NavigationStateTests: XCTestCase {

    func testRequestTabStoresPendingTab() {
        let state = NavigationState.shared
        state.requestTab(.thread)
        XCTAssertEqual(state.pendingTab, .thread)
        // Clean up
        _ = state.consumePendingTab()
    }

    func testConsumePendingTabReturnsAndClears() {
        let state = NavigationState.shared
        state.requestTab(.matter)
        let consumed = state.consumePendingTab()
        XCTAssertEqual(consumed, .matter)
        XCTAssertNil(state.pendingTab)
    }

    func testConsumePendingTabReturnsNilWhenEmpty() {
        let state = NavigationState.shared
        // Ensure clean state
        _ = state.consumePendingTab()
        let result = state.consumePendingTab()
        XCTAssertNil(result)
    }
}
