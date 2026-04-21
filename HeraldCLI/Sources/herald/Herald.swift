import ArgumentParser
import Foundation

@main
struct Herald: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "herald",
        abstract: "Browse and resolve Bonjour/mDNS services from the command line.",
        discussion: """
            herald is a macOS companion to the Herald iOS app. It exposes the
            same Bonjour discovery the iOS 'All Services' tab uses:

              types    List the Bonjour service types Herald knows about.
              browse   Browse a service type and list live instances.
              resolve  Resolve a single instance to hostname, port, IPs, and TXT.

            All output is JSON on stdout. Errors go to stderr.
            """,
        subcommands: [TypesCommand.self, BrowseCommand.self, ResolveCommand.self]
    )
}

struct JSONFormatOptions: ParsableArguments {
    @Flag(name: .long, help: "Emit compact (single-line) JSON for piping into jq.")
    var compact = false
}
