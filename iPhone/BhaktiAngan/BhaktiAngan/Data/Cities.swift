import Foundation
import UIKit

/// A bundled city (no GPS needed) — carries the coordinates and timezone the
/// Panchang engine needs for sunrise/sunset.
///
/// The full list (~10k cities, comprehensive for India + the subcontinent plus
/// major world cities) ships as a `cities` data asset and is decoded on first
/// use. City names stay romanized in both languages, which is standard for
/// place names. Everything is on-device — no network geocoding — so the app's
/// "Data Not Collected" privacy posture holds.
struct City: Identifiable, Hashable {
    let id: String
    let nameEN: String
    let nameHI: String
    let regionEN: String
    let latitude: Double
    let longitude: Double
    let timeZoneID: String

    func name(_ l: Lang) -> String { l == .hi ? nameHI : nameEN }

    /// UTC offset (incl. DST) for the given date.
    func tzSeconds(for date: Date) -> Int {
        (TimeZone(identifier: timeZoneID) ?? .current).secondsFromGMT(for: date)
    }
}

extension City: Decodable {
    /// Decoded from a compact positional array `[id, name, region, lat, lon, tz]`
    /// — smaller and faster than keyed objects across the ~69k-city dataset.
    init(from decoder: Decoder) throws {
        var c = try decoder.unkeyedContainer()
        let id = try c.decode(String.self)
        let name = try c.decode(String.self)
        let region = try c.decode(String.self)
        let lat = try c.decode(Double.self)
        let lon = try c.decode(Double.self)
        let tz = try c.decode(String.self)
        self.init(id: id, nameEN: name, nameHI: name, regionEN: region,
                  latitude: lat, longitude: lon, timeZoneID: tz)
    }
}

enum Cities {
    /// All bundled cities, sorted by population (largest first), loaded once.
    static let all: [City] = {
        guard let data = NSDataAsset(name: "cities")?.data,
              let cities = try? JSONDecoder().decode([City].self, from: data) else {
            assertionFailure("cities data asset missing or malformed")
            return []
        }
        return cities
    }()

    private static let byIdMap: [String: City] =
        Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

    /// The selected city for a stored id, or `nil` if it can't be found.
    static func byID(_ id: String) -> City? { byIdMap[id] }

    /// Cities whose name or region matches `query`, name-prefix matches first,
    /// capped to keep the picker responsive over the full list.
    static func search(_ query: String, limit: Int = 50) -> [City] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        var prefix: [City] = []
        var contains: [City] = []
        for city in all {
            let name = city.nameEN.lowercased()
            if name.hasPrefix(q) {
                prefix.append(city)
            } else if name.contains(q) || city.regionEN.lowercased().contains(q) {
                contains.append(city)
            }
            if prefix.count >= limit { break }
        }
        return Array((prefix + contains).prefix(limit))
    }
}
