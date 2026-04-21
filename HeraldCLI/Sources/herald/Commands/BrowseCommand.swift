import ArgumentParser
import Foundation

struct BrowseCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "browse",
        abstract: "Browse a single Bonjour service type and emit the resulting instance set as JSON."
    )

    @Argument(help: "The service type to browse, e.g. _http._tcp")
    var type: String

    @Option(name: .long, help: "Bonjour domain to browse in.")
    var domain: String = "local."

    @Option(name: .long, help: "How many seconds to collect add/remove events before emitting.")
    var duration: Double = 4.0

    @OptionGroup var format: JSONFormatOptions

    func run() async throws {
        let stream = DNSSDService.shared.browseInstances(type: type, domain: domain)

        var current: [String: BrowseInstanceEvent] = [:]

        let collector = Task {
            do {
                for try await event in stream {
                    let id = "\(event.name).\(event.type).\(event.domain)"
                    if event.isAdd {
                        current[id] = event
                    } else {
                        current.removeValue(forKey: id)
                    }
                }
            } catch is CancellationError {
                // expected when we time-box the stream
            } catch {
                JSONOutput.fail(error.localizedDescription, code: "browse-failed")
            }
        }

        try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        collector.cancel()
        _ = await collector.value

        let instances = current.values
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            .map(InstanceDTO.init)

        let result = BrowseResultDTO(
            type: type,
            domain: domain,
            durationSeconds: duration,
            instances: instances
        )

        try JSONOutput.emit(result, compact: format.compact)
    }
}
