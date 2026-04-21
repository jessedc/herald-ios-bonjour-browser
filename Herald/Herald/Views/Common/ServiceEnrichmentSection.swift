import SwiftUI

struct ServiceEnrichmentSection: View {
    let instance: ServiceInstance

    var body: some View {
        switch instance.type {
        case "_meshcop._udp":
            threadSection
        case "_matter._tcp", "_matter._udp", "_matterd._udp":
            matterSection
        case "_matterc._udp":
            matterCommissionableSection
        default:
            EmptyView()
        }
    }

    // MARK: - Thread Border Router

    @ViewBuilder
    private var threadSection: some View {
        let txt = instance.txtRecord
        Section("Thread Border Router") {
            if let nn = txt["nn"] {
                LabeledRow(label: "Network Name", value: nn.asString)
            }
            if let vn = txt["vn"] {
                LabeledRow(label: "Vendor", value: vn.asString)
            }
            if let mn = txt["mn"] {
                LabeledRow(label: "Model", value: mn.asString)
            }
            if let tv = txt["tv"] {
                LabeledRow(label: "Thread Version", value: tv.asString)
            }
            if let xp = txt["xp"] {
                let display = TXTValueFormatter.format(key: "xp", data: xp.data, serviceType: "_meshcop._udp")
                LabeledRow(label: "Extended PAN ID", value: display.primaryString)
            }
            if let pi = txt["pi"] {
                LabeledRow(label: "PAN ID", value: pi.asString)
            }
            let flags = ThreadBorderRouter.stateBitmapFlags(from: txt["sb"]?.data ?? Data())
            if !flags.isEmpty {
                LabeledRow(label: "State", value: flags.joined(separator: ", "))
            }
            if let dn = txt["dn"] {
                LabeledRow(label: "Domain Name", value: dn.asString)
            }
            if txt["bb"] != nil {
                LabeledRow(label: "Backbone Router", value: "Yes")
            }
        }
    }

    // MARK: - Matter Device

    @ViewBuilder
    private var matterSection: some View {
        let txt = instance.txtRecord
        let parsed = MatterInstanceName.parse(instance.name)
        Section(parsed != nil ? "Matter Operational Device" : "Matter Device") {
            if let parsed {
                LabeledRow(label: "Fabric ID", value: parsed.fabricID)
                LabeledRow(label: "Node ID", value: parsed.truncatedNodeID)
            }
            if let vp = txt["VP"]?.asString {
                let vendorName = MatterVendorIDs.vendorName(for: vp)
                LabeledRow(label: "Vendor / Product", value: vendorName.map { "\(vp) (\($0))" } ?? vp)
            }
            if let dt = txt["DT"]?.asString {
                let desc = MatterDeviceTypes.description(for: dt)
                LabeledRow(label: "Device Type", value: desc.map { "\(dt) (\($0))" } ?? dt)
            }
            if let dn = txt["DN"] {
                LabeledRow(label: "Device Name", value: dn.asString)
            }
            if let d = txt["D"] {
                LabeledRow(label: "Discriminator", value: d.asString)
            }
            if let cm = txt["CM"]?.asString {
                LabeledRow(label: "Commissioning Mode", value: MatterDevice.commissioningModeDescription(cm))
            }
            if let hints = MatterDevice.decodePairingHint(txt["PH"]?.asString) {
                LabeledRow(label: "Pairing Hints", value: hints.joined(separator: ", "))
            }
            if txt["ICD"]?.asString == "1" {
                LabeledRow(label: "Intermittent Device (ICD)", value: "Yes (Battery / Sleepy)")
            }
            if let sii = MatterDevice.humanizeInterval(txt["SII"]?.asString) {
                LabeledRow(label: "Session Idle Interval", value: sii)
            }
            if let sai = MatterDevice.humanizeInterval(txt["SAI"]?.asString) {
                LabeledRow(label: "Session Active Interval", value: sai)
            }
            if let t = txt["T"]?.asString {
                LabeledRow(label: "TCP Supported", value: t == "1" ? "Yes" : "No")
            }
        }
    }

    // MARK: - Matter Commissionable

    @ViewBuilder
    private var matterCommissionableSection: some View {
        let txt = instance.txtRecord
        Section("Matter Commissionable") {
            if let dn = txt["DN"] {
                LabeledRow(label: "Device Name", value: dn.asString)
            }
            if let vp = txt["VP"]?.asString {
                let vendorName = MatterVendorIDs.vendorName(for: vp)
                LabeledRow(label: "Vendor / Product", value: vendorName.map { "\(vp) (\($0))" } ?? vp)
            }
            if let dt = txt["DT"]?.asString {
                let desc = MatterDeviceTypes.description(for: dt)
                LabeledRow(label: "Device Type", value: desc.map { "\(dt) (\($0))" } ?? dt)
            }
        }
    }
}
