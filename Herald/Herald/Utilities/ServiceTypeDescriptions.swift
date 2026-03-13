import Foundation

enum ServiceTypeDescriptions {

    struct Group {
        let name: String
        let types: [(type: String, description: String)]
    }

    static let groups: [Group] = [
        Group(name: "Meta-Query", types: [
            ("_dns-sd._udp", "DNS Service Discovery"),
        ]),
        Group(name: "Apple Device Communication", types: [
            ("_companion-link._tcp", "Companion Link"),
            ("_device-info._tcp", "Device Info"),
            ("_apple-mobdev2._tcp", "Apple Mobile Device"),
            ("_airdrop._tcp", "AirDrop"),
            ("_remotepairing._tcp", "Remote Pairing"),
            ("_mediaremote._tcp", "Media Remote"),
            ("_apple-pairable._tcp", "Apple Pairable"),
            ("_continuity._tcp", "Continuity / Handoff"),
        ]),
        Group(name: "AirPlay / Media", types: [
            ("_airplay._tcp", "AirPlay"),
            ("_raop._tcp", "AirPlay Audio (RAOP)"),
            ("_airplayTXTver._tcp", "AirPlay 2 Extended"),
            ("_atc._tcp", "Apple TV Control"),
        ]),
        Group(name: "HomeKit / Smart Home", types: [
            ("_homekit._tcp", "HomeKit Accessory"),
            ("_hap._tcp", "HomeKit Accessory Protocol"),
            ("_hks._tcp", "HomeKit Secure"),
            ("_coap._udp", "CoAP (Constrained Application Protocol)"),
            ("_coaps._udp", "Secure CoAP (DTLS)"),
        ]),
        Group(name: "Thread / Matter", types: [
            ("_meshcop._udp", "Thread Border Router (MeshCoP)"),
            ("_matter._tcp", "Matter Smart Home"),
            ("_matter._udp", "Matter Smart Home (UDP)"),
            ("_matterc._udp", "Matter Commissioner"),
            ("_trel._udp", "Thread Radio Encapsulation"),
            ("_srpl-tls._tcp", "SRP Server (TLS)"),
            ("_dnssd._udp", "DNS-SD Discovery Proxy"),
        ]),
        Group(name: "File Sharing / Remote Access", types: [
            ("_smb._tcp", "SMB File Sharing"),
            ("_afpovertcp._tcp", "AFP File Sharing"),
            ("_nfs._tcp", "NFS File Sharing"),
            ("_ftp._tcp", "FTP"),
            ("_ssh._tcp", "SSH (Secure Shell)"),
            ("_sftp-ssh._tcp", "SFTP"),
            ("_rfb._tcp", "VNC Remote Desktop"),
            ("_rdp._tcp", "Remote Desktop (RDP)"),
            ("_eppc._tcp", "Apple Remote Events"),
            ("_vnc._tcp", "VNC Remote Desktop"),
            ("_webdav._tcp", "WebDAV File Sharing"),
            ("_webdavs._tcp", "Secure WebDAV File Sharing"),
            ("_net-assistant._udp", "Apple Remote Desktop"),
        ]),
        Group(name: "Printing / Scanning", types: [
            ("_printer._tcp", "Printer"),
            ("_ipp._tcp", "IPP Printing"),
            ("_ipps._tcp", "Secure IPP Printing"),
            ("_pdl-datastream._tcp", "PDL Data Stream Printing"),
            ("_scanner._tcp", "Scanner"),
            ("_uscan._tcp", "AirScan Scanner"),
            ("_uscans._tcp", "Secure AirScan Scanner"),
        ]),
        Group(name: "Web Servers", types: [
            ("_http._tcp", "Web Server (HTTP)"),
            ("_https._tcp", "Secure Web Server (HTTPS)"),
        ]),
        Group(name: "Third-Party Media & Smart Home", types: [
            ("_googlecast._tcp", "Google Cast (Chromecast)"),
            ("_spotify-connect._tcp", "Spotify Connect"),
            ("_sonos._tcp", "Sonos"),
            ("_daap._tcp", "Digital Audio Access (iTunes)"),
            ("_dpap._tcp", "Digital Photo Access"),
            ("_touch-able._tcp", "iTunes Remote Pairing"),
            ("_roku-rcp._tcp", "Roku Control Protocol"),
            ("_hue._tcp", "Philips Hue Bridge"),
            ("_dacp._tcp", "iTunes Remote Control (DACP)"),
        ]),
        Group(name: "Network Infrastructure", types: [
            ("_sleep-proxy._udp", "Sleep Proxy"),
            ("_workstation._tcp", "Workstation"),
            ("_airport._tcp", "AirPort Base Station"),
            ("_dns-update._udp", "DNS Dynamic Update"),
            ("_ntp._udp", "NTP Time Server"),
        ]),
        Group(name: "Messaging", types: [
            ("_ichat._tcp", "iChat / Messages"),
            ("_presence._tcp", "XMPP Presence"),
        ]),
    ]

    private static let descriptions: [String: String] = {
        var map: [String: String] = [:]
        for group in groups {
            for entry in group.types {
                map[entry.type] = entry.description
            }
        }
        return map
    }()

    static func description(for type: String) -> String? {
        descriptions[type]
    }

}
