import TipKit

// MARK: - Thread Network Tip

/// Explains what the Thread tab shows — appears on first visit.
struct ThreadNetworkTip: Tip {
    var title: Text {
        Text("Thread Network")
    }

    var message: Text? {
        // swiftlint:disable:next line_length
        Text("Thread is a low-power mesh network for smart home devices. Border routers listed here bridge the Thread mesh to your Wi-Fi or Ethernet network.")
    }

    var image: Image? {
        Image(systemName: "point.3.connected.trianglepath.dotted")
    }
}

// MARK: - Matter Device Tip

/// Explains what the Matter tab shows — appears on first visit.
struct MatterDeviceTip: Tip {
    var title: Text {
        Text("Matter Devices")
    }

    var message: Text? {
        // swiftlint:disable:next line_length
        Text("Matter is a smart home standard that lets devices from different ecosystems — Apple Home, Google Home, Alexa — work together. Commissionable devices are ready to pair; operational devices are already on a fabric.")
    }

    var image: Image? {
        Image(systemName: "house")
    }
}

// MARK: - Matter Fabrics Tip

/// Explains Matter fabric grouping — appears when 2+ fabrics are visible.
struct MatterFabricsTip: Tip {
    @Parameter
    static var fabricCount: Int = 0

    var title: Text {
        Text("Matter Fabrics")
    }

    var message: Text? {
        // swiftlint:disable:next line_length
        Text("Operational Matter devices are grouped by fabric. Each fabric represents a differen controller ecosystem.")
    }

    var image: Image? {
        Image(systemName: "network")
    }

    var rules: [Rule] {
        #Rule(Self.$fabricCount) { count in
            count >= 2
        }
    }
}

// MARK: - Siri Shortcut Tip

/// Promotes Siri voice integration — appears on first Info tab visit.
struct SiriShortcutTip: Tip {
    var title: Text {
        Text("Ask Siri")
    }

    var message: Text? {
        Text("Try asking Siri \"What's on my network with Herald\" for a quick summary of your Matter devices and Thread border routers.")
    }

    var image: Image? {
        Image(systemName: "waveform.and.mic")
    }
}

// MARK: - Reverse DNS Tip

/// Explains reverse DNS lookups — appears on first detail view visit.
struct ReverseDNSTip: Tip {
    var title: Text {
        Text("Reverse DNS Lookup")
    }

    var message: Text? {
        Text("After a service resolves, tap \"Run Reverse DNS Lookup\" to discover the hostname associated with each IP address.")
    }

    var image: Image? {
        Image(systemName: "arrow.left.arrow.right")
    }
}
