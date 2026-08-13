import XCTest
@testable import SHICHENApp

final class LunarTests: XCTestCase {
    func testLunarPhaseFractionRange() async throws {
        let engine = LunarAstronomyEngine()
        let loc = ObserverLocation.defaultJeju()
        let cal = Calendar.utcCalendar
        let date = cal.date(from: DateComponents(year: 2026, month: 8, day: 10, hour: 0))!
        let state = await engine.currentState(timestamp: date, location: loc)
        XCTAssertNotNil(state.lunarPhase)
        if let ph = state.lunarPhase {
            XCTAssertGreaterThanOrEqual(ph, 0.0)
            XCTAssertLessThanOrEqual(ph, 1.0)
        }
    }
}
