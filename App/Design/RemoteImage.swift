import AppKit
import SwiftUI

struct RemoteImage: View {
    let url: URL?
    var fixtureName: String?
    var fallbackSymbol = "photo"
    @State private var loaded: NSImage?

    var body: some View {
        Group {
            if let fixtureName {
                Image(fixtureName).resizable().aspectRatio(contentMode: .fill)
            } else if let loaded {
                Image(nsImage: loaded).resizable().aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: fallbackSymbol).resizable().scaledToFit()
                    .foregroundStyle(DesignTokens.tertiary).padding(4)
            }
        }
        .task(id: url, load)
        .accessibilityHidden(true)
    }

    private func load() async {
        loaded = nil
        guard let url, url.scheme == "https" else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard !Task.isCancelled, (response as? HTTPURLResponse)?.statusCode == 200,
                  data.count <= 5_000_000 else { return }
            loaded = NSImage(data: data)
        } catch { /* Keep the semantic placeholder when an optional image is unavailable. */ }
    }
}
