import SwiftUI

// MARK: - Shared helpers

private func qualityColor(_ q: ChoghadiyaQuality) -> Color {
    switch q {
    case .good: return AppTheme.teal
    case .neutral: return AppTheme.marigold
    case .bad: return AppTheme.vermilion
    }
}

private func clockString(_ date: Date, timeZoneID: String) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone(identifier: timeZoneID) ?? .current
    f.dateFormat = "h:mm a"
    return f.string(from: date)
}

private func dateSuffix(_ date: Date, timeZoneID: String) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone(identifier: timeZoneID) ?? .current
    f.dateFormat = "MMM d"
    return f.string(from: date)
}

/// "h:mm a", with a " MMM d" suffix when `date` falls on a different civil day
/// than `ref` — so a post-midnight night time reads e.g. "12:24 AM Jun 26".
private func clockWithDate(_ date: Date, ref: Date, timeZoneID: String) -> String {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: timeZoneID) ?? .current
    let base = clockString(date, timeZoneID: timeZoneID)
    return cal.isDate(date, inSameDayAs: ref) ? base : base + " " + dateSuffix(date, timeZoneID: timeZoneID)
}

/// A "start – end" range that prints the date whenever it crosses midnight.
private func rangeString(_ start: Date, _ end: Date, ref: Date, timeZoneID tz: String) -> String {
    clockWithDate(start, ref: ref, timeZoneID: tz) + " – " + clockWithDate(end, ref: start, timeZoneID: tz)
}

/// Full weekday + date for the Panchang (Hindu) day, e.g. "Wednesday, Jun 24".
private func dayString(_ date: Date, timeZoneID: String, lang: Lang) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: lang == .hi ? "hi_IN" : "en_US")
    f.timeZone = TimeZone(identifier: timeZoneID) ?? .current
    f.setLocalizedDateFormatFromTemplate("EEEEdMMM")
    return f.string(from: date)
}

// MARK: - Today-screen card

struct PanchangCard: View {
    @EnvironmentObject private var loc: LocalizationManager
    @EnvironmentObject private var locationManager: LocationManager
    @AppStorage("panchangCityID") private var cityID = ""
    @State private var result: PanchangResult?

    var body: some View {
        NavigationLink {
            PanchangView()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(loc.s("Today's Panchang", "आज का पंचांग"))
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    Label(result?.city.name(loc.lang) ?? loc.s("Select location", "स्थान चुनें"),
                          systemImage: locationManager.isActive ? "location.fill" : "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(AppTheme.muted)
                }

                if let p = result {
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        let current = p.currentChoghadiya(at: context.date)
                        HStack(spacing: 10) {
                            Circle()
                                .fill(qualityColor(current?.quality ?? .neutral))
                                .frame(width: 10, height: 10)
                            Text(loc.s("Now", "अभी") + ": " + (current?.name(loc.lang) ?? "—"))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.ink)
                            Spacer()
                            if let end = current?.end {
                                Text(loc.s("until ", "") + clockString(end, timeZoneID: p.city.timeZoneID) + loc.s("", " तक"))
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.muted)
                            }
                        }
                    }
                    HStack(spacing: 8) {
                        Text("\(p.tithi.name(loc.lang)) · \(p.nakshatra.name(loc.lang))")
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                            .lineLimit(1)
                        if let vrat = p.vrat {
                            Text(vrat.name(loc.lang))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(AppTheme.vermilion)
                                .padding(.horizontal, 7).padding(.vertical, 2)
                                .background(AppTheme.vermilion.opacity(0.12), in: Capsule())
                                .lineLimit(1)
                        }
                    }
                } else {
                    Text(loc.s("Tap to set your location", "स्थान चुनने हेतु स्पर्श करें"))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)
                }
            }
            .padding(16)
            .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
        .onAppear { recompute() }
        .onChange(of: cityID) { _, _ in recompute() }
        .onChange(of: locationManager.revision) { _, _ in recompute() }
        .onChange(of: locationManager.useGPS) { _, _ in recompute() }
    }

    private func recompute() {
        if let city = locationManager.activeCity(manualID: cityID, lang: loc.lang) {
            result = PanchangCalculator.computeForInstant(Date(), city: city)
        } else {
            result = nil
        }
    }
}

// MARK: - Full Panchang screen

struct PanchangView: View {
    @EnvironmentObject private var loc: LocalizationManager
    @EnvironmentObject private var locationManager: LocationManager
    @Environment(\.colorScheme) private var scheme
    @AppStorage("panchangCityID") private var cityID = ""
    @State private var result: PanchangResult?
    @State private var showCityPicker = false
    @State private var viewDate = Date()
    @State private var showCalendar = false
    @State private var anchored = false

    /// The shown day is "live" when it actually contains the present moment
    /// (handles the sunrise-to-sunrise boundary without civil-date confusion).
    private var isLive: Bool { result?.currentChoghadiya(at: Date()) != nil }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let p = result {
                    dateNav(p)
                    summary(p)
                    if isLive { nowBanner(p) }
                    elements(p)
                    choghadiyaSection(loc.s("Day Choghadiya", "दिन का चौघड़िया"), p.dayChoghadiya, p, night: false, live: isLive)
                    choghadiyaSection(loc.s("Night Choghadiya", "रात्रि का चौघड़िया"), p.nightChoghadiya, p, night: true, live: isLive)
                    auspicious(p)
                    inauspicious(p)
                    Text(loc.s(
                        "Calculated on your device for \(p.city.name(loc.lang)). For important muhurta, please confirm with your local Panchang.",
                        "\(p.city.name(loc.lang)) के लिए आपके डिवाइस पर गणना की गई। महत्वपूर्ण मुहूर्त हेतु कृपया अपने स्थानीय पंचांग से पुष्टि करें।"
                    ))
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.muted)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                } else {
                    VStack(spacing: 14) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 38))
                            .foregroundStyle(AppTheme.vermilion)
                        Text(loc.s("Choose your location", "अपना स्थान चुनें"))
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.ink)
                        Text(loc.s(
                            "Panchang timings depend on your sunrise. Use your location, or pick your city.",
                            "पंचांग का समय आपके सूर्योदय पर निर्भर करता है। अपना स्थान उपयोग करें या अपना शहर चुनें।"
                        ))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppTheme.muted)
                        .padding(.horizontal, 34)
                        Button {
                            showCityPicker = true
                        } label: {
                            Label(loc.s("Choose location", "स्थान चुनें"), systemImage: "location.fill")
                                .font(.headline)
                                .padding(.vertical, 13)
                                .padding(.horizontal, 26)
                                .foregroundStyle(.white)
                                .background(AppTheme.teal, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 56)
                }
            }
            .padding(.vertical, 16)
        }
        .devotionalBackground()
        .navigationTitle(loc.s("Panchang", "पंचांग"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showCityPicker = true } label: {
                    Label(loc.s("Location", "स्थान"), systemImage: locationManager.isActive ? "location.fill" : "mappin.and.ellipse")
                }
            }
        }
        .sheet(isPresented: $showCityPicker) {
            CityPickerView(selectedID: $cityID)
        }
        .sheet(isPresented: $showCalendar) {
            NavigationStack {
                DatePicker(
                    loc.s("Choose a date", "तारीख़ चुनें"),
                    selection: $viewDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(AppTheme.teal)
                .padding()
                .navigationTitle(loc.s("Choose a date", "तारीख़ चुनें"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(loc.s("Today", "आज")) { goToday(); showCalendar = false }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(loc.s("Done", "हो गया")) { showCalendar = false }
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
        .onAppear { recompute() }
        .onChange(of: cityID) { _, _ in recompute() }
        .onChange(of: viewDate) { _, _ in recompute() }
        .onChange(of: locationManager.revision) { _, _ in recompute() }
        .onChange(of: locationManager.useGPS) { _, _ in recompute() }
    }

    private func recompute() {
        guard let city = locationManager.activeCity(manualID: cityID, lang: loc.lang) else {
            result = nil
            return
        }
        if !anchored {
            // Anchor to the running Panchang (sunrise-to-sunrise) day: before today's
            // sunrise the Hindu day is still yesterday, so start there.
            let now = Date()
            if let today = PanchangCalculator.compute(for: now, city: city), now < today.sunrise {
                viewDate = now.addingTimeInterval(-24 * 3600)
            } else {
                viewDate = now
            }
            anchored = true
        }
        // `viewDate` always sits inside the day to show; compute() reads only its
        // calendar date (in the city's zone), so the time of day doesn't matter.
        result = PanchangCalculator.compute(for: viewDate, city: city)
    }

    private func shiftDay(_ days: Int) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = result.flatMap { TimeZone(identifier: $0.city.timeZoneID) } ?? .current
        viewDate = cal.date(byAdding: .day, value: days, to: viewDate) ?? viewDate
    }

    private func goToday() {
        anchored = false
        recompute()
    }

    private func dateNav(_ p: PanchangResult) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 16) {
                Button { shiftDay(-1) } label: {
                    Image(systemName: "chevron.left").font(.headline)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.paper, in: Circle())
                }
                Button { showCalendar = true } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "calendar").font(.subheadline)
                        Text(dayString(p.sunrise, timeZoneID: p.city.timeZoneID, lang: loc.lang))
                            .font(.headline)
                    }
                    .foregroundStyle(AppTheme.plum)
                }
                Button { shiftDay(1) } label: {
                    Image(systemName: "chevron.right").font(.headline)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.paper, in: Circle())
                }
            }
            .tint(AppTheme.teal)
            HStack(spacing: 8) {
                Text(loc.s("Panchang day · sunrise to sunrise", "पंचांग दिवस · सूर्योदय से सूर्योदय"))
                    .font(.caption2).foregroundStyle(AppTheme.muted)
                if !isLive {
                    Button(loc.s("Today", "आज")) { goToday() }
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.vermilion)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func summary(_ p: PanchangResult) -> some View {
        VStack(spacing: 10) {
            if let vrat = p.vrat {
                Label(vrat.name(loc.lang), systemImage: "sparkles")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.vermilion)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(AppTheme.vermilion.opacity(0.12), in: Capsule())
            }
            HStack(spacing: 22) {
                sunStat("sunrise.fill", loc.s("Sunrise", "सूर्योदय"), clockString(p.sunrise, timeZoneID: p.city.timeZoneID))
                sunStat("sunset.fill", loc.s("Sunset", "सूर्यास्त"), clockString(p.sunset, timeZoneID: p.city.timeZoneID))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }

    private func auspicious(_ p: PanchangResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(loc.s("Auspicious period", "शुभ काल")).font(.headline).foregroundStyle(AppTheme.ink).padding(.horizontal, 20)
            HStack {
                Label(p.abhijit.name(loc.lang), systemImage: "sun.max.fill")
                    .font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.ink)
                Spacer()
                Text(clockString(p.abhijit.start, timeZoneID: p.city.timeZoneID) + " – " + clockString(p.abhijit.end, timeZoneID: p.city.timeZoneID))
                    .font(.caption).foregroundStyle(AppTheme.teal)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 16)
        }
    }

    private func sunStat(_ icon: String, _ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Label(title, systemImage: icon).font(.caption).foregroundStyle(AppTheme.muted)
            Text(value).font(.headline).foregroundStyle(AppTheme.ink)
        }
    }

    @ViewBuilder private func nowBanner(_ p: PanchangResult) -> some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let current = p.currentChoghadiya(at: context.date)
            HStack(spacing: 12) {
                Circle().fill(qualityColor(current?.quality ?? .neutral)).frame(width: 14, height: 14)
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc.s("Right now", "इस समय")).font(.caption).foregroundStyle(AppTheme.muted)
                    Text(current?.name(loc.lang) ?? "—").font(.title3.bold()).foregroundStyle(AppTheme.ink)
                }
                Spacer()
                if let current {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(loc.lang == .hi ? current.quality.labelHI : current.quality.labelEN)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(qualityColor(current.quality))
                        Text(clockString(current.start, timeZoneID: p.city.timeZoneID) + " – " + clockString(current.end, timeZoneID: p.city.timeZoneID))
                            .font(.caption2).foregroundStyle(AppTheme.muted)
                    }
                }
            }
            .padding(16)
            .background(qualityColor(current?.quality ?? .neutral).opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 16)
        }
    }

    private func elements(_ p: PanchangResult) -> some View {
        VStack(spacing: 0) {
            elementRow(loc.s("Tithi", "तिथि"), p.tithi, p)
            Divider().padding(.leading, 16)
            elementRow(loc.s("Nakshatra", "नक्षत्र"), p.nakshatra, p)
            Divider().padding(.leading, 16)
            elementRow(loc.s("Yoga", "योग"), p.yoga, p)
            Divider().padding(.leading, 16)
            elementRow(loc.s("Karana", "करण"), p.karana, p)
        }
        .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }

    private func elementRow(_ label: String, _ element: PanchangElement, _ p: PanchangResult) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(AppTheme.muted)
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(element.name(loc.lang)).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.ink)
                if let end = element.endsAt {
                    Text(loc.s("until ", "") + clockString(end, timeZoneID: p.city.timeZoneID) + loc.s("", " तक"))
                        .font(.caption2).foregroundStyle(AppTheme.muted)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private func choghadiyaSection(_ title: String, _ list: [Choghadiya], _ p: PanchangResult, night: Bool, live: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).foregroundStyle(AppTheme.ink).padding(.horizontal, 20)
            TimelineView(.periodic(from: .now, by: 60)) { context in
                VStack(spacing: 0) {
                    ForEach(Array(list.enumerated()), id: \.element.id) { index, c in
                        let isNow = live && c.contains(context.date)
                        // Dark-mode needs more opacity for the tint to read as a colour.
                        let tint = qualityColor(c.quality).opacity(
                            isNow ? (scheme == .dark ? 0.42 : 0.20)
                                  : (scheme == .dark ? 0.22 : 0.08)
                        )
                        if index > 0 { Divider().padding(.leading, 16) }
                        HStack(spacing: 10) {
                            Circle().fill(qualityColor(c.quality)).frame(width: 9, height: 9)
                            Text(c.name(loc.lang))
                                .font(.subheadline.weight(isNow ? .bold : .medium))
                                .foregroundStyle(AppTheme.ink)
                            if isNow {
                                Text(loc.s("NOW", "अभी"))
                                    .font(.caption2.weight(.bold)).foregroundStyle(.white)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(qualityColor(c.quality), in: Capsule())
                            }
                            Spacer()
                            Text(rangeString(c.start, c.end, ref: night ? p.sunset : p.sunrise, timeZoneID: p.city.timeZoneID))
                                .font(.caption).foregroundStyle(AppTheme.muted)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(tint)
                    }
                }
                .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 14))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 16)
            }
        }
    }

    private func inauspicious(_ p: PanchangResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(loc.s("Inauspicious periods", "अशुभ काल")).font(.headline).foregroundStyle(AppTheme.ink).padding(.horizontal, 20)
            VStack(spacing: 0) {
                ForEach([p.rahu, p.gulika, p.yamaganda, p.varaVela, p.kalaVela, p.kalaRatri], id: \.nameEN) { w in
                    if w.nameEN != p.rahu.nameEN { Divider().padding(.leading, 16) }
                    HStack {
                        Text(w.name(loc.lang)).font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.ink)
                        Spacer()
                        Text(rangeString(w.start, w.end, ref: p.sunrise, timeZoneID: p.city.timeZoneID))
                            .font(.caption).foregroundStyle(AppTheme.vermilion)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                }
            }
            .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - City picker (GPS + manual fallback)

struct CityPickerView: View {
    @EnvironmentObject private var loc: LocalizationManager
    @EnvironmentObject private var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedID: String
    @State private var query = ""

    private var filtered: [City] { Cities.search(query) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        locationManager.enableGPS()
                        dismiss()
                    } label: {
                        HStack {
                            Label(loc.s("Use my location", "मेरा स्थान उपयोग करें"), systemImage: "location.fill")
                                .foregroundStyle(AppTheme.ink)
                            Spacer()
                            if locationManager.useGPS {
                                Image(systemName: "checkmark").foregroundStyle(AppTheme.vermilion)
                            }
                        }
                    }
                    if locationManager.isDenied {
                        Text(loc.s(
                            "Location access is off. Turn it on in iPhone Settings, or choose a city below.",
                            "स्थान की अनुमति बंद है। इसे iPhone सेटिंग्स में चालू करें, या नीचे एक शहर चुनें।"
                        ))
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                    }
                } footer: {
                    Text(loc.s(
                        "GPS gives the most accurate sunrise and is used only on your device.",
                        "GPS सबसे सटीक सूर्योदय देता है और केवल आपके डिवाइस पर उपयोग होता है।"
                    ))
                }

                Section(loc.s("Or search your city", "या अपना शहर खोजें")) {
                    if query.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text(loc.s(
                            "Start typing your city — over 10,000 cities worldwide.",
                            "अपना शहर टाइप करें — दुनिया भर के 10,000+ शहर।"
                        ))
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                    } else if filtered.isEmpty {
                        Text(loc.s("No city found. Try another spelling.", "कोई शहर नहीं मिला। दूसरी वर्तनी आज़माएँ।"))
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                    }
                    ForEach(filtered) { city in
                        Button {
                            locationManager.useManualCity()
                            selectedID = city.id
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(city.name(loc.lang)).foregroundStyle(AppTheme.ink)
                                    Text(city.regionEN).font(.caption).foregroundStyle(AppTheme.muted)
                                }
                                Spacer()
                                if !locationManager.useGPS && city.id == selectedID {
                                    Image(systemName: "checkmark").foregroundStyle(AppTheme.vermilion)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(loc.s("Choose location", "स्थान चुनें"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: loc.s("Search city", "शहर खोजें"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(loc.s("Done", "हो गया")) { dismiss() }
                }
            }
        }
    }
}
