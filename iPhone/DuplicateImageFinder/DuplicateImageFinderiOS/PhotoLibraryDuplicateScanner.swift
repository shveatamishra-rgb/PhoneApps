import CryptoKit
import Foundation
import ImageIO
import Photos

enum ScanMode: String, CaseIterable, Identifiable {
    case all
    case bytes
    case pixels
    case visual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .bytes: return "Bytes"
        case .pixels: return "Pixels"
        case .visual: return "Looks"
        }
    }

    var includesBytes: Bool {
        self == .all || self == .bytes
    }

    var includesPixels: Bool {
        self == .all || self == .pixels
    }

    var includesVisual: Bool {
        self == .all || self == .visual
    }
}

enum DuplicateKind: String, CaseIterable, Identifiable {
    case bytes
    case pixels
    case visual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bytes: return "Byte-identical"
        case .pixels: return "Pixel-identical"
        case .visual: return "Look-alike"
        }
    }

    var sectionTitle: String {
        switch self {
        case .bytes: return "Byte-Identical Images"
        case .pixels: return "Pixel-Identical Images"
        case .visual: return "Images That Look the Same"
        }
    }

    var sectionDescription: String {
        switch self {
        case .bytes:
            return "Same stored resource bytes."
        case .pixels:
            return "Same decoded pixels after orientation and sRGB normalization."
        case .visual:
            return "Visually similar after resizing or recompression."
        }
    }

    var systemImage: String {
        switch self {
        case .bytes: return "doc.on.doc"
        case .pixels: return "camera.metering.matrix"
        case .visual: return "eye"
        }
    }
}

struct ScannedPhoto: Identifiable, Hashable {
    let id: String
    let localIdentifier: String
    let photoLibraryIdentifier: String?
    let fileURL: URL?
    let filename: String
    let sourceTitle: String
    let byteSize: Int64?
    let pixelWidth: Int
    let pixelHeight: Int
    let creationDate: Date?

    var isImportedFile: Bool {
        fileURL != nil
    }

    var pixelDescription: String {
        "\(pixelWidth) x \(pixelHeight)"
    }
}

struct DuplicateGroup: Identifiable, Hashable {
    let kind: DuplicateKind
    let signature: String
    let photos: [ScannedPhoto]

    var id: String {
        "\(kind.rawValue)-\(signature)"
    }

    var totalBytes: Int64 {
        photos.reduce(0) { $0 + ($1.byteSize ?? 0) }
    }

    var duplicateCount: Int {
        max(0, photos.count - 1)
    }
}

struct ScanSummary: Equatable {
    let scannedPhotoCount: Int
    let skippedPhotoCount: Int
    let groupCount: Int
    let duplicatePhotoCount: Int
    let wasStopped: Bool
    let completedCheckCount: Int
    let totalCheckCount: Int
}

struct ScanProgress {
    let completed: Int
    let total: Int
    let message: String

    var fraction: Double {
        guard total > 0 else { return 0 }
        return min(1, max(0, Double(completed) / Double(total)))
    }
}

final class ScanCancellationToken {
    private let lock = NSLock()
    private var cancelled = false

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    func cancel() {
        lock.lock()
        cancelled = true
        lock.unlock()
    }
}

struct PhotoLibraryDuplicateScanner {
    enum ScanError: LocalizedError {
        case cancelled
        case noImageResource
        case imageDataUnavailable

        var errorDescription: String? {
            switch self {
            case .cancelled:
                return "Scan cancelled."
            case .noImageResource:
                return "The photo resource could not be read."
            case .imageDataUnavailable:
                return "The image data could not be loaded."
            }
        }
    }

    private enum CandidateSource {
        case photo(PHAsset, PHAssetResource?)
        case importedFile(URL)
    }

    private struct Candidate {
        let id: String
        let filename: String
        let pixelWidth: Int
        let pixelHeight: Int
        let creationDate: Date?
        let source: CandidateSource

        var canHashBytes: Bool {
            switch source {
            case .photo(_, let resource):
                return resource != nil
            case .importedFile:
                return true
            }
        }

        var isScreenshot: Bool {
            switch source {
            case .photo(let asset, _):
                return asset.mediaSubtypes.contains(.photoScreenshot)
            case .importedFile:
                return false
            }
        }
    }

    fileprivate struct ByteHashResult {
        let hex: String
        let byteSize: Int64
    }

    func scan(
        mode: ScanMode,
        importedImageURLs: [URL] = [],
        cancellationToken: ScanCancellationToken,
        progress: @escaping (ScanProgress) async -> Void
    ) async throws -> (groups: [DuplicateGroup], summary: ScanSummary) {
        await progress(ScanProgress(completed: 0, total: 1, message: "Finding images..."))

        let candidates = fetchImageCandidates(importedImageURLs: importedImageURLs)
        let byteChecks = mode.includesBytes ? candidates.filter(\.canHashBytes).count : 0
        let imageChecks = (mode.includesPixels || mode.includesVisual) ? candidates.count : 0
        let totalWork = max(1, byteChecks + imageChecks)

        var completed = 0
        var skipped = 0
        var byteSizesByImageID: [String: Int64] = [:]
        var groups: [DuplicateGroup] = []

        if mode.includesBytes && !cancellationToken.isCancelled {
            let result = await scanByteDuplicates(
                candidates: candidates,
                totalWork: totalWork,
                completed: &completed,
                skipped: &skipped,
                byteSizesByImageID: &byteSizesByImageID,
                cancellationToken: cancellationToken,
                progress: progress
            )
            groups.append(contentsOf: result)
        }

        if (mode.includesPixels || mode.includesVisual) && !cancellationToken.isCancelled {
            let result = await scanImageDuplicates(
                candidates: candidates,
                mode: mode,
                totalWork: totalWork,
                completed: &completed,
                skipped: &skipped,
                byteSizesByImageID: byteSizesByImageID,
                cancellationToken: cancellationToken,
                progress: progress
            )
            groups.append(contentsOf: result)
        }

        let sortedGroups = groups.sorted {
            if $0.kind != $1.kind {
                return kindSortIndex($0.kind) < kindSortIndex($1.kind)
            }
            if $0.duplicateCount != $1.duplicateCount {
                return $0.duplicateCount > $1.duplicateCount
            }
            return $0.photos.count > $1.photos.count
        }

        let duplicatePhotoCount = sortedGroups.reduce(0) { count, group in
            count + group.duplicateCount
        }
        let wasStopped = cancellationToken.isCancelled

        await progress(ScanProgress(
            completed: wasStopped ? completed : totalWork,
            total: totalWork,
            message: wasStopped ? "Scan stopped. Showing results found so far." : "Scan complete."
        ))

        return (
            sortedGroups,
            ScanSummary(
                scannedPhotoCount: candidates.count,
                skippedPhotoCount: skipped,
                groupCount: sortedGroups.count,
                duplicatePhotoCount: duplicatePhotoCount,
                wasStopped: wasStopped,
                completedCheckCount: completed,
                totalCheckCount: totalWork
            )
        )
    }

    private func fetchImageCandidates(importedImageURLs: [URL]) -> [Candidate] {
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: true)
        ]

        let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        var candidates: [Candidate] = []
        candidates.reserveCapacity(fetchResult.count + importedImageURLs.count)

        fetchResult.enumerateObjects { asset, _, _ in
            let resource = primaryImageResource(for: asset)
            candidates.append(Candidate(
                id: asset.localIdentifier,
                filename: resource?.originalFilename ?? "Photo",
                pixelWidth: asset.pixelWidth,
                pixelHeight: asset.pixelHeight,
                creationDate: asset.creationDate,
                source: .photo(asset, resource)
            ))
        }

        for url in importedImageURLs {
            guard let dimensions = imageDimensions(for: url) else { continue }
            let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
            candidates.append(Candidate(
                id: ImportedImageStore.imageID(for: url),
                filename: url.lastPathComponent,
                pixelWidth: dimensions.width,
                pixelHeight: dimensions.height,
                creationDate: values?.contentModificationDate,
                source: .importedFile(url.standardizedFileURL)
            ))
        }

        return candidates
    }

    private func scanByteDuplicates(
        candidates: [Candidate],
        totalWork: Int,
        completed: inout Int,
        skipped: inout Int,
        byteSizesByImageID: inout [String: Int64],
        cancellationToken: ScanCancellationToken,
        progress: @escaping (ScanProgress) async -> Void
    ) async -> [DuplicateGroup] {
        var photosByHash: [String: [ScannedPhoto]] = [:]

        for candidate in candidates {
            if cancellationToken.isCancelled {
                break
            }

            guard candidate.canHashBytes else {
                skipped += 1
                continue
            }

            await progress(ScanProgress(
                completed: completed,
                total: totalWork,
                message: "Checking bytes: \(candidate.filename)"
            ))

            do {
                let hash = try await byteHash(for: candidate)
                byteSizesByImageID[candidate.id] = hash.byteSize
                let photo = scannedPhoto(from: candidate, byteSize: hash.byteSize)
                photosByHash[hash.hex, default: []].append(photo)
            } catch {
                skipped += 1
            }

            completed += 1
        }

        return photosByHash
            .filter { $0.value.count > 1 }
            .map { signature, photos in
                DuplicateGroup(
                    kind: .bytes,
                    signature: signature,
                    photos: sortPhotos(photos)
                )
            }
    }

    private func scanImageDuplicates(
        candidates: [Candidate],
        mode: ScanMode,
        totalWork: Int,
        completed: inout Int,
        skipped: inout Int,
        byteSizesByImageID: [String: Int64],
        cancellationToken: ScanCancellationToken,
        progress: @escaping (ScanProgress) async -> Void
    ) async -> [DuplicateGroup] {
        var photosByPixelHash: [String: [ScannedPhoto]] = [:]
        var visualEntries: [(fingerprint: VisualFingerprint, photo: ScannedPhoto, isScreenshot: Bool)] = []

        for candidate in candidates {
            if cancellationToken.isCancelled {
                break
            }

            await progress(ScanProgress(
                completed: completed,
                total: totalWork,
                message: "Checking image look: \(candidate.filename)"
            ))

            do {
                let image = try await imageData(for: candidate)
                let byteSize = byteSizesByImageID[candidate.id]

                if mode.includesPixels {
                    let pixelHash = try ImageFingerprint.pixelSHA256(
                        data: image.data,
                        orientation: image.orientation
                    )
                    let photo = scannedPhoto(
                        from: candidate,
                        byteSize: byteSize,
                        pixelWidth: pixelHash.width,
                        pixelHeight: pixelHash.height
                    )
                    photosByPixelHash[pixelHash.hex, default: []].append(photo)
                }

                if mode.includesVisual {
                    let visualHash = try ImageFingerprint.visualHash(
                        data: image.data,
                        orientation: image.orientation
                    )
                    let photo = scannedPhoto(
                        from: candidate,
                        byteSize: byteSize,
                        pixelWidth: visualHash.width,
                        pixelHeight: visualHash.height
                    )
                    visualEntries.append((visualHash, photo, candidate.isScreenshot))
                }
            } catch {
                skipped += 1
            }

            completed += 1
        }

        var groups = photosByPixelHash
            .filter { $0.value.count > 1 }
            .map { signature, photos in
                DuplicateGroup(
                    kind: .pixels,
                    signature: signature,
                    photos: sortPhotos(photos)
                )
            }

        groups.append(contentsOf: visualDuplicateGroups(from: visualEntries))
        return groups
    }

    private func visualDuplicateGroups(
        from entries: [(fingerprint: VisualFingerprint, photo: ScannedPhoto, isScreenshot: Bool)]
    ) -> [DuplicateGroup] {
        guard entries.count > 1 else { return [] }

        let disjointSet = DisjointSet(count: entries.count)
        var treesByAspectBucket: [Int: VisualBKTree] = [:]

        for (index, entry) in entries.enumerated() {
            let buckets = (entry.fingerprint.aspectBucket - 1)...(entry.fingerprint.aspectBucket + 1)
            for bucket in buckets {
                guard let tree = treesByAspectBucket[bucket] else { continue }
                for matchIndex in tree.search(
                    entry.fingerprint,
                    threshold: VisualFingerprint.duplicateThreshold
                ) {
                    let match = entries[matchIndex]
                    let requiresScreenshotPrecision = entry.isScreenshot || match.isScreenshot
                    if entry.fingerprint.isDuplicateMatch(
                        to: match.fingerprint,
                        requiresScreenshotPrecision: requiresScreenshotPrecision
                    ) {
                        disjointSet.union(index, matchIndex)
                    }
                }
            }

            let bucket = entry.fingerprint.aspectBucket
            if treesByAspectBucket[bucket] == nil {
                treesByAspectBucket[bucket] = VisualBKTree()
            }
            treesByAspectBucket[bucket]?.insert(entry.fingerprint, index: index)
        }

        let groupedIndexes = Dictionary(grouping: entries.indices) { disjointSet.find($0) }
            .values
            .filter { $0.count > 1 }

        return groupedIndexes.map { indexes in
            let firstIndex = indexes.min() ?? indexes[0]
            let signature = entries[firstIndex].fingerprint.signature
            let photos = indexes.map { entries[$0].photo }
            return DuplicateGroup(
                kind: .visual,
                signature: signature,
                photos: sortPhotos(photos)
            )
        }
    }

    private func primaryImageResource(for asset: PHAsset) -> PHAssetResource? {
        let resources = PHAssetResource.assetResources(for: asset)
        let preferredTypes: [PHAssetResourceType] = [
            .photo,
            .fullSizePhoto,
            .alternatePhoto
        ]

        for type in preferredTypes {
            if let resource = resources.first(where: { $0.type == type }) {
                return resource
            }
        }

        return resources.first
    }

    private func resourceByteHash(_ resource: PHAssetResource) async throws -> ByteHashResult {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true

            let state = ByteHashState()
            PHAssetResourceManager.default().requestData(
                for: resource,
                options: options,
                dataReceivedHandler: { data in
                    state.update(data)
                },
                completionHandler: { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: state.result())
                    }
                }
            )
        }
    }

    private func byteHash(for candidate: Candidate) async throws -> ByteHashResult {
        switch candidate.source {
        case .photo(_, let resource):
            guard let resource else { throw ScanError.noImageResource }
            return try await resourceByteHash(resource)
        case .importedFile(let url):
            return try fileByteHash(url: url)
        }
    }

    private func fileByteHash(url: URL) throws -> ByteHashResult {
        let handle = try FileHandle(forReadingFrom: url)
        defer {
            try? handle.close()
        }

        var hasher = SHA256()
        var byteSize: Int64 = 0
        while true {
            let data = try handle.read(upToCount: 1_048_576) ?? Data()
            if data.isEmpty {
                break
            }
            hasher.update(data: data)
            byteSize += Int64(data.count)
        }

        return ByteHashResult(
            hex: hasher.finalize().map { String(format: "%02x", $0) }.joined(),
            byteSize: byteSize
        )
    }

    private func imageData(for candidate: Candidate) async throws -> (data: Data, orientation: CGImagePropertyOrientation?) {
        switch candidate.source {
        case .photo(let asset, _):
            return try await photoImageData(for: asset)
        case .importedFile(let url):
            return (try Data(contentsOf: url), nil)
        }
    }

    private func photoImageData(for asset: PHAsset) async throws -> (data: Data, orientation: CGImagePropertyOrientation?) {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.version = .current
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .none
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            var didResume = false
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, orientation, info in
                guard !didResume else { return }

                if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
                    didResume = true
                    continuation.resume(throwing: ScanError.cancelled)
                    return
                }

                if let error = info?[PHImageErrorKey] as? Error {
                    didResume = true
                    continuation.resume(throwing: error)
                    return
                }

                guard let data else {
                    didResume = true
                    continuation.resume(throwing: ScanError.imageDataUnavailable)
                    return
                }

                didResume = true
                continuation.resume(returning: (data, orientation))
            }
        }
    }

    private func scannedPhoto(
        from candidate: Candidate,
        byteSize: Int64?,
        pixelWidth: Int? = nil,
        pixelHeight: Int? = nil
    ) -> ScannedPhoto {
        let photoLibraryIdentifier: String?
        let fileURL: URL?
        let sourceTitle: String

        switch candidate.source {
        case .photo:
            photoLibraryIdentifier = candidate.id
            fileURL = nil
            sourceTitle = "Photos"
        case .importedFile(let url):
            photoLibraryIdentifier = nil
            fileURL = url
            sourceTitle = "Imported"
        }

        return ScannedPhoto(
            id: candidate.id,
            localIdentifier: candidate.id,
            photoLibraryIdentifier: photoLibraryIdentifier,
            fileURL: fileURL,
            filename: candidate.filename,
            sourceTitle: sourceTitle,
            byteSize: byteSize,
            pixelWidth: pixelWidth ?? candidate.pixelWidth,
            pixelHeight: pixelHeight ?? candidate.pixelHeight,
            creationDate: candidate.creationDate
        )
    }

    private func imageDimensions(for url: URL) -> (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0,
              height > 0 else {
            return nil
        }

        return (width, height)
    }

    private func sortPhotos(_ photos: [ScannedPhoto]) -> [ScannedPhoto] {
        photos.sorted {
            if $0.creationDate != $1.creationDate {
                return ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast)
            }
            return $0.localIdentifier.localizedStandardCompare($1.localIdentifier) == .orderedAscending
        }
    }

    private func kindSortIndex(_ kind: DuplicateKind) -> Int {
        switch kind {
        case .bytes: return 0
        case .pixels: return 1
        case .visual: return 2
        }
    }
}

enum ImportedImageStore {
    static let idPrefix = "imported-file:"

    static var directory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ImportedImages", isDirectory: true)
    }

    static func imageID(for url: URL) -> String {
        idPrefix + url.standardizedFileURL.path
    }

    static func fileURL(for id: String) -> URL? {
        guard id.hasPrefix(idPrefix) else { return nil }
        let path = String(id.dropFirst(idPrefix.count))
        return URL(fileURLWithPath: path)
    }

    static func importedImageURLs() -> [URL] {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return urls
            .filter { url in
                guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey]),
                      values.isRegularFile == true else {
                    return false
                }
                return CGImageSourceCreateWithURL(url as CFURL, nil) != nil
            }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    static func importImages(from sourceURLs: [URL]) throws -> Int {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var importedCount = 0
        for sourceURL in sourceURLs {
            let didAccess = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            guard CGImageSourceCreateWithURL(sourceURL as CFURL, nil) != nil else {
                continue
            }

            let destination = uniqueDestination(for: sourceURL.lastPathComponent)
            try FileManager.default.copyItem(at: sourceURL, to: destination)
            importedCount += 1
        }

        return importedCount
    }

    static func deleteImportedImages(with ids: Set<String>) -> Int {
        var deletedCount = 0
        for id in ids {
            guard let url = fileURL(for: id),
                  FileManager.default.fileExists(atPath: url.path) else {
                continue
            }

            do {
                try FileManager.default.removeItem(at: url)
                deletedCount += 1
            } catch {
                continue
            }
        }

        return deletedCount
    }

    static func removeAll() throws {
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        try FileManager.default.removeItem(at: directory)
    }

    private static func uniqueDestination(for filename: String) -> URL {
        let fallbackName = "imported-image"
        let baseName = URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent
        let ext = URL(fileURLWithPath: filename).pathExtension
        let safeBaseName = baseName.isEmpty ? fallbackName : baseName

        var candidate = directory.appendingPathComponent(filename.isEmpty ? fallbackName : filename)
        var index = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            let name = ext.isEmpty ? "\(safeBaseName)-\(index)" : "\(safeBaseName)-\(index).\(ext)"
            candidate = directory.appendingPathComponent(name)
            index += 1
        }

        return candidate
    }
}

private final class ByteHashState {
    private let queue = DispatchQueue(label: "duplicate-image-finder.byte-hash")
    private var hasher = SHA256()
    private var byteSize: Int64 = 0

    func update(_ data: Data) {
        queue.sync {
            hasher.update(data: data)
            byteSize += Int64(data.count)
        }
    }

    func result() -> PhotoLibraryDuplicateScanner.ByteHashResult {
        queue.sync {
            PhotoLibraryDuplicateScanner.ByteHashResult(
                hex: hasher.finalize().map { String(format: "%02x", $0) }.joined(),
                byteSize: byteSize
            )
        }
    }
}

private final class DisjointSet {
    private var parent: [Int]
    private var rank: [Int]

    init(count: Int) {
        parent = Array(0..<count)
        rank = Array(repeating: 0, count: count)
    }

    func find(_ value: Int) -> Int {
        if parent[value] != value {
            parent[value] = find(parent[value])
        }
        return parent[value]
    }

    func union(_ first: Int, _ second: Int) {
        let firstRoot = find(first)
        let secondRoot = find(second)
        guard firstRoot != secondRoot else { return }

        if rank[firstRoot] < rank[secondRoot] {
            parent[firstRoot] = secondRoot
        } else if rank[firstRoot] > rank[secondRoot] {
            parent[secondRoot] = firstRoot
        } else {
            parent[secondRoot] = firstRoot
            rank[firstRoot] += 1
        }
    }
}

private final class VisualBKTree {
    private final class Node {
        let fingerprint: VisualFingerprint
        var indexes: [Int]
        var children: [Int: Node] = [:]

        init(fingerprint: VisualFingerprint, index: Int) {
            self.fingerprint = fingerprint
            self.indexes = [index]
        }
    }

    private var root: Node?

    func insert(_ fingerprint: VisualFingerprint, index: Int) {
        guard let root else {
            root = Node(fingerprint: fingerprint, index: index)
            return
        }

        var node = root
        while true {
            let distance = fingerprint.distance(to: node.fingerprint)
            if distance == 0 {
                node.indexes.append(index)
                return
            }

            if let child = node.children[distance] {
                node = child
            } else {
                node.children[distance] = Node(fingerprint: fingerprint, index: index)
                return
            }
        }
    }

    func search(_ fingerprint: VisualFingerprint, threshold: Int) -> [Int] {
        guard let root else { return [] }

        var matches: [Int] = []
        search(root, fingerprint: fingerprint, threshold: threshold, matches: &matches)
        return matches
    }

    private func search(
        _ node: Node,
        fingerprint: VisualFingerprint,
        threshold: Int,
        matches: inout [Int]
    ) {
        let distance = fingerprint.distance(to: node.fingerprint)
        if distance <= threshold {
            matches.append(contentsOf: node.indexes)
        }

        let lower = max(0, distance - threshold)
        let upper = distance + threshold
        for childDistance in lower...upper {
            if let child = node.children[childDistance] {
                search(child, fingerprint: fingerprint, threshold: threshold, matches: &matches)
            }
        }
    }
}
