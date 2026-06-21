import XCTest
@testable import DivineStillness

final class ContentCatalogTests: XCTestCase {
    func testCatalogImagesAreUniqueAndExcludeRemoved() {
        XCTAssertEqual(
            ContentCatalog.items.count,
            Set(ContentCatalog.items.map(\.imageName)).count,
            "image names must be unique"
        )
        for removed in ContentCatalog.removedImageNames {
            XCTAssertFalse(
                ContentCatalog.items.contains { $0.imageName == removed },
                "\(removed) should be excluded from the catalog"
            )
        }
    }

    func testFreeTierIsLeadingDarshansAndExcludesRemoved() {
        let freeDays = ContentCatalog.items.filter { !$0.isPremium }.map(\.day)
        // Free = days 1–12 by rule, minus any pulled image (day 12 venkateshwar).
        XCTAssertTrue(freeDays.allSatisfy { $0 <= 12 })
        XCTAssertFalse(freeDays.contains(12), "a pulled image must not be free")
        XCTAssertEqual(freeDays, Array(1...11))
    }

    func testCategoryLabelReplacesArbitraryCollections() {
        // The "collection" shown to users must be the meaningful deity category,
        // never the old arbitrary day-bucket labels.
        let stale = ["Morning Darshan", "Aarti Glow", "Meditation Darshan", "Temple Blessing"]
        for item in ContentCatalog.items {
            XCTAssertFalse(stale.contains(item.collection), "stale collection label leaked")
            XCTAssertEqual(item.collection, item.category.rawValue)
        }
    }

    func testEveryItemHasDevotionalCopy() {
        for item in ContentCatalog.items {
            XCTAssertFalse(item.deity.isEmpty)
            XCTAssertFalse(item.mantra.isEmpty)
            XCTAssertFalse(item.meaning.isEmpty)
            XCTAssertFalse(item.blessing.isEmpty)
        }
    }

    func testDailySelectionIsDeterministic() {
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: DateComponents(
            year: 2026,
            month: 6,
            day: 20
        ))!

        XCTAssertEqual(
            ContentCatalog.dailyItem(for: date),
            ContentCatalog.dailyItem(for: date)
        )
    }

    func testFreeMantrasAreShivaGaneshaAndKrishna() {
        let freeIDs = Set(
            ContentCatalog.mantraChoices
                .filter { !$0.isPremium }
                .map(\.id)
        )
        XCTAssertEqual(freeIDs, Set(["shiv", "ganesh", "krishna"]))
    }
}

@MainActor
final class StreakTests: XCTestCase {
    private var suiteName = ""

    override func setUp() {
        super.setUp()
        suiteName = "DivineStillnessTests.\(UUID().uuidString)"
    }

    private func makeState() -> AppState {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return AppState(defaults: defaults)
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    func testFirstVisitStartsStreakAtOne() {
        let state = makeState()
        XCTAssertEqual(state.recordDailyVisit(now: day(2026, 6, 20)), 1)
        XCTAssertEqual(state.bestStreak, 1)
    }

    func testConsecutiveDaysIncrementStreak() {
        let state = makeState()
        XCTAssertEqual(state.recordDailyVisit(now: day(2026, 6, 20)), 1)
        XCTAssertEqual(state.recordDailyVisit(now: day(2026, 6, 21)), 2)
        XCTAssertEqual(state.recordDailyVisit(now: day(2026, 6, 22)), 3)
        XCTAssertEqual(state.bestStreak, 3)
    }

    func testSameDayVisitDoesNotDoubleCount() {
        let state = makeState()
        XCTAssertEqual(state.recordDailyVisit(now: day(2026, 6, 20)), 1)
        XCTAssertEqual(state.recordDailyVisit(now: day(2026, 6, 20)), 1)
    }

    func testGapResetsStreakButKeepsBest() {
        let state = makeState()
        _ = state.recordDailyVisit(now: day(2026, 6, 20))
        _ = state.recordDailyVisit(now: day(2026, 6, 21))
        XCTAssertEqual(state.recordDailyVisit(now: day(2026, 6, 25)), 1)
        XCTAssertEqual(state.bestStreak, 2)
    }

    func testJapaCountResetsWhenDayRolls() {
        let state = makeState()
        state.incrementJapa()
        state.incrementJapa()
        XCTAssertEqual(state.dailyJapaCount, 2)

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        state.refreshJapaForToday(now: tomorrow)
        XCTAssertEqual(state.dailyJapaCount, 0, "Counter should reset on a new day")
    }

    func testJapaCountHoldsWithinSameDay() {
        let state = makeState()
        state.incrementJapa()
        state.refreshJapaForToday(now: Date())
        XCTAssertEqual(state.dailyJapaCount, 1, "Same-day refresh must not reset")
    }
}
