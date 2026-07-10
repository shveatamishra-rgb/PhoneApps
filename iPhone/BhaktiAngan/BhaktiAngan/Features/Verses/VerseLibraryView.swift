import SwiftUI
import UIKit

/// Loads the bundled Bhagavad Gita verses (verses.json) and picks the daily shlok.
enum VerseCatalog {
    static let all: [Verse] = {
        guard let asset = NSDataAsset(name: "verses"),
              let decoded = try? JSONDecoder().decode([Verse].self, from: asset.data)
        else { return [] }
        return decoded
    }()

    static let free: [Verse] = all.filter { !$0.isPremium }

    /// Deterministic daily shlok. Free users draw from the free pool so the
    /// daily verse is always fully viewable (like the daily darshan); Pro draws
    /// from the whole library. Advances by day-of-year.
    static func verseOfDay(for date: Date = Date(), hasPro: Bool = false) -> Verse? {
        let pool = hasPro ? all : free
        guard !pool.isEmpty else { return nil }
        // Fixed gregorian calendar: Calendar.current can be Buddhist/Islamic/Japanese
        // on some devices, whose day-of-year differs, and the widget bridge computes
        // with gregorian. Keep the app card and the widget on the same verse.
        let day = Calendar(identifier: .gregorian).ordinality(of: .day, in: .year, for: date) ?? 1
        return pool[(day - 1) % pool.count]
    }

    static func verse(id: String) -> Verse? { all.first { $0.id == id } }
}

private let verseCream = Color(red: 0.97, green: 0.95, blue: 0.89)

// MARK: - Today's Shlok card (Home tab)

/// Compact card for the Today tab. Whole card links into the Verse library,
/// which features this same verse at the top with save/share.
struct ShlokCard: View {
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var loc: LocalizationManager

    private var verse: Verse? { VerseCatalog.verseOfDay(hasPro: store.hasPro) }

    var body: some View {
        if let verse {
            NavigationLink {
                VerseLibraryView(initial: verse)
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(loc.s("TODAY'S SHLOK", "आज का श्लोक"))
                            .font(.caption2.weight(.bold))
                            .tracking(1.1)
                            .foregroundStyle(AppTheme.marigold)
                        Spacer()
                        Text(verse.source(loc.lang))
                            .font(.caption2)
                            .foregroundStyle(AppTheme.muted)
                    }
                    Text(verse.sanskrit)
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(AppTheme.ink)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(verse.meaning(loc.lang))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)
                        .lineLimit(2)
                    HStack(spacing: 4) {
                        Text(loc.s("Verse Library", "श्लोक संग्रह"))
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.teal)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 18).fill(AppTheme.paper))
                .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(AppTheme.marigold.opacity(0.22)))
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Verse library

struct VerseLibraryView: View {
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var loc: LocalizationManager
    @EnvironmentObject private var appState: AppState

    /// The verse to feature at the top (today's shlok by default).
    var initial: Verse? = nil

    @State private var query = ""
    @State private var theme: String? = nil
    @State private var savedOnly = false
    @State private var showPaywall = false

    private var featured: Verse? { initial ?? VerseCatalog.verseOfDay(hasPro: store.hasPro) }

    private var filtered: [Verse] {
        VerseCatalog.all.filter { v in
            if savedOnly && !appState.isVerseSaved(v) { return false }
            if let theme, v.theme != theme { return false }
            if !query.isEmpty {
                let q = query.lowercased()
                let hay = [v.ref, v.meaningEN, v.meaningHI, v.translit,
                           v.themeLabel(.en), v.themeLabel(.hi)].joined(separator: " ").lowercased()
                if !hay.contains(q) { return false }
            }
            return true
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let featured, query.isEmpty, theme == nil, !savedOnly {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(loc.s("Today's Shlok", "आज का श्लोक"))
                            .font(.caption.weight(.bold)).tracking(1)
                            .foregroundStyle(AppTheme.marigold)
                        featuredCard(featured)
                    }
                    .padding(.horizontal, 16)
                }

                searchBar
                themeChips

                LazyVStack(spacing: 12) {
                    ForEach(filtered) { verse in
                        row(verse)
                    }
                    if filtered.isEmpty {
                        Text(loc.s("No verses match your search.",
                                   "आपकी खोज से कोई श्लोक मेल नहीं खाता।"))
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.muted)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
        .devotionalBackground()
        .navigationTitle(loc.s("Bhagavad Gita", "भगवद्गीता"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private func featuredCard(_ verse: Verse) -> some View {
        NavigationLink { VerseDetailView(verse: verse) } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text(verse.sanskrit)
                    .font(.system(.title3, design: .serif))
                    .foregroundStyle(.white)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verse.meaning(loc.lang))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
                Text(verse.source(loc.lang))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: [AppTheme.plum, AppTheme.teal],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            )
        }
        .buttonStyle(.plain)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(AppTheme.muted)
            TextField(loc.s("Search dharma, peace, action…",
                            "धर्म, शांति, कर्म खोजें…"), text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(AppTheme.muted)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.paper))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(AppTheme.muted.opacity(0.18)))
        .padding(.horizontal, 16)
    }

    private var themeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(label: loc.s("All", "सभी"), active: theme == nil && !savedOnly) {
                    theme = nil; savedOnly = false
                }
                ForEach(Verse.themeOrder, id: \.self) { t in
                    chip(label: Verse.themeLabels[t]?[loc.lang == .hi ? 1 : 0] ?? t,
                         active: theme == t) {
                        theme = (theme == t ? nil : t); savedOnly = false
                    }
                }
                chip(label: loc.s("Saved", "सहेजे"), active: savedOnly,
                     systemImage: "bookmark.fill") {
                    savedOnly.toggle(); if savedOnly { theme = nil }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func chip(label: String, active: Bool, systemImage: String? = nil,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage { Image(systemName: systemImage).font(.caption2) }
                Text(label).font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Capsule().fill(active ? AppTheme.teal : AppTheme.paper))
            .foregroundStyle(active ? .white : AppTheme.ink)
            .overlay(Capsule().strokeBorder(active ? .clear : AppTheme.muted.opacity(0.2)))
        }
        .buttonStyle(.plain)
        .contentShape(Capsule())
    }

    @ViewBuilder
    private func row(_ verse: Verse) -> some View {
        let locked = verse.isPremium && !store.hasPro
        Group {
            if locked {
                Button { showPaywall = true } label: {
                    VerseRow(verse: verse, locked: true, saved: false)
                }
            } else {
                NavigationLink { VerseDetailView(verse: verse) } label: {
                    VerseRow(verse: verse, locked: false, saved: appState.isVerseSaved(verse))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct VerseRow: View {
    @EnvironmentObject private var loc: LocalizationManager
    let verse: Verse
    let locked: Bool
    let saved: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(verse.source(loc.lang))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.teal)
                    Text(verse.themeLabel(loc.lang))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(Capsule().fill(AppTheme.muted.opacity(0.12)))
                    if saved {
                        Image(systemName: "bookmark.fill")
                            .font(.caption2).foregroundStyle(AppTheme.marigold)
                    }
                }
                Text(verse.sanskrit.replacingOccurrences(of: "\n", with: " "))
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                // Locked rows tease the meaning without revealing it: blurred so
                // search cannot be used to read Pro translations for free.
                Text(verse.meaning(loc.lang))
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(2)
                    .blur(radius: locked ? 4 : 0)
                    .accessibilityHidden(locked)
            }
            Spacer(minLength: 0)
            Image(systemName: locked ? "lock.fill" : "chevron.right")
                .font(.caption).foregroundStyle(locked ? AppTheme.marigold : AppTheme.muted)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.paper))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(AppTheme.muted.opacity(0.14)))
    }
}

// MARK: - Verse detail

struct VerseDetailView: View {
    @EnvironmentObject private var loc: LocalizationManager
    @EnvironmentObject private var appState: AppState
    let verse: Verse

    @State private var showShare = false
    @State private var shareImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(verse.source(loc.lang))
                    .font(.caption.weight(.bold)).tracking(1)
                    .foregroundStyle(AppTheme.marigold)

                Text(verse.sanskrit)
                    .font(.system(.title2, design: .serif))
                    .foregroundStyle(AppTheme.ink)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)

                Text(verse.translit)
                    .font(.subheadline.italic())
                    .foregroundStyle(AppTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                Text(verse.meaning(loc.lang))
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(AppTheme.ink)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 6) {
                    Text(loc.s("LIVE IT TODAY", "आज इसे जिएँ"))
                        .font(.caption2.weight(.bold)).tracking(1)
                        .foregroundStyle(AppTheme.teal)
                    Text(verse.live(loc.lang))
                        .font(.system(.callout, design: .serif))
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.teal.opacity(0.10)))

                HStack(spacing: 12) {
                    actionButton(
                        appState.isVerseSaved(verse) ? "bookmark.fill" : "bookmark",
                        label: appState.isVerseSaved(verse) ? loc.s("Saved", "सहेजा") : loc.s("Save", "सहेजें")
                    ) { appState.toggleVerseSaved(verse) }

                    actionButton("square.and.arrow.up", label: loc.s("Share", "साझा करें")) {
                        // Render on the next runloop tick so the tap animation is not
                        // blocked by ImageRenderer (it must stay on the main actor).
                        Task { @MainActor in
                            shareImage = VerseShareCard.render(verse: verse, lang: loc.lang)
                            showShare = true
                        }
                    }
                }
            }
            .padding(20)
        }
        .devotionalBackground()
        .navigationTitle(verse.ref)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShare) {
            if let shareImage {
                ActivityView(activityItems: [shareImage, verse.source(loc.lang)])
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func actionButton(_ icon: String, label: String,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.teal)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.teal.opacity(0.12)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Share-as-card

/// A branded, shareable image of a verse (WhatsApp / Instagram stories). Rendered
/// off-screen via ImageRenderer; no network, no user data.
struct VerseShareCard: View {
    let verse: Verse
    let lang: Lang

    // The Gita is Krishna's teaching to Arjuna, so one coherent scene backs every
    // verse: the Gita Updesh art if the collectible is cached, else a bundled
    // Krishna, else the plum->teal gradient. Never a per-verse image (arbitrary).
    private static let backgroundNames = ["r_krishna_gita", "day23_krishna", "day4_krishna", "krishna-govardhan"]
    private var background: UIImage? {
        for n in Self.backgroundNames { if let ui = DarshanImageStore.uiImage(named: n) { return ui } }
        return nil
    }

    private var gradientFallback: LinearGradient {
        LinearGradient(colors: [Color(red: 0.24, green: 0.08, blue: 0.16),
                                Color(red: 0.08, green: 0.30, blue: 0.30)],
                       startPoint: .top, endPoint: .bottom)
    }

    var body: some View {
        ZStack {
            // Backdrop: artwork (filled) or the gradient.
            if let bg = background {
                Image(uiImage: bg)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 540, height: 675)
                    .clipped()
            } else {
                gradientFallback
            }
            // Scrim for legibility: darker at top and bottom to anchor Om and brand,
            // still firm through the middle so the verse reads over any painting.
            LinearGradient(stops: [
                .init(color: .black.opacity(0.62), location: 0.0),
                .init(color: .black.opacity(0.42), location: 0.5),
                .init(color: .black.opacity(0.72), location: 1.0),
            ], startPoint: .top, endPoint: .bottom)

            VStack(spacing: 18) {
                Text("\u{0950}")   // Om
                    .font(.system(size: 40, design: .serif))
                    .foregroundStyle(.white.opacity(0.92))

                Text(verse.sanskrit)
                    .font(.system(size: 27, weight: .semibold, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .lineSpacing(8)

                Rectangle().fill(Color(red: 0.80, green: 0.64, blue: 0.29)).frame(width: 60, height: 2)

                Text(verse.meaning(lang))
                    .font(.system(size: 20, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.96))
                    .lineSpacing(4)

                Text(verse.source(lang))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(red: 0.90, green: 0.83, blue: 0.65))

                Spacer(minLength: 0)

                Text(lang == .hi ? "भक्ति आँगन" : "Bhakti Angan")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))
            }
            .padding(44)
            .shadow(color: .black.opacity(0.55), radius: 7, x: 0, y: 2)  // lifts text off the art

            // Inset gold hairline for a collectible frame.
            RoundedRectangle(cornerRadius: 0)
                .strokeBorder(Color(red: 0.80, green: 0.64, blue: 0.29).opacity(0.55), lineWidth: 1.5)
                .padding(14)
        }
        .frame(width: 540, height: 675, alignment: .center)
    }

    /// Renders the card to a shareable UIImage at 2x for crisp output.
    static func render(verse: Verse, lang: Lang) -> UIImage {
        let renderer = ImageRenderer(content: VerseShareCard(verse: verse, lang: lang))
        renderer.scale = 2
        return renderer.uiImage ?? UIImage()
    }
}
