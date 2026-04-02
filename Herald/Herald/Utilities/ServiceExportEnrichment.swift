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
        txt: [String: String]
    ) -> (header: String, lines: [String]) {
        var lines: [String] = []
        if let nn = txt["nn"] { lines.append("Network Name: \(nn)") }
        if let vn = txt["vn"] { lines.append("Vendor: \(vn)") }
        if let mn = txt["mn"] { lines.append("Model: \(mn)") }
        if let tv = txt["tv"] { lines.append("Thread Version: \(tv)") }
        if let xp = txt["xp"] { lines.append("Extended PAN ID: \(xp)") }
        if let pi = txt["pi"] { lines.append("PAN ID: \(pi)") }
        let flags = ThreadBorderRouter.stateBitmapFlags(from: txt["sb"])
        if !flags.isEmpty {
            lines.append("State: \(flags.joined(separator: ", "))")
        }
        if let dn = txt["dn"] { lines.append("Domain Name: \(dn)") }
        if txt["bb"] != nil { lines.append("Backbone Router: Yes") }
        return ("Thread Border Router", lines)
    }

    private static func threadJSON(txt: [String: String]) -> [String: Any] {
        var dict: [String: Any] = ["type": "threadBorderRouter"]
        if let val = txt["nn"] { dict["networkName"] = val }
        if let val = txt["vn"] { dict["vendor"] = val }
        if let val = txt["mn"] { dict["model"] = val }
        if let val = txt["tv"] { dict["threadVersion"] = val }
        if let val = txt["xp"] { dict["extendedPANID"] = val }
        if let val = txt["pi"] { dict["panID"] = val }
        let flags = ThreadBorderRouter.stateBitmapFlags(from: txt["sb"])
        if !flags.isEmpty { dict["stateFlags"] = flags }
        if let val = txt["dn"] { dict["domainName"] = val }
        if txt["bb"] != nil { dict["backboneRouter"] = true }
        return dict
    }

    // MARK: - Matter Device

    private static func matterPlainText(
        name: String, txt: [String: String]
    ) -> (header: String, lines: [String]) {
        let parsed = MatterInstanceName.parse(name)
        let header = parsed != nil ? "Matter Operational Device" : "Matter Device"
        var lines: [String] = []
        if let parsed {
            lines.append("Fabric ID: \(parsed.fabricID)")
            lines.append("Node ID: \(parsed.truncatedNodeID)")
        }
        if let vp = txt["VP"] {
            let vendorName = MatterVendorIDs.vendorName(for: vp)
            lines.append("Vendor / Product: \(vendorName.map { "\(vp) (\($0))" } ?? vp)")
        }
        if let dt = txt["DT"] {
            let desc = MatterDeviceTypes.description(for: dt)
            lines.append("Device Type: \(desc.map { "\(dt) (\($0))" } ?? dt)")
        }
        if let dn = txt["DN"] { lines.append("Device Name: \(dn)") }
        if let discrim = txt["D"] { lines.append("Discriminator: \(discrim)") }
        if let cm = txt["CM"] {
            lines.append("Commissioning Mode: \(MatterDevice.commissioningModeDescription(cm))")
        }
        if let hints = MatterDevice.decodePairingHint(txt["PH"]) {
            lines.append("Pairing Hints: \(hints.joined(separator: ", "))")
        }
        if txt["ICD"] == "1" {
            lines.append("Intermittent Device (ICD): Yes (Battery / Sleepy)")
        }
        if let sii = MatterDevice.humanizeInterval(txt["SII"]) {
            lines.append("Session Idle Interval: \(sii)")
        }
        if let sai = MatterDevice.humanizeInterval(txt["SAI"]) {
            lines.append("Session Active Interval: \(sai)")
        }
        if let tcp = txt["T"] {
            lines.append("TCP Supported: \(tcp == "1" ? "Yes" : "No")")
        }
        return (header, lines)
    }

    private static func matterJSON(name: String, txt: [String: String]) -> [String: Any] {
        let parsed = MatterInstanceName.parse(name)
        var dict: [String: Any] = [
            "type": parsed != nil ? "matterOperationalDevice" : "matterDevice"
        ]
        if let parsed {
            dict["fabricID"] = parsed.fabricID
            dict["nodeID"] = parsed.truncatedNodeID
        }
        if let vp = txt["VP"] {
            dict["vendorProduct"] = vp
            if let vendorName = MatterVendorIDs.vendorName(for: vp) {
                dict["vendorName"] = vendorName
            }
        }
        if let dt = txt["DT"] {
            dict["deviceType"] = dt
            if let desc = MatterDeviceTypes.description(for: dt) {
                dict["deviceTypeDescription"] = desc
            }
        }
        if let val = txt["DN"] { dict["deviceName"] = val }
        if let val = txt["D"] { dict["discriminator"] = val }
        if let val = txt["CM"] {
            dict["commissioningMode"] = MatterDevice.commissioningModeDescription(val)
        }
        if let hints = MatterDevice.decodePairingHint(txt["PH"]) {
            dict["pairingHints"] = hints
        }
        if txt["ICD"] == "1" { dict["isICD"] = true }
        if let val = MatterDevice.humanizeInterval(txt["SII"]) {
            dict["sessionIdleInterval"] = val
        }
        if let val = MatterDevice.humanizeInterval(txt["SAI"]) {
            dict["sessionActiveInterval"] = val
        }
        if let tcp = txt["T"] { dict["tcpSupported"] = tcp == "1" }
        return dict
    }

    // MARK: - Matter Commissionable

    private static func matterCommissionablePlainText(
        txt: [String: String]
    ) -> (header: String, lines: [String]) {
        var lines: [String] = []
        if let dn = txt["DN"] { lines.append("Device Name: \(dn)") }
        if let vp = txt["VP"] {
            let vendorName = MatterVendorIDs.vendorName(for: vp)
            lines.append("Vendor / Product: \(vendorName.map { "\(vp) (\($0))" } ?? vp)")
        }
        if let dt = txt["DT"] {
            let desc = MatterDeviceTypes.description(for: dt)
            lines.append("Device Type: \(desc.map { "\(dt) (\($0))" } ?? dt)")
        }
        return ("Matter Commissionable", lines)
    }

    private static func matterCommissionableJSON(txt: [String: String]) -> [String: Any] {
        var dict: [String: Any] = ["type": "matterCommissionable"]
        if let val = txt["DN"] { dict["deviceName"] = val }
        if let vp = txt["VP"] {
            dict["vendorProduct"] = vp
            if let vendorName = MatterVendorIDs.vendorName(for: vp) {
                dict["vendorName"] = vendorName
            }
        }
        if let dt = txt["DT"] {
            dict["deviceType"] = dt
            if let desc = MatterDeviceTypes.description(for: dt) {
                dict["deviceTypeDescription"] = desc
            }
        }
        return dict
    }
}
