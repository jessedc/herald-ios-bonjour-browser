import Combine
import Foundation
import os

private let logger = Logger(subsystem: "com.herald", category: "ThreadNetworkViewModel")

/// Drives the Thread tab.
@MainActor
final class ThreadNetworkViewModel: ObservableObject, TextExportable {
    @Published var service = ThreadNetworkService()
    private var serviceCancellable: AnyCancellable?

    init() {
        serviceCancellable = service.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var errors: [DiscoveryError] { service.errors }

    func clearErrors() {
        service.clearErrors()
    }

    func start() {
        guard !service.isSearching else { return }
        logger.info("start: starting Thread network discovery")
        clearErrors()
        service.startDiscovery()
    }

    func stop() {
        logger.info("stop: stopping Thread view model")
        service.stopDiscovery()
    }

    var exportTitle: String { "Thread Network" }

    var exportText: String {
        ServiceExporter.plainText(
            borderRouters: service.borderRouters,
            trelPeers: service.trelPeers,
            srpServers: service.srpServers,
            commissioners: service.commissioners
        )
    }

    var exportJSON: String? {
        ServiceExporter.json(
            borderRouters: service.borderRouters,
            trelPeers: service.trelPeers,
            srpServers: service.srpServers,
            commissioners: service.commissioners
        )
    }

    func refresh() {
        logger.info("refresh: restarting Thread network discovery")
        clearErrors()
        service.stopDiscovery()
        service.allReset()
        service.startDiscovery()
    }
}
