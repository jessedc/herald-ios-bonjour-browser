import Foundation

/// Single source of truth for UI testing launch argument detection.
/// Replaces scattered `ProcessInfo.processInfo.arguments.contains(...)` checks.
enum UITestingMode {
    case errors       // -UITestingErrors: mock data + simulated errors
    case mockData     // -UITesting: mock data only
    case screenshots  // -UITestingScreenshots: realistic mock data for App Store screenshots
    case disabled     // Production

    static let current: UITestingMode = {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-UITestingErrors") { return .errors }
        if args.contains("-UITestingScreenshots") { return .screenshots }
        if args.contains("-UITesting") { return .mockData }
        return .disabled
    }()

    var isActive: Bool { self != .disabled }
}
