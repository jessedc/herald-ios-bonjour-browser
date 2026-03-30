import Foundation

enum ServiceExporter {

    // MARK: - Single Service Export

    static func plainText(for service: ResolvedService) -> String {
        var lines: [String] = []

        // Title
        lines.append("# \(service.name)")

        // Service section
        lines.append("")
        lines.append("## Service")
        lines.append("Name: \(service.name)")
        lines.append("Type: \(service.type)")
        lines.append("Domain: \(service.domain)")
        if let desc = ServiceTypeDescriptions.description(for: service.type) {
            lines.append("Description: \(desc)")
        }

        // Enrichment section (conditional by service type)
        if let enrichment = ServiceExportEnrichment.plainText(for: service) {
            lines.append("")
            lines.append("## \(enrichment.header)")
            lines.append(contentsOf: enrichment.lines)
        }

        // Connection section
        lines.append("")
        lines.append("## Connection")
        lines.append("Hostname: \(service.hostname)")
        lines.append("Port: \(service.formattedPort)")

        // IPv4 Addresses
        if !service.ipv4Addresses.isEmpty {
            lines.append("")
            lines.append("## IPv4 Addresses")
            for addr in service.ipv4Addresses {
                lines.append(addr)
            }
        }

        // IPv6 Addresses
        if !service.ipv6Addresses.isEmpty {
            lines.append("")
            lines.append("## IPv6 Addresses")
            for addr in service.ipv6Addresses {
                lines.append(addr)
            }
        }

        // Reverse DNS
        if !service.reverseDNS.isEmpty {
            lines.append("")
            lines.append("## Reverse DNS")
            for (ip, hostname) in service.reverseDNS.sorted(by: { $0.key < $1.key }) {
                lines.append("\(ip) → \(hostname)")
            }
        }

        // TXT Record (with human-readable labels)
        if !service.txtRecord.isEmpty {
            lines.append("")
            lines.append("## TXT Record")
            for (key, value) in service.txtRecord.sorted(by: { $0.key < $1.key }) {
                let displayKey = TXTRecordLabels.displayKey(for: key, serviceType: service.type)
                let displayValue = value.isEmpty ? "(empty)" : value
                lines.append("\(displayKey) = \(displayValue)")
            }
        }

        // Raw Data section
        lines.append("")
        lines.append("## Raw Data")
        lines.append(rawPlainText(for: service))

        return lines.joined(separator: "\n")
    }

    static func json(for service: ResolvedService) -> String {
        var dict: [String: Any] = [:]

        // Service section
        var serviceSection: [String: Any] = [
            "name": service.name,
            "type": service.type,
            "domain": service.domain
        ]
        if let desc = ServiceTypeDescriptions.description(for: service.type) {
            serviceSection["description"] = desc
        }
        dict["service"] = serviceSection

        // Enrichment section
        if let enrichment = ServiceExportEnrichment.json(for: service) {
            dict["enrichment"] = enrichment
        }

        // Connection section
        dict["connection"] = [
            "hostname": service.hostname,
            "port": service.port
        ] as [String: Any]

        // Addresses
        dict["ipv4Addresses"] = service.ipv4Addresses
        dict["ipv6Addresses"] = service.ipv6Addresses

        // Reverse DNS
        if !service.reverseDNS.isEmpty {
            dict["reverseDNS"] = service.reverseDNS
        }

        // TXT Record (with labels)
        if !service.txtRecord.isEmpty {
            var labeled: [String: Any] = [:]
            for (key, value) in service.txtRecord {
                var entry: [String: String] = ["key": key, "value": value]
                if let label = TXTRecordLabels.label(for: key, serviceType: service.type) {
                    entry["label"] = label
                }
                labeled[key] = entry
            }
            dict["txtRecord"] = labeled
        }

        // Raw data
        dict["rawData"] = rawJSONDict(for: service)

        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    // MARK: - All Services Export

    static func plainText(for instances: [ServiceInstance]) -> String {
        var lines: [String] = []
        lines.append("Bonjour Services Discovery — \(ISO8601DateFormatter().string(from: Date()))")
        lines.append("Total services found: \(instances.count)")
        lines.append(String(repeating: "─", count: 50))

        let grouped = Dictionary(grouping: instances, by: { $0.type })
        for (type, services) in grouped.sorted(by: { $0.key < $1.key }) {
            lines.append("")
            lines.append("\(type) (\(services.count))")
            for service in services.sorted(by: { $0.name < $1.name }) {
                lines.append("  • \(service.name)")
                if !service.txtRecord.isEmpty {
                    for (key, value) in service.txtRecord.sorted(by: { $0.key < $1.key }) {
                        lines.append("      \(key) = \(value)")
                    }
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Instance List Export

    static func plainText(for instances: [ServiceInstance], type: String, domain: String) -> String {
        var lines: [String] = []
        let description = ServiceTypeDescriptions.description(for: type) ?? type
        lines.append("\(description) — \(ISO8601DateFormatter().string(from: Date()))")
        lines.append("Type: \(type)")
        lines.append("Domain: \(domain)")
        lines.append("Instances: \(instances.count)")
        lines.append(String(repeating: "─", count: 50))

        for instance in instances.sorted(by: { $0.name < $1.name }) {
            lines.append("  • \(instance.name)")
            if !instance.txtRecord.isEmpty {
                for (key, value) in instance.txtRecord.sorted(by: { $0.key < $1.key }) {
                    lines.append("      \(key) = \(value)")
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Thread Export

    static func plainText(for borderRouters: [ThreadBorderRouter]) -> String {
        var lines: [String] = []
        lines.append("Thread Border Routers — \(ISO8601DateFormatter().string(from: Date()))")
        lines.append(String(repeating: "─", count: 50))

        if !borderRouters.isEmpty {
            lines.append("")
            lines.append("Border Routers (\(borderRouters.count))")
            for router in borderRouters {
                lines.append("  • \(router.name)")
                lines.append("      Network: \(router.networkName)")
                if let vendor = router.vendor {
                    lines.append("      Vendor: \(vendor)")
                }
                if let model = router.modelName {
                    lines.append("      Model: \(model)")
                }
                if let version = router.threadVersion {
                    lines.append("      Thread Version: \(version)")
                }
                if !router.stateBitmapFlags.isEmpty {
                    lines.append("      State: \(router.stateBitmapFlags.joined(separator: ", "))")
                }
                if let dn = router.domainName {
                    lines.append("      Domain: \(dn)")
                }
                if router.backboneRouterFlag != nil {
                    lines.append("      Backbone Router: Yes")
                }
            }
        } else {
            lines.append("")
            lines.append("No Thread border routers found.")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Matter Export

    static func plainText(for devices: [MatterDevice]) -> String {
        var lines: [String] = []
        lines.append("Matter Devices — \(ISO8601DateFormatter().string(from: Date()))")
        lines.append(String(repeating: "─", count: 50))

        if !devices.isEmpty {
            lines.append("")
            lines.append("Devices (\(devices.count))")
            for device in devices {
                lines.append("  • \(device.name)")
                lines.append("      Type: \(device.serviceType)")
                if let vp = device.vendorProductID {
                    if let vendorName = device.vendorName {
                        lines.append("      Vendor/Product: \(vendorName) (\(vp))")
                    } else {
                        lines.append("      Vendor/Product: \(vp)")
                    }
                }
                if let dn = device.deviceName {
                    lines.append("      Device Name: \(dn)")
                }
                if let dt = device.deviceType {
                    let desc = device.deviceTypeDescription
                    lines.append("      Device Type: \(desc) (\(dt))")
                }
                lines.append("      Commissioning: \(device.commissioningModeDescription)")
                if let d = device.discriminator {
                    lines.append("      Discriminator: \(d)")
                }
            }
        } else {
            lines.append("")
            lines.append("No Matter devices found.")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Thread Network Export (Expanded)

    static func plainText(
        borderRouters: [ThreadBorderRouter],
        trelPeers: [TRELPeer],
        srpServers: [SRPServer],
        commissioners: [MatterCommissioner]
    ) -> String {
        var lines: [String] = []
        lines.append("Thread Network — \(ISO8601DateFormatter().string(from: Date()))")
        lines.append(String(repeating: "─", count: 50))

        if !borderRouters.isEmpty {
            lines.append("")
            lines.append("Border Routers (\(borderRouters.count))")
            for router in borderRouters {
                lines.append("  • \(router.name)")
                lines.append("      Network: \(router.networkName)")
                if let vendor = router.vendor {
                    lines.append("      Vendor: \(vendor)")
                }
                if let model = router.modelName {
                    lines.append("      Model: \(model)")
                }
                if let version = router.threadVersion {
                    lines.append("      Thread Version: \(version)")
                }
                if !router.stateBitmapFlags.isEmpty {
                    lines.append("      State: \(router.stateBitmapFlags.joined(separator: ", "))")
                }
                if let dn = router.domainName {
                    lines.append("      Domain: \(dn)")
                }
                if router.backboneRouterFlag != nil {
                    lines.append("      Backbone Router: Yes")
                }
            }
        }

        if !trelPeers.isEmpty {
            lines.append("")
            lines.append("TREL Peers (\(trelPeers.count))")
            for peer in trelPeers {
                lines.append("  • \(peer.name)")
                if let hostname = peer.hostname {
                    lines.append("      Hostname: \(hostname)")
                }
            }
        }

        if !commissioners.isEmpty {
            lines.append("")
            lines.append("Commissioners (\(commissioners.count))")
            for comm in commissioners {
                lines.append("  • \(comm.name)")
                if let dn = comm.deviceName {
                    lines.append("      Device Name: \(dn)")
                }
                if let vp = comm.vendorProductID {
                    if let vendorName = comm.vendorName {
                        lines.append("      Vendor/Product: \(vendorName) (\(vp))")
                    } else {
                        lines.append("      Vendor/Product: \(vp)")
                    }
                }
                if comm.deviceType != nil {
                    lines.append("      Device Type: \(comm.deviceTypeDescription)")
                }
            }
        }

        if !srpServers.isEmpty {
            lines.append("")
            lines.append("SRP Servers (\(srpServers.count))")
            for server in srpServers {
                lines.append("  • \(server.name)")
                if let hostname = server.hostname {
                    lines.append("      Hostname: \(hostname)")
                }
                if server.port > 0 {
                    lines.append("      Port: \(server.port)")
                }
            }
        }

        let total = borderRouters.count + trelPeers.count + srpServers.count + commissioners.count
        if total == 0 {
            lines.append("")
            lines.append("No Thread network devices found.")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Thread JSON Export

    static func json(for borderRouters: [ThreadBorderRouter]) -> String {
        let items = borderRouters.map { router in borderRouterDict(router) }
        return jsonString(from: items)
    }

    static func json(for trelPeers: [TRELPeer]) -> String {
        let items = trelPeers.map { peer -> [String: Any] in
            var dict: [String: Any] = [
                "name": peer.name,
                "addresses": peer.addresses
            ]
            if let v = peer.hostname { dict["hostname"] = v }
            return dict
        }
        return jsonString(from: items)
    }

    static func json(for srpServers: [SRPServer]) -> String {
        let items = srpServers.map { server -> [String: Any] in
            var dict: [String: Any] = [
                "name": server.name,
                "port": server.port,
                "addresses": server.addresses
            ]
            if let v = server.hostname { dict["hostname"] = v }
            return dict
        }
        return jsonString(from: items)
    }

    static func json(for commissioners: [MatterCommissioner]) -> String {
        let items = commissioners.map { comm in commissionerDict(comm) }
        return jsonString(from: items)
    }

    static func json(
        borderRouters: [ThreadBorderRouter],
        trelPeers: [TRELPeer],
        srpServers: [SRPServer],
        commissioners: [MatterCommissioner]
    ) -> String {
        let routerItems = borderRouters.map { router in borderRouterDict(router) }
        let trelItems = trelPeers.map { peer -> [String: Any] in
            var dict: [String: Any] = [
                "name": peer.name,
                "addresses": peer.addresses
            ]
            if let v = peer.hostname { dict["hostname"] = v }
            return dict
        }
        let srpItems = srpServers.map { server -> [String: Any] in
            var dict: [String: Any] = [
                "name": server.name,
                "port": server.port,
                "addresses": server.addresses
            ]
            if let v = server.hostname { dict["hostname"] = v }
            return dict
        }
        let commItems = commissioners.map { comm in commissionerDict(comm) }
        let dict: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "borderRouters": routerItems,
            "trelPeers": trelItems,
            "srpServers": srpItems,
            "commissioners": commItems
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    // MARK: - Matter JSON Export

    static func json(for devices: [MatterDevice]) -> String {
        let items = devices.map { device -> [String: Any] in
            var dict: [String: Any] = [
                "name": device.name,
                "serviceType": device.serviceType,
                "addresses": device.addresses
            ]
            if let v = device.discriminator { dict["discriminator"] = v }
            if let v = device.vendorProductID { dict["vendorProductID"] = v }
            if let vendorName = device.vendorName { dict["vendorName"] = vendorName }
            if let v = device.commissioningMode { dict["commissioningMode"] = v }
            if let v = device.deviceType {
                dict["deviceType"] = v
                dict["deviceTypeDescription"] = device.deviceTypeDescription
            }
            if let v = device.deviceName { dict["deviceName"] = v }
            if let v = device.sessionIdleInterval { dict["sessionIdleInterval"] = v }
            if let v = device.sessionActiveInterval { dict["sessionActiveInterval"] = v }
            if let v = device.tcpSupported { dict["tcpSupported"] = v }
            if let v = device.isICD { dict["isICD"] = v }
            if let v = device.pairingHint { dict["pairingHint"] = v }
            if let v = device.hostname { dict["hostname"] = v }
            return dict
        }
        let dict: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "count": devices.count,
            "devices": items
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    // MARK: - All Services JSON Export

    static func json(for instances: [ServiceInstance]) -> String {
        let items = instances.map { instance -> [String: Any] in
            [
                "name": instance.name,
                "type": instance.type,
                "domain": instance.domain,
                "txtRecord": instance.txtRecord
            ]
        }
        let dict: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "count": instances.count,
            "services": items
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    // MARK: - Single Service Helpers

    private static func rawPlainText(for service: ResolvedService) -> String {
        var lines: [String] = []
        lines.append("Service: \(service.name)")
        lines.append("Type: \(service.type)")
        lines.append("Domain: \(service.domain)")
        lines.append("Hostname: \(service.hostname)")
        lines.append("Port: \(service.port)")

        if !service.ipv4Addresses.isEmpty {
            lines.append("IPv4: \(service.ipv4Addresses.joined(separator: ", "))")
        }
        if !service.ipv6Addresses.isEmpty {
            lines.append("IPv6: \(service.ipv6Addresses.joined(separator: ", "))")
        }

        if !service.reverseDNS.isEmpty {
            lines.append("Reverse DNS:")
            for (ip, hostname) in service.reverseDNS.sorted(by: { $0.key < $1.key }) {
                lines.append("  \(ip) → \(hostname)")
            }
        }

        if !service.txtRecord.isEmpty {
            lines.append("TXT Record:")
            for (key, value) in service.txtRecord.sorted(by: { $0.key < $1.key }) {
                lines.append("  \(key) = \(value)")
            }
        }

        lines.append("Resolved: \(ISO8601DateFormatter().string(from: service.resolvedAt))")

        return lines.joined(separator: "\n")
    }

    private static func rawJSONDict(for service: ResolvedService) -> [String: Any] {
        var dict: [String: Any] = [
            "name": service.name,
            "type": service.type,
            "domain": service.domain,
            "hostname": service.hostname,
            "port": service.port,
            "ipv4Addresses": service.ipv4Addresses,
            "ipv6Addresses": service.ipv6Addresses,
            "txtRecord": service.txtRecord,
            "resolvedAt": ISO8601DateFormatter().string(from: service.resolvedAt)
        ]
        if !service.reverseDNS.isEmpty {
            dict["reverseDNS"] = service.reverseDNS
        }
        return dict
    }

    // MARK: - Helpers

    private static func borderRouterDict(_ router: ThreadBorderRouter) -> [String: Any] {
        var dict: [String: Any] = [
            "name": router.name,
            "networkName": router.networkName,
            "extendedPANID": router.extendedPANID,
            "addresses": router.addresses
        ]
        if let v = router.panID { dict["panID"] = v }
        if let v = router.vendor { dict["vendor"] = v }
        if let v = router.modelName { dict["modelName"] = v }
        if let v = router.threadVersion { dict["threadVersion"] = v }
        if let v = router.stateBitmap {
            dict["stateBitmap"] = v
            if !router.stateBitmapFlags.isEmpty {
                dict["stateBitmapFlags"] = router.stateBitmapFlags
            }
        }
        if let v = router.activeTimestamp { dict["activeTimestamp"] = v }
        if let v = router.pendingTimestamp { dict["pendingTimestamp"] = v }
        if let v = router.sequenceNumber { dict["sequenceNumber"] = v }
        if let v = router.backboneRouterFlag { dict["backboneRouterFlag"] = v }
        if let v = router.domainName { dict["domainName"] = v }
        if let v = router.deviceDiscriminator { dict["deviceDiscriminator"] = v }
        if let v = router.hostname { dict["hostname"] = v }
        return dict
    }

    private static func commissionerDict(_ comm: MatterCommissioner) -> [String: Any] {
        var dict: [String: Any] = [
            "name": comm.name,
            "addresses": comm.addresses
        ]
        if let v = comm.deviceName { dict["deviceName"] = v }
        if let v = comm.vendorProductID { dict["vendorProductID"] = v }
        if let vendorName = comm.vendorName { dict["vendorName"] = vendorName }
        if let v = comm.deviceType {
            dict["deviceType"] = v
            dict["deviceTypeDescription"] = comm.deviceTypeDescription
        }
        if let v = comm.commissioningMode { dict["commissioningMode"] = v }
        if let v = comm.hostname { dict["hostname"] = v }
        return dict
    }

    private static func jsonString(from array: [[String: Any]]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: array, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return str
    }
}

// MARK: - Bluetooth Export

extension ServiceExporter {

    static func plainText(for peripherals: [BLEPeripheral]) -> String {
        var lines: [String] = []
        lines.append("Matter Commissioning Devices — \(ISO8601DateFormatter().string(from: Date()))")
        lines.append(String(repeating: "─", count: 50))

        if !peripherals.isEmpty {
            lines.append("")
            lines.append("Devices (\(peripherals.count))")
            for peripheral in peripherals {
                appendPeripheralLines(peripheral, to: &lines)
            }
        } else {
            lines.append("")
            lines.append("No Matter commissioning devices found.")
        }

        return lines.joined(separator: "\n")
    }

    static func json(for peripherals: [BLEPeripheral]) -> String {
        let items = peripherals.map { peripheral -> [String: Any] in
            var dict: [String: Any] = [
                "identifier": peripheral.identifier.uuidString,
                "rssi": peripheral.rssi,
                "isConnectable": peripheral.isConnectable,
                "signalDescription": peripheral.signalDescription
            ]
            if let name = peripheral.localName { dict["localName"] = name }
            if !peripheral.advertisedServiceUUIDs.isEmpty {
                dict["advertisedServiceUUIDs"] = peripheral.advertisedServiceUUIDs
            }
            if let disc = peripheral.matterDiscriminator { dict["matterDiscriminator"] = disc }
            if let vendor = peripheral.matterVendorID {
                dict["matterVendorID"] = vendor
                if let vendorName = peripheral.matterVendorName { dict["matterVendorName"] = vendorName }
            }
            if let product = peripheral.matterProductID { dict["matterProductID"] = product }
            return dict
        }
        let dict: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "count": peripherals.count,
            "peripherals": items
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    static func plainText(for peripheral: BLEPeripheral) -> String {
        var lines: [String] = []

        // Title
        lines.append("# \(peripheral.displayName)")

        // Device section
        lines.append("")
        lines.append("## Device")
        lines.append("Name: \(peripheral.displayName)")
        lines.append("Identifier: \(peripheral.identifier.uuidString)")
        lines.append("Connectable: \(peripheral.isConnectable ? "Yes" : "No")")

        // Signal section
        lines.append("")
        lines.append("## Signal")
        lines.append("RSSI: \(peripheral.rssi) dBm")
        lines.append("Strength: \(peripheral.signalDescription)")

        // Matter Commissioning section (conditional)
        if peripheral.matterServiceData != nil {
            lines.append("")
            lines.append("## Matter Commissioning")
            if let discriminator = peripheral.matterDiscriminator {
                lines.append("Discriminator: \(discriminator)")
            }
            if let vendorID = peripheral.matterVendorID {
                if let vendorName = peripheral.matterVendorName {
                    lines.append("Vendor: \(vendorID) (\(vendorName))")
                } else {
                    lines.append("Vendor ID: \(vendorID)")
                }
            }
            if let productID = peripheral.matterProductID {
                lines.append("Product ID: \(productID)")
            }
        }

        // Advertised Services section (conditional)
        if !peripheral.advertisedServiceUUIDs.isEmpty {
            lines.append("")
            lines.append("## Advertised Services")
            for uuid in peripheral.advertisedServiceUUIDs {
                lines.append(uuid)
            }
        }

        // Manufacturer Data section (conditional)
        if let manufacturerData = peripheral.manufacturerData, !manufacturerData.isEmpty {
            lines.append("")
            lines.append("## Manufacturer Data")
            lines.append(manufacturerData.map { String(format: "%02X", $0) }.joined(separator: " "))
        }

        // Timing section
        lines.append("")
        lines.append("## Timing")
        lines.append("First Seen: \(ISO8601DateFormatter().string(from: peripheral.firstSeen))")
        lines.append("Last Seen: \(ISO8601DateFormatter().string(from: peripheral.lastSeen))")

        // Raw Data section
        lines.append("")
        lines.append("## Raw Data")
        lines.append(rawPlainText(for: peripheral))

        return lines.joined(separator: "\n")
    }

    static func json(for peripheral: BLEPeripheral) -> String {
        var dict: [String: Any] = [:]

        // Device section
        var deviceSection: [String: Any] = [
            "name": peripheral.displayName,
            "identifier": peripheral.identifier.uuidString,
            "isConnectable": peripheral.isConnectable
        ]
        if let name = peripheral.localName { deviceSection["localName"] = name }
        dict["device"] = deviceSection

        // Signal section
        dict["signal"] = [
            "rssi": peripheral.rssi,
            "description": peripheral.signalDescription
        ] as [String: Any]

        // Matter Commissioning section (conditional)
        if peripheral.matterServiceData != nil {
            var matterSection: [String: Any] = [:]
            if let disc = peripheral.matterDiscriminator { matterSection["discriminator"] = disc }
            if let vendor = peripheral.matterVendorID {
                matterSection["vendorID"] = vendor
                if let vendorName = peripheral.matterVendorName { matterSection["vendorName"] = vendorName }
            }
            if let product = peripheral.matterProductID { matterSection["productID"] = product }
            dict["matterCommissioning"] = matterSection
        }

        // Advertised Services
        if !peripheral.advertisedServiceUUIDs.isEmpty {
            dict["advertisedServices"] = peripheral.advertisedServiceUUIDs
        }

        // Manufacturer Data (conditional)
        if let data = peripheral.manufacturerData, !data.isEmpty {
            dict["manufacturerData"] = data.map { String(format: "%02X", $0) }.joined(separator: " ")
        }

        // Timing section
        dict["timing"] = [
            "firstSeen": ISO8601DateFormatter().string(from: peripheral.firstSeen),
            "lastSeen": ISO8601DateFormatter().string(from: peripheral.lastSeen)
        ]

        // Raw data
        dict["rawData"] = rawJSONDict(for: peripheral)

        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    private static func rawPlainText(for peripheral: BLEPeripheral) -> String {
        var lines: [String] = []
        lines.append("Name: \(peripheral.displayName)")
        lines.append("Identifier: \(peripheral.identifier.uuidString)")
        lines.append("RSSI: \(peripheral.rssi) dBm (\(peripheral.signalDescription))")
        lines.append("Connectable: \(peripheral.isConnectable ? "Yes" : "No")")
        if !peripheral.advertisedServiceUUIDs.isEmpty {
            lines.append("Services: \(peripheral.advertisedServiceUUIDs.joined(separator: ", "))")
        }
        if let data = peripheral.matterServiceData {
            lines.append("Matter Service Data: \(data.map { String(format: "%02X", $0) }.joined(separator: " "))")
        }
        if let data = peripheral.manufacturerData, !data.isEmpty {
            lines.append("Manufacturer Data: \(data.map { String(format: "%02X", $0) }.joined(separator: " "))")
        }
        if let disc = peripheral.matterDiscriminator { lines.append("Discriminator: \(disc)") }
        if let vendor = peripheral.matterVendorID {
            if let vendorName = peripheral.matterVendorName {
                lines.append("Vendor: \(vendor) (\(vendorName))")
            } else {
                lines.append("Vendor ID: \(vendor)")
            }
        }
        if let product = peripheral.matterProductID { lines.append("Product ID: \(product)") }
        lines.append("First Seen: \(ISO8601DateFormatter().string(from: peripheral.firstSeen))")
        lines.append("Last Seen: \(ISO8601DateFormatter().string(from: peripheral.lastSeen))")
        return lines.joined(separator: "\n")
    }

    private static func rawJSONDict(for peripheral: BLEPeripheral) -> [String: Any] {
        var dict: [String: Any] = [
            "name": peripheral.displayName,
            "identifier": peripheral.identifier.uuidString,
            "rssi": peripheral.rssi,
            "signalDescription": peripheral.signalDescription,
            "isConnectable": peripheral.isConnectable,
            "firstSeen": ISO8601DateFormatter().string(from: peripheral.firstSeen),
            "lastSeen": ISO8601DateFormatter().string(from: peripheral.lastSeen)
        ]
        if let name = peripheral.localName { dict["localName"] = name }
        if !peripheral.advertisedServiceUUIDs.isEmpty {
            dict["advertisedServiceUUIDs"] = peripheral.advertisedServiceUUIDs
        }
        if let data = peripheral.matterServiceData {
            dict["matterServiceData"] = data.map { String(format: "%02X", $0) }.joined(separator: " ")
        }
        if let data = peripheral.manufacturerData, !data.isEmpty {
            dict["manufacturerData"] = data.map { String(format: "%02X", $0) }.joined(separator: " ")
        }
        if let disc = peripheral.matterDiscriminator { dict["matterDiscriminator"] = disc }
        if let vendor = peripheral.matterVendorID {
            dict["matterVendorID"] = vendor
            if let vendorName = peripheral.matterVendorName { dict["matterVendorName"] = vendorName }
        }
        if let product = peripheral.matterProductID { dict["matterProductID"] = product }
        return dict
    }

    private static func appendPeripheralLines(_ peripheral: BLEPeripheral, to lines: inout [String]) {
        lines.append("  • \(peripheral.displayName)")
        lines.append("      Signal: \(peripheral.rssi) dBm (\(peripheral.signalDescription))")
        if !peripheral.advertisedServiceUUIDs.isEmpty {
            lines.append("      Services: \(peripheral.advertisedServiceUUIDs.joined(separator: ", "))")
        }
        lines.append("      Connectable: \(peripheral.isConnectable ? "Yes" : "No")")
        if let disc = peripheral.matterDiscriminator {
            lines.append("      Discriminator: \(disc)")
        }
        if let vendor = peripheral.matterVendorID {
            if let vendorName = peripheral.matterVendorName {
                lines.append("      Vendor: \(vendor) (\(vendorName))")
            } else {
                lines.append("      Vendor ID: \(vendor)")
            }
        }
        if let product = peripheral.matterProductID {
            lines.append("      Product ID: \(product)")
        }
    }
}
