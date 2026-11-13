import AppKit
import ImageIO

@MainActor
enum IconImageDecoder {
    static func decode(_ data: Data, pointSize: CGFloat, displayScale: CGFloat) -> CGImage? {
        let pixels = max(1, Int(ceil(pointSize * displayScale)))
        let isSVG = String(decoding: data.prefix(1024), as: UTF8.self).contains("<svg")
        let sourceData = isSVG ? (EmbeddedSVGImage.extract(from: data) ?? data) : data
        if let source = CGImageSourceCreateWithData(sourceData as CFData, nil),
           let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: pixels,
                kCGImageSourceShouldCacheImmediately: true
           ] as CFDictionary) {
            guard let context = makeContext(pixels) else { return nil }
            context.interpolationQuality = .high
            context.draw(image, in: CGRect(x: 0, y: 0, width: pixels, height: pixels))
            return context.makeImage()
        }
        guard let image = NSImage(data: data), image.size.width > 0, image.size.height > 0,
              let context = makeContext(pixels) else { return nil }
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels),
                   from: NSRect(origin: .zero, size: image.size), operation: .copy, fraction: 1,
                   respectFlipped: false, hints: [.interpolation: NSImageInterpolation.high])
        return context.makeImage()
    }

    private static func makeContext(_ pixels: Int) -> CGContext? {
        CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    }
}
