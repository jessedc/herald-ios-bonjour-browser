import Foundation

struct ServiceInstance: Identifiable, Hashable {
    let name: String
    let type: String
    let domain: String
    let txtRecord: [String: String]

    var id: String { "\(name).\(type).\(domain)" }

    var displayName: String {
        // Many Bonjour names end with the type, trim for display
        name
    }
}
