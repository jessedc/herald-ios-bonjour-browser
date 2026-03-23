import Foundation

struct MatterInstanceName: Equatable {
    let fabricID: String
    let nodeID: String

    var truncatedFabricID: String {
        String(fabricID.prefix(8)) + "…"
    }

    var truncatedNodeID: String {
        // Strip leading zeros for readability
        let stripped = nodeID.drop { $0 == "0" }
        return stripped.isEmpty ? "0" : String(stripped)
    }

    static func parse(_ name: String) -> MatterInstanceName? {
        let parts = name.split(separator: "-", maxSplits: 1)
        guard parts.count == 2 else { return nil }
        let fabric = String(parts[0])
        let node = String(parts[1])
        // Both parts must be non-empty hex strings
        let hexChars = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
        guard !fabric.isEmpty, !node.isEmpty,
              fabric.unicodeScalars.allSatisfy({ hexChars.contains($0) }),
              node.unicodeScalars.allSatisfy({ hexChars.contains($0) })
        else { return nil }
        return MatterInstanceName(fabricID: fabric, nodeID: node)
    }
}

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

    // MARK: - Parsed instance name (operational devices)

    var parsedInstanceName: MatterInstanceName? {
        MatterInstanceName.parse(name)
    }

    var isOperational: Bool {
        parsedInstanceName != nil
    }

    /// Best available human-readable name: device name > hostname (without .local.) > raw instance name
    var displayName: String {
        if let dn = deviceName { return dn }
        if let h = hostname {
            return h.replacingOccurrences(of: ".local.", with: "")
                .replacingOccurrences(of: "-", with: " ")
        }
        return name
    }

    // MARK: - Humanized TXT values

    var isBatteryDevice: Bool {
        isICD == "1"
    }

    var sessionIdleDescription: String? {
        guard let humanized = Self.humanizeInterval(sessionIdleInterval) else { return nil }
        return "Idle wake: \(humanized)"
    }

    var sessionActiveDescription: String? {
        guard let humanized = Self.humanizeInterval(sessionActiveInterval) else { return nil }
        return "Active wake: \(humanized)"
    }

    var pairingHintDescriptions: [String]? {
        Self.decodePairingHint(pairingHint)
    }

    // MARK: - Static Utility Methods

    static func decodePairingHint(_ value: String?) -> [String]? {
        guard let ph = value, let intValue = Int(ph), intValue > 0 else { return nil }
        var hints: [String] = []
        if intValue & 0x01 != 0 { hints.append("Power cycle device") }
        if intValue & 0x02 != 0 { hints.append("Use device-specific app") }
        if intValue & 0x04 != 0 { hints.append("Press reset button for 10s") }
        if intValue & 0x08 != 0 { hints.append("Press reset button until LED blinks") }
        if intValue & 0x10 != 0 { hints.append("Press reset button for 5s") }
        if intValue & 0x20 != 0 { hints.append("Press setup button once") }
        return hints.isEmpty ? nil : hints
    }

    static func humanizeInterval(_ ms: String?) -> String? {
        guard let raw = ms, let value = Int(raw) else { return nil }
        if value >= 1000 {
            return "\(value / 1000)s"
        }
        return "\(value)ms"
    }

    // MARK: - Existing computed properties

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
