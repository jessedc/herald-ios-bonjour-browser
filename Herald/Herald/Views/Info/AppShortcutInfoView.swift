import SwiftUI

struct AppShortcutInfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(
                    "Herald includes Siri shortcuts for quick network status checks. "
                    + "You can trigger them hands-free with Siri "
                    + "or add them to automations in the Shortcuts app."
                )

                // Count Matter Devices
                Text("Count Matter Devices")
                    .font(.headline)

                bulletPoint("\"How many Matter devices are on my network with Herald\"")
                bulletPoint("\"Count Matter devices with Herald\"")
                bulletPoint("\"Find Matter devices with Herald\"")

                Text(
                    "Performs a 4-second Bonjour browse across three Matter service types "
                    + "(_matter._tcp, _matter._udp, and _matterd._udp), deduplicates by device name, "
                    + "and returns the total count. Tap the result to open the Matter tab."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Divider()

                // Count Thread Border Routers
                Text("Count Thread Border Routers")
                    .font(.headline)

                bulletPoint("\"How many Thread border routers are on my network with Herald\"")
                bulletPoint("\"Count Thread routers with Herald\"")
                bulletPoint("\"Find Thread border routers with Herald\"")

                Text(
                    "Browses for _meshcop._udp services to count Thread border routers, "
                    + "then resolves each to report the Thread network name. "
                    + "Tap the result to open the Thread tab."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Divider()

                // Network Summary
                Text("Network Summary")
                    .font(.headline)

                bulletPoint("\"What's on my network with Herald\"")
                bulletPoint("\"Scan my network with Herald\"")
                bulletPoint("\"Network summary with Herald\"")

                Text(
                    "Runs both Matter and Thread scans concurrently and returns a combined summary "
                    + "of devices and border routers found on your network."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Divider()

                Text(
                    "All shortcuts are also available in the Shortcuts app under Herald, "
                    + "where you can incorporate them into custom automations — for example, "
                    + "running a network check when you arrive home."
                )
            }
            .padding()
        }
        .navigationTitle("App Shortcuts")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\u{2022}")
            Text(text)
                .italic()
        }
        .padding(.leading, 4)
    }
}
