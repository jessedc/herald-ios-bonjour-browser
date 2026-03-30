import XCTest
@testable import Herald

final class BLEPeripheralTests: XCTestCase {

    // MARK: - Helpers

    private func makePeripheral(
        localName: String? = "Test Device",
        matterServiceData: Data? = nil,
        rssi: Int = -50,
        isConnectable: Bool = true,
        lastSeen: Date = Date()
    ) -> BLEPeripheral {
        BLEPeripheral(
            identifier: UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!,
            localName: localName,
            advertisedServiceUUIDs: [],
            manufacturerData: nil,
            matterServiceData: matterServiceData,
            rssi: rssi,
            isConnectable: isConnectable,
            firstSeen: Date(),
            lastSeen: lastSeen
        )
    }

    /// Builds Matter service data bytes per Spec §5.4.2.5.1:
    /// Byte 0: opcode, Bytes 1-2: discriminator+version, Bytes 3-4: vendor ID, Bytes 5-6: product ID
    private func makeMatterServiceData(
        opcode: UInt8 = 0x00,
        discriminator: UInt16 = 2976,
        version: UInt8 = 0,
        vendorID: UInt16 = 4512,
        productID: UInt16 = 1
    ) -> Data {
        // Discriminator occupies bits 0-11, version bits 12-15
        let discAndVersion = discriminator | (UInt16(version) << 12)
        return Data([
            opcode,
            UInt8(discAndVersion & 0xFF), UInt8(discAndVersion >> 8),
            UInt8(vendorID & 0xFF), UInt8(vendorID >> 8),
            UInt8(productID & 0xFF), UInt8(productID >> 8)
        ])
    }

    // MARK: - Matter Discriminator Parsing

    func testMatterDiscriminatorParsing() {
        let data = makeMatterServiceData(discriminator: 2976)
        let peripheral = makePeripheral(matterServiceData: data)
        XCTAssertEqual(peripheral.matterDiscriminator, "2976")
    }

    func testMatterDiscriminatorMasks12Bits() {
        // Set version bits too (bits 12-15) to verify masking
        let data = makeMatterServiceData(discriminator: 0x0FFF, version: 0x0F)
        let peripheral = makePeripheral(matterServiceData: data)
        XCTAssertEqual(peripheral.matterDiscriminator, "4095") // 0x0FFF = 4095
    }

    func testMatterDiscriminatorNilWhenDataTooShort() {
        let data = Data([0x00, 0x01]) // only 2 bytes, need 3
        let peripheral = makePeripheral(matterServiceData: data)
        XCTAssertNil(peripheral.matterDiscriminator)
    }

    func testMatterDiscriminatorNilWhenNoData() {
        let peripheral = makePeripheral(matterServiceData: nil)
        XCTAssertNil(peripheral.matterDiscriminator)
    }

    // MARK: - Matter Vendor ID Parsing

    func testMatterVendorIDParsing() {
        let data = makeMatterServiceData(vendorID: 4512)
        let peripheral = makePeripheral(matterServiceData: data)
        XCTAssertEqual(peripheral.matterVendorID, "4512")
    }

    func testMatterVendorIDLittleEndian() {
        // 0x11A0 = 4512 stored as [0xA0, 0x11]
        let data = makeMatterServiceData(vendorID: 0x11A0)
        let peripheral = makePeripheral(matterServiceData: data)
        XCTAssertEqual(peripheral.matterVendorID, "4512")
    }

    func testMatterVendorIDNilWhenDataTooShort() {
        let data = Data([0x00, 0x01, 0x02, 0x03]) // only 4 bytes, need 5
        let peripheral = makePeripheral(matterServiceData: data)
        XCTAssertNil(peripheral.matterVendorID)
    }

    // MARK: - Matter Product ID Parsing

    func testMatterProductIDParsing() {
        let data = makeMatterServiceData(productID: 42)
        let peripheral = makePeripheral(matterServiceData: data)
        XCTAssertEqual(peripheral.matterProductID, "42")
    }

    func testMatterProductIDNilWhenDataTooShort() {
        let data = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05]) // only 6 bytes, need 7
        let peripheral = makePeripheral(matterServiceData: data)
        XCTAssertNil(peripheral.matterProductID)
    }

    // MARK: - Signal Strength Description

    func testSignalDescriptionStrong() {
        let peripheral = makePeripheral(rssi: -45)
        XCTAssertEqual(peripheral.signalDescription, "Strong")
    }

    func testSignalDescriptionGood() {
        let peripheral = makePeripheral(rssi: -60)
        XCTAssertEqual(peripheral.signalDescription, "Good")
    }

    func testSignalDescriptionFair() {
        let peripheral = makePeripheral(rssi: -75)
        XCTAssertEqual(peripheral.signalDescription, "Fair")
    }

    func testSignalDescriptionWeak() {
        let peripheral = makePeripheral(rssi: -90)
        XCTAssertEqual(peripheral.signalDescription, "Weak")
    }

    func testSignalBoundaryMinus50IsStrong() {
        let peripheral = makePeripheral(rssi: -50)
        XCTAssertEqual(peripheral.signalDescription, "Strong")
    }

    func testSignalBoundaryMinus51IsGood() {
        let peripheral = makePeripheral(rssi: -51)
        XCTAssertEqual(peripheral.signalDescription, "Good")
    }

    // MARK: - Signal Icon

    func testSignalIconStrongIsWifi() {
        let peripheral = makePeripheral(rssi: -45)
        XCTAssertEqual(peripheral.signalIcon, "wifi")
    }

    func testSignalIconGoodIsWifi() {
        let peripheral = makePeripheral(rssi: -60)
        XCTAssertEqual(peripheral.signalIcon, "wifi")
    }

    func testSignalIconFairIsExclamation() {
        let peripheral = makePeripheral(rssi: -75)
        XCTAssertEqual(peripheral.signalIcon, "wifi.exclamationmark")
    }

    func testSignalIconWeakIsSlash() {
        let peripheral = makePeripheral(rssi: -90)
        XCTAssertEqual(peripheral.signalIcon, "wifi.slash")
    }

    // MARK: - Display Name

    func testDisplayNameWithLocalName() {
        let peripheral = makePeripheral(localName: "My Light")
        XCTAssertEqual(peripheral.displayName, "My Light")
    }

    func testDisplayNameFallbackToUUIDWhenNil() {
        let peripheral = makePeripheral(localName: nil)
        XCTAssertTrue(peripheral.displayName.hasSuffix("…"))
        XCTAssertEqual(peripheral.displayName, "12345678…")
    }

    func testDisplayNameFallbackToUUIDWhenEmpty() {
        let peripheral = makePeripheral(localName: "")
        XCTAssertTrue(peripheral.displayName.hasSuffix("…"))
    }

    // MARK: - Staleness

    func testIsStaleAfterFiveMinutes() {
        let sixMinutesAgo = Date().addingTimeInterval(-360)
        let peripheral = makePeripheral(lastSeen: sixMinutesAgo)
        XCTAssertTrue(peripheral.isStale)
    }

    func testIsNotStaleWhenRecent() {
        let peripheral = makePeripheral(lastSeen: Date())
        XCTAssertFalse(peripheral.isStale)
    }

    func testIsNotStaleAtJustUnderFiveMinutes() {
        // 299 seconds < 300 threshold, should NOT be stale
        let justUnderFiveMinutes = Date().addingTimeInterval(-299)
        let peripheral = makePeripheral(lastSeen: justUnderFiveMinutes)
        XCTAssertFalse(peripheral.isStale)
    }
}
