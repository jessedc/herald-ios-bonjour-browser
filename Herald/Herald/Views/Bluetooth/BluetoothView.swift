import CoreBluetooth
import SwiftUI
import TipKit

struct BluetoothView: View {
    @StateObject private var viewModel = BLEDiscoveryViewModel()
    @Environment(\.scenePhase) private var scenePhase
    private let bluetoothTip = BluetoothScanTip()

    var body: some View {
        NavigationStack {
            List {
                TipView(bluetoothTip)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                DiscoveryStatsSection(
                    chips: statsChips,
                    errors: viewModel.errors
                )

                Section("Matter Commissioning (\(viewModel.peripherals.count))") {
                    ForEach(viewModel.peripherals) { peripheral in
                        NavigationLink(value: peripheral) {
                            BLEPeripheralRow(peripheral: peripheral)
                        }
                        .accessibilityIdentifier("bluetooth.device.row.\(peripheral.identifier.uuidString)")
                    }
                }
            }
            .animation(.default, value: viewModel.service.peripherals.count)
            .navigationDestination(for: BLEPeripheral.self) { peripheral in
                BLEPeripheralDetailView(peripheral: peripheral)
            }
            .navigationTitle("Bluetooth")
            .overlay {
                if !isBluetoothAvailable {
                    ContentUnavailableView(
                        "Bluetooth Unavailable",
                        systemImage: "antenna.radiowaves.left.and.right.slash",
                        description: Text(unavailableDescription)
                    )
                } else if viewModel.service.isScanning && viewModel.service.peripherals.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Scanning for Matter commissioning devices...")
                            .foregroundStyle(.secondary)
                    }
                } else if !viewModel.service.isScanning && viewModel.service.peripherals.isEmpty
                    && viewModel.errors.isEmpty {
                    ContentUnavailableView(
                        "No Commissioning Devices",
                        systemImage: "antenna.radiowaves.left.and.right",
                        description: Text("No Matter devices in commissioning mode found nearby.")
                    )
                }
            }
            .exportable(title: viewModel.exportTitle, text: { viewModel.exportText }, json: { viewModel.exportJSON ?? "" })
            .refreshable {
                viewModel.refresh()
            }
            .task {
                viewModel.start()
            }
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
            StatChipData(
                count: viewModel.peripherals.count,
                label: "Devices",
                icon: "house"
            ),
        ]
    }

    private var isBluetoothAvailable: Bool {
        let state = viewModel.service.bluetoothState
        return state == .poweredOn || state == .unknown
    }

    private var unavailableDescription: String {
        switch viewModel.service.bluetoothState {
        case .poweredOff:
            return "Bluetooth is turned off. Enable it in Settings to scan for nearby devices."
        case .unauthorized:
            return "Herald doesn't have permission to use Bluetooth. Grant access in Settings > Privacy > Bluetooth."
        case .unsupported:
            return "Bluetooth is not available on this device. BLE scanning requires a physical device."
        default:
            return "Bluetooth is currently unavailable."
        }
    }

}

// MARK: - Peripheral Row

private struct BLEPeripheralRow: View {
    let peripheral: BLEPeripheral

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(peripheral.displayName)
                    .font(.headline)
                    .foregroundStyle(peripheral.isStale ? .secondary : .primary)
                Spacer()
                if peripheral.isStale {
                    Text("Not seen recently")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                signalView
            }

            Group {
                LabeledContent("Signal", value: "\(peripheral.rssi) dBm (\(peripheral.signalDescription))")

                if let discriminator = peripheral.matterDiscriminator {
                    LabeledContent("Discriminator", value: discriminator)
                }

                if let vendorID = peripheral.matterVendorID {
                    if let vendorName = peripheral.matterVendorName {
                        LabeledContent("Vendor", value: "\(vendorID) (\(vendorName))")
                    } else {
                        LabeledContent("Vendor ID", value: vendorID)
                    }
                }

                if let productID = peripheral.matterProductID {
                    LabeledContent("Product ID", value: productID)
                }

                LabeledContent("Connectable", value: peripheral.isConnectable ? "Yes" : "No")
            }
            .font(.caption)
        }
        .opacity(peripheral.isStale ? 0.6 : 1.0)
        .padding(.vertical, 2)
    }

    private var signalView: some View {
        Image(systemName: peripheral.signalIcon)
            .font(.caption)
            .foregroundStyle(signalColor)
    }

    private var signalColor: Color {
        switch peripheral.rssi {
        case -50...0: return .green
        case -70 ..< -50: return .blue
        case -85 ..< -70: return .orange
        default: return .red
        }
    }
}
