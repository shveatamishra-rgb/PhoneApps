import WidgetKit
import SwiftUI

// Shares the App Group with the app's ChoghadiyaBridge.
private let choghAppGroup = "group.in.bhaktiangan.app"

private enum CBrand {
    static let good    = Color(red: 0.16, green: 0.52, blue: 0.36)
    static let bad     = Color(red: 0.72, green: 0.22, blue: 0.16)
    static let neutral = Color(red: 0.78, green: 0.60, blue: 0.24)
    static func color(_ q: String) -> Color {
        switch q { case "good": return good; case "bad": return bad; default: return neutral }
    }
    static func label(_ q: String) -> String {
        switch q { case "good": return "Auspicious"; case "bad": return "Inauspicious"; default: return "Neutral" }
    }
}

// MARK: - Shared data (written by the app's ChoghadiyaBridge)

struct ChoghPeriod {
    let nameEN: String, nameHI: String
    let start: Date, end: Date
    let quality: String
    let isDay: Bool
}

struct ChoghData {
    let cityEN: String, cityHI: String, tz: String
    let periods: [ChoghPeriod]
}

enum ChoghStore {
    static var container: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: choghAppGroup)
    }
    static func load() -> ChoghData {
        guard let dir = container,
              let data = try? Data(contentsOf: dir.appendingPathComponent("choghadiya.json")),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ChoghData(cityEN: "", cityHI: "", tz: TimeZone.current.identifier, periods: [])
        }
        let rows = (obj["periods"] as? [[String: Any]]) ?? []
        let periods = rows.compactMap { r -> ChoghPeriod? in
            guard let s = r["start"] as? Double, let e = r["end"] as? Double else { return nil }
            return ChoghPeriod(nameEN: r["nameEN"] as? String ?? "",
                               nameHI: r["nameHI"] as? String ?? "",
                               start: Date(timeIntervalSince1970: s),
                               end: Date(timeIntervalSince1970: e),
                               quality: r["quality"] as? String ?? "neutral",
                               isDay: r["isDay"] as? Bool ?? true)
        }.sorted { $0.start < $1.start }
        return ChoghData(cityEN: obj["cityEN"] as? String ?? "",
                         cityHI: obj["cityHI"] as? String ?? "",
                         tz: obj["tz"] as? String ?? TimeZone.current.identifier,
                         periods: periods)
    }
}

// MARK: - Timeline

struct ChoghEntry: TimelineEntry {
    let date: Date
    let current: ChoghPeriod?
    let next: ChoghPeriod?
    let city: String
    let tz: String
    let hasData: Bool
}

struct ChoghProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChoghEntry { makeEntry(at: Date(), ChoghStore.load()) }

    func getSnapshot(in context: Context, completion: @escaping (ChoghEntry) -> Void) {
        completion(makeEntry(at: Date(), ChoghStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChoghEntry>) -> Void) {
        let data = ChoghStore.load()
        guard !data.periods.isEmpty else {
            let e = ChoghEntry(date: Date(), current: nil, next: nil, city: "", tz: data.tz, hasData: false)
            completion(Timeline(entries: [e], policy: .after(Date().addingTimeInterval(1800))))
            return
        }
        let now = Date()
        var entries: [ChoghEntry] = [makeEntry(at: now, data)]
        for p in data.periods where p.start > now {
            entries.append(makeEntry(at: p.start, data))
        }
        let reload = data.periods.last?.end ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: entries, policy: .after(reload)))
    }

    private func makeEntry(at date: Date, _ d: ChoghData) -> ChoghEntry {
        guard !d.periods.isEmpty else {
            return ChoghEntry(date: date, current: nil, next: nil, city: "", tz: d.tz, hasData: false)
        }
        // Only a period that actually covers `date` may render as current. If the
        // data has a gap (stale file), show the upcoming period in the NEXT slot
        // only; never present a future muhurat as the running one.
        let cur = d.periods.first { date >= $0.start && date < $0.end }
        let nxt = d.periods.first { $0.start > (cur?.start ?? date) }
        return ChoghEntry(date: date, current: cur, next: nxt, city: d.cityEN, tz: d.tz, hasData: cur != nil || nxt != nil)
    }
}

// MARK: - Views

struct ChoghWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ChoghEntry

    private var name: String { entry.current?.nameEN ?? entry.next?.nameEN ?? "" }
    private var quality: String { (entry.current ?? entry.next)?.quality ?? "neutral" }
    // "until <end>" while a period runs; "starts <time>" when only a future one exists.
    private var timeLine: String? {
        if let end = entry.current?.end { return "until \(clock(end))" }
        if let start = entry.next?.start { return "starts \(clock(start))" }
        return nil
    }

    private func clock(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: entry.tz) ?? .current
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    var body: some View {
        content.widgetURL(URL(string: "bhaktiangan://panchang"))
    }

    @ViewBuilder private var content: some View {
        if !entry.hasData {
            noData
        } else {
            switch family {
            case .systemMedium: medium
            case .accessoryRectangular: rectangular
            case .accessoryInline: inline
            default: small
            }
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("CHOGHADIYA").font(.system(size: 9, weight: .bold)).tracking(1.1).foregroundStyle(.white.opacity(0.85))
            Spacer(minLength: 0)
            Text(name).font(.system(size: 25, weight: .bold, design: .serif))
                .foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.6)
            Text(CBrand.label(quality)).font(.caption2.weight(.semibold)).foregroundStyle(.white.opacity(0.9))
            if let t = timeLine {
                Text(t).font(.caption2).foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { CBrand.color(quality) }
    }

    private var medium: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.city.isEmpty ? "CHOGHADIYA" : "CHOGHADIYA · \(entry.city.uppercased())")
                    .font(.system(size: 9, weight: .bold)).tracking(0.8)
                    .foregroundStyle(.white.opacity(0.85)).lineLimit(1)
                Spacer(minLength: 0)
                Text(name).font(.system(size: 27, weight: .bold, design: .serif))
                    .foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.6)
                Text(CBrand.label(quality)).font(.caption.weight(.semibold)).foregroundStyle(.white.opacity(0.92))
                if let t = timeLine {
                    Text(t).font(.caption2).foregroundStyle(.white.opacity(0.85))
                }
            }
            Spacer(minLength: 8)
            if entry.current != nil, let nxt = entry.next {
                VStack(alignment: .leading, spacing: 3) {
                    Text("NEXT").font(.system(size: 8, weight: .bold)).tracking(1).foregroundStyle(.white.opacity(0.7))
                    Text(nxt.nameEN).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                    Text(CBrand.label(nxt.quality)).font(.system(size: 10)).foregroundStyle(.white.opacity(0.8))
                    Text(clock(nxt.start)).font(.system(size: 11, weight: .medium)).foregroundStyle(.white.opacity(0.85))
                }
                .frame(width: 100, alignment: .leading)
                .padding(.leading, 12)
                .overlay(alignment: .leading) { Rectangle().fill(.white.opacity(0.25)).frame(width: 1) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { CBrand.color(quality) }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(name.isEmpty ? "Choghadiya" : "Choghadiya · \(name)").font(.headline).lineLimit(1)
            Text(CBrand.label(quality)).font(.caption)
            if let t = timeLine { Text(t).font(.caption2) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) { Color.clear }
    }

    @ViewBuilder private var inline: some View {
        if entry.current != nil {
            Text("\(name) · \(CBrand.label(quality))")
        } else if let nxt = entry.next {
            Text("\(nxt.nameEN) \(clock(nxt.start))")
        } else {
            Text("Choghadiya")
        }
    }

    private var noData: some View {
        VStack(spacing: 5) {
            Image(systemName: "location.slash").font(.footnote)
            Text("Set your city in Bhakti Angan").font(.caption2).multilineTextAlignment(.center)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) { CBrand.neutral }
    }
}

// MARK: - Widget

struct ChoghadiyaWidget: Widget {
    let kind = "ChoghadiyaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChoghProvider()) { entry in
            ChoghWidgetView(entry: entry)
        }
        .configurationDisplayName("Choghadiya")
        .description("The current muhurat and what comes next, for your city.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}
