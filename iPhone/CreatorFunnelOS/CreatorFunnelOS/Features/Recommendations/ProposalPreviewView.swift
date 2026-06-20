import SwiftUI

struct ProposalPreviewView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State var proposal: Proposal
    @State private var isApplying = false
    @State private var didApply = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    proposalHeader
                    impactCard
                    stepsCard
                    controlNote

                    if didApply {
                        Label("Proposal applied to the mock workspace.", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.success)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .appCard()
                    } else {
                        PrimaryButton(
                            title: proposal.ctaPrimary,
                            systemImage: "checkmark",
                            isLoading: isApplying
                        ) {
                            apply()
                        }
                        GhostButton(title: proposal.ctaSecondary) {
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .navigationTitle("Proposal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .appScreenBackground()
        }
    }

    private var proposalHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "wand.and.stars")
                .font(.title2)
                .foregroundStyle(AppTheme.brand)
                .frame(width: 52, height: 52)
                .background(AppTheme.brand.opacity(0.09))
                .clipShape(RoundedRectangle(cornerRadius: 15))

            Text(proposal.title)
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text(proposal.overview)
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(4)
        }
    }

    private var impactCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .foregroundStyle(AppTheme.success)
            VStack(alignment: .leading, spacing: 4) {
                Text("Expected impact")
                    .font(.subheadline.weight(.semibold))
                Text(proposal.expectedImpact)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .appCard()
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            SectionTitle(title: "Suggested steps", subtitle: "You remain in control of each change")
            ForEach(Array(proposal.suggestedSteps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(AppTheme.brand)
                        .clipShape(Circle())
                    Text(step)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
        }
        .appCard()
    }

    private var controlNote: some View {
        Label(
            "Applying this proposal updates only the suggested workspace configuration. It never publishes content or messages people without a qualifying request.",
            systemImage: "hand.raised.fill"
        )
        .font(.caption)
        .foregroundStyle(AppTheme.textSecondary)
        .appCard()
    }

    private func apply() {
        isApplying = true
        Task {
            didApply = await appState.applyProposal(proposal)
            if didApply {
                proposal.state = .applied
            }
            isApplying = false
        }
    }
}
