import SwiftUI

enum MenuHoverKind {
    case summary, position, action, profile, icon

    var radii: RectangleCornerRadii {
        switch self {
        case .summary: .init(topLeading: 999, bottomLeading: 999, bottomTrailing: 12, topTrailing: 12)
        case .position: .init(topLeading: 12, bottomLeading: 12, bottomTrailing: 12, topTrailing: 12)
        case .action: .init(topLeading: 8, bottomLeading: 8, bottomTrailing: 8, topTrailing: 8)
        case .profile, .icon: .init(topLeading: 999, bottomLeading: 999, bottomTrailing: 999, topTrailing: 999)
        }
    }

    var insets: EdgeInsets {
        switch self {
        case .summary: .init(top: -5, leading: -6, bottom: -6, trailing: -6)
        case .position, .action: .init(top: 0, leading: -6, bottom: 0, trailing: -6)
        case .profile: .init(top: -4, leading: -4, bottom: -4, trailing: -4)
        case .icon: .init(top: -3, leading: -3, bottom: -3, trailing: -3)
        }
    }
}
