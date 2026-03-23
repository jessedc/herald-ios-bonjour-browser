import SwiftUI

struct ThreadNetworkView: View {
    @StateObject private var viewModel = ThreadNetworkViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            List {
                DiscoveryStatsSection(
                    chips: [
                        StatChipData(count: viewModel.service.borderRouters.count, label: "Routers", icon: "wifi.router"),
                        StatChipData(count: viewModel.service.trelPeers.count, label: "TREL", icon: "antenna.radiowaves.left.and.right"),
                        StatChipData(count: viewModel.service.commissioners.count, label: "Commissioners", icon: "dot.radiowaves.right"),
                        StatChipData(count: viewModel.service.srpServers.count, label: "SRP", icon: "server.rack")
                    ],
                    errors: viewModel.errors
                )

                // Border Routers
                if !viewModel.service.borderRouters.isEmpty {
                    Section("Border Routers (\(viewModel.service.borderRouters.count))") {
                        ForEach(viewModel.service.borderRouters) { router in
                            NavigationLink(value: router.serviceInstance) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(router.name)
                                        .font(.headline)
                                    Group {
                                        LabeledContent("Network", value: router.networkName)
                                        if let vendor = router.vendor {
                                            LabeledContent("Vendor", value: vendor)
                                        }
                                        if let model = router.modelName {
                                            LabeledContent("Model", value: model)
                                        }
                                        if let version = router.threadVersion {
                                            LabeledContent("Thread Version", value: version)
                                        }
                                        if !router.extendedPANID.isEmpty {
                                            LabeledContent("Extended PAN ID", value: router.extendedPANID)
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
                                    }
                                    .font(.caption)
                                }
                                .padding(.vertical, 2)
                            }
                            .accessibilityIdentifier("thread.router.row.\(router.name)")
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

                // Matter Commissioners
                if !viewModel.service.commissioners.isEmpty {
                    Section("Commissioners (\(viewModel.service.commissioners.count))") {
                        ForEach(viewModel.service.commissioners) { comm in
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
                            .accessibilityIdentifier("thread.commissioner.row.\(comm.name)")
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
            .animation(.default, value: viewModel.service.borderRouters.count + viewModel.service.trelPeers.count + viewModel.service.commissioners.count + viewModel.service.srpServers.count)
            .navigationDestination(for: ServiceInstance.self) { instance in
                ServiceDetailView(instance: instance)
            }
            .navigationTitle("Thread Network")
            .overlay {
                let allEmpty = viewModel.service.borderRouters.isEmpty
                    && viewModel.service.trelPeers.isEmpty
                    && viewModel.service.srpServers.isEmpty
                    && viewModel.service.commissioners.isEmpty
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
            .onAppear { viewModel.start() }
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
