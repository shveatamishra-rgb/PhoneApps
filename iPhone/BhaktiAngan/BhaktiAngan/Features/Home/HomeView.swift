import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var loc: LocalizationManager
    @AppStorage("appearancePreference") private var appearanceRaw = AppearanceMode.system.rawValue
    @Environment(\.scenePhase) private var scenePhase
    @State private var showShare = false
    @State private var toast: String?
    @State private var showPaywall = false
    @State private var today = ContentCatalog.dailyItem()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 22) {
                    header
                    PanchangCard()
                    darshanHeading
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
                today = ContentCatalog.dailyItem(hasPro: store.hasPro)
                appState.recordDailyVisit()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    today = ContentCatalog.dailyItem(hasPro: store.hasPro)
                    appState.recordDailyVisit()
                }
            }
            .onChange(of: store.hasPro) { _, _ in
                today = ContentCatalog.dailyItem(hasPro: store.hasPro)
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
                    ActivityView(activityItems: [image, today.shareText(loc.lang)])
                        .presentationDetents([.medium, .large])
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Header (greeting + live device time + quick toggles)

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text(greeting)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.vermilion)
                TimelineView(.periodic(from: .now, by: 30)) { context in
                    Text(dateTimeString(context.date))
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.ink)
                }
                if appState.currentStreak > 1 { streakChip }
            }
            Spacer()
            HStack(spacing: 8) {
                languageMenu
                themeMenu
                proControl
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private var languageMenu: some View {
        Menu {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    loc.preference = language
                } label: {
                    if loc.preference == language {
                        Label(language.label, systemImage: "checkmark")
                    } else {
                        Text(language.label)
                    }
                }
            }
        } label: {
            Text(loc.isHindi ? "हिं" : "EN")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.vermilion)
                .frame(width: 42, height: 42)
                .background(AppTheme.paper, in: Circle())
        }
        .accessibilityLabel(loc.s("Language", "भाषा"))
    }

    private var themeMenu: some View {
        Menu {
            ForEach(AppearanceMode.allCases) { mode in
                Button {
                    appearanceRaw = mode.rawValue
                } label: {
                    if appearanceRaw == mode.rawValue {
                        Label(appearanceLabel(mode), systemImage: "checkmark")
                    } else {
                        Text(appearanceLabel(mode))
                    }
                }
            }
        } label: {
            Image(systemName: themeIcon)
                .font(.headline)
                .foregroundStyle(AppTheme.vermilion)
                .frame(width: 42, height: 42)
                .background(AppTheme.paper, in: Circle())
        }
        .accessibilityLabel(loc.s("Theme", "थीम"))
    }

    @ViewBuilder private var proControl: some View {
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
            .accessibilityLabel(loc.s("Open Bhakti Angan Pro", "भक्ति आँगन प्रो खोलें"))
        }
    }

    private var themeIcon: String {
        switch AppearanceMode(rawValue: appearanceRaw) ?? .system {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    private func appearanceLabel(_ mode: AppearanceMode) -> String {
        switch mode {
        case .system: return loc.s("System", "सिस्टम")
        case .light: return loc.s("Light", "उजाला")
        case .dark: return loc.s("Dark", "अँधेरा")
        }
    }

    private var streakChip: some View {
        Label(
            loc.s("\(appState.currentStreak) day streak", "\(appState.currentStreak) दिन की श्रृंखला"),
            systemImage: "flame.fill"
        )
        .font(.caption2.weight(.bold))
        .foregroundStyle(AppTheme.marigold)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(AppTheme.marigold.opacity(0.14), in: Capsule())
        .accessibilityLabel(loc.s("\(appState.currentStreak) day darshan streak", "\(appState.currentStreak) दिन की दर्शन श्रृंखला"))
    }

    private var darshanHeading: some View {
        Text(loc.s("Today's Darshan", "आज का दर्शन"))
            .font(.largeTitle.bold())
            .foregroundStyle(AppTheme.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
    }

    private var hero: some View {
        ZStack(alignment: .bottom) {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 500)
                .overlay(alignment: .top) {
                    Image(today.imageName)
                        .resizable()
                        .scaledToFill()
                }
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.82)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 14) {
                Text(today.collection(loc.lang).uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(AppTheme.marigold)
                Text(today.deity(loc.lang))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                Text(today.mantra(loc.lang))
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.94))

                HStack(spacing: 10) {
                    heroButton(
                        appState.isFavorite(today) ? "heart.fill" : "heart",
                        label: loc.s("Favorite", "पसंद")
                    ) {
                        appState.toggleFavorite(today)
                        showToast(appState.isFavorite(today)
                            ? loc.s("Added to favorites", "पसंद में जोड़ा गया")
                            : loc.s("Removed", "हटाया गया"))
                    }
                    heroButton("square.and.arrow.up", label: loc.s("Share", "साझा करें")) {
                        showShare = true
                    }
                    heroButton("arrow.down.to.line", label: loc.s("Save", "सहेजें")) {
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
                title: loc.s("One-minute practice", "एक मिनट का अभ्यास"),
                subtitle: loc.s("Read slowly, breathe once, and repeat the mantra.", "धीरे से पढ़ें, एक साँस लें, और मंत्र दोहराएँ।")
            )

            Text(today.meaning(loc.lang))
                .font(.body)
                .foregroundStyle(AppTheme.ink)

            Divider()

            Text(today.blessing(loc.lang))
                .font(.body.italic())
                .foregroundStyle(AppTheme.muted)

            NavigationLink {
                JapaPracticeView(choice: MantraChoice(
                    id: today.id,
                    deityEN: today.deityEN,
                    deityHI: today.deityHI,
                    mantraEN: today.mantraEN,
                    mantraHI: today.mantraHI,
                    meaningEN: today.meaningEN,
                    meaningHI: today.meaningHI,
                    isPremium: false
                ))
            } label: {
                Label(loc.s("Begin Japa", "जप आरंभ करें"), systemImage: "circle.grid.3x3.fill")
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
                title: loc.s("Explore darshan", "दर्शन देखें"),
                subtitle: store.hasPro
                    ? loc.s("Your complete darshan library.", "आपका संपूर्ण दर्शन संग्रह।")
                    : loc.s(
                        "Your first \(ContentCatalog.freeDarshanCount) images are always free.",
                        "पहले \(ContentCatalog.freeDarshanCount) दर्शन हमेशा निःशुल्क हैं।"
                    )
            )
            .padding(.horizontal, 20)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(store.hasPro ? ContentCatalog.items : Array(ContentCatalog.items.prefix(ContentCatalog.freeDarshanCount))) { item in
                        NavigationLink {
                            DarshanDetailView(item: item)
                        } label: {
                            VStack(alignment: .leading, spacing: 7) {
                                Color.clear
                                    .frame(width: 142, height: 205)
                                    .overlay(alignment: .top) {
                                        Image(item.imageName)
                                            .resizable()
                                            .scaledToFill()
                                    }
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                Text(item.deity(loc.lang))
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
                        Text(loc.s("Unlock the full darshan library", "संपूर्ण दर्शन संग्रह अनलॉक करें"))
                            .font(.headline)
                        Text(loc.s("Full library, every mantra, and unlimited wallpaper saves.", "पूरा संग्रह, हर मंत्र, और असीमित वॉलपेपर सहेजें।"))
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
        if hour < 12 { return loc.s("Good morning", "सुप्रभात") }
        if hour < 17 { return loc.s("Good afternoon", "नमस्कार") }
        return loc.s("Good evening", "शुभ संध्या")
    }

    private func dateTimeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: loc.lang == .hi ? "hi_IN" : "en_US")
        f.setLocalizedDateFormatFromTemplate("EEEdMMMhmma")
        return f.string(from: date)
    }

    private func saveToday() {
        Task {
            do {
                try await WallpaperLibrary.save(imageNamed: today.imageName)
                showToast(loc.s("Wallpaper saved to Photos", "वॉलपेपर फ़ोटो में सहेजा गया"))
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
