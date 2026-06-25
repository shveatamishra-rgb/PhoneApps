import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var loc: LocalizationManager
    @State private var searchText = ""
    @State private var selectedCategory: DeityCategory = .all
    @State private var showPaywall = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    categoryPicker

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredItems) { item in
                            if item.isPremium && !store.hasPro {
                                Button {
                                    showPaywall = true
                                } label: {
                                    lockedCard(item)
                                }
                                .buttonStyle(.plain)
                            } else {
                                NavigationLink {
                                    DarshanDetailView(item: item)
                                } label: {
                                    libraryCard(item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 28)
            }
            .devotionalBackground()
            .navigationTitle(loc.s("Darshan Library", "दर्शन संग्रह"))
            .searchable(text: $searchText, prompt: loc.s("Search Shiva, Krishna, Devi…", "शिव, कृष्ण, देवी खोजें…"))
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(DeityCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(category.label(loc.lang))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(
                                selectedCategory == category ? .white : AppTheme.ink
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                selectedCategory == category ? AppTheme.vermilion : AppTheme.paper,
                                in: Capsule()
                            )
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
    }

    private var filteredItems: [DevotionalItem] {
        ContentCatalog.items.filter { item in
            let categoryMatches = selectedCategory == .all || item.category == selectedCategory
            let q = searchText
            let searchMatches = q.isEmpty
                || item.deityEN.localizedCaseInsensitiveContains(q)
                || item.deityHI.localizedCaseInsensitiveContains(q)
                || item.mantraEN.localizedCaseInsensitiveContains(q)
                || item.mantraHI.localizedCaseInsensitiveContains(q)
            return categoryMatches && searchMatches
        }
    }

    private func libraryCard(_ item: DevotionalItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 245)
                    .overlay(alignment: .top) {
                        Image(item.imageName)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if appState.isFavorite(item) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.white)
                        .padding(9)
                        .background(.black.opacity(0.38), in: Circle())
                        .padding(8)
                }
            }

            Text(item.deity(loc.lang))
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
            Text(item.collection(loc.lang))
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
        }
    }

    private func lockedCard(_ item: DevotionalItem) -> some View {
        ZStack {
            libraryCard(item)
            RoundedRectangle(cornerRadius: 12)
                .fill(.black.opacity(0.48))
                .frame(height: 245)
                .frame(maxHeight: .infinity, alignment: .top)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                        ProBadge()
                    }
                    .foregroundStyle(.white)
                }
        }
    }
}
