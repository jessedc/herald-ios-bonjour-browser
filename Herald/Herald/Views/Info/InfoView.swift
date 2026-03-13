import SwiftUI

struct InfoView: View {
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
                
                Section("App Info") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                            .foregroundStyle(.secondary)
                    }
                    Link(destination: URL(string: "https://heraldapp.app")!) {
                        Label("Website", systemImage: "globe")
                    }
                    Link(destination: URL(string: "https://github.com/jessedc/herald-ios-bonjour-browser")!) {
                        Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            }
            .navigationTitle("Info")
            .navigationDestination(for: InfoTab.self) { tab in
                InfoDetailView(tab: tab)
            }
        }
    }
}

enum InfoTab: Hashable {
    case allServices
    case thread
    case matter
}
