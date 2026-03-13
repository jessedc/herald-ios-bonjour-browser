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
    let resolvedAt: Date

    var id: String { "\(name).\(type).\(domain)" }

    var allAddresses: [String] {
        ipv4Addresses + ipv6Addresses
    }

    var formattedPort: String {
        String(port)
    }
}
