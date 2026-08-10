import SwiftUI

struct DiagnosticsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DIAGNOSTICS")
                .font(.title2)
            Text("Clock Mode: \(appState.mode.rawValue)")
            Text("Now: \(DiagnosticsView.dateString(appState.now))")
            Text("Selected Zone: \(appState.selectedZone?.label ?? "-")")
            Text("Location: lat=\(appState.location.latitude), lon=\(appState.location.longitude), elev=\(appState.location.elevation)")
            Text("Astronomy state: \(appState.astronomicalState == nil ? "nil" : "available")")
            Text("Events: \(appState.astronomicalEvents == nil ? "nil" : "available")")
            Text("Shichen model: Reference Equal-Time")
            Spacer()
        }
        .padding()
    }

    static func dateString(_ d: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.string(from: d)
    }
}
