import Foundation

/// Some official logos wrap one PNG in an SVG pattern. AppKit can mis-scale that pattern.
/// Unwrap only that simple form; vector/composite SVGs retain their normal rendering path.
nonisolated final class EmbeddedSVGImage: NSObject, XMLParserDelegate {
    private var imageCount = 0
    private var patternCount = 0
    private var isSimple = true
    private var imageID: String?
    private var usedID: String?
    private var embeddedData: Data?

    static func extract(from data: Data) -> Data? {
        let delegate = EmbeddedSVGImage()
        let parser = XMLParser(data: data)
        parser.shouldResolveExternalEntities = false
        parser.delegate = delegate
        guard parser.parse(), delegate.isSimple, delegate.imageCount == 1, delegate.patternCount == 1,
              let imageID = delegate.imageID, delegate.usedID == "#" + imageID else { return nil }
        return delegate.embeddedData
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributes: [String: String]) {
        let name = elementName.split(separator: ":").last.map(String.init) ?? elementName
        switch name {
        case "pattern":
            patternCount += 1
            if attributes["patternContentUnits"] != "objectBoundingBox"
                || attributes["width"] != "1" || attributes["height"] != "1" { isSimple = false }
        case "use": usedID = attributes["href"] ?? attributes["xlink:href"]
        case "image":
            imageCount += 1
            imageID = attributes["id"]
            guard let source = attributes["href"] ?? attributes["xlink:href"],
                  source.hasPrefix("data:image/"), let comma = source.firstIndex(of: ","),
                  source[..<comma].hasSuffix(";base64") else { return }
            embeddedData = Data(base64Encoded: String(source[source.index(after: comma)...]), options: .ignoreUnknownCharacters)
        case "path", "circle", "ellipse", "polygon", "polyline", "text", "line", "filter", "mask":
            isSimple = false
        default: break
        }
    }
}
