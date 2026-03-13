import Foundation

struct TRELPeer: Identifiable {
    let name: String
    let hostname: String?
    let addresses: [String]

    var id: String { name }

    var serviceInstance: ServiceInstance {
        ServiceInstance(name: name, type: "_trel._udp", domain: "local.", txtRecord: [:])
    }
}

struct SRPServer: Identifiable {
    let name: String
    let hostname: String?
    let port: UInt16
    let addresses: [String]

    var id: String { name }

    var serviceInstance: ServiceInstance {
        ServiceInstance(name: name, type: "_srpl-tls._tcp", domain: "local.", txtRecord: [:])
    }
}

struct MatterCommissioner: Identifiable {
    let name: String
    let deviceName: String?
    let vendorProductID: String?
    let deviceType: String?
    let commissioningMode: String?
    let hostname: String?
    let addresses: [String]

    var id: String { name }

    var deviceTypeDescription: String {
        MatterDeviceTypes.description(for: deviceType) ?? deviceType ?? "Unknown"
    }

    var vendorName: String? {
        MatterVendorIDs.vendorName(for: vendorProductID)
    }

    var serviceInstance: ServiceInstance {
        var txt: [String: String] = [:]
        if let v = deviceName { txt["DN"] = v }
        if let v = vendorProductID { txt["VP"] = v }
        if let v = deviceType { txt["DT"] = v }
        if let v = commissioningMode { txt["CM"] = v }
        return ServiceInstance(name: name, type: "_matterc._udp", domain: "local.", txtRecord: txt)
    }
}
