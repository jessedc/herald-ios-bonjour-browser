import SwiftUI

struct MatterDeviceView: View {
    @StateObject private var viewModel = MatterDeviceViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            List {
                DiscoveryStatsSection(
                    chips: [
                        StatChipData(count: viewModel.service.devices.count, label: "Devices", icon: "house")
                    ],
                    errors: viewModel.errors
                )

                if !viewModel.service.devices.isEmpty {
                    Section("Matter Devices (\(viewModel.service.devices.count))") {
                        ForEach(viewModel.service.devices) { device in
                            NavigationLink(value: device.serviceInstance) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(device.name)
                                        .font(.headline)
                                    Group {
                                        LabeledContent("Service", value: device.serviceType)
                                        if let vp = device.vendorProductID {
                                            if let vendorName = device.vendorName {
                                                LabeledContent("Vendor/Product", value: "\(vendorName) (\(vp))")
                                            } else {
                                                LabeledContent("Vendor/Product", value: vp)
                                            }
                                        }
                                        if let dn = device.deviceName {
                                            LabeledContent("Device Name", value: dn)
                                        }
                                        if device.deviceType != nil {
                                            LabeledContent("Device Type", value: device.deviceTypeDescription)
                                        }
                                        LabeledContent("Commissioning", value: device.commissioningModeDescription)
                                        if let d = device.discriminator {
                                            LabeledContent("Discriminator", value: d)
                                        }
                                    }
                                    .font(.caption)
                                }
                                .padding(.vertical, 2)
                            }
                            .accessibilityIdentifier("matter.device.row.\(device.name)")
                        }
                    }
                }
            }
            .animation(.default, value: viewModel.service.devices.count)
            .navigationDestination(for: ServiceInstance.self) { instance in
                ServiceDetailView(instance: instance)
            }
            .navigationTitle("Matter Devices")
            .overlay {
                if viewModel.service.isSearching && viewModel.service.devices.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Searching for Matter devices...")
                            .foregroundStyle(.secondary)
                    }
                } else if !viewModel.service.isSearching && viewModel.service.devices.isEmpty
                    && viewModel.errors.isEmpty {
                    ContentUnavailableView(
                        "No Matter Devices Found",
                        systemImage: "house"
                    )
                }
            }
            .exportable(title: viewModel.exportTitle, text: { viewModel.exportText }, json: { viewModel.exportJSON ?? "" })
            .refreshable {
                viewModel.refresh()
            }
            .onAppear { viewModel.start() }
            .onDisappear { viewModel.stop() }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active { viewModel.refresh() }
            }
        }
    }
}
