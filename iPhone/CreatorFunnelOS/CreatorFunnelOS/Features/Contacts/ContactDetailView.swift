import SwiftUI

struct ContactDetailView: View {
    @State private var contact: LeadContact
    @State private var isExportPresented = false

    init(contact: LeadContact) {
        _contact = State(initialValue: contact)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                identityCard
                detailsCard
                sourceCard
                notesCard
                activityCard
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, 30)
        }
        .navigationTitle("Lead detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isExportPresented = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Export or share lead")
            }
        }
        .sheet(isPresented: $isExportPresented) {
            LeadExportPlaceholderView(contact: contact)
        }
        .appScreenBackground()
    }

    private var identityCard: some View {
        VStack(spacing: 14) {
            CreatorAvatar(initials: contact.initials, size: 76)
            VStack(spacing: 4) {
                Text(contact.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(contact.instagramHandle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Picker("Relationship stage", selection: $contact.status) {
                ForEach(LeadContact.Status.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.segmented)
        }
        .frame(maxWidth: .infinity)
        .appCard()
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            DetailRow(icon: "at", label: "Instagram", value: contact.instagramHandle)
            Divider().padding(.leading, 44)
            DetailRow(icon: "envelope", label: "Email", value: contact.email ?? "Not provided")
            Divider().padding(.leading, 44)
            DetailRow(icon: "arrow.triangle.branch", label: "Source", value: contact.sourceFunnel)
            Divider().padding(.leading, 44)
            DetailRow(
                icon: "calendar",
                label: "Captured",
                value: contact.capturedAt.formatted(date: .abbreviated, time: .shortened)
            )
        }
        .appCard(padding: 8)
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Notes", subtitle: "Keep context human and useful")

            TextField("Add a private note", text: $contact.notes, axis: .vertical)
                .lineLimit(4...8)
                .padding(13)
                .background(AppTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 13))

            if !contact.tags.isEmpty {
                FlowTags(tags: contact.tags)
            }
        }
        .appCard()
    }

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "Lead source", subtitle: "How this person entered the creator workflow")
            DetailRow(icon: "arrow.triangle.branch", label: "Funnel", value: contact.sourceFunnel)
            DetailRow(
                icon: "photo",
                label: "Source post",
                value: sourcePostTitle
            )
            DetailRow(
                icon: "clock",
                label: "Last engaged",
                value: contact.lastEngagedAt.formatted(date: .abbreviated, time: .shortened)
            )
        }
        .appCard(padding: 8)
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(title: "Journey")

            JourneyRow(
                icon: "text.bubble.fill",
                title: "Requested the resource",
                detail: "Used the funnel keyword on Instagram",
                color: AppTheme.brand
            )
            JourneyRow(
                icon: "person.crop.circle.badge.plus",
                title: "Contact captured",
                detail: "Shared details through \(contact.sourceFunnel)",
                color: AppTheme.success
            )
            JourneyRow(
                icon: "link",
                title: "Destination opened",
                detail: "Continued from the requested DM to the resource page",
                color: .purple
            )
        }
        .appCard()
    }

    private var sourcePostTitle: String {
        guard let sourcePostId = contact.sourcePostId else { return "Not recorded" }
        return SampleData.socialPosts.first(where: { $0.id == sourcePostId })?.title ?? "Post unavailable"
    }
}

private struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.brand)
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            Spacer()
        }
        .padding(10)
    }
}

private struct FlowTags: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.brand)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(AppTheme.brand.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
        }
    }
}

private struct JourneyRow: View {
    let icon: String
    let title: String
    let detail: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 35, height: 35)
                .background(color.opacity(0.09))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
}

private struct LeadExportPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss
    let contact: LeadContact

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 34))
                    .foregroundStyle(AppTheme.brand)
                    .frame(width: 74, height: 74)
                    .background(AppTheme.brand.opacity(0.09))
                    .clipShape(Circle())

                Text("Export & share")
                    .font(.title2.weight(.bold))

                Text("A production export can include consent-based lead fields and an audit record. Private notes remain excluded unless the user explicitly includes them.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                VStack(spacing: 0) {
                    DetailRow(icon: "person", label: "Lead", value: contact.name)
                    Divider().padding(.leading, 44)
                    DetailRow(icon: "doc", label: "Format", value: "CSV or JSON")
                }
                .appCard(padding: 8)

                StatusPill(title: "Reporting hook ready", color: AppTheme.success)

                FeatureAvailabilityCard(
                    icon: "square.and.arrow.down",
                    title: "Workspace export",
                    message: "The service contract is ready; file generation and secure download delivery are intentionally mocked."
                )

                Spacer()
            }
            .padding(24)
            .navigationTitle("Lead export")
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
