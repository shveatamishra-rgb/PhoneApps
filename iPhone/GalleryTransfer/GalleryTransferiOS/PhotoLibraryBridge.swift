import AVFoundation
import CoreLocation
import Foundation
import ImageIO
import Photos
import UniformTypeIdentifiers

struct ReceivedUpload: Sendable {
    let filename: String
    let fileURL: URL
    let contentType: String?
    var latitude: Double? = nil
    var longitude: Double? = nil
    var dateMillis: Double? = nil

    /// Location the sender measured (sent as headers), authoritative over whatever we
    /// can parse from the file itself.
    var headerLocation: CLLocation? {
        guard let latitude, let longitude,
              (-90...90).contains(latitude), (-180...180).contains(longitude),
              !(abs(latitude) < 0.000001 && abs(longitude) < 0.000001) else {
            return nil
        }
        return CLLocation(latitude: latitude, longitude: longitude)
    }

    var headerDate: Date? {
        guard let dateMillis else { return nil }
        return Date(timeIntervalSince1970: dateMillis / 1000.0)
    }
}

struct UploadResult: Sendable {
    let filename: String
    let message: String
    let didSave: Bool
    var localIdentifier: String? = nil
}

struct SavedMediaMetadata: Sendable {
    let savedFilename: String
    let mediaKind: TransferMediaKind
    let hasLocation: Bool
    let locationMessage: String
    let hasCreationDate: Bool
    var localIdentifier: String? = nil
}

/// Carries the created asset's identifier out of the PhotoKit change block, which runs
/// synchronously, so a reference box is safe across the `@Sendable` boundary.
private final class CreatedAssetIdentifierBox: @unchecked Sendable {
    var value: String?
}

struct PhotoLibraryBridge {
    enum BridgeError: LocalizedError {
        case missingPhotoResource
        case unsupportedMedia

        var errorDescription: String? {
            switch self {
            case .missingPhotoResource:
                return "The original Photo Library resource could not be read."
            case .unsupportedMedia:
                return "The uploaded file is not a supported photo or video."
            }
        }
    }

    private var exportDirectory: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("GalleryTransferOutgoing", isDirectory: true)
    }

    private var pickedDirectory: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("GalleryTransferPicked", isDirectory: true)
    }

    /// Resets the outgoing staging area. Call once before exporting a fresh selection.
    func beginOutgoingExport() throws {
        try prepareCleanDirectory(exportDirectory)
        try? FileManager.default.removeItem(at: pickedDirectory)
    }

    /// Preferred export path: writes the asset's true original resource, which carries
    /// all embedded metadata (GPS, capture date, camera EXIF). Returns nil when the
    /// asset can't be reached (e.g. its identifier isn't in the limited-access set),
    /// so the caller can fall back to `adoptPickedFile`.
    func exportAssetOriginal(localIdentifier: String) async throws -> OutgoingPhotoFile? {
        let fetch = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = fetch.firstObject,
              let mediaKind = TransferMediaKind(assetMediaType: asset.mediaType),
              let resource = primaryMediaResource(for: asset) else {
            return nil
        }

        let fallbackExtension = resourceUniformTypeExtension(resource) ?? mediaKind.fallbackExtension
        let filename = safeFilename(
            resource.originalFilename,
            fallback: "\(localIdentifier).\(fallbackExtension)"
        )
        let destination = uniqueDestination(in: exportDirectory, filename: filename)
        try await writeResource(resource, to: destination)
        return try outgoingFile(at: destination, mediaKind: mediaKind)
    }

    /// Fallback export path: adopts a file the picker already handed us (via
    /// `loadTransferable`) when the asset identifier is unavailable. Original bytes are
    /// served unchanged, so embedded metadata still rides along.
    func adoptPickedFile(_ picked: PickedMediaFile) throws -> OutgoingPhotoFile? {
        guard let mediaKind = mediaKind(for: picked.url) else {
            return nil
        }

        let filename = safeFilename(
            picked.suggestedName,
            fallback: "media.\(mediaKind.fallbackExtension)"
        )
        let destination = uniqueDestination(in: exportDirectory, filename: filename)
        try FileManager.default.moveItem(at: picked.url, to: destination)
        return try outgoingFile(at: destination, mediaKind: mediaKind)
    }

    private func outgoingFile(at destination: URL, mediaKind: TransferMediaKind) throws -> OutgoingPhotoFile {
        let values = try destination.resourceValues(forKeys: Set<URLResourceKey>([.fileSizeKey]))
        return OutgoingPhotoFile(
            id: destination.lastPathComponent,
            filename: destination.lastPathComponent,
            byteSize: Int64(values.fileSize ?? 0),
            url: destination,
            mediaKind: mediaKind
        )
    }

    /// Drops the staged copies of iPhone originals selected for sending. Safe to call
    /// when nothing is staged. Used when the receiver stops so the temp copies don't
    /// linger in the app container until the next export or an iOS purge.
    func clearExportedOriginals() {
        try? FileManager.default.removeItem(at: exportDirectory)
        try? FileManager.default.removeItem(at: pickedDirectory)
    }

    func saveReceivedMediaToPhotos(_ upload: ReceivedUpload) async throws -> SavedMediaMetadata {
        let mediaKind = try uploadedMediaKind(
            for: upload.fileURL,
            filename: upload.filename,
            contentType: upload.contentType
        )
        let metadata = await MediaMetadata(url: upload.fileURL, mediaKind: mediaKind)
        let savedFilename = preferredSavedFilename(
            uploadFilename: upload.filename,
            fileURL: upload.fileURL,
            mediaKind: mediaKind,
            metadata: metadata
        )

        // Prefer the location/date the sender measured (HTTP headers): the Android app
        // reads them from the unredacted original, which is more reliable than parsing
        // the file here. Fall back to whatever is embedded in the file.
        let finalLocation = upload.headerLocation ?? metadata.location
        let finalDate = upload.headerDate ?? metadata.creationDate

        let identifierBox = CreatedAssetIdentifierBox()
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            options.originalFilename = savedFilename
            // Let Photos consume the staged file directly instead of copying it, so
            // peak temp usage stays ~1x the file. receiveUpload's `defer` still cleans
            // up if a move ever leaves the source behind or the save fails.
            options.shouldMoveFile = true

            request.creationDate = finalDate
            request.location = finalLocation

            switch mediaKind {
            case .image:
                request.addResource(with: .photo, fileURL: upload.fileURL, options: options)
            case .video:
                request.addResource(with: .video, fileURL: upload.fileURL, options: options)
            }

            identifierBox.value = request.placeholderForCreatedAsset?.localIdentifier
        }

        let locationMessage: String
        if let finalLocation {
            locationMessage = String(
                format: "GPS saved: %.5f, %.5f",
                finalLocation.coordinate.latitude,
                finalLocation.coordinate.longitude
            )
        } else if case .invalid(let reason) = metadata.locationResult {
            locationMessage = reason
        } else {
            locationMessage = "No GPS location metadata arrived with the upload."
        }

        return SavedMediaMetadata(
            savedFilename: savedFilename,
            mediaKind: mediaKind,
            hasLocation: finalLocation != nil,
            locationMessage: locationMessage,
            hasCreationDate: finalDate != nil,
            localIdentifier: identifierBox.value
        )
    }

    private func uploadedMediaKind(for url: URL, filename: String, contentType: String?) throws -> TransferMediaKind {
        if let contentType,
           let type = UTType(mimeType: contentType),
           let mediaKind = TransferMediaKind(uniformType: type) {
            return mediaKind
        }

        let extensionSource = URL(fileURLWithPath: filename).pathExtension.isEmpty
            ? url.pathExtension
            : URL(fileURLWithPath: filename).pathExtension
        if let type = UTType(filenameExtension: extensionSource),
           let mediaKind = TransferMediaKind(uniformType: type) {
            return mediaKind
        }

        if CGImageSourceCreateWithURL(url as CFURL, nil) != nil {
            return .image
        }

        throw BridgeError.unsupportedMedia
    }

    private func mediaKind(for url: URL) -> TransferMediaKind? {
        if let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType,
           let kind = TransferMediaKind(uniformType: contentType) {
            return kind
        }

        let ext = url.pathExtension.lowercased()
        if !ext.isEmpty,
           let type = UTType(filenameExtension: ext),
           let kind = TransferMediaKind(uniformType: type) {
            return kind
        }

        if CGImageSourceCreateWithURL(url as CFURL, nil) != nil {
            return .image
        }

        return nil
    }

    private func primaryMediaResource(for asset: PHAsset) -> PHAssetResource? {
        let resources = PHAssetResource.assetResources(for: asset)
        let preferredTypes: [PHAssetResourceType]

        switch asset.mediaType {
        case .image:
            preferredTypes = [.photo, .fullSizePhoto, .alternatePhoto]
        case .video:
            preferredTypes = [.video, .fullSizeVideo, .pairedVideo]
        default:
            return nil
        }

        for type in preferredTypes {
            if let resource = resources.first(where: { $0.type == type }) {
                return resource
            }
        }

        return resources.first
    }

    private func writeResource(_ resource: PHAssetResource, to destination: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            PHAssetResourceManager.default().writeData(for: resource, toFile: destination, options: options) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func resourceUniformTypeExtension(_ resource: PHAssetResource) -> String? {
        UTType(resource.uniformTypeIdentifier)?.preferredFilenameExtension
    }

    private func prepareCleanDirectory(_ directory: URL) throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: directory.path) {
            try fileManager.removeItem(at: directory)
        }
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func uniqueDestination(in directory: URL, filename: String) -> URL {
        let parsed = URL(fileURLWithPath: filename)
        let baseName = parsed.deletingPathExtension().lastPathComponent.isEmpty
            ? "media"
            : parsed.deletingPathExtension().lastPathComponent
        let ext = parsed.pathExtension

        var candidate = directory.appendingPathComponent(filename)
        var index = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            let nextName = ext.isEmpty ? "\(baseName)-\(index)" : "\(baseName)-\(index).\(ext)"
            candidate = directory.appendingPathComponent(nextName)
            index += 1
        }

        return candidate
    }

    private func preferredSavedFilename(
        uploadFilename: String,
        fileURL: URL,
        mediaKind: TransferMediaKind,
        metadata: MediaMetadata
    ) -> String {
        let incomingFilename = safeFilename(uploadFilename, fallback: fileURL.lastPathComponent)
        // Preserve the name Android sent (including numeric MediaStore IDs that some
        // browsers hand videos). Only synthesize a readable timestamp name when no
        // usable name arrived at all.
        guard isGenericUploadName(incomingFilename),
              let creationDate = metadata.creationDate else {
            return incomingFilename
        }

        let ext = filenameExtension(from: incomingFilename, mediaKind: mediaKind)
        return "\(timestampFilename(from: creationDate)).\(ext)"
    }

    private func isGenericUploadName(_ filename: String) -> Bool {
        let baseName = URL(fileURLWithPath: filename)
            .deletingPathExtension()
            .lastPathComponent
            .lowercased()
        return baseName.isEmpty || baseName == "android-media" || baseName == "media"
    }

    private func filenameExtension(from filename: String, mediaKind: TransferMediaKind) -> String {
        let ext = URL(fileURLWithPath: filename).pathExtension
        return ext.isEmpty ? mediaKind.fallbackExtension : ext.lowercased()
    }

    private func timestampFilename(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: date)
    }
}

private extension TransferMediaKind {
    init?(assetMediaType: PHAssetMediaType) {
        switch assetMediaType {
        case .image:
            self = .image
        case .video:
            self = .video
        default:
            return nil
        }
    }

    init?(uniformType: UTType) {
        if uniformType.conforms(to: .image) {
            self = .image
        } else if uniformType.conforms(to: .movie)
            || uniformType.conforms(to: .video)
            || uniformType.conforms(to: .audiovisualContent) {
            self = .video
        } else {
            return nil
        }
    }

    var fallbackExtension: String {
        switch self {
        case .image: return "jpg"
        case .video: return "mov"
        }
    }
}

private struct MediaMetadata {
    let mediaKind: TransferMediaKind
    let creationDate: Date?
    let locationResult: LocationResult

    var location: CLLocation? {
        if case .valid(let location) = locationResult {
            return location
        }
        return nil
    }

    func savedSummary(savedFilename: String) -> SavedMediaMetadata {
        switch locationResult {
        case .valid(let location):
            return SavedMediaMetadata(
                savedFilename: savedFilename,
                mediaKind: mediaKind,
                hasLocation: true,
                locationMessage: String(
                    format: "GPS found: %.5f, %.5f",
                    location.coordinate.latitude,
                    location.coordinate.longitude
                ),
                hasCreationDate: creationDate != nil
            )

        case .invalid(let reason):
            return SavedMediaMetadata(
                savedFilename: savedFilename,
                mediaKind: mediaKind,
                hasLocation: false,
                locationMessage: reason,
                hasCreationDate: creationDate != nil
            )

        case .notFound:
            return SavedMediaMetadata(
                savedFilename: savedFilename,
                mediaKind: mediaKind,
                hasLocation: false,
                locationMessage: "No GPS location metadata arrived in the uploaded file.",
                hasCreationDate: creationDate != nil
            )
        }
    }

    init(url: URL, mediaKind: TransferMediaKind) async {
        self.mediaKind = mediaKind

        switch mediaKind {
        case .image:
            let metadata = ImageMetadata(url: url)
            creationDate = metadata.creationDate
            locationResult = metadata.locationResult
        case .video:
            let metadata = await VideoMetadata(url: url)
            creationDate = metadata.creationDate
            locationResult = metadata.locationResult
        }
    }
}

private struct ImageMetadata {
    let creationDate: Date?
    let locationResult: LocationResult

    init(url: URL) {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            creationDate = nil
            locationResult = .notFound
            return
        }

        creationDate = MetadataHelpers.imageCreationDate(from: properties)
        locationResult = MetadataHelpers.imageLocationResult(from: properties)
    }
}

private struct VideoMetadata {
    let creationDate: Date?
    let locationResult: LocationResult

    init(url: URL) async {
        let asset = AVURLAsset(url: url)
        var items: [AVMetadataItem] = (try? await asset.load(.metadata)) ?? []

        // Android MP4s keep location/date in the QuickTime user-data atoms (©xyz / ©day),
        // which are not part of the common metadata. Pull every available metadata format
        // so those atoms are included.
        if let formats = try? await asset.load(.availableMetadataFormats) {
            for format in formats {
                if let formatItems = try? await asset.loadMetadata(for: format) {
                    items.append(contentsOf: formatItems)
                }
            }
        }

        creationDate = await MetadataHelpers.videoCreationDate(from: items)
        locationResult = await MetadataHelpers.videoLocationResult(from: items)
    }
}

private enum MetadataHelpers {
    static func imageCreationDate(from properties: [CFString: Any]) -> Date? {
        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]

        let dateString = exif?[kCGImagePropertyExifDateTimeOriginal] as? String
            ?? exif?[kCGImagePropertyExifDateTimeDigitized] as? String
            ?? tiff?[kCGImagePropertyTIFFDateTime] as? String

        return dateString.flatMap(dateFromMetadataString)
    }

    static func imageLocationResult(from properties: [CFString: Any]) -> LocationResult {
        guard let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any] else {
            return .notFound
        }

        guard let latitude = doubleValue(gps[kCGImagePropertyGPSLatitude]),
              let longitude = doubleValue(gps[kCGImagePropertyGPSLongitude]) else {
            return .invalid("GPS metadata was present, but latitude/longitude were not readable.")
        }

        let latitudeRef = gps[kCGImagePropertyGPSLatitudeRef] as? String
        let longitudeRef = gps[kCGImagePropertyGPSLongitudeRef] as? String
        let signedLatitude = latitudeRef == "S" ? -latitude : latitude
        let signedLongitude = longitudeRef == "W" ? -longitude : longitude
        let altitudeValue = doubleValue(gps[kCGImagePropertyGPSAltitude])
        let altitudeRef = intValue(gps[kCGImagePropertyGPSAltitudeRef])
        let altitude = altitudeValue.map { altitudeRef == 1 ? -$0 : $0 }

        return locationResult(latitude: signedLatitude, longitude: signedLongitude, altitude: altitude)
    }

    static func videoCreationDate(from items: [AVMetadataItem]) async -> Date? {
        guard let metadata = await metadataString(
            in: items,
            identifiers: [
                .quickTimeMetadataCreationDate,
                .quickTimeUserDataCreationDate,
                .commonIdentifierCreationDate
            ]
        ) else {
            return nil
        }

        return dateFromMetadataString(metadata)
    }

    static func videoLocationResult(from items: [AVMetadataItem]) async -> LocationResult {
        let identifiers: [AVMetadataIdentifier] = [
            .quickTimeMetadataLocationISO6709,
            .quickTimeUserDataLocationISO6709,
            .commonIdentifierLocation
        ]
        if let iso6709 = await metadataString(in: items, identifiers: identifiers) {
            return locationResult(fromISO6709: iso6709)
        }

        // Fallback: any metadata value that parses as an ISO 6709 location string,
        // covering formats whose identifier we did not list explicitly.
        for item in items {
            if let value = try? await item.load(.stringValue),
               let first = value.first,
               first == "+" || first == "-" {
                let result = locationResult(fromISO6709: value)
                if case .valid = result {
                    return result
                }
            }
        }

        return .notFound
    }

    static func metadataString(in items: [AVMetadataItem], identifiers: [AVMetadataIdentifier]) async -> String? {
        for item in items {
            guard let identifier = item.identifier else { continue }
            guard identifiers.contains(identifier) else { continue }
            if let value = try? await item.load(.stringValue) {
                return value
            }
        }

        return nil
    }

    static func dateFromMetadataString(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        let exifFormatter = DateFormatter()
        exifFormatter.locale = Locale(identifier: "en_US_POSIX")
        exifFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        if let date = exifFormatter.date(from: trimmed) {
            return date
        }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: trimmed) {
            return date
        }

        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.date(from: trimmed)
    }

    static func locationResult(fromISO6709 value: String) -> LocationResult {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var values: [Double] = []
        var index = trimmed.startIndex

        while index < trimmed.endIndex {
            guard trimmed[index] == "+" || trimmed[index] == "-" else {
                break
            }

            let start = index
            index = trimmed.index(after: index)
            while index < trimmed.endIndex {
                let character = trimmed[index]
                if character.isNumber || character == "." {
                    index = trimmed.index(after: index)
                } else {
                    break
                }
            }

            guard let number = Double(trimmed[start..<index]) else {
                break
            }
            values.append(number)
        }

        guard values.count >= 2 else {
            return .invalid("GPS metadata was present, but video coordinates were not readable.")
        }

        return locationResult(latitude: values[0], longitude: values[1], altitude: values.count > 2 ? values[2] : nil)
    }

    static func locationResult(latitude: Double, longitude: Double, altitude: Double?) -> LocationResult {
        guard (-90...90).contains(latitude),
              (-180...180).contains(longitude) else {
            return .invalid("GPS metadata was present, but the coordinates were outside a valid range.")
        }

        if abs(latitude) < 0.000001 && abs(longitude) < 0.000001 {
            return .invalid("GPS metadata was present as 0,0, so it was ignored instead of saved as a false location.")
        }

        return .valid(CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: altitude ?? 0,
            horizontalAccuracy: kCLLocationAccuracyNearestTenMeters,
            verticalAccuracy: altitude == nil ? -1 : kCLLocationAccuracyNearestTenMeters,
            timestamp: Date()
        ))
    }

    static func doubleValue(_ value: Any?) -> Double? {
        if let value = value as? Double {
            return value
        }
        if let value = value as? Float {
            return Double(value)
        }
        if let value = value as? Int {
            return Double(value)
        }
        if let value = value as? NSNumber {
            return value.doubleValue
        }
        if let value = value as? String {
            return Double(value)
        }
        return nil
    }

    static func intValue(_ value: Any?) -> Int? {
        if let value = value as? Int {
            return value
        }
        if let value = value as? NSNumber {
            return value.intValue
        }
        if let value = value as? String {
            return Int(value)
        }
        return nil
    }
}

private enum LocationResult {
    case valid(CLLocation)
    case invalid(String)
    case notFound
}

func safeFilename(_ filename: String, fallback: String) -> String {
    let trimmed = filename.trimmingCharacters(in: .whitespacesAndNewlines)
    let fallbackName = fallback.trimmingCharacters(in: .whitespacesAndNewlines)
    let candidate = trimmed.isEmpty ? fallbackName : trimmed
    let lastComponent = candidate
        .replacingOccurrences(of: "\\", with: "/")
        .split(separator: "/")
        .last
        .map(String.init) ?? candidate

    let reserved = CharacterSet(charactersIn: ":")
        .union(.controlCharacters)
        .union(.newlines)
    let cleaned = String(lastComponent.unicodeScalars.map { scalar in
        reserved.contains(scalar) ? Character("_") : Character(scalar)
    })
    .trimmingCharacters(in: CharacterSet(charactersIn: ". "))

    guard !cleaned.isEmpty, cleaned != ".", cleaned != ".." else {
        return fallbackName.isEmpty ? "media" : safeFilename(fallbackName, fallback: "media")
    }

    return cleaned
}
