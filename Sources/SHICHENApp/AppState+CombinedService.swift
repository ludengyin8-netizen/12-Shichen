import Foundation

extension AppState {
    // Replace sharedAstronomyService with a combined engine service that will use Solar + Lunar engines.
    private static let combinedAstronomyService = AstronomyService(engine: CombinedAstronomyEngine(), cache: EventCache())

    public func updateAstronomyAndShichen() async {
        let loc = self.location
        let now = self.now
        let astro = await AppState.combinedAstronomyService.currentState(timestamp: now, location: loc)
        await MainActor.run {
            self.astronomicalState = astro
        }

        let cal = Calendar.utcCalendar
        let startOfDay = cal.startOfDay(for: now)
        let events = await AppState.combinedAstronomyService.events(for: startOfDay, location: loc)
        await MainActor.run {
            self.astronomicalEvents = events
        }

        let boundaries = await AppState.sharedShichenService.boundaries(for: now, location: loc)
        await MainActor.run {
            self.shichenBoundaries = boundaries
        }
    }
}
