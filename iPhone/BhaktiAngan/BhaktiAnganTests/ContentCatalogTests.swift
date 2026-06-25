import XCTest
@testable import BhaktiAngan

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
        let free = ContentCatalog.items.filter { !$0.isPremium }
        // Exactly the advertised number of leading darshans are free, and they are
        // precisely the tiles shown in Home's "always free" Explore strip — so a
        // pulled image can never leave a locked tile under that header.
        XCTAssertEqual(free.count, ContentCatalog.freeDarshanCount)
        XCTAssertEqual(
            free.map(\.id),
            ContentCatalog.items.prefix(ContentCatalog.freeDarshanCount).map(\.id)
        )
        for removed in ContentCatalog.removedImageNames {
            XCTAssertFalse(free.contains { $0.imageName == removed })
        }
    }

    func testCategoryLabelReplacesArbitraryCollections() {
        // The "collection" shown to users must be the meaningful deity category,
        // never the old arbitrary day-bucket labels.
        let stale = ["Morning Darshan", "Aarti Glow", "Meditation Darshan", "Temple Blessing"]
        for item in ContentCatalog.items {
            XCTAssertFalse(stale.contains(item.collection(.en)), "stale collection label leaked")
            XCTAssertEqual(item.collection(.en), item.category.rawValue)
            XCTAssertFalse(item.collection(.hi).isEmpty, "category needs a Hindi label")
        }
    }

    func testEveryItemHasDevotionalCopyInBothLanguages() {
        for item in ContentCatalog.items {
            for lang in [Lang.en, .hi] {
                XCTAssertFalse(item.deity(lang).isEmpty, "\(item.imageName) missing deity (\(lang))")
                XCTAssertFalse(item.mantra(lang).isEmpty, "\(item.imageName) missing mantra (\(lang))")
                XCTAssertFalse(item.meaning(lang).isEmpty, "\(item.imageName) missing meaning (\(lang))")
                XCTAssertFalse(item.blessing(lang).isEmpty, "\(item.imageName) missing blessing (\(lang))")
            }
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

    func testDailyDarshanIsWeekdayAligned() {
        // Build at local noon so the weekday matches dailyItem's Calendar.current
        // regardless of the test machine's timezone.
        let cal = Calendar.current
        // 22 Jun 2026 = Monday, 23 = Tuesday, 24 = Wednesday, 25 = Thursday.
        func item(_ d: Int, pro: Bool) -> String {
            ContentCatalog.dailyItem(for: cal.date(from: DateComponents(year: 2026, month: 6, day: d, hour: 12))!, hasPro: pro).imageName
        }
        XCTAssertTrue(item(22, pro: false).contains("shiv"), "Monday should be Shiva")
        XCTAssertTrue(item(23, pro: true).contains("hanuman"), "Tuesday should be Hanuman")
        XCTAssertTrue(item(24, pro: false).contains("ganesh"), "Wednesday should be Ganesha")
        XCTAssertTrue(item(25, pro: true).contains("vishnu"), "Thursday should be Vishnu")
    }

    func testFreeDailyDarshanNeverShowsProArt() {
        // Over a full year, the free daily darshan must never be a Pro image.
        var cal = Calendar(identifier: .gregorian)
        let start = cal.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        for offset in 0..<365 {
            let d = cal.date(byAdding: .day, value: offset, to: start)!
            XCTAssertFalse(ContentCatalog.dailyItem(for: d, hasPro: false).isPremium,
                           "Free daily darshan leaked a Pro image on day \(offset)")
        }
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
        suiteName = "BhaktiAnganTests.\(UUID().uuidString)"
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

final class PanchangTests: XCTestCase {
    // A fixed reference city so the Panchang tests stay independent of the bundled list.
    private let delhi = City(id: "new-delhi", nameEN: "New Delhi", nameHI: "नई दिल्ली",
                             regionEN: "Delhi, India", latitude: 28.6139, longitude: 77.2090,
                             timeZoneID: "Asia/Kolkata")

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        return cal.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
    }

    func testComputesAndSunriseBeforeSunset() {
        let p = PanchangCalculator.compute(for: date(2026, 6, 23), city: delhi)
        XCTAssertNotNil(p)
        if let p { XCTAssertLessThan(p.sunrise, p.sunset) }
    }

    func testDelhiJuneSunriseInPlausibleRange() {
        let p = PanchangCalculator.compute(for: date(2026, 6, 23), city: delhi)!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        let hour = cal.component(.hour, from: p.sunrise)
        XCTAssertTrue((5...6).contains(hour), "Delhi late-June sunrise should be ~05:25 IST, got hour \(hour)")
    }

    func testChoghadiyaCoverageAndContiguity() {
        let p = PanchangCalculator.compute(for: date(2026, 6, 23), city: delhi)!
        XCTAssertEqual(p.dayChoghadiya.count, 8)
        XCTAssertEqual(p.nightChoghadiya.count, 8)
        XCTAssertEqual(p.dayChoghadiya.first?.start, p.sunrise)
        XCTAssertEqual(p.dayChoghadiya.last?.end, p.sunset)
        for i in 1..<p.dayChoghadiya.count {
            XCTAssertEqual(p.dayChoghadiya[i].start, p.dayChoghadiya[i - 1].end)
        }
    }

    func testCurrentChoghadiyaResolvesToFirstAfterSunrise() {
        let p = PanchangCalculator.compute(for: date(2026, 6, 23), city: delhi)!
        let justAfterSunrise = p.sunrise.addingTimeInterval(60)
        XCTAssertEqual(p.currentChoghadiya(at: justAfterSunrise)?.id, p.dayChoghadiya.first?.id)
    }

    func testElementsHaveBilingualNames() {
        let p = PanchangCalculator.compute(for: date(2026, 6, 23), city: delhi)!
        for element in [p.tithi, p.nakshatra, p.yoga, p.karana] {
            XCTAssertFalse(element.name(.en).isEmpty)
            XCTAssertFalse(element.name(.hi).isEmpty)
        }
    }

    func testChoghadiyaSequenceMatchesCanonicalForMonday() {
        // 22 June 2026 is a Monday. Day advances +1, night advances -2 — verified
        // against DrikPanchang (e.g. the night slot at ~03:12 is Amrit, not Udveg).
        let p = PanchangCalculator.compute(for: date(2026, 6, 22), city: delhi)!
        XCTAssertEqual(p.dayChoghadiya.map { $0.nameEN },
                       ["Amrit", "Kaal", "Shubh", "Rog", "Udveg", "Char", "Labh", "Amrit"])
        XCTAssertEqual(p.nightChoghadiya.map { $0.nameEN },
                       ["Char", "Rog", "Kaal", "Labh", "Udveg", "Shubh", "Amrit", "Char"])
    }

    func testRahuKaalWithinDaytime() {
        let p = PanchangCalculator.compute(for: date(2026, 6, 23), city: delhi)!
        XCTAssertGreaterThanOrEqual(p.rahu.start, p.sunrise)
        XCTAssertLessThanOrEqual(p.rahu.end, p.sunset.addingTimeInterval(1))
    }

    func testVelaAndAbhijitWindows() {
        // 22 June 2026 is a Monday; Kala Vela = 2nd daytime eighth (Saturn-ruled),
        // Vara Vela = last (8th) eighth — both verified against DrikPanchang.
        let p = PanchangCalculator.compute(for: date(2026, 6, 22), city: delhi)!
        let eighth = p.sunset.timeIntervalSince(p.sunrise) / 8
        XCTAssertEqual(p.kalaVela.start.timeIntervalSince(p.sunrise), eighth, accuracy: 1)
        XCTAssertEqual(p.varaVela.start.timeIntervalSince(p.sunrise), 7 * eighth, accuracy: 1)
        XCTAssertEqual(p.varaVela.end.timeIntervalSince(p.sunset), 0, accuracy: 1)
        // Kala Ratri lies in the night (sunset → next sunrise).
        XCTAssertGreaterThanOrEqual(p.kalaRatri.start, p.sunset)
        // Abhijit Muhurat straddles solar midday.
        let midday = p.sunrise.addingTimeInterval(p.sunset.timeIntervalSince(p.sunrise) / 2)
        XCTAssertLessThanOrEqual(p.abhijit.start, midday)
        XCTAssertGreaterThanOrEqual(p.abhijit.end, midday)
    }

    func testVratDetectedForEkadashiTithi() {
        // Sweep a lunar month; at least one Ekadashi must be flagged as a vrat.
        var foundEkadashi = false
        for offset in 0..<31 {
            let d = Calendar.current.date(byAdding: .day, value: offset, to: date(2026, 6, 1))!
            if let p = PanchangCalculator.compute(for: d, city: delhi),
               p.vrat?.nameEN == "Ekadashi" { foundEkadashi = true; break }
        }
        XCTAssertTrue(foundEkadashi, "An Ekadashi vrat should be flagged within a month")
    }
}
