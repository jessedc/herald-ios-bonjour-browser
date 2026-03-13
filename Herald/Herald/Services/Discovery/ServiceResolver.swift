import Foundation
import os

private extension Array where Element: Hashable {
    /// Returns the array with duplicates removed, preserving order.
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

private let logger = Logger(subsystem: "com.herald", category: "ServiceResolver")

/// Resolves a service instance to its hostname, port, and IP addresses.
@MainActor
final class ServiceResolver: ObservableObject, UITestingConfigurable {
    @Published private(set) var resolved: ResolvedService?
    @Published private(set) var isResolving = false
    @Published private(set) var error: String?

    var errors: [DiscoveryError] {
        if let error {
            return [DiscoveryError(message: error, source: "Service Resolver")]
        }
        return []
    }

    func clearErrors() {
        error = nil
    }

    private let dnssd = DNSSDService.shared
    private var resolveTask: Task<Void, Never>?
    private var currentInstance: ServiceInstance?

    func resolve(instance: ServiceInstance) {
        logger.info("resolve: starting for '\(instance.name)' type='\(instance.type)' domain='\(instance.domain)'")
        resolveTask?.cancel()
        isResolving = true
        error = nil
        resolved = nil
        currentInstance = instance

        if applyUITestingOverrides() { return }

        resolveTask = Task {
            do {
                logger.info("resolve: step 1 — calling dnssd.resolve()")
                let (hostname, port, txtRecord) = try await dnssd.resolve(
                    name: instance.name,
                    type: instance.type,
                    domain: instance.domain
                )

                guard !Task.isCancelled else {
                    logger.info("resolve: cancelled after resolve step")
                    return
                }

                logger.info("resolve: step 2 — calling dnssd.getAddresses(hostname: '\(hostname)')")
                let addresses = try await dnssd.getAddresses(hostname: hostname)

                guard !Task.isCancelled else {
                    logger.info("resolve: cancelled after getAddresses step")
                    return
                }

                // Merge TXT: prefer data from resolve callback, fall back to browse data
                let mergedTXT = txtRecord.isEmpty ? instance.txtRecord : txtRecord
                logger.info("resolve: complete — hostname='\(hostname)' port=\(port) ipv4=\(addresses.ipv4) ipv6=\(addresses.ipv6) txtKeys=[\(mergedTXT.keys.joined(separator: ", "))]")
                resolved = ResolvedService(
                    name: instance.name,
                    type: instance.type,
                    domain: instance.domain,
                    hostname: hostname,
                    port: port,
                    ipv4Addresses: addresses.ipv4.uniqued(),
                    ipv6Addresses: addresses.ipv6.uniqued(),
                    txtRecord: mergedTXT,
                    resolvedAt: Date()
                )
            } catch {
                if !Task.isCancelled {
                    logger.error("resolve: failed with error: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                }
            }

            isResolving = false
        }
    }

    func cancel() {
        logger.info("cancel: cancelling resolve task")
        resolveTask?.cancel()
        resolveTask = nil
        isResolving = false
    }

    // MARK: - UITestingConfigurable

    func applyScreenshotMockData() {
        guard let instance = currentInstance else { return }
        logger.info("resolve: screenshot mode — injecting realistic resolved data")
        // Use the curated resolved service if it matches, otherwise generate from instance
        if instance.name == ScreenshotMockData.resolvedService.name
            && instance.type == ScreenshotMockData.resolvedService.type {
            resolved = ScreenshotMockData.resolvedService
        } else {
            let hostname = instance.name.replacingOccurrences(of: " ", with: "-") + ".local."
            resolved = ResolvedService(
                name: instance.name,
                type: instance.type,
                domain: instance.domain,
                hostname: hostname,
                port: 80,
                ipv4Addresses: ["10.0.1.100"],
                ipv6Addresses: ["fe80::1a2b:3c4d:5e6f:9999"],
                txtRecord: instance.txtRecord,
                resolvedAt: Date()
            )
        }
        isResolving = false
    }

    func applyUITestingMockData() {
        guard let instance = currentInstance else { return }
        logger.info("resolve: UI testing mode — injecting mock resolved data")
        resolved = ResolvedService(
            name: instance.name,
            type: instance.type,
            domain: instance.domain,
            hostname: "test-host.local.",
            port: 80,
            ipv4Addresses: ["192.168.1.100"],
            ipv6Addresses: [],
            txtRecord: instance.txtRecord,
            resolvedAt: Date()
        )
        isResolving = false
    }

    func applyUITestingErrors() {
        applyUITestingMockData()
    }
}
