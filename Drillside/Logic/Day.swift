import Foundation

/// Calendar-day helpers. Days are stored as "yyyy-MM-dd" keys in the user's current calendar,
/// which keeps streaks and check-offs stable regardless of the time of day they were recorded.
enum Day {
    static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        cal.firstWeekday = 2 // Monday
        return cal
    }

    static func key(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 2000, c.month ?? 1, c.day ?? 1)
    }

    static var today: String { key(Date()) }

    static func date(_ key: String) -> Date {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return Date() }
        var c = DateComponents()
        c.year = parts[0]
        c.month = parts[1]
        c.day = parts[2]
        c.hour = 12 // noon avoids DST edge cases
        return calendar.date(from: c) ?? Date()
    }

    static func add(_ key: String, _ days: Int) -> String {
        let d = calendar.date(byAdding: .day, value: days, to: date(key)) ?? date(key)
        return Self.key(d)
    }

    /// Whole days from `a` to `b` (positive when b is later).
    static func between(_ a: String, _ b: String) -> Int {
        let da = calendar.startOfDay(for: date(a))
        let db = calendar.startOfDay(for: date(b))
        return calendar.dateComponents([.day], from: da, to: db).day ?? 0
    }

    /// Monday of the week containing `key`.
    static func weekStart(_ key: String) -> String {
        let wd = calendar.component(.weekday, from: date(key)) // 1 = Sunday
        let offset = (wd + 5) % 7
        return add(key, -offset)
    }

    static func weekdayIndexMondayFirst(_ key: String) -> Int {
        let wd = calendar.component(.weekday, from: date(key))
        return (wd + 5) % 7
    }

    static func dayOfMonth(_ key: String) -> Int {
        calendar.component(.day, from: date(key))
    }

    static func month(_ key: String) -> Int {
        calendar.component(.month, from: date(key))
    }

    private static let shortFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEE MMM d")
        return f
    }()

    private static let longFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEEE MMMM d")
        return f
    }()

    private static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEE")
        return f
    }()

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMM")
        return f
    }()

    static func short(_ key: String) -> String { shortFormatter.string(from: date(key)) }
    static func long(_ key: String) -> String { longFormatter.string(from: date(key)) }
    static func weekday(_ key: String) -> String { weekdayFormatter.string(from: date(key)) }
    static func monthName(_ key: String) -> String { monthFormatter.string(from: date(key)) }

    /// Check-offs are allowed for today and up to two days back.
    static let retroWindow = 2

    static func canEdit(_ key: String, today: String = Day.today) -> Bool {
        let d = between(key, today)
        return d >= 0 && d <= retroWindow
    }
}
