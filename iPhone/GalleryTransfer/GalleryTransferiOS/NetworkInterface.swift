import Foundation

enum NetworkInterface {
    /// Best-guess LAN IPv4 for another phone to reach this device on the same Wi-Fi.
    /// Prefers en0 (Wi-Fi), then any private-range IPv4, skipping loopback, cellular,
    /// and link-local — so we hand out a numeric address that actually resolves rather
    /// than falling back to `iphone.local`.
    static func wifiIPv4Address() -> String? {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaces) == 0 else {
            return nil
        }
        defer {
            freeifaddrs(interfaces)
        }

        var preferred: String?   // en0 (Wi-Fi)
        var fallback: String?    // any other private IPv4

        var pointer = interfaces
        while let interface = pointer?.pointee {
            defer {
                pointer = interface.ifa_next
            }

            guard interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) else {
                continue
            }

            let name = String(cString: interface.ifa_name)
            guard name != "lo0", !name.hasPrefix("pdp_ip") else {
                continue
            }

            var address = interface.ifa_addr.pointee
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let result = getnameinfo(
                &address,
                socklen_t(interface.ifa_addr.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            )
            guard result == 0 else {
                continue
            }

            let ip = String(cString: hostname)
            if ip.hasPrefix("169.254.") {
                continue
            }

            if name == "en0" {
                preferred = ip
            } else if fallback == nil, isPrivateIPv4(ip) {
                fallback = ip
            }
        }

        return preferred ?? fallback
    }

    private static func isPrivateIPv4(_ ip: String) -> Bool {
        if ip.hasPrefix("192.168.") || ip.hasPrefix("10.") {
            return true
        }
        let parts = ip.split(separator: ".")
        if parts.count == 4, parts[0] == "172", let second = Int(parts[1]), (16...31).contains(second) {
            return true
        }
        return false
    }
}
