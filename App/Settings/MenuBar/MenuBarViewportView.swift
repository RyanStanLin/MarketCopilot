import AppKit
import CoreImage.CIFilterBuiltins
import QuartzCore
import SwiftUI

/// This native boundary clips every descendant, including AppKit combo-box layers.
/// Core Image filters the actual composited content, so controls stay live while blurring.
final class MenuBarViewportView: NSView {
    let host: NSHostingView<MenuBarTokenLane>
    private let driver: MenuBarScrollDriver
    private let edgeMask = CAGradientLayer()
    private var lastSize = CGSize.zero
    private var lastScale: CGFloat = 0
    private var lastLeft: CGFloat = -1
    private var lastRight: CGFloat = -1

    init(content: MenuBarTokenLane, driver: MenuBarScrollDriver) {
        self.driver = driver
        host = NSHostingView(rootView: content)
        super.init(frame: .zero)
        wantsLayer = true
        clipsToBounds = true
        layer?.masksToBounds = true
        host.sizingOptions = []
        host.autoresizingMask = [.width, .height]
        addSubview(host)
        edgeMask.startPoint = CGPoint(x: 0, y: 0.5)
        edgeMask.endPoint = CGPoint(x: 1, y: 0.5)
        layer?.mask = edgeMask
        driver.onScrollChange = { [weak self] in self?.updateEdges() }
    }

    required init?(coder: NSCoder) { nil }

    override func layout() {
        super.layout()
        host.frame = bounds
        updateEdges()
    }

    override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        updateEdges()
    }

    func detach() { driver.onScrollChange = {}; driver.detach() }

    func updateEdges() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let scale = window?.backingScaleFactor ?? 2
        let extent = driver.edgeDistances
        let left = Self.strength(extent.leading)
        let right = Self.strength(extent.trailing)
        guard bounds.size != lastSize || scale != lastScale || abs(left - lastLeft) > 0.001 || abs(right - lastRight) > 0.001 else { return }
        lastSize = bounds.size; lastScale = scale; lastLeft = left; lastRight = right

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        edgeMask.frame = bounds
        edgeMask.contentsScale = scale
        let band = min(MenuBarEditorTokens.edgeWidth, bounds.width / 2) / bounds.width
        edgeMask.locations = [0, band * 0.25, band * 0.5, band * 0.75, band,
                              1 - band, 1 - band * 0.75, 1 - band * 0.5, 1 - band * 0.25, 1].map { NSNumber(value: Double($0)) }
        edgeMask.colors = [1 - left, 1 - left * 0.85, 1 - left * 0.5, 1 - left * 0.15, 1,
                           1, 1 - right * 0.15, 1 - right * 0.5, 1 - right * 0.85, 1 - right]
            .map { CGColor(gray: 1, alpha: $0) }
        CATransaction.commit()

        guard left > 0 || right > 0 else { contentFilters = []; return }
        let imageBounds = CGRect(origin: .zero, size: CGSize(width: bounds.width * scale, height: bounds.height * scale))
        let edge = min(MenuBarEditorTokens.edgeWidth * scale, imageBounds.width / 2)
        let leading = CIFilter.linearGradient()
        leading.point0 = .zero
        leading.point1 = CGPoint(x: edge, y: 0)
        leading.color0 = CIColor(red: left, green: left, blue: left)
        leading.color1 = .black
        let trailing = CIFilter.linearGradient()
        trailing.point0 = CGPoint(x: imageBounds.width - edge, y: 0)
        trailing.point1 = CGPoint(x: imageBounds.width, y: 0)
        trailing.color0 = .black
        trailing.color1 = CIColor(red: right, green: right, blue: right)
        let maximum = CIFilter.maximumCompositing()
        maximum.inputImage = leading.outputImage?.cropped(to: imageBounds)
        maximum.backgroundImage = trailing.outputImage?.cropped(to: imageBounds)
        let blur = CIFilter.maskedVariableBlur()
        blur.mask = maximum.outputImage?.cropped(to: imageBounds)
        blur.radius = Float(MenuBarEditorTokens.edgeBlurRadius * scale)
        contentFilters = [blur]
    }

    private static func strength(_ distance: CGFloat) -> CGFloat {
        let t = min(1, max(0, distance / 16))
        return t * t * t * (t * (t * 6 - 15) + 10)
    }
}
