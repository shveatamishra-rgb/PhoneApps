import SwiftUI
import UIKit

/// Loads the bundled bilingual katha (extracted from the website's story builders).
enum StoryCatalog {
    static let all: [Story] = {
        guard let asset = NSDataAsset(name: "stories"),
              let decoded = try? JSONDecoder().decode([Story].self, from: asset.data)
        else { return [] }
        return decoded
    }()
}

/// A rich, deity-appropriate cover gradient (no bundled art needed; the katha are
/// text-forward and read like an elegant book).
private func deityGradient(_ deity: String) -> [Color] {
    switch deity {
    case "shiva":   return [AppTheme.teal, AppTheme.plum]
    case "vishnu":  return [AppTheme.marigold, AppTheme.vermilion]
    case "krishna": return [AppTheme.plum, AppTheme.teal]
    case "devi":    return [AppTheme.vermilion, AppTheme.plum]
    case "ganesha": return [AppTheme.marigold, AppTheme.plum]
    case "hanuman": return [AppTheme.vermilion, AppTheme.marigold]
    default:        return [AppTheme.plum, AppTheme.teal]
    }
}

private let kathaCream = Color(red: 0.97, green: 0.95, blue: 0.89)

// MARK: - List

struct KathaView: View {
    @EnvironmentObject private var store: StoreManager
    @EnvironmentObject private var loc: LocalizationManager
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(loc.s("Timeless tales of the gods, each with a moral for daily life.",
                               "देवताओं की कालजयी कथाएँ, हर एक में जीवन का एक सार।"))
                        .font(.system(.subheadline, design: .serif)).italic()
                        .foregroundStyle(AppTheme.muted)
                        .padding(.horizontal, 16)
                        .padding(.top, 2)

                    ForEach(StoryCatalog.all) { story in
                        cell(story)
                    }
                }
                .padding(.bottom, 30)
            }
            .devotionalBackground()
            .navigationTitle(loc.s("Katha", "कथा"))
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    @ViewBuilder
    private func cell(_ story: Story) -> some View {
        let locked = story.isPremium && !store.hasPro
        Group {
            if locked {
                Button { showPaywall = true } label: { StoryCard(story: story, locked: true) }
            } else {
                NavigationLink { KathaDetailView(story: story) } label: { StoryCard(story: story, locked: false) }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
}

private struct StoryCard: View {
    @EnvironmentObject private var loc: LocalizationManager
    let story: Story
    let locked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                ZStack {
                    LinearGradient(colors: deityGradient(story.deity),
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                    if let ui = UIImage(named: story.id) {
                        Image(uiImage: ui).resizable().scaledToFill()
                    }
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .clipped()

                LinearGradient(colors: [.black.opacity(0.65), .black.opacity(0.05), .clear],
                               startPoint: .bottom, endPoint: .top)
                    .frame(height: 150)

                VStack(alignment: .leading, spacing: 4) {
                    Text(story.eyebrow(loc.lang).uppercased())
                        .font(.caption2.weight(.bold)).tracking(1.3)
                        .foregroundStyle(kathaCream.opacity(0.95))
                    Text(story.title(loc.lang))
                        .font(.system(.title2, design: .serif).weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }
                .padding(14)
                .shadow(color: .black.opacity(0.6), radius: 6)
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .topTrailing) {
                if locked {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill").font(.caption)
                        ProBadge()
                    }
                    .foregroundStyle(.white)
                    .padding(12)
                }
            }

            HStack(alignment: .top, spacing: 10) {
                Text(story.intro(loc.lang))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(3)
                Spacer(minLength: 4)
                Image(systemName: locked ? "lock.fill" : "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(locked ? AppTheme.muted : AppTheme.vermilion)
                    .padding(.top, 2)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(AppTheme.paper)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.black.opacity(0.06), lineWidth: 1))
        .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Reader

struct KathaDetailView: View {
    @EnvironmentObject private var loc: LocalizationManager
    @State private var showShare = false
    let story: Story

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    ZStack {
                        LinearGradient(colors: deityGradient(story.deity),
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                        if let ui = UIImage(named: story.id) {
                            Image(uiImage: ui).resizable().scaledToFill()
                        }
                    }
                    .frame(height: 260)
                    .frame(maxWidth: .infinity)
                    .clipped()

                    LinearGradient(colors: [.black.opacity(0.6), .black.opacity(0.05), .clear],
                                   startPoint: .bottom, endPoint: .center)
                        .frame(height: 260)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(story.eyebrow(loc.lang).uppercased())
                            .font(.caption.weight(.bold)).tracking(1.4)
                            .foregroundStyle(kathaCream.opacity(0.95))
                        Text(story.title(loc.lang))
                            .font(.system(size: 38, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                            .lineLimit(3)
                    }
                    .padding(20)
                    .shadow(color: .black.opacity(0.6), radius: 8)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 18) {
                    Text(story.intro(loc.lang))
                        .font(.system(.title3, design: .serif)).italic()
                        .foregroundStyle(AppTheme.ink)

                    ForEach(Array(story.body(loc.lang).enumerated()), id: \.offset) { _, para in
                        Text(para)
                            .font(.system(.body, design: .serif))
                            .lineSpacing(6)
                            .foregroundStyle(AppTheme.ink.opacity(0.9))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(loc.s("The Moral", "इस कथा का अर्थ").uppercased())
                            .font(.caption2.weight(.bold)).tracking(1.4)
                            .foregroundStyle(AppTheme.marigold)
                        Text(story.moral(loc.lang))
                            .font(.callout)
                            .lineSpacing(4)
                            .foregroundStyle(AppTheme.ink.opacity(0.9))
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.paper)
                    .overlay(alignment: .leading) {
                        Rectangle().fill(AppTheme.marigold).frame(width: 3)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(20)
            }
        }
        .background(AppTheme.ivory)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(story.title(loc.lang)).font(.headline)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showShare = true } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showShare) {
            ActivityView(activityItems: [shareText])
                .presentationDetents([.medium, .large])
        }
    }

    private var shareText: String {
        let footer = loc.s("Read more katha in the Bhakti Angan app.",
                           "भक्ति आँगन ऐप में और कथाएँ पढ़ें।")
        return "\(story.title(loc.lang))\n\n\(story.intro(loc.lang))\n\n\(story.moral(loc.lang))\n\n\(footer)"
    }
}
