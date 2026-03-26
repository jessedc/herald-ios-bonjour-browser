import SwiftUI
import TipKit

struct InfoView: View {
    private let siriShortcutTip = SiriShortcutTip()
    @State private var showTipsResetConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    // swiftlint:disable:next line_length
                    Text("Herald discovers services on your local network using DNS-SD (DNS Service Discovery) and multicast DNS (mDNS/Bonjour). It browses for advertised service types, resolves instances to hostnames and IP addresses, and displays their metadata.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Queries by Tab") {
                    NavigationLink(value: InfoTab.allServices) {
                        Label("All Services", systemImage: "list.bullet.rectangle")
                    }
                    NavigationLink(value: InfoTab.thread) {
                        Label("Thread", systemImage: "point.3.connected.trianglepath.dotted")
                    }
                    NavigationLink(value: InfoTab.matter) {
                        Label("Matter", systemImage: "house")
                    }
                }

                Section("App Shortcuts") {
                    TipView(siriShortcutTip)
                    NavigationLink(value: AppShortcutInfoDestination()) {
                        Label("Count Matter Devices", systemImage: "waveform.and.mic")
                    }
                    NavigationLink(value: AppShortcutInfoDestination()) {
                        Label("Count Thread Routers", systemImage: "wifi.router")
                    }
                    NavigationLink(value: AppShortcutInfoDestination()) {
                        Label("Network Summary", systemImage: "network")
                    }
                }

                Section("App Settings") {
                    Button {
                        showTipsResetConfirmation = true
                    } label: {
                        Label("Reset Tips", systemImage: "lightbulb")
                    }
                    .confirmationDialog("Reset all tips?", isPresented: $showTipsResetConfirmation) {
                        Button("Reset Tips") {
                            try? Tips.resetDatastore()
                        }
                    } message: {
                        Text("All educational tips will appear again.")
                    }
                }
                
                Section("More Info") {
                    Link(destination: URL(string: "https://heraldapp.app")!) {
                        Label("Website", systemImage: "globe")
                    }
                    Link(destination: URL(string: "https://github.com/jessedc/herald-ios-bonjour-browser")!) {
                        Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }

                Section {
                    Text("Herald v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Info")
            .navigationDestination(for: InfoTab.self) { tab in
                InfoDetailView(tab: tab)
            }
            .navigationDestination(for: AppShortcutInfoDestination.self) { _ in
                AppShortcutInfoView()
            }
        }
    }
}

enum InfoTab: Hashable {
    case allServices
    case thread
    case matter
}

struct AppShortcutInfoDestination: Hashable {}
