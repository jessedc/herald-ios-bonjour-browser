import Foundation

/// A group of border routers believed to be on the same Thread mesh.
///
/// Grouped primarily by Network Name (`nn`), since the Extended PAN ID (`xp`) is typically
/// withheld from MeshCoP TXT records for privacy on modern BRs (Apple, Thread 1.4+).
struct ThreadNetwork: Identifiable {
    let groupingKey: String
    let routers: [ThreadBorderRouter]

    var id: String { groupingKey }

    /// The network name from the first router (all should agree by construction of the grouping).
    var networkName: String {
        routers.first?.networkName ?? "Unknown"
    }

    /// The Extended PAN ID if at least one router in the group advertises it; otherwise nil.
    var extendedPANID: String? {
        routers.lazy.compactMap(\.extendedPANID).first
    }

    /// True when routers on the same mesh report different Active Timestamps, indicating
    /// out-of-sync Thread operational datasets (e.g., after a firmware update on one device).
    var hasConfigDrift: Bool {
        let timestamps = routers.compactMap(\.activeTimestamp)
        guard timestamps.count >= 2 else { return false }
        return Set(timestamps).count > 1
    }

    /// True when routers grouped together advertise conflicting Extended PAN IDs —
    /// a signal that two distinct meshes coincidentally share a network name.
    var hasExtendedPANIDMismatch: Bool {
        let ids = Set(routers.compactMap(\.extendedPANID))
        return ids.count > 1
    }

    /// Human-readable warnings for this network group.
    var warnings: [String] {
        var result: [String] = []
        if hasConfigDrift {
            result.append("Dataset version mismatch — border routers have different Active Timestamps")
        }
        if hasExtendedPANIDMismatch {
            let ids = Set(routers.compactMap(\.extendedPANID)).sorted()
            result.append("Extended PAN ID mismatch — routers share a network name but report: \(ids.joined(separator: ", "))")
        }
        return result
    }

    /// Groups border routers by Network Name first (reliably advertised), falling back to
    /// Extended PAN ID when the name is missing, and finally treating unknowns as singletons.
    /// Preserves the order of first appearance.
    static func grouped(from routers: [ThreadBorderRouter]) -> [ThreadNetwork] {
        var seen: [String: Int] = [:]
        var groups: [[ThreadBorderRouter]] = []
        for router in routers {
            let key = groupingKey(for: router)
            if let index = seen[key] {
                groups[index].append(router)
            } else {
                seen[key] = groups.count
                groups.append([router])
            }
        }
        return groups.map { ThreadNetwork(groupingKey: groupingKey(for: $0[0]), routers: $0) }
    }

    private static func groupingKey(for router: ThreadBorderRouter) -> String {
        if !router.networkName.isEmpty, router.networkName != "Unknown" {
            return "nn:\(router.networkName)"
        }
        if let xp = router.extendedPANID, !xp.isEmpty {
            return "xp:\(xp)"
        }
        return "router:\(router.name)"
    }
}

struct ThreadBorderRouter: Identifiable {
    let name: String
    let networkName: String
    let extendedPANID: String?
    let panID: String?
    let vendor: String?
    let modelName: String?
    let threadVersion: String?
    let stateBitmap: String?
    let activeTimestamp: String?
    /// Thread Partition ID (`pt`) — 4 big-endian bytes on the wire. Previously
    /// misnamed `pendingTimestamp`; see `dev-docs/txt-record-labels-audit.md`.
    let partitionID: UInt32?
    let sequenceNumber: String?
    let backboneRouterFlag: String?
    let domainName: String?
    let deviceDiscriminator: String?
    let hostname: String?
    let addresses: [String]

    var id: String { "\(name)-\(extendedPANID ?? "")" }

    var stateBitmapFlags: [String] {
        Self.stateBitmapFlags(from: stateBitmap)
    }

    static func stateBitmapFlags(from hexString: String?) -> [String] {
        guard let hexString, let value = UInt8(hexString, radix: 16) else { return [] }
        return stateBitmapFlags(fromByte: value)
    }

    /// Accepts the raw MeshCoP `sb` bytes. Only the low byte matters for the
    /// connection-mode + Thread/Available flags defined in
    /// `border_agent_txt_data.cpp`; higher bytes (epskc support, etc.) are
    /// vendor-specific and ignored here.
    static func stateBitmapFlags(from data: Data) -> [String] {
        guard let lastByte = data.last else { return [] }
        return stateBitmapFlags(fromByte: lastByte)
    }

    private static func stateBitmapFlags(fromByte value: UInt8) -> [String] {
        var flags: [String] = []
        let connectionMode = value & 0x07
        switch connectionMode {
        case 0: flags.append("Not Connectable")
        case 1: flags.append("PSKc")
        case 2: flags.append("PSKd + Vendor")
        default: flags.append("Connection Mode \(connectionMode)")
        }
        if value & 0x08 != 0 {
            flags.append("Thread Active")
        }
        if value & 0x10 != 0 {
            flags.append("Available")
        }
        return flags
    }

    /// Decode the 4-byte big-endian Partition ID from `pt` raw bytes.
    /// Returns nil if the byte count isn't 4 — some implementations may ship
    /// vendor-specific encodings and we avoid inventing a value.
    static func partitionID(from data: Data) -> UInt32? {
        guard data.count == 4 else { return nil }
        return data.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
    }

    var serviceInstance: ServiceInstance {
        var txt: [String: TXTValue] = ["nn": TXTValue(networkName)]
        if let v = extendedPANID { txt["xp"] = TXTValue(v) }
        if let v = panID { txt["pi"] = TXTValue(v) }
        if let v = vendor { txt["vn"] = TXTValue(v) }
        if let v = modelName { txt["mn"] = TXTValue(v) }
        if let v = threadVersion { txt["tv"] = TXTValue(v) }
        if let v = stateBitmap { txt["sb"] = TXTValue(v) }
        if let v = activeTimestamp { txt["at"] = TXTValue(v) }
        if let v = partitionID {
            // Encode as 4 big-endian bytes so a round-trip through the formatter
            // produces the same decoded decimal we display.
            var bytes = Data(count: 4)
            bytes[0] = UInt8((v >> 24) & 0xFF)
            bytes[1] = UInt8((v >> 16) & 0xFF)
            bytes[2] = UInt8((v >> 8) & 0xFF)
            bytes[3] = UInt8(v & 0xFF)
            txt["pt"] = TXTValue(data: bytes)
        }
        if let v = sequenceNumber { txt["sq"] = TXTValue(v) }
        if let v = backboneRouterFlag { txt["bb"] = TXTValue(v) }
        if let v = domainName { txt["dn"] = TXTValue(v) }
        if let v = deviceDiscriminator { txt["dd"] = TXTValue(v) }
        return ServiceInstance(name: name, type: "_meshcop._udp", domain: "local.", txtRecord: txt)
    }
}
