var zone: TheoreticalZone

var body: some View {
    VStack(alignment: .leading, spacing: 10) {
        Text(zone.label)
            .font(.title)
        HStack {
            Text("Local:")
            Text(ZoneDetailView.timeString(for: zone.localDate(from: appState.now)))
                .monospaced()
        }

        if appState.isCalculating {
            Text("Calculating astronomical data...")
                .foregroundColor(.gray)
        }

        if let err = appState.lastCalculationError {
            Text("Error: \(err)")
                .foregroundColor(.red)
        }

        Divider()

        Group {
            Text("SOLAR")
                .font(.headline)
            Text("Altitude: \(ZoneDetailView.formatted(appState.astronomicalState?.solarAltitude))")
            Text("Azimuth: \(ZoneDetailView.formatted(appState.astronomicalState?.solarAzimuth))")

            if let events = appState.astronomicalEvents {
                Text("Sunrise: \(ZoneDetailView.timeOrUnavailable(events.sunrise))")
                Text("Transit: \(ZoneDetailView.timeOrUnavailable(events.solarTransit))")
                Text("Sunset: \(ZoneDetailView.timeOrUnavailable(events.sunset))")
            }
        }

        Divider()

        Group {
            Text("LUNAR")
                .font(.headline)
            Text("Altitude: \(ZoneDetailView.formatted(appState.astronomicalState?.lunarAltitude))")
            Text("Azimuth: \(ZoneDetailView.formatted(appState.astronomicalState?.lunarAzimuth))")
            Text("Phase: \(ZoneDetailView.formatted(appState.astronomicalState?.lunarPhase))")

            if let events = appState.astronomicalEvents {
                Text("Moonrise: \(ZoneDetailView.timeOrUnavailable(events.moonrise))")
                Text("Lunar Transit: \(ZoneDetailView.timeOrUnavailable(events.lunarTransit))")
                Text("Moonset: \(ZoneDetailView.timeOrUnavailable(events.moonset))")
            }
        }

        Divider()

        Group {
            Text("SHICHEN (REFERENCE)")
                .font(.headline)
            if let shichen = appState.shichenBoundaries, !shichen.isEmpty {
                ForEach(shichen, id: \.branch) { b in
                    HStack {
                        Text(b.branch.rawValue)
                        Spacer()
                        if let s = b.start, let e = b.end {
                            Text("\(ZoneDetailView.timeString(for: s)) — \(ZoneDetailView.timeString(for: e))")
                                .monospaced()
                        } else {
                            Text("UNAVAILABLE")
                        }
                    }
                }
            } else {
                Text("No Shichen data available")
            }
        }

        Spacer()
    }
    .padding()
    .onAppear {
        Task {
            await appState.updateAstronomyAndShichen()
        }
    }
}

static func timeString(for date: Date) -> String {
    let f = DateFormatter()
    f.timeZone = TimeZone(secondsFromGMT: 0)
    f.dateFormat = "HH:mm:ss"
    return f.string(from: date)
}

static func formatted(_ v: Double?) -> String {
    if let v = v { return String(format: "%.3f", v) }
    return "UNAVAILABLE"
}

static func timeOrUnavailable(_ d: Date?) -> String {
    if let d = d { return timeString(for: d) }
    return "UNAVAILABLE"
}
