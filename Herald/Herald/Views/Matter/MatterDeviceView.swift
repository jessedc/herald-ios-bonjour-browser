import SwiftUI

struct MatterDeviceView: View {
    @StateObject private var viewModel = MatterDeviceViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            List {
                DiscoveryStatsSection(
                    chips: statsChips,
                    errors: viewModel.errors
                )

                ForEach(Array(viewModel.devicesByFabric.enumerated()), id: \.element.id) { index, group in
                    Section(sectionHeader(for: group, index: index, totalFabrics: viewModel.fabricCount)) {
                        ForEach(group.devices) { device in
                            NavigationLink(value: device.serviceInstance) {
                                MatterDeviceRow(device: device)
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
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active: viewModel.start()
                case .background: viewModel.stop()
                default: break
                }
            }
        }
    }

    private var statsChips: [StatChipData] {
        [
            StatChipData(count: viewModel.service.devices.count, label: "Devices", icon: "house"),
            StatChipData(count: viewModel.fabricCount, label: "Fabrics", icon: "network"),
        ]
    }

    private func sectionHeader(for group: MatterDeviceFabricGroup, index: Int, totalFabrics: Int) -> String {
        if group.fabricID != nil {
            let count = group.devices.count
            let deviceWord = count == 1 ? "Device" : "Devices"
            if totalFabrics == 1 {
                return "Operational Devices (\(count))"
            }
            return "Fabric \(index + 1) — \(count) \(deviceWord)"
        }
        return "Commissionable Devices (\(group.devices.count))"
    }
}

// MARK: - Device Row

private struct MatterDeviceRow: View {
    let device: MatterDevice

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(device.displayName)
                    .font(.headline)
                if device.isBatteryDevice {
                    Label("Battery", systemImage: "battery.50")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.orange.opacity(0.12), in: Capsule())
                }
            }

            Group {
                if device.isOperational, let parsed = device.parsedInstanceName {
                    LabeledContent("Fabric ID", value: parsed.truncatedFabricID)
                    LabeledContent("Node ID", value: parsed.truncatedNodeID)
                }

                LabeledContent("Service", value: device.serviceType)

                if let vp = device.vendorProductID {
                    if let vendorName = device.vendorName {
                        LabeledContent("Vendor/Product", value: "\(vendorName) (\(vp))")
                    } else {
                        LabeledContent("Vendor/Product", value: vp)
                    }
                }

                if device.deviceType != nil {
                    LabeledContent("Device Type", value: device.deviceTypeDescription)
                }

                if let cm = device.commissioningMode, cm != "0" {
                    LabeledContent("Commissioning", value: device.commissioningModeDescription)
                }

                if let d = device.discriminator {
                    LabeledContent("Discriminator", value: d)
                }

                if let idle = device.sessionIdleDescription {
                    LabeledContent("Session Idle", value: idle)
                }

                if let active = device.sessionActiveDescription {
                    LabeledContent("Session Active", value: active)
                }

                if let hints = device.pairingHintDescriptions {
                    LabeledContent("Pairing Hints", value: hints.joined(separator: ", "))
                }
            }
            .font(.caption)
        }
        .padding(.vertical, 2)
    }
}
