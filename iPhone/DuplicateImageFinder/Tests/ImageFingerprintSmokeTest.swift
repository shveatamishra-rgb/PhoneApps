import AppKit
import Foundation
import ImageIO

@main
struct ImageFingerprintSmokeTest {
    static func main() throws {
        let png = try imageData(type: .png)
        let tiff = try imageData(type: .tiff)
        let jpegHigh = try imageData(type: .jpeg, compression: 0.95)
        let jpegLow = try imageData(type: .jpeg, compression: 0.45)

        let pngPixelHash = try ImageFingerprint.pixelSHA256(data: png)
        let tiffPixelHash = try ImageFingerprint.pixelSHA256(data: tiff)
        guard pngPixelHash.hex == tiffPixelHash.hex else {
            throw SmokeTestError.expectedPixelMatch
        }

        guard ImageFingerprint.byteSHA256(data: jpegHigh) != ImageFingerprint.byteSHA256(data: jpegLow) else {
            throw SmokeTestError.expectedDifferentBytes
        }

        let highPixelHash = try ImageFingerprint.pixelSHA256(data: jpegHigh)
        let lowPixelHash = try ImageFingerprint.pixelSHA256(data: jpegLow)
        guard highPixelHash.hex != lowPixelHash.hex else {
            throw SmokeTestError.expectedDifferentPixels
        }

        let highVisualHash = try ImageFingerprint.visualHash(data: jpegHigh)
        let lowVisualHash = try ImageFingerprint.visualHash(data: jpegLow)
        let distance = highVisualHash.distance(to: lowVisualHash)
        guard distance <= VisualFingerprint.duplicateThreshold else {
            throw SmokeTestError.expectedVisualMatch(distance)
        }

        let firstScreenshot = try screenshotLikeImageData(text: "Bank OTP 482913\nMeeting notes\nInvoice paid")
        let secondScreenshot = try screenshotLikeImageData(text: "Recipe ideas\nFlight change\nCalendar invite")
        let firstScreenshotHash = try ImageFingerprint.visualHash(data: firstScreenshot)
        let secondScreenshotHash = try ImageFingerprint.visualHash(data: secondScreenshot)
        guard !firstScreenshotHash.isDuplicateMatch(
            to: secondScreenshotHash,
            requiresScreenshotPrecision: true
        ) else {
            throw SmokeTestError.expectedDifferentScreenshots
        }

        print("Smoke test passed: recompressed visual distance \(distance).")
    }

    private static func imageData(type: NSBitmapImageRep.FileType, compression: CGFloat? = nil) throws -> Data {
        let width = 96
        let height = 72
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw SmokeTestError.cannotCreateImage
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

        for y in 0..<height {
            for x in 0..<width {
                let red = CGFloat(x) / CGFloat(width)
                let green = CGFloat(y) / CGFloat(height)
                let blue = CGFloat((x * y) % 29) / 28.0
                NSColor(red: red, green: green, blue: blue, alpha: 1).setFill()
                NSRect(x: x, y: y, width: 1, height: 1).fill()
            }
        }

        NSGraphicsContext.restoreGraphicsState()

        var properties: [NSBitmapImageRep.PropertyKey: Any] = [:]
        if let compression {
            properties[.compressionFactor] = compression
        }

        guard let data = rep.representation(using: type, properties: properties) else {
            throw SmokeTestError.cannotEncodeImage
        }

        return data
    }

    private static func screenshotLikeImageData(text: String) throws -> Data {
        let width = 390
        let height = 844
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw SmokeTestError.cannotCreateImage
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

        NSColor.white.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()

        NSColor(calibratedWhite: 0.94, alpha: 1).setFill()
        NSRect(x: 0, y: height - 96, width: width, height: 96).fill()

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 11
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24, weight: .regular),
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraph
        ]
        NSAttributedString(string: text, attributes: attributes)
            .draw(in: NSRect(x: 28, y: 260, width: width - 56, height: 260))

        NSGraphicsContext.restoreGraphicsState()

        guard let data = rep.representation(using: .png, properties: [:]) else {
            throw SmokeTestError.cannotEncodeImage
        }

        return data
    }
}

private enum SmokeTestError: LocalizedError {
    case cannotCreateImage
    case cannotEncodeImage
    case expectedPixelMatch
    case expectedDifferentBytes
    case expectedDifferentPixels
    case expectedVisualMatch(Int)
    case expectedDifferentScreenshots

    var errorDescription: String? {
        switch self {
        case .cannotCreateImage:
            return "Could not create a test bitmap."
        case .cannotEncodeImage:
            return "Could not encode a test image."
        case .expectedPixelMatch:
            return "Expected the PNG and TIFF encodings to decode to identical pixels."
        case .expectedDifferentBytes:
            return "Expected recompressed JPEG images to have different bytes."
        case .expectedDifferentPixels:
            return "Expected recompressed JPEG images to decode to different pixels."
        case .expectedVisualMatch(let distance):
            return "Expected recompressed JPEG images to match visually; distance was \(distance)."
        case .expectedDifferentScreenshots:
            return "Expected different text-heavy screenshots not to match visually."
        }
    }
}
