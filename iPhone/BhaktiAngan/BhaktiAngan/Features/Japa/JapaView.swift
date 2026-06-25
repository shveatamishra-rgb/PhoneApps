import StoreKit
import SwiftUI

struct JapaView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var loc: LocalizationManager
    @State private var showPaywall = false

    private var selectedChoice: MantraChoice {
        ContentCatalog.mantraChoices.first { $0.id == appState.selectedMantraID }
            ?? ContentCatalog.mantraChoices[0]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    mantraSelector

                    JapaPracticeView(choice: selectedChoice)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .devotionalBackground()
            .navigationTitle(loc.s("Japa", "जप"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { appState.refreshJapaForToday() }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var mantraSelector: some View {
        Menu {
            ForEach(ContentCatalog.mantraChoices) { choice in
                Button {
                    if choice.isPremium && !store.hasPro {
                        showPaywall = true
                    } else {
                        appState.selectMantra(choice.id)
                    }
                } label: {
                    if choice.isPremium && !store.hasPro {
                        Label(choice.deity(loc.lang), systemImage: "lock.fill")
                    } else {
                        Text(choice.deity(loc.lang))
                    }
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(loc.s("CURRENT MANTRA", "वर्तमान मंत्र"))
                        .font(.caption2.bold())
                        .tracking(1)
                        .foregroundStyle(AppTheme.vermilion)
                    Text(selectedChoice.deity(loc.lang))
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundStyle(AppTheme.muted)
            }
            .padding(15)
            .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct JapaPracticeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var loc: LocalizationManager
    @Environment(\.requestReview) private var requestReview
    @AppStorage("japaGoal") private var goal = 108
    @State private var showCompletion = false

    let choice: MantraChoice

    static let goalPresets = [27, 54, 108, 1008, 10000]

    private var isComplete: Bool { appState.dailyJapaCount >= goal }

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 8) {
                Text(choice.mantra(loc.lang))
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.plum)
                Text(choice.meaning(loc.lang))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ZStack {
                Circle()
                    .stroke(AppTheme.marigold.opacity(0.2), lineWidth: 15)
                Circle()
                    .trim(
                        from: 0,
                        to: min(Double(appState.dailyJapaCount) / Double(goal), 1)
                    )
                    .stroke(
                        AppTheme.marigold,
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.25), value: appState.dailyJapaCount)

                Button {
                    chant()
                } label: {
                    VStack(spacing: 4) {
                        Text(appState.dailyJapaCount.formatted())
                            .font(.system(size: 54, weight: .bold, design: .rounded))
                            .contentTransition(.numericText())
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        Text(loc.s("of \(goal.formatted())", "\(goal.formatted()) में से"))
                            .font(.headline)
                            .foregroundStyle(AppTheme.muted)
                        Text(isComplete
                            ? loc.s("Mala complete", "माला पूर्ण")
                            : loc.s("Tap to chant", "जप हेतु स्पर्श करें"))
                            .font(.caption)
                            .foregroundStyle(isComplete ? AppTheme.teal : AppTheme.vermilion)
                    }
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 18)
                    .frame(width: 220, height: 220)
                    .background(AppTheme.paper, in: Circle())
                    .overlay {
                        Circle().stroke(
                            isComplete ? AppTheme.teal.opacity(0.5) : .clear,
                            lineWidth: 3
                        )
                    }
                }
                .buttonStyle(.plain)
            }
            .frame(width: 260, height: 260)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(Self.goalPresets, id: \.self) { goalButton($0) }
                }
                .padding(.horizontal, 2)
            }
            .scrollIndicators(.hidden)

            Button(role: .destructive) {
                appState.resetJapa()
            } label: {
                Label(loc.s("Reset today's count", "आज की गिनती रीसेट करें"), systemImage: "arrow.counterclockwise")
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(.vertical, 18)
        .overlay(alignment: .top) {
            if showCompletion {
                Label(
                    loc.s("Mala complete · \(goal) names 🙏", "माला पूर्ण · \(goal) नाम 🙏"),
                    systemImage: "checkmark.seal.fill"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(AppTheme.teal, in: Capsule())
                .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func chant() {
        appState.incrementJapa()
        if appState.dailyJapaCount == goal {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation { showCompletion = true }
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                withAnimation { showCompletion = false }
            }
            // A finished mala is the most positive moment to ask for a rating.
            ReviewPrompter.requestIfAppropriate(requestReview)
        } else {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    private func goalButton(_ value: Int) -> some View {
        Button {
            goal = value
        } label: {
            Text(value.formatted())
            .font(.subheadline.bold())
            .foregroundStyle(goal == value ? .white : AppTheme.vermilion)
            .frame(minWidth: 58)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                goal == value ? AppTheme.vermilion : AppTheme.paper,
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }
}
