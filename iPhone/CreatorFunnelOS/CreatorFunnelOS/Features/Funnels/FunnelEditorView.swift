import SwiftUI

@MainActor
final class FunnelEditorViewModel: ObservableObject {
    @Published var funnel: Funnel
    @Published var isSaving = false
    @Published var validationMessage: String?
    let isNew: Bool

    init(funnel: Funnel) {
        self.funnel = funnel
        isNew = funnel.name.isEmpty
    }

    var canSave: Bool {
        let scheme = URL(string: funnel.destinationLink)?.scheme?.lowercased()
        return !funnel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !funnel.triggerKeyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !funnel.publicReply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !funnel.directMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && scheme == "https"
    }

    func validate() -> Bool {
        guard canSave else {
            validationMessage = "Complete every field and use a valid https:// destination link."
            return false
        }
        validationMessage = nil
        return true
    }
}

struct FunnelEditorView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: FunnelEditorViewModel

    init(funnel: Funnel) {
        _viewModel = StateObject(wrappedValue: FunnelEditorViewModel(funnel: funnel))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                statusCard
                detailsCard
                messageCard
                destinationCard
                previewCard

                if let message = viewModel.validationMessage {
                    Label(message, systemImage: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                PrimaryButton(
                    title: viewModel.isNew ? "Create funnel" : "Save changes",
                    systemImage: "checkmark",
                    isLoading: viewModel.isSaving
                ) {
                    save()
                }
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, 32)
        }
        .navigationTitle(viewModel.isNew ? "New funnel" : "Edit funnel")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Funnel status")
                    .font(.headline)
                Text(statusDetail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Picker("Funnel status", selection: $viewModel.funnel.status) {
                ForEach(FunnelStatus.allCases, id: \.self) { status in
                    Text(status.title).tag(status)
                }
            }
            .pickerStyle(.segmented)
        }
        .appCard()
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionTitle(title: "Basics", subtitle: "Keep the trigger specific and easy to remember")

            VStack(alignment: .leading, spacing: 8) {
                FormFieldLabel(title: "Funnel name")
                TextField("e.g. Free Brand Checklist", text: $viewModel.funnel.name)
                    .textFieldStyle(AppTextFieldStyle())
            }

            VStack(alignment: .leading, spacing: 8) {
                FormFieldLabel(
                    title: "Trigger keyword",
                    hint: "A comment keyword that clearly signals the person wants the resource"
                )
                TextField("e.g. BRAND", text: $viewModel.funnel.triggerKeyword)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .textFieldStyle(AppTextFieldStyle())
                    .onChange(of: viewModel.funnel.triggerKeyword) { _, newValue in
                        viewModel.funnel.triggerKeyword = newValue
                            .uppercased()
                            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
                    }
            }
        }
        .appCard()
    }

    private var messageCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionTitle(title: "Messages", subtitle: "Set accurate expectations in both steps")

            VStack(alignment: .leading, spacing: 8) {
                FormFieldLabel(
                    title: "Public reply",
                    hint: "A brief acknowledgement shown under the comment"
                )
                TextField("Sent it — check your DMs.", text: $viewModel.funnel.publicReply, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(AppTextFieldStyle())
            }

            VStack(alignment: .leading, spacing: 8) {
                FormFieldLabel(
                    title: "DM text",
                    hint: "Deliver the promised value without pressure or misleading urgency"
                )
                TextField("Here is the resource you requested…", text: $viewModel.funnel.directMessage, axis: .vertical)
                    .lineLimit(4...8)
                    .textFieldStyle(AppTextFieldStyle())
            }
        }
        .appCard()
    }

    private var destinationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            FormFieldLabel(
                title: "Destination link",
                hint: "Use a secure URL that directly matches the content promise"
            )
            TextField("https://yourdomain.com/resource", text: $viewModel.funnel.destinationLink)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(AppTextFieldStyle())
        }
        .appCard()
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "Conversation preview")

            HStack(alignment: .top, spacing: 9) {
                CreatorAvatar(initials: "IG", size: 34)
                Text(viewModel.funnel.publicReply.isEmpty ? "Your public reply appears here." : viewModel.funnel.publicReply)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(12)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }

            HStack {
                Spacer(minLength: 42)
                Text(viewModel.funnel.directMessage.isEmpty ? "Your direct message appears here." : viewModel.funnel.directMessage)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(13)
                    .background(AppTheme.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .appCard()
    }

    private func save() {
        guard viewModel.validate() else { return }
        viewModel.isSaving = true

        Task {
            do {
                try await appState.saveFunnel(viewModel.funnel)
                viewModel.isSaving = false
                dismiss()
            } catch {
                viewModel.isSaving = false
                viewModel.validationMessage = error.localizedDescription
            }
        }
    }

    private var statusDetail: String {
        switch viewModel.funnel.status {
        case .draft:
            "Finish setup and assign at least one post before activating."
        case .active:
            "Ready to respond when a matching keyword request is received."
        case .paused:
            "No automated replies will be sent until this funnel is active again."
        }
    }
}

private struct AppTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(14)
            .background(AppTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay {
                RoundedRectangle(cornerRadius: 13)
                    .stroke(AppTheme.border.opacity(0.8), lineWidth: 1)
            }
    }
}
