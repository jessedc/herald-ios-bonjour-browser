/// Services that inject mock data and/or errors when running under UI tests.
///
/// Conforming types implement `applyUITestingMockData()` and `applyUITestingErrors()`
/// with their specific mock payloads. The default `applyUITestingOverrides()` method
/// checks `UITestingMode.current` and dispatches to the appropriate method.
@MainActor
protocol UITestingConfigurable: AnyObject {
    func applyUITestingMockData()
    func applyUITestingErrors()
    func applyScreenshotMockData()
}

extension UITestingConfigurable {
    /// Default screenshot mock data falls back to regular mock data.
    func applyScreenshotMockData() {
        applyUITestingMockData()
    }

    /// Returns `true` if mock data was injected (caller should return early).
    func applyUITestingOverrides() -> Bool {
        switch UITestingMode.current {
        case .errors:
            applyUITestingErrors()
            return true
        case .screenshots:
            applyScreenshotMockData()
            return true
        case .mockData:
            applyUITestingMockData()
            return true
        case .disabled:
            return false
        }
    }
}
