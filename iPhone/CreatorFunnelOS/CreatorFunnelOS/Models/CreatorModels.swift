import Foundation

struct CreatorAccount: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var username: String
    var displayName: String
    var followerCount: Int
    var isConnected: Bool

    var initials: String {
        displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
    }
}

struct DashboardMetric: Identifiable, Codable, Hashable, Sendable {
    enum Kind: String, Codable, Sendable {
        case conversations
        case triggeredComments
        case successfulDMs
        case leads
        case leadConversion
        case clickRate
        case activeFunnels

        var icon: String {
            switch self {
            case .conversations: "bubble.left.and.bubble.right"
            case .triggeredComments: "text.bubble"
            case .successfulDMs: "paperplane"
            case .leads: "person.crop.circle.badge.plus"
            case .leadConversion: "person.line.dotted.person.fill"
            case .clickRate: "arrow.up.right"
            case .activeFunnels: "point.3.connected.trianglepath.dotted"
            }
        }

        var tintName: String {
            switch self {
            case .conversations: "blue"
            case .triggeredComments: "indigo"
            case .successfulDMs: "teal"
            case .leads: "green"
            case .leadConversion: "mint"
            case .clickRate: "purple"
            case .activeFunnels: "orange"
            }
        }
    }

    let id: UUID
    var title: String
    var value: String
    var change: String
    var kind: Kind
}

struct Funnel: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var status: FunnelStatus
    var triggerKeyword: String
    var publicReply: String
    var directMessage: String
    var destinationLink: String
    var connectedPostIds: [UUID]
    var conversations: Int
    var leads: Int
    var createdAt: Date
    var updatedAt: Date

    var isActive: Bool {
        get { status == .active }
        set { status = newValue ? .active : .paused }
    }

    init(
        id: UUID,
        name: String,
        status: FunnelStatus? = nil,
        triggerKeyword: String,
        publicReply: String,
        directMessage: String,
        destinationLink: String,
        connectedPostIds: [UUID] = [],
        isActive: Bool,
        conversations: Int,
        leads: Int,
        createdAt: Date = .now,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.status = status ?? (isActive ? .active : .paused)
        self.triggerKeyword = triggerKeyword
        self.publicReply = publicReply
        self.directMessage = directMessage
        self.destinationLink = destinationLink
        self.connectedPostIds = connectedPostIds
        self.conversations = conversations
        self.leads = leads
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static var blank: Funnel {
        Funnel(
            id: UUID(),
            name: "",
            status: .draft,
            triggerKeyword: "",
            publicReply: "",
            directMessage: "",
            destinationLink: "",
            isActive: true,
            conversations: 0,
            leads: 0,
            updatedAt: .now
        )
    }
}

struct LeadContact: Identifiable, Codable, Hashable, Sendable {
    enum Status: String, Codable, CaseIterable, Sendable {
        case new = "New"
        case warm = "Warm"
        case converted = "Converted"
    }

    let id: UUID
    var name: String
    var instagramHandle: String
    var email: String?
    var sourceFunnel: String
    var sourcePostId: UUID?
    var sourceFunnelId: UUID?
    var status: Status
    var tags: [String]
    var notes: String
    var capturedAt: Date
    var lastEngagedAt: Date

    init(
        id: UUID,
        name: String,
        instagramHandle: String,
        email: String?,
        sourceFunnel: String,
        sourcePostId: UUID? = nil,
        sourceFunnelId: UUID? = nil,
        status: Status,
        tags: [String],
        notes: String,
        capturedAt: Date,
        lastEngagedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.instagramHandle = instagramHandle
        self.email = email
        self.sourceFunnel = sourceFunnel
        self.sourcePostId = sourcePostId
        self.sourceFunnelId = sourceFunnelId
        self.status = status
        self.tags = tags
        self.notes = notes
        self.capturedAt = capturedAt
        self.lastEngagedAt = lastEngagedAt ?? capturedAt
    }

    var initials: String {
        name
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
    }
}

struct ContentItem: Identifiable, Codable, Hashable, Sendable {
    enum Format: String, Codable, CaseIterable, Sendable {
        case reel = "Reel"
        case carousel = "Carousel"
        case story = "Story"
        case live = "Live"

        var icon: String {
            switch self {
            case .reel: "play.rectangle"
            case .carousel: "square.stack"
            case .story: "circle.dashed"
            case .live: "dot.radiowaves.left.and.right"
            }
        }
    }

    enum Status: String, Codable, CaseIterable, Sendable {
        case idea = "Idea"
        case draft = "Draft"
        case scheduled = "Scheduled"
        case published = "Published"
    }

    let id: UUID
    var title: String
    var caption: String
    var format: Format
    var status: Status
    var scheduledAt: Date
    var linkedFunnelName: String?
}

struct ActivityEvent: Identifiable, Codable, Hashable, Sendable {
    enum Kind: String, Codable, Sendable {
        case message
        case lead
        case click

        var icon: String {
            switch self {
            case .message: "paperplane.fill"
            case .lead: "person.fill.badge.plus"
            case .click: "link"
            }
        }
    }

    let id: UUID
    var title: String
    var detail: String
    var date: Date
    var kind: Kind
}

struct WorkspaceSnapshot: Codable, Sendable {
    var account: CreatorAccount?
    var metrics: [DashboardMetric]
    var analytics: AnalyticsSnapshot?
    var funnels: [Funnel]
    var contacts: [LeadContact]
    var content: [ContentItem]
    var activity: [ActivityEvent]
    var recommendations: [Recommendation]
    var contentIdeas: [ContentIdea]
    var contentDrafts: [ContentDraft]
    var contentTemplates: [ContentTemplate]

    static let empty = WorkspaceSnapshot(
        account: nil,
        metrics: [],
        analytics: nil,
        funnels: [],
        contacts: [],
        content: [],
        activity: [],
        recommendations: [],
        contentIdeas: [],
        contentDrafts: [],
        contentTemplates: []
    )
}

enum SubscriptionPlan: String, CaseIterable, Identifiable, Sendable {
    case monthly
    case yearly

    var id: String { rawValue }
    var title: String { self == .monthly ? "Monthly" : "Yearly" }
    var price: String { self == .monthly ? "$9.99" : "$79.99" }
    var cadence: String { self == .monthly ? "per month" : "per year" }
    var detail: String { self == .monthly ? "Flexible, cancel anytime" : "Save 33% compared with monthly" }
}
