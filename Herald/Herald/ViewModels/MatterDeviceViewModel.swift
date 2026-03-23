import Combine
import Foundation
import os

private let logger = Logger(subsystem: "com.herald", category: "MatterDeviceViewModel")

struct MatterDeviceFabricGroup: Identifiable {
    let fabricID: String?
    let devices: [MatterDevice]

    var id: String { fabricID ?? "ungrouped" }
}

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

    /// Groups devices by fabric ID; commissionable/unparseable devices go in a nil-fabric group
    var devicesByFabric: [MatterDeviceFabricGroup] {
        var fabricMap: [String: [MatterDevice]] = [:]
        var ungrouped: [MatterDevice] = []

        for device in service.devices {
            if let fabricID = device.parsedInstanceName?.fabricID {
                fabricMap[fabricID, default: []].append(device)
            } else {
                ungrouped.append(device)
            }
        }

        var groups: [MatterDeviceFabricGroup] = fabricMap
            .sorted { $0.key < $1.key }
            .map { MatterDeviceFabricGroup(fabricID: $0.key, devices: $0.value) }

        if !ungrouped.isEmpty {
            groups.append(MatterDeviceFabricGroup(fabricID: nil, devices: ungrouped))
        }

        return groups
    }

    var fabricCount: Int {
        Set(service.devices.compactMap { $0.parsedInstanceName?.fabricID }).count
    }

    func clearErrors() {
        service.clearErrors()
    }

    func start() {
        guard !service.isSearching else { return }
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
