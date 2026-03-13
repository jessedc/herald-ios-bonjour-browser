import Foundation

struct MatterDevice: Identifiable {
    let name: String
    let serviceType: String
    let discriminator: String?
    let vendorProductID: String?
    let commissioningMode: String?
    let deviceType: String?
    let deviceName: String?
    let sessionIdleInterval: String?
    let sessionActiveInterval: String?
    let tcpSupported: String?
    let isICD: String?
    let pairingHint: String?
    let hostname: String?
    let addresses: [String]

    var id: String { "\(name)-\(serviceType)" }

    var serviceInstance: ServiceInstance {
        var txt: [String: String] = [:]
        if let v = discriminator { txt["D"] = v }
        if let v = vendorProductID { txt["VP"] = v }
        if let v = commissioningMode { txt["CM"] = v }
        if let v = deviceType { txt["DT"] = v }
        if let v = deviceName { txt["DN"] = v }
        if let v = sessionIdleInterval { txt["SII"] = v }
        if let v = sessionActiveInterval { txt["SAI"] = v }
        if let v = tcpSupported { txt["T"] = v }
        if let v = isICD { txt["ICD"] = v }
        if let v = pairingHint { txt["PH"] = v }
        return ServiceInstance(name: name, type: serviceType, domain: "local.", txtRecord: txt)
    }

    var deviceTypeDescription: String {
        MatterDeviceTypes.description(for: deviceType) ?? deviceType ?? "Unknown"
    }

    var vendorName: String? {
        MatterVendorIDs.vendorName(for: vendorProductID)
    }

    var commissioningModeDescription: String {
        Self.commissioningModeDescription(commissioningMode)
    }

    static func commissioningModeDescription(_ mode: String?) -> String {
        switch mode {
        case "0": return "Not Commissioning"
        case "1": return "Basic"
        case "2": return "Enhanced"
        default: return mode ?? "Unknown"
        }
    }
}
