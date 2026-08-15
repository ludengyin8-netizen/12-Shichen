import Foundation

extension AppState {
    // Replace sharedAstronomyService with a combined engine service that will use Solar + Lunar engines.
    private static let solarAstronomyService = AstronomyService(engine: SolarAstronomyEngine(), cache: EventCache(), modelVersion: "v1-solar")
}
