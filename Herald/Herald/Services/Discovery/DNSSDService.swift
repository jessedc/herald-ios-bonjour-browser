import Foundation
import dnssd
import os

private let logger = Logger(subsystem: "com.herald", category: "DNSSDService")

/// Low-level Swift wrapper around the dns_sd.h C API.
/// Provides instance browsing and service resolution
/// using AsyncStream for continuous operations and async/throws for one-shot operations.
///
/// Uses a single shared `DNSServiceRef` connection (via `DNSServiceCreateConnection`)
/// to multiplex all browse/resolve/address operations. This avoids daemon-side state
/// corruption that occurs when multiple independent connections are created.
final class DNSSDService: @unchecked Sendable {

    static let shared = DNSSDService()

    private let queue = DispatchQueue(label: "com.herald.dnssd", qos: .userInitiated)

    /// Single shared connection to mDNSResponder. All child operations are multiplexed through this.
    private var sharedRef: DNSServiceRef?

    /// Tracks active child refs (accessed only on `queue`).
    private var activeChildRefs: Set<UnsafeMutableRawPointer> = []

    private init() {
        setupSharedConnection()
    }

    private func setupSharedConnection() {
        var ref: DNSServiceRef?
        let err = DNSServiceCreateConnection(&ref)
        guard err == kDNSServiceErr_NoError, let connectionRef = ref else {
            logger.error("setupSharedConnection: DNSServiceCreateConnection failed with error \(err)")
            return
        }
        DNSServiceSetDispatchQueue(connectionRef, queue)
        sharedRef = connectionRef
        logger.info("setupSharedConnection: shared connection established")
    }

    /// Tear down the existing shared connection and create a fresh one.
    /// All active child refs are released first. Callers must re-establish
    /// any browse/resolve operations after calling this.
    func reconnect() {
        queue.async {
            logger.info("reconnect: tearing down shared connection (\(self.activeChildRefs.count) active child refs)")
            // Deallocating the parent ref frees all children automatically,
            // so just clear our tracking set without individual deallocation.
            self.activeChildRefs.removeAll()
            if let ref = self.sharedRef {
                DNSServiceRefDeallocate(ref)
                self.sharedRef = nil
            }
            self.setupSharedConnection()
        }
    }

    private func trackChildRef(_ ref: DNSServiceRef) {
        let ptr = UnsafeMutableRawPointer(ref)
        activeChildRefs.insert(ptr)
    }

    private func releaseChildRef(_ ref: DNSServiceRef) {
        let ptr = UnsafeMutableRawPointer(ref)
        activeChildRefs.remove(ptr)
        DNSServiceRefDeallocate(ref)
    }

    deinit {
        // Deallocating the parent ref frees all children automatically.
        // Do NOT iterate activeChildRefs.
        if let ref = sharedRef {
            DNSServiceRefDeallocate(ref)
        }
    }

    // MARK: - Instance Browsing

    /// Browse for service instances of a given type in a domain.
    /// Uses shared connection to avoid daemon-side state corruption.
    /// All dns_sd calls are dispatched onto the serial queue to serialize access to the shared connection.
    func browseInstances(type: String, domain: String) -> AsyncThrowingStream<BrowseInstanceEvent, Error> {
        logger.info("browseInstances: starting for type='\(type)' domain='\(domain)'")
        return AsyncThrowingStream { continuation in
            self.queue.async {
                guard let parentRef = self.sharedRef else {
                    logger.error("browseInstances: shared connection unavailable")
                    continuation.finish(throwing: DNSSDError.connectionUnavailable)
                    return
                }

                var childRef: DNSServiceRef? = parentRef

                let context = Unmanaged.passRetained(
                    BrowseInstancesCallbackContext(continuation: continuation)
                ).toOpaque()

                let err = DNSServiceBrowse(
                    &childRef,
                    DNSServiceFlags(kDNSServiceFlagsShareConnection),
                    0, // all interfaces
                    type,
                    domain,
                    { _, flags, _, errorCode, serviceName, regtype, replyDomain, context in
                        guard let context = context else { return }
                        let ctx = Unmanaged<BrowseInstancesCallbackContext>.fromOpaque(context)
                            .takeUnretainedValue()
                        if errorCode != kDNSServiceErr_NoError {
                            logger.error("browseInstances callback: error code \(errorCode)")
                            ctx.continuation.finish(throwing: DNSSDError.instanceBrowseFailed(Int(errorCode)))
                            return
                        }
                        guard let serviceName = serviceName,
                              let regtype = regtype,
                              let replyDomain = replyDomain else { return }

                        let name = String(cString: serviceName)
                        var type = String(cString: regtype)
                        if type.hasSuffix(".") { type = String(type.dropLast()) }
                        var domain = String(cString: replyDomain)
                        if !domain.hasSuffix(".") { domain += "." }

                        let isAdd = (flags & kDNSServiceFlagsAdd) != 0
                        let event = BrowseInstanceEvent(name: name, type: type, domain: domain, isAdd: isAdd)
                        logger.info("browseInstances callback: \(isAdd ? "+" : "-") '\(name)' type='\(type)' domain='\(domain)'")
                        ctx.continuation.yield(event)
                    },
                    context
                )

                guard err == kDNSServiceErr_NoError, let serviceRef = childRef else {
                    // NoAuth (-65555) means type is not in NSBonjourServices or app lacks com.apple.developer.networking.multicast entitlement
                    logger.error("browseInstances: DNSServiceBrowse failed with error \(err) for type='\(type)' domain='\(domain)'")
                    Unmanaged<BrowseInstancesCallbackContext>.fromOpaque(context).release()
                    continuation.finish(throwing: DNSSDError.instanceBrowseFailed(Int(err)))
                    return
                }

                logger.info("browseInstances: DNSServiceBrowse started successfully for type='\(type)' domain='\(domain)' (shared connection)")
                self.trackChildRef(serviceRef)

                nonisolated(unsafe) let cleanupRef = serviceRef
                nonisolated(unsafe) let cleanupCtx = context
                continuation.onTermination = { @Sendable [weak self] _ in
                    logger.info("browseInstances: stream terminated for type='\(type)' domain='\(domain)'")
                    self?.queue.async { self?.releaseChildRef(cleanupRef) }
                    Unmanaged<BrowseInstancesCallbackContext>.fromOpaque(cleanupCtx).release()
                }
            }
        }
    }

    // MARK: - Service Resolution

    /// Resolve a service instance to hostname, port, and TXT record.
    /// Uses shared connection to avoid daemon-side state corruption.
    /// All dns_sd calls are dispatched onto the serial queue to serialize access to the shared connection.
    func resolve(name: String, type: String, domain: String) async throws -> (hostname: String, port: UInt16, txtRecord: [String: String]) {
        logger.info("resolve: starting for '\(name)' type='\(type)' domain='\(domain)'")

        guard let parentRef = self.sharedRef else {
            throw DNSSDError.connectionUnavailable
        }

        nonisolated(unsafe) let capturedParentRef = parentRef
        return try await withCheckedThrowingContinuation { continuation in
            self.queue.async {
                var childRef: DNSServiceRef? = capturedParentRef

                let context = Unmanaged.passRetained(
                    ResolveCallbackContext(continuation: continuation)
                ).toOpaque()

                let err = DNSServiceResolve(
                    &childRef,
                    DNSServiceFlags(kDNSServiceFlagsShareConnection),
                    0,
                    name,
                    type,
                    domain,
                    { _, _, _, errorCode, _, hosttarget, port, txtLen, txtRecord, context in
                        guard let context = context else { return }
                        let ctx = Unmanaged<ResolveCallbackContext>.fromOpaque(context)
                            .takeUnretainedValue()

                        guard !ctx.didResume else {
                            logger.debug("resolve callback: ignoring duplicate callback for already-resumed continuation")
                            return
                        }

                        if errorCode != kDNSServiceErr_NoError {
                            logger.error("resolve callback: error code \(errorCode)")
                            ctx.didResume = true
                            ctx.continuation.resume(throwing: DNSSDError.resolveFailed(Int(errorCode)))
                            return
                        }

                        guard let hosttarget = hosttarget else {
                            logger.error("resolve callback: nil hosttarget")
                            ctx.didResume = true
                            ctx.continuation.resume(throwing: DNSSDError.resolveFailed(-1))
                            return
                        }

                        let hostname = String(cString: hosttarget)
                        let hostPort = UInt16(bigEndian: port)
                        let txt = DNSSDService.parseTXTRecordData(txtRecord, length: txtLen)
                        logger.info("resolve callback: resolved to hostname='\(hostname)' port=\(hostPort) txtKeys=[\(txt.keys.joined(separator: ", "))]")
                        ctx.didResume = true
                        ctx.continuation.resume(returning: (hostname, hostPort, txt))
                    },
                    context
                )

                guard err == kDNSServiceErr_NoError, let serviceRef = childRef else {
                    logger.error("resolve: DNSServiceResolve failed with error \(err)")
                    Unmanaged<ResolveCallbackContext>.fromOpaque(context).release()
                    continuation.resume(throwing: DNSSDError.resolveFailed(Int(err)))
                    return
                }

                logger.info("resolve: DNSServiceResolve started successfully (shared connection, 10s timeout)")
                self.trackChildRef(serviceRef)

                // Timeout: resume with error if callback hasn't fired, then cleanup
                nonisolated(unsafe) let cleanupRef = serviceRef
                nonisolated(unsafe) let cleanupCtx = context
                self.queue.asyncAfter(deadline: .now() + 10) { [weak self] in
                    let ctx = Unmanaged<ResolveCallbackContext>.fromOpaque(cleanupCtx)
                        .takeUnretainedValue()
                    if !ctx.didResume {
                        logger.warning("resolve: 10s timeout reached, no callback received")
                        ctx.didResume = true
                        ctx.continuation.resume(throwing: DNSSDError.resolveFailed(-1))
                    }
                    self?.releaseChildRef(cleanupRef)
                    Unmanaged<ResolveCallbackContext>.fromOpaque(cleanupCtx).release()
                }
            }
        }
    }

    // MARK: - TXT Record Parsing

    /// Parse raw DNS TXT record data into a key-value dictionary.
    static func parseTXTRecordData(_ data: UnsafePointer<UInt8>?, length: UInt16) -> [String: String] {
        guard let data = data, length > 0 else { return [:] }
        var result: [String: String] = [:]
        var offset = 0
        while offset < Int(length) {
            let strLen = Int(data[offset])
            offset += 1
            guard strLen > 0, offset + strLen <= Int(length) else { break }
            let bytes = UnsafeBufferPointer(start: data.advanced(by: offset), count: strLen)
            if let str = String(bytes: bytes, encoding: .utf8) {
                if let eqIdx = str.firstIndex(of: "=") {
                    let key = String(str[str.startIndex..<eqIdx])
                    let value = String(str[str.index(after: eqIdx)...])
                    result[key] = value
                } else {
                    result[str] = ""
                }
            }
            offset += strLen
        }
        return result
    }

    // MARK: - Address Lookup

    /// Look up IP addresses for a hostname.
    /// Uses shared connection to avoid daemon-side state corruption.
    /// All dns_sd calls are dispatched onto the serial queue to serialize access to the shared connection.
    func getAddresses(hostname: String) async throws -> (ipv4: [String], ipv6: [String]) {
        logger.info("getAddresses: starting lookup for hostname '\(hostname)'")

        guard let parentRef = self.sharedRef else {
            throw DNSSDError.connectionUnavailable
        }

        nonisolated(unsafe) let capturedParentRef = parentRef
        return try await withCheckedThrowingContinuation { continuation in
            self.queue.async {
                var childRef: DNSServiceRef? = capturedParentRef

                let context = Unmanaged.passRetained(
                    AddressCallbackContext(continuation: continuation)
                ).toOpaque()

                let err = DNSServiceGetAddrInfo(
                    &childRef,
                    DNSServiceFlags(kDNSServiceFlagsShareConnection),
                    0,
                    DNSServiceProtocol(kDNSServiceProtocol_IPv4 | kDNSServiceProtocol_IPv6),
                    hostname,
                    { _, flags, _, errorCode, _, address, _, context in
                        guard let context = context else { return }
                        let ctx = Unmanaged<AddressCallbackContext>.fromOpaque(context)
                            .takeUnretainedValue()

                        guard !ctx.didResume else {
                            logger.debug("getAddresses callback: ignoring, continuation already resumed")
                            return
                        }

                        if errorCode != kDNSServiceErr_NoError {
                            logger.error("getAddresses callback: error code \(errorCode)")
                            ctx.didResume = true
                            ctx.continuation.resume(throwing: DNSSDError.addressLookupFailed(Int(errorCode)))
                            return
                        }
                        guard let address = address else {
                            logger.warning("getAddresses callback: nil address pointer")
                            return
                        }

                        let family = address.pointee.sa_family
                        if family == sa_family_t(AF_INET) {
                            address.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { addr in
                                var buf = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                                var addrCopy = addr.pointee.sin_addr
                                inet_ntop(AF_INET, &addrCopy, &buf, socklen_t(INET_ADDRSTRLEN))
                                let addrStr = String(cString: buf)
                                logger.info("getAddresses callback: found IPv4 address \(addrStr)")
                                ctx.ipv4.append(addrStr)
                            }
                        } else if family == sa_family_t(AF_INET6) {
                            address.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { addr in
                                var buf = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
                                var addrCopy = addr.pointee.sin6_addr
                                inet_ntop(AF_INET6, &addrCopy, &buf, socklen_t(INET6_ADDRSTRLEN))
                                let addrStr = String(cString: buf)
                                logger.info("getAddresses callback: found IPv6 address \(addrStr)")
                                ctx.ipv6.append(addrStr)
                            }
                        } else {
                            logger.warning("getAddresses callback: unknown address family \(family)")
                        }

                        let moreComing = (flags & kDNSServiceFlagsMoreComing) != 0
                        if !moreComing {
                            logger.info("getAddresses callback: no more coming, resuming with \(ctx.ipv4.count) IPv4 + \(ctx.ipv6.count) IPv6 addresses")
                            ctx.didResume = true
                            ctx.continuation.resume(returning: (ctx.ipv4, ctx.ipv6))
                        } else {
                            logger.debug("getAddresses callback: moreComing flag set, waiting for more addresses")
                        }
                    },
                    context
                )

                guard err == kDNSServiceErr_NoError, let serviceRef = childRef else {
                    logger.error("getAddresses: DNSServiceGetAddrInfo failed with error \(err)")
                    Unmanaged<AddressCallbackContext>.fromOpaque(context).release()
                    continuation.resume(throwing: DNSSDError.addressLookupFailed(Int(err)))
                    return
                }

                logger.info("getAddresses: DNSServiceGetAddrInfo started successfully (shared connection, 5s timeout)")
                self.trackChildRef(serviceRef)

                // Timeout: resume with whatever addresses we've collected, then cleanup
                nonisolated(unsafe) let cleanupRef = serviceRef
                nonisolated(unsafe) let cleanupCtx = context
                self.queue.asyncAfter(deadline: .now() + 5) { [weak self] in
                    let ctx = Unmanaged<AddressCallbackContext>.fromOpaque(cleanupCtx)
                        .takeUnretainedValue()
                    if !ctx.didResume {
                        logger.warning("getAddresses: 5s timeout reached, resuming with \(ctx.ipv4.count) IPv4 + \(ctx.ipv6.count) IPv6 addresses collected so far")
                        ctx.didResume = true
                        ctx.continuation.resume(returning: (ctx.ipv4, ctx.ipv6))
                    }
                    self?.releaseChildRef(cleanupRef)
                    Unmanaged<AddressCallbackContext>.fromOpaque(cleanupCtx).release()
                }
            }
        }
    }
}

// MARK: - Browse Event

/// Event from DNSServiceBrowse indicating an instance was added or removed.
struct BrowseInstanceEvent: Sendable {
    let name: String
    let type: String
    let domain: String
    let isAdd: Bool
}

// MARK: - Callback Contexts

private final class BrowseInstancesCallbackContext {
    let continuation: AsyncThrowingStream<BrowseInstanceEvent, Error>.Continuation
    init(continuation: AsyncThrowingStream<BrowseInstanceEvent, Error>.Continuation) {
        self.continuation = continuation
    }
}

private final class ResolveCallbackContext {
    let continuation: CheckedContinuation<(hostname: String, port: UInt16, txtRecord: [String: String]), Error>
    var didResume = false
    init(continuation: CheckedContinuation<(hostname: String, port: UInt16, txtRecord: [String: String]), Error>) {
        self.continuation = continuation
    }
}

private final class AddressCallbackContext {
    let continuation: CheckedContinuation<(ipv4: [String], ipv6: [String]), Error>
    var ipv4: [String] = []
    var ipv6: [String] = []
    var didResume = false
    init(continuation: CheckedContinuation<(ipv4: [String], ipv6: [String]), Error>) {
        self.continuation = continuation
    }
}

// MARK: - Errors

enum DNSSDError: LocalizedError {
    case resolveFailed(Int)
    case addressLookupFailed(Int)
    case connectionUnavailable
    case instanceBrowseFailed(Int)

    var errorDescription: String? {
        switch self {
        case .resolveFailed(let code):
            return "DNS-SD resolve failed with error code \(code)"
        case .addressLookupFailed(let code):
            return "DNS-SD address lookup failed with error code \(code)"
        case .connectionUnavailable:
            return "DNS-SD shared connection is unavailable"
        case .instanceBrowseFailed(let code):
            return "DNS-SD instance browse failed with error code \(code)"
        }
    }
}
