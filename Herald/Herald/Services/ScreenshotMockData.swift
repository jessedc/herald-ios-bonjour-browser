// swiftlint:disable function_body_length type_body_length
import Foundation

/// Realistic mock data for App Store screenshot capture.
///
/// Generated from sanitized real network exports. To regenerate:
/// 1. Export JSON from each screen on a real network
/// 2. Run `scripts/sanitize_export.py` with the 4 JSON files
/// 3. Replace this file with the script output
enum ScreenshotMockData {

    // MARK: - All Services

    static let allServicesInstances: [ServiceInstance] = [
        // AirPlay
        ServiceInstance(
            name: "Living Room",
            type: "_airplay._tcp",
            domain: "local.",
            txtRecord: [:]
        ),
        ServiceInstance(
            name: "Bedroom HomePod",
            type: "_airplay._tcp",
            domain: "local.",
            txtRecord: [:]
        ),
        ServiceInstance(
            name: "Office Apple TV",
            type: "_airplay._tcp",
            domain: "local.",
            txtRecord: [:]
        ),
        ServiceInstance(
            name: "Kitchen Display",
            type: "_airplay._tcp",
            domain: "local.",
            txtRecord: [:]
        ),
        // Companion Link
        ServiceInstance(
            name: "MacBook Pro",
            type: "_companion-link._tcp",
            domain: "local.",
            txtRecord: [:]
        ),
        ServiceInstance(
            name: "iPad",
            type: "_companion-link._tcp",
            domain: "local.",
            txtRecord: [:]
        ),
        // Home Sharing
        ServiceInstance(
            name: "Home Library",
            type: "_home-sharing._tcp",
            domain: "local.",
            txtRecord: [:]
        ),
        // HTTP
        ServiceInstance(
            name: "Synology NAS",
            type: "_http._tcp",
            domain: "local.",
            txtRecord: [:]
        ),
        // IPP Printing
        ServiceInstance(
            name: "HP LaserJet Pro",
            type: "_ipp._tcp",
            domain: "local.",
            txtRecord: [:]
        ),
        ServiceInstance(
            name: "Brother Color Laser",
            type: "_ipp._tcp",
            domain: "local.",
            txtRecord: [:]
        ),
        // RAOP (AirPlay Audio)
        ServiceInstance(
            name: "Living Room",
            type: "_raop._tcp",
            domain: "local.",
            txtRecord: [:]
        ),
        ServiceInstance(
            name: "Bedroom HomePod",
            type: "_raop._tcp",
            domain: "local.",
            txtRecord: [:]
        ),
        // Sleep Proxy
        ServiceInstance(
            name: "70-35-60-63.1 Apple TV",
            type: "_sleep-proxy._udp",
            domain: "local.",
            txtRecord: [:]
        ),
        // SMB File Sharing
        ServiceInstance(
            name: "Synology NAS",
            type: "_smb._tcp",
            domain: "local.",
            txtRecord: [:]
        ),
        ServiceInstance(
            name: "MacBook Pro",
            type: "_smb._tcp",
            domain: "local.",
            txtRecord: [:]
        ),
        // SSH
        ServiceInstance(
            name: "Synology NAS",
            type: "_sftp-ssh._tcp",
            domain: "local.",
            txtRecord: [:]
        ),
        // HAP (HomeKit)
        ServiceInstance(
            name: "Living Room Light",
            type: "_hap._tcp",
            domain: "local.",
            txtRecord: [:]
        ),
        ServiceInstance(
            name: "Front Door Lock",
            type: "_hap._tcp",
            domain: "local.",
            txtRecord: [:]
        ),
        // Chromecast
        ServiceInstance(
            name: "Family Room TV",
            type: "_googlecast._tcp",
            domain: "local.",
            txtRecord: [:]
        )
    ]

    static let serviceTypeCounts: [String: Int] = {
        var counts: [String: Int] = [:]
        for instance in allServicesInstances {
            counts[instance.type, default: 0] += 1
        }
        return counts
    }()

    // MARK: - Service Detail (resolved)

    static let resolvedService = ResolvedService(
        name: "HP LaserJet Pro",
        type: "_ipp._tcp",
        domain: "local.",
        hostname: "HP-LaserJet-Pro.local.",
        port: 631,
        ipv4Addresses: ["10.0.1.42"],
        ipv6Addresses: ["fe80::1a2b:3c4d:5e6f:7890"],
        txtRecord: [
            "rp": "ipp/print",
            "note": "Home Office",
            "ty": "HP LaserJet Pro MFP",
            "adminurl": "http://HP-LaserJet-Pro.local.",
            "pdl": "application/pdf,image/jpeg",
            "URF": "W8,SRGB24,CP1,RS300",
            "Color": "T",
            "Duplex": "T"
        ],
        resolvedAt: Date()
    )

    // MARK: - Thread Network

    static let borderRouters: [ThreadBorderRouter] = [
        ThreadBorderRouter(
            name: "Living Room HomePod mini",
            networkName: "HomeThread",
            extendedPANID: "a1b2c3d4e5f6a7b8",
            panID: "c4d5",
            vendor: "Apple Inc.",
            modelName: "AudioAccessory6,1",
            threadVersion: "1.3.0",
            stateBitmap: nil,
            activeTimestamp: nil,
            pendingTimestamp: nil,
            sequenceNumber: nil,
            backboneRouterFlag: nil,
            domainName: nil,
            deviceDiscriminator: nil,
            hostname: "Living-Room-HomePod-mini.local.",
            addresses: ["10.0.1.20", "fe80::1a2b:3c4d:5e6f:1001"]
        ),
        ThreadBorderRouter(
            name: "Bedroom HomePod mini",
            networkName: "HomeThread",
            extendedPANID: "a1b2c3d4e5f6a7b8",
            panID: "c4d5",
            vendor: "Apple Inc.",
            modelName: "AudioAccessory6,1",
            threadVersion: "1.3.0",
            stateBitmap: nil,
            activeTimestamp: nil,
            pendingTimestamp: nil,
            sequenceNumber: nil,
            backboneRouterFlag: nil,
            domainName: nil,
            deviceDiscriminator: nil,
            hostname: "Bedroom-HomePod-mini.local.",
            addresses: ["10.0.1.21", "fe80::1a2b:3c4d:5e6f:1002"]
        ),
        ThreadBorderRouter(
            name: "Office Apple TV 4K",
            networkName: "HomeThread",
            extendedPANID: "a1b2c3d4e5f6a7b8",
            panID: "c4d5",
            vendor: "Apple Inc.",
            modelName: "AppleTV14,1",
            threadVersion: "1.3.0",
            stateBitmap: nil,
            activeTimestamp: nil,
            pendingTimestamp: nil,
            sequenceNumber: nil,
            backboneRouterFlag: nil,
            domainName: nil,
            deviceDiscriminator: nil,
            hostname: "Office-Apple-TV-4K.local.",
            addresses: ["10.0.1.22", "fe80::1a2b:3c4d:5e6f:1003"]
        )
    ]

    static let trelPeers: [TRELPeer] = [
        TRELPeer(
            name: "Living Room HomePod mini",
            hostname: "Living-Room-HomePod-mini.local.",
            addresses: ["10.0.1.20"]
        ),
        TRELPeer(
            name: "Office Apple TV 4K",
            hostname: "Office-Apple-TV-4K.local.",
            addresses: ["10.0.1.22"]
        )
    ]

    static let srpServers: [SRPServer] = [
        SRPServer(
            name: "Living Room HomePod mini",
            hostname: "Living-Room-HomePod-mini.local.",
            port: 53,
            addresses: ["10.0.1.20"]
        )
    ]

    static let commissioners: [MatterCommissioner] = [
        MatterCommissioner(
            name: "Living Room HomePod mini",
            deviceName: "Living Room",
            vendorProductID: "4937+9",
            deviceType: "22",
            commissioningMode: "0",
            hostname: "Living-Room-HomePod-mini.local.",
            addresses: ["10.0.1.20"]
        )
    ]

    // MARK: - Matter Devices

    static let matterDevices: [MatterDevice] = [
        MatterDevice(
            name: "Nanoleaf Strip A087",
            serviceType: "_matter._tcp",
            discriminator: "2976",
            vendorProductID: "4448+2",
            commissioningMode: "0",
            deviceType: "268",
            deviceName: "Light Strip",
            sessionIdleInterval: "500",
            sessionActiveInterval: "300",
            tcpSupported: "0",
            isICD: "0",
            pairingHint: "33",
            hostname: "Nanoleaf-Strip-A087.local.",
            addresses: ["10.0.1.50", "fe80::1a2b:3c4d:5e6f:2001"]
        ),
        MatterDevice(
            name: "Eve Room B204",
            serviceType: "_matter._tcp",
            discriminator: "1540",
            vendorProductID: "4874+82",
            commissioningMode: "0",
            deviceType: "770",
            deviceName: "Room Sensor",
            sessionIdleInterval: "5000",
            sessionActiveInterval: "300",
            tcpSupported: "0",
            isICD: "1",
            pairingHint: "33",
            hostname: "Eve-Room-B204.local.",
            addresses: ["10.0.1.51", "fe80::1a2b:3c4d:5e6f:2002"]
        ),
        MatterDevice(
            name: "Eve Energy C310",
            serviceType: "_matter._tcp",
            discriminator: "3840",
            vendorProductID: "4874+50",
            commissioningMode: "0",
            deviceType: "266",
            deviceName: "Smart Plug",
            sessionIdleInterval: "500",
            sessionActiveInterval: "300",
            tcpSupported: "0",
            isICD: "0",
            pairingHint: "33",
            hostname: "Eve-Energy-C310.local.",
            addresses: ["10.0.1.52", "fe80::1a2b:3c4d:5e6f:2003"]
        )
    ]
}
// swiftlint:enable function_body_length type_body_length
