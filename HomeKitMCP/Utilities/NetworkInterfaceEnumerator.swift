import Foundation

struct NetworkInterface: Identifiable, Hashable {
    let id: String       // BSD name, e.g., "en0"
    let name: String     // Human-readable, e.g., "Wi-Fi"
    let address: String  // IPv4 address

    var displayLabel: String {
        "\(address) (\(name))"
    }
}

enum NetworkInterfaceEnumerator {
    /// Returns all active IPv4 network interfaces excluding loopback.
    static func availableInterfaces() -> [NetworkInterface] {
        var result: [NetworkInterface] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return result }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let sa = ptr.pointee.ifa_addr.pointee
            guard sa.sa_family == UInt8(AF_INET) else { continue }

            let bsdName = String(cString: ptr.pointee.ifa_name)
            guard bsdName != "lo0" else { continue }

            var addr = ptr.pointee.ifa_addr.pointee
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            withUnsafePointer(to: &addr) { addrPtr in
                addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                    getnameinfo(sockaddrPtr, socklen_t(sa.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, 0, NI_NUMERICHOST)
                }
            }
            let ipString = String(cString: hostname)

            result.append(NetworkInterface(
                id: bsdName,
                name: humanReadableName(for: bsdName),
                address: ipString
            ))
        }
        return result
    }

    /// Checks whether a given IP address is currently assigned to a local interface.
    static func isAddressAvailable(_ address: String) -> Bool {
        if address == "127.0.0.1" || address == "0.0.0.0" { return true }
        return availableInterfaces().contains { $0.address == address }
    }

    /// Resolves a bind address, falling back to 127.0.0.1 if the stored
    /// address is a specific IP that is no longer available.
    static func resolvedBindAddress(_ stored: String) -> String {
        if isAddressAvailable(stored) { return stored }
        return "127.0.0.1"
    }

    private static func humanReadableName(for bsdName: String) -> String {
        switch bsdName {
        case "en0": return "Wi-Fi"
        case "en1": return "Ethernet"
        case let name where name.hasPrefix("en"): return "Ethernet (\(name))"
        case let name where name.hasPrefix("utun"): return "VPN (\(name))"
        case "bridge0": return "Bridge"
        case let name where name.hasPrefix("awdl"): return "AirDrop (\(name))"
        default: return bsdName
        }
    }
}
