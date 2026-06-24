import Combine
import CoreTransferable
import Foundation
import Photos
import PhotosUI
import StoreKit
import SwiftUI
import UniformTypeIdentifiers

/// Lifetime free allowance, kept in iCloud key-value storage so it is per-Apple-ID,
/// syncs across the user's devices, and survives reinstalls. Mirrored to UserDefaults
/// so it still works locally before the iCloud capability is enabled.
final class UsageTracker {
    static let freeLimit = 50
    private let key = "ferryLifetimeTransfers"
    private let cloud = NSUbiquitousKeyValueStore.default
    private let local = UserDefaults.standard

    init() {
        cloud.synchronize()
    }

    var count: Int {
        max(Int(cloud.longLong(forKey: key)), local.integer(forKey: key))
    }

    var remaining: Int {
        max(0, Self.freeLimit - count)
    }

    func increment(by amount: Int = 1) {
        let updated = count + amount
        cloud.set(Int64(updated), forKey: key)
        cloud.synchronize()
        local.set(updated, forKey: key)
    }
}

/// StoreKit 2 wrapper for the non-consumable "Ferry Pro" unlock.
@MainActor
final class PurchaseManager: ObservableObject {
    static let productID = "ferry_pro"

    @Published var isPro = false
    @Published var product: Product?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = listenForTransactions()
        Task {
            await loadProduct()
            await refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    var priceText: String { product?.displayPrice ?? "" }

    func loadProduct() async {
        product = try? await Product.products(for: [Self.productID]).first
    }

    func refreshEntitlements() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                owned = true
            }
        }
        isPro = owned
    }

    func purchase() async {
        guard let product else { return }
        guard let result = try? await product.purchase() else { return }
        if case .success(let verification) = result, case .verified(let transaction) = verification {
            await transaction.finish()
            isPro = true
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
    }
}

struct FreeLimitReachedError: LocalizedError {
    var errorDescription: String? {
        "The iPhone reached its free limit of \(UsageTracker.freeLimit) lifetime transfers. Ferry Pro unlocks unlimited."
    }
}

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
                .appendingPathComponent("FerryPicked", isDirectory: true)
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
    @Published var isPro = false
    @Published var lifetimeUsed = 0

    let purchase = PurchaseManager()
    private let usage = UsageTracker()
    private var cancellables = Set<AnyCancellable>()

    /// Files the free tier may still transfer (send or receive). Int.max once Pro.
    var freeRemaining: Int { isPro ? Int.max : usage.remaining }
    var freeLimit: Int { UsageTracker.freeLimit }

    private var server: PhotoTransferServer?
    private let photoBridge = PhotoLibraryBridge()

    init() {
        lifetimeUsed = usage.count
        purchase.$isPro
            .receive(on: RunLoop.main)
            .sink { [weak self] pro in
                self?.isPro = pro
                self?.updateServerAllowance()
            }
            .store(in: &cancellables)
    }

    /// Receive gate: blocks once the free lifetime allowance is used, then records the save.
    func handleIncomingUpload(_ upload: ReceivedUpload) async throws -> SavedMediaMetadata {
        if !isPro && usage.remaining <= 0 {
            throw FreeLimitReachedError()
        }
        let metadata = try await photoBridge.saveReceivedMediaToPhotos(upload)
        recordTransfer()
        return metadata
    }

    func recordTransfer(_ amount: Int = 1) {
        usage.increment(by: amount)
        lifetimeUsed = usage.count
        updateServerAllowance()
    }

    func purchasePro() async {
        await purchase.purchase()
    }

    func restorePro() async {
        await purchase.restore()
    }

    private func updateServerAllowance() {
        let allowance: Int? = isPro ? nil : usage.remaining
        Task { await server?.setDownloadAllowance(allowance) }
    }

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
                onUpload: { [weak self] upload in
                    guard let self else { throw CancellationError() }
                    return try await self.handleIncomingUpload(upload)
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
                },
                onDownloadServed: { [weak self] in
                    Task { @MainActor in
                        self?.recordTransfer()
                    }
                }
            )

            try await server.start()
            self.server = server
            await server.setDownloadAllowance(isPro ? nil : freeRemaining)
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
