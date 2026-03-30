import Foundation

/// A BLE peripheral advertising the Matter commissioning service (UUID 0xFFF6).
///
/// The scanner filters to only this service UUID, so every discovered peripheral
/// is a Matter device in commissioning mode (Matter Core Spec §5.4.2).
struct BLEPeripheral: Identifiable, Hashable {
    static func == (lhs: BLEPeripheral, rhs: BLEPeripheral) -> Bool {
        lhs.identifier == rhs.identifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    let identifier: UUID
    let localName: String?
    let advertisedServiceUUIDs: [String]
    let manufacturerData: Data?
    /// Service data from the Matter commissioning UUID (0xFFF6).
    /// Parsed per Matter Core Spec §5.4.2.5.1.
    let matterServiceData: Data?
    let rssi: Int
    let isConnectable: Bool
    let firstSeen: Date
    var lastSeen: Date

    var id: UUID { identifier }

    // MARK: - Display

    var displayName: String {
        if let name = localName, !name.isEmpty {
            return name
        }
        return identifier.uuidString.prefix(8).uppercased() + "…"
    }

    // MARK: - Staleness

    /// A device is considered stale if it hasn't been seen for over 5 minutes.
    var isStale: Bool {
        Date().timeIntervalSince(lastSeen) > 300
    }

    // MARK: - Signal Strength

    var signalDescription: String {
        switch rssi {
        case -50...0: return "Strong"
        case -70 ..< -50: return "Good"
        case -85 ..< -70: return "Fair"
        default: return "Weak"
        }
    }

    var signalIcon: String {
        switch rssi {
        case -50...0: return "wifi"
        case -70 ..< -50: return "wifi"
        case -85 ..< -70: return "wifi.exclamationmark"
        default: return "wifi.slash"
        }
    }

    // MARK: - Matter Commissioning Data (Spec §5.4.2.5.1)

    /// Parses the 12-bit long discriminator from Matter service data.
    /// Octets 1-2: bits [0:11] = discriminator, bits [12:15] = version.
    var matterDiscriminator: String? {
        guard let data = matterServiceData, data.count >= 3 else { return nil }
        let raw = UInt16(data[1]) | (UInt16(data[2]) << 8)
        let longDiscriminator = raw & 0x0FFF
        return String(longDiscriminator)
    }

    /// Parses the vendor ID from Matter service data (octets 3-4, little-endian).
    var matterVendorID: String? {
        guard let data = matterServiceData, data.count >= 5 else { return nil }
        let vendorID = UInt16(data[3]) | (UInt16(data[4]) << 8)
        return String(vendorID)
    }

    /// Parses the product ID from Matter service data (octets 5-6, little-endian).
    var matterProductID: String? {
        guard let data = matterServiceData, data.count >= 7 else { return nil }
        let productID = UInt16(data[5]) | (UInt16(data[6]) << 8)
        return String(productID)
    }

    /// Human-readable vendor name from the Matter vendor ID lookup table.
    var matterVendorName: String? {
        MatterVendorIDs.vendorName(for: matterVendorID)
    }
}
