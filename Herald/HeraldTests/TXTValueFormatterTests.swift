import XCTest
@testable import Herald

final class TXTValueFormatterTests: XCTestCase {

    // MARK: - MeshCoP binary keys

    /// The reported bug: Thread Partition ID (`pt`) arrives as 4 raw bytes
    /// `0x0E 0x40 0x1F 0x50` and must render as the decoded uint32
    /// `239,083,344` (= 0x0E401F50), not the mangled UTF-8 string `"@P"`.
    func testMeshcopPartitionIDDecodedAsUInt32() {
        let data = Data([0x0E, 0x40, 0x1F, 0x50])
        let display = TXTValueFormatter.format(key: "pt", data: data, serviceType: "_meshcop._udp")

        XCTAssertEqual(display, .decoded(primary: "239,083,344", hex: "0E401F50"))
        XCTAssertEqual(display.primaryString, "239,083,344 (0x0E401F50)")
    }

    func testMeshcopExtendedPANIDUsesColonSeparatedHex() {
        let data = Data([0xDE, 0xAD, 0x00, 0xBE, 0xEF, 0x00, 0xCA, 0xFE])
        let display = TXTValueFormatter.format(key: "xp", data: data, serviceType: "_meshcop._udp")

        XCTAssertEqual(display, .hex("DE:AD:00:BE:EF:00:CA:FE"))
    }

    func testMeshcopStateBitmapDecodesFlags() {
        // 0x19 = 0b00011001 → connection mode 1 (PSKc) + Thread Active + Available
        let display = TXTValueFormatter.format(
            key: "sb",
            data: Data([0x00, 0x00, 0x00, 0x19]),
            serviceType: "_meshcop._udp"
        )

        guard case .flags(let hex, let description) = display else {
            return XCTFail("expected .flags, got \(display)")
        }
        XCTAssertEqual(hex, "00000019")
        XCTAssertEqual(description, "PSKc, Thread Active, Available")
    }

    func testMeshcopNetworkNameIsText() {
        let display = TXTValueFormatter.format(
            key: "nn",
            data: Data("Office".utf8),
            serviceType: "_meshcop._udp"
        )
        XCTAssertEqual(display, .text("Office"))
    }

    // MARK: - Unknown keys fall back to heuristic

    func testUnknownKeyPrintableAsciiRendersAsText() {
        let display = TXTValueFormatter.format(
            key: "path",
            data: Data("/api".utf8),
            serviceType: "_http._tcp"
        )
        XCTAssertEqual(display, .text("/api"))
    }

    /// Control bytes mixed with printable characters must not be classified as
    /// text. Previously the UTF-8-valid `0x0E 0x40 0x1F 0x50` would pass
    /// through as the mangled string "@P" for unknown keys too.
    func testUnknownKeyWithControlBytesFallsBackToHex() {
        let display = TXTValueFormatter.format(
            key: "custom",
            data: Data([0x0E, 0x40, 0x1F, 0x50]),
            serviceType: "_unknown._tcp"
        )
        XCTAssertEqual(display, .hex("0E401F50"))
    }

    func testEmptyValue() {
        let display = TXTValueFormatter.format(
            key: "flag",
            data: Data(),
            serviceType: "_http._tcp"
        )
        XCTAssertEqual(display, .empty)
        XCTAssertEqual(display.primaryString, "")
    }

    // MARK: - Raw bytes preservation in DNSSDService.parseTXTRecordData

    /// Regression: a value containing control bytes must round-trip through
    /// parseTXTRecordData without being dropped or UTF-8 decoded.
    func testParseTXTRecordPreservesBinaryValueBytes() {
        // Wire format: length-prefixed "pt=<4 bytes>"
        let key: [UInt8] = Array("pt=".utf8)
        let valueBytes: [UInt8] = [0x0E, 0x40, 0x1F, 0x50]
        let entry = key + valueBytes
        let wire: [UInt8] = [UInt8(entry.count)] + entry

        let result = wire.withUnsafeBufferPointer { buf -> [String: TXTValue] in
            DNSSDService.parseTXTRecordData(buf.baseAddress, length: UInt16(wire.count))
        }

        XCTAssertEqual(result["pt"]?.data, Data(valueBytes))
    }

    /// Values may contain `=` bytes after the first one (RFC 6763 §6.3).
    /// Only the first `=` separates key from value.
    func testParseTXTRecordSplitsOnFirstEqualsByte() {
        let entry = Array("k=a=b".utf8)
        let wire: [UInt8] = [UInt8(entry.count)] + entry

        let result = wire.withUnsafeBufferPointer { buf -> [String: TXTValue] in
            DNSSDService.parseTXTRecordData(buf.baseAddress, length: UInt16(wire.count))
        }

        XCTAssertEqual(result["k"]?.asString, "a=b")
    }
}
