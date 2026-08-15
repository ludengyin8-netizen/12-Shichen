public func currentState(timestamp: Date, location: ObserverLocation) async -> AstronomicalState {
    #if canImport(SwiftAA)
    do {
        let jd = JulianDay(date: timestamp)
        let earthLocation = GeographicCoordinates(positivelyOrientedLongitude: Angle(degrees: location.longitude), latitude: Angle(degrees: location.latitude), elevation: Length(meters: location.elevation))
        let moon = Moon(julianDay: jd)
        let topocentric = try moon.topocentricHorizontalCoordinates(for: earthLocation, julianDay: jd)
        let altitude = topocentric.horizontalAltitude.degrees
        let azimuth = topocentric.horizontalAzimuth.degrees
        let illum = try moon.illuminatedFraction(julianDay: jd)
        return AstronomicalState(timestamp: timestamp, solarAltitude: nil, solarAzimuth: nil, lunarAltitude: altitude, lunarAzimuth: azimuth, lunarPhase: illum)
    } catch {
        return AstronomicalState(timestamp: timestamp, solarAltitude: nil, solarAzimuth: nil, lunarAltitude: nil, lunarAzimuth: nil, lunarPhase: nil)
    }
    #else
    let jd = SolarCalculator.julianDay(from: timestamp)
    let synodicMonth = 29.530588853
    var age = fmod(jd - 2451550.1, synodicMonth)
    if age < 0 { age += synodicMonth }
    let fraction = age / synodicMonth
    return AstronomicalState(timestamp: timestamp, solarAltitude: nil, solarAzimuth: nil, lunarAltitude: nil, lunarAzimuth: nil, lunarPhase: fraction)
    #endif
}

public func events(for date: Date, location: ObserverLocation) async -> AstronomicalEvents {
    let cal = Calendar.utcCalendar
    let start = cal.startOfDay(for: date)
    let end = cal.date(byAdding: .day, value: 1, to: start)!

    #if canImport(SwiftAA)
    // Coarse sampling
    let coarseInterval: TimeInterval = 600.0
    var samples: [(Date, Double)] = []
    var t = start
    while t <= end {
        if let alt = moonAltitude(at: t, location: location) {
            samples.append((t, alt))
        }
        t = t.addingTimeInterval(coarseInterval)
    }

    if samples.isEmpty {
        return AstronomicalEvents(civilDawn: nil, sunrise: nil, solarTransit: nil, sunset: nil, civilDusk: nil, moonrise: nil, lunarTransit: nil, moonset: nil, moonPhase: nil)
    }

    // Find crossings
    func refineCrossing(startSample: (Date, Double), endSample: (Date, Double)) -> Date? {
        var loT = startSample.0
        var hiT = endSample.0
        var loAlt = startSample.1
        var hiAlt = endSample.1
        for _ in 0..<30 {
            let midT = Date(timeIntervalSince1970: (loT.timeIntervalSince1970 + hiT.timeIntervalSince1970) / 2.0)
            guard let midAlt = moonAltitude(at: midT, location: location) else { return nil }
            if (loAlt <= 0 && midAlt > 0) || (loAlt > 0 && midAlt <= 0) {
                hiT = midT; hiAlt = midAlt
            } else {
                loT = midT; loAlt = midAlt
            }
            if hiT.timeIntervalSince1970 - loT.timeIntervalSince1970 < 0.5 { break }
        }
        return Date(timeIntervalSince1970: (loT.timeIntervalSince1970 + hiT.timeIntervalSince1970) / 2.0)
    }

    var rise: Date? = nil
    var set: Date? = nil
    for i in 0..<(samples.count - 1) {
        let a1 = samples[i].1
        let a2 = samples[i+1].1
        if a1 <= 0 && a2 > 0 && rise == nil {
            rise = refineCrossing(startSample: samples[i], endSample: samples[i+1])
        }
        if a1 > 0 && a2 <= 0 && set == nil {
            set = refineCrossing(startSample: samples[i], endSample: samples[i+1])
        }
    }

    // Transit: refine local maximum using quadratic fit around the best sample
    if let maxIndex = samples.enumerated().max(by: { $0.element.1 < $1.element.1 })?.offset {
        let i0 = max(0, maxIndex - 1)
        let i1 = maxIndex
        let i2 = min(samples.count - 1, maxIndex + 1)
        let t0 = samples[i0].0.timeIntervalSince1970
        let y0 = samples[i0].1
        let t1 = samples[i1].0.timeIntervalSince1970
        let y1 = samples[i1].1
        let t2 = samples[i2].0.timeIntervalSince1970
        let y2 = samples[i2].1
        let denom = (t0 - t1) * (t0 - t2) * (t1 - t2)
        if denom != 0 {
            let A = (t2*(y1 - y0) + t1*(y0 - y2) + t0*(y2 - y1)) / denom
            let B = (t2*t2*(y0 - y1) + t1*t1*(y2 - y0) + t0*t0*(y1 - y2)) / denom
            if A != 0 {
                let vertexT = -B / (2*A)
                let transit = Date(timeIntervalSince1970: vertexT)
                let phaseState = await currentState(timestamp: start, location: location)
                return AstronomicalEvents(civilDawn: nil, sunrise: nil, solarTransit: nil, sunset: nil, civilDusk: nil, moonrise: rise, lunarTransit: transit, moonset: set, moonPhase: phaseState.lunarPhase)
            }
        }
        let transitFallback = samples[maxIndex].0
        let phaseState = await currentState(timestamp: start, location: location)
        return AstronomicalEvents(civilDawn: nil, sunrise: nil, solarTransit: nil, sunset: nil, civilDusk: nil, moonrise: rise, lunarTransit: transitFallback, moonset: set, moonPhase: phaseState.lunarPhase)
    }

    let phaseState = await currentState(timestamp: start, location: location)
    return AstronomicalEvents(civilDawn: nil, sunrise: nil, solarTransit: nil, sunset: nil, civilDusk: nil, moonrise: rise, lunarTransit: nil, moonset: set, moonPhase: phaseState.lunarPhase)
    #else
    return AstronomicalEvents(civilDawn: nil, sunrise: nil, solarTransit: nil, sunset: nil, civilDusk: nil, moonrise: nil, lunarTransit: nil, moonset: nil, moonPhase: nil)
    #endif
}

private func moonAltitude(at timestamp: Date, location: ObserverLocation) -> Double? {
    #if canImport(SwiftAA)
    do {
        let jd = JulianDay(date: timestamp)
        let moon = Moon(julianDay: jd)
        let geo = GeographicCoordinates(positivelyOrientedLongitude: Angle(degrees: location.longitude), latitude: Angle(degrees: location.latitude), elevation: Length(meters: location.elevation))
        let topocentric = try moon.topocentricHorizontalCoordinates(for: geo, julianDay: jd)
        return topocentric.horizontalAltitude.degrees
    } catch {
        return nil
    }
    #else
    return nil
    #endif
}
