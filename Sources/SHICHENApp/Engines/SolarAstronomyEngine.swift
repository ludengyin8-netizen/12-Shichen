import Foundation

public final class SolarAstronomyEngine: AstronomyEngineProtocol {
    public init() {}

    public func currentState(timestamp: Date, location: ObserverLocation) async -> AstronomicalState {
        // compute solar position
        let (alt, az) = SolarCalculator.solarPosition(timestamp: timestamp, location: location)
        return AstronomicalState(timestamp: timestamp, solarAltitude: alt, solarAzimuth: az, lunarAltitude: nil, lunarAzimuth: nil, lunarPhase: nil)
    }

    public func events(for date: Date, location: ObserverLocation) async -> AstronomicalEvents {
        let cal = Calendar.utcCalendar
        let day = cal.startOfDay(for: date)
        let (sunrise, transit, sunset) = SolarCalculator.sunEvents(for: day, location: location, altitude: -0.833)
        let (dawn, dusk) = SolarCalculator.civilDawnDusk(for: day, location: location)
        return AstronomicalEvents(civilDawn: dawn, sunrise: sunrise, solarTransit: transit, sunset: sunset, civilDusk: dusk, moonrise: nil, lunarTransit: nil, moonset: nil, moonPhase: nil)
    }
}
