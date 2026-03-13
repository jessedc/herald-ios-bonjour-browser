import Foundation

enum MatterDeviceTypes {

    private static let deviceTypes: [String: String] = [
        // Lighting
        "256": "On/Off Light",
        "257": "Dimmable Light",
        "258": "Color Temperature Light",
        "259": "Extended Color Light",
        "268": "Color Dimmable Light",

        // Switches
        "260": "On/Off Light Switch",
        "261": "Dimmer Switch",
        "262": "Color Dimmer Switch",

        // Plugs & Outlets
        "266": "On/Off Plug-in Unit",
        "267": "Dimmable Plug-in Unit",

        // Sensors
        "21": "Contact Sensor",
        "263": "Occupancy Sensor",
        "770": "Temperature Sensor",
        "775": "Humidity Sensor",
        "2076": "Light Sensor",
        "44": "Flow Sensor",
        "45": "Pressure Sensor",

        // HVAC
        "769": "Thermostat",
        "768": "Heating/Cooling Unit",
        "43": "Fan",

        // Closures
        "10": "Door Lock",
        "514": "Window Covering",

        // Media
        "35": "Casting Video Player",
        "36": "Content App",
        "34": "Speaker",

        // Infrastructure
        "22": "Root Node",
        "14": "Aggregator",
        "17": "Bridge",
        "273": "Pump",

        // Safety
        "118": "Smoke/CO Alarm",
    ]

    static func description(for deviceType: String?) -> String? {
        guard let deviceType else { return nil }
        return deviceTypes[deviceType]
    }
}
