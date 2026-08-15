import Foundation

public final class AstronomyService {
    private let engine: AstronomyEngineProtocol
    private let cache: EventCache
    private let modelVersion: String

    public init(engine: AstronomyEngineProtocol, cache: EventCache, modelVersion: String) {
        self.engine = engine
        self.cache = cache
        self.modelVersion = modelVersion
    }

    public func currentState(timestamp: Date, location: ObserverLocation) async -> AstronomicalState {
        return await engine.currentState(timestamp: timestamp, location: location)
    }

    public func events(for date: Date, location: ObserverLocation) async -> AstronomicalEvents {
        let key = EventCacheKey(date: date, latitude: location.latitude, longitude: location.longitude, elevation: location.elevation, modelVersion: modelVersion)
        if let cached = cache.get(key: key) {
            return cached
        }
        let events = await engine.events(for: date, location: location)
        cache.set(key: key, events: events)
        return events
    }

    public func invalidateCache() {
        cache.invalidateAll()
    }
}
