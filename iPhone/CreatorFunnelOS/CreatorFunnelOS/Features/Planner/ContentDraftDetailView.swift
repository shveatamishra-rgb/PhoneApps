import SwiftUI

struct ContentDraftDetailView: View {
    @EnvironmentObject private var appState: AppState
    @State private var draft: ContentDraft
    @State private var isSaving = false
    @State private var didSave = false

    init(draft: ContentDraft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    FormFieldLabel(title: "Working title")
                    TextField("Draft title", text: $draft.title)
                        .draftFieldStyle()
                }
                .appCard()

                VStack(alignment: .leading, spacing: 10) {
                    FormFieldLabel(title: "Hook", hint: "The first line should match the value the post delivers")
                    TextField("Opening line", text: $draft.hook, axis: .vertical)
                        .lineLimit(3...6)
                        .draftFieldStyle()
                }
                .appCard()

                VStack(alignment: .leading, spacing: 10) {
                    FormFieldLabel(title: "Caption draft")
                    TextField("Caption", text: $draft.caption, axis: .vertical)
                        .lineLimit(6...14)
                        .draftFieldStyle()
                }
                .appCard()

                VStack(alignment: .leading, spacing: 14) {
                    SectionTitle(title: "Schedule & post notes")
                    DatePicker(
                        "Planned date",
                        selection: Binding(
                            get: { draft.scheduledAt ?? .now },
                            set: { draft.scheduledAt = $0 }
                        )
                    )
                    Picker("Status", selection: $draft.status) {
                        ForEach(ContentDraftStatus.allCases, id: \.self) {
                            Text($0.title).tag($0)
                        }
                    }
                    TextField("Production notes, CTA, visual direction", text: $draft.postNotes, axis: .vertical)
                        .lineLimit(4...8)
                        .draftFieldStyle()
                }
                .appCard()

                if didSave {
                    Label("Draft saved", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.success)
                }

                PrimaryButton(title: "Save draft", systemImage: "checkmark", isLoading: isSaving) {
                    save()
                }
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, 32)
        }
        .navigationTitle("Draft detail")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }

    private func save() {
        isSaving = true
        draft.updatedAt = .now
        Task {
            do {
                try await appState.saveDraft(draft)
                didSave = true
            } catch {
                appState.errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}

private extension View {
    func draftFieldStyle() -> some View {
        padding(13)
            .background(AppTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: 13))
    }
}

struct TemplateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let template: ContentTemplate

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Label(template.category, systemImage: template.format.icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.brand)
                    Text(template.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text(template.description)
                        .font(.body)
                        .foregroundStyle(AppTheme.textSecondary)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Template guidance")
                            .font(.headline)
                        Text(template.prompt)
                            .font(.body)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineSpacing(4)
                    }
                    .appCard()
                    FeatureAvailabilityCard(
                        icon: "doc.badge.plus",
                        title: "Create draft from template",
                        message: "The production planner will prefill a new draft while keeping the creator in control of every word.",
                        badge: template.isPro ? "Pro preview" : "Beta"
                    )
                }
                .padding(24)
            }
            .navigationTitle("Content template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .appScreenBackground()
        }
    }
}

struct PlannerToolPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss
    let tool: PlannerTool

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Image(systemName: tool.icon)
                    .font(.system(size: 34))
                    .foregroundStyle(AppTheme.brand)
                    .frame(width: 76, height: 76)
                    .background(AppTheme.brand.opacity(0.09))
                    .clipShape(Circle())
                Text(tool.title)
                    .font(.title2.weight(.bold))
                Text("This production placeholder defines the future workflow without pretending generated copy is ready to publish. A later service can propose options from your saved idea, voice guidance, and compliance settings.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                StatusPill(title: "Feature flag: off", color: AppTheme.textSecondary)
                Spacer()
            }
            .padding(26)
            .navigationTitle("Planner tool")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .appScreenBackground()
        }
    }
}
