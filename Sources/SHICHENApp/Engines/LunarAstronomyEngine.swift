import Foundation
import SwiftAA

public final class LunarAstronomyEngine: AstronomyEngineProtocol {
    public init() {}

    public func currentState(timestamp: Date, location: ObserverLocation) async -> AstronomicalState {
        // TODO: Replace the simplistic phase estimate below with SwiftAA-based precise lunar position and altitude/azimuth.
        // For now, provide a conservative lunarPhase estimate (fraction of synodic month) and leave alt/az as UNAVAILABLE to avoid inventing badly-tested values.
        let jd = SolarCalculator.julianDay(from: timestamp)
        // Simple synodic month age approximation
        let synodicMonth = 29.530588853
        var age = fmod(jd - 2451550.1, synodicMonth)
        if age < 0 { age += synodicMonth }
        let fraction = age / synodicMonth

        return AstronomicalState(timestamp: timestamp, solarAltitude: nil, solarAzimuth: nil, lunarAltitude: nil, lunarAzimuth: nil, lunarPhase: fraction)
    }

    public func events(for date: Date, location: ObserverLocation) async -> AstronomicalEvents {
        // TODO: Implement precise moonrise/moonset/lunar transit calculations using SwiftAA's moon position routines.
        // Until then return nils to explicitly mark UNAVAILABLE for moon events.
        return AstronomicalEvents(civilDawn: nil, sunrise: nil, solarTransit: nil, sunset: nil, civilDusk: nil, moonrise: nil, lunarTransit: nil, moonset: nil, moonPhase: nil)
    }
}
