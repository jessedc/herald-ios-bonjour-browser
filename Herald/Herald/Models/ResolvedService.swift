import Foundation

struct ResolvedService: Identifiable {
    let name: String
    let type: String
    let domain: String
    let hostname: String
    let port: UInt16
    let ipv4Addresses: [String]
    let ipv6Addresses: [String]
    let txtRecord: [String: String]
    let reverseDNS: [String: String]
    let resolvedAt: Date

    init(
        name: String,
        type: String,
        domain: String,
        hostname: String,
        port: UInt16,
        ipv4Addresses: [String],
        ipv6Addresses: [String],
        txtRecord: [String: String],
        reverseDNS: [String: String] = [:],
        resolvedAt: Date
    ) {
        self.name = name
        self.type = type
        self.domain = domain
        self.hostname = hostname
        self.port = port
        self.ipv4Addresses = ipv4Addresses
        self.ipv6Addresses = ipv6Addresses
        self.txtRecord = txtRecord
        self.reverseDNS = reverseDNS
        self.resolvedAt = resolvedAt
    }

    var id: String { "\(name).\(type).\(domain)" }

    var allAddresses: [String] {
        ipv4Addresses + ipv6Addresses
    }

    var formattedPort: String {
        String(port)
    }
}
