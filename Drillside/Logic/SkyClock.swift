import Foundation

/// Approximates the local sun cycle from the clock and the date (no location needed).
/// Day length follows the season for a mid-latitude location; southern-hemisphere time zones are flipped.
enum SkyClock {
    struct State: Equatable {
        /// 0 = full day, 1 = full night.
        var night: Double
        /// 0…1 warm sunrise / sunset tint.
        var golden: Double
        /// Position of the sun across today's daylight (0 at sunrise, 1 at sunset); outside daylight it's clamped.
        var sunProgress: Double
        /// Position of the moon across the night (0 at dusk, 1 at dawn).
        var moonProgress: Double
        var sunrise: Double
        var sunset: Double
    }

    enum Mode: String, CaseIterable {
        case auto, day, night

        var next: Mode {
            switch self {
            case .auto: return .day
            case .day: return .night
            case .night: return .auto
            }
        }

        var label: String {
            switch self {
            case .auto: return "Sky follows your clock"
            case .day: return "Always day"
            case .night: return "Always night"
            }
        }

        var icon: String {
            switch self {
            case .auto: return "clock"
            case .day: return "sun.max"
            case .night: return "moon.stars"
            }
        }
    }

    private static let southernPrefixes = ["Australia/", "Pacific/Auckland", "Pacific/Chatham", "America/Argentina", "America/Santiago",
                                           "America/Sao_Paulo", "America/Montevideo", "America/Asuncion", "Africa/Johannesburg",
                                           "Africa/Maputo", "Africa/Windhoek", "Indian/Mauritius", "Antarctica/"]

    static func isSouthern(_ timeZone: TimeZone) -> Bool {
        southernPrefixes.contains { timeZone.identifier.hasPrefix($0) }
    }

    static func sunTimes(for date: Date, calendar: Calendar = .current, timeZone: TimeZone = .current) -> (sunrise: Double, sunset: Double) {
        let doy = Double(calendar.ordinality(of: .day, in: .year, for: date) ?? 172)
        let southern = southernPrefixes.contains { timeZone.identifier.hasPrefix($0) }
        let seasonal = cos(2 * Double.pi * (doy - 172) / 365.25) * (southern ? -1 : 1)
        let dayLength = 12 + 3.2 * seasonal
        let solarNoon = 12.3 + (timeZone.isDaylightSavingTime(for: date) ? 1 : 0)
        return (solarNoon - dayLength / 2, solarNoon + dayLength / 2)
    }

    static func state(at date: Date, calendar: Calendar = .current, timeZone: TimeZone = .current) -> State {
        var cal = calendar
        cal.timeZone = timeZone
        let c = cal.dateComponents([.hour, .minute, .second], from: date)
        let h = Double(c.hour ?? 12) + Double(c.minute ?? 0) / 60 + Double(c.second ?? 0) / 3600
        let (sr, ss) = sunTimes(for: date, calendar: cal, timeZone: timeZone)
        return state(hour: h, sunrise: sr, sunset: ss)
    }

    static func state(hour h: Double, sunrise sr: Double, sunset ss: Double) -> State {
        // Darkness ramps from 15 min before sunset to 45 min after it, and back around sunrise.
        let dusk = smoothstep(ss - 0.25, ss + 0.75, h)
        let dawn = 1 - smoothstep(sr - 0.75, sr + 0.25, h)
        let night = h >= 12 ? dusk : dawn
        let golden = max(bell(h, center: ss - 0.15, width: 1.1), bell(h, center: sr + 0.1, width: 0.9))
        let sun = min(1, max(0, (h - sr) / (ss - sr)))
        let nightLength = 24 - (ss - sr)
        let sinceDusk = h >= ss ? h - ss : h + 24 - ss
        let moon = min(1, max(0, sinceDusk / nightLength))
        return State(night: night, golden: golden * (1 - night * 0.6), sunProgress: sun, moonProgress: moon, sunrise: sr, sunset: ss)
    }

    static func resolved(mode: Mode, at date: Date) -> State {
        let s = state(at: date)
        switch mode {
        case .auto: return s
        case .day: return State(night: 0, golden: 0, sunProgress: 0.45, moonProgress: 0, sunrise: s.sunrise, sunset: s.sunset)
        case .night: return State(night: 1, golden: 0, sunProgress: 1, moonProgress: 0.4, sunrise: s.sunrise, sunset: s.sunset)
        }
    }

    private static func smoothstep(_ a: Double, _ b: Double, _ x: Double) -> Double {
        let t = min(1, max(0, (x - a) / (b - a)))
        return t * t * (3 - 2 * t)
    }

    private static func bell(_ x: Double, center: Double, width: Double) -> Double {
        let d = abs(x - center) / width
        guard d < 1 else { return 0 }
        let v = 1 - d
        return v * v * (3 - 2 * v)
    }
}
