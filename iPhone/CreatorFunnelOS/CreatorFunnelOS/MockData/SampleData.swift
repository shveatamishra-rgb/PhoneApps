import Foundation

enum SampleData {
    static let workspaceId = UUID(uuidString: "D33DE4E8-EFCA-460B-862E-88005DAA59DE")!
    static let userId = UUID(uuidString: "D583CA93-1438-4E30-81A8-A58283808D15")!
    static let accountId = UUID(uuidString: "9245FCEE-C6CC-4D63-B848-2FF7BCE45317")!
    static let brandFunnelId = UUID(uuidString: "A1BBD75D-0193-4A0F-97B8-B4356D8CC927")!
    static let newsletterFunnelId = UUID(uuidString: "E7315BC7-358A-4A22-B36D-C6D39A44DB6C")!
    static let workshopFunnelId = UUID(uuidString: "5C6A8B8E-0BA4-4990-974E-24DBB7AB3E4C")!

    static let user = User(
        id: userId,
        fullName: "Maya Chen",
        email: "maya@example.com",
        avatarURL: nil,
        createdAt: Date().addingTimeInterval(-8_000_000)
    )

    static let domainWorkspace = Workspace(
        id: workspaceId,
        name: "Maya Creates",
        planTier: .free,
        createdAt: Date().addingTimeInterval(-7_500_000)
    )

    static let membership = Membership(
        id: UUID(),
        userId: userId,
        workspaceId: workspaceId,
        role: .owner,
        joinedAt: domainWorkspace.createdAt
    )

    static let socialAccount = SocialAccount(
        id: accountId,
        platform: .instagram,
        handle: "maya.creates",
        accountType: .creator,
        isConnected: true,
        lastSyncAt: Date().addingTimeInterval(-420)
    )

    static let account = CreatorAccount(
        id: accountId,
        username: "maya.creates",
        displayName: "Maya Chen",
        followerCount: 24_800,
        isConnected: true
    )

    static let socialPosts = [
        SocialPost(
            id: UUID(uuidString: "0C4268AC-477A-4A19-AD92-AC2A444CD034")!,
            accountId: accountId,
            platformPostId: "ig_1844201",
            title: "Three signs your positioning is too broad",
            publishedAt: Date().addingTimeInterval(-172_800),
            status: .published
        ),
        SocialPost(
            id: UUID(uuidString: "4577A48A-F241-4BD8-9327-3996D9704CDA")!,
            accountId: accountId,
            platformPostId: "ig_1844022",
            title: "My weekly content planning system",
            publishedAt: Date().addingTimeInterval(-604_800),
            status: .published
        ),
        SocialPost(
            id: UUID(),
            accountId: accountId,
            platformPostId: nil,
            title: "A calm creator workflow beats constant urgency",
            publishedAt: nil,
            status: .scheduled
        )
    ]

    static let metrics = [
        DashboardMetric(id: UUID(), title: "Triggered comments", value: "512", change: "+18% this month", kind: .triggeredComments),
        DashboardMetric(id: UUID(), title: "Successful DMs", value: "476", change: "93% delivery rate", kind: .successfulDMs),
        DashboardMetric(id: UUID(), title: "Leads captured", value: "96", change: "+12% this month", kind: .leads),
        DashboardMetric(id: UUID(), title: "Lead conversion", value: "18.7%", change: "+2.1 points", kind: .leadConversion),
        DashboardMetric(id: UUID(), title: "Link click rate", value: "31.4%", change: "+4.2 points", kind: .clickRate),
        DashboardMetric(id: UUID(), title: "Active funnels", value: "2", change: "All healthy", kind: .activeFunnels)
    ]

    static let funnels = [
        Funnel(
            id: brandFunnelId,
            name: "Free Brand Checklist",
            status: .active,
            triggerKeyword: "BRAND",
            publicReply: "Sent it your way — check your DMs ✨",
            directMessage: "Here’s the brand checklist I mentioned. I hope it helps you tighten your positioning.",
            destinationLink: "https://example.com/brand-checklist",
            connectedPostIds: [socialPosts[0].id],
            isActive: true,
            conversations: 218,
            leads: 54,
            createdAt: Date().addingTimeInterval(-2_500_000),
            updatedAt: Date().addingTimeInterval(-3_600)
        ),
        Funnel(
            id: newsletterFunnelId,
            name: "Creator Newsletter",
            status: .active,
            triggerKeyword: "WEEKLY",
            publicReply: "You’re in — I just sent the details.",
            directMessage: "Join my weekly creator note for practical content systems and behind-the-scenes lessons.",
            destinationLink: "https://example.com/newsletter",
            connectedPostIds: [socialPosts[1].id],
            isActive: true,
            conversations: 146,
            leads: 31,
            createdAt: Date().addingTimeInterval(-1_800_000),
            updatedAt: Date().addingTimeInterval(-86_400)
        ),
        Funnel(
            id: workshopFunnelId,
            name: "Workshop Waitlist",
            status: .paused,
            triggerKeyword: "WORKSHOP",
            publicReply: "Thanks! I’ve sent the waitlist link to your DMs.",
            directMessage: "You can join the early-access list here. I’ll only send workshop updates.",
            destinationLink: "https://example.com/workshop",
            isActive: false,
            conversations: 64,
            leads: 11,
            createdAt: Date().addingTimeInterval(-3_200_000),
            updatedAt: Date().addingTimeInterval(-604_800)
        )
    ]

    static let contacts = [
        LeadContact(
            id: UUID(),
            name: "Avery Brooks",
            instagramHandle: "@averybuilds",
            email: "avery@example.com",
            sourceFunnel: "Free Brand Checklist",
            sourcePostId: socialPosts[0].id,
            sourceFunnelId: brandFunnelId,
            status: .warm,
            tags: ["Branding", "Coach"],
            notes: "Interested in the next positioning workshop.",
            capturedAt: Date().addingTimeInterval(-7_200),
            lastEngagedAt: Date().addingTimeInterval(-1_800)
        ),
        LeadContact(
            id: UUID(),
            name: "Jordan Lee",
            instagramHandle: "@jordantellsstories",
            email: "jordan@example.com",
            sourceFunnel: "Creator Newsletter",
            sourcePostId: socialPosts[1].id,
            sourceFunnelId: newsletterFunnelId,
            status: .new,
            tags: ["Newsletter"],
            notes: "",
            capturedAt: Date().addingTimeInterval(-90_000)
        ),
        LeadContact(
            id: UUID(),
            name: "Nia Patel",
            instagramHandle: "@niamakes",
            email: nil,
            sourceFunnel: "Free Brand Checklist",
            sourcePostId: socialPosts[0].id,
            sourceFunnelId: brandFunnelId,
            status: .converted,
            tags: ["Design", "Client"],
            notes: "Booked a brand clarity call.",
            capturedAt: Date().addingTimeInterval(-220_000),
            lastEngagedAt: Date().addingTimeInterval(-43_000)
        ),
        LeadContact(
            id: UUID(),
            name: "Sam Rivera",
            instagramHandle: "@samshoots",
            email: "sam@example.com",
            sourceFunnel: "Workshop Waitlist",
            sourceFunnelId: workshopFunnelId,
            status: .new,
            tags: ["Photography"],
            notes: "",
            capturedAt: Date().addingTimeInterval(-410_000)
        )
    ]

    static let content = [
        ContentItem(
            id: UUID(),
            title: "Three signs your positioning is too broad",
            caption: "Clear positioning makes every content decision easier…",
            format: .reel,
            status: .scheduled,
            scheduledAt: Calendar.current.date(byAdding: .hour, value: 5, to: .now)!,
            linkedFunnelName: "Free Brand Checklist"
        ),
        ContentItem(
            id: UUID(),
            title: "My weekly content planning system",
            caption: "A calm content rhythm beats a frantic calendar.",
            format: .carousel,
            status: .draft,
            scheduledAt: Calendar.current.date(byAdding: .day, value: 2, to: .now)!,
            linkedFunnelName: "Creator Newsletter"
        ),
        ContentItem(
            id: UUID(),
            title: "Studio Q&A",
            caption: "Bring your questions about sustainable creator systems.",
            format: .live,
            status: .idea,
            scheduledAt: Calendar.current.date(byAdding: .day, value: 5, to: .now)!,
            linkedFunnelName: nil
        )
    ]

    static let activity = [
        ActivityEvent(id: UUID(), title: "New lead captured", detail: "Avery joined through Free Brand Checklist", date: Date().addingTimeInterval(-2_100), kind: .lead),
        ActivityEvent(id: UUID(), title: "Destination link opened", detail: "@lena.studio opened your newsletter link", date: Date().addingTimeInterval(-5_400), kind: .click),
        ActivityEvent(id: UUID(), title: "Keyword matched", detail: "BRAND triggered a compliant DM reply", date: Date().addingTimeInterval(-8_200), kind: .message)
    ]

    static let analytics = AnalyticsSnapshot(
        id: UUID(),
        workspaceId: workspaceId,
        periodStart: Calendar.current.date(byAdding: .day, value: -30, to: .now)!,
        periodEnd: .now,
        activeFunnelCount: 2,
        triggerVolume: 512,
        successfulDMs: 476,
        dmSuccessRate: 0.93,
        linkClickThroughRate: 0.314,
        leadConversionRate: 0.187,
        leadsCaptured: 96,
        bestPerformingFunnelId: brandFunnelId,
        bestPerformingPostId: socialPosts[0].id,
        sevenDayTrend: trendPoints(days: 7, values: [42, 55, 51, 68, 64, 79, 88]),
        thirtyDayTrend: trendPoints(days: 30, values: [188, 204, 221, 216, 250, 273, 281, 312, 338, 367])
    )

    static let recommendations = [
        Recommendation(
            id: UUID(uuidString: "7C73598C-3DAA-42C2-8423-7379ECF5B0EF")!,
            type: .reuseTemplate,
            title: "Reuse your highest-converting DM",
            summary: "The Brand Checklist message converts 1.8× better than your other active template.",
            rationale: "Its promise is specific, the message is concise, and the destination closely matches the post.",
            projectedBenefit: "Potentially 14–20 additional leads per month",
            actionLabel: "Review proposal",
            status: .new,
            createdAt: Date().addingTimeInterval(-4_200)
        ),
        Recommendation(
            id: UUID(uuidString: "9517916B-1D75-4D02-A7D6-FCA19484B9A9")!,
            type: .shortenCTA,
            title: "Shorten the newsletter CTA",
            summary: "People open this DM often, but fewer continue to the destination link.",
            rationale: "A shorter first sentence may make the requested action easier to scan.",
            projectedBenefit: "Estimated 3–6 point click-through improvement",
            actionLabel: "Preview revision",
            status: .viewed,
            createdAt: Date().addingTimeInterval(-86_400)
        )
    ]

    static let proposals = recommendations.map { recommendation in
        Proposal(
            id: UUID(),
            recommendationId: recommendation.id,
            title: recommendation.title,
            overview: recommendation.summary,
            expectedImpact: recommendation.projectedBenefit,
            suggestedSteps: [
                "Review the suggested copy against the original post promise.",
                "Apply the change to one funnel first.",
                "Compare delivery, clicks, and lead capture for seven days."
            ],
            ctaPrimary: "Apply proposal",
            ctaSecondary: "Not now",
            state: .preview
        )
    }

    static let contentIdeas = [
        ContentIdea(
            id: UUID(),
            workspaceId: workspaceId,
            title: "The quiet reason creators abandon good systems",
            summary: "A reflective reel about reducing friction instead of chasing motivation.",
            format: .reel,
            tags: ["Systems", "Mindset"],
            createdAt: Date().addingTimeInterval(-3_600),
            isSaved: true
        ),
        ContentIdea(
            id: UUID(),
            workspaceId: workspaceId,
            title: "What I review before publishing a lead magnet",
            summary: "Turn the compliance checklist into a practical carousel.",
            format: .carousel,
            tags: ["Lead capture", "Trust"],
            createdAt: Date().addingTimeInterval(-86_400),
            isSaved: true
        )
    ]

    static let contentDrafts = [
        ContentDraft(
            id: UUID(),
            workspaceId: workspaceId,
            ideaId: contentIdeas.first?.id,
            title: "A content system should make you calmer",
            hook: "If your content system only works when you feel motivated, it is not a system yet.",
            caption: "Sustainable creator workflow is mostly about reducing the number of decisions you repeat.",
            format: .reel,
            status: .drafting,
            scheduledAt: Calendar.current.date(byAdding: .day, value: 3, to: .now),
            postNotes: "Use calm studio B-roll. End with WEEKLY keyword CTA.",
            createdAt: Date().addingTimeInterval(-172_800),
            updatedAt: Date().addingTimeInterval(-7_200)
        )
    ]

    static let contentTemplates = [
        ContentTemplate(
            id: UUID(),
            name: "Problem → Reframe → Next step",
            category: "Educational",
            description: "A clear carousel structure for teaching without overwhelming.",
            prompt: "Name the familiar problem, offer a calmer reframe, then give one useful next step.",
            format: .carousel,
            isPro: false
        ),
        ContentTemplate(
            id: UUID(),
            name: "Behind the system",
            category: "Authority",
            description: "Show the repeatable process behind a result.",
            prompt: "Open with the outcome, show three process decisions, and close with an honest limitation.",
            format: .reel,
            isPro: true
        ),
        ContentTemplate(
            id: UUID(),
            name: "Consent-led resource CTA",
            category: "Lead capture",
            description: "Invite a clear keyword request without manufactured urgency.",
            prompt: "Describe the resource, who it helps, and the exact keyword someone can comment to request it.",
            format: .staticPost,
            isPro: true
        )
    ]

    static let subscription = Subscription(
        id: UUID(),
        tier: .free,
        status: .active,
        renewalDate: nil,
        billingPeriod: .none,
        isTrial: false,
        canRestore: true
    )

    static let notificationPreference = NotificationPreference(
        id: UUID(),
        userId: userId,
        activityAlerts: true,
        weeklyDigest: true,
        recommendationAlerts: true
    )

    static let featureFlags = [
        FeatureFlag(id: UUID(), key: "recommendations", isEnabled: true, rolloutPercentage: 100, variant: "proposal_cards"),
        FeatureFlag(id: UUID(), key: "team_workspaces", isEnabled: false, rolloutPercentage: 0, variant: nil),
        FeatureFlag(id: UUID(), key: "csv_export", isEnabled: false, rolloutPercentage: 0, variant: "coming_soon"),
        FeatureFlag(id: UUID(), key: "hook_generator", isEnabled: false, rolloutPercentage: 0, variant: "placeholder"),
        FeatureFlag(id: UUID(), key: "onboarding_experiment", isEnabled: false, rolloutPercentage: 0, variant: "control")
    ]

    static let workspace = WorkspaceSnapshot(
        account: account,
        metrics: metrics,
        analytics: analytics,
        funnels: funnels,
        contacts: contacts,
        content: content,
        activity: activity,
        recommendations: recommendations,
        contentIdeas: contentIdeas,
        contentDrafts: contentDrafts,
        contentTemplates: contentTemplates
    )

    private static func trendPoints(days: Int, values: [Double]) -> [AnalyticsTrendPoint] {
        let step = max(1, days / max(1, values.count - 1))
        return values.enumerated().map { index, value in
            AnalyticsTrendPoint(
                id: UUID(),
                date: Calendar.current.date(
                    byAdding: .day,
                    value: -(days - 1) + (index * step),
                    to: .now
                )!,
                value: value
            )
        }
    }
}
