import AppIntents

/// Siri intent that counts Matter smart home devices visible on the local network.
/// Available via Siri phrases and the Shortcuts app.
struct CountMatterDevicesIntent: AppIntent {

    static var title: LocalizedStringResource = "Count Matter Devices"

    static var description = IntentDescription(
        "Counts Matter smart home devices visible on your local network"
    )

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await NavigationState.shared.requestTab(.matter)
        let count: Int
        do {
            count = try await MatterDeviceCounter.countDevices()
        } catch {
            return .result(
                dialog: "Herald couldn't scan the network. Please open the app first to grant network access, then try again."
            )
        }

        let message: String
        switch count {
        case 0:
            message = "Herald didn't find any Matter devices on your network."
        case 1:
            message = "Herald found 1 Matter device on your network."
        default:
            message = "Herald found \(count) Matter devices on your network."
        }

        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}
