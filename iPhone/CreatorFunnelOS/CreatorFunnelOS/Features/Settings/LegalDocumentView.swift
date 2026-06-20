import SwiftUI

enum LegalDocument {
    case privacy
    case terms

    var title: String {
        self == .privacy ? "Privacy Policy" : "Terms of Service"
    }

    var lastUpdated: String {
        "Testing policy — June 18, 2026"
    }

    var sections: [(String, String)] {
        switch self {
        case .privacy:
            [
                ("Overview", "Creator Funnel OS helps creators organize content, consent-based conversations, and lead information. When live services are enabled, data is processed by the configured Creator Funnel OS API and official platform integrations."),
                ("Information we process", "The service may process account profile details, content plans, funnel configuration, requested direct-message events, contact details voluntarily submitted by a lead, and aggregate performance information."),
                ("How information is used", "Information is used to provide the workspace, deliver requested resources, measure funnel performance, maintain security, and support the account. It must not be used for fake engagement, mass following, follower generation, or unsolicited messaging."),
                ("Platform connections", "Instagram features use official Meta APIs and permissions. Creator Funnel OS does not request or store an Instagram password."),
                ("Your choices", "Users should be able to pause funnels, disconnect connected accounts, export eligible contact data, and request deletion. Contact outreach must honor consent and applicable privacy and marketing laws."),
                ("Testing notice", "This policy must be replaced by the hosted, legally reviewed policy for the operating company before public App Store distribution.")
            ]
        case .terms:
            [
                ("Using the service", "Creator Funnel OS provides planning, workflow, contact-management, and analytics tools for authentic creator-business activity. You are responsible for your content, audience promises, and compliance with platform rules and applicable law."),
                ("Prohibited use", "The service may not be used for fake followers, follow-for-follow schemes, mass following, deceptive engagement, scraping, spam, impersonation, or sending messages that a recipient did not reasonably request."),
                ("Account connections", "You may connect only accounts you are authorized to manage. Integrations use official platform authorization and remain subject to platform terms and technical limits."),
                ("Subscriptions", "Paid plans will renew according to the terms shown by the App Store. Users can manage or cancel subscriptions through their Apple ID settings. Restore Purchases should be available wherever the paywall is presented."),
                ("Availability", "During private testing, service availability and external-platform behavior may change as integrations are validated."),
                ("Testing notice", "These terms must be replaced by hosted terms reviewed for the operating company before public App Store distribution.")
            ]
        }
    }
}

struct LegalDocumentView: View {
    let document: LegalDocument

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(document.title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(document.lastUpdated)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                ForEach(Array(document.sections.enumerated()), id: \.offset) { _, section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.0)
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(section.1)
                            .font(.body)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineSpacing(5)
                    }
                }
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 34)
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .appScreenBackground()
    }
}
