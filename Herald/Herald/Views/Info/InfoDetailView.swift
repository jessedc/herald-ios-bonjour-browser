import SwiftUI

struct InfoDetailView: View {
    let tab: InfoTab

    var body: some View {
        List {
            switch tab {
            case .allServices:
                ForEach(allServicesGroups, id: \.name) { group in
                    Section(group.name) {
                        ForEach(group.types, id: \.type) { entry in
                            queryRow(type: entry.type, description: entry.description)
                        }
                    }
                }
            case .thread, .matter:
                ForEach(queries, id: \.type) { query in
                    Section(query.label ?? "") {
                        queryRow(type: query.type, description: query.description)
                    }
                }
            }
        }
        .navigationTitle(title)
    }

    private func queryRow(type: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(type)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var title: String {
        switch tab {
        case .allServices: "All Services Queries"
        case .thread: "Thread Queries"
        case .matter: "Matter Queries"
        }
    }

    private var allServicesGroups: [ServiceTypeDescriptions.Group] {
        let plistTypes = Set(
            (Bundle.main.infoDictionary?["NSBonjourServices"] as? [String] ?? [])
                .filter { $0 != "_services._dns-sd._udp" }
        )
        return ServiceTypeDescriptions.groups.compactMap { group in
            let filtered = group.types.filter { plistTypes.contains($0.type) }
            guard !filtered.isEmpty else { return nil }
            return ServiceTypeDescriptions.Group(name: group.name, types: filtered)
        }
    }

    private var queries: [QueryInfo] {
        switch tab {
        case .allServices:
            return []
        case .thread:
            return [
                QueryInfo(
                    label: "Border Routers",
                    type: "_meshcop._udp.local.",
                    description: "Discovers Thread Border Routers via the Mesh Commissioning Protocol. "
                        + "TXT records provide network name (nn), extended PAN ID (xp), vendor (vn), "
                        + "model (mn), and Thread version (tv)."
                ),
                QueryInfo(
                    label: "TREL Peers",
                    type: "_trel._udp.local.",
                    description: "Discovers Thread Radio Encapsulation Link peers. TREL allows Thread "
                        + "devices to communicate over infrastructure links (Wi-Fi/Ethernet) "
                        + "as an alternative to 802.15.4 radio."
                ),
                QueryInfo(
                    label: "SRP Servers",
                    type: "_srpl-tls._tcp.local.",
                    description: "Discovers Service Registration Protocol servers over TLS. SRP allows "
                        + "Thread devices to register DNS service records via a border router, "
                        + "making them discoverable on the wider network."
                ),
                QueryInfo(
                    label: "Matter Commissioners",
                    type: "_matterc._udp.local.",
                    description: "Discovers Matter commissioner devices on the Thread network. "
                        + "TXT records provide device name (DN), vendor/product ID (VP), "
                        + "device type (DT), and commissioning mode (CM)."
                ),
            ]
        case .matter:
            return [
                QueryInfo(
                    label: "Matter over TCP",
                    type: "_matter._tcp.local.",
                    description: "Discovers Matter smart home devices advertising over TCP. "
                        + "TXT records provide discriminator (D), vendor/product ID (VP), "
                        + "commissioning mode (CM), device type (DT), and device name (DN)."
                ),
                QueryInfo(
                    label: "Matter over UDP",
                    type: "_matter._udp.local.",
                    description: "Discovers Matter smart home devices advertising over UDP. "
                        + "Uses the same TXT record fields as TCP. UDP is the primary transport "
                        + "for Matter devices on Thread and Wi-Fi networks."
                ),
            ]
        }
    }
}

private struct QueryInfo {
    var label: String?
    let type: String
    let description: String
}
