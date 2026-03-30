import Combine
import Foundation
import os

private let logger = Logger(subsystem: "com.herald", category: "BLEDiscoveryViewModel")

@MainActor
final class BLEDiscoveryViewModel: ObservableObject, TextExportable {
    @Published var service = BLEDiscoveryService()
    private var serviceCancellable: AnyCancellable?

    init() {
        serviceCancellable = service.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var errors: [DiscoveryError] { service.errors }

    var peripherals: [BLEPeripheral] { service.peripherals }

    func clearErrors() {
        service.clearErrors()
    }

    func start() {
        guard !service.isScanning else { return }
        logger.info("start: starting BLE discovery")
        clearErrors()
        service.startDiscovery()
    }

    func stop() {
        logger.info("stop: tearing down BLE discovery")
        service.tearDown()
    }

    func refresh() {
        logger.info("refresh: restarting BLE discovery")
        clearErrors()
        service.stopDiscovery()
        service.peripheralsReset()
        service.startDiscovery()
    }

    // MARK: - TextExportable

    var exportTitle: String { "Bluetooth Devices" }

    var exportText: String {
        ServiceExporter.plainText(for: service.peripherals)
    }

    var exportJSON: String? {
        ServiceExporter.json(for: service.peripherals)
    }
}
