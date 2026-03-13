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
    private var pollingTask: Task<Void, Never>?
    private let dnssd = DNSSDService.shared

    func clearErrors() {
        errors.removeAll()
    }

    func startDiscovery() {
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

        logger.info("startDiscovery: browsing _matter._tcp and _matter._udp in local.")
        let tcp = ServiceInstanceBrowser()
        let udp = ServiceInstanceBrowser()
        tcpBrowser = tcp
        udpBrowser = udp
        isSearching = true
        tcp.start(type: "_matter._tcp", domain: "local.")
        udp.start(type: "_matter._udp", domain: "local.")

        pollingTask = Task {
            var lastTcpCount = 0
            var lastUdpCount = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                let tcpInstances = tcp.instances
                let udpInstances = udp.instances
                if tcpInstances.count != lastTcpCount || udpInstances.count != lastUdpCount {
                    logger.info("startDiscovery: matter device count changed tcp=\(tcpInstances.count) udp=\(udpInstances.count)")
                    lastTcpCount = tcpInstances.count
                    lastUdpCount = udpInstances.count
                    await resolveAndUpdateDevices(tcpInstances: tcpInstances, udpInstances: udpInstances)
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
        isSearching = false
    }

    private func resolveAndUpdateDevices(tcpInstances: [ServiceInstance], udpInstances: [ServiceInstance]) async {
        let allInstances = tcpInstances + udpInstances
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
                            addresses: []
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
        logger.info("startDiscovery: UI testing mode - injecting mock matter device")
        devices = [
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
                addresses: ["192.168.1.50"]
            )
        ]
        isSearching = false
    }

    private func applyMatterErrors() {
        logger.info("startDiscovery: UI testing error mode - no matter devices")
        isSearching = false
    }
}
