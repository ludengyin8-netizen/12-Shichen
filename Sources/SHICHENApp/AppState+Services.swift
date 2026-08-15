import Foundation

extension AppState {
    // Keep legacy sharedAstronomyService for non-solar use in development
    private static let sharedAstronomyService = AstronomyService(engine: DummyAstronomyEngine(), cache: EventCache(), modelVersion: "v0-dummy")
}
