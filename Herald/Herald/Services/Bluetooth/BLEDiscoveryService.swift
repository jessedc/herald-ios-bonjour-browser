import CoreBluetooth
import Foundation
import os

/// Matter commissioning BLE service UUID (Matter Core Spec §5.4.2).
private let matterCommissioningUUID = CBUUID(string: "FFF6")

private let logger = Logger(subsystem: "com.herald", category: "BLEDiscoveryService")

@MainActor
final class BLEDiscoveryService: ObservableObject, UITestingConfigurable {
    @Published private(set) var peripherals: [BLEPeripheral] = []
    @Published private(set) var isScanning = false
    @Published private(set) var errors: [DiscoveryError] = []
    @Published private(set) var bluetoothState: CBManagerState = .unknown

    private var scanner: BLEScannerDelegate?
    private var peripheralMap: [UUID: BLEPeripheral] = [:]

    func clearErrors() {
        errors.removeAll()
    }

    func peripheralsReset() {
        peripherals = []
        peripheralMap = [:]
    }

    func startDiscovery() {
        guard !isScanning else { return }

        switch UITestingMode.current {
        case .errors:
            applyBLEErrors()
            return
        case .screenshots:
            applyScreenshotBLEDevices()
            return
        case .mockData:
            applyMockBLEDevices()
            return
        case .disabled:
            break
        }

        logger.info("startDiscovery: beginning BLE scan")
        isScanning = true

        if scanner == nil {
            let delegate = BLEScannerDelegate(
                onPeripheralDiscovered: { [weak self] peripheral in
                    Task { @MainActor [weak self] in
                        self?.handleDiscoveredPeripheral(peripheral)
                    }
                },
                onStateChanged: { [weak self] state in
                    Task { @MainActor [weak self] in
                        self?.handleStateChange(state)
                    }
                }
            )
            scanner = delegate
            delegate.start()
        } else {
            scanner?.resumeScan()
        }
    }

    func stopDiscovery() {
        logger.info("stopDiscovery: stopping BLE scan")
        scanner?.pauseScan()
        isScanning = false
    }

    /// Fully tears down the CBCentralManager connection. Call when going to background.
    func tearDown() {
        stopDiscovery()
        scanner?.tearDown()
        scanner = nil
    }

    // MARK: - Private

    private func handleDiscoveredPeripheral(_ peripheral: BLEPeripheral) {
        if let existing = peripheralMap[peripheral.identifier] {
            peripheralMap[peripheral.identifier] = BLEPeripheral(
                identifier: existing.identifier,
                localName: peripheral.localName ?? existing.localName,
                advertisedServiceUUIDs: peripheral.advertisedServiceUUIDs.isEmpty
                    ? existing.advertisedServiceUUIDs : peripheral.advertisedServiceUUIDs,
                manufacturerData: peripheral.manufacturerData ?? existing.manufacturerData,
                matterServiceData: peripheral.matterServiceData ?? existing.matterServiceData,
                rssi: peripheral.rssi,
                isConnectable: peripheral.isConnectable,
                firstSeen: existing.firstSeen,
                lastSeen: peripheral.lastSeen
            )
        } else {
            peripheralMap[peripheral.identifier] = peripheral
            logger.info("handleDiscoveredPeripheral: new device '\(peripheral.displayName)' rssi=\(peripheral.rssi)")
        }

        publishPeripherals()
    }

    private func handleStateChange(_ state: CBManagerState) {
        bluetoothState = state
        let auth = CBManager.authorization
        logger.info("handleStateChange: state=\(state.rawValue) authorization=\(auth.rawValue)")
        switch state {
        case .poweredOn:
            logger.info("handleStateChange: Bluetooth powered on, authorization=\(auth.rawValue)")
        case .poweredOff:
            logger.warning("handleStateChange: Bluetooth powered off")
            errors.append(DiscoveryError(
                message: "Bluetooth is powered off. Enable Bluetooth in Settings to scan for nearby devices.",
                source: "Bluetooth Scanner"
            ))
            isScanning = false
        case .unauthorized:
            logger.warning("handleStateChange: Bluetooth unauthorized")
            errors.append(DiscoveryError(
                message: "Bluetooth access is not authorized. Grant permission in Settings > Privacy > Bluetooth.",
                source: "Bluetooth Scanner"
            ))
            isScanning = false
        case .unsupported:
            logger.warning("handleStateChange: Bluetooth unsupported (simulator?)")
            errors.append(DiscoveryError(
                message: "Bluetooth is not available on this device.",
                source: "Bluetooth Scanner"
            ))
            isScanning = false
        default:
            break
        }
    }

    private func publishPeripherals() {
        peripherals = peripheralMap.values
            .sorted { ($0.localName ?? "").localizedCaseInsensitiveCompare($1.localName ?? "") == .orderedAscending }
        logger.debug("publishPeripherals: \(self.peripherals.count) devices")
    }

    // MARK: - UITestingConfigurable

    func applyScreenshotMockData() {
        applyScreenshotBLEDevices()
    }

    func applyUITestingMockData() {
        applyMockBLEDevices()
    }

    func applyUITestingErrors() {
        applyBLEErrors()
    }

    private func applyScreenshotBLEDevices() {
        logger.info("startDiscovery: screenshot mode - injecting realistic BLE devices")
        peripherals = ScreenshotMockData.blePeripherals
        isScanning = false
        bluetoothState = .poweredOn
    }

    private func applyMockBLEDevices() {
        logger.info("startDiscovery: UI testing mode - injecting mock Matter commissioning devices")
        peripherals = [
            BLEPeripheral(
                identifier: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!,
                localName: "Test Matter Light",
                advertisedServiceUUIDs: ["FFF6"],
                manufacturerData: nil,
                matterServiceData: Data([0x00, 0xA0, 0x0B, 0xA0, 0x11, 0x01, 0x00]),
                rssi: -55,
                isConnectable: true,
                firstSeen: Date(),
                lastSeen: Date()
            ),
            BLEPeripheral(
                identifier: UUID(uuidString: "B2C3D4E5-F6A7-8901-BCDE-F12345678901")!,
                localName: "Test Matter Sensor",
                advertisedServiceUUIDs: ["FFF6"],
                manufacturerData: nil,
                matterServiceData: Data([0x00, 0x04, 0x06, 0x0A, 0x13, 0x02, 0x00]),
                rssi: -72,
                isConnectable: true,
                firstSeen: Date(),
                lastSeen: Date()
            )
        ]
        isScanning = false
        bluetoothState = .poweredOn
    }

    private func applyBLEErrors() {
        logger.info("startDiscovery: UI testing error mode")
        peripherals = []
        isScanning = false
        bluetoothState = .unsupported
        errors.append(DiscoveryError(
            message: "Bluetooth is not available on this device.",
            source: "Bluetooth Scanner"
        ))
    }
}

// MARK: - CBCentralManager Delegate Bridge

/// Bridges CoreBluetooth delegate callbacks (off-main-thread) to @Sendable closures.
private final class BLEScannerDelegate: NSObject, CBCentralManagerDelegate {
    private var centralManager: CBCentralManager?
    private let onPeripheralDiscovered: @Sendable (BLEPeripheral) -> Void
    private let onStateChanged: @Sendable (CBManagerState) -> Void

    init(
        onPeripheralDiscovered: @escaping @Sendable (BLEPeripheral) -> Void,
        onStateChanged: @escaping @Sendable (CBManagerState) -> Void
    ) {
        self.onPeripheralDiscovered = onPeripheralDiscovered
        self.onStateChanged = onStateChanged
        super.init()
    }

    func start() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func pauseScan() {
        if centralManager?.state == .poweredOn {
            centralManager?.stopScan()
        }
    }

    func resumeScan() {
        if centralManager?.state == .poweredOn {
            centralManager?.scanForPeripherals(
                withServices: [matterCommissioningUUID],
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
            )
        }
    }

    func tearDown() {
        pauseScan()
        centralManager?.delegate = nil
        centralManager = nil
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        onStateChanged(central.state)
        if central.state == .poweredOn {
            logger.info("BLEScannerDelegate: starting Matter commissioning scan (UUID FFF6)")
            central.scanForPeripherals(
                withServices: [matterCommissioningUUID],
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
            )
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let serviceUUIDs = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?
            .map { $0.uuidString } ?? []
        let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name
        let isConnectable = (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue ?? false

        // Extract Matter commissioning service data (Spec §5.4.2.5.1)
        let serviceDataMap = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data]
        let matterServiceData = serviceDataMap?[matterCommissioningUUID]

        logger.debug("didDiscover: '\(localName ?? "unnamed")' rssi=\(RSSI) services=\(serviceUUIDs)")

        let blePeripheral = BLEPeripheral(
            identifier: peripheral.identifier,
            localName: localName,
            advertisedServiceUUIDs: serviceUUIDs,
            manufacturerData: manufacturerData,
            matterServiceData: matterServiceData,
            rssi: RSSI.intValue,
            isConnectable: isConnectable,
            firstSeen: Date(),
            lastSeen: Date()
        )

        onPeripheralDiscovered(blePeripheral)
    }
}
