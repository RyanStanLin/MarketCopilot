import MarketCore
import SwiftUI

struct MenuBarTokenView: View {
    let token: MenuBarToken
    let store: AppStore
    let drag: MenuBarReorderState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var targets: [MenuBarTarget] {
        var values = store.menuBarTargets(for: token.metric)
        if let selected = token.target, !values.contains(where: { $0.id == selected.id }) { values.insert(selected, at: 0) }
        return values
    }

    private var targetChoices: [MenuBarChoice] {
        let values = targets
        let counts = Dictionary(grouping: values, by: \.displayName).mapValues(\.count)
        return values.map { target in
            let suffix = target.product == .perps ? L10n.text("Perps") : L10n.text("Predictions")
            let title = counts[target.displayName, default: 0] > 1
                ? "\(target.displayName) · \(suffix) · \(target.marketID.suffix(6))" : target.displayName
            return MenuBarChoice(id: target.id, title: title)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
                .frame(width: 17, height: 16)
                .padding(.leading, 8).padding(.trailing, 4)
                .frame(height: 32).contentShape(Rectangle())
                .help("Drag left or right to reorder")
                .accessibilityLabel(Text("Reorder token"))
                .accessibilityAction(named: Text("Move left")) { step(-1) }
                .accessibilityAction(named: Text("Move right")) { step(1) }
                .gesture(DragGesture(minimumDistance: 3, coordinateSpace: .named("menuBarEditor"))
                    .onChanged { value in
                        drag.update(id: token.id, value: value, tokens: store.refreshSettings.menuBarTokens, reduceMotion: reduceMotion)
                    }
                    .onEnded { _ in
                        store.reorderMenuBarTokens(drag.order)
                        drag.settle(reduceMotion: reduceMotion)
                    })
            HStack(alignment: .bottom, spacing: 6) {
                MenuBarComboBox(choices: MenuBarMetric.allCases.map { MenuBarChoice(id: $0.rawValue, title: $0.title) },
                                selection: token.metric.rawValue, placeholder: L10n.text("Metric"), onSelect: selectMetric)
                    .frame(width: token.metric.needsTarget ? MenuBarEditorTokens.pickerWidth : MenuBarEditorTokens.globalPickerWidth,
                           height: MenuBarEditorTokens.controlHeight)
                if token.metric.needsTarget {
                    Text("of").font(.title2).frame(height: 22)
                    MenuBarComboBox(choices: targetChoices,
                                    selection: token.target?.id, placeholder: L10n.text("Choose a market"), onSelect: selectTarget)
                        .frame(width: MenuBarEditorTokens.pickerWidth, height: MenuBarEditorTokens.controlHeight)
                }
            }.padding(4)
            Button(action: remove) {
                Image(systemName: "xmark.circle.fill").font(.system(size: 13))
                    .foregroundStyle(.secondary).frame(width: 16, height: 16)
                    .padding(.leading, 4).padding(.trailing, 8).frame(height: 32)
            }
            .buttonStyle(PressButtonStyle()).help("Remove token").accessibilityLabel(Text("Remove token"))
        }
        .padding(1)
        .background(MenuBarEditorTokens.tokenBackground, in: MenuBarEditorTokens.shape)
        .overlay { MenuBarEditorTokens.shape.strokeBorder(MenuBarEditorTokens.border, lineWidth: 1) }
        .frame(height: MenuBarEditorTokens.tokenHeight)
    }

    private func selectMetric(_ id: String) {
        guard let metric = MenuBarMetric(rawValue: id) else { return }
        withAnimation(reduceMotion ? nil : DesignTokens.drawerAnimation) { store.changeMenuBarMetric(metric, tokenID: token.id) }
    }

    private func selectTarget(_ id: String) {
        guard let target = targets.first(where: { $0.id == id }) else { return }
        store.changeMenuBarTarget(target, tokenID: token.id)
    }

    private func remove() {
        withAnimation(reduceMotion ? nil : DesignTokens.drawerAnimation) { store.deleteMenuBarToken(token.id) }
    }

    private func step(_ direction: Int) {
        withAnimation(reduceMotion ? nil : DesignTokens.drawerAnimation) { store.stepMenuBarToken(token.id, direction: direction) }
    }
}
