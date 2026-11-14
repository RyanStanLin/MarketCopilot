import SwiftUI
import MarketCore

struct PositionsContent: View {
    let store: AppStore
    let product: MarketProduct
    let viewportHeight: CGFloat
    @State private var scroll = DrawerScrollState()
    @State private var keyboardIndex: Int?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var items: [DrawerItem] {
        product == .predictions ? store.predictionPositions.map(DrawerItem.prediction) : store.positions.map(DrawerItem.perps)
    }
    private var rowHeight: CGFloat { product == .predictions ? DesignTokens.predictionHeight : DesignTokens.positionHeight }
    private var naturalHeight: CGFloat { 12 + CGFloat(max(1, items.count)) * rowHeight + CGFloat(max(0, items.count - 1)) * 31 }
    private var canScroll: Bool { naturalHeight > viewportHeight + 0.5 }
    private var active: Bool { product == .predictions ? store.isPredictionsExpanded : store.isPerpsExpanded }
    private var hasSnapshot: Bool { product == .predictions ? store.snapshot.predictions != nil : store.snapshot.perps != nil }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: DesignTokens.rowGap) {
                    if items.isEmpty {
                        Text(L10n.text(hasSnapshot ? "No open positions" : "Unavailable"))
                            .font(DesignTokens.caption).foregroundStyle(DesignTokens.secondary)
                            .frame(maxWidth: .infinity).frame(height: rowHeight)
                    }
                    ForEach(items) { item in
                        VStack(spacing: DesignTokens.rowGap) {
                            VStack(spacing: 0) {
                                switch item {
                                case .prediction(let position): PredictionRow(position: position, store: store)
                                case .perps(let position): PositionRow(position: position, store: store)
                                }
                            }
                            .frame(width: DesignTokens.menuWidth - 2 * DesignTokens.inset)
                            // Include the complete rounded hover background in the raster layer.
                            .padding(.horizontal, DesignTokens.positionHoverOutset)
                            .modifier(DrawerReelEffect(viewportHeight: viewportHeight,
                                topStrength: canScroll ? scroll.topStrength : 0,
                                bottomStrength: canScroll ? scroll.bottomStrength : 0))
                            .animation(DesignTokens.scrollEffectAnimation, value: scroll.topStrength)
                            .animation(DesignTokens.scrollEffectAnimation, value: scroll.bottomStrength)
                            if item.id != items.last?.id {
                                MenuSeparator().padding(.horizontal, DesignTokens.positionHoverOutset)
                                    .modifier(DrawerReelEffect(viewportHeight: viewportHeight,
                                        topStrength: canScroll ? scroll.topStrength : 0,
                                        bottomStrength: canScroll ? scroll.bottomStrength : 0))
                                    .animation(DesignTokens.scrollEffectAnimation, value: scroll.topStrength)
                                    .animation(DesignTokens.scrollEffectAnimation, value: scroll.bottomStrength)
                            }
                        }
                        .id(item.id)
                    }
                }
                .frame(width: DesignTokens.menuWidth - 2 * (DesignTokens.inset - DesignTokens.positionHoverOutset))
                .padding(.horizontal, DesignTokens.inset - DesignTokens.positionHoverOutset)
                .padding(.vertical, 6)
                .id(product.rawValue + "-start")
                .background(DrawerScrollAxisLock())
            }
            .scrollIndicators(.never).scrollDisabled(!canScroll).scrollBounceBehavior(.basedOnSize)
            .onScrollGeometryChange(for: DrawerScrollState.self) { geometry in
                let offset = max(0, geometry.contentOffset.y + geometry.contentInsets.top)
                let extent = max(0, geometry.contentSize.height + geometry.contentInsets.top
                    + geometry.contentInsets.bottom - geometry.containerSize.height)
                let remaining = max(0, extent - offset)
                return DrawerScrollState(offset: offset, remaining: remaining)
            } action: { _, value in scroll = value }
            .onScrollPhaseChange { _, phase in
                if phase == .interacting || phase == .tracking || phase == .decelerating { keyboardIndex = nil }
            }
            .onChange(of: items.map(\.id)) { keyboardIndex = nil }
            .onChange(of: store.drawerKeyboardRequest) {
                guard active, canScroll, !items.isEmpty else { return }
                let current = keyboardIndex ?? Int((scroll.offset / (rowHeight + 31)).rounded())
                let next = min(max(0, current + store.drawerKeyboardDirection), max(0, items.count - 2))
                keyboardIndex = next
                withAnimation(reduceMotion ? nil : DesignTokens.drawerAnimation) {
                    proxy.scrollTo(next == 0 ? product.rawValue + "-start" : items[next].id, anchor: .top)
                }
            }
        }
        .frame(width: DesignTokens.menuWidth, height: max(0, viewportHeight))
    }
}
