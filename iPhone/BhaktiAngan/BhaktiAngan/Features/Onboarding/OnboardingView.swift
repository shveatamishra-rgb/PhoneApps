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
        VStack(spacing: 24) {
            Spacer()

            Text(loc.s("Who would you like to begin with?", "आप किसके साथ आरंभ करना चाहेंगे?"))
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.plum)
                .padding(.horizontal, 24)

            Text(loc.s(
                "You can explore every deity and change this anytime.",
                "आप हर देवता के दर्शन कर सकते हैं और इसे कभी भी बदल सकते हैं।"
            ))
            .foregroundStyle(AppTheme.muted)

            VStack(spacing: 10) {
                ishtaRow(id: "shiv", name: loc.s("Lord Shiva", "भगवान शिव"), mantra: loc.s("Om Namah Shivaya", "ॐ नमः शिवाय"))
                ishtaRow(id: "ganesh", name: loc.s("Lord Ganesha", "भगवान गणेश"), mantra: loc.s("Om Gan Ganapataye Namah", "ॐ गं गणपतये नमः"))
                ishtaRow(id: "krishna", name: loc.s("Lord Krishna", "भगवान कृष्ण"), mantra: loc.s("Hare Krishna Hare Rama", "हरे कृष्ण हरे राम"))
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(loc.s("Begin My Daily Darshan", "मेरा दैनिक दर्शन आरंभ करें")) {
                appState.completeOnboarding(ishta: selectedIshta)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
        }
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

    private func ishtaRow(id: String, name: String, mantra: String) -> some View {
        Button {
            selectedIshta = id
        } label: {
            HStack {
                Image(systemName: selectedIshta == id ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedIshta == id ? AppTheme.vermilion : AppTheme.muted)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.headline)
                    Text(mantra)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)
                }
                Spacer()
            }
            .foregroundStyle(AppTheme.ink)
            .padding(16)
            .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedIshta == id ? AppTheme.vermilion : Color.black.opacity(0.08),
                        lineWidth: selectedIshta == id ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
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
