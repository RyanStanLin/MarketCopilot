import AppKit
import SwiftUI

struct RemoteImage: View {
    let url: URL?
    var fixtureName: String?
    var fallbackSymbol = "photo"
    var size: CGFloat = DesignTokens.iconSize
    @State private var loaded: CGImage?
    @Environment(\.displayScale) private var displayScale
    private var loadID: String { "\(url?.absoluteString ?? "")|\(size)|\(displayScale)" }

    var body: some View {
        Group {
            if let fixtureName {
                Image(fixtureName).resizable()
            } else if let loaded {
                Image(decorative: loaded, scale: displayScale).resizable()
            } else {
                Image(systemName: fallbackSymbol).resizable().scaledToFit()
                    .foregroundStyle(DesignTokens.tertiary).padding(4)
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .fixedSize()
        .task(id: loadID, load)
        .accessibilityHidden(true)
    }

    private func load() async {
        loaded = nil
        guard let url, url.scheme == "https" else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard !Task.isCancelled, (response as? HTTPURLResponse)?.statusCode == 200,
                  data.count <= 5_000_000 else { return }
            loaded = IconImageDecoder.decode(data, pointSize: size, displayScale: displayScale)
        } catch { /* Keep the semantic placeholder when an optional image is unavailable. */ }
    }
}
