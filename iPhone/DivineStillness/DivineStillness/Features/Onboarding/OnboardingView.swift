import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
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
                    Text("A quiet darshan, every day")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(18)
                        .frame(maxWidth: .infinity)
                        .background(.black.opacity(0.46))
                }

            VStack(spacing: 8) {
                Text("Divine Stillness Om")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppTheme.plum)
                Text("Sacred images, simple mantras, and a daily pause for devotion.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.muted)
                    .padding(.horizontal, 28)
            }

            Button("Continue") {
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

            Text("Make devotion a gentle habit")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.plum)

            VStack(spacing: 18) {
                benefit("photo.fill", "Daily Darshan", "A new sacred image and blessing each day.")
                benefit("circle.grid.3x3.fill", "Japa Counter", "Keep a calm 108-name practice without distraction.")
                benefit("bell.fill", "Quiet Reminders", "Choose a morning or evening time that works for you.")
            }
            .padding(.horizontal, 30)

            Spacer()

            Button("Choose My Deity") {
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

            Text("Who would you like to begin with?")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.plum)
                .padding(.horizontal, 24)

            Text("You can explore every deity and change this anytime.")
                .foregroundStyle(AppTheme.muted)

            VStack(spacing: 10) {
                ishtaRow(id: "shiv", name: "Lord Shiva", mantra: "Om Namah Shivaya")
                ishtaRow(id: "ganesh", name: "Lord Ganesha", mantra: "Om Gan Ganapataye Namah")
                ishtaRow(id: "krishna", name: "Lord Krishna", mantra: "Hare Krishna Hare Rama")
            }
            .padding(.horizontal, 24)

            Spacer()

            Button("Begin My Daily Darshan") {
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
