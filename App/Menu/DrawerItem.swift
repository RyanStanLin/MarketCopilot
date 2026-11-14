import MarketCore

enum DrawerItem: Identifiable {
    case prediction(PredictionPosition)
    case perps(PerpPosition)
    var id: String {
        switch self {
        case .prediction(let value): "prediction-" + value.id
        case .perps(let value): "perps-\(value.id)"
        }
    }
}
