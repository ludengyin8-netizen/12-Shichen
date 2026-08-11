import XCTest
@testable import SHICHENApp

final class SolarTests: XCTestCase {
    func testSunriseTransitSunsetOrder() async throws {
        let loc = ObserverLocation.defaultJeju()
        let cal = Calendar.utcCalendar
        let date = cal.date(from: DateComponents(year: 2026, month: 8, day: 10))!
        let engine = SolarAstronomyEngine()
        let events = await engine.events(for: date, location: loc)
        XCTAssertNotNil(events.sunrise, "sunrise should exist for Jeju on this date")
        XCTAssertNotNil(events.solarTransit, "transit should exist")
        XCTAssertNotNil(events.sunset, "sunset should exist")
        if let r = events.sunrise, let t = events.solarTransit, let s = events.sunset {
            XCTAssertTrue(r < t && t < s, "sunrise < transit < sunset")
        }
    }
}
