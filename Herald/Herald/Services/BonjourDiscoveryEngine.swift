import Foundation
import os

private let logger = Logger(subsystem: "com.herald", category: "BonjourDiscoveryEngine")

/// Orchestrates full Bonjour discovery: plist types → instances.
/// Drives the "All Services" view by browsing all NSBonjourServices types.
@MainActor
final class BonjourDiscoveryEngine: ObservableObject, UITestingConfigurable {
    @Published private(set) var allInstances: [ServiceInstance] = []
    @Published private(set) var serviceTypeCounts: [String: Int] = [:]
    @Published private(set) var isScanning = false
    @Published private(set) var errors: [DiscoveryError] = []

    private var instanceBrowsers: [String: ServiceInstanceBrowser] = [:]

    func clearErrors() {
        errors.removeAll()
    }

    func startFullScan() {
        logger.info("startFullScan: beginning plist-driven Bonjour discovery")
        stopAll()
        isScanning = true
        clearErrors()

        if applyUITestingOverrides() { return }

        // Browse all known types from NSBonjourServices in local.
        if let bonjourTypes = Bundle.main.infoDictionary?["NSBonjourServices"] as? [String] {
            for type in bonjourTypes where type != "_services._dns-sd._udp" {
                browseInstances(type: type, domain: "local.")
            }
        }
    }

    func stopAll() {
        logger.info("stopAll: tearing down \(self.instanceBrowsers.count) instance browsers")
        for browser in instanceBrowsers.values { browser.stop() }
        instanceBrowsers.removeAll()
        allInstances = []
        serviceTypeCounts = [:]
        clearErrors()
        isScanning = false
    }

    /// Restart discovery after returning from background.
    /// Reconnects the dns_sd shared connection to handle stale/dead connections
    /// that can occur when iOS suspends the app or the network changes.
    func restartAfterBackground() {
        logger.info("restartAfterBackground: reconnecting dns_sd and restarting scan")
        stopAll()
        DNSSDService.shared.reconnect()
        // Small delay to let the new connection establish before starting browse operations
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            startFullScan()
        }
    }

    private func browseInstances(type: String, domain: String) {
        let key = "\(type).\(domain)"
        guard instanceBrowsers[key] == nil else {
            logger.debug("browseInstances: browser already exists for '\(key)'")
            return
        }

        logger.info("browseInstances: creating instance browser for type='\(type)' domain='\(domain)'")
        let browser = ServiceInstanceBrowser()
        instanceBrowsers[key] = browser
        browser.start(type: type, domain: domain)

        // Observe changes from this browser
        Task {
            // Poll for changes (simple approach without Combine)
            var lastCount = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                let instances = browser.instances
                if instances.count != lastCount {
                    logger.info("browseInstances: instance count changed \(lastCount) → \(instances.count) for '\(key)'")
                    lastCount = instances.count
                    rebuildAllInstances()
                }
            }
        }
    }

    private func rebuildAllInstances() {
        var all: [ServiceInstance] = []
        var counts: [String: Int] = [:]
        for (_, browser) in instanceBrowsers {
            all.append(contentsOf: browser.instances)
            for instance in browser.instances {
                counts[instance.type, default: 0] += 1
            }
        }
        allInstances = all.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        serviceTypeCounts = counts
        logger.info("rebuildAllInstances: \(all.count) total instances across \(counts.count) types from \(self.instanceBrowsers.count) browsers")
    }

    // MARK: - UITestingConfigurable

    private func applyMockInstances() {
        allInstances = [
            ServiceInstance(
                name: "Test Service",
                type: "_http._tcp",
                domain: "local.",
                txtRecord: ["path": "/index.html"]
            ),
            ServiceInstance(
                name: "Office Printer",
                type: "_ipp._tcp",
                domain: "local.",
                txtRecord: ["rp": "ipp/print", "note": "2nd floor"]
            ),
            ServiceInstance(
                name: "Living Room Speaker",
                type: "_airplay._tcp",
                domain: "local.",
                txtRecord: ["model": "HomePod"]
            ),
            ServiceInstance(
                name: "Kitchen Display",
                type: "_airplay._tcp",
                domain: "local.",
                txtRecord: ["model": "AppleTV"]
            )
        ]
        serviceTypeCounts = ["_http._tcp": 1, "_ipp._tcp": 1, "_airplay._tcp": 2]
        isScanning = false
    }

    func applyScreenshotMockData() {
        logger.info("startFullScan: screenshot mode — injecting realistic mock data")
        allInstances = ScreenshotMockData.allServicesInstances.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        serviceTypeCounts = ScreenshotMockData.serviceTypeCounts
        isScanning = false
    }

    func applyUITestingMockData() {
        logger.info("startFullScan: UI testing mode — injecting mock data")
        applyMockInstances()
    }

    func applyUITestingErrors() {
        logger.info("startFullScan: UI testing error mode — injecting mock data with error")
        applyMockInstances()
        errors.append(DiscoveryError(message: "Service type discovery failed for local.", source: "Bonjour Discovery"))
    }
}
