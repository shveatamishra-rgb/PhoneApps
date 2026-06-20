import Photos
import UIKit

enum WallpaperLibrary {
    static func save(imageNamed name: String) async throws {
        guard let image = UIImage(named: name) else {
            throw WallpaperError.imageMissing
        }

        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw WallpaperError.permissionDenied
        }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
}

enum WallpaperError: LocalizedError {
    case imageMissing
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .imageMissing:
            return "This wallpaper could not be loaded."
        case .permissionDenied:
            return "Allow photo access in iPhone Settings to save wallpapers."
        }
    }
}
