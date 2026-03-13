import Foundation

enum MatterVendorIDs {

    private static let vendors: [String: String] = [
        "4937": "Apple",
        "4996": "Google",
        "5009": "Amazon",
        "5010": "IKEA",
        "4742": "Signify (Philips Hue)",
        "4448": "Nanoleaf",
        "4874": "Eve Systems",
        "4098": "Samsung",
        "5127": "Aqara",
        "4417": "Tuya",
        "5264": "TP-Link",
        "4655": "Belkin",
        "65521": "Test Vendor (CSA)",
    ]

    static func vendorName(for vendorProductID: String?) -> String? {
        guard let vendorProductID else { return nil }
        let vendorID = vendorProductID.split(separator: "+").first.map(String.init) ?? vendorProductID
        return vendors[vendorID]
    }
}
