import Foundation

enum ServiceExporter {

    // MARK: - Single Service Export

    static func plainText(for service: ResolvedService) -> String {
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

        if !service.txtRecord.isEmpty {
            lines.append("TXT Record:")
            for (key, value) in service.txtRecord.sorted(by: { $0.key < $1.key }) {
                lines.append("  \(key) = \(value)")
            }
        }

        return lines.joined(separator: "\n")
    }

    static func json(for service: ResolvedService) -> String {
        let dict: [String: Any] = [
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
