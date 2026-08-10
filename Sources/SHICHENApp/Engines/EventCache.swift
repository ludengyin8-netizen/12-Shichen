import Foundation

public struct EventCacheKey: Hashable {
    public let calendarDateISO: String
    public let latitude: Double
    public let longitude: Double
    public let elevation: Double
    public let modelVersion: String

    public init(date: Date, latitude: Double, longitude: Double, elevation: Double, modelVersion: String) {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        self.calendarDateISO = f.string(from: date)
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.modelVersion = modelVersion
    }
}

public final class EventCache {
    private var storage: [EventCacheKey: AstronomicalEvents] = [:]
    private let queue = DispatchQueue(label: "EventCache.queue")

    public init() {}

    public func get(key: EventCacheKey) -> AstronomicalEvents? {
        return queue.sync { storage[key] }
    }

    public func set(key: EventCacheKey, events: AstronomicalEvents) {
        queue.sync { storage[key] = events }
    }

    public func invalidateAll() {
        queue.sync { storage.removeAll() }
    }
}
