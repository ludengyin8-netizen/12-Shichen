import Foundation
import SwiftUI

@MainActor
public final class AppState: ObservableObject {
    @Published public private(set) var mode: ClockMode = .live
    @Published public var now: Date = Date() {
        didSet {
            // No heavy calculations here — services will observe and recalc
        }
    }

    @Published public var selectedZone: TheoreticalZone?
    @Published public var location: ObserverLocation = ObserverLocation.defaultJeju()

    @Published public var astronomicalState: AstronomicalState?
    @Published public var astronomicalEvents: AstronomicalEvents?

    @Published public var isCalculating: Bool = false
    @Published public var lastCalculationError: String? = nil

    public var zones: [TheoreticalZone] = ZoneEngine.defaultZones()

    private var timeEngine = TimeEngine()
    private var cancellables: [Any] = []

    public init() {
        // wire timeEngine -> appState.now
        Task { @MainActor in
            self.mode = self.timeEngine.mode
            self.now = self.timeEngine.now
            // Observe via timer-like approach: subscribe to updates
            // For simplicity in this skeleton, use a repeating Task
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.now = self.timeEngine.now
            }
            self.selectedZone = self.zones.first(where: { $0.label == "UTC" })
        }
    }

    public func returnToLive() {
        timeEngine.returnToLive()
        mode = .live
        now = Date()
    }

    public func setLocation(_ newLocation: ObserverLocation) {
        self.location = newLocation
        // Invalidate astronomy cache when location changes
        AppState.combinedAstronomyService.invalidateCache()
        Task { await self.updateAstronomyAndShichen() }
    }
}
