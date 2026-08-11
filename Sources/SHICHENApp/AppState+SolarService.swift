import Foundation

// Update AstronomyService to use SolarAstronomyEngine by default for modelVersion v1-solar
extension AppState {
    private static let solarAstronomyService = AstronomyService(engine: SolarAstronomyEngine(), cache: EventCache())

    // During Phase 8, replace sharedAstronomyService with solarAstronomyService
    // We'll use AppState.solarAstronomyService when updating astronomy
    // Keep previous sharedAstronomyService for fallback if needed
}
