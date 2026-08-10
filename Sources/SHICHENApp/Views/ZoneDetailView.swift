import SwiftUI

struct ZoneDetailView: View {
    @EnvironmentObject var appState: AppState

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

            Divider()

            Group {
                Text("SOLAR")
                    .font(.headline)
                Text("Altitude: \(formatted(appState.astronomicalState?.solarAltitude))")
                Text("Azimuth: \(formatted(appState.astronomicalState?.solarAzimuth))")
            }

            Divider()

            Group {
                Text("LUNAR")
                    .font(.headline)
                Text("Altitude: \(formatted(appState.astronomicalState?.lunarAltitude))")
                Text("Azimuth: \(formatted(appState.astronomicalState?.lunarAzimuth))")
                Text("Phase: \(formatted(appState.astronomicalState?.lunarPhase))")
            }

            Divider()

            Group {
                Text("SHICHEN (REFERENCE)")
                    .font(.headline)
                if let shichen = appState.shichenBoundaries, !shichen.isEmpty {
                    ForEach(shichen, id: \.
                        branch) { b in
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
}
