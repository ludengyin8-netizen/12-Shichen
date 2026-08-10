import Foundation

public final class ShichenService {
    private let engine: ShichenEngineProtocol

    public init(engine: ShichenEngineProtocol) {
        self.engine = engine
    }

    public func boundaries(for reference: Date, location: ObserverLocation) async -> [ShichenBoundary] {
        return await engine.boundaries(for: reference, location: location)
    }
}
