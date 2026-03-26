import SwiftUI

/// Shared navigation state that allows AppIntents (and other entry points)
/// to request a specific tab when the app foregrounds.
///
/// The intent sets a pending tab during `perform()` (which runs in-process,
/// even when the app is backgrounded). When the user taps the Siri result
/// and the app foregrounds, ContentView consumes the pending tab.
/// A timestamp ensures stale requests are ignored if the user dismisses
/// Siri without tapping into the app.
@Observable
@MainActor
final class NavigationState {
    static let shared = NavigationState()

    private(set) var pendingTab: AppTab?
    private var requestedAt: Date?

    /// Maximum age for a pending tab request to be honored (30 seconds).
    private let maxAge: TimeInterval = 30

    private init() {}

    func requestTab(_ tab: AppTab) {
        pendingTab = tab
        requestedAt = Date()
    }

    /// Returns and clears the pending tab if it was requested recently.
    func consumePendingTab() -> AppTab? {
        guard let tab = pendingTab, let requested = requestedAt,
              Date().timeIntervalSince(requested) < maxAge else {
            pendingTab = nil
            requestedAt = nil
            return nil
        }
        pendingTab = nil
        requestedAt = nil
        return tab
    }
}
