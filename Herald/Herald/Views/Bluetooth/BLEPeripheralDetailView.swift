import SwiftUI

struct BLEPeripheralDetailView: View {
    let peripheral: BLEPeripheral

    var body: some View {
        List {
            Section("Device") {
                LabeledRow(label: "Name", value: peripheral.displayName)
                LabeledRow(label: "Identifier", value: peripheral.identifier.uuidString)
                LabeledRow(label: "Connectable", value: peripheral.isConnectable ? "Yes" : "No")
            }

            Section("Signal") {
                LabeledRow(label: "RSSI", value: "\(peripheral.rssi) dBm")
                LabeledRow(label: "Strength", value: peripheral.signalDescription)
            }

            if peripheral.matterServiceData != nil {
                Section("Matter Commissioning") {
                    if let discriminator = peripheral.matterDiscriminator {
                        LabeledRow(label: "Discriminator", value: discriminator)
                    }

                    if let vendorID = peripheral.matterVendorID {
                        if let vendorName = peripheral.matterVendorName {
                            LabeledRow(label: "Vendor", value: "\(vendorID) (\(vendorName))")
                        } else {
                            LabeledRow(label: "Vendor ID", value: vendorID)
                        }
                    }

                    if let productID = peripheral.matterProductID {
                        LabeledRow(label: "Product ID", value: productID)
                    }
                }

                Section("Raw Service Data") {
                    if let data = peripheral.matterServiceData {
                        Text(data.map { String(format: "%02X", $0) }.joined(separator: " "))
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }

            if !peripheral.advertisedServiceUUIDs.isEmpty {
                Section("Advertised Services") {
                    ForEach(peripheral.advertisedServiceUUIDs, id: \.self) { uuid in
                        Text(uuid)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }

            if let manufacturerData = peripheral.manufacturerData, !manufacturerData.isEmpty {
                Section("Manufacturer Data") {
                    Text(manufacturerData.map { String(format: "%02X", $0) }.joined(separator: " "))
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
            }

            Section("Timing") {
                LabeledRow(label: "First Seen", value: peripheral.firstSeen.formatted(date: .abbreviated, time: .standard))
                LabeledRow(label: "Last Seen", value: peripheral.lastSeen.formatted(date: .abbreviated, time: .standard))
            }
        }
        .navigationTitle(peripheral.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .exportable(
            title: peripheral.displayName,
            text: { ServiceExporter.plainText(for: peripheral) },
            json: { ServiceExporter.json(for: peripheral) }
        )
    }
}
