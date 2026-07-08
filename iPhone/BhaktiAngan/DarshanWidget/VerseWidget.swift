import WidgetKit
import SwiftUI

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
        let infos = VerseStore.timeline()
        guard !infos.isEmpty else {
            completion(Timeline(entries: [currentEntry()], policy: .after(Date().addingTimeInterval(60))))
            return
        }
        let entries = infos.map { VerseEntry(date: $0.date, info: $0) }
        let reload = cal.date(byAdding: .day, value: 1, to: infos.last!.date) ?? Date().addingTimeInterval(86_400)
        completion(Timeline(entries: entries, policy: .after(reload)))
    }

    private func currentEntry() -> VerseEntry {
        let infos = VerseStore.timeline()
        let today = Calendar(identifier: .gregorian).startOfDay(for: Date())
        let info = infos.last(where: { $0.date <= today }) ?? infos.first
        return VerseEntry(date: Date(), info: info)
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
