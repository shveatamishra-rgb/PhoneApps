import Photos
import PhotosUI
import SwiftUI
import CoreImage.CIFilterBuiltins
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = TransferViewModel()
    @State private var selectedPickerItems: [PhotosPickerItem] = []
    @State private var previewItem: PreviewItem?
    @State private var recentPage = 0
    @State private var showProSheet = false
    @AppStorage("ferryPro") private var isPro = false
    @AppStorage("appTheme") private var appTheme: AppTheme = .system

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    permissionCard
                    serverCard
                    sendCard
                    receivedCard
                    noteCard
                }
                .padding(16)
            }
            .background(Color.brandBackground.ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .navigationTitle("Ferry")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    proButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    themeMenu
                }
            }
            .task {
                await viewModel.refreshPhotoAuthorization()
            }
            .onChange(of: selectedPickerItems) { _, newItems in
                Task {
                    await viewModel.prepareOutgoingPhotos(from: newItems)
                }
            }
            .sheet(item: $previewItem) { item in
                AssetPreviewView(localIdentifier: item.id)
            }
            .sheet(isPresented: $showProSheet) {
                ProUpgradeView(isPro: $isPro, freeLimit: freeSelectionLimit)
            }
        }
        .tint(.brandPrimary)
        .preferredColorScheme(appTheme.colorScheme)
    }

    private var freeSelectionLimit: Int { 50 }

    @ViewBuilder
    private var proButton: some View {
        if isPro {
            Label("PRO", systemImage: "crown.fill")
                .labelStyle(.titleAndIcon)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.brandAccent)
        } else {
            Button {
                showProSheet = true
            } label: {
                Image(systemName: "crown")
                    .foregroundStyle(Color.brandAccent)
                    .accessibilityLabel("Go Pro")
            }
        }
    }

    private var themeMenu: some View {
        Menu {
            Picker("Appearance", selection: $appTheme) {
                ForEach(AppTheme.allCases) { theme in
                    Label(theme.label, systemImage: theme.systemImage).tag(theme)
                }
            }
        } label: {
            Image(systemName: appTheme.systemImage)
                .foregroundStyle(Color.brandPrimary)
                .accessibilityLabel("Appearance")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Original media bridge", systemImage: "photo.stack")
                .font(.headline)
                .foregroundStyle(Color.brandPrimary)

            Text("Move photos and videos between Android and iPhone over the same Wi-Fi without recompressing them. Received media is saved directly into Photos.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .sectionSurface()
    }

    @ViewBuilder
    private var permissionCard: some View {
        if !viewModel.canWritePhotos {
            VStack(alignment: .leading, spacing: 12) {
                Text("Photos permission needed")
                    .font(.headline)

                Text(viewModel.permissionMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button("Allow Photos Access") {
                    Task {
                        await viewModel.requestPhotoAuthorization()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .sectionSurface()
        }
    }

    private var serverCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Receive from Android", systemImage: "square.and.arrow.down")
                    .font(.headline)

                Spacer()

                Circle()
                    .fill(viewModel.isServerRunning ? Color.green : Color.secondary)
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)
            }

            Text("Keep both phones on the same Wi-Fi, start the receiver, then scan the code (or enter the address + PIN) in the Ferry app on Android.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let transferURL = viewModel.transferURL {
                QRCodeView(text: viewModel.qrPayload ?? transferURL)
                    .frame(width: 190, height: 190)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)

                Text(transferURL)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                if let pin = viewModel.transferPIN {
                    HStack(spacing: 8) {
                        Text("PIN")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(pin)
                            .font(.system(.title3, design: .monospaced).weight(.bold))
                            .foregroundStyle(Color.brandAccent)
                            .textSelection(.enabled)
                        Spacer()
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text("Scanning the code connects automatically. To open the address by hand, enter this PIN. Anyone on this Wi-Fi who has the PIN can connect while the receiver runs.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                Text(viewModel.receiverHint)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button {
                    Task {
                        await viewModel.toggleServer()
                    }
                } label: {
                    Label(
                        viewModel.isServerRunning ? "Stop Receiver" : "Start Receiver",
                        systemImage: viewModel.isServerRunning ? "stop.circle" : "play.circle"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canWritePhotos)

                if viewModel.receivedCount > 0 {
                    Text("\(viewModel.receivedCount) saved")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.isReceiving {
                Text(viewModel.receivingName.isEmpty ? "Receiving..." : "Receiving \(viewModel.receivingName)...")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if viewModel.receiveProgress > 0 {
                    ProgressView(value: min(max(viewModel.receiveProgress, 0), 1))
                        .tint(Color.brandPrimary)
                } else {
                    ProgressView()
                        .progressViewStyle(.linear)
                        .tint(Color.brandPrimary)
                }
            }

            Text(viewModel.status)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .sectionSurface()
    }

    private var sendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Send from iPhone", systemImage: "square.and.arrow.up")
                .font(.headline)

            Text("Choose iPhone photos or videos to make them available to the Ferry app on Android (or any browser on the same Wi-Fi). Originals are exported as their current Photo Library resources.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            PhotosPicker(
                selection: $selectedPickerItems,
                maxSelectionCount: isPro ? nil : freeSelectionLimit,
                matching: .any(of: [.images, .videos]),
                preferredItemEncoding: .current
            ) {
                Label("Choose Photos or Videos", systemImage: "photo.on.rectangle")
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.hasReadAccess)

            if viewModel.outgoingFiles.isEmpty {
                Text(viewModel.hasReadAccess ? "No media selected for Android yet." : "Allow Photos access first.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.outgoingFiles) { file in
                        HStack(spacing: 10) {
                            Image(systemName: file.mediaKind.systemImage)
                                .foregroundStyle(Color.brandAccent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(file.filename)
                                    .font(.callout.weight(.medium))
                                    .lineLimit(1)
                                Text(formatBytes(file.byteSize))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .sectionSurface()
    }

    private var receivedCard: some View {
        let pageSize = 8
        let total = viewModel.recentImports.count
        let pageCount = max(1, (total + pageSize - 1) / pageSize)
        let page = min(recentPage, pageCount - 1)
        let start = page * pageSize
        let visible = total == 0 ? [] : Array(viewModel.recentImports[start ..< min(start + pageSize, total)])

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Recent saves", systemImage: "checkmark.circle")
                    .font(.headline)
                Spacer()
                if total > 0 {
                    Text("\(total) total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.recentImports.isEmpty {
                Text("Uploaded Android photos and videos will appear here after they are saved to Photos.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(visible) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.didSave ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(item.didSave ? Color.green : Color.red)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.filename)
                                .font(.callout.weight(.medium))
                                .lineLimit(1)
                            Text(item.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if item.didSave, let id = item.localIdentifier {
                            Button {
                                previewItem = PreviewItem(id: id)
                            } label: {
                                Label("View", systemImage: "eye")
                                    .labelStyle(.titleAndIcon)
                                    .font(.caption.weight(.semibold))
                            }
                            .buttonStyle(.bordered)
                            .tint(Color.brandPrimary)
                        }
                    }
                }

                if pageCount > 1 {
                    HStack {
                        Button {
                            if page > 0 { recentPage = page - 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .disabled(page == 0)

                        Spacer()

                        Text("Page \(page + 1) of \(pageCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            if page < pageCount - 1 { recentPage = page + 1 }
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(page >= pageCount - 1)
                    }
                    .buttonStyle(.bordered)
                    .tint(Color.brandPrimary)
                    .padding(.top, 4)
                }
            }
        }
        .sectionSurface()
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("About quality and location", systemImage: "info.circle")
                .font(.headline)

            Text("The app transfers media files as bytes and saves received files as PhotoKit resources. Metadata, including GPS location when present, stays inside the original file.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .sectionSurface()
    }
}

private struct QRCodeView: View {
    let text: String

    var body: some View {
        if let image = Self.makeQRCode(from: text) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("QR code for transfer address")
        }
    }

    private static func makeQRCode(from text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"

        let context = CIContext()
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

private extension View {
    func sectionSurface() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.brandSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.brandBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 3, y: 1)
    }
}

private func formatBytes(_ value: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: value)
}

private struct PreviewItem: Identifiable {
    let id: String
}

private struct ProUpgradeView: View {
    @Binding var isPro: Bool
    let freeLimit: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color.brandAccent)
                    Text("Ferry Pro")
                        .font(.largeTitle.weight(.bold))
                }

                Text("Free includes up to \(freeLimit) files per transfer.")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    benefit("infinity", "Unlimited files per transfer")
                    benefit("sparkles", "More premium features coming soon")
                }

                if isPro {
                    Label("You're on Pro. Thank you!", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Color.brandPrimary)
                }

                Spacer()

                if isPro {
                    Button { dismiss() } label: {
                        Text("Done").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        isPro = true
                        dismiss()
                    } label: {
                        Text("Unlock Pro").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Text("Restore and real in-app purchase are coming soon.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(20)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .tint(.brandPrimary)
    }

    private func benefit(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color.brandAccent)
                .frame(width: 24)
            Text(text)
            Spacer()
        }
    }
}

private struct AssetPreviewView: View {
    let localIdentifier: String
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .navigationTitle("Saved to Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if let url = URL(string: "photos-redirect://") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open Photos", systemImage: "photo.on.rectangle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear(perform: loadImage)
        }
    }

    private func loadImage() {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject else {
            return
        }
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 1600, height: 1600),
            contentMode: .aspectFit,
            options: options
        ) { result, _ in
            if let result {
                image = result
            }
        }
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var systemImage: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon.stars"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

extension Color {
    // Brand palette: black + forest green + gold (dark), ivory + forest + gold (light).
    static let brandBackground = Color(lightHex: 0xF4EDDC, darkHex: 0x080D0A)
    static let brandSurface = Color(lightHex: 0xFFFDF6, darkHex: 0x0F1C15)
    static let brandSurfaceAlt = Color(lightHex: 0xECE3CF, darkHex: 0x16271D)
    static let brandText = Color(lightHex: 0x1F2A23, darkHex: 0xF0ECDE)
    static let brandMuted = Color(lightHex: 0x6C6450, darkHex: 0x9BB0A2)
    static let brandPrimary = Color(lightHex: 0x1F5130, darkHex: 0x2F9159)
    static let brandAccent = Color(lightHex: 0xB07D12, darkHex: 0xD8B450)
    static let brandBorder = Color(lightHex: 0xE0D7C0, darkHex: 0x1E3327)

    init(lightHex: UInt, darkHex: UInt) {
        self = Color(uiColor: UIColor { traits in
            UIColor(rgbHex: traits.userInterfaceStyle == .dark ? darkHex : lightHex)
        })
    }
}

private extension UIColor {
    convenience init(rgbHex: UInt) {
        self.init(
            red: CGFloat((rgbHex >> 16) & 0xFF) / 255,
            green: CGFloat((rgbHex >> 8) & 0xFF) / 255,
            blue: CGFloat(rgbHex & 0xFF) / 255,
            alpha: 1
        )
    }
}
