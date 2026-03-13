import Foundation

struct DiscoveryError: Identifiable {
    let id = UUID()
    let message: String
    let source: String
}
