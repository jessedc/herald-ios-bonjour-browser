import Foundation

struct ThreadBorderRouter: Identifiable {
    let name: String
    let networkName: String
    let extendedPANID: String
    let panID: String?
    let vendor: String?
    let modelName: String?
    let threadVersion: String?
    let stateBitmap: String?
    let activeTimestamp: String?
    let pendingTimestamp: String?
    let sequenceNumber: String?
    let backboneRouterFlag: String?
    let domainName: String?
    let deviceDiscriminator: String?
    let hostname: String?
    let addresses: [String]

    var id: String { "\(name)-\(extendedPANID)" }

    var stateBitmapFlags: [String] {
        Self.stateBitmapFlags(from: stateBitmap)
    }

    static func stateBitmapFlags(from hexString: String?) -> [String] {
        guard let hexString, let value = UInt8(hexString, radix: 16) else { return [] }
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

    var serviceInstance: ServiceInstance {
        var txt: [String: String] = ["nn": networkName, "xp": extendedPANID]
        if let v = panID { txt["pi"] = v }
        if let v = vendor { txt["vn"] = v }
        if let v = modelName { txt["mn"] = v }
        if let v = threadVersion { txt["tv"] = v }
        if let v = stateBitmap { txt["sb"] = v }
        if let v = activeTimestamp { txt["at"] = v }
        if let v = pendingTimestamp { txt["pt"] = v }
        if let v = sequenceNumber { txt["sq"] = v }
        if let v = backboneRouterFlag { txt["bb"] = v }
        if let v = domainName { txt["dn"] = v }
        if let v = deviceDiscriminator { txt["dd"] = v }
        return ServiceInstance(name: name, type: "_meshcop._udp", domain: "local.", txtRecord: txt)
    }
}
