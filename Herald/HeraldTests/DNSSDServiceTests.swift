import XCTest
@testable import Herald

final class DNSSDServiceTests: XCTestCase {

    // MARK: - reverseDNSName(ipv4:)

    func testReverseDNSNameIPv4Basic() {
        let result = DNSSDService.reverseDNSName(ipv4: "192.168.1.50")
        XCTAssertEqual(result, "50.1.168.192.in-addr.arpa")
    }

    func testReverseDNSNameIPv4AllZeros() {
        let result = DNSSDService.reverseDNSName(ipv4: "0.0.0.0")
        XCTAssertEqual(result, "0.0.0.0.in-addr.arpa")
    }

    func testReverseDNSNameIPv4MaxValues() {
        let result = DNSSDService.reverseDNSName(ipv4: "255.255.255.255")
        XCTAssertEqual(result, "255.255.255.255.in-addr.arpa")
    }

    func testReverseDNSNameIPv4Loopback() {
        let result = DNSSDService.reverseDNSName(ipv4: "127.0.0.1")
        XCTAssertEqual(result, "1.0.0.127.in-addr.arpa")
    }

    func testReverseDNSNameIPv4Invalid() {
        XCTAssertNil(DNSSDService.reverseDNSName(ipv4: "not.an.ip"))
        XCTAssertNil(DNSSDService.reverseDNSName(ipv4: "192.168.1"))
        XCTAssertNil(DNSSDService.reverseDNSName(ipv4: "192.168.1.256"))
        XCTAssertNil(DNSSDService.reverseDNSName(ipv4: ""))
    }

    // MARK: - reverseDNSName(ipv6:)

    func testReverseDNSNameIPv6Full() {
        let result = DNSSDService.reverseDNSName(ipv6: "2001:0db8:0000:0000:0000:0000:0000:0001")
        XCTAssertEqual(result, "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.b.d.0.1.0.0.2.ip6.arpa")
    }

    func testReverseDNSNameIPv6Compressed() {
        let result = DNSSDService.reverseDNSName(ipv6: "fe80::1")
        XCTAssertEqual(result, "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.e.f.ip6.arpa")
    }

    func testReverseDNSNameIPv6WithScope() {
        let result = DNSSDService.reverseDNSName(ipv6: "fe80::1%en0")
        XCTAssertEqual(result, "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.e.f.ip6.arpa")
    }

    func testReverseDNSNameIPv6LinkLocal() {
        let result = DNSSDService.reverseDNSName(ipv6: "fe80::1a2b:3c4d:5e6f:7890")
        XCTAssertEqual(result, "0.9.8.7.f.6.e.5.d.4.c.3.b.2.a.1.0.0.0.0.0.0.0.0.0.0.0.0.0.8.e.f.ip6.arpa")
    }

    func testReverseDNSNameIPv6Loopback() {
        let result = DNSSDService.reverseDNSName(ipv6: "::1")
        XCTAssertEqual(result, "1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa")
    }

    func testReverseDNSNameIPv6Invalid() {
        XCTAssertNil(DNSSDService.reverseDNSName(ipv6: "not-an-ipv6"))
    }

    // MARK: - parseDNSName

    func testParseDNSNameBasic() {
        // "foo.local." encoded as [3, f, o, o, 5, l, o, c, a, l, 0]
        let bytes: [UInt8] = [3, 102, 111, 111, 5, 108, 111, 99, 97, 108, 0]
        let result = bytes.withUnsafeBufferPointer { buf in
            DNSSDService.parseDNSName(from: buf.baseAddress!, length: buf.count)
        }
        XCTAssertEqual(result, "foo.local.")
    }

    func testParseDNSNameSingleLabel() {
        // "test." encoded as [4, t, e, s, t, 0]
        let bytes: [UInt8] = [4, 116, 101, 115, 116, 0]
        let result = bytes.withUnsafeBufferPointer { buf in
            DNSSDService.parseDNSName(from: buf.baseAddress!, length: buf.count)
        }
        XCTAssertEqual(result, "test.")
    }

    func testParseDNSNameThreeLabels() {
        // "a.b.c." encoded as [1, a, 1, b, 1, c, 0]
        let bytes: [UInt8] = [1, 97, 1, 98, 1, 99, 0]
        let result = bytes.withUnsafeBufferPointer { buf in
            DNSSDService.parseDNSName(from: buf.baseAddress!, length: buf.count)
        }
        XCTAssertEqual(result, "a.b.c.")
    }

    func testParseDNSNameEmptyReturnsNil() {
        let bytes: [UInt8] = [0]
        let result = bytes.withUnsafeBufferPointer { buf in
            DNSSDService.parseDNSName(from: buf.baseAddress!, length: buf.count)
        }
        XCTAssertNil(result)
    }

    func testParseDNSNameTruncatedReturnsNil() {
        // Label says 10 bytes but only 3 available
        let bytes: [UInt8] = [10, 102, 111, 111]
        let result = bytes.withUnsafeBufferPointer { buf in
            DNSSDService.parseDNSName(from: buf.baseAddress!, length: buf.count)
        }
        XCTAssertNil(result)
    }
}
