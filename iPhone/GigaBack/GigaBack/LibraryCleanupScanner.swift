import Foundation
import Photos

/// A photo-library video surfaced in the Large Videos category.
struct ScannedVideo: Identifiable, Hashable {
    let localIdentifier: String
    let filename: String
    let byteSize: Int64?
    let duration: TimeInterval
    let pixelWidth: Int
    let pixelHeight: Int
    let creationDate: Date?

    var id: String { localIdentifier }

    var durationDescription: String {
        let total = Int(duration.rounded())
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Metadata-only passes over the photo library. Nothing here decodes media,
/// so these run in milliseconds even on huge libraries and never touch iCloud.
enum LibraryCleanupScanner {
    /// Videos at or above this size always qualify as "large".
    static let largeVideoThresholdBytes: Int64 = 50_000_000
    /// Cap so a video-heavy library does not produce an endless list.
    static let largeVideoLimit = 200

    /// All screenshots in the library, newest first (the ones least likely to matter
    /// are old, but people triage from the familiar end).
    static func fetchScreenshots() -> [ScannedPhoto] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(
            format: "(mediaSubtypes & %d) != 0",
            PHAssetMediaSubtype.photoScreenshot.rawValue
        )
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        var screenshots: [ScannedPhoto] = []
        screenshots.reserveCapacity(fetchResult.count)

        fetchResult.enumerateObjects { asset, _, _ in
            let resource = primaryResource(for: asset, type: .photo)
            screenshots.append(ScannedPhoto(
                id: asset.localIdentifier,
                localIdentifier: asset.localIdentifier,
                photoLibraryIdentifier: asset.localIdentifier,
                fileURL: nil,
                filename: resource?.originalFilename ?? "Screenshot",
                sourceTitle: "Screenshots",
                byteSize: resource.flatMap(fileSize(of:)),
                pixelWidth: asset.pixelWidth,
                pixelHeight: asset.pixelHeight,
                creationDate: asset.creationDate
            ))
        }
        return screenshots
    }

    /// Videos sorted by size (largest first). Size comes from resource metadata,
    /// so no video is downloaded or decoded.
    static func fetchLargeVideos() -> [ScannedVideo] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "duration", ascending: false)]

        let fetchResult = PHAsset.fetchAssets(with: .video, options: options)
        var videos: [ScannedVideo] = []
        videos.reserveCapacity(min(fetchResult.count, largeVideoLimit * 2))

        fetchResult.enumerateObjects { asset, _, _ in
            let resource = primaryResource(for: asset, type: .video)
            videos.append(ScannedVideo(
                localIdentifier: asset.localIdentifier,
                filename: resource?.originalFilename ?? "Video",
                byteSize: resource.flatMap(fileSize(of:)),
                duration: asset.duration,
                pixelWidth: asset.pixelWidth,
                pixelHeight: asset.pixelHeight,
                creationDate: asset.creationDate
            ))
        }

        let sized = videos
            .filter { ($0.byteSize ?? 0) >= largeVideoThresholdBytes }
            .sorted { ($0.byteSize ?? 0) > ($1.byteSize ?? 0) }
        if sized.count >= 10 {
            return Array(sized.prefix(largeVideoLimit))
        }
        // Sparse metadata (byteSize unavailable): fall back to longest videos so the
        // category is still useful instead of empty.
        return Array(videos.sorted { $0.duration > $1.duration }.prefix(50))
    }

    private static func primaryResource(
        for asset: PHAsset,
        type: PHAssetResourceType
    ) -> PHAssetResource? {
        let resources = PHAssetResource.assetResources(for: asset)
        return resources.first { $0.type == type } ?? resources.first
    }

    /// Resource size via KVC. "fileSize" is not in the public header but is the
    /// de-facto standard used across shipping cleaner apps; callers must treat
    /// nil as "unknown" and degrade gracefully.
    private static func fileSize(of resource: PHAssetResource) -> Int64? {
        (resource.value(forKey: "fileSize") as? CLong).map(Int64.init)
    }
}
