import XCTest
@testable import Herald

final class ServiceExporterTests: XCTestCase {

    // MARK: - ResolvedService Plain Text

    func testResolvedServicePlainTextIncludesAllFields() {
        let service = ResolvedService(
            name: "My Printer",
            type: "_ipp._tcp",
            domain: "local.",
            hostname: "printer.local.",
            port: 631,
            ipv4Addresses: ["192.168.1.100"],
            ipv6Addresses: ["fe80::1"],
            txtRecord: ["rp": "ipp/print", "ty": "Laser"],
            resolvedAt: Date()
        )
        let text = ServiceExporter.plainText(for: service)

        // Title banner
        XCTAssertTrue(text.contains("My Printer"))

        // Service section with description
        XCTAssertTrue(text.contains("## Service"))
        XCTAssertTrue(text.contains("Name: My Printer"))
        XCTAssertTrue(text.contains("Type: _ipp._tcp"))
        XCTAssertTrue(text.contains("Domain: local."))
        XCTAssertTrue(text.contains("Description: "))

        // Connection section
        XCTAssertTrue(text.contains("## Connection"))
        XCTAssertTrue(text.contains("Hostname: printer.local."))
        XCTAssertTrue(text.contains("Port: 631"))

        // Addresses (one per line in main section)
        XCTAssertTrue(text.contains("## IPv4 Addresses"))
        XCTAssertTrue(text.contains("192.168.1.100"))
        XCTAssertTrue(text.contains("## IPv6 Addresses"))
        XCTAssertTrue(text.contains("fe80::1"))

        // TXT Record with labels
        XCTAssertTrue(text.contains("## TXT Record"))
        XCTAssertTrue(text.contains("Resource Path (rp) = ipp/print"))
        XCTAssertTrue(text.contains("ty = Laser"))

        // Raw Data section preserves flat format
        XCTAssertTrue(text.contains("## Raw Data"))
        XCTAssertTrue(text.contains("IPv4: 192.168.1.100"))
        XCTAssertTrue(text.contains("IPv6: fe80::1"))
        XCTAssertTrue(text.contains("  rp = ipp/print"))
    }

    func testResolvedServicePlainTextOmitsEmptyAddresses() {
        let service = ResolvedService(
            name: "Test",
            type: "_http._tcp",
            domain: "local.",
            hostname: "test.local.",
            port: 80,
            ipv4Addresses: [],
            ipv6Addresses: [],
            txtRecord: [:],
            resolvedAt: Date()
        )
        let text = ServiceExporter.plainText(for: service)

        XCTAssertFalse(text.contains("IPv4 Addresses"))
        XCTAssertFalse(text.contains("IPv6 Addresses"))
        XCTAssertFalse(text.contains("TXT Record"))
    }

    func testResolvedServicePlainTextMultipleAddresses() {
        let service = ResolvedService(
            name: "Multi",
            type: "_http._tcp",
            domain: "local.",
            hostname: "multi.local.",
            port: 8080,
            ipv4Addresses: ["10.0.0.1", "10.0.0.2"],
            ipv6Addresses: ["fe80::1", "fe80::2"],
            txtRecord: [:],
            resolvedAt: Date()
        )
        let text = ServiceExporter.plainText(for: service)

        // Main section: one address per line
        XCTAssertTrue(text.contains("10.0.0.1"))
        XCTAssertTrue(text.contains("10.0.0.2"))
        XCTAssertTrue(text.contains("fe80::1"))
        XCTAssertTrue(text.contains("fe80::2"))

        // Raw Data section: comma-separated
        XCTAssertTrue(text.contains("IPv4: 10.0.0.1, 10.0.0.2"))
        XCTAssertTrue(text.contains("IPv6: fe80::1, fe80::2"))
    }

    // MARK: - ResolvedService JSON

    func testResolvedServiceJSONIsValidAndContainsFields() {
        let date = Date()
        let service = ResolvedService(
            name: "WebServer",
            type: "_http._tcp",
            domain: "local.",
            hostname: "web.local.",
            port: 8080,
            ipv4Addresses: ["192.168.1.50"],
            ipv6Addresses: [],
            txtRecord: ["path": "/api"],
            resolvedAt: date
        )
        let json = ServiceExporter.json(for: service)

        let data = json.data(using: .utf8)!
        let parsed = try! JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Service section
        let svc = parsed["service"] as! [String: Any]
        XCTAssertEqual(svc["name"] as? String, "WebServer")
        XCTAssertEqual(svc["type"] as? String, "_http._tcp")
        XCTAssertEqual(svc["domain"] as? String, "local.")

        // Connection section
        let conn = parsed["connection"] as! [String: Any]
        XCTAssertEqual(conn["hostname"] as? String, "web.local.")
        XCTAssertEqual(conn["port"] as? UInt16, 8080)

        // Addresses
        XCTAssertEqual(parsed["ipv4Addresses"] as? [String], ["192.168.1.50"])
        XCTAssertEqual(parsed["ipv6Addresses"] as? [String], [])

        // No enrichment for _http._tcp
        XCTAssertNil(parsed["enrichment"])

        // TXT Record with label structure
        let txtRecord = parsed["txtRecord"] as! [String: Any]
        let pathEntry = txtRecord["path"] as! [String: String]
        XCTAssertEqual(pathEntry["key"], "path")
        XCTAssertEqual(pathEntry["value"], "/api")

        // Raw data preserves flat structure
        let raw = parsed["rawData"] as! [String: Any]
        XCTAssertEqual(raw["name"] as? String, "WebServer")
        XCTAssertEqual(raw["hostname"] as? String, "web.local.")
        XCTAssertNotNil(raw["resolvedAt"])
    }

    // MARK: - ResolvedService Reverse DNS

    func testResolvedServicePlainTextIncludesReverseDNS() {
        let service = ResolvedService(
            name: "Test",
            type: "_http._tcp",
            domain: "local.",
            hostname: "test.local.",
            port: 80,
            ipv4Addresses: ["192.168.1.50"],
            ipv6Addresses: [],
            txtRecord: [:],
            reverseDNS: ["192.168.1.50": "myhost.example.com."],
            resolvedAt: Date()
        )
        let text = ServiceExporter.plainText(for: service)

        XCTAssertTrue(text.contains("## Reverse DNS"))
        XCTAssertTrue(text.contains("192.168.1.50 → myhost.example.com."))
    }

    func testResolvedServicePlainTextOmitsEmptyReverseDNS() {
        let service = ResolvedService(
            name: "Test",
            type: "_http._tcp",
            domain: "local.",
            hostname: "test.local.",
            port: 80,
            ipv4Addresses: ["192.168.1.50"],
            ipv6Addresses: [],
            txtRecord: [:],
            resolvedAt: Date()
        )
        let text = ServiceExporter.plainText(for: service)

        XCTAssertFalse(text.contains("Reverse DNS"))
    }

    func testResolvedServiceJSONIncludesReverseDNS() {
        let service = ResolvedService(
            name: "Test",
            type: "_http._tcp",
            domain: "local.",
            hostname: "test.local.",
            port: 80,
            ipv4Addresses: ["10.0.0.1"],
            ipv6Addresses: [],
            txtRecord: [:],
            reverseDNS: ["10.0.0.1": "server.local."],
            resolvedAt: Date()
        )
        let json = ServiceExporter.json(for: service)

        let data = json.data(using: .utf8)!
        let parsed = try! JSONSerialization.jsonObject(with: data) as! [String: Any]

        // Top-level reverse DNS
        let rdns = parsed["reverseDNS"] as? [String: String]
        XCTAssertEqual(rdns?["10.0.0.1"], "server.local.")

        // Also in rawData
        let raw = parsed["rawData"] as! [String: Any]
        let rawRdns = raw["reverseDNS"] as? [String: String]
        XCTAssertEqual(rawRdns?["10.0.0.1"], "server.local.")
    }

    func testResolvedServiceJSONOmitsEmptyReverseDNS() {
        let service = ResolvedService(
            name: "Test",
            type: "_http._tcp",
            domain: "local.",
            hostname: "test.local.",
            port: 80,
            ipv4Addresses: [],
            ipv6Addresses: [],
            txtRecord: [:],
            resolvedAt: Date()
        )
        let json = ServiceExporter.json(for: service)

        let data = json.data(using: .utf8)!
        let parsed = try! JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertNil(parsed["reverseDNS"])
    }

    // MARK: - Enrichment: Thread Border Router

    func testResolvedServicePlainTextThreadEnrichment() {
        let service = ResolvedService(
            name: "HomePod mini",
            type: "_meshcop._udp",
            domain: "local.",
            hostname: "homepod.local.",
            port: 49152,
            ipv4Addresses: ["192.168.1.10"],
            ipv6Addresses: [],
            txtRecord: [
                "nn": "MyThread", "vn": "Apple", "mn": "HomePod mini",
                "tv": "1.3.0", "xp": "dead00beef00cafe", "pi": "face",
                "dn": "DefaultDomain", "bb": "1"
            ],
            resolvedAt: Date()
        )
        let text = ServiceExporter.plainText(for: service)

        XCTAssertTrue(text.contains("## Thread Border Router"))
        XCTAssertTrue(text.contains("Network Name: MyThread"))
        XCTAssertTrue(text.contains("Vendor: Apple"))
        XCTAssertTrue(text.contains("Model: HomePod mini"))
        XCTAssertTrue(text.contains("Thread Version: 1.3.0"))
        XCTAssertTrue(text.contains("Extended PAN ID: dead00beef00cafe"))
        XCTAssertTrue(text.contains("PAN ID: face"))
        XCTAssertTrue(text.contains("Domain Name: DefaultDomain"))
        XCTAssertTrue(text.contains("Backbone Router: Yes"))
    }

    func testResolvedServiceJSONThreadEnrichment() {
        let service = ResolvedService(
            name: "HomePod",
            type: "_meshcop._udp",
            domain: "local.",
            hostname: "homepod.local.",
            port: 49152,
            ipv4Addresses: [],
            ipv6Addresses: [],
            txtRecord: ["nn": "MyThread", "vn": "Apple", "tv": "1.3.0"],
            resolvedAt: Date()
        )
        let json = ServiceExporter.json(for: service)
        let data = json.data(using: .utf8)!
        let parsed = try! JSONSerialization.jsonObject(with: data) as! [String: Any]

        let enrichment = parsed["enrichment"] as! [String: Any]
        XCTAssertEqual(enrichment["type"] as? String, "threadBorderRouter")
        XCTAssertEqual(enrichment["networkName"] as? String, "MyThread")
        XCTAssertEqual(enrichment["vendor"] as? String, "Apple")
        XCTAssertEqual(enrichment["threadVersion"] as? String, "1.3.0")
    }

    // MARK: - Enrichment: Matter Device

    func testResolvedServicePlainTextMatterEnrichment() {
        let service = ResolvedService(
            name: "ABCD1234-0000000000005678",
            type: "_matter._tcp",
            domain: "local.",
            hostname: "light.local.",
            port: 5540,
            ipv4Addresses: ["192.168.1.50"],
            ipv6Addresses: [],
            txtRecord: [
                "VP": "65521+32769", "DT": "256", "DN": "Kitchen Light",
                "D": "3840", "CM": "1", "ICD": "1", "T": "1"
            ],
            resolvedAt: Date()
        )
        let text = ServiceExporter.plainText(for: service)

        XCTAssertTrue(text.contains("## Matter Operational Device"))
        XCTAssertTrue(text.contains("Fabric ID: ABCD1234"))
        XCTAssertTrue(text.contains("Node ID: 5678"))
        XCTAssertTrue(text.contains("Vendor / Product: 65521+32769 (Test Vendor (CSA))"))
        XCTAssertTrue(text.contains("Device Type: 256 (On/Off Light)"))
        XCTAssertTrue(text.contains("Device Name: Kitchen Light"))
        XCTAssertTrue(text.contains("Discriminator: 3840"))
        XCTAssertTrue(text.contains("Commissioning Mode: Basic"))
        XCTAssertTrue(text.contains("Intermittent Device (ICD): Yes (Battery / Sleepy)"))
        XCTAssertTrue(text.contains("TCP Supported: Yes"))
    }

    func testResolvedServicePlainTextMatterNonOperational() {
        let service = ResolvedService(
            name: "NotHex-Name",
            type: "_matter._udp",
            domain: "local.",
            hostname: "device.local.",
            port: 5540,
            ipv4Addresses: [],
            ipv6Addresses: [],
            txtRecord: ["DN": "My Device"],
            resolvedAt: Date()
        )
        let text = ServiceExporter.plainText(for: service)

        // Non-parseable name → "Matter Device" not "Matter Operational Device"
        XCTAssertTrue(text.contains("## Matter Device"))
        XCTAssertFalse(text.contains("Fabric ID:"))
        XCTAssertTrue(text.contains("Device Name: My Device"))
    }

    func testResolvedServiceJSONMatterEnrichment() {
        let service = ResolvedService(
            name: "ABCD1234-0000000000005678",
            type: "_matter._tcp",
            domain: "local.",
            hostname: "light.local.",
            port: 5540,
            ipv4Addresses: [],
            ipv6Addresses: [],
            txtRecord: [
                "VP": "65521+32769", "DT": "256", "DN": "Kitchen Light",
                "D": "3840", "CM": "1"
            ],
            resolvedAt: Date()
        )
        let json = ServiceExporter.json(for: service)
        let data = json.data(using: .utf8)!
        let parsed = try! JSONSerialization.jsonObject(with: data) as! [String: Any]

        let enrichment = parsed["enrichment"] as! [String: Any]
        XCTAssertEqual(enrichment["type"] as? String, "matterOperationalDevice")
        XCTAssertEqual(enrichment["fabricID"] as? String, "ABCD1234")
        XCTAssertEqual(enrichment["nodeID"] as? String, "5678")
        XCTAssertEqual(enrichment["vendorProduct"] as? String, "65521+32769")
        XCTAssertEqual(enrichment["vendorName"] as? String, "Test Vendor (CSA)")
        XCTAssertEqual(enrichment["deviceType"] as? String, "256")
        XCTAssertEqual(enrichment["deviceTypeDescription"] as? String, "On/Off Light")
        XCTAssertEqual(enrichment["deviceName"] as? String, "Kitchen Light")
        XCTAssertEqual(enrichment["discriminator"] as? String, "3840")
        XCTAssertEqual(enrichment["commissioningMode"] as? String, "Basic")
    }

    // MARK: - Enrichment: Matter Commissioner

    func testResolvedServicePlainTextMatterCommissionerEnrichment() {
        let service = ResolvedService(
            name: "MyHub",
            type: "_matterc._udp",
            domain: "local.",
            hostname: "hub.local.",
            port: 5540,
            ipv4Addresses: [],
            ipv6Addresses: [],
            txtRecord: ["DN": "Hub", "VP": "65521+1", "DT": "22"],
            resolvedAt: Date()
        )
        let text = ServiceExporter.plainText(for: service)

        XCTAssertTrue(text.contains("## Matter Commissioner"))
        XCTAssertTrue(text.contains("Device Name: Hub"))
        XCTAssertTrue(text.contains("Vendor / Product: 65521+1 (Test Vendor (CSA))"))
        XCTAssertTrue(text.contains("Device Type: 22 (Root Node)"))
    }

    func testResolvedServiceJSONMatterCommissionerEnrichment() {
        let service = ResolvedService(
            name: "MyHub",
            type: "_matterc._udp",
            domain: "local.",
            hostname: "hub.local.",
            port: 5540,
            ipv4Addresses: [],
            ipv6Addresses: [],
            txtRecord: ["DN": "Hub", "VP": "65521+1"],
            resolvedAt: Date()
        )
        let json = ServiceExporter.json(for: service)
        let data = json.data(using: .utf8)!
        let parsed = try! JSONSerialization.jsonObject(with: data) as! [String: Any]

        let enrichment = parsed["enrichment"] as! [String: Any]
        XCTAssertEqual(enrichment["type"] as? String, "matterCommissioner")
        XCTAssertEqual(enrichment["deviceName"] as? String, "Hub")
        XCTAssertEqual(enrichment["vendorName"] as? String, "Test Vendor (CSA)")
    }

    // MARK: - No Enrichment for Generic Services

    func testResolvedServicePlainTextNoEnrichmentForGenericType() {
        let service = ResolvedService(
            name: "WebServer",
            type: "_http._tcp",
            domain: "local.",
            hostname: "web.local.",
            port: 80,
            ipv4Addresses: [],
            ipv6Addresses: [],
            txtRecord: [:],
            resolvedAt: Date()
        )
        let text = ServiceExporter.plainText(for: service)

        XCTAssertFalse(text.contains("Thread Border Router"))
        XCTAssertFalse(text.contains("Matter"))
    }

    func testResolvedServiceJSONNoEnrichmentForGenericType() {
        let service = ResolvedService(
            name: "WebServer",
            type: "_http._tcp",
            domain: "local.",
            hostname: "web.local.",
            port: 80,
            ipv4Addresses: [],
            ipv6Addresses: [],
            txtRecord: [:],
            resolvedAt: Date()
        )
        let json = ServiceExporter.json(for: service)
        let data = json.data(using: .utf8)!
        let parsed = try! JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertNil(parsed["enrichment"])
    }

    // MARK: - TXT Record Labels

    func testResolvedServicePlainTextTXTLabels() {
        let service = ResolvedService(
            name: "HomePod",
            type: "_meshcop._udp",
            domain: "local.",
            hostname: "homepod.local.",
            port: 49152,
            ipv4Addresses: [],
            ipv6Addresses: [],
            txtRecord: ["nn": "MyThread", "tv": "1.3.0"],
            resolvedAt: Date()
        )
        let text = ServiceExporter.plainText(for: service)

        // TXT section uses human-readable labels
        XCTAssertTrue(text.contains("Network Name (nn) = MyThread"))
        XCTAssertTrue(text.contains("Thread Version (tv) = 1.3.0"))

        // Raw Data section uses raw keys
        XCTAssertTrue(text.contains("  nn = MyThread"))
        XCTAssertTrue(text.contains("  tv = 1.3.0"))
    }

    func testResolvedServicePlainTextTXTEmptyValue() {
        let service = ResolvedService(
            name: "Test",
            type: "_http._tcp",
            domain: "local.",
            hostname: "test.local.",
            port: 80,
            ipv4Addresses: [],
            ipv6Addresses: [],
            txtRecord: ["flag": ""],
            resolvedAt: Date()
        )
        let text = ServiceExporter.plainText(for: service)

        XCTAssertTrue(text.contains("flag = (empty)"))
    }

    func testResolvedServiceJSONTXTRecordLabels() {
        let service = ResolvedService(
            name: "Printer",
            type: "_ipp._tcp",
            domain: "local.",
            hostname: "printer.local.",
            port: 631,
            ipv4Addresses: [],
            ipv6Addresses: [],
            txtRecord: ["rp": "ipp/print"],
            resolvedAt: Date()
        )
        let json = ServiceExporter.json(for: service)
        let data = json.data(using: .utf8)!
        let parsed = try! JSONSerialization.jsonObject(with: data) as! [String: Any]

        let txtRecord = parsed["txtRecord"] as! [String: Any]
        let rpEntry = txtRecord["rp"] as! [String: String]
        XCTAssertEqual(rpEntry["key"], "rp")
        XCTAssertEqual(rpEntry["label"], "Resource Path")
        XCTAssertEqual(rpEntry["value"], "ipp/print")

        // Raw data preserves flat txtRecord
        let raw = parsed["rawData"] as! [String: Any]
        let rawTxt = raw["txtRecord"] as! [String: String]
        XCTAssertEqual(rawTxt["rp"], "ipp/print")
    }

    // MARK: - Raw Data Section

    func testResolvedServicePlainTextRawDataSection() {
        let service = ResolvedService(
            name: "Test",
            type: "_http._tcp",
            domain: "local.",
            hostname: "test.local.",
            port: 80,
            ipv4Addresses: ["10.0.0.1"],
            ipv6Addresses: [],
            txtRecord: ["key": "value"],
            resolvedAt: Date()
        )
        let text = ServiceExporter.plainText(for: service)

        XCTAssertTrue(text.contains("## Raw Data"))
        // Raw section contains the flat format
        XCTAssertTrue(text.contains("Service: Test"))
        XCTAssertTrue(text.contains("Resolved:"))
    }

    func testResolvedServiceJSONRawDataSection() {
        let service = ResolvedService(
            name: "Test",
            type: "_http._tcp",
            domain: "local.",
            hostname: "test.local.",
            port: 80,
            ipv4Addresses: ["10.0.0.1"],
            ipv6Addresses: [],
            txtRecord: [:],
            resolvedAt: Date()
        )
        let json = ServiceExporter.json(for: service)
        let data = json.data(using: .utf8)!
        let parsed = try! JSONSerialization.jsonObject(with: data) as! [String: Any]

        let raw = parsed["rawData"] as! [String: Any]
        XCTAssertEqual(raw["name"] as? String, "Test")
        XCTAssertEqual(raw["type"] as? String, "_http._tcp")
        XCTAssertEqual(raw["hostname"] as? String, "test.local.")
        XCTAssertEqual(raw["port"] as? UInt16, 80)
        XCTAssertEqual(raw["ipv4Addresses"] as? [String], ["10.0.0.1"])
        XCTAssertNotNil(raw["resolvedAt"])
    }

    // MARK: - Service Description

    func testResolvedServicePlainTextIncludesDescription() {
        let service = ResolvedService(
            name: "Printer",
            type: "_ipp._tcp",
            domain: "local.",
            hostname: "printer.local.",
            port: 631,
            ipv4Addresses: [],
            ipv6Addresses: [],
            txtRecord: [:],
            resolvedAt: Date()
        )
        let text = ServiceExporter.plainText(for: service)

        XCTAssertTrue(text.contains("Description:"))
    }

    func testResolvedServiceJSONIncludesDescription() {
        let service = ResolvedService(
            name: "Printer",
            type: "_ipp._tcp",
            domain: "local.",
            hostname: "printer.local.",
            port: 631,
            ipv4Addresses: [],
            ipv6Addresses: [],
            txtRecord: [:],
            resolvedAt: Date()
        )
        let json = ServiceExporter.json(for: service)
        let data = json.data(using: .utf8)!
        let parsed = try! JSONSerialization.jsonObject(with: data) as! [String: Any]

        let svc = parsed["service"] as! [String: Any]
        XCTAssertNotNil(svc["description"])
    }

    // MARK: - ServiceInstance List Plain Text

    func testInstanceListPlainTextGroupsByType() {
        let instances = [
            ServiceInstance(name: "Printer A", type: "_ipp._tcp", domain: "local.", txtRecord: [:]),
            ServiceInstance(name: "Printer B", type: "_ipp._tcp", domain: "local.", txtRecord: [:]),
            ServiceInstance(name: "Web Server", type: "_http._tcp", domain: "local.", txtRecord: [:])
        ]
        let text = ServiceExporter.plainText(for: instances)

        XCTAssertTrue(text.contains("Total services found: 3"))
        XCTAssertTrue(text.contains("_http._tcp (1)"))
        XCTAssertTrue(text.contains("_ipp._tcp (2)"))
        XCTAssertTrue(text.contains("• Printer A"))
        XCTAssertTrue(text.contains("• Printer B"))
        XCTAssertTrue(text.contains("• Web Server"))
    }

    func testInstanceListPlainTextIncludesTxtRecords() {
        let instances = [
            ServiceInstance(name: "Svc", type: "_http._tcp", domain: "local.", txtRecord: ["key": "value"])
        ]
        let text = ServiceExporter.plainText(for: instances)

        XCTAssertTrue(text.contains("key = value"))
    }

    func testInstanceListPlainTextEmptyInput() {
        let text = ServiceExporter.plainText(for: [ServiceInstance]())

        XCTAssertTrue(text.contains("Total services found: 0"))
    }

    func testInstanceListPlainTextSortsTypesThenNames() {
        let instances = [
            ServiceInstance(name: "Zulu", type: "_b._tcp", domain: "local.", txtRecord: [:]),
            ServiceInstance(name: "Alpha", type: "_b._tcp", domain: "local.", txtRecord: [:]),
            ServiceInstance(name: "Echo", type: "_a._tcp", domain: "local.", txtRecord: [:])
        ]
        let text = ServiceExporter.plainText(for: instances)
        let lines = text.components(separatedBy: "\n")

        let aTypeIndex = lines.firstIndex { $0.contains("_a._tcp") }!
        let bTypeIndex = lines.firstIndex { $0.contains("_b._tcp") }!
        XCTAssertLessThan(aTypeIndex, bTypeIndex, "Types should be sorted alphabetically")

        let alphaIndex = lines.firstIndex { $0.contains("Alpha") }!
        let zuluIndex = lines.firstIndex { $0.contains("Zulu") }!
        XCTAssertLessThan(alphaIndex, zuluIndex, "Names within a type should be sorted")
    }

    // MARK: - Instance List with Type/Domain

    func testInstanceListWithTypeDomainIncludesHeader() {
        let instances = [
            ServiceInstance(name: "Test", type: "_http._tcp", domain: "local.", txtRecord: [:])
        ]
        let text = ServiceExporter.plainText(for: instances, type: "_http._tcp", domain: "local.")

        XCTAssertTrue(text.contains("Type: _http._tcp"))
        XCTAssertTrue(text.contains("Domain: local."))
        XCTAssertTrue(text.contains("Instances: 1"))
        XCTAssertTrue(text.contains("• Test"))
    }

    // MARK: - ServiceInstance List JSON

    func testInstanceListJSONIsValid() {
        let instances = [
            ServiceInstance(name: "Svc1", type: "_http._tcp", domain: "local.", txtRecord: ["a": "b"]),
            ServiceInstance(name: "Svc2", type: "_ipp._tcp", domain: "local.", txtRecord: [:])
        ]
        let json = ServiceExporter.json(for: instances)

        let data = json.data(using: .utf8)!
        let parsed = try! JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(parsed["count"] as? Int, 2)
        XCTAssertNotNil(parsed["timestamp"])

        let services = parsed["services"] as! [[String: Any]]
        XCTAssertEqual(services.count, 2)

        let svc1 = services.first { ($0["name"] as? String) == "Svc1" }!
        XCTAssertEqual(svc1["type"] as? String, "_http._tcp")
        XCTAssertEqual((svc1["txtRecord"] as? [String: String])?["a"], "b")
    }

    func testInstanceListJSONEmptyInput() {
        let json = ServiceExporter.json(for: [ServiceInstance]())

        let data = json.data(using: .utf8)!
        let parsed = try! JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(parsed["count"] as? Int, 0)
        XCTAssertEqual((parsed["services"] as? [Any])?.count, 0)
    }

    // MARK: - Thread Border Router Plain Text

    func testThreadBorderRouterPlainText() {
        let routers = [
            ThreadBorderRouter(
                name: "HomePod",
                networkName: "MyThread",
                extendedPANID: "dead00beef00cafe",
                panID: "face",
                vendor: "Apple",
                modelName: "HomePod mini",
                threadVersion: "1.3.0",
                stateBitmap: nil, activeTimestamp: nil, pendingTimestamp: nil,
                sequenceNumber: nil, backboneRouterFlag: nil, domainName: nil,
                deviceDiscriminator: nil,
                hostname: "homepod.local.",
                addresses: ["192.168.1.1"]
            )
        ]
        let text = ServiceExporter.plainText(for: routers)

        XCTAssertTrue(text.contains("Thread Border Routers"))
        XCTAssertTrue(text.contains("Border Routers (1)"))
        XCTAssertTrue(text.contains("• HomePod"))
        XCTAssertTrue(text.contains("Network: MyThread"))
        XCTAssertTrue(text.contains("Vendor: Apple"))
        XCTAssertTrue(text.contains("Model: HomePod mini"))
        XCTAssertTrue(text.contains("Thread Version: 1.3.0"))
    }

    func testThreadBorderRouterPlainTextOmitsNilFields() {
        let routers = [
            ThreadBorderRouter(
                name: "Basic",
                networkName: "Net",
                extendedPANID: "0000",
                panID: nil,
                vendor: nil,
                modelName: nil,
                threadVersion: nil,
                stateBitmap: nil, activeTimestamp: nil, pendingTimestamp: nil,
                sequenceNumber: nil, backboneRouterFlag: nil, domainName: nil,
                deviceDiscriminator: nil,
                hostname: nil,
                addresses: []
            )
        ]
        let text = ServiceExporter.plainText(for: routers)

        XCTAssertTrue(text.contains("• Basic"))
        XCTAssertTrue(text.contains("Network: Net"))
        XCTAssertFalse(text.contains("Vendor:"))
        XCTAssertFalse(text.contains("Model:"))
        XCTAssertFalse(text.contains("Thread Version:"))
    }

    func testThreadBorderRouterPlainTextEmpty() {
        let text = ServiceExporter.plainText(for: [ThreadBorderRouter]())

        XCTAssertTrue(text.contains("No Thread border routers found."))
    }

    // MARK: - Matter Device Plain Text

    func testMatterDevicePlainText() {
        let devices = [
            MatterDevice(
                name: "Light",
                serviceType: "_matter._tcp",
                discriminator: "3840",
                vendorProductID: "65521+32769",
                commissioningMode: "1",
                deviceType: "256",
                deviceName: "Kitchen Light",
                sessionIdleInterval: nil,
                sessionActiveInterval: nil,
                tcpSupported: nil,
                isICD: nil,
                pairingHint: nil,
                hostname: "light.local.",
                addresses: ["192.168.1.50"]
            )
        ]
        let text = ServiceExporter.plainText(for: devices)

        XCTAssertTrue(text.contains("Matter Devices"))
        XCTAssertTrue(text.contains("Devices (1)"))
        XCTAssertTrue(text.contains("• Light"))
        XCTAssertTrue(text.contains("Type: _matter._tcp"))
        XCTAssertTrue(text.contains("Vendor/Product: Test Vendor (CSA) (65521+32769)"))
        XCTAssertTrue(text.contains("Device Name: Kitchen Light"))
        XCTAssertTrue(text.contains("Device Type: On/Off Light (256)"))
        XCTAssertTrue(text.contains("Commissioning: Basic"))
        XCTAssertTrue(text.contains("Discriminator: 3840"))
    }

    func testMatterDevicePlainTextOmitsNilFields() {
        let devices = [
            MatterDevice(
                name: "Minimal",
                serviceType: "_matter._udp",
                discriminator: nil,
                vendorProductID: nil,
                commissioningMode: nil,
                deviceType: nil,
                deviceName: nil,
                sessionIdleInterval: nil,
                sessionActiveInterval: nil,
                tcpSupported: nil,
                isICD: nil,
                pairingHint: nil,
                hostname: nil,
                addresses: []
            )
        ]
        let text = ServiceExporter.plainText(for: devices)

        XCTAssertTrue(text.contains("• Minimal"))
        XCTAssertTrue(text.contains("Type: _matter._udp"))
        XCTAssertTrue(text.contains("Commissioning: Unknown"))
        XCTAssertFalse(text.contains("Vendor/Product:"))
        XCTAssertFalse(text.contains("Device Name:"))
        XCTAssertFalse(text.contains("Device Type:"))
        XCTAssertFalse(text.contains("Discriminator:"))
    }

    func testMatterDevicePlainTextEmpty() {
        let text = ServiceExporter.plainText(for: [MatterDevice]())

        XCTAssertTrue(text.contains("No Matter devices found."))
    }

    func testMatterDeviceCommissioningModes() {
        let modes: [(String?, String)] = [
            ("0", "Not Commissioning"),
            ("1", "Basic"),
            ("2", "Enhanced"),
            (nil, "Unknown"),
            ("99", "99")
        ]
        for (mode, expected) in modes {
            let devices = [
                MatterDevice(
                    name: "Dev",
                    serviceType: "_matter._tcp",
                    discriminator: nil,
                    vendorProductID: nil,
                    commissioningMode: mode,
                    deviceType: nil,
                    deviceName: nil,
                    sessionIdleInterval: nil,
                    sessionActiveInterval: nil,
                    tcpSupported: nil,
                    isICD: nil,
                    pairingHint: nil,
                    hostname: nil,
                    addresses: []
                )
            ]
            let text = ServiceExporter.plainText(for: devices)
            XCTAssertTrue(
                text.contains("Commissioning: \(expected)"),
                "Mode \(mode ?? "nil") should produce '\(expected)'"
            )
        }
    }

    // MARK: - Thread Network Expanded Export

    func testThreadNetworkExpandedPlainText() {
        let routers = [
            ThreadBorderRouter(
                name: "Router1", networkName: "Net", extendedPANID: "0001",
                panID: nil, vendor: "Apple", modelName: nil, threadVersion: "1.3.0",
                stateBitmap: nil, activeTimestamp: nil, pendingTimestamp: nil,
                sequenceNumber: nil, backboneRouterFlag: nil, domainName: nil,
                deviceDiscriminator: nil, hostname: nil, addresses: []
            )
        ]
        let trelPeers = [
            TRELPeer(name: "Peer1", hostname: "peer.local.", addresses: [])
        ]
        let srpServers = [
            SRPServer(name: "SRP1", hostname: "srp.local.", port: 53, addresses: [])
        ]
        let commissioners = [
            MatterCommissioner(
                name: "Comm1", deviceName: "Hub", vendorProductID: "1+2",
                deviceType: nil, commissioningMode: nil, hostname: nil, addresses: []
            )
        ]

        let text = ServiceExporter.plainText(
            borderRouters: routers,
            trelPeers: trelPeers,
            srpServers: srpServers,
            commissioners: commissioners
        )

        XCTAssertTrue(text.contains("Thread Network"))
        XCTAssertTrue(text.contains("Border Routers (1)"))
        XCTAssertTrue(text.contains("• Router1"))
        XCTAssertTrue(text.contains("Vendor: Apple"))

        XCTAssertTrue(text.contains("TREL Peers (1)"))
        XCTAssertTrue(text.contains("• Peer1"))
        XCTAssertTrue(text.contains("Hostname: peer.local."))

        XCTAssertTrue(text.contains("Commissioners (1)"))
        XCTAssertTrue(text.contains("• Comm1"))
        XCTAssertTrue(text.contains("Device Name: Hub"))
        XCTAssertTrue(text.contains("Vendor/Product: 1+2"))

        XCTAssertTrue(text.contains("SRP Servers (1)"))
        XCTAssertTrue(text.contains("• SRP1"))
        XCTAssertTrue(text.contains("Hostname: srp.local."))
        XCTAssertTrue(text.contains("Port: 53"))
    }

    func testThreadNetworkExpandedOmitsEmptySections() {
        let text = ServiceExporter.plainText(
            borderRouters: [
                ThreadBorderRouter(
                    name: "R", networkName: "N", extendedPANID: "0",
                    panID: nil, vendor: nil, modelName: nil, threadVersion: nil,
                    stateBitmap: nil, activeTimestamp: nil, pendingTimestamp: nil,
                    sequenceNumber: nil, backboneRouterFlag: nil, domainName: nil,
                    deviceDiscriminator: nil, hostname: nil, addresses: []
                )
            ],
            trelPeers: [],
            srpServers: [],
            commissioners: []
        )

        XCTAssertTrue(text.contains("Border Routers (1)"))
        XCTAssertFalse(text.contains("TREL Peers"))
        XCTAssertFalse(text.contains("SRP Servers"))
        XCTAssertFalse(text.contains("Commissioners"))
    }

    func testThreadNetworkExpandedAllEmpty() {
        let text = ServiceExporter.plainText(
            borderRouters: [],
            trelPeers: [],
            srpServers: [],
            commissioners: []
        )

        XCTAssertTrue(text.contains("No Thread network devices found."))
    }

    func testThreadNetworkExpandedSRPZeroPort() {
        let text = ServiceExporter.plainText(
            borderRouters: [],
            trelPeers: [],
            srpServers: [SRPServer(name: "S", hostname: nil, port: 0, addresses: [])],
            commissioners: []
        )

        XCTAssertTrue(text.contains("• S"))
        XCTAssertFalse(text.contains("Port:"), "Port 0 should be omitted")
    }

    func testThreadNetworkExpandedTRELNilHostname() {
        let text = ServiceExporter.plainText(
            borderRouters: [],
            trelPeers: [TRELPeer(name: "P", hostname: nil, addresses: [])],
            srpServers: [],
            commissioners: []
        )

        XCTAssertTrue(text.contains("• P"))
        XCTAssertFalse(text.contains("Hostname:"), "Nil hostname should be omitted")
    }
}
