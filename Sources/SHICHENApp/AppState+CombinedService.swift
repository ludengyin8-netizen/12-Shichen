import Foundation

extension AppState {
    // Combined astronomy service uses both solar and lunar engines; cached separately under modelVersion v1-combined
    static let combinedAstronomyService = AstronomyService(engine: CombinedAstronomyEngine(), cache: EventCache(), modelVersion: "v1-combined")

    // Expose boundaries for UI
    @Published public var shichenBoundaries: [ShichenBoundary]? = nil

    public func updateAstronomyAndShichen() async {
        await MainActor.run { self.isCalculating = true; self.lastCalculationError = nil }
        do {
            let loc = self.location
            let now = self.now
            let astro = await AppState.combinedAstronomyService.currentState(timestamp: now, location: loc)
            await MainActor.run { self.astronomicalState = astro }

            let cal = Calendar.utcCalendar
            let startOfDay = cal.startOfDay(for: now)
            let events = await AppState.combinedAstronomyService.events(for: startOfDay, location: loc)
            await MainActor.run { self.astronomicalEvents = events }

            let boundaries = await AppState.sharedShichenService.boundaries(for: now, location: loc)
            await MainActor.run { self.shichenBoundaries = boundaries }

            await MainActor.run { self.isCalculating = false }
        } catch {
            await MainActor.run {
                self.isCalculating = false
                self.lastCalculationError = "Calculation failed: \(error.localizedDescription)"
            }
        }
    }
}
