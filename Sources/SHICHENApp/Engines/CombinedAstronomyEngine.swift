import Foundation
import SwiftAA

public final class CombinedAstronomyEngine: AstronomyEngineProtocol {
    private let solar = SolarAstronomyEngine()
    private let lunar = LunarAstronomyEngine()

    public init() {}

    public func currentState(timestamp: Date, location: ObserverLocation) async -> AstronomicalState {
        async let s = solar.currentState(timestamp: timestamp, location: location)
        async let l = lunar.currentState(timestamp: timestamp, location: location)
        let (ss, ls) = await (s, l)
        return AstronomicalState(timestamp: timestamp,
                                 solarAltitude: ss.solarAltitude,
                                 solarAzimuth: ss.solarAzimuth,
                                 lunarAltitude: ls.lunarAltitude,
                                 lunarAzimuth: ls.lunarAzimuth,
                                 lunarPhase: ls.lunarPhase)
    }

    public func events(for date: Date, location: ObserverLocation) async -> AstronomicalEvents {
        async let se = solar.events(for: date, location: location)
        async let le = lunar.events(for: date, location: location)
        let (sEvents, lEvents) = await (se, le)
        return AstronomicalEvents(civilDawn: sEvents.civilDawn,
                                  sunrise: sEvents.sunrise,
                                  solarTransit: sEvents.solarTransit,
                                  sunset: sEvents.sunset,
                                  civilDusk: sEvents.civilDusk,
                                  moonrise: lEvents.moonrise,
                                  lunarTransit: lEvents.lunarTransit,
                                  moonset: lEvents.moonset,
                                  moonPhase: lEvents.moonPhase ?? lEvents.moonPhase)
    }
}
