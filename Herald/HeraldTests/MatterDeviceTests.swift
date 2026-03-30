import XCTest
@testable import Herald

final class MatterInstanceNameTests: XCTestCase {

    // MARK: - Parsing

    func testParseValidOperationalName() {
        let result = MatterInstanceName.parse("38271586BF3DEB06-00000000082931E5")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.fabricID, "38271586BF3DEB06")
        XCTAssertEqual(result?.nodeID, "00000000082931E5")
    }

    func testParseUppercaseHex() {
        let result = MatterInstanceName.parse("ABCDEF1234567890-FEDCBA0987654321")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.fabricID, "ABCDEF1234567890")
    }

    func testParseLowercaseHex() {
        let result = MatterInstanceName.parse("abcdef1234567890-fedcba0987654321")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.fabricID, "abcdef1234567890")
    }

    func testParseMixedCaseHex() {
        let result = MatterInstanceName.parse("AbCdEf-123456")
        XCTAssertNotNil(result)
    }

    func testParseReturnsNilForNoHyphen() {
        XCTAssertNil(MatterInstanceName.parse("ABCDEF1234"))
    }

    func testParseReturnsNilForEmptyFabric() {
        XCTAssertNil(MatterInstanceName.parse("-0000001"))
    }

    func testParseReturnsNilForEmptyNode() {
        XCTAssertNil(MatterInstanceName.parse("ABCDEF-"))
    }

    func testParseReturnsNilForNonHexChars() {
        XCTAssertNil(MatterInstanceName.parse("GHIJKL-000001"))
    }

    // MARK: - Truncation

    func testTruncatedFabricID() {
        let result = MatterInstanceName.parse("38271586BF3DEB06-00000000082931E5")!
        XCTAssertEqual(result.truncatedFabricID, "38271586…")
    }

    func testTruncatedNodeIDStripsLeadingZeros() {
        let result = MatterInstanceName.parse("38271586BF3DEB06-00000000082931E5")!
        XCTAssertEqual(result.truncatedNodeID, "82931E5")
    }

    func testTruncatedNodeIDAllZeros() {
        let result = MatterInstanceName.parse("ABCDEF12-0000000000000000")!
        XCTAssertEqual(result.truncatedNodeID, "0")
    }
}

// MARK: - MatterDevice Tests

final class MatterDeviceTests: XCTestCase {

    // MARK: - Helpers

    private func makeDevice(
        name: String = "Test",
        serviceType: String = "_matter._tcp",
        discriminator: String? = nil,
        vendorProductID: String? = nil,
        commissioningMode: String? = nil,
        deviceType: String? = nil,
        deviceName: String? = nil,
        sessionIdleInterval: String? = nil,
        sessionActiveInterval: String? = nil,
        tcpSupported: String? = nil,
        isICD: String? = nil,
        pairingHint: String? = nil,
        hostname: String? = nil,
        addresses: [String] = []
    ) -> MatterDevice {
        MatterDevice(
            name: name,
            serviceType: serviceType,
            discriminator: discriminator,
            vendorProductID: vendorProductID,
            commissioningMode: commissioningMode,
            deviceType: deviceType,
            deviceName: deviceName,
            sessionIdleInterval: sessionIdleInterval,
            sessionActiveInterval: sessionActiveInterval,
            tcpSupported: tcpSupported,
            isICD: isICD,
            pairingHint: pairingHint,
            hostname: hostname,
            addresses: addresses
        )
    }

    // MARK: - Interval Humanization

    func testHumanizeIntervalMilliseconds() {
        XCTAssertEqual(MatterDevice.humanizeInterval("300"), "300ms")
    }

    func testHumanizeIntervalSeconds() {
        XCTAssertEqual(MatterDevice.humanizeInterval("5000"), "5s")
    }

    func testHumanizeIntervalOneSecond() {
        XCTAssertEqual(MatterDevice.humanizeInterval("1000"), "1s")
    }

    func testHumanizeIntervalNil() {
        XCTAssertNil(MatterDevice.humanizeInterval(nil))
    }

    func testHumanizeIntervalNonNumeric() {
        XCTAssertNil(MatterDevice.humanizeInterval("abc"))
    }

    // MARK: - Session Descriptions

    func testSessionIdleDescription() {
        let device = makeDevice(sessionIdleInterval: "500")
        XCTAssertEqual(device.sessionIdleDescription, "Idle wake: 500ms")
    }

    func testSessionActiveDescription() {
        let device = makeDevice(sessionActiveInterval: "5000")
        XCTAssertEqual(device.sessionActiveDescription, "Active wake: 5s")
    }

    func testSessionIdleDescriptionNilWhenNoInterval() {
        let device = makeDevice()
        XCTAssertNil(device.sessionIdleDescription)
    }

    func testSessionActiveDescriptionNilWhenNoInterval() {
        let device = makeDevice()
        XCTAssertNil(device.sessionActiveDescription)
    }

    // MARK: - Pairing Hint Bitmask

    func testDecodePairingHintSingleBit() {
        let hints = MatterDevice.decodePairingHint("1")
        XCTAssertEqual(hints, ["Power cycle device"])
    }

    func testDecodePairingHintMultipleBits() {
        // 0x21 = 33 = bits 0 + 5
        let hints = MatterDevice.decodePairingHint("33")
        XCTAssertEqual(hints, ["Power cycle device", "Press setup button once"])
    }

    func testDecodePairingHintAllBits() {
        // 0x3F = 63 = all 6 bits
        let hints = MatterDevice.decodePairingHint("63")
        XCTAssertEqual(hints?.count, 6)
        XCTAssertEqual(hints?.first, "Power cycle device")
        XCTAssertEqual(hints?.last, "Press setup button once")
    }

    func testDecodePairingHintZero() {
        XCTAssertNil(MatterDevice.decodePairingHint("0"))
    }

    func testDecodePairingHintNil() {
        XCTAssertNil(MatterDevice.decodePairingHint(nil))
    }

    // MARK: - Battery / ICD

    func testIsBatteryDeviceTrue() {
        let device = makeDevice(isICD: "1")
        XCTAssertTrue(device.isBatteryDevice)
    }

    func testIsBatteryDeviceFalse() {
        let device = makeDevice(isICD: "0")
        XCTAssertFalse(device.isBatteryDevice)
    }

    func testIsBatteryDeviceNilICD() {
        let device = makeDevice()
        XCTAssertFalse(device.isBatteryDevice)
    }

    // MARK: - Operational Detection

    func testIsOperationalTrue() {
        let device = makeDevice(name: "38271586BF3DEB06-00000000082931E5")
        XCTAssertTrue(device.isOperational)
    }

    func testIsOperationalFalse() {
        let device = makeDevice(name: "My Smart Light")
        XCTAssertFalse(device.isOperational)
    }

    // MARK: - Device Type Description

    func testDeviceTypeDescription() {
        let device = makeDevice(deviceType: "256")
        XCTAssertEqual(device.deviceTypeDescription, "On/Off Light")
    }

    func testDeviceTypeDescriptionUnknown() {
        let device = makeDevice(deviceType: "99999")
        XCTAssertEqual(device.deviceTypeDescription, "99999")
    }

    func testDeviceTypeDescriptionNil() {
        let device = makeDevice()
        XCTAssertEqual(device.deviceTypeDescription, "Unknown")
    }

    // MARK: - Commissioning Mode

    func testCommissioningModeNotCommissioning() {
        XCTAssertEqual(MatterDevice.commissioningModeDescription("0"), "Not Commissioning")
    }

    func testCommissioningModeBasic() {
        XCTAssertEqual(MatterDevice.commissioningModeDescription("1"), "Basic")
    }

    func testCommissioningModeEnhanced() {
        XCTAssertEqual(MatterDevice.commissioningModeDescription("2"), "Enhanced")
    }

    func testCommissioningModeNil() {
        XCTAssertEqual(MatterDevice.commissioningModeDescription(nil), "Unknown")
    }

    // MARK: - Display Name

    func testDisplayNamePrefersDeviceName() {
        let device = makeDevice(deviceName: "Lamp", hostname: "test-host.local.")
        XCTAssertEqual(device.displayName, "Lamp")
    }

    func testDisplayNameFallsBackToHostname() {
        let device = makeDevice(hostname: "test-host.local.")
        XCTAssertEqual(device.displayName, "test host")
    }

    func testDisplayNameFallsBackToRawName() {
        let device = makeDevice(name: "38271586BF3DEB06-00000000082931E5")
        XCTAssertEqual(device.displayName, "38271586BF3DEB06-00000000082931E5")
    }
}
