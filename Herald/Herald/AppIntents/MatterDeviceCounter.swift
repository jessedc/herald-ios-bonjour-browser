import Foundation

/// Lightweight, non-UI discovery helper that counts Matter devices on the local network.
/// Uses DNSSDService directly — no @MainActor or ObservableObject overhead.
struct MatterDeviceCounter {

    static let matterServiceTypes = ["_matter._tcp", "_matter._udp", "_matterd._udp"]

    /// Performs a time-boxed Bonjour browse for Matter devices and returns the count.
    /// Deduplicates by instance name across all three Matter service types.
    static func countDevices(timeout: Duration = .seconds(4)) async throws -> Int {
        try await withThrowingTaskGroup(of: Set<String>.self) { group in
            for type in matterServiceTypes {
                group.addTask {
                    var names = Set<String>()
                    let stream = DNSSDService.shared.browseInstances(type: type, domain: "local.")
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
            }

            // Let discovery run for the timeout duration, then cancel all browse tasks
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
                // Expected from the timeout task
                group.cancelAll()
                // Collect remaining results from cancelled browse tasks
                while let names = try? await group.next() {
                    allNames.formUnion(names)
                }
            }
            return allNames.count
        }
    }
}
