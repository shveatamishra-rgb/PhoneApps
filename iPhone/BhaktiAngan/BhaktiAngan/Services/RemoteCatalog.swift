import SwiftUI
import UIKit
import WidgetKit

/// Remote content pipeline (v1.1): lets the darshan catalog grow, and lets an
/// image be replaced or pulled, without shipping a new build.
///
/// A small manifest is fetched from the website (bare GET, no identifiers, no
/// analytics — the App Privacy "Data Not Collected" label holds):
///
/// ```json
/// {
///   "version": 1,
///   "removed":  ["day20_shiv"],
///   "replaces": [{ "imageName": "day1_shiv", "url": "https://…/day1_shiv-v2.jpg", "rev": 2 }],
///   "additions": [{
///     "id": "r1_durga_navratri", "url": "https://…/r1_durga.jpg",
///     "deityEN": "Maa Durga", "deityHI": "माँ दुर्गा", "category": "Devi",
///     "mantraEN": "…", "mantraHI": "…", "meaningEN": "…", "meaningHI": "…",
///     "blessingEN": "…", "blessingHI": "…", "isPremium": true,
///     "availableFrom": "2026-09-20", "availableUntil": null
///   }]
/// }
/// ```
///
/// Offline-first: the bundled 51 darshans are always the base. The manifest and
/// every image are cached under Application Support; no network means bundled +
/// previously cached content keeps working. An `availableFrom`/`availableUntil`
/// window turns an addition into a timed festival drop.
struct RemoteManifest: Codable, Equatable {
    var version: Int
    var removed: [String]?
    var replaces: [RemoteReplacement]?
    var additions: [RemoteAddition]?
}

struct RemoteReplacement: Codable, Equatable {
    var imageName: String
    var url: String
    var rev: Int?

    var cacheFileName: String { "\(imageName)-r\(rev ?? 1).img" }
}

struct RemoteAddition: Codable, Equatable {
    var id: String
    var url: String
    var deityEN: String
    var deityHI: String
    var category: String
    var mantraEN: String
    var mantraHI: String
    var meaningEN: String
    var meaningHI: String
    var blessingEN: String
    var blessingHI: String
    var isPremium: Bool
    var availableFrom: String?
    var availableUntil: String?

    var cacheFileName: String { "\(id).img" }

    /// yyyy-MM-dd window check, evaluated in the device's calendar.
    func isAvailable(on date: Date = Date()) -> Bool {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        if let from = availableFrom, let d = fmt.date(from: from), date < d { return false }
        if let until = availableUntil, let d = fmt.date(from: until) {
            // inclusive end day
            if date >= d.addingTimeInterval(86_400) { return false }
        }
        return true
    }

    func devotionalItem(day: Int) -> DevotionalItem {
        DevotionalItem(
            day: day,
            imageName: id,
            deityEN: deityEN,
            deityHI: deityHI,
            category: DeityCategory(rawValue: category) ?? .all,
            mantraEN: mantraEN,
            mantraHI: mantraHI,
            meaningEN: meaningEN,
            meaningHI: meaningHI,
            blessingEN: blessingEN,
            blessingHI: blessingHI,
            isPremium: isPremium
        )
    }
}

final class RemoteCatalog {
    static let shared = RemoteCatalog()

    /// Public GET served by the site's Code Snippets bridge; a 404 (route not
    /// yet installed) or any network failure is silently ignored.
    static let manifestURL = URL(string: "https://bhaktiangan.com/wp-json/bhaktiangan/v1/app-catalog")!
    private static let refreshInterval: TimeInterval = 12 * 60 * 60
    private static let lastRefreshKey = "remoteCatalogLastRefresh"

    private(set) var manifest: RemoteManifest?

    private let directory: URL
    private let imagesDirectory: URL
    private var manifestFile: URL { directory.appendingPathComponent("manifest.json") }

    init(directoryName: String = "RemoteCatalog") {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directory = support.appendingPathComponent(directoryName, isDirectory: true)
        imagesDirectory = directory.appendingPathComponent("images", isDirectory: true)
        try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        if let data = try? Data(contentsOf: manifestFile) {
            manifest = try? JSONDecoder().decode(RemoteManifest.self, from: data)
        }
    }

    // MARK: - Derived state (read by ContentCatalog / the image store)

    /// Remote kill-switch: bundled images to hide (same idea as
    /// `ContentCatalog.removedImageNames`, but changeable without a build).
    var removedImageNames: Set<String> {
        Set(manifest?.removed ?? [])
    }

    /// Additions whose window is open AND whose image is already cached —
    /// an item never appears with a missing picture.
    var availableAdditions: [DevotionalItem] {
        guard let additions = manifest?.additions else { return [] }
        var day = 1000
        var result: [DevotionalItem] = []
        for addition in additions where addition.isAvailable() {
            let file = imagesDirectory.appendingPathComponent(addition.cacheFileName)
            guard FileManager.default.fileExists(atPath: file.path) else { continue }
            day += 1
            result.append(addition.devotionalItem(day: day))
        }
        return result
    }

    /// Cached image file for a replacement (keyed by the bundled image name) or
    /// an addition (keyed by its id). Nil -> caller falls back to the bundle.
    func imagePath(for imageName: String) -> URL? {
        if let rep = manifest?.replaces?.first(where: { $0.imageName == imageName }) {
            let file = imagesDirectory.appendingPathComponent(rep.cacheFileName)
            if FileManager.default.fileExists(atPath: file.path) { return file }
        }
        if let add = manifest?.additions?.first(where: { $0.id == imageName }) {
            let file = imagesDirectory.appendingPathComponent(add.cacheFileName)
            if FileManager.default.fileExists(atPath: file.path) { return file }
        }
        return nil
    }

    // MARK: - Refresh

    /// Launch hook: at most one network refresh per 12 hours.
    func refreshIfStale() async {
        let last = UserDefaults.standard.double(forKey: Self.lastRefreshKey)
        guard Date().timeIntervalSince1970 - last > Self.refreshInterval else { return }
        await refresh()
    }

    func refresh() async {
        var request = URLRequest(url: Self.manifestURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let fresh = try? JSONDecoder().decode(RemoteManifest.self, from: data) else { return }

        try? data.write(to: manifestFile, options: .atomic)
        manifest = fresh
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.lastRefreshKey)

        // Download any missing images (replacements + windowed additions).
        var wanted: [(String, String)] = []
        for rep in fresh.replaces ?? [] { wanted.append((rep.cacheFileName, rep.url)) }
        for add in fresh.additions ?? [] where add.isAvailable() { wanted.append((add.cacheFileName, add.url)) }
        for (fileName, urlString) in wanted {
            let target = imagesDirectory.appendingPathComponent(fileName)
            guard !FileManager.default.fileExists(atPath: target.path), let url = URL(string: urlString) else { continue }
            guard let (imgData, imgResponse) = try? await URLSession.shared.data(from: url),
                  (imgResponse as? HTTPURLResponse)?.statusCode == 200,
                  UIImage(data: imgData) != nil else { continue }
            try? imgData.write(to: target, options: .atomic)
        }
    }
}

// MARK: - Image resolution seam

/// Single place every view resolves a darshan image: a cached remote file
/// (replacement or addition) wins; otherwise the bundled asset.
enum DarshanImageStore {
    static func uiImage(named name: String) -> UIImage? {
        if let path = RemoteCatalog.shared.imagePath(for: name),
           let image = UIImage(contentsOfFile: path.path) {
            return image
        }
        return UIImage(named: name)
    }
}

extension DevotionalItem {
    /// SwiftUI image for this darshan, remote-aware. Falls back to the bundled
    /// asset name so bundled items behave exactly as before.
    var displayImage: Image {
        if let ui = DarshanImageStore.uiImage(named: imageName) {
            return Image(uiImage: ui)
        }
        return Image(imageName)
    }
}

// MARK: - Gallery like counts (read-only social proof)

/// Reads the website's public gallery like counts and shows them in the app as
/// social proof ("loved by N").
///
/// IMPORTANT privacy stance: this is a BARE GET with NO identifiers, no body, no
/// device id, and we never POST a like from the app. We only read public totals,
/// so the App Privacy "Data Not Collected" label continues to hold (the same
/// stance as `RemoteCatalog`). Counts are cached for offline use and refreshed at
/// most once every 12h. Only the remotely-added collectibles (ids like
/// `r_krishna_tokri`) map to a website gallery slug; bundled darshans have no
/// website counterpart and simply show no count.
@MainActor
final class LikeCounts: ObservableObject {
    static let shared = LikeCounts()

    @Published private(set) var counts: [String: Int] = [:]

    private static let url = URL(string: "https://bhaktiangan.com/wp-json/bhaktiangan/v1/gallery-likes")!
    private static let refreshInterval: TimeInterval = 12 * 60 * 60
    private static let lastKey = "likeCountsLastRefresh"
    private let cacheFile: URL

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        cacheFile = support.appendingPathComponent("gallery-like-counts.json")
        if let data = try? Data(contentsOf: cacheFile),
           let map = try? JSONDecoder().decode([String: Int].self, from: data) {
            counts = map
        }
    }

    /// Website like-slug for a darshan item, or nil if it has no website counterpart.
    static func webSlug(forImageName name: String) -> String? {
        guard name.hasPrefix("r_") else { return nil }
        return String(name.dropFirst(2)).replacingOccurrences(of: "_", with: "-")
    }

    /// The public like count for this darshan, or nil when there is none to show.
    func count(for item: DevotionalItem) -> Int? {
        guard let slug = Self.webSlug(forImageName: item.imageName),
              let n = counts[slug], n > 0 else { return nil }
        return n
    }

    func refreshIfStale() async {
        let last = UserDefaults.standard.double(forKey: Self.lastKey)
        guard Date().timeIntervalSince1970 - last > Self.refreshInterval else { return }
        await refresh()
    }

    func refresh() async {
        var request = URLRequest(url: Self.url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let raw = obj["counts"] as? [String: Any] else { return }
        var map: [String: Int] = [:]
        for (key, value) in raw {
            if let n = (value as? NSNumber)?.intValue { map[key] = n }
        }
        counts = map
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.lastKey)
        if let out = try? JSONSerialization.data(withJSONObject: map) {
            try? out.write(to: cacheFile, options: .atomic)
        }
    }
}

// MARK: - Daily Darshan widget bridge

/// Feeds the Daily Darshan home / lock screen widget. The widget is a separate
/// process that cannot see the app's catalog or asset bundle, so the app writes
/// the next few days of darshan (a small timeline + de-duplicated JPEGs) into a
/// shared App Group container; the widget only reads and renders it. This keeps
/// the widget in perfect sync with what the app shows, including remotely added
/// or festival darshans, with no shared model code.
///
/// SETUP (one time, in Xcode): add the "App Groups" capability with the identifier
/// below to BOTH the app target and the widget extension target. Until that is done
/// this is a silent no-op, so the app builds and runs exactly as before.
enum WidgetBridge {
    static let appGroup = "group.in.bhaktiangan.app"

    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    }

    /// Publish the next 7 days of darshan for the widget and ask it to reload.
    /// Cheap and idempotent; safe to call on launch and on every foreground.
    static func publish(hasPro: Bool, lang: Lang) {
        guard let dir = containerURL else { return } // App Group not enabled yet
        let imagesDir = dir.appendingPathComponent("images", isDirectory: true)
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)

        let cal = Calendar(identifier: .gregorian)
        let fmt = DateFormatter()
        fmt.calendar = cal
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"

        var entries: [[String: String]] = []
        var written = Set<String>()
        for offset in 0..<7 {
            guard let date = cal.date(byAdding: .day, value: offset, to: Date()) else { continue }
            let item = ContentCatalog.dailyItem(for: date, hasPro: hasPro)
            if !written.contains(item.imageName) {
                if let ui = DarshanImageStore.uiImage(named: item.imageName),
                   let data = Self.jpeg(ui, maxWidth: 820) {
                    try? data.write(to: imagesDir.appendingPathComponent(item.imageName + ".jpg"), options: .atomic)
                    written.insert(item.imageName)
                }
            }
            entries.append([
                "date": fmt.string(from: date),
                "image": item.imageName,
                "deity": item.deity(lang),
                "mantra": item.mantra(lang),
                "eyebrow": item.collection(lang),
            ])
        }
        if let data = try? JSONSerialization.data(withJSONObject: entries) {
            try? data.write(to: dir.appendingPathComponent("timeline.json"), options: .atomic)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func jpeg(_ image: UIImage, maxWidth: CGFloat) -> Data? {
        let scale = min(1, maxWidth / max(image.size.width, 1))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        // Force 1 point = 1 pixel; the renderer otherwise defaults to 3x, which
        // would make a ~2400px, multi-MB image that blows the widget memory budget.
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return resized.jpegData(compressionQuality: 0.8)
    }
}

// MARK: - Daily Verse widget bridge

/// Feeds the Daily Verse (shlok) widget. Writes the next 7 days of verse-of-day
/// (Sanskrit + meaning + source) to the App Group as `verse_timeline.json`; the
/// widget rolls through them by date. Text only, no images. Matches the app's
/// free/Pro pool so the widget shows exactly the shlok the app shows.
enum VerseBridge {
    static let appGroup = "group.in.bhaktiangan.app"

    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    }

    static func publish(hasPro: Bool, lang: Lang) {
        guard let dir = containerURL else { return }   // App Group not enabled yet
        let cal = Calendar(identifier: .gregorian)
        let fmt = DateFormatter()
        fmt.calendar = cal
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"

        var entries: [[String: String]] = []
        for offset in 0..<7 {
            guard let date = cal.date(byAdding: .day, value: offset, to: Date()),
                  let verse = VerseCatalog.verseOfDay(for: date, hasPro: hasPro) else { continue }
            entries.append([
                "date": fmt.string(from: date),
                "ref": verse.ref,
                "source": verse.source(lang),
                "sanskrit": verse.sanskrit,
                "meaning": verse.meaning(lang),
                "theme": verse.themeLabel(lang),
            ])
        }
        if let data = try? JSONSerialization.data(withJSONObject: entries) {
            try? data.write(to: dir.appendingPathComponent("verse_timeline.json"), options: .atomic)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Choghadiya widget bridge

/// Feeds the Choghadiya (muhurat) widget. Same idea as `WidgetBridge`: the app
/// computes the day's choghadiya periods for the user's chosen Panchang location
/// and writes them to the shared App Group container; the widget reads and rolls
/// through them. The widget follows the app's location (iOS widgets can't host a
/// location picker in the tile). No-op if the App Group is off; if no location is
/// chosen it clears the file so the widget prompts the user to set one.
@MainActor
enum ChoghadiyaBridge {
    static let appGroup = "group.in.bhaktiangan.app"
    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    }

    static func publish() {
        guard let dir = containerURL else { return }
        let target = dir.appendingPathComponent("choghadiya.json")
        let cityID = UserDefaults.standard.string(forKey: "panchangCityID") ?? ""
        guard let city = LocationManager.shared.activeCity(manualID: cityID, lang: .en) else {
            try? FileManager.default.removeItem(at: target)
            WidgetCenter.shared.reloadAllTimelines()
            return
        }
        let cal = Calendar(identifier: .gregorian)
        var periods: [Choghadiya] = []
        // 7 days like WidgetBridge: the widget's timeline advances by itself at every
        // muhurat boundary, so this window is how long it stays correct app-unopened.
        // Start at -1: night choghadiya belongs to the date it STARTS on, so between
        // midnight and sunrise the running period lives in yesterday's compute. Without
        // yesterday, a post-midnight publish loses the current period and the widget
        // falls back to showing the morning's first muhurat as if it were current.
        for offset in -1..<7 {
            let day = cal.date(byAdding: .day, value: offset, to: Date()) ?? Date()
            if let r = PanchangCalculator.compute(for: day, city: city) {
                periods += r.dayChoghadiya + r.nightChoghadiya
            }
        }
        let now = Date()
        var seen = Set<Int>()
        let list = periods
            .filter { $0.end > now }
            .filter { seen.insert(Int($0.start.timeIntervalSince1970)).inserted }
            .sorted { $0.start < $1.start }
        let rows: [[String: Any]] = list.map { c in
            [
                "nameEN": c.nameEN, "nameHI": c.nameHI,
                "start": c.start.timeIntervalSince1970,
                "end": c.end.timeIntervalSince1970,
                "quality": c.quality == .good ? "good" : (c.quality == .bad ? "bad" : "neutral"),
                "isDay": c.isDay,
            ]
        }
        let payload: [String: Any] = [
            "cityEN": city.nameEN, "cityHI": city.nameHI, "tz": city.timeZoneID, "periods": rows,
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload) {
            try? data.write(to: target, options: .atomic)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
