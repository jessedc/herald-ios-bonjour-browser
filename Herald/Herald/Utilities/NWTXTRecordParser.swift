import Foundation
import Network

enum NWTXTRecordParser {
    /// Parse NWTXTRecord into a [String: String] dictionary.
    static func parse(_ txtRecord: NWTXTRecord) -> [String: String] {
        txtRecord.dictionary
    }
}
