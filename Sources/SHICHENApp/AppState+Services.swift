import Foundation

extension AppState {
    // New services
    private static let sharedAstronomyService = AstronomyService(engine: DummyAstronomyEngine(), cache: EventCache())
    private static let sharedShichenService = ShichenService(engine: EqualTimeShichenEngine())

    // Expose boundaries for UI
    @Published public var shichenBoundaries: [ShichenBoundary]? = nil

    public func updateAstronomyAndShichen() async {
        // Update instantaneous state
        let loc = self.location
        let now = self.now
        let astro = await AppState.sharedAstronomyService.currentState(timestamp: now, location: loc)
        await MainActor.run {
            self.astronomicalState = astro
        }

        // Update events (use startOfDay for caching)
        let cal = Calendar.utcCalendar
        let startOfDay = cal.startOfDay(for: now)
        let events = await AppState.sharedAstronomyService.events(for: startOfDay, location: loc)
        await MainActor.run {
            self.astronomicalEvents = events
        }

        // Shichen boundaries (reference)
        let boundaries = await AppState.sharedShichenService.boundaries(for: now, location: loc)
        await MainActor.run {
            self.shichenBoundaries = boundaries
        }
    }
}
