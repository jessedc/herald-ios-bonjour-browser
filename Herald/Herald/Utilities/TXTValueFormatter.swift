import Foundation

/// A rendering of a TXT record value, chosen by `TXTValueFormatter` based on
/// what the key is known to represent.
enum TXTValueDisplay: Equatable {
    /// UTF-8 text. The only case where the raw bytes aren't surfaced, because
    /// the text itself is the authoritative representation.
    case text(String)

    /// Uppercase hex with optional `:` separators (no `0x` prefix).
    case hex(String)

    /// Structured decoding plus the canonical hex form for verification.
    /// `primary` is the human-facing value (e.g. `"239,224,144"`); `hex` is
    /// the uppercase byte string (e.g. `"0E401F50"`).
    case decoded(primary: String, hex: String)

    /// Bitmap value rendered as its decoded flag list plus the raw hex.
    case flags(hex: String, description: String)

    /// Empty value (`key=`).
    case empty

    /// The single-line representation used by plaintext exporters.
    var primaryString: String {
        switch self {
        case .text(let s): return s
        case .hex(let s): return s
        case .decoded(let primary, let hex): return "\(primary) (0x\(hex))"
        case .flags(let hex, let description): return "0x\(hex) · \(description)"
        case .empty: return ""
        }
    }
}

/// Per-service classification of TXT record values. Unknown keys fall back to a
/// printable-or-hex heuristic.
enum TXTValueFormatter {

    static func format(key: String, data: Data, serviceType: String) -> TXTValueDisplay {
        if data.isEmpty { return .empty }

        switch classification(for: key, serviceType: serviceType) {
        case .text:
            return textOrHex(data)
        case .hexRaw:
            return .hex(hexString(data))
        case .hexColonSeparated:
            return .hex(hexString(data, separator: ":"))
        case .uint8:
            return decodedUnsigned(data, expectedBytes: 1)
        case .uint16:
            return decodedUnsigned(data, expectedBytes: 2)
        case .uint32:
            return decodedUnsigned(data, expectedBytes: 4)
        case .uint64:
            return decodedUnsigned(data, expectedBytes: 8)
        case .threadStateBitmap:
            let hex = hexString(data)
            let flags = threadStateBitmapFlags(from: data)
            if flags.isEmpty {
                return .hex(hex)
            }
            return .flags(hex: hex, description: flags.joined(separator: ", "))
        case .auto:
            return textOrHex(data)
        }
    }

    // MARK: - Classification

    enum Classification {
        case text
        case hexRaw               // uppercase, no separators
        case hexColonSeparated    // AA:BB:CC…
        case uint8
        case uint16
        case uint32
        case uint64
        case threadStateBitmap
        case auto
    }

    static func classification(for key: String, serviceType: String) -> Classification {
        switch serviceType {
        case "_meshcop._udp":
            switch key {
            case "nn", "vn", "mn", "tv", "dn", "rv", "omr": return .text
            case "id": return .hexRaw
            case "xp", "xa": return .hexColonSeparated
            case "pt": return .uint32
            case "at": return .uint64
            case "sb": return .threadStateBitmap
            case "sq": return .uint8
            case "bb": return .uint16
            default: return .auto
            }
        case "_matter._tcp", "_matter._udp", "_matterd._udp", "_matterc._udp":
            switch key {
            case "RI": return .hexRaw
            default: return .text
            }
        case "_hap._tcp":
            // HAP device id is a MAC string already (AA:BB:CC:DD:EE:FF), not raw bytes.
            return .text
        default:
            return .auto
        }
    }

    // MARK: - Helpers

    /// Heuristic for unknown keys: all bytes printable ASCII (plus TAB) → text.
    /// Otherwise hex.
    private static func textOrHex(_ data: Data) -> TXTValueDisplay {
        if let text = data.utf8StringIfPrintable() {
            return .text(text)
        }
        return .hex(hexString(data))
    }

    private static func decodedUnsigned(_ data: Data, expectedBytes: Int) -> TXTValueDisplay {
        let hex = hexString(data)
        guard data.count == expectedBytes else {
            // Byte count mismatch — show hex alone rather than a misleading decode.
            return .hex(hex)
        }
        let value: UInt64 = data.reduce(0) { ($0 << 8) | UInt64($1) }
        let formatted = decimalFormatter.string(from: NSNumber(value: value)) ?? String(value)
        return .decoded(primary: formatted, hex: hex)
    }

    static func hexString(_ data: Data, separator: String = "") -> String {
        data.map { String(format: "%02X", $0) }.joined(separator: separator)
    }

    /// Decodes the Thread MeshCoP `sb` (State Bitmap) low byte per OpenThread
    /// `border_agent_txt_data.cpp`. Inlined here so the formatter (and the
    /// `herald` CLI, which shares this file via symlink) doesn't depend on
    /// `ThreadBorderRouter`.
    private static func threadStateBitmapFlags(from data: Data) -> [String] {
        guard let value = data.last else { return [] }
        var flags: [String] = []
        let connectionMode = value & 0x07
        switch connectionMode {
        case 0: flags.append("Not Connectable")
        case 1: flags.append("PSKc")
        case 2: flags.append("PSKd + Vendor")
        default: flags.append("Connection Mode \(connectionMode)")
        }
        if value & 0x08 != 0 { flags.append("Thread Active") }
        if value & 0x10 != 0 { flags.append("Available") }
        return flags
    }

    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.usesGroupingSeparator = true
        return f
    }()
}

private extension Data {
    /// Returns the UTF-8 string only if the bytes are all printable ASCII
    /// (0x20–0x7E) or TAB (0x09). Conservative on purpose: a 4-byte binary
    /// value that happens to contain `@` and `P` must not be classified as text.
    func utf8StringIfPrintable() -> String? {
        guard !isEmpty else { return nil }
        for byte in self where byte != 0x09 && (byte < 0x20 || byte > 0x7E) {
            return nil
        }
        return String(data: self, encoding: .utf8)
    }
}
