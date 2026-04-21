import Foundation

/// Bonjour service types that `herald` advertises via `herald types`.
///
/// This list was seeded from the iOS app's `NSBonjourServices` (in
/// `Herald/Herald/Resources/Info.plist`). The iOS app needs that plist entry
/// because `NWBrowser`/mDNSResponder gate browse requests on declared types
/// on-device; the CLI runs on macOS where that restriction doesn't apply, so
/// the CLI can browse any type the user names on the command line. Keeping
/// the list static means the CLI never touches the iOS source tree at
/// runtime or build time, and minor drift from the app's plist is fine — the
/// CLI's copy is just the "known-useful" hint list for `herald types`.
///
/// If you add a new type to the iOS `NSBonjourServices` and want it
/// mentioned here too, just paste it into `allTypes`.
enum BonjourTypes {
    static let allTypes: [String] = [
        "_http._tcp",
        "_https._tcp",
        "_airplay._tcp",
        "_raop._tcp",
        "_homekit._tcp",
        "_hap._tcp",
        "_companion-link._tcp",
        "_sleep-proxy._udp",
        "_smb._tcp",
        "_afpovertcp._tcp",
        "_nfs._tcp",
        "_ftp._tcp",
        "_ssh._tcp",
        "_sftp-ssh._tcp",
        "_printer._tcp",
        "_ipp._tcp",
        "_ipps._tcp",
        "_pdl-datastream._tcp",
        "_scanner._tcp",
        "_daap._tcp",
        "_dpap._tcp",
        "_ichat._tcp",
        "_presence._tcp",
        "_rfb._tcp",
        "_rdp._tcp",
        "_device-info._tcp",
        "_googlecast._tcp",
        "_spotify-connect._tcp",
        "_sonos._tcp",
        "_meshcop._udp",
        "_matter._tcp",
        "_matter._udp",
        "_matterd._udp",
        "_matterc._udp",
        "_trel._udp",
        "_coap._udp",
        "_workstation._tcp",
        "_net-assistant._udp",
        "_apple-mobdev2._tcp",
        "_airport._tcp",
        "_airdrop._tcp",
        "_touch-able._tcp",
        "_remotepairing._tcp",
        "_mediaremote._tcp",
        "_apple-pairable._tcp",
        "_continuity._tcp",
        "_airplayTXTver._tcp",
        "_atc._tcp",
        "_hks._tcp",
        "_coaps._udp",
        "_srpl-tls._tcp",
        "_dnssd._udp",
        "_eppc._tcp",
        "_vnc._tcp",
        "_webdav._tcp",
        "_webdavs._tcp",
        "_uscan._tcp",
        "_uscans._tcp",
        "_roku-rcp._tcp",
        "_hue._tcp",
        "_dacp._tcp",
        "_dns-update._udp",
        "_ntp._udp",
    ]
}
