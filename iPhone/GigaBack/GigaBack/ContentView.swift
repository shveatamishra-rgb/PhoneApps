import Photos
import PhotosUI
import ImageIO
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = ScanViewModel()
    @ObservedObject private var store = GigaBackStore.shared
    @State private var isShowingFileImporter = false
    @State private var showPaywall = false
    @State private var isSmartCleaning = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    authorizationSection
                    heroSection
                    scanControls
                    if viewModel.summary != nil {
                        categoryGrid
                    }
                    if let summary = viewModel.summary {
                        SummaryView(summary: summary)
                    }
                }
                .padding(18)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("GigaBack")
            .toolbar {
                if viewModel.hasLimitedAccess {
                    Button("Manage Access") {
                        viewModel.presentLimitedLibraryPicker()
                    }
                }
            }
            .task {
                await viewModel.refreshAuthorization()
                viewModel.refreshImportedCount()
            }
            .fileImporter(
                isPresented: $isShowingFileImporter,
                allowedContentTypes: [.image],
                allowsMultipleSelection: true
            ) { result in
                Task {
                    await viewModel.importImages(result)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(reclaimableBytes: viewModel.reclaimableBytes)
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.summary != nil {
                let reclaimable = viewModel.reclaimableBytes
                VStack(alignment: .leading, spacing: 4) {
                    Text(reclaimable > 0 ? formatBytes(reclaimable) : "All clean")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(reclaimable > 0 ? Color.accentColor : .green)
                    Text(reclaimable > 0
                        ? "reclaimable from duplicates and similar photos"
                        : "No duplicate space left to reclaim.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if reclaimable > 0 {
                    Button {
                        smartClean()
                    } label: {
                        HStack {
                            if isSmartCleaning {
                                ProgressView()
                            } else {
                                Image(systemName: store.isPro ? "wand.and.stars" : "lock.fill")
                            }
                            Text("Smart Clean \(formatBytes(reclaimable))")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSmartCleaning || viewModel.isScanning)

                    Text("Keeps the best photo of every group. Deleted items stay in Recently Deleted for 30 days.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Label("Get your gigabytes back", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)

                Text("GigaBack finds duplicates, similar shots, screenshots, blurry photos, and large videos wasting space. Everything runs on your iPhone; photos never leave your device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sectionSurface()
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
            NavigationLink {
                DuplicateGroupsDetailView(
                    viewModel: viewModel,
                    kinds: [.bytes, .pixels],
                    title: "Duplicates",
                    allowBulkSelection: true
                )
            } label: {
                CategoryCard(
                    title: "Duplicates",
                    systemImage: "doc.on.doc",
                    detail: categoryDetail(groupCount: viewModel.duplicateGroups.count),
                    tint: .blue
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                DuplicateGroupsDetailView(
                    viewModel: viewModel,
                    kinds: [.visual],
                    title: "Similar",
                    allowBulkSelection: true
                )
            } label: {
                CategoryCard(
                    title: "Similar",
                    systemImage: "photo.on.rectangle.angled",
                    detail: categoryDetail(groupCount: viewModel.similarGroups.count),
                    tint: .indigo
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                ScreenshotsSwipeView(viewModel: viewModel)
            } label: {
                CategoryCard(
                    title: "Screenshots",
                    systemImage: "camera.viewfinder",
                    detail: viewModel.screenshots.isEmpty
                        ? "None found"
                        : "\(viewModel.screenshots.count) · \(formatBytes(viewModel.screenshotsBytes))",
                    tint: .teal
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                BlurryPhotosView(viewModel: viewModel)
            } label: {
                CategoryCard(
                    title: "Blurry",
                    systemImage: "camera.metering.none",
                    detail: viewModel.blurryPhotos.isEmpty
                        ? "None found"
                        : "\(viewModel.blurryPhotos.count) photos",
                    tint: .orange
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                LargeVideosView(viewModel: viewModel)
            } label: {
                CategoryCard(
                    title: "Large Videos",
                    systemImage: "video",
                    detail: viewModel.largeVideos.isEmpty
                        ? "None found"
                        : "\(viewModel.largeVideos.count) · \(formatBytes(viewModel.largeVideosBytes))",
                    tint: .pink
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func categoryDetail(groupCount: Int) -> String {
        groupCount == 0 ? "None found" : "\(groupCount) groups"
    }

    private func smartClean() {
        guard store.isPro else {
            showPaywall = true
            return
        }
        isSmartCleaning = true
        Task {
            viewModel.selectAllExtras()
            await viewModel.deleteSelectedPhotos()
            isSmartCleaning = false
        }
    }

    @ViewBuilder
    private var authorizationSection: some View {
        if !viewModel.hasPhotoAccess {
            VStack(alignment: .leading, spacing: 12) {
                Text("Photos access is needed before scanning.")
                    .font(.headline)

                Text(viewModel.authorizationMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // 5.1.1(iv): pre-permission buttons must not say "Allow"; the
                // system prompt is where the user grants access.
                Button("Continue") {
                    Task {
                        await viewModel.requestAuthorization()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .sectionSurface()
        } else if viewModel.hasLimitedAccess {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Limited Photos access is active.")
                        .font(.headline)

                    Text("The scan will include only the photos you have selected for this app, plus any imported files.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .sectionSurface()
        }
    }

    private var scanControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                if viewModel.isScanning {
                    Button(role: .destructive) {
                        viewModel.stopScan()
                    } label: {
                        Label("Stop", systemImage: "stop.circle")
                    }
                } else {
                    Button {
                        viewModel.startScan()
                    } label: {
                        Label("Scan", systemImage: "sparkle.magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canScan)
                }

                Spacer()

                Text(viewModel.status)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Button {
                        isShowingFileImporter = true
                    } label: {
                        Label("Import Images", systemImage: "square.and.arrow.down")
                    }
                    .disabled(viewModel.isScanning)

                    if viewModel.importedImageCount > 0 {
                        Text("\(viewModel.importedImageCount) imported")
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        Button("Clear Imports") {
                            Task {
                                await viewModel.clearImportedImages()
                            }
                        }
                        .font(.callout)
                        .disabled(viewModel.isScanning)
                    }
                }

                Text("For WhatsApp images that are not saved to Photos, share or save them to Files first, then import them here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ProgressView(value: viewModel.progress)
                .opacity(viewModel.isScanning ? 1 : 0)
        }
        .sectionSurface()
    }

}

/// Group-based results screen, shared by Duplicates (bytes + pixels) and Similar (visual).
///
/// Free vs Pro: reviewing groups and deleting one group at a time is free (the app
/// must visibly work before asking for money). Selecting extras across every group
/// at once is a Pro convenience.
struct DuplicateGroupsDetailView: View {
    @ObservedObject var viewModel: ScanViewModel
    @ObservedObject private var store = GigaBackStore.shared
    let kinds: Set<DuplicateKind>
    let title: String
    let allowBulkSelection: Bool

    @State private var previewRequest: PreviewRequest?
    @State private var showPaywall = false

    init(viewModel: ScanViewModel, kinds: Set<DuplicateKind>, title: String, allowBulkSelection: Bool) {
        self.viewModel = viewModel
        self.kinds = kinds
        self.title = title
        self.allowBulkSelection = allowBulkSelection
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if filteredGroups.isEmpty {
                    ContentUnavailableView(
                        "Nothing here",
                        systemImage: "checkmark.circle",
                        description: Text("No \(title.lowercased()) found in the last scan.")
                    )
                } else {
                    selectionBar

                    ForEach(sections) { section in
                        DuplicateSectionView(
                            section: section,
                            selectedPhotoIDs: viewModel.selectedForDeletion,
                            onPhotoSelection: viewModel.setDeletionSelection,
                            onSelectExtras: viewModel.selectExtras,
                            onClearGroup: viewModel.clearGroupSelection,
                            onPreview: { group, photo in
                                previewRequest = PreviewRequest(group: group, initialPhotoID: photo.localIdentifier)
                            }
                        )
                    }
                }
            }
            .padding(18)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $previewRequest) { request in
            ImageCompareView(
                request: request,
                selectedPhotoIDs: $viewModel.selectedForDeletion,
                onSelectionChange: viewModel.setDeletionSelection
            )
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(reclaimableBytes: viewModel.reclaimableBytes)
        }
    }

    private var selectionBar: some View {
        HStack(spacing: 12) {
            Text("\(selectedCount) selected")
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()

            if selectedCount == 0 {
                if allowBulkSelection {
                    Button {
                        if store.isPro {
                            for group in filteredGroups {
                                viewModel.selectExtras(group)
                            }
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Label("Select All Extras", systemImage: store.isPro ? "checklist" : "lock.fill")
                    }
                }
            } else {
                Button("Clear") {
                    viewModel.clearDeletionSelection()
                }

                Button(role: .destructive) {
                    Task {
                        await viewModel.deleteSelectedPhotos()
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .sectionSurface()
    }

    private var filteredGroups: [DuplicateGroup] {
        viewModel.groups.filter { kinds.contains($0.kind) }
    }

    private var selectedCount: Int {
        let visible = Set(filteredGroups.flatMap { $0.photos.map(\.localIdentifier) })
        return viewModel.selectedForDeletion.intersection(visible).count
    }

    private var sections: [DuplicateResultSection] {
        DuplicateKind.allCases.compactMap { kind in
            guard kinds.contains(kind) else { return nil }
            let groups = filteredGroups.filter { $0.kind == kind }
            guard !groups.isEmpty else { return nil }
            return DuplicateResultSection(kind: kind, groups: groups)
        }
    }
}

private struct PreviewRequest: Identifiable {
    let id = UUID()
    let group: DuplicateGroup
    let initialPhotoID: String
}

private struct SummaryView: View {
    let summary: ScanSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SummaryMetric(label: "Groups", value: "\(summary.groupCount)", systemImage: "rectangle.stack")
                SummaryMetric(label: "Extras", value: "\(summary.duplicatePhotoCount)", systemImage: "doc.on.doc")
            }

            HStack {
                SummaryMetric(label: "Scanned", value: "\(summary.scannedPhotoCount)", systemImage: "checkmark.circle")
                SummaryMetric(label: "Skipped", value: "\(summary.skippedPhotoCount)", systemImage: "exclamationmark.triangle")
            }

            if summary.wasStopped {
                Label("Stopped early. Results are partial.", systemImage: "stop.circle")
                    .font(.callout)
                    .foregroundStyle(.orange)
            }
        }
        .sectionSurface()
    }
}

private struct SummaryMetric: View {
    let label: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct EmptyStateView: View {
    @ObservedObject var viewModel: ScanViewModel

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: viewModel.isScanning ? "magnifyingglass" : "photo.on.rectangle")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .sectionSurface()
    }

    private var title: String {
        if viewModel.isScanning {
            return "Scanning images"
        }
        if viewModel.summary != nil {
            return "No duplicates found"
        }
        return "Ready when you are"
    }

    private var message: String {
        if viewModel.isScanning {
            return viewModel.status
        }
        if let summary = viewModel.summary {
            return "Scanned \(summary.scannedPhotoCount) images. \(summary.skippedPhotoCount) images could not be read."
        }
        if viewModel.importedImageCount > 0 {
            return "Use All mode to compare Photos with your imported images in one pass."
        }
        return "Use All mode to check byte matches, exact pixels, and same-looking copies in one pass. Import files to include app exports."
    }
}

private struct DuplicateResultSection: Identifiable {
    let kind: DuplicateKind
    let groups: [DuplicateGroup]

    var id: DuplicateKind { kind }

    var imageCount: Int {
        groups.reduce(0) { $0 + $1.photos.count }
    }
}

private struct DuplicateSectionView: View {
    let section: DuplicateResultSection
    let selectedPhotoIDs: Set<String>
    let onPhotoSelection: (ScannedPhoto, Bool) -> Void
    let onSelectExtras: (DuplicateGroup) -> Void
    let onClearGroup: (DuplicateGroup) -> Void
    let onPreview: (DuplicateGroup, ScannedPhoto) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: section.kind.systemImage)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 3) {
                    Text(section.kind.sectionTitle)
                        .font(.headline)

                    Text("\(section.groups.count) sets - \(section.imageCount) images. \(section.kind.sectionDescription)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            ForEach(Array(section.groups.enumerated()), id: \.element.id) { index, group in
                DuplicateGroupView(
                    groupNumber: index + 1,
                    group: group,
                    selectedPhotoIDs: selectedPhotoIDs,
                    onPhotoSelection: onPhotoSelection,
                    onSelectExtras: onSelectExtras,
                    onClearGroup: onClearGroup,
                    onPreview: onPreview
                )
            }
        }
        .sectionSurface()
    }
}

private struct DuplicateGroupView: View {
    let groupNumber: Int
    let group: DuplicateGroup
    let selectedPhotoIDs: Set<String>
    let onPhotoSelection: (ScannedPhoto, Bool) -> Void
    let onSelectExtras: (DuplicateGroup) -> Void
    let onClearGroup: (DuplicateGroup) -> Void
    let onPreview: (DuplicateGroup, ScannedPhoto) -> Void

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 10) {
                ForEach(group.photos) { photo in
                    PhotoRow(
                        photo: photo,
                        isSelected: selectedPhotoIDs.contains(photo.localIdentifier),
                        onSelectionChange: onPhotoSelection,
                        onPreview: {
                            onPreview(group, photo)
                        }
                    )
                }
            }
            .padding(.top, 10)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Duplicate set \(groupNumber)")
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Text("\(group.photos.count) images")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Button("Select Extras") {
                        onSelectExtras(group)
                    }
                    .font(.caption)

                    Button("Clear Set") {
                        onClearGroup(group)
                    }
                    .font(.caption)

                    if let firstPhoto = group.photos.first {
                        Button("Compare") {
                            onPreview(group, firstPhoto)
                        }
                        .font(.caption)
                    }

                    Spacer()
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct PhotoRow: View {
    let photo: ScannedPhoto
    let isSelected: Bool
    let onSelectionChange: (ScannedPhoto, Bool) -> Void
    let onPreview: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onSelectionChange(photo, !isSelected)
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isSelected ? "Deselect photo" : "Select photo")

            Button(action: onPreview) {
                PhotoThumbnailView(photo: photo)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open full image")

            VStack(alignment: .leading, spacing: 4) {
                Text(photo.filename)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Text(photoSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
    }

    private var photoSubtitle: String {
        let size = photo.byteSize.map(formatBytes) ?? "Size unknown"
        let date = photo.creationDate.map(Self.dateFormatter.string) ?? "No date"
        return "\(photo.sourceTitle) - \(size) - \(photo.pixelDescription) - \(date)"
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

struct PhotoThumbnailView: View {
    let photo: ScannedPhoto
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.tertiarySystemGroupedBackground))

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 58, height: 58)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .task(id: photo.localIdentifier) {
            image = await ThumbnailLoader.shared.thumbnail(for: photo)
        }
    }
}

private struct ImageCompareView: View {
    let request: PreviewRequest
    @Binding var selectedPhotoIDs: Set<String>
    let onSelectionChange: (ScannedPhoto, Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoID: String

    init(
        request: PreviewRequest,
        selectedPhotoIDs: Binding<Set<String>>,
        onSelectionChange: @escaping (ScannedPhoto, Bool) -> Void
    ) {
        self.request = request
        _selectedPhotoIDs = selectedPhotoIDs
        self.onSelectionChange = onSelectionChange
        _selectedPhotoID = State(initialValue: request.initialPhotoID)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $selectedPhotoID) {
                    ForEach(request.group.photos) { photo in
                        FullImagePreview(photo: photo)
                            .tag(photo.localIdentifier)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .background(.black)

                if let selectedPhoto {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(selectedPhoto.filename)
                            .font(.headline)
                            .lineLimit(2)

                        Text("\(selectedPhoto.sourceTitle) - \(selectedPhoto.byteSize.map(formatBytes) ?? "Size unknown") - \(selectedPhoto.pixelDescription)")
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        HStack {
                            Button(selectedPhotoIDs.contains(selectedPhoto.localIdentifier) ? "Deselect" : "Select for Delete") {
                                onSelectionChange(
                                    selectedPhoto,
                                    !selectedPhotoIDs.contains(selectedPhoto.localIdentifier)
                                )
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(selectedPhotoIDs.contains(selectedPhoto.localIdentifier) ? .gray : .red)

                            Spacer()

                            Text("\(selectedIndex + 1) of \(request.group.photos.count)")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle(request.group.kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var selectedPhoto: ScannedPhoto? {
        request.group.photos.first { $0.localIdentifier == selectedPhotoID }
    }

    private var selectedIndex: Int {
        request.group.photos.firstIndex { $0.localIdentifier == selectedPhotoID } ?? 0
    }
}

private struct FullImagePreview: View {
    let photo: ScannedPhoto
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(10)
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .task(id: photo.localIdentifier) {
            image = await FullImageLoader.shared.image(for: photo)
        }
    }
}

private actor FullImageLoader {
    static let shared = FullImageLoader()
    private let cache = NSCache<NSString, UIImage>()

    func image(for photo: ScannedPhoto) async -> UIImage? {
        let key = photo.localIdentifier as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let image: UIImage?
        if let fileURL = photo.fileURL {
            image = UIImage(contentsOfFile: fileURL.path)
        } else if let photoLibraryIdentifier = photo.photoLibraryIdentifier,
                  let asset = PHAsset.fetchAssets(withLocalIdentifiers: [photoLibraryIdentifier], options: nil).firstObject {
            image = await requestPreview(for: asset)
        } else {
            image = nil
        }

        if let image {
            cache.setObject(image, forKey: key)
        }
        return image
    }

    private func requestPreview(for asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true

            var didResume = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 1800, height: 1800),
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

actor ThumbnailLoader {
    static let shared = ThumbnailLoader()
    private let cache = NSCache<NSString, UIImage>()

    /// Thumbnail for any library asset (photo or video) by local identifier.
    func thumbnail(forAssetIdentifier identifier: String) async -> UIImage? {
        let key = identifier as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject else {
            return nil
        }
        let image = await requestThumbnail(for: asset)
        if let image {
            cache.setObject(image, forKey: key)
        }
        return image
    }

    func thumbnail(for photo: ScannedPhoto) async -> UIImage? {
        let key = photo.localIdentifier as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let image: UIImage?
        if let fileURL = photo.fileURL {
            image = Self.fileThumbnail(for: fileURL)
        } else if let photoLibraryIdentifier = photo.photoLibraryIdentifier,
                  let asset = PHAsset.fetchAssets(withLocalIdentifiers: [photoLibraryIdentifier], options: nil).firstObject {
            image = await requestThumbnail(for: asset)
        } else {
            image = nil
        }

        if let image {
            cache.setObject(image, forKey: key)
        }
        return image
    }

    private static func fileThumbnail(for url: URL) -> UIImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: 160
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    private func requestThumbnail(for asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true

            var didResume = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 160, height: 160),
                contentMode: .aspectFill,
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

@MainActor
final class ScanViewModel: ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @Published var mode: ScanMode = .all
    @Published var isScanning = false
    @Published var progress = 0.0
    @Published var status = "Ready"
    @Published var groups: [DuplicateGroup] = []
    @Published var summary: ScanSummary?
    @Published var selectedForDeletion: Set<String> = []
    @Published var importedImageCount = 0
    @Published var blurryPhotos: [ScannedPhoto] = []
    @Published var screenshots: [ScannedPhoto] = []
    @Published var largeVideos: [ScannedVideo] = []

    private var scanTask: Task<Void, Never>?
    private var cancellationToken: ScanCancellationToken?

    var hasPhotoAccess: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }

    var canScan: Bool {
        hasPhotoAccess || importedImageCount > 0
    }

    var hasLimitedAccess: Bool {
        authorizationStatus == .limited
    }

    var authorizationMessage: String {
        switch authorizationStatus {
        case .notDetermined:
            return "The scan stays on-device and checks the photos you allow. You can also import image files without granting Photos access."
        case .denied, .restricted:
            return "Photos access is disabled. Enable it in Settings to scan this iPhone, or import image files from Files."
        case .limited:
            return "Limited access is enabled."
        case .authorized:
            return "Photos access is enabled."
        @unknown default:
            return "Photos access is unavailable."
        }
    }

    func refreshAuthorization() async {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func refreshImportedCount() {
        importedImageCount = ImportedImageStore.importedImageURLs().count
    }

    func requestAuthorization() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status
    }

    func presentLimitedLibraryPicker() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let controller = scene.windows.first(where: \.isKeyWindow)?.rootViewController else {
            return
        }
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: controller)
    }

    func startScan() {
        guard canScan, !isScanning else { return }

        scanTask?.cancel()
        cancellationToken?.cancel()

        let token = ScanCancellationToken()
        cancellationToken = token
        isScanning = true
        progress = 0
        status = "Starting scan..."
        groups = []
        summary = nil
        selectedForDeletion = []
        blurryPhotos = []
        screenshots = []
        largeVideos = []

        let selectedMode = mode
        let importedImageURLs = ImportedImageStore.importedImageURLs()
        let libraryAccessGranted = hasPhotoAccess
        scanTask = Task {
            let scanner = PhotoLibraryDuplicateScanner()

            // Metadata-only categories are near-instant; populate them before the
            // deep scan so the UI fills in immediately. Off the main actor: the
            // per-asset resource lookups add up on large libraries.
            if libraryAccessGranted {
                let categories = await Task.detached(priority: .userInitiated) {
                    (screenshots: LibraryCleanupScanner.fetchScreenshots(),
                     largeVideos: LibraryCleanupScanner.fetchLargeVideos())
                }.value
                guard self.cancellationToken === token else { return }
                self.screenshots = categories.screenshots
                self.largeVideos = categories.largeVideos
            }

            do {
                let result = try await scanner.scan(
                    mode: selectedMode,
                    importedImageURLs: importedImageURLs,
                    cancellationToken: token
                ) { update in
                    await MainActor.run {
                        guard self.cancellationToken === token else { return }
                        self.progress = update.fraction
                        self.status = update.message
                    }
                }

                guard self.cancellationToken === token else { return }
                self.groups = result.groups
                self.summary = result.summary
                self.blurryPhotos = result.blurryPhotos
                self.progress = result.summary.wasStopped
                    ? Double(result.summary.completedCheckCount) / Double(max(result.summary.totalCheckCount, 1))
                    : 1
                self.status = result.groups.isEmpty
                    ? "No duplicates found."
                    : "Found \(result.summary.groupCount) duplicate groups."
                self.isScanning = false
            } catch {
                guard self.cancellationToken === token else { return }
                self.progress = 0
                self.status = error.localizedDescription
                self.isScanning = false
            }
        }
    }

    func stopScan() {
        cancellationToken?.cancel()
        scanTask?.cancel()
        status = "Stopping after the current image..."
    }

    func importImages(_ result: Result<[URL], Error>) async {
        switch result {
        case .success(let urls):
            do {
                let imported = try ImportedImageStore.importImages(from: urls)
                refreshImportedCount()
                status = imported == 1
                    ? "Imported 1 image."
                    : "Imported \(imported) images."
            } catch {
                status = "Import failed: \(error.localizedDescription)"
            }
        case .failure(let error):
            status = "Import failed: \(error.localizedDescription)"
        }
    }

    func clearImportedImages() async {
        do {
            let importedIDs = Set(groups.flatMap(\.photos).filter(\.isImportedFile).map(\.localIdentifier))
            try ImportedImageStore.removeAll()
            refreshImportedCount()
            removeDeletedPhotos(ids: importedIDs)
            status = "Cleared imported images."
        } catch {
            status = "Could not clear imports: \(error.localizedDescription)"
        }
    }

    func setDeletionSelection(_ photo: ScannedPhoto, isSelected: Bool) {
        if isSelected {
            selectedForDeletion.insert(photo.localIdentifier)
        } else {
            selectedForDeletion.remove(photo.localIdentifier)
        }
    }

    func selectExtras(_ group: DuplicateGroup) {
        for photo in group.photos.dropFirst() {
            selectedForDeletion.insert(photo.localIdentifier)
        }
    }

    func clearGroupSelection(_ group: DuplicateGroup) {
        for photo in group.photos {
            selectedForDeletion.remove(photo.localIdentifier)
        }
    }

    func selectAllExtras() {
        for group in groups {
            selectExtras(group)
        }
    }

    func clearDeletionSelection() {
        selectedForDeletion = []
    }

    /// Bytes freed by deleting every non-keeper across all duplicate groups,
    /// deduplicated by asset (a photo can appear in byte, pixel, and visual groups).
    var reclaimableBytes: Int64 {
        var bytesByID: [String: Int64] = [:]
        for group in groups {
            for photo in group.photos.dropFirst() {
                bytesByID[photo.localIdentifier] = photo.byteSize ?? 0
            }
        }
        return bytesByID.values.reduce(0, +)
    }

    var duplicateGroups: [DuplicateGroup] {
        groups.filter { $0.kind != .visual }
    }

    var similarGroups: [DuplicateGroup] {
        groups.filter { $0.kind == .visual }
    }

    var screenshotsBytes: Int64 {
        screenshots.reduce(0) { $0 + ($1.byteSize ?? 0) }
    }

    var largeVideosBytes: Int64 {
        largeVideos.reduce(0) { $0 + ($1.byteSize ?? 0) }
    }

    func deleteSelectedPhotos() async {
        let deleted = await deleteAssets(withIdentifiers: selectedForDeletion)
        guard !deleted.isEmpty else { return }
        status = deleted.count == 1
            ? "Deleted 1 item. Recoverable in Recently Deleted for 30 days."
            : "Deleted \(deleted.count) items. Recoverable in Recently Deleted for 30 days."
    }

    /// Deletes library assets and/or imported files, then prunes every result
    /// list. Returns the identifiers that were actually deleted.
    @discardableResult
    func deleteAssets(withIdentifiers identifiers: Set<String>) async -> Set<String> {
        let ids = Array(identifiers)
        guard !ids.isEmpty else { return [] }

        let importedIDs = Set(ids.filter { ImportedImageStore.fileURL(for: $0) != nil })
        let photoIDs = ids.filter { !importedIDs.contains($0) }
        var deletedIDs = Set<String>()

        if !photoIDs.isEmpty {
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: photoIDs, options: nil)
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.deleteAssets(assets)
                }
                deletedIDs.formUnion(photoIDs)
            } catch {
                status = "Delete failed: \(error.localizedDescription)"
                return []
            }
        }

        let importedDeletedCount = ImportedImageStore.deleteImportedImages(with: importedIDs)
        if importedDeletedCount > 0 {
            deletedIDs.formUnion(importedIDs)
            refreshImportedCount()
        }

        removeDeletedPhotos(ids: deletedIDs)
        screenshots.removeAll { deletedIDs.contains($0.localIdentifier) }
        blurryPhotos.removeAll { deletedIDs.contains($0.localIdentifier) }
        largeVideos.removeAll { deletedIDs.contains($0.localIdentifier) }
        return deletedIDs
    }

    private func removeDeletedPhotos(ids: Set<String>) {
        groups = groups.compactMap { group in
            let remaining = group.photos.filter { !ids.contains($0.localIdentifier) }
            guard remaining.count > 1 else { return nil }
            return DuplicateGroup(kind: group.kind, signature: group.signature, photos: remaining)
        }

        selectedForDeletion.subtract(ids)
        if let summary {
            let duplicateCount = groups.reduce(0) { $0 + $1.duplicateCount }
            self.summary = ScanSummary(
                scannedPhotoCount: summary.scannedPhotoCount,
                skippedPhotoCount: summary.skippedPhotoCount,
                groupCount: groups.count,
                duplicatePhotoCount: duplicateCount,
                wasStopped: summary.wasStopped,
                completedCheckCount: summary.completedCheckCount,
                totalCheckCount: summary.totalCheckCount
            )
        }
    }
}

extension View {
    func sectionSurface() -> some View {
        self
            .padding(14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

func formatBytes(_ value: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: value)
}
