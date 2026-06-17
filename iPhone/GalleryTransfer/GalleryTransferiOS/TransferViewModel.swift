import CoreTransferable
import Foundation
import Photos
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

enum TransferMediaKind: String, Hashable, Sendable {
    case image
    case video

    var systemImage: String {
        switch self {
        case .image: return "photo"
        case .video: return "video"
        }
    }
}

struct OutgoingPhotoFile: Identifiable, Hashable, Sendable {
    let id: String
    let filename: String
    let byteSize: Int64
    let url: URL
    let mediaKind: TransferMediaKind
}

/// A media original copied out of the Photos picker into app-owned temp storage.
/// `FileRepresentation` streams the bytes to disk, so a multi-GB video is never
/// held entirely in memory, and we don't depend on a (possibly nil) asset identifier.
struct PickedMediaFile: Transferable {
    let url: URL
    let suggestedName: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .item) { received in
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("GalleryTransferPicked", isDirectory: true)
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            let destination = directory.appendingPathComponent(received.file.lastPathComponent)
            try FileManager.default.copyItem(at: received.file, to: destination)
            return PickedMediaFile(url: destination, suggestedName: received.file.lastPathComponent)
        }
    }
}

struct RecentImport: Identifiable {
    let id = UUID()
    let filename: String
    let message: String
    let didSave: Bool
    let localIdentifier: String?
}

@MainActor
final class TransferViewModel: ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @Published var isServerRunning = false
    @Published var transferURL: String?
    @Published var qrPayload: String?
    @Published var transferPIN: String?
    @Published var status = "Receiver is stopped."
    @Published var outgoingFiles: [OutgoingPhotoFile] = []
    @Published var recentImports: [RecentImport] = []
    @Published var receivedCount = 0
    @Published var isReceiving = false
    @Published var receivingName = ""
    @Published var receiveProgress: Double = 0

    private var server: PhotoTransferServer?
    private let photoBridge = PhotoLibraryBridge()

    var canWritePhotos: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }

    var hasReadAccess: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }

    var permissionMessage: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Gallery Transfer needs Photos access so received media can land directly in the Photos app."
        case .denied, .restricted:
            return "Photos access is off. Enable it in Settings to save received photos and videos directly to Photos."
        case .limited:
            return "Limited Photos access is enabled. Receiving still works, and sending can use the photos you choose."
        case .authorized:
            return "Photos access is enabled."
        @unknown default:
            return "Photos access is unavailable."
        }
    }

    var receiverHint: String {
        if !canWritePhotos {
            return "Allow Photos access to start receiving."
        }
        return "Start the receiver to get a local transfer address."
    }

    func refreshPhotoAuthorization() async {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestPhotoAuthorization() async {
        authorizationStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    func toggleServer() async {
        if isServerRunning {
            await stopServer()
        } else {
            await startServer()
        }
    }

    func prepareOutgoingPhotos(from pickerItems: [PhotosPickerItem]) async {
        guard hasReadAccess else {
            status = "Allow Photos access before choosing images."
            return
        }

        do {
            status = "Preparing originals for Android..."
            try photoBridge.beginOutgoingExport()

            var files: [OutgoingPhotoFile] = []
            for item in pickerItems {
                var exported: OutgoingPhotoFile?

                // Prefer the true Photos original (guaranteed GPS/EXIF). Fall back to the
                // picker's own file only when the asset identifier is nil or the asset
                // isn't fetchable under limited access.
                if let identifier = item.itemIdentifier {
                    exported = try? await photoBridge.exportAssetOriginal(localIdentifier: identifier)
                }
                if exported == nil,
                   let picked = try? await item.loadTransferable(type: PickedMediaFile.self) {
                    exported = try? photoBridge.adoptPickedFile(picked)
                }

                if let exported {
                    files.append(exported)
                }
            }

            outgoingFiles = files
            await server?.updateOutgoingFiles(outgoingFiles)
            status = outgoingFiles.isEmpty
                ? "No readable original media items were selected."
                : "Prepared \(outgoingFiles.count) original media files."
        } catch {
            status = "Could not prepare photos: \(error.localizedDescription)"
        }
    }

    private func startServer() async {
        guard canWritePhotos else {
            status = "Allow Photos access first."
            return
        }

        do {
            let server = PhotoTransferServer(
                port: 8899,
                outgoingFiles: outgoingFiles,
                onUpload: { [photoBridge] upload in
                    try await photoBridge.saveReceivedMediaToPhotos(upload)
                },
                onUploadStarted: { [weak self] name in
                    Task { @MainActor in
                        self?.isReceiving = true
                        self?.receivingName = name
                        self?.receiveProgress = 0
                        self?.status = "Receiving \(name)..."
                    }
                },
                onUploadProgress: { [weak self] fraction in
                    Task { @MainActor in
                        self?.receiveProgress = fraction
                    }
                },
                onUploadFinished: { [weak self] result in
                    Task { @MainActor in
                        self?.recordUploadResult(result)
                    }
                }
            )

            try await server.start()
            self.server = server
            isServerRunning = true

            let pin = server.accessPIN
            transferPIN = pin

            if let address = NetworkInterface.wifiIPv4Address() {
                let base = "http://\(address):\(server.port)"
                transferURL = base
                qrPayload = "\(base)/?pin=\(pin)"
                status = "Receiver is running. Scan the code on Android, or open the address and enter the PIN."
            } else {
                let base = "http://iphone.local:\(server.port)"
                transferURL = base
                qrPayload = "\(base)/?pin=\(pin)"
                status = "Receiver is running. If the address does not open, connect both phones to the same Wi-Fi."
            }
        } catch {
            status = "Could not start receiver: \(error.localizedDescription)"
            isServerRunning = false
            transferURL = nil
            qrPayload = nil
            transferPIN = nil
        }
    }

    private func stopServer() async {
        await server?.stop()
        server = nil
        isServerRunning = false
        isReceiving = false
        receivingName = ""
        receiveProgress = 0
        transferURL = nil
        qrPayload = nil
        transferPIN = nil
        // The staged send copies are only reachable through the now-stopped server,
        // so free that temp space and clear the list that pointed at it.
        photoBridge.clearExportedOriginals()
        outgoingFiles = []
        status = "Receiver is stopped."
    }

    private func recordUploadResult(_ result: UploadResult) {
        isReceiving = false
        receivingName = ""
        receiveProgress = 0
        if result.didSave {
            receivedCount += 1
        }

        recentImports.insert(
            RecentImport(
                filename: result.filename,
                message: result.message,
                didSave: result.didSave,
                localIdentifier: result.localIdentifier
            ),
            at: 0
        )

        // Keep a generous history (UI paginates); bound it so memory stays sane.
        if recentImports.count > 300 {
            recentImports = Array(recentImports.prefix(300))
        }

        status = result.message
    }
}
