import Combine
import Foundation
import os

private let logger = Logger(subsystem: "com.herald", category: "MatterDeviceViewModel")

@MainActor
final class MatterDeviceViewModel: ObservableObject, TextExportable {
    @Published var service = MatterDeviceService()
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
        logger.info("start: starting Matter device discovery")
        clearErrors()
        service.startDiscovery()
    }

    func stop() {
        logger.info("stop: stopping Matter view model")
        service.stopDiscovery()
    }

    var exportTitle: String { "Matter Devices" }

    var exportText: String {
        ServiceExporter.plainText(for: service.devices)
    }

    var exportJSON: String? {
        ServiceExporter.json(for: service.devices)
    }

    func refresh() {
        logger.info("refresh: restarting Matter device discovery")
        clearErrors()
        service.stopDiscovery()
        service.devicesReset()
        service.startDiscovery()
    }
}
