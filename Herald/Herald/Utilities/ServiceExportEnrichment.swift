import Foundation

/// Enrichment formatters for single-service export, mirroring the decoded
/// fields shown in ServiceEnrichmentSection (Thread, Matter, Commissionable).
enum ServiceExportEnrichment {

    // MARK: - Plain Text

    static func plainText(
        for service: ResolvedService
    ) -> (header: String, lines: [String])? {
        let txt = service.txtRecord
        switch service.type {
        case "_meshcop._udp":
            return threadPlainText(txt: txt)
        case "_matter._tcp", "_matter._udp", "_matterd._udp":
            return matterPlainText(name: service.name, txt: txt)
        case "_matterc._udp":
            return matterCommissionablePlainText(txt: txt)
        default:
            return nil
        }
    }

    // MARK: - JSON

    static func json(for service: ResolvedService) -> [String: Any]? {
        let txt = service.txtRecord
        switch service.type {
        case "_meshcop._udp":
            return threadJSON(txt: txt)
        case "_matter._tcp", "_matter._udp", "_matterd._udp":
            return matterJSON(name: service.name, txt: txt)
        case "_matterc._udp":
            return matterCommissionableJSON(txt: txt)
        default:
            return nil
        }
    }

    // MARK: - Thread Border Router

    private static func threadPlainText(
        txt: [String: TXTValue]
    ) -> (header: String, lines: [String]) {
        var lines: [String] = []
        if let nn = txt["nn"] { lines.append("Network Name: \(nn.asString)") }
        if let vn = txt["vn"] { lines.append("Vendor: \(vn.asString)") }
        if let mn = txt["mn"] { lines.append("Model: \(mn.asString)") }
        if let tv = txt["tv"] { lines.append("Thread Version: \(tv.asString)") }
        if let xp = txt["xp"] {
            let display = TXTValueFormatter.format(key: "xp", data: xp.data, serviceType: "_meshcop._udp")
            lines.append("Extended PAN ID: \(display.primaryString)")
        }
        if let pi = txt["pi"] { lines.append("PAN ID: \(pi.asString)") }
        let flags = ThreadBorderRouter.stateBitmapFlags(from: txt["sb"]?.data ?? Data())
        if !flags.isEmpty {
            lines.append("State: \(flags.joined(separator: ", "))")
        }
        if let dn = txt["dn"] { lines.append("Domain Name: \(dn.asString)") }
        if txt["bb"] != nil { lines.append("Backbone Router: Yes") }
        return ("Thread Border Router", lines)
    }

    private static func threadJSON(txt: [String: TXTValue]) -> [String: Any] {
        var dict: [String: Any] = ["type": "threadBorderRouter"]
        if let val = txt["nn"] { dict["networkName"] = val.asString }
        if let val = txt["vn"] { dict["vendor"] = val.asString }
        if let val = txt["mn"] { dict["model"] = val.asString }
        if let val = txt["tv"] { dict["threadVersion"] = val.asString }
        if let val = txt["xp"] {
            let display = TXTValueFormatter.format(key: "xp", data: val.data, serviceType: "_meshcop._udp")
            dict["extendedPANID"] = display.primaryString
        }
        if let val = txt["pi"] { dict["panID"] = val.asString }
        let flags = ThreadBorderRouter.stateBitmapFlags(from: txt["sb"]?.data ?? Data())
        if !flags.isEmpty { dict["stateFlags"] = flags }
        if let val = txt["dn"] { dict["domainName"] = val.asString }
        if txt["bb"] != nil { dict["backboneRouter"] = true }
        return dict
    }

    // MARK: - Matter Device

    private static func matterPlainText(
        name: String, txt: [String: TXTValue]
    ) -> (header: String, lines: [String]) {
        let parsed = MatterInstanceName.parse(name)
        let header = parsed != nil ? "Matter Operational Device" : "Matter Device"
        var lines: [String] = []
        if let parsed {
            lines.append("Fabric ID: \(parsed.fabricID)")
            lines.append("Node ID: \(parsed.truncatedNodeID)")
        }
        if let vp = txt["VP"]?.asString {
            let vendorName = MatterVendorIDs.vendorName(for: vp)
            lines.append("Vendor / Product: \(vendorName.map { "\(vp) (\($0))" } ?? vp)")
        }
        if let dt = txt["DT"]?.asString {
            let desc = MatterDeviceTypes.description(for: dt)
            lines.append("Device Type: \(desc.map { "\(dt) (\($0))" } ?? dt)")
        }
        if let dn = txt["DN"] { lines.append("Device Name: \(dn.asString)") }
        if let discrim = txt["D"] { lines.append("Discriminator: \(discrim.asString)") }
        if let cm = txt["CM"]?.asString {
            lines.append("Commissioning Mode: \(MatterDevice.commissioningModeDescription(cm))")
        }
        if let hints = MatterDevice.decodePairingHint(txt["PH"]?.asString) {
            lines.append("Pairing Hints: \(hints.joined(separator: ", "))")
        }
        if txt["ICD"]?.asString == "1" {
            lines.append("Intermittent Device (ICD): Yes (Battery / Sleepy)")
        }
        if let sii = MatterDevice.humanizeInterval(txt["SII"]?.asString) {
            lines.append("Session Idle Interval: \(sii)")
        }
        if let sai = MatterDevice.humanizeInterval(txt["SAI"]?.asString) {
            lines.append("Session Active Interval: \(sai)")
        }
        if let tcp = txt["T"]?.asString {
            lines.append("TCP Supported: \(tcp == "1" ? "Yes" : "No")")
        }
        return (header, lines)
    }

    private static func matterJSON(name: String, txt: [String: TXTValue]) -> [String: Any] {
        let parsed = MatterInstanceName.parse(name)
        var dict: [String: Any] = [
            "type": parsed != nil ? "matterOperationalDevice" : "matterDevice"
        ]
        if let parsed {
            dict["fabricID"] = parsed.fabricID
            dict["nodeID"] = parsed.truncatedNodeID
        }
        if let vp = txt["VP"]?.asString {
            dict["vendorProduct"] = vp
            if let vendorName = MatterVendorIDs.vendorName(for: vp) {
                dict["vendorName"] = vendorName
            }
        }
        if let dt = txt["DT"]?.asString {
            dict["deviceType"] = dt
            if let desc = MatterDeviceTypes.description(for: dt) {
                dict["deviceTypeDescription"] = desc
            }
        }
        if let val = txt["DN"] { dict["deviceName"] = val.asString }
        if let val = txt["D"] { dict["discriminator"] = val.asString }
        if let val = txt["CM"]?.asString {
            dict["commissioningMode"] = MatterDevice.commissioningModeDescription(val)
        }
        if let hints = MatterDevice.decodePairingHint(txt["PH"]?.asString) {
            dict["pairingHints"] = hints
        }
        if txt["ICD"]?.asString == "1" { dict["isICD"] = true }
        if let val = MatterDevice.humanizeInterval(txt["SII"]?.asString) {
            dict["sessionIdleInterval"] = val
        }
        if let val = MatterDevice.humanizeInterval(txt["SAI"]?.asString) {
            dict["sessionActiveInterval"] = val
        }
        if let tcp = txt["T"]?.asString { dict["tcpSupported"] = tcp == "1" }
        return dict
    }

    // MARK: - Matter Commissionable

    private static func matterCommissionablePlainText(
        txt: [String: TXTValue]
    ) -> (header: String, lines: [String]) {
        var lines: [String] = []
        if let dn = txt["DN"] { lines.append("Device Name: \(dn.asString)") }
        if let vp = txt["VP"]?.asString {
            let vendorName = MatterVendorIDs.vendorName(for: vp)
            lines.append("Vendor / Product: \(vendorName.map { "\(vp) (\($0))" } ?? vp)")
        }
        if let dt = txt["DT"]?.asString {
            let desc = MatterDeviceTypes.description(for: dt)
            lines.append("Device Type: \(desc.map { "\(dt) (\($0))" } ?? dt)")
        }
        return ("Matter Commissionable", lines)
    }

    private static func matterCommissionableJSON(txt: [String: TXTValue]) -> [String: Any] {
        var dict: [String: Any] = ["type": "matterCommissionable"]
        if let val = txt["DN"] { dict["deviceName"] = val.asString }
        if let vp = txt["VP"]?.asString {
            dict["vendorProduct"] = vp
            if let vendorName = MatterVendorIDs.vendorName(for: vp) {
                dict["vendorName"] = vendorName
            }
        }
        if let dt = txt["DT"]?.asString {
            dict["deviceType"] = dt
            if let desc = MatterDeviceTypes.description(for: dt) {
                dict["deviceTypeDescription"] = desc
            }
        }
        return dict
    }
}
