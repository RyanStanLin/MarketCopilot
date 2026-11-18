#if DEBUG
import AppKit
import MarketCore

/// A visible, isolated fixture for inspecting native controls and window compositing.
@MainActor
enum MenuBarEditorPreview {
    static func configure(_ store: AppStore) {
        let language: AppLanguage = CommandLine.arguments.contains("--preview-english") ? .english : .simplifiedChinese
        store.refreshSettings.language = language
        L10n.language = language
        store.refreshSettings.menuBarTokens = [MenuBarMetric.appIcon, .totalPortfolioWithOffset, .totalCashWithOffset, .perpsCashWithOffset]
            .map { MenuBarToken(metric: $0) }
        store.refreshDraft = store.refreshSettings
        NSApp.appearance = NSAppearance(named: CommandLine.arguments.contains("--preview-dark") ? .darkAqua : .aqua)
    }

    static func report(_ window: NSWindow) {
        let message = "Menu Bar preview: pid=\(ProcessInfo.processInfo.processIdentifier) window=\(window.windowNumber) frame=\(NSStringFromRect(window.frame))\n"
        FileHandle.standardOutput.write(Data(message.utf8))
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
            guard let view = window.contentView?.superview else { return }
            view.layoutSubtreeIfNeeded()
            view.displayIfNeeded()
            guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
            view.cacheDisplay(in: view.bounds, to: bitmap)
            let appearance = CommandLine.arguments.contains("--preview-dark") ? "dark" : "light"
            let path = URL.cachesDirectory.appending(path: "MenuBarPreview-\(appearance).png")
            do {
                try FileManager.default.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
                guard let data = bitmap.representation(using: .png, properties: [:]) else { return }
                try data.write(to: path)
                FileHandle.standardOutput.write(Data("Component: \(path.path)\n".utf8))
            } catch {
                FileHandle.standardOutput.write(Data("Component unavailable: \(error.localizedDescription)\n".utf8))
            }
        }
    }
}
#endif
