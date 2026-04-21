import ArgumentParser
import Foundation

struct TypesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "types",
        abstract: "List all Bonjour service types herald knows about."
    )

    @OptionGroup var format: JSONFormatOptions

    func run() async throws {
        let entries = BonjourTypes.allTypes.map { type in
            TypeEntryDTO(
                type: type,
                description: ServiceTypeDescriptions.description(for: type)
            )
        }
        try JSONOutput.emit(entries, compact: format.compact)
    }
}
