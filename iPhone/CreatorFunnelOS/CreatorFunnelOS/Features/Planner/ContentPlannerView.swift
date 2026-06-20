import SwiftUI

struct ContentPlannerView: View {
    enum PlannerSection: String, CaseIterable {
        case calendar = "Calendar"
        case ideas = "Ideas"
        case library = "Library"
    }

    @EnvironmentObject private var appState: AppState
    @State private var section: PlannerSection = .calendar
    @State private var selectedDate = Date()
    @State private var selectedDraft: ContentDraft?
    @State private var selectedTemplate: ContentTemplate?
    @State private var tool: PlannerTool?
    @State private var isAddingContent = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 22) {
                Picker("Planner section", selection: $section) {
                    ForEach(PlannerSection.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)

                switch section {
                case .calendar:
                    calendarContent
                case .ideas:
                    ideasContent
                case .library:
                    libraryContent
                }
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, 34)
        }
        .navigationTitle("Planner")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddingContent = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add content")
            }
        }
        .sheet(isPresented: $isAddingContent) {
            NewContentView { item in
                appState.workspace.content.insert(item, at: 0)
            }
        }
        .sheet(item: $selectedTemplate) { template in
            TemplateDetailView(template: template)
        }
        .sheet(item: $tool) { tool in
            PlannerToolPlaceholderView(tool: tool)
        }
        .navigationDestination(item: $selectedDraft) { draft in
            ContentDraftDetailView(draft: draft)
        }
        .appScreenBackground()
    }

    private var calendarContent: some View {
        Group {
            weekPicker

            VStack(alignment: .leading, spacing: 14) {
                SectionTitle(
                    title: "Content queue",
                    subtitle: "\(appState.workspace.content.count) ideas and scheduled posts"
                )

                if appState.workspace.content.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.plus",
                        title: "Your plan is open",
                        message: "Add your first content idea and connect it to a useful funnel.",
                        actionTitle: "Add content"
                    ) {
                        isAddingContent = true
                    }
                } else {
                    ForEach(appState.workspace.content.sorted(by: { $0.scheduledAt < $1.scheduledAt })) { item in
                        ContentRow(item: item)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                SectionTitle(title: "Drafts", subtitle: "Open a draft to refine its hook, caption, and post notes")
                if appState.workspace.contentDrafts.isEmpty {
                    EmptyStateView(
                        icon: "doc.badge.plus",
                        title: "No drafts yet",
                        message: "Saved ideas can become structured drafts when you are ready."
                    )
                } else {
                    ForEach(appState.workspace.contentDrafts) { draft in
                        Button {
                            selectedDraft = draft
                        } label: {
                            DraftRow(draft: draft)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var ideasContent: some View {
        Group {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle(title: "Ideas inbox", subtitle: "Capture useful angles before they disappear")

                if appState.workspace.contentIdeas.isEmpty {
                    EmptyStateView(
                        icon: "lightbulb",
                        title: "Your inbox is empty",
                        message: "Save a question, observation, or audience problem as your first content idea."
                    )
                } else {
                    ForEach(appState.workspace.contentIdeas) { idea in
                        IdeaCard(idea: idea)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                SectionTitle(title: "Writing tools", subtitle: "Structured helpers—not one-click publishing")
                Button {
                    tool = .hookGenerator
                } label: {
                    PlannerToolRow(
                        icon: "text.quote",
                        title: "Hook generator",
                        detail: "Explore opening lines from a saved idea",
                        badge: "Placeholder"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    tool = .captionDraft
                } label: {
                    PlannerToolRow(
                        icon: "text.alignleft",
                        title: "Caption draft assistant",
                        detail: "Turn a clear outline into a first draft",
                        badge: "Placeholder"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var libraryContent: some View {
        Group {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle(title: "Template library", subtitle: "Reusable structures for thoughtful creator content")

                ForEach(appState.workspace.contentTemplates) { template in
                    Button {
                        selectedTemplate = template
                    } label: {
                        TemplateRow(template: template)
                    }
                    .buttonStyle(.plain)
                }
            }

            FeatureAvailabilityCard(
                icon: "square.and.arrow.down",
                title: "Shared team templates",
                message: "A future Team workspace can publish approved templates and brand guidance to members."
            )
        }
    }

    private var weekPicker: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(Date.now.formatted(.dateTime.month(.wide).year()))
                        .font(.headline)
                    Text("Choose a day to focus your planning")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "calendar")
                    .foregroundStyle(AppTheme.brand)
            }

            HStack(spacing: 8) {
                ForEach(weekDates, id: \.self) { date in
                    Button {
                        selectedDate = date
                    } label: {
                        VStack(spacing: 7) {
                            Text(date.formatted(.dateTime.weekday(.narrow)))
                                .font(.caption2.weight(.semibold))
                            Text(date.formatted(.dateTime.day()))
                                .font(.subheadline.weight(.bold))
                        }
                        .foregroundStyle(Calendar.current.isDate(date, inSameDayAs: selectedDate) ? .white : AppTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            Calendar.current.isDate(date, inSameDayAs: selectedDate)
                                ? AppTheme.brand
                                : AppTheme.background
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .appCard()
    }

    private var weekDates: [Date] {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
}

enum PlannerTool: String, Identifiable {
    case hookGenerator
    case captionDraft

    var id: String { rawValue }
    var title: String { self == .hookGenerator ? "Hook generator" : "Caption draft assistant" }
    var icon: String { self == .hookGenerator ? "text.quote" : "text.alignleft" }
}

private struct ContentRow: View {
    let item: ContentItem

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: item.format.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.brand)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.brand.opacity(0.09))
                    .clipShape(RoundedRectangle(cornerRadius: 13))

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("\(item.format.rawValue) • \(item.scheduledAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()
                StatusPill(title: item.status.rawValue, color: statusColor)
            }

            if let linkedFunnelName = item.linkedFunnelName {
                Label("Linked to \(linkedFunnelName)", systemImage: "link")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.brand)
            }
        }
        .appCard()
    }

    private var statusColor: Color {
        switch item.status {
        case .idea: AppTheme.textSecondary
        case .draft: AppTheme.warning
        case .scheduled: AppTheme.brand
        case .published: AppTheme.success
        }
    }
}

private struct DraftRow: View {
    let draft: ContentDraft

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: draft.format.icon)
                .foregroundStyle(AppTheme.brand)
                .frame(width: 42, height: 42)
                .background(AppTheme.brand.opacity(0.09))
                .clipShape(RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 4) {
                Text(draft.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(draft.status.title)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .appCard()
    }
}

private struct IdeaCard: View {
    let idea: ContentIdea

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(idea.format.title, systemImage: idea.format.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.brand)
                Spacer()
                Image(systemName: idea.isSaved ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(AppTheme.brand)
            }
            Text(idea.title)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text(idea.summary)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(3)
            HStack {
                ForEach(idea.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.background)
                        .clipShape(Capsule())
                }
            }
        }
        .appCard()
    }
}

private struct TemplateRow: View {
    let template: ContentTemplate

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: template.format.icon)
                .foregroundStyle(AppTheme.brand)
                .frame(width: 42, height: 42)
                .background(AppTheme.brand.opacity(0.09))
                .clipShape(RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(template.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    if template.isPro {
                        StatusPill(title: "Pro", color: AppTheme.warning)
                    }
                }
                Text(template.description)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
                Text(template.category)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.brand)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .appCard()
    }
}

private struct PlannerToolRow: View {
    let icon: String
    let title: String
    let detail: String
    let badge: String

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.brand)
                .frame(width: 42, height: 42)
                .background(AppTheme.brand.opacity(0.09))
                .clipShape(RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            StatusPill(title: badge, color: AppTheme.textSecondary)
        }
        .appCard()
    }
}

private struct NewContentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var caption = ""
    @State private var format: ContentItem.Format = .reel
    @State private var status: ContentItem.Status = .idea
    @State private var scheduledAt = Date().addingTimeInterval(86_400)

    let onSave: (ContentItem) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Content") {
                    TextField("Working title", text: $title)
                    TextField("Caption notes", text: $caption, axis: .vertical)
                        .lineLimit(3...6)
                    Picker("Format", selection: $format) {
                        ForEach(ContentItem.Format.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    Picker("Stage", selection: $status) {
                        ForEach(ContentItem.Status.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    DatePicker("Publish date", selection: $scheduledAt)
                }
            }
            .navigationTitle("New content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            ContentItem(
                                id: UUID(),
                                title: title,
                                caption: caption,
                                format: format,
                                status: status,
                                scheduledAt: scheduledAt,
                                linkedFunnelName: nil
                            )
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

extension ContentFormat {
    var title: String {
        switch self {
        case .reel: "Reel"
        case .carousel: "Carousel"
        case .story: "Story"
        case .live: "Live"
        case .staticPost: "Post"
        }
    }

    var icon: String {
        switch self {
        case .reel: "play.rectangle"
        case .carousel: "square.stack"
        case .story: "circle.dashed"
        case .live: "dot.radiowaves.left.and.right"
        case .staticPost: "photo"
        }
    }
}

extension ContentDraftStatus {
    var title: String {
        switch self {
        case .idea: "Idea"
        case .drafting: "Drafting"
        case .ready: "Ready"
        case .scheduled: "Scheduled"
        case .published: "Published"
        }
    }
}
