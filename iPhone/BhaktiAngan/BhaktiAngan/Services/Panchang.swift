import Foundation

enum ChoghadiyaQuality {
    case good, neutral, bad
    var labelEN: String { self == .good ? "Auspicious" : self == .bad ? "Inauspicious" : "Neutral" }
    var labelHI: String { self == .good ? "शुभ" : self == .bad ? "अशुभ" : "सामान्य" }
}

struct Choghadiya: Identifiable {
    let id = UUID()
    let nameEN: String
    let nameHI: String
    let start: Date
    let end: Date
    let quality: ChoghadiyaQuality
    let isDay: Bool
    func name(_ l: Lang) -> String { l == .hi ? nameHI : nameEN }
    func contains(_ date: Date) -> Bool { date >= start && date < end }
}

struct KaalWindow {
    let nameEN: String
    let nameHI: String
    let start: Date
    let end: Date
    func name(_ l: Lang) -> String { l == .hi ? nameHI : nameEN }
}

/// A Panchang element (tithi/nakshatra/yoga/karana) as of sunrise, with the
/// instant it changes (nil if it didn't change within the search window).
struct PanchangElement {
    let nameEN: String
    let nameHI: String
    let endsAt: Date?
    func name(_ l: Lang) -> String { l == .hi ? nameHI : nameEN }
}

struct PanchangResult {
    let date: Date
    let city: City
    let sunrise: Date
    let sunset: Date
    let varaEN: String
    let varaHI: String
    let tithi: PanchangElement
    let nakshatra: PanchangElement
    let yoga: PanchangElement
    let karana: PanchangElement
    let dayChoghadiya: [Choghadiya]
    let nightChoghadiya: [Choghadiya]
    let rahu: KaalWindow
    let gulika: KaalWindow
    let yamaganda: KaalWindow
    let abhijit: KaalWindow      // auspicious midday muhurta
    let varaVela: KaalWindow     // inauspicious (day)
    let kalaVela: KaalWindow     // inauspicious (day)
    let kalaRatri: KaalWindow    // inauspicious (night)
    let vrat: PanchangElement?   // today's vrat / parva, if any (e.g. Ekadashi)

    func currentChoghadiya(at date: Date) -> Choghadiya? {
        (dayChoghadiya + nightChoghadiya).first { $0.contains(date) }
    }
}

enum PanchangCalculator {
    private static let cycle = PanchangNames.choghadiya          // Udveg,Char,Labh,Amrit,Kaal,Shubh,Rog
    private static let dayStartIdx = [0, 3, 6, 2, 5, 1, 4]       // Sun..Sat -> index into cycle
    private static let nightStartIdx = [5, 1, 4, 0, 3, 6, 2]
    private static let rahuSeg = [8, 2, 7, 5, 6, 4, 3]           // 1-based daytime eighth
    private static let gulikaSeg = [7, 6, 5, 4, 3, 2, 1]
    private static let yamaSeg = [5, 4, 3, 2, 1, 7, 6]
    private static let kalaVelaSeg = [5, 2, 6, 3, 7, 4, 1]       // Sun..Sat daytime eighth (Saturn-ruled)
    private static let kalaRatriSeg = [7, 5, 8, 6, 6, 4, 7]      // Sun..Sat nighttime eighth (verified vs DrikPanchang)
    private static let goodIdx: Set<Int> = [2, 3, 5]             // Labh, Amrit, Shubh
    private static let neutralIdx: Set<Int> = [1]               // Char

    /// Picks the Hindu day (sunrise→sunrise) that `now` falls in, so the live
    /// "right now" Choghadiya stays correct even before today's sunrise.
    static func computeForInstant(_ now: Date, city: City) -> PanchangResult? {
        guard let today = compute(for: now, city: city) else { return nil }
        if now < today.sunrise {
            return compute(for: now.addingTimeInterval(-24 * 3600), city: city) ?? today
        }
        return today
    }

    static func compute(for date: Date, city: City) -> PanchangResult? {
        let tz = TimeZone(identifier: city.timeZoneID) ?? .current
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let c = cal.dateComponents([.year, .month, .day, .weekday], from: date)
        guard let y = c.year, let m = c.month, let d = c.day, let wd = c.weekday else { return nil }
        let weekday = wd - 1 // 0 = Sunday

        let tzSec = city.tzSeconds(for: date)
        guard let today = Astronomy.sunriseSunset(
            year: y, month: m, day: d,
            latitude: city.latitude, longitude: city.longitude, tzSeconds: tzSec
        ) else { return nil }

        // Next day's sunrise bounds the night Choghadiya.
        let base = cal.date(from: DateComponents(year: y, month: m, day: d)) ?? date
        let next = cal.date(byAdding: .day, value: 1, to: base) ?? date
        let nc = cal.dateComponents([.year, .month, .day], from: next)
        let tomorrow = Astronomy.sunriseSunset(
            year: nc.year!, month: nc.month!, day: nc.day!,
            latitude: city.latitude, longitude: city.longitude, tzSeconds: city.tzSeconds(for: next)
        )
        let sunrise = today.sunrise
        let sunset = today.sunset
        let nextSunrise = tomorrow?.sunrise ?? sunset.addingTimeInterval(12 * 3600)

        // Calendar elements as of sunrise (the conventional reference).
        let jd = Astronomy.julianDay(sunrise)
        let sun = Astronomy.sunLongitude(jd)
        let moon = Astronomy.moonLongitude(jd)
        let ayan = Astronomy.ayanamsaLahiri(jd)
        let diff = Astronomy.norm360(moon - sun)

        let tithiIdx = min(29, Int(diff / 12))
        let tithi = PanchangElement(
            nameEN: tithiName(diff).en, nameHI: tithiName(diff).hi,
            endsAt: transitionEnd(after: sunrise, hours: 30) { tithiIndex(at: $0) }
        )
        let vrat = PanchangNames.vrat[tithiIdx].map {
            PanchangElement(nameEN: $0.en, nameHI: $0.hi, endsAt: nil)
        }
        let nakshatra = PanchangElement(
            nameEN: PanchangNames.nakshatra[nakshatraIdx(moon: moon, ayan: ayan)].en,
            nameHI: PanchangNames.nakshatra[nakshatraIdx(moon: moon, ayan: ayan)].hi,
            endsAt: transitionEnd(after: sunrise, hours: 30) { nakshatraIndex(at: $0) }
        )
        let yoga = PanchangElement(
            nameEN: PanchangNames.yoga[yogaIdx(sun: sun, moon: moon, ayan: ayan)].en,
            nameHI: PanchangNames.yoga[yogaIdx(sun: sun, moon: moon, ayan: ayan)].hi,
            endsAt: transitionEnd(after: sunrise, hours: 30) { yogaIndex(at: $0) }
        )
        let karana = PanchangElement(
            nameEN: karanaName(diff).en, nameHI: karanaName(diff).hi,
            endsAt: transitionEnd(after: sunrise, hours: 18) { karanaIndex(at: $0) }
        )

        let dayCho = choghadiya(from: sunrise, to: sunset, startIdx: dayStartIdx[weekday], isDay: true)
        let nightCho = choghadiya(from: sunset, to: nextSunrise, startIdx: nightStartIdx[weekday], isDay: false)

        return PanchangResult(
            date: date, city: city, sunrise: sunrise, sunset: sunset,
            varaEN: PanchangNames.vara[weekday].en, varaHI: PanchangNames.vara[weekday].hi,
            tithi: tithi, nakshatra: nakshatra, yoga: yoga, karana: karana,
            dayChoghadiya: dayCho, nightChoghadiya: nightCho,
            rahu: kaal(PanchangNames.rahuKaal, seg: rahuSeg[weekday], sunrise: sunrise, sunset: sunset),
            gulika: kaal(PanchangNames.gulikaKaal, seg: gulikaSeg[weekday], sunrise: sunrise, sunset: sunset),
            yamaganda: kaal(PanchangNames.yamaganda, seg: yamaSeg[weekday], sunrise: sunrise, sunset: sunset),
            abhijit: segment(PanchangNames.abhijit, from: sunrise, to: sunset, parts: 15, seg: 8),
            varaVela: segment(PanchangNames.varaVela, from: sunrise, to: sunset, parts: 8, seg: 8),
            kalaVela: segment(PanchangNames.kalaVela, from: sunrise, to: sunset, parts: 8, seg: kalaVelaSeg[weekday]),
            kalaRatri: segment(PanchangNames.kalaRatri, from: sunset, to: nextSunrise, parts: 8, seg: kalaRatriSeg[weekday]),
            vrat: vrat
        )
    }

    // MARK: - Element names

    private static func tithiName(_ diff: Double) -> PanchangNames.Bi {
        let idx = min(29, Int(diff / 12))
        if idx == 14 { return PanchangNames.tithi[14] }       // Purnima
        if idx == 29 { return PanchangNames.amavasya }        // Amavasya
        let paksha = idx < 15 ? PanchangNames.shuklaPaksha : PanchangNames.krishnaPaksha
        let t = PanchangNames.tithi[idx % 15]
        return ("\(paksha.en) \(t.en)", "\(paksha.hi) \(t.hi)")
    }

    private static func karanaName(_ diff: Double) -> PanchangNames.Bi {
        let idx = min(59, Int(diff / 6))
        switch idx {
        case 0: return PanchangNames.karanaKimstughna
        case 57: return PanchangNames.karanaShakuni
        case 58: return PanchangNames.karanaChatushpada
        case 59: return PanchangNames.karanaNaga
        default: return PanchangNames.karanaMovable[(idx - 1) % 7]
        }
    }

    private static func nakshatraIdx(moon: Double, ayan: Double) -> Int {
        min(26, Int(Astronomy.norm360(moon - ayan) / (360.0 / 27)))
    }

    private static func yogaIdx(sun: Double, moon: Double, ayan: Double) -> Int {
        min(26, Int(Astronomy.norm360(sun + moon - 2 * ayan) / (360.0 / 27)))
    }

    // MARK: - Transition root-finding (index increments are monotonic in time)

    private static func tithiIndex(at date: Date) -> Int {
        let jd = Astronomy.julianDay(date)
        return Int(Astronomy.norm360(Astronomy.moonLongitude(jd) - Astronomy.sunLongitude(jd)) / 12)
    }
    private static func karanaIndex(at date: Date) -> Int {
        let jd = Astronomy.julianDay(date)
        return Int(Astronomy.norm360(Astronomy.moonLongitude(jd) - Astronomy.sunLongitude(jd)) / 6)
    }
    private static func nakshatraIndex(at date: Date) -> Int {
        let jd = Astronomy.julianDay(date)
        return Int(Astronomy.norm360(Astronomy.moonLongitude(jd) - Astronomy.ayanamsaLahiri(jd)) / (360.0 / 27))
    }
    private static func yogaIndex(at date: Date) -> Int {
        let jd = Astronomy.julianDay(date)
        return Int(Astronomy.norm360(Astronomy.sunLongitude(jd) + Astronomy.moonLongitude(jd) - 2 * Astronomy.ayanamsaLahiri(jd)) / (360.0 / 27))
    }

    private static func transitionEnd(after start: Date, hours: Double, index: (Date) -> Int) -> Date? {
        let startIdx = index(start)
        let step: TimeInterval = 600
        let limit = start.addingTimeInterval(hours * 3600)
        var prev = start
        var t = start.addingTimeInterval(step)
        while t <= limit {
            if index(t) != startIdx {
                var lo = prev, hi = t
                for _ in 0..<24 {
                    let mid = lo.addingTimeInterval(hi.timeIntervalSince(lo) / 2)
                    if index(mid) == startIdx { lo = mid } else { hi = mid }
                }
                return hi
            }
            prev = t
            t = t.addingTimeInterval(step)
        }
        return nil
    }

    // MARK: - Choghadiya & Kaal windows

    private static func choghadiya(from start: Date, to end: Date, startIdx: Int, isDay: Bool) -> [Choghadiya] {
        let dur = end.timeIntervalSince(start) / 8
        // Day Choghadiya advances +1 through the cycle; night advances -2 (≡ +5 mod 7).
        let step = isDay ? 1 : 5
        return (0..<8).map { i in
            let idx = (startIdx + step * i) % 7
            let quality: ChoghadiyaQuality = goodIdx.contains(idx) ? .good : (neutralIdx.contains(idx) ? .neutral : .bad)
            let s = start.addingTimeInterval(Double(i) * dur)
            return Choghadiya(nameEN: cycle[idx].en, nameHI: cycle[idx].hi,
                              start: s, end: s.addingTimeInterval(dur), quality: quality, isDay: isDay)
        }
    }

    private static func kaal(_ name: PanchangNames.Bi, seg: Int, sunrise: Date, sunset: Date) -> KaalWindow {
        let part = sunset.timeIntervalSince(sunrise) / 8
        let start = sunrise.addingTimeInterval(Double(seg - 1) * part)
        return KaalWindow(nameEN: name.en, nameHI: name.hi, start: start, end: start.addingTimeInterval(part))
    }

    /// The `seg`-th (1-based) slice when `from`→`to` is split into `parts` equal
    /// windows — used for Abhijit (8th of 15), Vara/Kala Vela, and Kala Ratri.
    private static func segment(_ name: PanchangNames.Bi, from: Date, to: Date, parts: Int, seg: Int) -> KaalWindow {
        let part = to.timeIntervalSince(from) / Double(parts)
        let start = from.addingTimeInterval(Double(seg - 1) * part)
        return KaalWindow(nameEN: name.en, nameHI: name.hi, start: start, end: start.addingTimeInterval(part))
    }
}
