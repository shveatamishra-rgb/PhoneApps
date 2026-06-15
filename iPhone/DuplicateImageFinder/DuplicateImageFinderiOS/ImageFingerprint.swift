import CoreGraphics
import CoreImage
import CryptoKit
import Foundation
import ImageIO

enum ImageFingerprintError: LocalizedError {
    case invalidImage
    case imageTooLarge

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The image could not be decoded."
        case .imageTooLarge:
            return "The image is too large to safely decode."
        }
    }
}

struct PixelFingerprint: Hashable {
    let hex: String
    let width: Int
    let height: Int
}

struct VisualFingerprint: Hashable {
    static let duplicateThreshold = 6
    static let screenshotDuplicateThreshold = 2
    static let lumaDistanceThreshold = 8.0
    static let screenshotLumaDistanceThreshold = 3.0
    static let screenshotDarkMaskSimilarityThreshold = 0.85
    private static let darkLumaThreshold: UInt8 = 235

    let hash: UInt64
    let width: Int
    let height: Int
    let lumaSignature: [UInt8]

    var signature: String {
        String(format: "%016llx", hash)
    }

    var aspectRatio: Double {
        guard height > 0 else { return 0 }
        return Double(width) / Double(height)
    }

    var aspectBucket: Int {
        Int((aspectRatio * 50).rounded())
    }

    func distance(to other: VisualFingerprint) -> Int {
        (hash ^ other.hash).nonzeroBitCount
    }

    func lumaDistance(to other: VisualFingerprint) -> Double {
        guard lumaSignature.count == other.lumaSignature.count,
              !lumaSignature.isEmpty else {
            return .infinity
        }

        let total = zip(lumaSignature, other.lumaSignature).reduce(0) { sum, pair in
            sum + abs(Int(pair.0) - Int(pair.1))
        }
        return Double(total) / Double(lumaSignature.count)
    }

    func isDuplicateMatch(to other: VisualFingerprint, requiresScreenshotPrecision: Bool) -> Bool {
        let hashDistance = distance(to: other)
        let imageDistance = lumaDistance(to: other)

        if requiresScreenshotPrecision {
            return hashDistance <= Self.screenshotDuplicateThreshold
                && imageDistance <= Self.screenshotLumaDistanceThreshold
                && darkMaskSimilarity(to: other) >= Self.screenshotDarkMaskSimilarityThreshold
        }

        return hashDistance <= Self.duplicateThreshold
            && imageDistance <= Self.lumaDistanceThreshold
    }

    private func darkMaskSimilarity(to other: VisualFingerprint) -> Double {
        guard lumaSignature.count == other.lumaSignature.count,
              !lumaSignature.isEmpty else {
            return 0
        }

        var intersection = 0
        var union = 0
        for (left, right) in zip(lumaSignature, other.lumaSignature) {
            let leftIsDark = left < Self.darkLumaThreshold
            let rightIsDark = right < Self.darkLumaThreshold

            if leftIsDark || rightIsDark {
                union += 1
            }
            if leftIsDark && rightIsDark {
                intersection += 1
            }
        }

        guard union > 0 else { return 1 }
        return Double(intersection) / Double(union)
    }
}

enum ImageFingerprint {
    private static let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
    private static let maxDecodedBytes = 1_500_000_000

    static func byteSHA256(data: Data) -> String {
        hexString(SHA256.hash(data: data))
    }

    static func pixelSHA256(data: Data, orientation: CGImagePropertyOrientation? = nil) throws -> PixelFingerprint {
        let image = try orientedImage(data: data, orientation: orientation)
        let extent = image.extent.integral
        let width = Int(extent.width)
        let height = Int(extent.height)

        guard width > 0, height > 0 else {
            throw ImageFingerprintError.invalidImage
        }

        let rowBytes = width * 4
        let decodedBytes = rowBytes * height
        guard decodedBytes <= maxDecodedBytes else {
            throw ImageFingerprintError.imageTooLarge
        }

        var pixels = [UInt8](repeating: 0, count: decodedBytes)
        render(
            image,
            width: width,
            height: height,
            rowBytes: rowBytes,
            pixels: &pixels
        )

        var hasher = SHA256()
        hasher.update(data: Data("rgba8-srgb:\(width)x\(height):".utf8))
        hasher.update(data: Data(pixels))

        return PixelFingerprint(
            hex: hexString(hasher.finalize()),
            width: width,
            height: height
        )
    }

    static func visualHash(data: Data, orientation: CGImagePropertyOrientation? = nil) throws -> VisualFingerprint {
        let image = try orientedImage(data: data, orientation: orientation)
        let extent = image.extent.integral
        let sourceWidth = Int(extent.width)
        let sourceHeight = Int(extent.height)

        guard sourceWidth > 0, sourceHeight > 0 else {
            throw ImageFingerprintError.invalidImage
        }

        let sampleWidth = 9
        let sampleHeight = 8
        let rowBytes = sampleWidth * 4
        var pixels = [UInt8](repeating: 0, count: rowBytes * sampleHeight)

        let normalized = image.transformed(
            by: CGAffineTransform(translationX: -extent.origin.x, y: -extent.origin.y)
        )
        let scaled = normalized.transformed(
            by: CGAffineTransform(
                scaleX: CGFloat(sampleWidth) / CGFloat(sourceWidth),
                y: CGFloat(sampleHeight) / CGFloat(sourceHeight)
            )
        )

        render(
            scaled,
            width: sampleWidth,
            height: sampleHeight,
            rowBytes: rowBytes,
            pixels: &pixels
        )

        var hash: UInt64 = 0
        for y in 0..<sampleHeight {
            for x in 0..<(sampleWidth - 1) {
                let left = luminance(in: pixels, rowBytes: rowBytes, x: x, y: y)
                let right = luminance(in: pixels, rowBytes: rowBytes, x: x + 1, y: y)
                hash <<= 1
                if left > right {
                    hash |= 1
                }
            }
        }

        let detailSize = 32
        let detailRowBytes = detailSize * 4
        var detailPixels = [UInt8](repeating: 0, count: detailRowBytes * detailSize)
        let detailScaled = normalized.transformed(
            by: CGAffineTransform(
                scaleX: CGFloat(detailSize) / CGFloat(sourceWidth),
                y: CGFloat(detailSize) / CGFloat(sourceHeight)
            )
        )

        render(
            detailScaled,
            width: detailSize,
            height: detailSize,
            rowBytes: detailRowBytes,
            pixels: &detailPixels
        )

        var lumaSignature: [UInt8] = []
        lumaSignature.reserveCapacity(detailSize * detailSize)
        for y in 0..<detailSize {
            for x in 0..<detailSize {
                lumaSignature.append(UInt8(clamping: luminance(in: detailPixels, rowBytes: detailRowBytes, x: x, y: y)))
            }
        }

        return VisualFingerprint(
            hash: hash,
            width: sourceWidth,
            height: sourceHeight,
            lumaSignature: lumaSignature
        )
    }

    private static func orientedImage(data: Data, orientation: CGImagePropertyOrientation?) throws -> CIImage {
        let image: CIImage?
        if let orientation {
            image = CIImage(data: data)?.oriented(orientation)
        } else {
            image = CIImage(data: data, options: [.applyOrientationProperty: true])
        }

        guard let oriented = image else {
            throw ImageFingerprintError.invalidImage
        }

        let extent = oriented.extent
        guard extent.width.isFinite, extent.height.isFinite else {
            throw ImageFingerprintError.invalidImage
        }

        return oriented
    }

    private static func render(
        _ image: CIImage,
        width: Int,
        height: Int,
        rowBytes: Int,
        pixels: inout [UInt8]
    ) {
        let normalized = image.transformed(
            by: CGAffineTransform(translationX: -image.extent.origin.x, y: -image.extent.origin.y)
        )

        let context = CIContext(options: [
            .workingColorSpace: colorSpace,
            .outputColorSpace: colorSpace
        ])

        pixels.withUnsafeMutableBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            context.render(
                normalized,
                toBitmap: baseAddress,
                rowBytes: rowBytes,
                bounds: CGRect(x: 0, y: 0, width: width, height: height),
                format: .RGBA8,
                colorSpace: colorSpace
            )
        }
    }

    private static func luminance(in pixels: [UInt8], rowBytes: Int, x: Int, y: Int) -> Int {
        let index = y * rowBytes + x * 4
        let red = Double(pixels[index])
        let green = Double(pixels[index + 1])
        let blue = Double(pixels[index + 2])
        return Int((0.2126 * red + 0.7152 * green + 0.0722 * blue).rounded())
    }

    private static func hexString<D: Sequence>(_ digest: D) -> String where D.Element == UInt8 {
        digest.map { String(format: "%02x", $0) }.joined()
    }
}
