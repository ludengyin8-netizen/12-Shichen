import Foundation

public protocol ShichenEngineProtocol {
    /// Compute shichen boundaries for the 24-hour period that contains `reference`.
    /// Implementations must return 12 boundaries (reference model may return equal intervals).
    func boundaries(for reference: Date, location: ObserverLocation) async -> [ShichenBoundary]
}

/// Reference equal-time shichen engine: divides UTC day into 12 equal intervals (2 hours each).
/// This is explicitly a REFERENCE model and must not be presented as historical.
public final class EqualTimeShichenEngine: ShichenEngineProtocol {
    public init() {}

    public func boundaries(for reference: Date, location: ObserverLocation) async -> [ShichenBoundary] {
        // Use the UTC calendar day containing reference
        let cal = Calendar.utcCalendar
        let startOfDay = cal.startOfDay(for: reference)

        var boundaries: [ShichenBoundary] = []
        for i in 0..<12 {
            let start = cal.date(byAdding: .hour, value: i * 2, to: startOfDay)
            let end = cal.date(byAdding: .hour, value: (i + 1) * 2, to: startOfDay)
            let branch = ShichenBranch.allCases[i]
            let b = ShichenBoundary(branch: branch, start: start, end: end, basis: [.fallbackModel])
            boundaries.append(b)
        }
        return boundaries
    }
}
