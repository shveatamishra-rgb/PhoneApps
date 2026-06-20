import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: StoreManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var showShare = false
    @State private var toast: String?
    @State private var showPaywall = false
    @State private var today = ContentCatalog.dailyItem()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    header
                    hero
                    practice
                    explore
                    proInvitation
                }
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .devotionalBackground()
            .navigationBarHidden(true)
            .onAppear {
                today = ContentCatalog.dailyItem()
                appState.recordDailyVisit()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    today = ContentCatalog.dailyItem()
                    appState.recordDailyVisit()
                }
            }
            .overlay(alignment: .bottom) {
                if let toast {
                    ToastView(message: toast)
                        .padding(.bottom, 18)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .sheet(isPresented: $showShare) {
                if let image = UIImage(named: today.imageName) {
                    ActivityView(activityItems: [image, today.shareText])
                        .presentationDetents([.medium, .large])
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(greeting)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.vermilion)
                    if appState.currentStreak > 1 {
                        streakChip
                    }
                }
                Text("Today's Darshan")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppTheme.ink)
            }
            Spacer()
            if store.hasPro {
                ProBadge()
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Image(systemName: "sparkles")
                        .font(.headline)
                        .foregroundStyle(AppTheme.vermilion)
                        .frame(width: 42, height: 42)
                        .background(AppTheme.paper, in: Circle())
                }
                .accessibilityLabel("Open Divine Stillness Pro")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
    }

    private var streakChip: some View {
        Label("\(appState.currentStreak) day streak", systemImage: "flame.fill")
            .font(.caption2.weight(.bold))
            .foregroundStyle(AppTheme.marigold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(AppTheme.marigold.opacity(0.14), in: Capsule())
            .accessibilityLabel("\(appState.currentStreak) day darshan streak")
    }

    private var hero: some View {
        ZStack(alignment: .bottom) {
            Image(today.imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 500)
                .frame(maxWidth: .infinity)
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.82)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 14) {
                Text(today.collection.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(AppTheme.marigold)
                Text(today.deity)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                Text(today.mantra)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.94))

                HStack(spacing: 10) {
                    heroButton(
                        appState.isFavorite(today) ? "heart.fill" : "heart",
                        label: "Favorite"
                    ) {
                        appState.toggleFavorite(today)
                        showToast(appState.isFavorite(today) ? "Added to favorites" : "Removed")
                    }
                    heroButton("square.and.arrow.up", label: "Share") {
                        showShare = true
                    }
                    heroButton("arrow.down.to.line", label: "Save") {
                        saveToday()
                    }
                }
            }
            .padding(20)
        }
        .frame(height: 500)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 16)
        .shadow(color: AppTheme.plum.opacity(0.18), radius: 18, y: 8)
    }

    private var practice: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(
                title: "One-minute practice",
                subtitle: "Read slowly, breathe once, and repeat the mantra."
            )

            Text(today.meaning)
                .font(.body)
                .foregroundStyle(AppTheme.ink)

            Divider()

            Text(today.blessing)
                .font(.body.italic())
                .foregroundStyle(AppTheme.muted)

            NavigationLink {
                JapaPracticeView(choice: MantraChoice(
                    id: today.id,
                    deity: today.deity,
                    mantra: today.mantra,
                    meaning: today.meaning,
                    isPremium: false
                ))
            } label: {
                Label("Begin Japa", systemImage: "circle.grid.3x3.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .foregroundStyle(.white)
                    .background(AppTheme.teal, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(18)
        .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }

    private var explore: some View {
        VStack(spacing: 14) {
            SectionHeading(
                title: "Explore darshan",
                subtitle: "Your first 12 images are always free."
            )
            .padding(.horizontal, 20)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(ContentCatalog.items.prefix(12)) { item in
                        NavigationLink {
                            DarshanDetailView(item: item)
                        } label: {
                            VStack(alignment: .leading, spacing: 7) {
                                Image(item.imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 142, height: 205)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                Text(item.deity)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.ink)
                                    .lineLimit(1)
                            }
                            .frame(width: 142, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
        }
    }

    @ViewBuilder
    private var proInvitation: some View {
        if !store.hasPro {
            Button {
                showPaywall = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.marigold)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Unlock all 60 darshans")
                            .font(.headline)
                        Text("Full library, every mantra, and unlimited wallpaper saves.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.76))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(.white)
                .padding(18)
                .background(AppTheme.plum, in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)
        }
    }

    private func heroButton(
        _ icon: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.white.opacity(0.16), in: Capsule())
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    private func saveToday() {
        Task {
            do {
                try await WallpaperLibrary.save(imageNamed: today.imageName)
                showToast("Wallpaper saved to Photos")
            } catch {
                showToast(error.localizedDescription)
            }
        }
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { toast = nil }
        }
    }
}
