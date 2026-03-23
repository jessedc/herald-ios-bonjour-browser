import Foundation
import os

private let logger = Logger(subsystem: "com.herald", category: "ThreadNetworkService")

/// Discovers Thread network devices via Bonjour browse:
/// border routers (_meshcop._udp), TREL peers (_trel._udp),
/// SRP servers (_srpl-tls._tcp), and Matter commissionable devices (_matterc._udp).
@MainActor
final class ThreadNetworkService: ObservableObject, UITestingConfigurable {
    @Published private(set) var borderRouters: [ThreadBorderRouter] = []
    @Published private(set) var trelPeers: [TRELPeer] = []
    @Published private(set) var srpServers: [SRPServer] = []
    @Published private(set) var commissioners: [MatterCommissioner] = []
    @Published private(set) var isSearching = false
    @Published private(set) var errors: [DiscoveryError] = []

    private var meshcopBrowser: ServiceInstanceBrowser?
    private var trelBrowser: ServiceInstanceBrowser?
    private var srpBrowser: ServiceInstanceBrowser?
    private var mattercBrowser: ServiceInstanceBrowser?
    private var pollingTask: Task<Void, Never>?
    private let dnssd = DNSSDService.shared

    func clearErrors() {
        errors.removeAll()
    }

    func startDiscovery() {
        guard !isSearching else { return }

        switch UITestingMode.current {
        case .errors:
            applyThreadErrors()
            return
        case .screenshots:
            applyScreenshotThreadData()
            return
        case .mockData:
            applyMockThreadData()
            return
        case .disabled:
            break
        }

        logger.info("startDiscovery: browsing Thread service types in local.")
        let meshcop = ServiceInstanceBrowser()
        let trel = ServiceInstanceBrowser()
        let srp = ServiceInstanceBrowser()
        let matterc = ServiceInstanceBrowser()
        meshcopBrowser = meshcop
        trelBrowser = trel
        srpBrowser = srp
        mattercBrowser = matterc
        isSearching = true

        meshcop.start(type: "_meshcop._udp", domain: "local.")
        trel.start(type: "_trel._udp", domain: "local.")
        srp.start(type: "_srpl-tls._tcp", domain: "local.")
        matterc.start(type: "_matterc._udp", domain: "local.")

        pollingTask = Task {
            var lastMeshcopCount = 0
            var lastTrelCount = 0
            var lastSrpCount = 0
            var lastMattercCount = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                let meshcopInstances = meshcop.instances
                let trelInstances = trel.instances
                let srpInstances = srp.instances
                let mattercInstances = matterc.instances

                if meshcopInstances.count != lastMeshcopCount {
                    lastMeshcopCount = meshcopInstances.count
                    await resolveAndUpdateBorderRouters(from: meshcopInstances)
                }
                if trelInstances.count != lastTrelCount {
                    lastTrelCount = trelInstances.count
                    await resolveAndUpdateTRELPeers(from: trelInstances)
                }
                if srpInstances.count != lastSrpCount {
                    lastSrpCount = srpInstances.count
                    await resolveAndUpdateSRPServers(from: srpInstances)
                }
                if mattercInstances.count != lastMattercCount {
                    lastMattercCount = mattercInstances.count
                    await resolveAndUpdateCommissioners(from: mattercInstances)
                }
            }
        }
    }

    func allReset() {
        borderRouters = []
        trelPeers = []
        srpServers = []
        commissioners = []
    }

    func stopDiscovery() {
        logger.info("stopDiscovery: stopping Thread browsers")
        pollingTask?.cancel()
        pollingTask = nil
        meshcopBrowser?.stop()
        meshcopBrowser = nil
        trelBrowser?.stop()
        trelBrowser = nil
        srpBrowser?.stop()
        srpBrowser = nil
        mattercBrowser?.stop()
        mattercBrowser = nil
        isSearching = false
    }

    // MARK: - Resolve Methods

    private func resolveAndUpdateBorderRouters(from instances: [ServiceInstance]) async {
        let dnssd = self.dnssd
        let routers: [ThreadBorderRouter] = await withTaskGroup(of: ThreadBorderRouter.self) { group in
            for instance in instances {
                let name = instance.name
                let type = instance.type
                let domain = instance.domain
                group.addTask {
                    do {
                        let resolved = try await dnssd.resolve(name: name, type: type, domain: domain)
                        let txt = resolved.txtRecord
                        return ThreadBorderRouter(
                            name: name,
                            networkName: txt["nn"] ?? "Unknown",
                            extendedPANID: txt["xp"] ?? "",
                            panID: txt["pi"],
                            vendor: txt["vn"],
                            modelName: txt["mn"],
                            threadVersion: txt["tv"],
                            stateBitmap: txt["sb"],
                            activeTimestamp: txt["at"],
                            pendingTimestamp: txt["pt"],
                            sequenceNumber: txt["sq"],
                            backboneRouterFlag: txt["bb"],
                            domainName: txt["dn"],
                            deviceDiscriminator: txt["dd"],
                            hostname: resolved.hostname,
                            addresses: []
                        )
                    } catch {
                        logger.warning("resolveAndUpdateBorderRouters: failed to resolve '\(name)': \(error.localizedDescription)")
                        return ThreadBorderRouter(
                            name: name,
                            networkName: "Unknown",
                            extendedPANID: "",
                            panID: nil,
                            vendor: nil,
                            modelName: nil,
                            threadVersion: nil,
                            stateBitmap: nil,
                            activeTimestamp: nil,
                            pendingTimestamp: nil,
                            sequenceNumber: nil,
                            backboneRouterFlag: nil,
                            domainName: nil,
                            deviceDiscriminator: nil,
                            hostname: nil,
                            addresses: []
                        )
                    }
                }
            }
            var results: [ThreadBorderRouter] = []
            for await router in group {
                results.append(router)
            }
            return results
        }
        borderRouters = routers.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func resolveAndUpdateTRELPeers(from instances: [ServiceInstance]) async {
        let dnssd = self.dnssd
        let peers: [TRELPeer] = await withTaskGroup(of: TRELPeer.self) { group in
            for instance in instances {
                let name = instance.name
                let type = instance.type
                let domain = instance.domain
                group.addTask {
                    do {
                        let resolved = try await dnssd.resolve(name: name, type: type, domain: domain)
                        return TRELPeer(name: name, hostname: resolved.hostname, addresses: [])
                    } catch {
                        logger.warning("resolveAndUpdateTRELPeers: failed to resolve '\(name)': \(error.localizedDescription)")
                        return TRELPeer(name: name, hostname: nil, addresses: [])
                    }
                }
            }
            var results: [TRELPeer] = []
            for await peer in group {
                results.append(peer)
            }
            return results
        }
        trelPeers = peers.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func resolveAndUpdateSRPServers(from instances: [ServiceInstance]) async {
        let dnssd = self.dnssd
        let servers: [SRPServer] = await withTaskGroup(of: SRPServer.self) { group in
            for instance in instances {
                let name = instance.name
                let type = instance.type
                let domain = instance.domain
                group.addTask {
                    do {
                        let resolved = try await dnssd.resolve(name: name, type: type, domain: domain)
                        return SRPServer(name: name, hostname: resolved.hostname, port: resolved.port, addresses: [])
                    } catch {
                        logger.warning("resolveAndUpdateSRPServers: failed to resolve '\(name)': \(error.localizedDescription)")
                        return SRPServer(name: name, hostname: nil, port: 0, addresses: [])
                    }
                }
            }
            var results: [SRPServer] = []
            for await server in group {
                results.append(server)
            }
            return results
        }
        srpServers = servers.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func resolveAndUpdateCommissioners(from instances: [ServiceInstance]) async {
        let dnssd = self.dnssd
        let comms: [MatterCommissioner] = await withTaskGroup(of: MatterCommissioner.self) { group in
            for instance in instances {
                let name = instance.name
                let type = instance.type
                let domain = instance.domain
                group.addTask {
                    do {
                        let resolved = try await dnssd.resolve(name: name, type: type, domain: domain)
                        let txt = resolved.txtRecord
                        return MatterCommissioner(
                            name: name,
                            deviceName: txt["DN"],
                            vendorProductID: txt["VP"],
                            deviceType: txt["DT"],
                            commissioningMode: txt["CM"],
                            hostname: resolved.hostname,
                            addresses: []
                        )
                    } catch {
                        logger.warning("resolveAndUpdateCommissioners: failed to resolve '\(name)': \(error.localizedDescription)")
                        return MatterCommissioner(
                            name: name,
                            deviceName: nil,
                            vendorProductID: nil,
                            deviceType: nil,
                            commissioningMode: nil,
                            hostname: nil,
                            addresses: []
                        )
                    }
                }
            }
            var results: [MatterCommissioner] = []
            for await comm in group {
                results.append(comm)
            }
            return results
        }
        commissioners = comms.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - UITestingConfigurable

    func applyScreenshotMockData() {
        applyScreenshotThreadData()
    }

    func applyUITestingMockData() {
        applyMockThreadData()
    }

    func applyUITestingErrors() {
        applyThreadErrors()
    }

    private func applyScreenshotThreadData() {
        logger.info("startDiscovery: screenshot mode - injecting realistic Thread data")
        borderRouters = ScreenshotMockData.borderRouters
        trelPeers = ScreenshotMockData.trelPeers
        srpServers = ScreenshotMockData.srpServers
        commissioners = ScreenshotMockData.commissioners
        isSearching = false
    }

    private func applyMockThreadData() {
        logger.info("startDiscovery: UI testing mode - injecting mock Thread data")
        borderRouters = [
            ThreadBorderRouter(
                name: "Test Border Router",
                networkName: "TestNetwork",
                extendedPANID: "dead00beef00cafe",
                panID: "face",
                vendor: "Apple",
                modelName: "HomePod mini",
                threadVersion: "1.3.0",
                stateBitmap: nil,
                activeTimestamp: nil,
                pendingTimestamp: nil,
                sequenceNumber: nil,
                backboneRouterFlag: nil,
                domainName: nil,
                deviceDiscriminator: nil,
                hostname: "test-router.local.",
                addresses: ["192.168.1.1"]
            )
        ]
        trelPeers = [
            TRELPeer(name: "Test TREL Peer", hostname: "trel-peer.local.", addresses: ["192.168.1.2"])
        ]
        srpServers = [
            SRPServer(name: "Test SRP Server", hostname: "srp-server.local.", port: 53, addresses: ["192.168.1.3"])
        ]
        commissioners = [
            MatterCommissioner(
                name: "Test Commissioner",
                deviceName: "Kitchen Hub",
                vendorProductID: "65521+32769",
                deviceType: "256",
                commissioningMode: "1",
                hostname: "commissioner.local.",
                addresses: ["192.168.1.4"]
            )
        ]
        isSearching = false
    }

    private func applyThreadErrors() {
        logger.info("startDiscovery: UI testing error mode - no Thread devices")
        isSearching = false
    }
}
