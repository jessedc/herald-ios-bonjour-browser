import ArgumentParser
import Foundation

enum JSONOutput {

    static func encoder(compact: Bool) -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if compact {
            encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        } else {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        }
        return encoder
    }

    static func emit<T: Encodable>(_ value: T, compact: Bool) throws {
        let data = try encoder(compact: compact).encode(value)
        if let str = String(data: data, encoding: .utf8) {
            print(str)
        }
    }

    static func fail(_ message: String, code: String = "error") -> Never {
        let payload: [String: String] = ["error": message, "code": code]
        if let data = try? encoder(compact: true).encode(payload),
           let str = String(data: data, encoding: .utf8) {
            FileHandle.standardError.write(Data((str + "\n").utf8))
        } else {
            FileHandle.standardError.write(Data((message + "\n").utf8))
        }
        Herald.exit(withError: ExitCode.failure)
    }
}

struct TypeEntryDTO: Encodable {
    let type: String
    let description: String?
}

struct InstanceDTO: Encodable {
    let name: String
    let type: String
    let domain: String

    init(_ event: BrowseInstanceEvent) {
        self.name = event.name
        self.type = event.type
        self.domain = event.domain
    }

    init(name: String, type: String, domain: String) {
        self.name = name
        self.type = type
        self.domain = domain
    }
}

struct BrowseResultDTO: Encodable {
    let type: String
    let domain: String
    let durationSeconds: Double
    let instances: [InstanceDTO]
}

struct ResolveResultDTO: Encodable {
    let name: String
    let type: String
    let domain: String
    let description: String?
    let hostname: String
    let port: UInt16
    let ipv4Addresses: [String]
    let ipv6Addresses: [String]
    let txtRecord: [String: TXTValueDTO]
    let resolvedAt: Date
}

/// Structured TXT record entry for CLI JSON output. `hex` is always present so
/// downstream consumers can round-trip binary values without guessing at the
/// encoding; `text` appears only when the formatter classifies the key as
/// UTF-8 text; `decoded` appears for structured formats (uint32 partition ID,
/// state-bitmap flag list, etc.).
struct TXTValueDTO: Encodable {
    let hex: String
    let text: String?
    let decoded: String?
    let label: String?

    init(key: String, value: TXTValue, serviceType: String) {
        let display = TXTValueFormatter.format(key: key, data: value.data, serviceType: serviceType)
        self.hex = TXTValueFormatter.hexString(value.data)
        self.label = TXTRecordLabels.label(for: key, serviceType: serviceType)
        switch display {
        case .text(let s):
            self.text = s
            self.decoded = nil
        case .decoded(let primary, _):
            self.text = nil
            self.decoded = primary
        case .flags(_, let description):
            self.text = nil
            self.decoded = description
        case .hex, .empty:
            self.text = nil
            self.decoded = nil
        }
    }
}

