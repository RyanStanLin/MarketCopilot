#if DEBUG
import AppKit
import SwiftUI

@MainActor
final class MenuMotionValidation {
    private let store: AppStore
    private let panel: NSPanel
    private var frames: [String: CGRect] = [:]
    private var samples: [[String: Any]] = []

    private init(store: AppStore, panel: NSPanel) {
        self.store = store
        self.panel = panel
    }

    static func run(store: AppStore, panel: NSPanel) {
        let validation = MenuMotionValidation(store: store, panel: panel)
        store.menuLayoutObserved = { [weak validation] component, frame in
            validation?.frames[component] = frame
        }
        Task { await validation.run() }
    }

    private func run() async {
        try? await Task.sleep(for: .milliseconds(600))
        let top = panel.frame.maxY
        let left = panel.frame.minX
        await sample(phase: "collapsed", duration: 0.08)
        store.toggleDrawer()
        await sample(phase: "opening", duration: 0.65)
        store.toggleDrawer()
        await sample(phase: "closing", duration: 0.65)
        store.toggleDrawer()
        await sample(phase: "interruptedOpening", duration: 0.08)
        store.toggleDrawer()
        await sample(phase: "interruptedClosing", duration: 0.65)
        let tolerance = 1 / panel.backingScaleFactor
        let checks: [String: Bool] = [
            "sampledIntermediateFrames": samples.contains { sample in
                guard let height = sample["windowHeight"] as? CGFloat else { return false }
                return height > 340 && height < 650
            },
            "windowTopAndLeftStayFixed": samples.allSatisfy {
                abs(($0["windowTop"] as? CGFloat ?? .infinity) - top) <= tolerance
                    && abs(($0["windowLeft"] as? CGFloat ?? .infinity) - left) <= tolerance
            },
            "headerStaysAtTop": samples.allSatisfy {
                abs($0["headerY"] as? CGFloat ?? .infinity) <= tolerance
                    && abs(($0["headerHeight"] as? CGFloat ?? .infinity) - 159) <= tolerance
            },
            "drawerContentStaysBelowParent": samples.allSatisfy {
                abs(($0["drawerContentY"] as? CGFloat ?? .infinity) - 159) <= tolerance
                    && abs(($0["drawerViewportY"] as? CGFloat ?? .infinity) - 159) <= tolerance
            },
            "cashFollowsClippedViewport": samples.allSatisfy {
                abs(($0["cashY"] as? CGFloat ?? .infinity) - 159 - ($0["drawerViewportHeight"] as? CGFloat ?? 0)) <= tolerance
            },
            "reversedAnimationReturnsToCollapsedHeight": abs(panel.frame.height - 327) <= tolerance
        ]
        let passed = checks.values.allSatisfy { $0 }
        do {
            let directory = URL.cachesDirectory.appending(path: "DesignValidation", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let report: [String: Any] = ["checks": checks, "passed": passed, "samples": samples]
            let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: directory.appending(path: "menu-motion-validation.json"))
            print("Menu motion: \(checks), \(samples.count) native frame samples")
        } catch { print("Menu motion report failed: \(error)"); exit(1) }
        if !passed { exit(1) }
        NSApp.terminate(nil)
    }

    private func sample(phase: String, duration: TimeInterval) async {
        let deadline = Date().addingTimeInterval(duration)
        while Date() < deadline {
            try? await Task.sleep(for: .milliseconds(8))
            guard let header = frames["header"], let drawer = frames["drawerContent"],
                  let viewport = frames["drawerViewport"], let cash = frames["cash"] else { continue }
            samples.append(["phase": phase, "windowTop": panel.frame.maxY, "windowLeft": panel.frame.minX,
                "windowHeight": panel.frame.height, "headerY": header.minY, "headerHeight": header.height,
                "drawerContentY": drawer.minY, "drawerViewportY": viewport.minY,
                "drawerViewportHeight": viewport.height, "cashY": cash.minY])
        }
    }
}
#endif
