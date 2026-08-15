import Foundation

public final class LunarAstronomyEngine: AstronomyEngineProtocol {
    public init() {}

    public func currentState(timestamp: Date, location: ObserverLocation) async -> AstronomicalState {
        // Conservative lunar phase estimate using synodic month fraction (already in previous commit)
        let jd = SolarCalculator.julianDay(from: timestamp)
        let synodicMonth = 29.530588853
        var age = fmod(jd - 2451550.1, synodicMonth)
        if age < 0 { age += synodicMonth }
        let fraction = age / synodicMonth

        // altitude/azimuth intentionally UNAVAILABLE until precise implementation is added (SwiftAA-backed)
        return AstronomicalState(timestamp: timestamp,
                                 solarAltitude: nil,
                                 solarAzimuth: nil,
                                 lunarAltitude: nil,
                                 lunarAzimuth: nil,
                                 lunarPhase: fraction)
    }

    public func events(for date: Date, location: ObserverLocation) async -> AstronomicalEvents {
        // Attempt to numerically search for moonrise, lunar transit, moonset by sampling the 24-hour interval.
        // This method will only produce results if moonAltitude(at:location:) is implemented to return real values.
        // To avoid inventing data, if moonAltitude is not implemented (returns nil) we return UNAVAILABLE (nil) for all moon events.

        let cal = Calendar.utcCalendar
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start)!

        // sampling interval in seconds (e.g., 300s = 5 minutes)
        let sampleInterval: TimeInterval = 300.0
        var samples: [(date: Date, altitude: Double?)] = []
        var t = start
        while t <= end {
            let alt = moonAltitude(at: t, location: location)
            samples.append((date: t, altitude: alt))
            t = t.addingTimeInterval(sampleInterval)
        }

        // If we have no altitude data (all nil), return unavailable
        if samples.allSatisfy({ $0.altitude == nil }) {
            return AstronomicalEvents(civilDawn: nil, sunrise: nil, solarTransit: nil, sunset: nil, civilDusk: nil, moonrise: nil, lunarTransit: nil, moonset: nil, moonPhase: nil)
        }

        // Helper to find crossing from negative to positive altitude (rise) and positive to negative (set)
        func findCrossing(isRising: Bool) -> Date? {
            for i in 0..<(samples.count - 1) {
                guard let a1 = samples[i].altitude, let a2 = samples[i+1].altitude else { continue }
                if isRising {
                    if a1 <= 0.0 && a2 > 0.0 {
                        // linear interpolate between samples[i] and samples[i+1]
                        let frac = (0.0 - a1) / (a2 - a1)
                        let seconds = samples[i].date.timeIntervalSince1970 + frac * (samples[i+1].date.timeIntervalSince1970 - samples[i].date.timeIntervalSince1970)
                        return Date(timeIntervalSince1970: seconds)
                    }
                } else {
                    if a1 > 0.0 && a2 <= 0.0 {
                        let frac = (a1 - 0.0) / (a1 - a2)
                        let seconds = samples[i].date.timeIntervalSince1970 + frac * (samples[i+1].date.timeIntervalSince1970 - samples[i].date.timeIntervalSince1970)
                        return Date(timeIntervalSince1970: seconds)
                    }
                }
            }
            return nil
        }

        // Find moonrise and moonset
        let moonrise = findCrossing(isRising: true)
        let moonset = findCrossing(isRising: false)

        // Transit: approximate as time of maximum altitude in samples
        let transitSample = samples.compactMap { (d: Date, alt: Double?) -> (Date, Double)? in
            if let alt = alt { return (d, alt) } else { return nil }
        }.max(by: { $0.1 < $1.1 })
        let transit = transitSample?.0

        return AstronomicalEvents(civilDawn: nil, sunrise: nil, solarTransit: nil, sunset: nil, civilDusk: nil, moonrise: moonrise, lunarTransit: transit, moonset: moonset, moonPhase: nil)
    }

    // Placeholder: returns lunar altitude in degrees above horizon for given timestamp and location.
    // Intended to be replaced by a SwiftAA-backed implementation that computes topocentric altitude.
    // Returning nil indicates UNAVAILABLE and prevents the engine from fabricating rise/set times.
    private func moonAltitude(at timestamp: Date, location: ObserverLocation) -> Double? {
        // TODO: Implement using SwiftAA to compute topocentric altitude
        return nil
    }
}
