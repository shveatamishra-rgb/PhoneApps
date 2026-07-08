import AVKit
import Photos
import SwiftUI

// MARK: - Category card (home grid)

struct CategoryCard: View {
    let title: String
    let systemImage: String
    let detail: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(tint)
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Screenshot swipe triage (free)

/// Tinder-style triage: swipe left to queue for deletion, right to keep.
/// Free on purpose; it proves the app works and builds the delete habit.
struct ScreenshotsSwipeView: View {
    @ObservedObject var viewModel: ScanViewModel

    @State private var remaining: [ScannedPhoto] = []
    @State private var toDelete: [ScannedPhoto] = []
    @State private var keptCount = 0
    @State private var dragOffset = CGSize.zero
    @State private var isDeleting = false
    @State private var didLoad = false

    var body: some View {
        VStack(spacing: 16) {
            if let current = remaining.first {
                Text("\(remaining.count) to review")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                swipeCard(for: current)

                HStack(spacing: 40) {
                    Button {
                        swipe(delete: true)
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.red)
                    }
                    Button {
                        swipe(delete: false)
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.green)
                    }
                }
                .padding(.bottom, 4)
            } else if didLoad {
                ContentUnavailableView(
                    toDelete.isEmpty && keptCount == 0 ? "No screenshots found" : "All reviewed",
                    systemImage: toDelete.isEmpty && keptCount == 0 ? "camera.viewfinder" : "checkmark.circle",
                    description: Text(toDelete.isEmpty
                        ? "Run a scan from the home screen to refresh this list."
                        : "Ready to delete \(toDelete.count) screenshots.")
                )
            }

            if !toDelete.isEmpty {
                Button {
                    applyDeletions()
                } label: {
                    HStack {
                        if isDeleting {
                            ProgressView()
                        } else {
                            Image(systemName: "trash")
                        }
                        Text("Delete \(toDelete.count) (\(formatBytes(toDelete.reduce(0) { $0 + ($1.byteSize ?? 0) })))")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(isDeleting)
                .padding(.horizontal)

                Text("Recoverable in Recently Deleted for 30 days.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .navigationTitle("Screenshots")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !didLoad else { return }
            remaining = viewModel.screenshots
            didLoad = true
        }
    }

    private func swipeCard(for photo: ScannedPhoto) -> some View {
        AssetPreviewImage(assetIdentifier: photo.localIdentifier)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(alignment: .topLeading) {
                if dragOffset.width < -30 {
                    swipeBadge("DELETE", color: .red)
                }
            }
            .overlay(alignment: .topTrailing) {
                if dragOffset.width > 30 {
                    swipeBadge("KEEP", color: .green)
                }
            }
            .offset(dragOffset)
            .rotationEffect(.degrees(Double(dragOffset.width) / 24))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        if value.translation.width < -100 {
                            swipe(delete: true)
                        } else if value.translation.width > 100 {
                            swipe(delete: false)
                        } else {
                            withAnimation(.spring(duration: 0.3)) {
                                dragOffset = .zero
                            }
                        }
                    }
            )
    }

    private func swipeBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.title3.bold())
            .foregroundStyle(color)
            .padding(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color, lineWidth: 3))
            .rotationEffect(.degrees(color == .red ? -12 : 12))
            .padding(18)
    }

    private func swipe(delete: Bool) {
        guard let current = remaining.first else { return }
        if delete {
            toDelete.append(current)
        } else {
            keptCount += 1
        }
        withAnimation(.easeOut(duration: 0.2)) {
            dragOffset = CGSize(width: delete ? -600 : 600, height: 0)
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            remaining.removeFirst()
            dragOffset = .zero
        }
    }

    private func applyDeletions() {
        isDeleting = true
        Task {
            let deleted = await viewModel.deleteAssets(
                withIdentifiers: Set(toDelete.map(\.localIdentifier))
            )
            toDelete.removeAll { deleted.contains($0.localIdentifier) }
            isDeleting = false
        }
    }
}

// MARK: - Blurry photos (Pro cleanup)

struct BlurryPhotosView: View {
    @ObservedObject var viewModel: ScanViewModel
    @ObservedObject private var store = GigaBackStore.shared

    @State private var selected: Set<String> = []
    @State private var showPaywall = false
    @State private var isDeleting = false
    @State private var previewPhoto: ScannedPhoto?

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 4)]

    var body: some View {
        ScrollView {
            if viewModel.blurryPhotos.isEmpty {
                ContentUnavailableView(
                    "No blurry photos found",
                    systemImage: "camera.metering.none",
                    description: Text("Photos with almost no sharp detail appear here after a scan.")
                )
                .padding(.top, 60)
            } else {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(viewModel.blurryPhotos) { photo in
                        selectableThumbnail(photo)
                    }
                }
                .padding(4)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Blurry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.blurryPhotos.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(selected.count == viewModel.blurryPhotos.count ? "Deselect All" : "Select All") {
                        if selected.count == viewModel.blurryPhotos.count {
                            selected = []
                        } else {
                            selected = Set(viewModel.blurryPhotos.map(\.localIdentifier))
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !selected.isEmpty {
                deleteBar
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(reclaimableBytes: viewModel.reclaimableBytes)
        }
        .sheet(item: $previewPhoto) { photo in
            PhotoPreviewSheet(photo: photo)
        }
    }

    private func selectableThumbnail(_ photo: ScannedPhoto) -> some View {
        let isSelected = selected.contains(photo.localIdentifier)
        return PhotoThumbnailView(photo: photo)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 3)
            )
            .onTapGesture {
                previewPhoto = photo
            }
            .overlay(alignment: .bottomTrailing) {
                // Separate tap target: the circle selects, the photo previews.
                Button {
                    if isSelected {
                        selected.remove(photo.localIdentifier)
                    } else {
                        selected.insert(photo.localIdentifier)
                    }
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.accentColor : .white)
                        .shadow(radius: 2)
                        .padding(6)
                }
                .buttonStyle(.plain)
            }
    }

    private var deleteBar: some View {
        Button {
            guard store.isPro else {
                showPaywall = true
                return
            }
            isDeleting = true
            Task {
                let deleted = await viewModel.deleteAssets(withIdentifiers: selected)
                selected.subtract(deleted)
                isDeleting = false
            }
        } label: {
            HStack {
                if isDeleting {
                    ProgressView()
                } else {
                    Image(systemName: store.isPro ? "trash" : "lock.fill")
                }
                Text("Delete \(selected.count) Blurry Photos")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .disabled(isDeleting)
        .padding()
        .background(.bar)
    }
}

// MARK: - Large videos (Pro cleanup)

struct LargeVideosView: View {
    @ObservedObject var viewModel: ScanViewModel
    @ObservedObject private var store = GigaBackStore.shared

    @State private var selected: Set<String> = []
    @State private var showPaywall = false
    @State private var isDeleting = false
    @State private var previewVideo: ScannedVideo?

    var body: some View {
        List {
            if viewModel.largeVideos.isEmpty {
                ContentUnavailableView(
                    "No large videos found",
                    systemImage: "video",
                    description: Text("Videos over \(formatBytes(LibraryCleanupScanner.largeVideoThresholdBytes)) appear here after a scan.")
                )
            } else {
                ForEach(viewModel.largeVideos) { video in
                    videoRow(video)
                }
            }
        }
        .navigationTitle("Large Videos")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if !selected.isEmpty {
                deleteBar
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(reclaimableBytes: viewModel.reclaimableBytes)
        }
        .sheet(item: $previewVideo) { video in
            VideoPreviewSheet(video: video)
        }
    }

    private func videoRow(_ video: ScannedVideo) -> some View {
        let isSelected = selected.contains(video.localIdentifier)
        return HStack(spacing: 12) {
            Button {
                previewVideo = video
            } label: {
                AssetThumbnail(assetIdentifier: video.localIdentifier)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        Image(systemName: "play.fill")
                            .font(.body)
                            .foregroundStyle(.white)
                            .shadow(radius: 3)
                    }
                    .overlay(alignment: .bottomLeading) {
                        Text(video.durationDescription)
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 4))
                            .padding(3)
                    }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(video.filename)
                    .font(.subheadline)
                    .lineLimit(1)
                if let byteSize = video.byteSize {
                    Text(formatBytes(byteSize))
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)
                }
                if let date = video.creationDate {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelected {
                selected.remove(video.localIdentifier)
            } else {
                selected.insert(video.localIdentifier)
            }
        }
    }

    private var deleteBar: some View {
        let selectedBytes = viewModel.largeVideos
            .filter { selected.contains($0.localIdentifier) }
            .reduce(Int64(0)) { $0 + ($1.byteSize ?? 0) }

        return Button {
            guard store.isPro else {
                showPaywall = true
                return
            }
            isDeleting = true
            Task {
                let deleted = await viewModel.deleteAssets(withIdentifiers: selected)
                selected.subtract(deleted)
                isDeleting = false
            }
        } label: {
            HStack {
                if isDeleting {
                    ProgressView()
                } else {
                    Image(systemName: store.isPro ? "trash" : "lock.fill")
                }
                Text("Delete \(selected.count) Videos (\(formatBytes(selectedBytes)))")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .disabled(isDeleting)
        .padding()
        .background(.bar)
    }
}

// MARK: - Shared asset image loaders

/// Small square thumbnail for any library asset (used for video rows).
struct AssetThumbnail: View {
    let assetIdentifier: String
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color(.tertiarySystemFill)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "video")
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: assetIdentifier) {
            image = await ThumbnailLoader.shared.thumbnail(forAssetIdentifier: assetIdentifier)
        }
    }
}

/// Full-screen photo preview (blurry grid, and anywhere a single photo needs inspection).
struct PhotoPreviewSheet: View {
    let photo: ScannedPhoto
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AssetPreviewImage(assetIdentifier: photo.localIdentifier)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .navigationTitle(photo.filename)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

/// Plays a library video via AVKit. The player item streams from the local
/// asset (or the user's own iCloud) and nothing is exported or copied.
struct VideoPreviewSheet: View {
    let video: ScannedVideo
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var failed = false

    var body: some View {
        NavigationStack {
            Group {
                if let player {
                    VideoPlayer(player: player)
                        .onAppear { player.play() }
                        .onDisappear { player.pause() }
                } else if failed {
                    ContentUnavailableView(
                        "Could not load video",
                        systemImage: "video.slash",
                        description: Text("Check your connection if this video is stored in iCloud.")
                    )
                } else {
                    ProgressView("Loading video")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .navigationTitle(video.filename)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                if let item = await Self.playerItem(for: video.localIdentifier) {
                    player = AVPlayer(playerItem: item)
                } else {
                    failed = true
                }
            }
        }
    }

    private static func playerItem(for identifier: String) async -> AVPlayerItem? {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .automatic

            var didResume = false
            PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { item, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                let isFinal = item != nil
                    || info?[PHImageErrorKey] != nil
                    || (info?[PHImageCancelledKey] as? Bool) == true
                    || !isDegraded
                guard isFinal, !didResume else { return }
                didResume = true
                continuation.resume(returning: item)
            }
        }
    }
}

/// Large preview for the swipe card.
struct AssetPreviewImage: View {
    let assetIdentifier: String
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color(.secondarySystemBackground)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
            }
        }
        .task(id: assetIdentifier) {
            image = nil
            image = await Self.load(assetIdentifier)
        }
    }

    private static func load(_ identifier: String) async -> UIImage? {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true

            var didResume = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 1200, height: 1200),
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                guard !didResume else { return }
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                let isFinal = info?[PHImageErrorKey] != nil
                    || (info?[PHImageCancelledKey] as? Bool) == true
                    || !isDegraded
                guard isFinal else { return }
                didResume = true
                continuation.resume(returning: image)
            }
        }
    }
}
