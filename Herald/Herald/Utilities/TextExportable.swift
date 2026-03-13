import Foundation

@MainActor
protocol TextExportable {
    var exportTitle: String { get }
    var exportText: String { get }
    var exportJSON: String? { get }
}

extension TextExportable {
    var exportJSON: String? { nil }
}
