import Foundation

enum ScheduleKind: String, Codable, CaseIterable, Identifiable {
    case daily, every, week
    var id: String { rawValue }
    var title: String {
        switch self {
        case .daily: return "Daily"
        case .every: return "Every N days"
        case .week: return "N× / week"
        }
    }
}

enum HabitKind: String, Codable, CaseIterable, Identifiable {
    case habit, focus
    var id: String { rawValue }
}

struct HabitMeta: Equatable {
    var label: String
    var due: Bool
    var streak: Int
    var weekDone: Int
    var weekTarget: Int
    var nextInDays: Int
}

/// Pure scheduling / streak rules for a habit. Kept free of SwiftData so it is easy to unit-test.
struct HabitRules {
    var schedule: ScheduleKind
    var n: Int
    var startKey: String
    var done: Set<String>

    var interval: Int { max(1, n) }

    func isDue(_ key: String) -> Bool {
        let d = Day.between(startKey, key)
        if d < 0 { return false }
        if schedule == .every { return d % interval == 0 }
        return true
    }

    func isDone(_ key: String) -> Bool { done.contains(key) }

    func weekCount(_ key: String) -> Int {
        let start = Day.weekStart(key)
        var count = 0
        for i in 0..<7 where done.contains(Day.add(start, i)) {
            count += 1
        }
        return count
    }

    /// Consecutive completed due-days ending at `key` (or the day before, if `key` isn't done yet).
    func streak(_ key: String) -> Int {
        var k = done.contains(key) ? key : Day.add(key, -1)
        var count = 0
        for _ in 0..<800 {
            if Day.between(startKey, k) < 0 { break }
            if isDue(k) {
                if done.contains(k) { count += 1 } else { break }
            }
            k = Day.add(k, -1)
        }
        return count
    }

    func meta(_ key: String) -> HabitMeta {
        switch schedule {
        case .week:
            let wk = weekCount(key)
            let due = wk < interval || done.contains(key)
            return HabitMeta(label: "\(interval)×/week", due: due, streak: 0, weekDone: wk, weekTarget: interval, nextInDays: 0)
        case .every:
            let d = Day.between(startKey, key)
            let due = d >= 0 && d % interval == 0
            let rem = ((d % interval) + interval) % interval
            let next = due ? 0 : interval - rem
            return HabitMeta(label: "Every \(interval) days", due: due, streak: streak(key), weekDone: 0, weekTarget: 0, nextInDays: next)
        case .daily:
            return HabitMeta(label: "Daily", due: true, streak: streak(key), weekDone: 0, weekTarget: 0, nextInDays: 0)
        }
    }

    /// Completion rate over the last 30 days (28 for weekly targets), excluding today.
    func rate30(today: String) -> Double {
        if schedule == .week {
            var c = 0
            for i in 1...28 where done.contains(Day.add(today, -i)) { c += 1 }
            return min(1, Double(c) / Double(interval * 4))
        }
        var due = 0
        var dn = 0
        for i in 1...30 {
            let k = Day.add(today, -i)
            if isDue(k) {
                due += 1
                if done.contains(k) { dn += 1 }
            }
        }
        return due == 0 ? 0 : Double(dn) / Double(due)
    }
}

enum Stats {
    /// Share of due (non-weekly) habits completed on a day.
    static func dayRatio(_ rules: [HabitRules], _ key: String) -> Double {
        var due = 0
        var dn = 0
        for r in rules where r.schedule != .week {
            if r.isDue(key) {
                due += 1
                if r.done.contains(key) { dn += 1 }
            }
        }
        return due == 0 ? 0 : Double(dn) / Double(due)
    }

    static func heatLevel(ratio: Double) -> Int {
        if ratio <= 0 { return 0 }
        if ratio < 0.34 { return 1 }
        if ratio < 0.6 { return 2 }
        if ratio < 0.85 { return 3 }
        return 4
    }

    static func heatLevel(focusMinutes m: Int) -> Int {
        if m <= 0 { return 0 }
        if m < 30 { return 1 }
        if m < 60 { return 2 }
        if m < 90 { return 3 }
        return 4
    }

    static func frictionTag(for text: String) -> String {
        let t = text.lowercased()
        if t.isEmpty { return "" }
        func has(_ words: [String]) -> Bool { words.contains { t.contains($0) } }
        if has(["phone", "scroll", "screen", "late", "night", "tiktok", "youtube", "instagram"]) { return "Late screens" }
        if has(["meeting", "call"]) { return "Meetings" }
        if has(["tired", "energy", "sleep", "slump", "sick"]) { return "Low energy" }
        if has(["distract", "notif", "snack", "ping", "slack", "message"]) { return "Distractions" }
        if has(["goal", "unclear", "plan", "priorit"]) { return "Unclear goal" }
        return "Other"
    }
}
