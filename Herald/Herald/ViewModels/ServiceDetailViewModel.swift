import Combine
import Foundation

/// Drives the service detail view with resolution and export.
@MainActor
final class ServiceDetailViewModel: ObservableObject, TextExportable {
    @Published private var resolver = ServiceResolver()

    var resolverError: String? { resolver.error }
    var isResolving: Bool { resolver.isResolving }
    var resolved: ResolvedService? { resolver.resolved }

    let instance: ServiceInstance
    private var cancellables = Set<AnyCancellable>()

    init(instance: ServiceInstance) {
        self.instance = instance
        resolver.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func resolve() {
        resolver.resolve(instance: instance)
    }

    /// Best available TXT record — resolved data takes priority over browse data.
    var txtRecord: [String: String] {
        resolved?.txtRecord ?? instance.txtRecord
    }

    /// Instance enriched with resolved TXT data for the enrichment section.
    var enrichedInstance: ServiceInstance {
        ServiceInstance(name: instance.name, type: instance.type, domain: instance.domain, txtRecord: txtRecord)
    }

    var exportTitle: String { instance.name }

    var exportText: String {
        guard let resolved = resolver.resolved else {
            return ServiceExporter.plainText(for: [instance])
        }
        return ServiceExporter.plainText(for: resolved)
    }

    var exportJSON: String? {
        guard let resolved = resolver.resolved else {
            return ServiceExporter.json(for: [instance])
        }
        return ServiceExporter.json(for: resolved)
    }
}
