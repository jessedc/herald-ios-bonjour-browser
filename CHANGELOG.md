# Changelog

## Version 1.4

### Thread Network Grouping
Border routers are now grouped by Thread network so routers on the same mesh appear together under a shared header. Grouping uses the Network Name (`nn`) with fallback to Extended PAN ID (`xp`) if present.

### Decoded Binary TXT Records
TXT record values that arrive as raw bytes — Thread's Partition ID (`pt`), Extended PAN ID (`xp`), State Bitmap (`sb`), and similar MeshCoP fields — are now decoded correctly. The service detail view shows a two-line decoded + hex layout per key, with type-aware formatting (uint32, colon-separated IDs, state bitmap flags) and a printable-or-hex fallback for unknown keys.

### Config Drift Detection (Experimental)
Thread sections now surface mismatches in Active Timestamp and Extended PAN ID within a group, so you can spot when border routers on the same mesh disagree about the current dataset or have collided with a neighbour mesh. Per-router timestamps render in orange only when drift is detected.

### herald macOS CLI
A new `herald` command-line companion lives in `HeraldCLI/` and brings the "All Services" tab to the terminal with three subcommands: `types` lists known service types, `browse` time-boxes a Bonjour browse, and `resolve` returns the full detail payload (hostname, port, IPv4/IPv6, labelled TXT records). Output is JSON on stdout with a `--compact` flag for `jq` piping.

### Bug Fixes
- Renamed "Commissioners" to "Commissionable" in the Thread tab to match Matter spec terminology for `_matterc._udp` devices

## Version 1.3

### Matter Commissioning
- New Bluetooth tab scans for nearby Matter commissioning devices via BLE (service UUID 0xFFF6)

### Export Enhancements
- Service detail export enhanced to include service descriptions, decoded Thread/Matter fields, labeled TXT records, and a raw data

## Version 1.2

### Siri & App Shortcuts
- Ask Siri to count Matter smart home devices on your local network — "How many Matter devices are on my network with Herald"
- Ask Siri to count Thread border routers — "How many Thread border routers are on my network with Herald"
- Ask Siri for a full network summary — "What's on my network with Herald"

### Educational Tips
- Added contextual tips throughout the app to help new users understand Thread networks, Matter fabrics, export functionality, Siri shortcuts, and reverse DNS lookups

### Dark Mode App Icon
- Added a dark mode variant of the app icon

### Bug Fixes
- Fixed service detail scroll position resetting after navigating to Reverse DNS lookup info
- Improved service detail resolution reliability using structured concurrency
- Improved resolution time for Matter device discovery by removing redundant lookups

## Version 1.1

### Matter Tab Enhancements
- Devices are now grouped by Matter fabric for easier identification
- Operational (commissioned) Matter devices are now discovered via `_matterd._udp`
- Decoded pairing hint bitmasks into human-readable descriptions
- Humanized session interval values (ICD, SII, SAI) for better readability
- Improved section headers with numbered fabric labels instead of raw hex IDs
- Device detail view now shows parsed fabric/node IDs, ICD status, and TCP support
- Fixed data disappearing when navigating away from the Matter or Thread tabs

### Reverse DNS Lookups
- Added on-demand reverse DNS (PTR) lookups for resolved IP addresses
- Tap "Run Reverse DNS Lookup" on any service detail to query PTR records

### TXT Record Labels
- Added labels for AirPlay fields (`fex`, `act`, `at`, `c`)
- Added labels for SRP replication fields (`did`, `dn`, `pid`, `priority`, `xpanid`)
- Added Thread border router vendor/product label (`vp`)
- Fixed AirPlay version label (`vv`) description

## Version 1.0 (Initial Release)

Herald discovers and inspects Bonjour service on your local network using DNS-SD/mDNS, giving you visibility into the devices and services around you. Herald is designed for debugging smart home setups, exploring Thread and Matter devices, or just visualising what's broadcasting on your network.

- Browse 45+ Bonjour service types including HTTP, SSH, AirPlay, HomeKit, printers, file shares — in a single searchable list
- Inspect service details including hostname, port, IPv4/IPv6 addresses, and parsed TXT records with human-readable labels
- Dedicated Thread network tab showing Border Routers, TREL peers, SRP servers, and Matter commissioners with decoded metadata (network name, vendor, model, Thread version)
- Dedicated Matter tab for discovering smart home devices with vendor lookup, device type, commissioning mode, and discriminator
- Export discovered services as plain text or JSON for sharing and documentation
- Search across service names, types, and TXT record values to find what you're looking for instantly
- Clean, native iOS interface with live-updating service counts and clear error reporting
- No account required, no data collection — everything runs locally on your device

