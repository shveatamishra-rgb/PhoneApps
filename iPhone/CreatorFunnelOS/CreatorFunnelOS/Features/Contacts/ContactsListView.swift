import SwiftUI

struct ContactsListView: View {
    @EnvironmentObject private var appState: AppState
    @State private var searchText = ""
    @State private var selectedStatus: LeadContact.Status?

    private var visibleContacts: [LeadContact] {
        appState.workspace.contacts.filter { contact in
            let matchesSearch = searchText.isEmpty
                || contact.name.localizedCaseInsensitiveContains(searchText)
                || contact.instagramHandle.localizedCaseInsensitiveContains(searchText)
                || contact.email?.localizedCaseInsensitiveContains(searchText) == true
            let matchesStatus = selectedStatus == nil || contact.status == selectedStatus
            return matchesSearch && matchesStatus
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                summaryCard
                statusFilters

                if visibleContacts.isEmpty {
                    EmptyStateView(
                        icon: "person.crop.circle.badge.questionmark",
                        title: appState.workspace.contacts.isEmpty ? "No contacts yet" : "No matching contacts",
                        message: appState.workspace.contacts.isEmpty
                            ? "People who intentionally share their details through a funnel will appear here."
                            : "Clear the search or choose another relationship stage."
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(visibleContacts.enumerated()), id: \.element.id) { index, contact in
                            NavigationLink {
                                ContactDetailView(contact: contact)
                            } label: {
                                ContactRow(contact: contact)
                            }
                            .buttonStyle(.plain)

                            if index < visibleContacts.count - 1 {
                                Divider()
                                    .padding(.leading, 72)
                            }
                        }
                    }
                    .appCard(padding: 6)
                }
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, 30)
        }
        .navigationTitle("Leads")
        .searchable(text: $searchText, prompt: "Search name, handle, or email")
        .appScreenBackground()
    }

    private var summaryCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(appState.workspace.contacts.count)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("consent-based leads")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "person.2.fill")
                .font(.title2)
                .foregroundStyle(AppTheme.brand)
                .frame(width: 52, height: 52)
                .background(AppTheme.brand.opacity(0.09))
                .clipShape(Circle())
        }
        .appCard()
    }

    private var statusFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedStatus == nil) {
                    selectedStatus = nil
                }
                ForEach(LeadContact.Status.allCases, id: \.self) { status in
                    FilterChip(title: status.rawValue, isSelected: selectedStatus == status) {
                        selectedStatus = status
                    }
                }
            }
        }
    }
}

private struct ContactRow: View {
    let contact: LeadContact

    private var statusColor: Color {
        switch contact.status {
        case .new: AppTheme.brand
        case .warm: AppTheme.warning
        case .converted: AppTheme.success
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            CreatorAvatar(initials: contact.initials, size: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(contact.instagramHandle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Text(contact.sourceFunnel)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.brand)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                StatusPill(title: contact.status.rawValue, color: statusColor)
                Text(contact.capturedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.55))
        }
        .padding(10)
        .contentShape(Rectangle())
    }
}
