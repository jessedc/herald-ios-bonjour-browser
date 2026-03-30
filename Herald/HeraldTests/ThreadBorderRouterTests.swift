import XCTest
@testable import Herald

final class ThreadBorderRouterTests: XCTestCase {

    // MARK: - State Bitmap Flags

    func testStateBitmapNotConnectable() {
        let flags = ThreadBorderRouter.stateBitmapFlags(from: "00")
        XCTAssertEqual(flags, ["Not Connectable"])
    }

    func testStateBitmapPSKc() {
        let flags = ThreadBorderRouter.stateBitmapFlags(from: "01")
        XCTAssertEqual(flags, ["PSKc"])
    }

    func testStateBitmapPSKdVendor() {
        let flags = ThreadBorderRouter.stateBitmapFlags(from: "02")
        XCTAssertEqual(flags, ["PSKd + Vendor"])
    }

    func testStateBitmapThreadActive() {
        // 0x09 = 0x01 (PSKc) + 0x08 (Thread Active)
        let flags = ThreadBorderRouter.stateBitmapFlags(from: "09")
        XCTAssertEqual(flags, ["PSKc", "Thread Active"])
    }

    func testStateBitmapAvailable() {
        // 0x11 = 0x01 (PSKc) + 0x10 (Available)
        let flags = ThreadBorderRouter.stateBitmapFlags(from: "11")
        XCTAssertEqual(flags, ["PSKc", "Available"])
    }

    func testStateBitmapAllFlags() {
        // 0x19 = 0x01 (PSKc) + 0x08 (Thread Active) + 0x10 (Available)
        let flags = ThreadBorderRouter.stateBitmapFlags(from: "19")
        XCTAssertEqual(flags, ["PSKc", "Thread Active", "Available"])
    }

    func testStateBitmapNilReturnsEmpty() {
        let flags = ThreadBorderRouter.stateBitmapFlags(from: nil)
        XCTAssertEqual(flags, [])
    }

    func testStateBitmapInvalidHexReturnsEmpty() {
        let flags = ThreadBorderRouter.stateBitmapFlags(from: "ZZ")
        XCTAssertEqual(flags, [])
    }
}
