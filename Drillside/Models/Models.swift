import Foundation
import SwiftData

/// Single row holding progression, island meta and settings.
@Model
final class Profile {
    var level: Int = 1
    var xp: Int = 0
    var shells: Int = 0
    var islandSize: Int = 6
    /// Unplaced props; each element is a `PropType` raw value (duplicates = count).
    var inventory: [String] = []
    var companions: [String] = []
    var pillarNames: [String] = []
    var pillarHints: [String] = []
    var workMinutes: Int = 25
    var breakMinutes: Int = 5
    var rounds: Int = 2
    var reminderOn: Bool = false
    var reminderHour: Int = 21
    var reminderMinute: Int = 0
    /// "system", "light" or "dark"
    var theme: String = "system"
    var isNight: Bool = false
    /// "auto" (follows the clock), "day" or "night".
    var skyMode: String = "auto"
    /// Show running focus sessions in the Dynamic Island / Lock Screen.
    var liveActivityOn: Bool = true
    var createdAt: Date = Date()
    // v1.4.0 (schema V3)
    var achievements: [String] = []
    /// One sentence the weekly review asks for, shown on DRILL all week.
    var weeklyFocus: String = ""
    /// Week-start keys ("yyyy-MM-dd" Mondays) for which a weekly review was completed.
    var reviewWeeks: [String] = []
    /// FocusSound raw value.
    var focusSound: String = "off"
    var soundVolume: Double = 0.6
    var chimeOn: Bool = true
    var seasonalOn: Bool = true
    var islandTheme: String = "classic"
    var ownedThemes: [String] = ["classic"]

    init() {
        level = 1
        xp = 0
        shells = 0
        islandSize = Economy.minIsland
        inventory = []
        companions = []
        pillarNames = Pillars.defaultNames
        pillarHints = Pillars.defaultHints
        workMinutes = 25
        breakMinutes = 5
        rounds = 2
        reminderOn = false
        reminderHour = 21
        reminderMinute = 0
        theme = "system"
        isNight = false
        skyMode = "auto"
        liveActivityOn = true
        createdAt = Date()
        achievements = []
        weeklyFocus = ""
        reviewWeeks = []
        focusSound = "off"
        soundVolume = 0.6
        chimeOn = true
        seasonalOn = true
        islandTheme = "classic"
        ownedThemes = ["classic"]
    }

    func pillarName(_ i: Int) -> String {
        i >= 0 && i < pillarNames.count ? pillarNames[i] : Pillars.defaultNames[max(0, min(4, i))]
    }

    func pillarHint(_ i: Int) -> String {
        i >= 0 && i < pillarHints.count ? pillarHints[i] : Pillars.defaultHints[max(0, min(4, i))]
    }

    var acronym: String { (0..<5).map { Pillars.letter(pillarName($0)) }.joined() }

    func inventoryCount(_ type: PropType) -> Int { inventory.filter { $0 == type.rawValue }.count }

    var inventoryCounts: [InventoryItem] {
        PropType.allCases.compactMap { t in
            let c = inventoryCount(t)
            return c > 0 ? InventoryItem(type: t, count: c) : nil
        }
    }

    func removeFromInventory(_ type: PropType) -> Bool {
        guard let i = inventory.firstIndex(of: type.rawValue) else { return false }
        inventory.remove(at: i)
        return true
    }

    var ownedCompanions: [CompanionType] { companions.compactMap(CompanionType.init(rawValue:)) }

    var wallet: Economy.Wallet {
        get { Economy.Wallet(level: level, xp: xp, shells: shells) }
        set {
            level = newValue.level
            xp = newValue.xp
            shells = newValue.shells
        }
    }

    /// Returns the number of levels gained.
    @discardableResult
    func award(xp dx: Int, shells ds: Int) -> Int {
        var w = wallet
        let gained = w.apply(xp: dx, shells: ds)
        wallet = w
        return gained
    }
}

@Model
final class Habit {
    var id: UUID = UUID()
    var name: String = ""
    var pillar: Int = 0
    var kindRaw: String = "habit"
    var focusMinutes: Int = 25
    var scheduleRaw: String = "daily"
    var scheduleN: Int = 1
    var startKey: String = ""
    var sortOrder: Int = 0
    var doneKeys: [String] = []
    var createdAt: Date = Date()
    /// Archived habits are hidden from DRILL but keep their history in stats (added in schema 1.3.0).
    var archived: Bool = false
    var archivedAt: Date?
    /// Past archived periods as "yyyy-MM-dd..yyyy-MM-dd"; those days are never due.
    var pauses: [String] = []
    // v1.4.0: quantity tracking ("Read 20 pages" → log 32) and per-day notes
    /// Unit label, e.g. "pages". Empty = plain check-off habit.
    var unit: String = ""
    /// Daily target amount (0 = no target).
    var target: Int = 0
    /// "yyyy-MM-dd=amount" entries.
    var amounts: [String] = []
    /// "yyyy-MM-dd=note" entries.
    var notes: [String] = []

    init(name: String, pillar: Int, kind: HabitKind, focusMinutes: Int, schedule: ScheduleKind, n: Int, startKey: String, sortOrder: Int) {
        self.id = UUID()
        self.name = name
        self.pillar = pillar
        self.kindRaw = kind.rawValue
        self.focusMinutes = focusMinutes
        self.scheduleRaw = schedule.rawValue
        self.scheduleN = n
        self.startKey = startKey
        self.sortOrder = sortOrder
        self.doneKeys = []
        self.createdAt = Date()
    }

    var kind: HabitKind {
        get { HabitKind(rawValue: kindRaw) ?? .habit }
        set { kindRaw = newValue.rawValue }
    }

    var schedule: ScheduleKind {
        get { ScheduleKind(rawValue: scheduleRaw) ?? .daily }
        set { scheduleRaw = newValue.rawValue }
    }

    var rules: HabitRules {
        HabitRules(schedule: schedule, n: scheduleN, startKey: startKey, done: Set(doneKeys),
                   endKey: archived ? archivedAt.map(Day.key) ?? Day.today : nil,
                   pauses: HabitRules.parsePauses(pauses))
    }

    func isDone(_ key: String) -> Bool { doneKeys.contains(key) }

    var tracksAmount: Bool { !unit.trimmingCharacters(in: .whitespaces).isEmpty }

    func amount(on key: String) -> Int? { DayValues.get(amounts, key).flatMap(Int.init) }
    func note(on key: String) -> String? { DayValues.get(notes, key) }

    func setAmount(_ value: Int?, on key: String) { amounts = DayValues.set(amounts, key, value.map(String.init)) }
    func setNote(_ text: String?, on key: String) {
        let t = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        notes = DayValues.set(notes, key, (t?.isEmpty ?? true) ? nil : t)
    }

    /// Sum of logged amounts over the `days` days ending at `key` (inclusive).
    func total(days: Int, endingAt key: String) -> Int {
        (0..<days).reduce(0) { $0 + (amount(on: Day.add(key, -$1)) ?? 0) }
    }

    func setDone(_ done: Bool, on key: String) {
        if done {
            if !doneKeys.contains(key) { doneKeys.append(key) }
        } else {
            doneKeys.removeAll { $0 == key }
        }
    }
}

@Model
final class FocusSession {
    var id: UUID = UUID()
    var startedAt: Date = Date()
    var dayKey: String = ""
    var minutes: Int = 0
    var habitID: UUID?
    var title: String = ""
    var completed: Bool = false

    init(startedAt: Date, dayKey: String, minutes: Int, habitID: UUID?, title: String, completed: Bool) {
        self.id = UUID()
        self.startedAt = startedAt
        self.dayKey = dayKey
        self.minutes = minutes
        self.habitID = habitID
        self.title = title
        self.completed = completed
    }
}

@Model
final class LogEntry {
    @Attribute(.unique) var dayKey: String = ""
    var well: String = ""
    var wrong: String = ""
    var fix: String = ""
    var tag: String = ""
    var updatedAt: Date = Date()

    init(dayKey: String, well: String, wrong: String, fix: String) {
        self.dayKey = dayKey
        self.well = well
        self.wrong = wrong
        self.fix = fix
        self.tag = Stats.frictionTag(for: wrong)
        self.updatedAt = Date()
    }
}

@Model
final class PlacedProp {
    var id: UUID = UUID()
    var typeRaw: String = "tree"
    var row: Int = 0
    var col: Int = 0

    init(type: PropType, row: Int, col: Int) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.row = row
        self.col = col
    }

    var type: PropType { PropType(rawValue: typeRaw) ?? .tree }
}

struct InventoryItem: Identifiable, Equatable {
    let type: PropType
    let count: Int
    var id: String { type.rawValue }
}

/// Tiny "key=value" list helpers used for per-day amounts and notes (keeps the schema to plain arrays).
enum DayValues {
    static func get(_ list: [String], _ key: String) -> String? {
        let prefix = key + "="
        return list.last(where: { $0.hasPrefix(prefix) }).map { String($0.dropFirst(prefix.count)) }
    }

    static func set(_ list: [String], _ key: String, _ value: String?) -> [String] {
        var out = list.filter { !$0.hasPrefix(key + "=") }
        if let value { out.append(key + "=" + value) }
        return out
    }
}

enum AppSchema {
    static let models: [any PersistentModel.Type] = [Profile.self, Habit.self, FocusSession.self, LogEntry.self, PlacedProp.self]
}
