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

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: DesignTokens.rowGap) {
                    if items.isEmpty {
                        Text("No open positions").font(DesignTokens.caption).foregroundStyle(DesignTokens.secondary)
                            .frame(maxWidth: .infinity).frame(height: rowHeight)
                    }
                    ForEach(items) { item in
                        Group {
                            switch item {
                            case .prediction(let position): PredictionRow(position: position, store: store)
                            case .perps(let position): PositionRow(position: position, store: store)
                            }
                        }
                        .modifier(DrawerReelEffect(viewportHeight: viewportHeight,
                            topActive: canScroll && scroll.hasAbove, bottomActive: canScroll && scroll.hasBelow))
                        .id(item.id)
                        if item.id != items.last?.id { MenuSeparator() }
                    }
                }
                .padding(.vertical, 6)
                .id(product.rawValue + "-start")
            }
            .scrollIndicators(.never).scrollDisabled(!canScroll).scrollBounceBehavior(.basedOnSize)
            .onScrollGeometryChange(for: DrawerScrollState.self) { geometry in
                let offset = max(0, geometry.contentOffset.y + geometry.contentInsets.top)
                return DrawerScrollState(offset: offset, hasAbove: offset > 0.5,
                    hasBelow: offset + geometry.containerSize.height < geometry.contentSize.height - 0.5)
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
            .overlay(alignment: .top) {
                if canScroll && scroll.hasAbove {
                    LinearGradient(colors: [Color(nsColor: .systemGray), .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: DesignTokens.scrollShadowHeight).padding(.horizontal, -DesignTokens.inset)
                        .allowsHitTesting(false).accessibilityHidden(true)
                }
            }
            .overlay(alignment: .bottom) {
                if canScroll && scroll.hasBelow {
                    LinearGradient(colors: [.clear, Color(nsColor: .systemGray)], startPoint: .top, endPoint: .bottom)
                        .frame(height: DesignTokens.scrollShadowHeight).padding(.horizontal, -DesignTokens.inset)
                        .offset(y: 9) // Continue through the drawer's 8 pt padding and 1 pt border.
                        .allowsHitTesting(false).accessibilityHidden(true)
                }
            }
        }
        .frame(height: max(0, viewportHeight))
    }
}
