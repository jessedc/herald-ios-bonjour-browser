# Changelog

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

