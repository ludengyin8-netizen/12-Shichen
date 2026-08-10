import Foundation

public protocol AstronomyEngineProtocol {
    // Return instantaneous astronomical state (positions, phase) for timestamp and location
    func currentState(timestamp: Date, location: ObserverLocation) async -> AstronomicalState

    // Return astronomical events for a given calendar date (UTC day) and location
    func events(for date: Date, location: ObserverLocation) async -> AstronomicalEvents
}

/// A minimal placeholder astronomy engine. It intentionally does not attempt to produce
/// high-precision results in this commit. It returns nil for event times and positions
/// to avoid inventing astronomical data. This preserves the project's "no fake fallback" rule.
public final class DummyAstronomyEngine: AstronomyEngineProtocol {
    public init() {}

    public func currentState(timestamp: Date, location: ObserverLocation) async -> AstronomicalState {
        // Placeholder: return state with nil positions to indicate UNAVAILABLE
        return AstronomicalState(timestamp: timestamp,
                                 solarAltitude: nil,
                                 solarAzimuth: nil,
                                 lunarAltitude: nil,
                                 lunarAzimuth: nil,
                                 lunarPhase: nil)
    }

    public func events(for date: Date, location: ObserverLocation) async -> AstronomicalEvents {
        // Placeholder: return all nils to indicate events are UNAVAILABLE / NOT_IMPLEMENTED
        return AstronomicalEvents()
    }
}
