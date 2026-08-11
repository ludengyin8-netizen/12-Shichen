import Foundation

internal extension Double {
    var degreesToRadians: Double { return self * .pi / 180.0 }
    var radiansToDegrees: Double { return self * 180.0 / .pi }
}

public struct SolarCalculator {
    // Based on NOAA / Meeus simplified solar calculations suitable for sunrise/sunset and transit approximations.

    // Convert Date (UTC) to Julian Day
    public static func julianDay(from date: Date) -> Double {
        let cal = Calendar(identifier: .gregorian)
        var comp = cal.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: date)
        let year = comp.year!
        var month = comp.month!
        let day = Double(comp.day!) + (Double(comp.hour ?? 0) - 12.0)/24.0 + Double(comp.minute ?? 0)/1440.0 + Double(comp.second ?? 0)/86400.0

        var y = year
        if month <= 2 {
            y -= 1
            month += 12
        }
        let A = floor(Double(y)/100.0)
        let B = 2 - A + floor(A/4.0)
        let jd = floor(365.25 * Double(y + 4716)) + floor(30.6001 * Double(month + 1)) + day + B - 1524.5
        return jd
    }

    static func julianCenturies(from jd: Double) -> Double {
        return (jd - 2451545.0) / 36525.0
    }

    // Geometric mean longitude of the sun (deg)
    static func geomMeanLongSun(T: Double) -> Double {
        var L = 280.46646 + T * (36000.76983 + T * 0.0003032)
        L = fmod(L, 360.0)
        if L < 0 { L += 360.0 }
        return L
    }

    static func geomMeanAnomalySun(T: Double) -> Double {
        return 357.52911 + T * (35999.05029 - 0.0001537 * T)
    }

    static func eccentricityEarthOrbit(T: Double) -> Double {
        return 0.016708634 - T * (0.000042037 + 0.0000001267 * T)
    }

    static func sunEqOfCenter(T: Double, M: Double) -> Double {
        let Mrad = M.degreesToRadians
        let sinM = sin(Mrad)
        let sin2M = sin(2 * Mrad)
        let sin3M = sin(3 * Mrad)
        return sinM * (1.914602 - T * (0.004817 + 0.000014 * T)) + sin2M * (0.019993 - 0.000101 * T) + sin3M * 0.000289
    }

    static func sunTrueLong(T: Double, L0: Double, C: Double) -> Double {
        return L0 + C
    }

    static func sunApparentLong(T: Double, trueLong: Double) -> Double {
        let omega = 125.04 - 1934.136 * T
        return trueLong - 0.00569 - 0.00478 * sin(omega.degreesToRadians)
    }

    static func meanObliquityOfEcliptic(T: Double) -> Double {
        let seconds = 21.448 - T * (46.8150 + T * (0.00059 - T * 0.001813))
        return 23.0 + (26.0 + (seconds/60.0))/60.0
    }

    static func obliquityCorrection(T: Double, e0: Double) -> Double {
        let omega = 125.04 - 1934.136 * T
        return e0 + 0.00256 * cos(omega.degreesToRadians)
    }

    static func sunDeclination(epsilon: Double, lambda: Double) -> Double {
        let eps = epsilon.degreesToRadians
        let lam = lambda.degreesToRadians
        return asin(sin(eps) * sin(lam)).radiansToDegrees
    }

    static func equationOfTime(T: Double) -> Double {
        let L0 = geomMeanLongSun(T: T)
        let e = eccentricityEarthOrbit(T: T)
        let M = geomMeanAnomalySun(T: T)
        let C = sunEqOfCenter(T: T, M: M)
        let trueLong = sunTrueLong(T: T, L0: L0, C: C)
        let omega = 125.04 - 1934.136 * T
        let e0 = meanObliquityOfEcliptic(T: T)
        let eps = obliquityCorrection(T: T, e0: e0)
        let y = pow(tan((eps/2.0).degreesToRadians), 2.0)

        let L0rad = L0.degreesToRadians
        let Mrad = M.degreesToRadians

        let Etime = y * sin(2.0 * L0rad) - 2.0 * e * sin(Mrad) + 4.0 * e * y * sin(Mrad) * cos(2.0 * L0rad) - 0.5 * y * y * sin(4.0 * L0rad) - 1.25 * e * e * sin(2.0 * Mrad)
        return (Etime.radiansToDegrees * 4.0) // in minutes of time
    }

    // Convert Julian Day to Date (UTC)
    static func date(fromJulianDay jd: Double) -> Date {
        var J = jd + 0.5
        let Z = Int(floor(J))
        let F = J - Double(Z)
        var A = Z
        if Z >= 2299161 {
            let alpha = Int(floor(Double(Z - 1867216.25)/36524.25))
            A = Z + 1 + alpha - Int(floor(Double(alpha)/4.0))
        }
        let B = A + 1524
        let C = Int(floor((Double(B) - 122.1)/365.25))
        let D = Int(floor(365.25 * Double(C)))
        let E = Int(floor((Double(B - D))/30.6001))
        let day = Double(B - D) - floor(30.6001 * Double(E)) + F
        var month = E < 14 ? E - 1 : E - 13
        var year = month > 2 ? C - 4716 : C - 4715

        let dayInt = Int(floor(day))
        let dayFrac = day - Double(dayInt)
        let secondsInDay = dayFrac * 86400.0
        let hour = Int(secondsInDay / 3600.0)
        let minute = Int((secondsInDay - Double(hour * 3600)) / 60.0)
        let second = Int(secondsInDay) % 60

        var comps = DateComponents()
        comps.timeZone = TimeZone(secondsFromGMT: 0)
        comps.year = year
        comps.month = month
        comps.day = dayInt
        comps.hour = hour
        comps.minute = minute
        comps.second = second

        let cal = Calendar(identifier: .gregorian)
        return cal.date(from: comps) ?? Date()
    }

    // Core NOAA-based sunrise/sunset/transit approximation
    // altitude parameter: degrees (e.g., -0.833 for sunrise/sunset including refraction, -6 for civil dawn)
    public static func sunEvents(for date: Date, location: ObserverLocation, altitude: Double = -0.833) -> (sunrise: Date?, transit: Date?, sunset: Date?) {
        // Use UTC date's day
        let cal = Calendar.utcCalendar
        let jd = julianDay(from: date)
        let lw = -location.longitude // NOAA uses negative for west? we will use longitude in degrees east, follow formulas accordingly
        // Following NOAA algorithm: longitude positive east -> use lon in degrees
        // Compute approximate solar transit
        let n = round(jd - 2451545.0009 - (location.longitude / 360.0))
        let Jstar = 2451545.0009 + (location.longitude / 360.0) + n
        let T = julianCenturies(from: Jstar)
        let M = geomMeanAnomalySun(T: T)
        let C = sunEqOfCenter(T: T, M: M)
        let L = sunTrueLong(T: T, L0: geomMeanLongSun(T: T), C: C)
        let lambda = sunApparentLong(T: T, trueLong: L)
        let Jtransit = Jstar + 0.0053 * sin(M.degreesToRadians) - 0.0069 * sin(2.0 * lambda.degreesToRadians)
        // declination at transit
        let e0 = meanObliquityOfEcliptic(T: T)
        let eps = obliquityCorrection(T: T, e0: e0)
        let delta = sunDeclination(epsilon: eps, lambda: lambda)

        // Hour angle
        let phi = location.latitude
        let h0 = altitude
        let cosH = (sin(h0.degreesToRadians) - sin(phi.degreesToRadians) * sin(delta.degreesToRadians)) / (cos(phi.degreesToRadians) * cos(delta.degreesToRadians))
        if cosH < -1 || cosH > 1 {
            // Sun does not rise/set on this date at this location
            return (nil, date(fromJulianDay: Jtransit), nil)
        }
        let H = acos(cosH).radiansToDegrees
        let Jrise = Jtransit - H / 360.0
        let Jset = Jtransit + H / 360.0

        let rise = date(fromJulianDay: Jrise)
        let set = date(fromJulianDay: Jset)
        let transit = date(fromJulianDay: Jtransit)
        return (rise, transit, set)
    }

    public static func civilDawnDusk(for date: Date, location: ObserverLocation) -> (dawn: Date?, dusk: Date?) {
        let res = sunEvents(for: date, location: location, altitude: -6.0)
        return (res.sunrise, res.sunset)
    }

    // Compute solar altitude and azimuth for given timestamp and location
    // Returns (altitudeDegrees, azimuthDegrees) where azimuth is degrees from north (0=north, 90=east)
    public static func solarPosition(timestamp: Date, location: ObserverLocation) -> (altitude: Double, azimuth: Double) {
        let jd = julianDay(from: timestamp)
        let T = julianCenturies(from: jd)
        let L0 = geomMeanLongSun(T: T)
        let M = geomMeanAnomalySun(T: T)
        let C = sunEqOfCenter(T: T, M: M)
        let trueLong = sunTrueLong(T: T, L0: L0, C: C)
        let lambda = sunApparentLong(T: T, trueLong: trueLong)
        let e0 = meanObliquityOfEcliptic(T: T)
        let eps = obliquityCorrection(T: T, e0: e0)
        let delta = sunDeclination(epsilon: eps, lambda: lambda)

        // Equation of time (minutes)
        let EoT = equationOfTime(T: T)

        // Local solar time in minutes
        let timezoneOffsetMinutes = 0.0 // UTC
        let lon = location.longitude
        let timeUTCComponents = Calendar.utcCalendar.dateComponents([.hour, .minute, .second], from: timestamp)
        let minutes = Double((timeUTCComponents.hour ?? 0) * 60 + (timeUTCComponents.minute ?? 0)) + Double(timeUTCComponents.second ?? 0) / 60.0
        let lstMinutes = minutes + (lon * 4.0) - EoT // approximate local solar time in minutes
        let H = (lstMinutes / 4.0) - 180.0 // hour angle in degrees

        let phi = location.latitude.degreesToRadians
        let deltaRad = delta.degreesToRadians
        let Hrad = H.degreesToRadians

        let altitude = asin(sin(phi) * sin(deltaRad) + cos(phi) * cos(deltaRad) * cos(Hrad)).radiansToDegrees
        let azimuth = atan2(sin(Hrad), cos(Hrad) * sin(phi) - tan(deltaRad) * cos(phi)).radiansToDegrees
        // convert azimuth to degrees from north
        var az = azimuth + 180.0
        if az < 0 { az += 360.0 }
        if az >= 360 { az -= 360.0 }
        return (altitude, az)
    }
}
