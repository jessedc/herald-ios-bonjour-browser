import AppIntents

/// Registers Herald's App Intents as Siri shortcuts with suggested phrases.
struct HeraldShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CountMatterDevicesIntent(),
            phrases: [
                "How many Matter devices are on my network with \(.applicationName)",
                "Count Matter devices with \(.applicationName)",
                "Find Matter devices with \(.applicationName)"
            ],
            shortTitle: "Count Matter Devices",
            systemImageName: "house"
        )

        AppShortcut(
            intent: CountThreadBorderRoutersIntent(),
            phrases: [
                "How many Thread border routers are on my network with \(.applicationName)",
                "Count Thread routers with \(.applicationName)",
                "Find Thread border routers with \(.applicationName)"
            ],
            shortTitle: "Count Thread Routers",
            systemImageName: "wifi.router"
        )

        AppShortcut(
            intent: GetNetworkSummaryIntent(),
            phrases: [
                "What's on my network with \(.applicationName)",
                "Scan my network with \(.applicationName)",
                "Network summary with \(.applicationName)"
            ],
            shortTitle: "Network Summary",
            systemImageName: "network"
        )
    }
}
