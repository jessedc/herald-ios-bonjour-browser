import ArgumentParser
import Foundation

struct ResolveCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "resolve",
        abstract: "Resolve a Bonjour instance to its hostname, port, IPs, and TXT record."
    )

    @Argument(help: "Instance name as seen in browse output.")
    var name: String

    @Argument(help: "Service type, e.g. _http._tcp")
    var type: String

    @Option(name: .long, help: "Bonjour domain the instance lives in.")
    var domain: String = "local."

    @OptionGroup var format: JSONFormatOptions

    func run() async throws {
        let service = DNSSDService.shared

        let hostname: String
        let port: UInt16
        let txt: [String: TXTValue]
        do {
            let resolved = try await service.resolve(name: name, type: type, domain: domain)
            hostname = resolved.hostname
            port = resolved.port
            txt = resolved.txtRecord
        } catch {
            JSONOutput.fail(error.localizedDescription, code: "resolve-failed")
        }

        let ipv4: [String]
        let ipv6: [String]
        do {
            let addresses = try await service.getAddresses(hostname: hostname)
            ipv4 = addresses.ipv4
            ipv6 = addresses.ipv6
        } catch {
            JSONOutput.fail(error.localizedDescription, code: "address-lookup-failed")
        }

        var txtDTOs: [String: TXTValueDTO] = [:]
        for (key, value) in txt {
            txtDTOs[key] = TXTValueDTO(key: key, value: value, serviceType: type)
        }

        let result = ResolveResultDTO(
            name: name,
            type: type,
            domain: domain,
            description: ServiceTypeDescriptions.description(for: type),
            hostname: hostname,
            port: port,
            ipv4Addresses: ipv4,
            ipv6Addresses: ipv6,
            txtRecord: txtDTOs,
            resolvedAt: Date()
        )

        try JSONOutput.emit(result, compact: format.compact)
    }
}
