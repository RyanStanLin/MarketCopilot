import SwiftUI

struct MenuBarWiggle: ViewModifier {
    let id: UUID
    let enabled: Bool

    private var variation: Double { Double(id.uuid.0 % 5) / 5 }

    func body(content: Content) -> some View {
        content.phaseAnimator(enabled ? [-1.0, 1.0] : [0.0]) { view, phase in
            view.rotationEffect(.degrees(phase * (0.3 + variation * 0.25)))
                .offset(y: phase * 0.2)
        } animation: { _ in
            .easeInOut(duration: 0.17 + variation * 0.05)
        }
    }
}
