import AppIntents

/// Siri intent that provides a summary of Matter devices and Thread border routers on the local network.
/// Available via Siri phrases and the Shortcuts app.
struct GetNetworkSummaryIntent: AppIntent {

    static var title: LocalizedStringResource = "Network Summary"

    static var description = IntentDescription(
        "Summarizes the Matter devices and Thread infrastructure on your local network"
    )

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let matterCount: Int
        let threadResult: ThreadBorderRouterCounter.Result
        do {
            async let matter = MatterDeviceCounter.countDevices()
            async let thread = ThreadBorderRouterCounter.countRouters()
            matterCount = try await matter
            threadResult = try await thread
        } catch {
            return .result(
                dialog: "Herald couldn't scan the network. Please open the app first to grant network access, then try again."
            )
        }

        let message = buildSummaryMessage(
            matterCount: matterCount,
            threadCount: threadResult.count,
            networkNames: threadResult.networkNames
        )

        return .result(dialog: IntentDialog(stringLiteral: message))
    }

    private func buildSummaryMessage(
        matterCount: Int,
        threadCount: Int,
        networkNames: Set<String>
    ) -> String {
        if matterCount == 0 && threadCount == 0 {
            return "Herald didn't find any Matter devices or Thread border routers on your network."
        }

        var parts: [String] = []

        switch matterCount {
        case 0:
            break
        case 1:
            parts.append("1 Matter device")
        default:
            parts.append("\(matterCount) Matter devices")
        }

        switch threadCount {
        case 0:
            break
        case 1:
            parts.append("1 Thread border router")
        default:
            parts.append("\(threadCount) Thread border routers")
        }

        var message = "Herald found \(parts.joined(separator: " and ")) on your network"

        if !networkNames.isEmpty {
            let sorted = networkNames.sorted()
            if sorted.count == 1, let name = sorted.first {
                message += " (Thread network: \(name))"
            } else {
                message += " (Thread networks: \(sorted.joined(separator: ", ")))"
            }
        }

        message += "."
        return message
    }
}
