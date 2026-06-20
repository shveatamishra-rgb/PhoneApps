import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var favorites: Set<String>
    @Published var hasCompletedOnboarding: Bool
    @Published var selectedTab: AppTab = .home
    @Published var selectedMantraID: String
    @Published var dailyJapaCount: Int
    @Published private(set) var currentStreak: Int
    @Published private(set) var bestStreak: Int

    private let defaults: UserDefaults
    private let favoritesKey = "favoriteImageNames"
    private let onboardingKey = "hasCompletedOnboarding"
    private let selectedMantraKey = "selectedMantraID"
    private let currentStreakKey = "currentStreak"
    private let bestStreakKey = "bestStreak"
    private let lastVisitDayKey = "lastVisitDay"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        favorites = Set(defaults.stringArray(forKey: favoritesKey) ?? [])
        selectedMantraID = defaults.string(forKey: selectedMantraKey)
            ?? "shiv"

        let arguments = ProcessInfo.processInfo.arguments
        hasCompletedOnboarding = defaults.bool(forKey: onboardingKey)
            || arguments.contains("--skip-onboarding")

        if arguments.contains("--tab-library") {
            selectedTab = .library
        } else if arguments.contains("--tab-japa") {
            selectedTab = .japa
        } else if arguments.contains("--tab-settings") {
            selectedTab = .settings
        }

        let japaKey = Self.japaKey(for: Date())
        dailyJapaCount = defaults.integer(forKey: japaKey)
        currentStreak = defaults.integer(forKey: currentStreakKey)
        bestStreak = defaults.integer(forKey: bestStreakKey)
    }

    func completeOnboarding(ishta: String) {
        selectedMantraID = ishta
        hasCompletedOnboarding = true
        defaults.set(true, forKey: onboardingKey)
        defaults.set(ishta, forKey: selectedMantraKey)
    }

    func toggleFavorite(_ item: DevotionalItem) {
        if favorites.contains(item.imageName) {
            favorites.remove(item.imageName)
        } else {
            favorites.insert(item.imageName)
        }
        defaults.set(Array(favorites), forKey: favoritesKey)
    }

    func isFavorite(_ item: DevotionalItem) -> Bool {
        favorites.contains(item.imageName)
    }

    func selectMantra(_ id: String) {
        selectedMantraID = id
        defaults.set(id, forKey: selectedMantraKey)
    }

    func incrementJapa() {
        dailyJapaCount += 1
        defaults.set(dailyJapaCount, forKey: Self.japaKey(for: Date()))
    }

    func resetJapa() {
        dailyJapaCount = 0
        defaults.set(0, forKey: Self.japaKey(for: Date()))
    }

    /// Records that the devotee opened the app today and keeps the daily
    /// darshan streak in sync. Returns the streak after recording so callers
    /// can celebrate a milestone. Calling more than once in a day is a no-op.
    @discardableResult
    func recordDailyVisit(now: Date = Date()) -> Int {
        let today = Self.dayString(for: now)
        let lastVisit = defaults.string(forKey: lastVisitDayKey)

        guard lastVisit != today else { return currentStreak }

        let calendar = Calendar(identifier: .gregorian)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)
            .map(Self.dayString(for:))

        if lastVisit == yesterday {
            currentStreak += 1
        } else {
            currentStreak = 1
        }

        bestStreak = max(bestStreak, currentStreak)
        defaults.set(today, forKey: lastVisitDayKey)
        defaults.set(currentStreak, forKey: currentStreakKey)
        defaults.set(bestStreak, forKey: bestStreakKey)
        return currentStreak
    }

    private static func japaKey(for date: Date) -> String {
        "japaCount.\(dayString(for: date))"
    }

    private static func dayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

enum AppTab: Hashable {
    case home
    case library
    case japa
    case settings
}
