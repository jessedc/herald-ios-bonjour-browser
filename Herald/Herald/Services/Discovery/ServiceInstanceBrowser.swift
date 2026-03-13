import Foundation
import os

private let logger = Logger(subsystem: "com.herald", category: "ServiceInstanceBrowser")

/// Browses for service instances of a given type using the dns_sd C API.
/// Replaces NWBrowser to avoid NSBonjourServices entitlement restrictions
/// that prevent browsing dynamically-discovered service types.
@MainActor
final class ServiceInstanceBrowser: ObservableObject, UITestingConfigurable {
    @Published private(set) var instances: [ServiceInstance] = []
    @Published private(set) var isSearching = false
    @Published private(set) var errors: [DiscoveryError] = []

    private let dnssd = DNSSDService.shared
    private var browseTask: Task<Void, Never>?
    private var currentType = ""
    private var currentDomain = "local."

    func clearErrors() {
        errors.removeAll()
    }

    func start(type: String, domain: String?) {
        logger.info("start: browsing for type='\(type)' domain='\(domain ?? "nil")'")
        stop()
        isSearching = true
        clearErrors()
        currentType = type
        currentDomain = domain ?? "local."

        if applyUITestingOverrides() { return }

        // Track instances by a composite key to handle add/remove events
        var instanceMap: [String: ServiceInstance] = [:]

        browseTask = Task {
            do {
                for try await event in dnssd.browseInstances(type: type, domain: domain ?? "local.") {
                    guard !Task.isCancelled else {
                        logger.info("start: task cancelled, breaking out of browse stream (type='\(type)')")
                        break
                    }

                    let key = "\(event.name).\(event.type).\(event.domain)"
                    if event.isAdd {
                        let instance = ServiceInstance(
                            name: event.name,
                            type: event.type,
                            domain: event.domain,
                            txtRecord: [:]
                        )
                        instanceMap[key] = instance
                        logger.info("start: added instance '\(event.name)' (total: \(instanceMap.count)) type='\(type)'")
                    } else {
                        instanceMap.removeValue(forKey: key)
                        logger.info("start: removed instance '\(event.name)' (total: \(instanceMap.count)) type='\(type)'")
                    }

                    instances = instanceMap.values
                        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                }
            } catch {
                if !Task.isCancelled {
                    logger.error("start: browse instances error: \(error)")
                    errors.append(DiscoveryError(message: error.localizedDescription, source: "Instance Browser"))
                }
            }
            if !Task.isCancelled && instances.isEmpty {
                errors.append(DiscoveryError(message: "No instances found for \(type) in \(domain ?? "local.")", source: "Instance Browser"))
            }
            logger.info("start: browse stream ended for type='\(type)'")
            isSearching = false
        }
    }

    func stop() {
        if browseTask != nil {
            logger.info("stop: cancelling browse task")
        }
        browseTask?.cancel()
        browseTask = nil
        isSearching = false
        instances = []
    }

    // MARK: - UITestingConfigurable

    func applyUITestingMockData() {
        logger.info("start: UI testing mode — injecting mock instance")
        instances = [
            ServiceInstance(
                name: "Test Service",
                type: currentType,
                domain: currentDomain,
                txtRecord: ["path": "/index.html"]
            )
        ]
        isSearching = false
    }

    func applyUITestingErrors() {
        applyUITestingMockData()
        errors.append(DiscoveryError(message: "Browse failed for \(currentType) in \(currentDomain)", source: "Instance Browser"))
    }
}
