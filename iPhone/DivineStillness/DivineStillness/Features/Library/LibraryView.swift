import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: StoreManager
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
            .navigationTitle("Darshan Library")
            .searchable(text: $searchText, prompt: "Search Shiva, Krishna, Devi...")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(DeityCategory.allCases) { category in
                    Button(category.rawValue) {
                        selectedCategory = category
                    }
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
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.hidden)
    }

    private var filteredItems: [DevotionalItem] {
        ContentCatalog.items.filter { item in
            let categoryMatches = selectedCategory == .all || item.category == selectedCategory
            let searchMatches = searchText.isEmpty
                || item.deity.localizedCaseInsensitiveContains(searchText)
                || item.mantra.localizedCaseInsensitiveContains(searchText)
            return categoryMatches && searchMatches
        }
    }

    private func libraryCard(_ item: DevotionalItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Image(item.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 245)
                    .frame(maxWidth: .infinity)
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

            Text(item.deity)
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
            Text(item.collection)
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
