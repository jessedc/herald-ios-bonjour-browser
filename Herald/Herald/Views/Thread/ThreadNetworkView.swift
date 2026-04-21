import SwiftUI
import TipKit

struct ThreadNetworkView: View {
    @StateObject private var viewModel = ThreadNetworkViewModel()
    @Environment(\.scenePhase) private var scenePhase
    private let threadNetworkTip = ThreadNetworkTip()

    var body: some View {
        NavigationStack {
            List {
                TipView(threadNetworkTip)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                DiscoveryStatsSection(
                    chips: [
                        StatChipData(count: viewModel.networks.count, label: "Networks", icon: "network"),
                        StatChipData(count: viewModel.service.borderRouters.count, label: "Routers", icon: "wifi.router"),
                        StatChipData(count: viewModel.service.trelPeers.count, label: "TREL", icon: "antenna.radiowaves.left.and.right"),
                        StatChipData(count: viewModel.service.commissionables.count, label: "Commissionable", icon: "dot.radiowaves.right"),
                        StatChipData(count: viewModel.service.srpServers.count, label: "SRP", icon: "server.rack")
                    ],
                    errors: viewModel.errors
                )

                // Border Routers — grouped by Thread network (Extended PAN ID)
                ForEach(viewModel.networks) { network in
                    Section {
                        // Config drift / mismatch warnings
                        ForEach(network.warnings, id: \.self) { warning in
                            Label(warning, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .listRowBackground(Color.orange.opacity(0.1))
                        }

                        ForEach(network.routers) { router in
                            NavigationLink(value: router.serviceInstance) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(router.name)
                                        .font(.headline)
                                    Group {
                                        if let vendor = router.vendor {
                                            LabeledContent("Vendor", value: vendor)
                                        }
                                        if let model = router.modelName {
                                            LabeledContent("Model", value: model)
                                        }
                                        if let version = router.threadVersion {
                                            LabeledContent("Thread Version", value: version)
                                        }
                                        if !router.stateBitmapFlags.isEmpty {
                                            LabeledContent("State", value: router.stateBitmapFlags.joined(separator: ", "))
                                        }
                                        if let dn = router.domainName {
                                            LabeledContent("Domain", value: dn)
                                        }
                                        if router.backboneRouterFlag != nil {
                                            LabeledContent("Backbone Router", value: "Yes")
                                        }
                                        if let at = router.activeTimestamp, network.hasConfigDrift {
                                            LabeledContent("Active Timestamp", value: at)
                                                .foregroundStyle(.orange)
                                        }
                                    }
                                    .font(.caption)
                                }
                                .padding(.vertical, 2)
                            }
                            .accessibilityIdentifier("thread.router.row.\(router.name)")
                        }
                    } header: {
                        HStack {
                            Text("\(network.networkName) — \(network.routers.count) \(network.routers.count == 1 ? "router" : "routers")")
                            if !network.warnings.isEmpty {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption2)
                            }
                        }
                    } footer: {
                        if let xp = network.extendedPANID {
                            Text("Extended PAN ID: \(xp)")
                                .font(.caption2)
                        } else {
                            Text("Extended PAN ID: not advertised")
                                .font(.caption2)
                        }
                    }
                }

                // TREL Peers
                if !viewModel.service.trelPeers.isEmpty {
                    Section("TREL Peers (\(viewModel.service.trelPeers.count))") {
                        ForEach(viewModel.service.trelPeers) { peer in
                            NavigationLink(value: peer.serviceInstance) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(peer.name)
                                        .font(.headline)
                                    if let hostname = peer.hostname {
                                        LabeledContent("Hostname", value: hostname)
                                            .font(.caption)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            .accessibilityIdentifier("thread.trel.row.\(peer.name)")
                        }
                    }
                }

                // Matter Commissionable Devices
                if !viewModel.service.commissionables.isEmpty {
                    Section("Commissionable (\(viewModel.service.commissionables.count))") {
                        ForEach(viewModel.service.commissionables) { comm in
                            NavigationLink(value: comm.serviceInstance) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(comm.name)
                                        .font(.headline)
                                    Group {
                                        if let dn = comm.deviceName {
                                            LabeledContent("Device Name", value: dn)
                                        }
                                        if let vp = comm.vendorProductID {
                                            if let vendorName = comm.vendorName {
                                                LabeledContent("Vendor/Product", value: "\(vendorName) (\(vp))")
                                            } else {
                                                LabeledContent("Vendor/Product", value: vp)
                                            }
                                        }
                                        if comm.deviceType != nil {
                                            LabeledContent("Device Type", value: comm.deviceTypeDescription)
                                        }
                                    }
                                    .font(.caption)
                                }
                                .padding(.vertical, 2)
                            }
                            .accessibilityIdentifier("thread.commissionable.row.\(comm.name)")
                        }
                    }
                }

                // SRP Servers
                if !viewModel.service.srpServers.isEmpty {
                    Section("SRP Servers (\(viewModel.service.srpServers.count))") {
                        ForEach(viewModel.service.srpServers) { server in
                            NavigationLink(value: server.serviceInstance) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(server.name)
                                        .font(.headline)
                                    Group {
                                        if let hostname = server.hostname {
                                            LabeledContent("Hostname", value: hostname)
                                        }
                                        if server.port > 0 {
                                            LabeledContent("Port", value: "\(server.port)")
                                        }
                                    }
                                    .font(.caption)
                                }
                                .padding(.vertical, 2)
                            }
                            .accessibilityIdentifier("thread.srp.row.\(server.name)")
                        }
                    }
                }
            }
            .animation(
                .default,
                value: viewModel.service.borderRouters.count
                    + viewModel.service.trelPeers.count
                    + viewModel.service.commissionables.count
                    + viewModel.service.srpServers.count
            )
            .navigationDestination(for: ServiceInstance.self) { instance in
                ServiceDetailView(instance: instance)
            }
            .navigationTitle("Thread Network")
            .overlay {
                let allEmpty = viewModel.service.borderRouters.isEmpty
                    && viewModel.service.trelPeers.isEmpty
                    && viewModel.service.srpServers.isEmpty
                    && viewModel.service.commissionables.isEmpty
                if viewModel.service.isSearching && allEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Searching for Thread devices...")
                            .foregroundStyle(.secondary)
                    }
                } else if !viewModel.service.isSearching && allEmpty
                    && viewModel.errors.isEmpty {
                    ContentUnavailableView(
                        "No Thread Devices Found",
                        systemImage: "wifi.router"
                    )
                }
            }
            .exportable(title: viewModel.exportTitle, text: { viewModel.exportText }, json: { viewModel.exportJSON ?? "" })
            .refreshable {
                viewModel.refresh()
            }
            .task { viewModel.start() }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active: viewModel.start()
                case .background: viewModel.stop()
                default: break
                }
            }
        }
    }
}
