import AppIntents

/// Siri intent that counts Thread border routers visible on the local network.
/// Available via Siri phrases and the Shortcuts app.
struct CountThreadBorderRoutersIntent: AppIntent {

    static var title: LocalizedStringResource = "Count Thread Border Routers"

    static var description = IntentDescription(
        "Counts Thread border routers visible on your local network"
    )

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await NavigationState.shared.requestTab(.thread)
        let result: ThreadBorderRouterCounter.Result
        do {
            result = try await ThreadBorderRouterCounter.countRouters()
        } catch {
            return .result(
                dialog: "Herald couldn't scan the network. Please open the app first to grant network access, then try again."
            )
        }

        let message: String
        switch result.count {
        case 0:
            message = "Herald didn't find any Thread border routers on your network."
        case 1:
            if let networkName = result.networkNames.first {
                message = "Herald found 1 Thread border router on your network, on the \(networkName) network."
            } else {
                message = "Herald found 1 Thread border router on your network."
            }
        default:
            let networkSuffix: String
            if result.networkNames.isEmpty {
                networkSuffix = ""
            } else if result.networkNames.count == 1, let name = result.networkNames.first {
                networkSuffix = " on the \(name) network"
            } else {
                let sorted = result.networkNames.sorted()
                networkSuffix = " across networks: \(sorted.joined(separator: ", "))"
            }
            message = "Herald found \(result.count) Thread border routers on your network\(networkSuffix)."
        }

        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}
