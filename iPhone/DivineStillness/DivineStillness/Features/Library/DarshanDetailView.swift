import SwiftUI
import UIKit

struct DarshanDetailView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showShare = false
    @State private var toast: String?

    let item: DevotionalItem

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Image(item.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .background(.black)

                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.collection.uppercased())
                            .font(.caption.bold())
                            .tracking(1)
                            .foregroundStyle(AppTheme.vermilion)
                        Text(item.deity)
                            .font(.largeTitle.bold())
                            .foregroundStyle(AppTheme.ink)
                    }

                    Text(item.mantra)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(AppTheme.plum)

                    Text(item.meaning)
                        .foregroundStyle(AppTheme.muted)

                    Divider()

                    Text(item.blessing)
                        .font(.body.italic())
                        .foregroundStyle(AppTheme.ink)

                    HStack(spacing: 10) {
                        actionButton(
                            appState.isFavorite(item) ? "heart.fill" : "heart",
                            "Favorite"
                        ) {
                            appState.toggleFavorite(item)
                        }
                        actionButton("square.and.arrow.up", "Share") {
                            showShare = true
                        }
                        actionButton("arrow.down.to.line", "Save") {
                            save()
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(AppTheme.ivory)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(item.deity)
                    .font(.headline)
            }
        }
        .overlay(alignment: .bottom) {
            if let toast {
                ToastView(message: toast)
                    .padding(.bottom, 18)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showShare) {
            if let image = UIImage(named: item.imageName) {
                ActivityView(activityItems: [image, item.shareText])
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func actionButton(
        _ icon: String,
        _ title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(AppTheme.vermilion)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(AppTheme.paper, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func save() {
        Task {
            do {
                try await WallpaperLibrary.save(imageNamed: item.imageName)
                showToast("Wallpaper saved to Photos")
            } catch {
                showToast(error.localizedDescription)
            }
        }
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { toast = nil }
        }
    }
}
