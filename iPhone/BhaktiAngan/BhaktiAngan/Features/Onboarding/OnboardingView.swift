import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var loc: LocalizationManager
    @State private var page = 0
    @State private var selectedIshta = "shiv"

    var body: some View {
        ZStack {
            AppTheme.ivory.ignoresSafeArea()

            TabView(selection: $page) {
                welcomePage.tag(0)
                ritualPage.tag(1)
                preferencePage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Image("day1_shiv")
                .resizable()
                .scaledToFill()
                .frame(width: 250, height: 360)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(alignment: .bottom) {
                    Text(loc.s("A quiet darshan, every day", "हर दिन, एक शांत दर्शन"))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(18)
                        .frame(maxWidth: .infinity)
                        .background(.black.opacity(0.46))
                }

            VStack(spacing: 8) {
                Text("Bhakti Angan")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppTheme.plum)
                Text(loc.s(
                    "Sacred images, simple mantras, and a daily pause for devotion.",
                    "पावन चित्र, सरल मंत्र, और भक्ति के लिए एक दैनिक ठहराव।"
                ))
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.muted)
                .padding(.horizontal, 28)
            }

            Button(loc.s("Continue", "आगे बढ़ें")) {
                withAnimation { page = 1 }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 28)
        }
        .padding(.vertical, 30)
    }

    private var ritualPage: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "sun.max.circle.fill")
                .font(.system(size: 82))
                .foregroundStyle(AppTheme.marigold)

            Text(loc.s("Make devotion a gentle habit", "भक्ति को एक सहज आदत बनाएँ"))
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.plum)

            VStack(spacing: 18) {
                benefit("photo.fill",
                        loc.s("Daily Darshan", "दैनिक दर्शन"),
                        loc.s("A new sacred image and blessing each day.", "हर दिन एक नया पावन चित्र और आशीर्वाद।"))
                benefit("circle.grid.3x3.fill",
                        loc.s("Japa Counter", "जप गणक"),
                        loc.s("Keep a calm 108-name practice without distraction.", "बिना विघ्न के शांत 108-नाम का अभ्यास करें।"))
                benefit("bell.fill",
                        loc.s("Quiet Reminders", "शांत स्मरण"),
                        loc.s("Choose a morning or evening time that works for you.", "अपने अनुसार सुबह या शाम का समय चुनें।"))
            }
            .padding(.horizontal, 30)

            Spacer()

            Button(loc.s("Choose My Deity", "अपना इष्ट चुनें")) {
                withAnimation { page = 2 }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
        }
    }

    private var preferencePage: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text(loc.s("Choose your deity", "अपना इष्ट चुनें"))
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.plum)
                Text(loc.s(
                    "Pick who you would like to begin with. You can explore every deity and change this anytime.",
                    "चुनें कि आप किसके साथ आरंभ करना चाहेंगे। आप हर देवता के दर्शन कर सकते हैं और इसे कभी भी बदल सकते हैं।"
                ))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.muted)
            }
            .padding(.top, 22)
            .padding(.horizontal, 24)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 20) {
                    ForEach(ishtaOptions) { option in
                        deityCell(option)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 8)
            }

            Button(loc.s("Begin My Daily Darshan", "मेरा दैनिक दर्शन आरंभ करें")) {
                appState.completeOnboarding(ishta: selectedIshta)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
    }

    private struct IshtaOption: Identifiable {
        let id: String
        let name: String
        let image: String?
    }

    /// Popular deities that have a valid bundled image and a mantra, drawn from
    /// the live (defect-filtered) catalog so a thumbnail is never a removed image.
    private var ishtaOptions: [IshtaOption] {
        func img(_ slug: String) -> String? {
            ContentCatalog.items.first { $0.imageName.contains(slug) }?.imageName
        }
        return [
            IshtaOption(id: "shiv", name: loc.s("Shiva", "शिव"), image: img("shiv")),
            IshtaOption(id: "ganesh", name: loc.s("Ganesha", "गणेश"), image: img("ganesh")),
            IshtaOption(id: "krishna", name: loc.s("Krishna", "कृष्ण"), image: img("krishna")),
            IshtaOption(id: "shri_ram", name: loc.s("Rama", "राम"), image: img("shri_ram")),
            IshtaOption(id: "shri_hanuman", name: loc.s("Hanuman", "हनुमान"), image: img("shri_hanuman")),
            IshtaOption(id: "vishnu", name: loc.s("Vishnu", "विष्णु"), image: img("vishnu")),
            IshtaOption(id: "vaishno_devi", name: loc.s("Vaishno Devi", "वैष्णो देवी"), image: img("vaishno_devi")),
            IshtaOption(id: "saraswati_mata", name: loc.s("Saraswati", "सरस्वती"), image: img("saraswati_mata")),
        ]
    }

    private func deityCell(_ option: IshtaOption) -> some View {
        let selected = selectedIshta == option.id
        return Button {
            withAnimation(.easeOut(duration: 0.15)) { selectedIshta = option.id }
        } label: {
            VStack(spacing: 8) {
                Color.clear
                    .frame(width: 96, height: 96)
                    .overlay(alignment: .top) {
                        if let name = option.image {
                            Image(name).resizable().scaledToFill()
                        } else {
                            AppTheme.paper
                        }
                    }
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(
                            selected ? AppTheme.vermilion : Color.black.opacity(0.08),
                            lineWidth: selected ? 3 : 1
                        )
                    )
                    .overlay(alignment: .bottomTrailing) {
                        if selected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(AppTheme.vermilion)
                                .background(Circle().fill(.white))
                        }
                    }
                    .shadow(color: .black.opacity(selected ? 0.20 : 0.08), radius: 6, y: 3)
                Text(option.name)
                    .font(.subheadline.weight(selected ? .bold : .medium))
                    .foregroundStyle(selected ? AppTheme.plum : AppTheme.ink)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    private func benefit(_ icon: String, _ title: String, _ detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(AppTheme.vermilion)
                .frame(width: 38)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
            }
            Spacer()
        }
    }

}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                configuration.isPressed
                    ? AppTheme.plum.opacity(0.82)
                    : AppTheme.plum,
                in: RoundedRectangle(cornerRadius: 12)
            )
    }
}
