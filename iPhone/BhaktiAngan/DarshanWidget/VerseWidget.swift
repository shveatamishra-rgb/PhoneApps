import WidgetKit
import SwiftUI
import UIKit   // NSDataAsset for the bundled verse fallback

// Must match VerseBridge.appGroup in the main app.
private let verseAppGroupID = "group.in.bhaktiangan.app"

private enum VBrand {
    static let plum  = Color(red: 0.24, green: 0.08, blue: 0.16)
    static let teal  = Color(red: 0.10, green: 0.32, blue: 0.31)
    static let gold  = Color(red: 0.86, green: 0.70, blue: 0.38)
}

// MARK: - Shared data (written by the app's VerseBridge)

struct VerseInfo {
    let date: Date
    let ref: String
    let source: String
    let sanskrit: String
    let meaning: String
    let theme: String
}

enum VerseStore {
    static var container: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: verseAppGroupID)
    }

    static func timeline() -> [VerseInfo] {
        guard let dir = container,
              let data = try? Data(contentsOf: dir.appendingPathComponent("verse_timeline.json")),
              let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else { return [] }
        let cal = Calendar(identifier: .gregorian)
        let fmt = DateFormatter()
        fmt.calendar = cal
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd"
        return rows.compactMap { row -> VerseInfo? in
            guard let ds = row["date"], let d = fmt.date(from: ds) else { return nil }
            return VerseInfo(date: cal.startOfDay(for: d),
                             ref: row["ref"] ?? "",
                             source: row["source"] ?? "",
                             sanskrit: row["sanskrit"] ?? "",
                             meaning: row["meaning"] ?? "",
                             theme: row["theme"] ?? "")
        }.sorted { $0.date < $1.date }
    }
}

// MARK: - Bundled fallback (starvation-proofing)
//
// The bridge writes only ~7 days of entries; if the app is not opened after that,
// the widget must never freeze on a stale verse or go blank. A copy of the app's
// verses.json is bundled in this extension's asset catalog, and the fallback picks
// the same free-pool verse the app would (gregorian day-of-year modulo), so the
// widget stays fresh indefinitely without the bridge.
enum VerseFallback {
    private struct Row: Decodable {
        let ref: String
        let sanskrit: String
        let meaningEN: String
        let meaningHI: String
        let isPremium: Bool
    }

    private static let freePool: [Row] = {
        guard let asset = NSDataAsset(name: "verses"),
              let rows = try? JSONDecoder().decode([Row].self, from: asset.data) else { return [] }
        return rows.filter { !$0.isPremium }
    }()

    /// Hindi output if the bridged rows were Hindi (the bridge localizes `source`);
    /// English otherwise. Keeps the fallback consistent with the user's app language.
    static func info(for date: Date, hindi: Bool) -> VerseInfo? {
        guard !freePool.isEmpty else { return nil }
        let cal = Calendar(identifier: .gregorian)
        let day = cal.ordinality(of: .day, in: .year, for: date) ?? 1
        let v = freePool[(day - 1) % freePool.count]
        return VerseInfo(date: cal.startOfDay(for: date),
                         ref: v.ref,
                         source: (hindi ? "भगवद्गीता " : "Bhagavad Gita ") + v.ref,
                         sanskrit: v.sanskrit,
                         meaning: hindi ? v.meaningHI : v.meaningEN,
                         theme: "")
    }

    static func isHindi(_ infos: [VerseInfo]) -> Bool {
        infos.last?.source.hasPrefix("भगवद्गीता") ?? false
    }
}

// MARK: - Timeline

struct VerseEntry: TimelineEntry {
    let date: Date
    let info: VerseInfo?
}

struct VerseProvider: TimelineProvider {
    func placeholder(in context: Context) -> VerseEntry { currentEntry() }

    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: Date())
        let infos = VerseStore.timeline()
        let hindi = VerseFallback.isHindi(infos)

        // Bridged entries first (they carry the app's exact language + Pro pool),
        // then bundled-fallback entries so the timeline always extends 7 days past
        // today even if the app is never opened again.
        var entries = infos.filter { $0.date >= today }.map { VerseEntry(date: $0.date, info: $0) }
        let lastCovered = entries.last?.date ?? cal.date(byAdding: .day, value: -1, to: today) ?? today
        var d = cal.date(byAdding: .day, value: 1, to: lastCovered) ?? today
        let horizon = cal.date(byAdding: .day, value: 7, to: today) ?? today
        while d <= horizon {
            if let info = VerseFallback.info(for: d, hindi: hindi) {
                entries.append(VerseEntry(date: d, info: info))
            }
            d = cal.date(byAdding: .day, value: 1, to: d) ?? horizon.addingTimeInterval(1)
        }

        // Today's entry: if the bridge already covered today, that one wins (it is
        // first in the array); otherwise the fallback above supplied it.
        if entries.isEmpty {
            completion(Timeline(entries: [currentEntry()], policy: .after(Date().addingTimeInterval(3_600))))
            return
        }
        // Ensure there is an entry active right now (entries dated today at 00:00 cover this).
        let reloadBase = entries.last?.date ?? today
        let reload = cal.date(byAdding: .day, value: 1, to: reloadBase) ?? Date().addingTimeInterval(86_400)
        completion(Timeline(entries: entries, policy: .after(reload)))
    }

    private func currentEntry() -> VerseEntry {
        let infos = VerseStore.timeline()
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: Date())
        // Prefer a bridged entry for today; fall back to the bundled catalog rather
        // than freezing on a stale bridged verse.
        if let info = infos.last(where: { cal.isDate($0.date, inSameDayAs: today) }) {
            return VerseEntry(date: Date(), info: info)
        }
        let hindi = VerseFallback.isHindi(infos)
        return VerseEntry(date: Date(), info: VerseFallback.info(for: today, hindi: hindi) ?? infos.last)
    }
}

// MARK: - Views

struct VerseWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: VerseEntry

    private var sanskrit: String { entry.info?.sanskrit ?? "" }
    private var meaning: String { entry.info?.meaning ?? "" }
    private var source: String { entry.info?.source ?? "Bhagavad Gita" }
    // One-line form of the Sanskrit (widgets are tight on height).
    private var sanskritOneLine: String {
        sanskrit.replacingOccurrences(of: "\n", with: " ")
    }

    var body: some View {
        content.widgetURL(URL(string: "bhaktiangan://verse"))
    }

    @ViewBuilder private var content: some View {
        if entry.info == nil {
            empty
        } else {
            switch family {
            case .systemLarge: large
            case .accessoryRectangular: rectangular
            case .accessoryInline: inline
            default: small   // systemSmall + systemMedium share the compact layout
            }
        }
    }

    private var gradient: some View {
        LinearGradient(colors: [VBrand.plum, VBrand.teal],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // systemSmall / systemMedium: source eyebrow + Sanskrit, meaning if room.
    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SHLOK")
                .font(.system(size: 9, weight: .bold)).tracking(1.2)
                .foregroundStyle(VBrand.gold)
            Text(sanskritOneLine)
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
                .lineLimit(family == .systemMedium ? 2 : 3)
                .minimumScaleFactor(0.7)
            if family == .systemMedium, !meaning.isEmpty {
                Text(meaning)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Text(source)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { gradient }
    }

    // systemLarge: full verse + meaning.
    private var large: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TODAY’S SHLOK")
                .font(.system(size: 12, weight: .bold)).tracking(1.4)
                .foregroundStyle(VBrand.gold)
            Text(sanskrit)
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
                .lineSpacing(6)
                .minimumScaleFactor(0.7)
            if !meaning.isEmpty {
                Text(meaning)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(4)
            }
            Spacer(minLength: 0)
            Text(source)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { gradient }
    }

    // Lock screen rectangular.
    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(sanskritOneLine).font(.headline).lineLimit(1)
            Text(meaning).font(.caption2).lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Color.clear }
    }

    private var inline: some View {
        Text(sanskritOneLine)
    }

    private var empty: some View {
        VStack(spacing: 5) {
            Image(systemName: "book.closed").font(.footnote)
            Text("Open Bhakti Angan").font(.caption2).multilineTextAlignment(.center)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) { gradient }
    }
}

// MARK: - Widget

struct VerseWidget: Widget {
    let kind = "VerseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VerseProvider()) { entry in
            VerseWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Shlok")
        .description("A Bhagavad Gita verse each day, on your home and lock screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge,
                            .accessoryRectangular, .accessoryInline])
    }
}
