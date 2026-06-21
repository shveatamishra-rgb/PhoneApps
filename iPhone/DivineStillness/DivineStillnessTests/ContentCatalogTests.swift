import XCTest
@testable import DivineStillness

final class ContentCatalogTests: XCTestCase {
    func testCatalogContainsSixtyUniqueImages() {
        XCTAssertEqual(ContentCatalog.items.count, 60)
        XCTAssertEqual(Set(ContentCatalog.items.map(\.imageName)).count, 60)
    }

    func testFreeTierContainsExactlyFirstTwelveImages() {
        let freeItems = ContentCatalog.items.filter { !$0.isPremium }
        XCTAssertEqual(freeItems.count, 12)
        XCTAssertEqual(freeItems.map(\.day), Array(1...12))
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
