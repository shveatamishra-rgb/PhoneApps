import WidgetKit
import SwiftUI
import UIKit

// Must match WidgetBridge.appGroup in the main app.
private let appGroupID = "group.in.bhaktiangan.app"

// Brand palette (the widget is a separate target and cannot see the app's AppTheme).
private enum Brand {
    static let ink     = Color(red: 0.23, green: 0.17, blue: 0.13)
    static let cream   = Color(red: 0.96, green: 0.94, blue: 0.88)
    static let gold    = Color(red: 0.80, green: 0.64, blue: 0.29)
    static let vermil  = Color(red: 0.75, green: 0.23, blue: 0.17)
    static let teal    = Color(red: 0.12, green: 0.37, blue: 0.35)
}

// MARK: - Shared data (written by the app's WidgetBridge)

struct DarshanInfo {
    let date: Date
    let imageName: String
    let deity: String
    let mantra: String
    let eyebrow: String
}

enum DarshanStore {
    static var container: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    static func timeline() -> [DarshanInfo] {
        guard let dir = container,
              let data = try? Data(contentsOf: dir.appendingPathComponent("timeline.json")),
              let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else { return [] }
        let cal = Calendar(identifier: .gregorian)
        let fmt = DateFormatter()
        fmt.calendar = cal
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"
        return rows.compactMap { row -> DarshanInfo? in
            guard let ds = row["date"], let d = fmt.date(from: ds) else { return nil }
            return DarshanInfo(date: cal.startOfDay(for: d),
                               imageName: row["image"] ?? "",
                               deity: row["deity"] ?? "",
                               mantra: row["mantra"] ?? "",
                               eyebrow: row["eyebrow"] ?? "")
        }.sorted { $0.date < $1.date }
    }

    static func image(_ name: String) -> UIImage? {
        guard !name.isEmpty, let dir = container else { return nil }
        let url = dir.appendingPathComponent("images").appendingPathComponent(name + ".jpg")
        return UIImage(contentsOfFile: url.path)
    }
}

// MARK: - Timeline

struct DarshanEntry: TimelineEntry {
    let date: Date
    let info: DarshanInfo?   // image loaded lazily in the view, so only the shown entry decodes
}

struct DarshanProvider: TimelineProvider {
    func placeholder(in context: Context) -> DarshanEntry { currentEntry() }

    func getSnapshot(in context: Context, completion: @escaping (DarshanEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DarshanEntry>) -> Void) {
        let cal = Calendar(identifier: .gregorian)
        let infos = DarshanStore.timeline()
        guard !infos.isEmpty else {
            // No data yet (app may not have written it). Retry soon rather than
            // caching an empty state for hours.
            completion(Timeline(entries: [currentEntry()], policy: .after(Date().addingTimeInterval(60))))
            return
        }
        let entries = infos.map { DarshanEntry(date: $0.date, info: $0) }
        let reload = cal.date(byAdding: .day, value: 1, to: infos.last!.date) ?? Date().addingTimeInterval(86_400)
        completion(Timeline(entries: entries, policy: .after(reload)))
    }

    private func currentEntry() -> DarshanEntry {
        let infos = DarshanStore.timeline()
        let today = Calendar(identifier: .gregorian).startOfDay(for: Date())
        let info = infos.last(where: { $0.date <= today }) ?? infos.first
        return DarshanEntry(date: Date(), info: info)
    }
}

// MARK: - Views

struct DarshanWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DarshanEntry

    private var deity: String { entry.info?.deity ?? "Bhakti Angan" }
    private var mantra: String { entry.info?.mantra ?? "" }
    private var eyebrow: String { entry.info?.eyebrow ?? "" }
    private var uiImage: UIImage? { entry.info.flatMap { DarshanStore.image($0.imageName) } }

    var body: some View {
        content.widgetURL(URL(string: "bhaktiangan://today"))
    }

    @ViewBuilder private var content: some View {
        switch family {
        case .systemMedium: medium
        case .systemLarge: large
        case .accessoryRectangular: rectangular
        case .accessoryInline: inline
        default: small
        }
    }

    // Full-bleed artwork with a soft fallback gradient.
    @ViewBuilder private var artwork: some View {
        if let ui = uiImage {
            Image(uiImage: ui).resizable().scaledToFill()
        } else {
            LinearGradient(colors: [Brand.teal, Brand.vermil], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    // systemSmall: full-bleed image, name over a bottom scrim.
    private var small: some View {
        VStack(alignment: .leading, spacing: 3) {
            Spacer(minLength: 0)
            if !eyebrow.isEmpty {
                Text(eyebrow.uppercased())
                    .font(.system(size: 9, weight: .bold)).tracking(1.1)
                    .foregroundStyle(.white.opacity(0.85))
            }
            Text(deity)
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundStyle(.white).lineLimit(2).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { scrimmed }
    }

    // systemLarge: bigger image, eyebrow + name + mantra.
    private var large: some View {
        VStack(alignment: .leading, spacing: 6) {
            Spacer(minLength: 0)
            Text(eyebrow.isEmpty ? "TODAY’S DARSHAN" : eyebrow.uppercased())
                .font(.system(size: 12, weight: .bold)).tracking(1.4)
                .foregroundStyle(Brand.gold)
            Text(deity)
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(.white).lineLimit(2).minimumScaleFactor(0.7)
            if !mantra.isEmpty {
                Text(mantra)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92)).lineLimit(1).minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { scrimmed }
    }

    private var scrimmed: some View {
        ZStack {
            artwork
            LinearGradient(colors: [.black.opacity(0.72), .black.opacity(0.15), .clear],
                           startPoint: .bottom, endPoint: .center)
        }
    }

    // systemMedium: framed thumbnail + text on cream.
    private var medium: some View {
        HStack(spacing: 14) {
            artwork
                .frame(width: 112)
                .frame(maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                Text(eyebrow.isEmpty ? "TODAY’S DARSHAN" : eyebrow.uppercased())
                    .font(.system(size: 10, weight: .bold)).tracking(1.2)
                    .foregroundStyle(Brand.vermil)
                Text(deity)
                    .font(.system(size: 21, weight: .bold, design: .serif))
                    .foregroundStyle(Brand.ink).lineLimit(2).minimumScaleFactor(0.7)
                if !mantra.isEmpty {
                    Text(mantra)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Brand.teal).lineLimit(2).minimumScaleFactor(0.8)
                }
                Spacer(minLength: 0)
            }
            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) { Brand.cream }
    }

    // Lock screen (tinted / monochrome): text forward.
    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(eyebrow.isEmpty ? "Today’s Darshan" : eyebrow)
                .font(.system(size: 12, weight: .semibold))
            Text(deity).font(.headline).lineLimit(1)
            if !mantra.isEmpty { Text(mantra).font(.caption).lineLimit(1) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Color.clear }
    }

    private var inline: some View {
        Text(mantra.isEmpty ? deity : "\(deity) · \(mantra)")
    }
}

// MARK: - Widget

struct DarshanWidget: Widget {
    let kind = "DarshanWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DarshanProvider()) { entry in
            DarshanWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Darshan")
        .description("A new darshan every day, on your Home and Lock Screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct DarshanWidgetBundle: WidgetBundle {
    var body: some Widget {
        DarshanWidget()
        ChoghadiyaWidget()
        VerseWidget()
    }
}
