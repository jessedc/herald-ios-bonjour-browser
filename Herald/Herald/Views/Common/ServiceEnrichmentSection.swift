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
            matterCommissionerSection
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
                LabeledRow(label: "Network Name", value: nn)
            }
            if let vn = txt["vn"] {
                LabeledRow(label: "Vendor", value: vn)
            }
            if let mn = txt["mn"] {
                LabeledRow(label: "Model", value: mn)
            }
            if let tv = txt["tv"] {
                LabeledRow(label: "Thread Version", value: tv)
            }
            if let xp = txt["xp"] {
                LabeledRow(label: "Extended PAN ID", value: xp)
            }
            if let pi = txt["pi"] {
                LabeledRow(label: "PAN ID", value: pi)
            }
            let flags = ThreadBorderRouter.stateBitmapFlags(from: txt["sb"])
            if !flags.isEmpty {
                LabeledRow(label: "State", value: flags.joined(separator: ", "))
            }
            if let dn = txt["dn"] {
                LabeledRow(label: "Domain Name", value: dn)
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
            if let vp = txt["VP"] {
                let vendorName = MatterVendorIDs.vendorName(for: vp)
                LabeledRow(label: "Vendor / Product", value: vendorName.map { "\(vp) (\($0))" } ?? vp)
            }
            if let dt = txt["DT"] {
                let desc = MatterDeviceTypes.description(for: dt)
                LabeledRow(label: "Device Type", value: desc.map { "\(dt) (\($0))" } ?? dt)
            }
            if let dn = txt["DN"] {
                LabeledRow(label: "Device Name", value: dn)
            }
            if let d = txt["D"] {
                LabeledRow(label: "Discriminator", value: d)
            }
            if let cm = txt["CM"] {
                LabeledRow(label: "Commissioning Mode", value: MatterDevice.commissioningModeDescription(cm))
            }
            if let hints = MatterDevice.decodePairingHint(txt["PH"]) {
                LabeledRow(label: "Pairing Hints", value: hints.joined(separator: ", "))
            }
            if txt["ICD"] == "1" {
                LabeledRow(label: "Intermittent Device (ICD)", value: "Yes (Battery / Sleepy)")
            }
            if let sii = MatterDevice.humanizeInterval(txt["SII"]) {
                LabeledRow(label: "Session Idle Interval", value: sii)
            }
            if let sai = MatterDevice.humanizeInterval(txt["SAI"]) {
                LabeledRow(label: "Session Active Interval", value: sai)
            }
            if let t = txt["T"] {
                LabeledRow(label: "TCP Supported", value: t == "1" ? "Yes" : "No")
            }
        }
    }

    // MARK: - Matter Commissioner

    @ViewBuilder
    private var matterCommissionerSection: some View {
        let txt = instance.txtRecord
        Section("Matter Commissioner") {
            if let dn = txt["DN"] {
                LabeledRow(label: "Device Name", value: dn)
            }
            if let vp = txt["VP"] {
                let vendorName = MatterVendorIDs.vendorName(for: vp)
                LabeledRow(label: "Vendor / Product", value: vendorName.map { "\(vp) (\($0))" } ?? vp)
            }
            if let dt = txt["DT"] {
                let desc = MatterDeviceTypes.description(for: dt)
                LabeledRow(label: "Device Type", value: desc.map { "\(dt) (\($0))" } ?? dt)
            }
        }
    }
}
