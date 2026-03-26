import Foundation

/// Lightweight, non-UI discovery helper that counts Thread border routers on the local network.
/// Uses DNSSDService directly — no @MainActor or ObservableObject overhead.
/// Mirrors MatterDeviceCounter pattern for time-boxed browsing.
struct ThreadBorderRouterCounter {

    /// Result of a Thread border router scan, including network name context.
    struct Result {
        let count: Int
        let networkNames: Set<String>
    }

    /// Performs a time-boxed Bonjour browse for Thread border routers, returns the count,
    /// and resolves discovered instances to extract Thread network names from TXT records.
    static func countRouters(timeout: Duration = .seconds(4)) async throws -> Result {
        // Phase 1: Browse for instances (first 2 seconds)
        let discoveredNames = try await browseRouterNames(timeout: .seconds(2))

        guard !discoveredNames.isEmpty else {
            return Result(count: 0, networkNames: [])
        }

        // Phase 2: Resolve instances to get TXT records with network names (remaining 2 seconds)
        let networkNames = await resolveNetworkNames(
            instanceNames: discoveredNames,
            timeout: .seconds(2)
        )

        return Result(count: discoveredNames.count, networkNames: networkNames)
    }

    /// Browse for _meshcop._udp instances and return discovered names.
    private static func browseRouterNames(timeout: Duration) async throws -> Set<String> {
        try await withThrowingTaskGroup(of: Set<String>.self) { group in
            group.addTask {
                var names = Set<String>()
                let stream = DNSSDService.shared.browseInstances(type: "_meshcop._udp", domain: "local.")
                do {
                    for try await event in stream {
                        if event.isAdd {
                            names.insert(event.name)
                        } else {
                            names.remove(event.name)
                        }
                    }
                } catch is CancellationError {
                    // Expected — timeout cancelled us
                } catch {
                    // Stream error — return what we collected
                }
                return names
            }

            group.addTask {
                try await Task.sleep(for: timeout)
                throw CancellationError()
            }

            var allNames = Set<String>()
            do {
                for try await names in group {
                    allNames.formUnion(names)
                }
            } catch is CancellationError {
                group.cancelAll()
                while let names = try? await group.next() {
                    allNames.formUnion(names)
                }
            }
            return allNames
        }
    }

    /// Resolve discovered instances to extract Thread network names (nn) from TXT records.
    private static func resolveNetworkNames(instanceNames: Set<String>, timeout: Duration) async -> Set<String> {
        await withTaskGroup(of: String?.self) { group in
            for name in instanceNames {
                group.addTask {
                    do {
                        let resolved = try await DNSSDService.shared.resolve(
                            name: name,
                            type: "_meshcop._udp",
                            domain: "local."
                        )
                        return resolved.txtRecord["nn"]
                    } catch {
                        return nil
                    }
                }
            }

            // Timeout task
            group.addTask {
                try? await Task.sleep(for: timeout)
                return nil
            }

            var names = Set<String>()
            for await networkName in group {
                if let nn = networkName, !nn.isEmpty {
                    names.insert(nn)
                }
            }
            return names
        }
    }
}
