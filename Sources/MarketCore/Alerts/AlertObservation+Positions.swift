import Foundation

extension AlertObservation {
    public static func prediction(target: AlertTarget, snapshot: PredictionSnapshot) -> Self {
        guard let position = snapshot.positions.first(where: { $0.tokenID == target.marketID && $0.isActive }) else {
            return Self(targetID: target.id, readings: [.activePosition: AlertReading(0, at: snapshot.timestamp)])
        }
        var values: [AlertMetric: AlertReading] = [.activePosition: AlertReading(1, at: snapshot.timestamp)]
        if let price = position.currentPrice { values[.price] = AlertReading(price, at: snapshot.timestamp) }
        if let profit = position.unrealizedPnl { values[.profit] = AlertReading(profit, at: snapshot.timestamp) }
        if let rate = position.returnOnEquity { values[.returnPercent] = AlertReading(rate * 100, at: snapshot.timestamp) }
        return Self(targetID: target.id, readings: values)
    }

    public static func perps(target: AlertTarget, snapshot: PerpsSnapshot, quotes: [Int: MarketQuote]) -> Self {
        guard let id = Int(target.marketID), let position = snapshot.positions.first(where: { $0.id == id && $0.size != 0 }) else {
            return Self(targetID: target.id, readings: [.activePosition: AlertReading(0, at: snapshot.timestamp)])
        }
        var values: [AlertMetric: AlertReading] = [
            .activePosition: AlertReading(1, at: snapshot.timestamp),
            .profit: AlertReading(position.unrealizedPnl, at: snapshot.timestamp),
            .returnPercent: AlertReading(position.returnOnEquity * 100, at: snapshot.timestamp),
            .funding: AlertReading(position.cumulativeFunding, at: snapshot.timestamp)
        ]
        if let quote = quotes[id], let mark = quote.mark, mark > 0 {
            values[.price] = AlertReading(mark, at: quote.timestamp, dependingOn: snapshot.timestamp)
            if let liquidation = position.liquidationPrice, liquidation > 0 {
                let distance = position.isLong ? mark - liquidation : liquidation - mark
                values[.liquidationBuffer] = AlertReading(max(0, distance / mark * 100),
                    at: max(quote.timestamp, snapshot.timestamp), dependingOn: min(quote.timestamp, snapshot.timestamp))
            }
        }
        return Self(targetID: target.id, readings: values)
    }
}
