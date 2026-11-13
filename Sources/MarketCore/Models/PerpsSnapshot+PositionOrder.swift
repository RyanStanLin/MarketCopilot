import Foundation

extension PerpsSnapshot {
    /// Updates replace values in place; newly opened positions are appended.
    public func preservingPositionOrder(from previous: [PerpPosition]) -> Self {
        var remaining: [Int: PerpPosition] = [:]
        for position in positions { remaining[position.id] = position }
        var ordered = previous.compactMap { remaining.removeValue(forKey: $0.id) }
        for position in positions {
            if let added = remaining.removeValue(forKey: position.id) { ordered.append(added) }
        }
        var result = self
        result.positions = ordered
        return result
    }
}
