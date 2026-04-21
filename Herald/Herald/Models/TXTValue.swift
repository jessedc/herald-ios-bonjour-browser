import Foundation

/// A DNS-SD TXT record value. Always holds the raw bytes from the wire format.
/// The wire format permits arbitrary bytes in values (only keys are constrained to
/// printable ASCII by RFC 6763), so binary-valued TXT records — like Thread's
/// Partition ID or Extended PAN ID — must not be prematurely UTF-8 decoded.
///
/// - Use `data` for the raw bytes (required by `TXTValueFormatter`).
/// - Use `utf8String` for strict UTF-8 (nil on invalid).
/// - Use `asString` as a best-effort text accessor (empty on invalid).
/// - Dictionary literals like `["nn": "Office"]` keep working via
///   `ExpressibleByStringLiteral`.
struct TXTValue: Hashable, Sendable {
    let data: Data

    init(data: Data) { self.data = data }

    init(_ string: String) { self.data = Data(string.utf8) }

    var utf8String: String? { String(data: data, encoding: .utf8) }

    var asString: String { utf8String ?? "" }

    var isEmpty: Bool { data.isEmpty }
}

extension TXTValue: ExpressibleByStringLiteral {
    init(stringLiteral value: String) { self.init(value) }
}

extension TXTValue: CustomStringConvertible {
    var description: String { asString }
}
