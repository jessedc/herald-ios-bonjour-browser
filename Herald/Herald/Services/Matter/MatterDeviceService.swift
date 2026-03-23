import Foundation
import os

private let logger = Logger(subsystem: "com.herald", category: "MatterDeviceService")

@MainActor
final class MatterDeviceService: ObservableObject, UITestingConfigurable {
    @Published private(set) var devices: [MatterDevice] = []
    @Published private(set) var isSearching = false
    @Published private(set) var errors: [DiscoveryError] = []

    private var tcpBrowser: ServiceInstanceBrowser?
    private var udpBrowser: ServiceInstanceBrowser?
    private var operationalBrowser: ServiceInstanceBrowser?
    private var pollingTask: Task<Void, Never>?
    private let dnssd = DNSSDService.shared

    func clearErrors() {
        errors.removeAll()
    }

    func startDiscovery() {
        guard !isSearching else { return }

        switch UITestingMode.current {
        case .errors:
            applyMatterErrors()
            return
        case .screenshots:
            applyScreenshotMatterDevices()
            return
        case .mockData:
            applyMockMatterDevices()
            return
        case .disabled:
            break
        }

        logger.info("startDiscovery: browsing _matter._tcp, _matter._udp, and _matterd._udp in local.")
        let tcp = ServiceInstanceBrowser()
        let udp = ServiceInstanceBrowser()
        let operational = ServiceInstanceBrowser()
        tcpBrowser = tcp
        udpBrowser = udp
        operationalBrowser = operational
        isSearching = true
        tcp.start(type: "_matter._tcp", domain: "local.")
        udp.start(type: "_matter._udp", domain: "local.")
        operational.start(type: "_matterd._udp", domain: "local.")

        pollingTask = Task {
            var lastTcpCount = 0
            var lastUdpCount = 0
            var lastOperationalCount = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                let tcpInstances = tcp.instances
                let udpInstances = udp.instances
                let operationalInstances = operational.instances
                if tcpInstances.count != lastTcpCount
                    || udpInstances.count != lastUdpCount
                    || operationalInstances.count != lastOperationalCount {
                    let tcpCount = tcpInstances.count
                    let udpCount = udpInstances.count
                    let opCount = operationalInstances.count
                    logger.info("startDiscovery: matter count changed tcp=\(tcpCount) udp=\(udpCount) op=\(opCount)")
                    lastTcpCount = tcpInstances.count
                    lastUdpCount = udpInstances.count
                    lastOperationalCount = operationalInstances.count
                    await resolveAndUpdateDevices(
                        tcpInstances: tcpInstances,
                        udpInstances: udpInstances,
                        operationalInstances: operationalInstances
                    )
                }
            }
        }
    }

    func devicesReset() {
        devices = []
    }

    func stopDiscovery() {
        logger.info("stopDiscovery: stopping matter browsers")
        pollingTask?.cancel()
        pollingTask = nil
        tcpBrowser?.stop()
        tcpBrowser = nil
        udpBrowser?.stop()
        udpBrowser = nil
        operationalBrowser?.stop()
        operationalBrowser = nil
        isSearching = false
    }

    private func resolveAndUpdateDevices(
        tcpInstances: [ServiceInstance],
        udpInstances: [ServiceInstance],
        operationalInstances: [ServiceInstance]
    ) async {
        let allInstances = tcpInstances + udpInstances + operationalInstances
        let dnssd = self.dnssd
        let resolved: [MatterDevice] = await withTaskGroup(of: MatterDevice.self) { group in
            for instance in allInstances {
                let name = instance.name
                let type = instance.type
                let domain = instance.domain
                group.addTask {
                    do {
                        let result = try await dnssd.resolve(name: name, type: type, domain: domain)
                        let txt = result.txtRecord

                        // Resolve IP addresses from hostname
                        var addressList: [String] = []
                        if !result.hostname.isEmpty {
                            do {
                                let addrs = try await dnssd.getAddresses(hostname: result.hostname)
                                addressList = addrs.ipv4 + addrs.ipv6
                            } catch {
                                logger.warning(
                                    "resolveAndUpdateDevices: address lookup failed for '\(result.hostname)': \(error.localizedDescription)"
                                )
                            }
                        }

                        return MatterDevice(
                            name: name,
                            serviceType: type,
                            discriminator: txt["D"],
                            vendorProductID: txt["VP"],
                            commissioningMode: txt["CM"],
                            deviceType: txt["DT"],
                            deviceName: txt["DN"],
                            sessionIdleInterval: txt["SII"],
                            sessionActiveInterval: txt["SAI"],
                            tcpSupported: txt["T"],
                            isICD: txt["ICD"],
                            pairingHint: txt["PH"],
                            hostname: result.hostname,
                            addresses: addressList
                        )
                    } catch {
                        logger.warning("resolveAndUpdateDevices: failed to resolve '\(name)': \(error.localizedDescription)")
                        return MatterDevice(
                            name: name,
                            serviceType: type,
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
                    }
                }
            }
            var results: [MatterDevice] = []
            for await device in group {
                results.append(device)
            }
            return results
        }
        devices = resolved.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        logger.info("resolveAndUpdateDevices: \(self.devices.count) matter devices total")
    }

    // MARK: - UITestingConfigurable

    func applyScreenshotMockData() {
        applyScreenshotMatterDevices()
    }

    func applyUITestingMockData() {
        applyMockMatterDevices()
    }

    func applyUITestingErrors() {
        applyMatterErrors()
    }

    private func applyScreenshotMatterDevices() {
        logger.info("startDiscovery: screenshot mode - injecting realistic matter devices")
        devices = ScreenshotMockData.matterDevices
        isSearching = false
    }

    private func applyMockMatterDevices() {
        logger.info("startDiscovery: UI testing mode - injecting mock matter devices")
        devices = [
            // Operational device (hex instance name with fabric-node format)
            MatterDevice(
                name: "38271586BF3DEB06-00000000082931E5",
                serviceType: "_matterd._udp",
                discriminator: nil,
                vendorProductID: nil,
                commissioningMode: nil,
                deviceType: nil,
                deviceName: nil,
                sessionIdleInterval: "500",
                sessionActiveInterval: "300",
                tcpSupported: nil,
                isICD: "0",
                pairingHint: nil,
                hostname: "test-matter-node.local.",
                addresses: ["192.168.1.50"]
            ),
            // Commissionable device
            MatterDevice(
                name: "Test Matter Device",
                serviceType: "_matter._tcp",
                discriminator: "3840",
                vendorProductID: "65521+32769",
                commissioningMode: "1",
                deviceType: "256",
                deviceName: "Test Light",
                sessionIdleInterval: "500",
                sessionActiveInterval: "300",
                tcpSupported: "0",
                isICD: "0",
                pairingHint: "33",
                hostname: "test-matter.local.",
                addresses: ["192.168.1.51"]
            )
        ]
        isSearching = false
    }

    private func applyMatterErrors() {
        logger.info("startDiscovery: UI testing error mode - no matter devices")
        isSearching = false
    }
}
