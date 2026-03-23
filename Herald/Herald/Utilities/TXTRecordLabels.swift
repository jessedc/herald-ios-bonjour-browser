import Foundation

enum TXTRecordLabels {

    // MARK: - MeshCoP (_meshcop._udp) — Thread Border Router
    // Source: OpenThread src/core/meshcop/border_agent_txt_data.cpp/.hpp
    // https://github.com/openthread/openthread/blob/main/src/core/meshcop/border_agent_txt_data.cpp

    private static let meshcop: [String: String] = [
        "id": "Border Agent ID",
        "nn": "Network Name",
        "xp": "Extended PAN ID",
        "xa": "Extended Address",
        "vn": "Vendor Name",
        "mn": "Model Name",
        "tv": "Thread Version",
        "sb": "State Bitmap",
        "at": "Active Timestamp",
        "pt": "Partition ID",
        "sq": "BBR Sequence Number",
        "bb": "BBR Port",
        "dn": "Domain Name",
        "omr": "OMR Prefix",
        "rv": "Record Version",
        "vp": "Vendor Product",                // Vendor-specific; observed on Apple border routers
    ]

    // MARK: - Matter (_matter._tcp, _matterc._udp, _matterd._udp)
    // Source: connectedhomeip src/lib/dnssd/TxtFields.h
    // https://github.com/project-chip/connectedhomeip/blob/master/src/lib/dnssd/TxtFields.h
    // Commission keys (D, VP, CM, DT, DN, PH, PI, RI, CP): _matterc._udp, _matter._tcp, _matter._udp only
    // Common keys (SII, SAI, SAT, T, ICD): all three service types

    private static let matter: [String: String] = [
        "D": "Long Discriminator",
        "VP": "Vendor/Product ID",
        "CM": "Commissioning Mode",
        "DT": "Device Type",
        "DN": "Device Name",
        "SII": "Session Idle Interval",
        "SAI": "Session Active Interval",
        "T": "TCP Supported",
        "ICD": "Long Idle Time ICD",
        "PH": "Pairing Hint",
        "PI": "Pairing Instruction",
        "RI": "Rotating ID",
        "SAT": "Session Active Threshold",
        "CP": "Commissioner Passcode",
    ]

    // MARK: - IPP/IPPS Printing (_ipp._tcp, _ipps._tcp)
    // Source: Apple Bonjour Printing Specification v1.2.1, February 2015
    // URF and printer-type are CUPS/AirPrint extensions (not in Bonjour Printing Spec)

    private static let ipp: [String: String] = [
        "rp": "Resource Path",              // Spec Section 9.2.2
        "ty": "Printer Make and Model",     // Spec Section 9.2.6
        "note": "Location",                 // Spec Section 9.2.3
        "adminurl": "Admin URL",            // Spec Section 9.2.9
        "pdl": "Page Description Languages", // Spec Section 9.2.8
        "URF": "Universal Raster Format",   // CUPS/AirPrint extension
        "Color": "Color Supported",         // Spec Section 9.4, Table 3
        "Duplex": "Duplex Supported",       // Spec Section 9.4, Table 3
        "Copies": "Fast Copies Supported",  // Spec Section 9.4, Table 3
        "qtotal": "Queue Total",            // Spec Section 9.2.4
        "txtvers": "TXT Version",           // Spec Section 9.2.1
        "priority": "Priority",             // Spec Section 9.2.5
        "product": "Product",               // Spec Section 9.2.7
        "usb_MFG": "USB Manufacturer",      // Spec Section 9.2.10
        "usb_MDL": "USB Model",             // Spec Section 9.2.11
        "TLS": "TLS Version",               // Spec Section 9.2.14
        "UUID": "Printer UUID",             // Spec Section 9.2.15
        "printer-type": "Printer Type",     // CUPS extension
    ]

    // MARK: - AirPlay (_airplay._tcp)
    // Source: Reverse-engineered. openairplay/airplay-spec, AirPlay 2 Internals
    // (emanuelecozzi.net/docs/airplay2/discovery/), shairport-sync
    // No official Apple documentation exists for these keys.

    private static let airplay: [String: String] = [
        "model": "Model",
        "features": "Features",
        "deviceid": "Device ID",
        "pi": "Pairing Identity",              // PublicCUAirPlayPairingIdentifier
        "srcvers": "Source Version",
        "flags": "Flags",
        "pk": "Public Key",
        "acl": "Access Control",
        "btaddr": "Bluetooth Address",
        "fv": "Firmware Version",
        "gcgl": "Group Contains Group Leader",
        "gid": "Group ID",
        "igl": "Is Group Leader",
        "manufacturer": "Manufacturer",
        "osvers": "OS Version",
        "protovers": "Protocol Version",
        "psi": "System Pairing Identity",       // PublicCUSystemPairingIdentifier
        "rsf": "Required Sender Features",
        "serialNumber": "Serial Number",
        "vv": "AirPlay 2 Version",                // Apple internal codename "vodka"; typically value "2"
        "fex": "Features (Extended)",              // Base64-encoded features in little-endian form (shairport-sync)
        "act": "Unknown (act)",                    // Undocumented; observed on Apple AirPlay devices
        "at": "Unknown (at)",                      // Undocumented; hex value observed on Apple AirPlay devices
        "c": "Unknown (c)",                        // Undocumented; observed on Apple AirPlay devices
    ]

    // MARK: - HomeKit Accessory Protocol (_hap._tcp)
    // Source: Apple HomeKitADK HAP/HAPIPServiceDiscovery.c
    // https://github.com/apple/HomeKitADK/blob/master/HAP/HAPIPServiceDiscovery.c
    // References HAP Specification R14, Table 6-7

    private static let hap: [String: String] = [
        "c#": "Config Number",
        "ff": "Pairing Feature Flags",
        "id": "Device ID",
        "md": "Model Name",
        "pv": "Protocol Version",
        "s#": "State Number",
        "sf": "Status Flags",
        "ci": "Category ID",
        "sh": "Setup Hash",
    ]

    // MARK: - Google Cast (_googlecast._tcp)
    // Source: Reverse-engineered. pychromecast, CR-Cast wiki, oakbits.com
    // No official Google documentation exists for these keys.

    private static let googlecast: [String: String] = [
        "id": "Device ID",
        "cd": "Client Device ID",               // Unverified; poorly documented
        "md": "Model Name",
        "fn": "Friendly Name",
        "ca": "Capability Flags",                // Disputed: may be "Certificate Authority"
        "st": "Status",
        "ve": "Version",
        "ic": "Icon Path",
        "rs": "Receiver Status",
    ]

    // MARK: - CompanionLink (_companion-link._tcp)
    // Source: Reverse-engineered. pyatv (github.com/postlund/pyatv)
    // Apple proprietary. Most values rotate for privacy.

    private static let companionLink: [String: String] = [
        "rpAD": "Auth Tag",                      // Rotates; pyatv: "Bonjour Auth Tag"
        "rpBA": "Bluetooth Address",
        "rpFl": "Flags",
        "rpHA": "HomeKit Auth Tag",              // Rotates; pyatv: "HomeKit AuthTag"
        "rpHI": "HomeKit Rotating ID",           // Rotates
        "rpHN": "Hostname",
        "rpMac": "MAC Address",
        "rpVr": "Version",
        "rpMRtID": "MediaRemote ID",
        "rpMd": "Model",
    ]

    // MARK: - SMB (_smb._tcp)
    // Source: Observed on macOS. Limited documentation.

    private static let smb: [String: String] = [
        "dk": "Disk Kind",                       // May be specific to _adisk._tcp
    ]

    // MARK: - RAOP (_raop._tcp) — Remote Audio Output Protocol
    // Source: Reverse-engineered. openairplay/airplay-spec, AirPlay 2 Internals
    // (emanuelecozzi.net/docs/airplay2/discovery/), shairport-sync

    private static let raop: [String: String] = [
        "am": "Model",
        "vs": "Server Version",
        "vn": "AirTunes Protocol Version",
        "tp": "Transport Protocol",
        "md": "Metadata Types",
        "da": "Digest Auth",                     // RFC 2617 digest auth boolean
        "cn": "Audio Codecs",                    // 0=PCM, 1=ALAC, 2=AAC, 3=AAC ELD
        "et": "Encryption Types",
        "ft": "Features",
        "sv": "Unknown (sv)",                    // Boolean value; purpose unverified
        "pk": "Public Key",
        "fv": "Firmware Version",
        "ov": "OS Version",
        "sf": "Status Flags",
        "vv": "AirPlay 2 Version",                // Apple internal codename "vodka"; typically value "2"
    ]

    // MARK: - Device Info (_device-info._tcp)
    // Source: Observed on Apple devices. Used by Finder for device icons.

    private static let deviceInfo: [String: String] = [
        "model": "Model",
    ]

    // MARK: - Remote Pairing (_remotepairing._tcp)
    // Source: Reverse-engineered. theapplewiki.com/wiki/Dev:RemotePairing.framework
    // Apple proprietary.

    private static let remotePairing: [String: String] = [
        "authTag": "Auth Tag",
        "flags": "Flags",
        "identifier": "Identifier",
        "minVer": "Minimum Version",
        "ver": "Version",
    ]

    // MARK: - Spotify Connect (_spotify-connect._tcp)
    // Source: librespot (github.com/librespot-org/librespot) discovery/src/lib.rs

    private static let spotifyConnect: [String: String] = [
        "CPath": "Connect Path",
        "Stack": "Stack",
        "VERSION": "Version",
    ]

    // MARK: - SRP Replication (_srpl-tls._tcp) — Service Registration Protocol over TLS
    // Source: draft-ietf-dnssd-srp-replication (IETF)
    // https://dnssd-wg.github.io/draft-ietf-dnssd-srp-replication/draft-ietf-dnssd-srp-replication.html
    // xpanid and priority are Apple extensions not in the IETF draft.

    private static let srplTls: [String: String] = [
        "did": "Dataset ID",                      // 64-bit hex; establishes common SRP dataset
        "dn": "Domain Name",                      // Domain this dataset represents
        "pid": "Partner ID",                       // 64-bit hex; uniquely identifies SRP partner
        "priority": "Priority",                    // Apple extension; server selection priority
        "xpanid": "Extended PAN ID",              // Apple extension; Thread network identifier
    ]

    // MARK: - Lookup by service type

    private static let labelsByServiceType: [String: [String: String]] = [
        "_meshcop._udp": meshcop,
        "_matter._tcp": matter,
        "_matterc._udp": matter,
        "_matterd._udp": matter,
        "_ipp._tcp": ipp,
        "_ipps._tcp": ipp,
        "_airplay._tcp": airplay,
        "_hap._tcp": hap,
        "_googlecast._tcp": googlecast,
        "_companion-link._tcp": companionLink,
        "_smb._tcp": smb,
        "_raop._tcp": raop,
        "_device-info._tcp": deviceInfo,
        "_remotepairing._tcp": remotePairing,
        "_spotify-connect._tcp": spotifyConnect,
        "_srpl-tls._tcp": srplTls,
    ]

    static func label(for key: String, serviceType: String) -> String? {
        labelsByServiceType[serviceType]?[key]
    }

    static func displayKey(for key: String, serviceType: String) -> String {
        if let label = label(for: key, serviceType: serviceType) {
            return "\(label) (\(key))"
        }
        return key
    }
}
