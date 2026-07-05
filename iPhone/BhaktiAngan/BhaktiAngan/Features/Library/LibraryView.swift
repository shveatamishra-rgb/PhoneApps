import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var loc: LocalizationManager
    @State private var searchText = ""
    @State private var showPaywall = false

    /// Devotional ordering of the collections: Ganesha first (prathama pujya),
    /// then the great families. Only sections with items are shown.
    private let sectionOrder: [DeityCategory] = [.ganesha, .shiva, .vishnu, .krishna, .rama, .shakti]

    private let searchColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if searchText.isEmpty {
                    curatedShelves
                } else {
                    searchResults
                }
            }
            .devotionalBackground()
            .navigationTitle(loc.s("Darshan Library", "दर्शन संग्रह"))
            .searchable(text: $searchText, prompt: loc.s("Search Shiva, Krishna, Devi…", "शिव, कृष्ण, देवी खोजें…"))
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Curated, sectioned browse

    private var curatedShelves: some View {
        VStack(alignment: .leading, spacing: 26) {
            Text(loc.s("Collections of the gods, gathered for daily darshan.",
                       "देवताओं के संग्रह, दैनिक दर्शन के लिए।"))
                .font(.system(.subheadline, design: .serif))
                .italic()
                .foregroundStyle(AppTheme.muted)
                .padding(.horizontal, 16)
                .padding(.top, 2)

            ForEach(sectionsWithItems, id: \.0) { category, items in
                shelf(category: category, items: items)
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 32)
    }

    private var sectionsWithItems: [(DeityCategory, [DevotionalItem])] {
        let all = ContentCatalog.items
        return sectionOrder.compactMap { category in
            let items = all.filter { $0.category == category }
            return items.isEmpty ? nil : (category, items)
        }
    }

    private func shelf(category: DeityCategory, items: [DevotionalItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(loc.s("Collection", "संग्रह").uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(1.6)
                        .foregroundStyle(AppTheme.marigold)
                    Text(category.label(loc.lang))
                        .font(.system(.title2, design: .serif).weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                }
                Spacer()
                NavigationLink {
                    DeityGridView(category: category, items: items, showPaywall: $showPaywall)
                } label: {
                    HStack(spacing: 3) {
                        Text(loc.s("See all", "सभी देखें"))
                        Image(systemName: "chevron.right").font(.caption2.weight(.bold))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.teal)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(items) { item in
                        coverCard(item, width: 170, height: 236)
                    }
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Search results (flat grid)

    private var searchResults: some View {
        let results = ContentCatalog.items.filter { item in
            let q = searchText
            return item.deityEN.localizedCaseInsensitiveContains(q)
                || item.deityHI.localizedCaseInsensitiveContains(q)
                || item.mantraEN.localizedCaseInsensitiveContains(q)
                || item.mantraHI.localizedCaseInsensitiveContains(q)
                || item.category.label(.en).localizedCaseInsensitiveContains(q)
                || item.category.label(.hi).localizedCaseInsensitiveContains(q)
        }
        return Group {
            if results.isEmpty {
                ContentUnavailableView(
                    loc.s("No darshan found", "कोई दर्शन नहीं मिला"),
                    systemImage: "magnifyingglass",
                    description: Text(loc.s("Try a deity's name, like Shiva or Durga.",
                                            "किसी देवता का नाम आज़माएँ, जैसे शिव या दुर्गा।"))
                )
                .padding(.top, 60)
            } else {
                LazyVGrid(columns: searchColumns, spacing: 16) {
                    ForEach(results) { item in
                        coverCard(item, width: nil, height: 232)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
        }
    }

    // MARK: - Cover card (shared by shelves, search, and See-all grid)

    /// A single editorial cover. `width == nil` means fill the grid column.
    @ViewBuilder
    private func coverCard(_ item: DevotionalItem, width: CGFloat?, height: CGFloat) -> some View {
        let locked = item.isPremium && !store.hasPro
        Group {
            if locked {
                Button { showPaywall = true } label: {
                    LibraryCoverCard(item: item, width: width, height: height, locked: true)
                }
            } else {
                NavigationLink {
                    DarshanDetailView(item: item)
                } label: {
                    LibraryCoverCard(item: item, width: width, height: height, locked: false)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

/// The reusable editorial cover: image, bottom scrim, deity name in serif,
/// favorite heart, and a Pro lock veil when gated.
private struct LibraryCoverCard: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var loc: LocalizationManager
    let item: DevotionalItem
    let width: CGFloat?
    let height: CGFloat
    let locked: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.clear
                .frame(width: width, height: height)
                .frame(maxWidth: width == nil ? .infinity : nil)
                .overlay(alignment: .top) {
                    item.displayImage
                        .resizable()
                        .scaledToFill()
                }
                .clipped()

            LinearGradient(
                colors: [.black.opacity(0.72), .black.opacity(0.12), .clear],
                startPoint: .bottom, endPoint: .center
            )

            Text(item.deity(loc.lang))
                .font(.system(.headline, design: .serif).weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .shadow(radius: 4)
                .padding(.horizontal, 12)
                .padding(.bottom, 11)

            if appState.isFavorite(item) {
                Image(systemName: "heart.fill")
                    .font(.footnote)
                    .foregroundStyle(.white)
                    .padding(7)
                    .background(.black.opacity(0.38), in: Circle())
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }

            if locked {
                Color.black.opacity(0.42)
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill").font(.title3)
                    ProBadge()
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: width, height: height)
        .frame(maxWidth: width == nil ? .infinity : nil)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 6)
    }
}

/// "See all" for one collection: the full set as a two-column grid.
private struct DeityGridView: View {
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var loc: LocalizationManager
    let category: DeityCategory
    let items: [DevotionalItem]
    @Binding var showPaywall: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    let locked = item.isPremium && !store.hasPro
                    if locked {
                        Button { showPaywall = true } label: {
                            LibraryCoverCard(item: item, width: nil, height: 232, locked: true)
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink {
                            DarshanDetailView(item: item)
                        } label: {
                            LibraryCoverCard(item: item, width: nil, height: 232, locked: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
        .devotionalBackground()
        .navigationTitle(category.label(loc.lang))
        .navigationBarTitleDisplayMode(.inline)
    }
}
