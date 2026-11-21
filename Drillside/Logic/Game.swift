import Foundation
import SwiftData

/// All state-changing game actions live here so views stay thin.
@MainActor
enum Game {
    struct Outcome {
        var message: String?
        var levelsGained: Int = 0
        var ok: Bool = true
    }

    // MARK: Habits

    /// Toggles a habit for a day within the retro window. Returns true if it is now done.
    @discardableResult
    static func toggle(_ habit: Habit, day: String, profile: Profile) -> Outcome {
        guard Day.canEdit(day) else {
            return Outcome(message: "Check-offs are limited to \(Day.retroWindow) days back", ok: false)
        }
        if habit.isDone(day) {
            habit.setDone(false, on: day)
            profile.award(xp: -Economy.habitXP, shells: -Economy.habitShells)
            return Outcome()
        }
        habit.setDone(true, on: day)
        let lv = profile.award(xp: Economy.habitXP, shells: Economy.habitShells)
        return Outcome(levelsGained: lv)
    }

    static func nextSortOrder(pillar: Int, habits: [Habit]) -> Int {
        let inPillar = habits.filter { $0.pillar == pillar }
        return pillar * 1000 + (inPillar.map { $0.sortOrder % 1000 }.max() ?? -1) + 1
    }

    static func reorder(_ ordered: [Habit]) {
        for (i, h) in ordered.enumerated() {
            h.sortOrder = h.pillar * 1000 + i
        }
    }

    // MARK: Focus

    /// Records a finished (or ended-early) focus session and pays out rewards.
    static func commitFocus(minutes: Int, completed: Bool, habitID: UUID?, title: String, startedAt: Date,
                            profile: Profile, habits: [Habit], context: ModelContext) -> (levels: Int, checkedOff: Bool) {
        var levels = 0
        var checked = false
        if minutes > 0 {
            context.insert(FocusSession(startedAt: startedAt, dayKey: Day.today, minutes: minutes,
                                        habitID: habitID, title: title, completed: completed))
            levels += profile.award(xp: minutes * Economy.xpPerFocusMinute, shells: minutes * Economy.shellsPerFocusMinute)
        }
        if completed, let hid = habitID, let h = habits.first(where: { $0.id == hid }), !h.isDone(Day.today) {
            h.setDone(true, on: Day.today)
            levels += profile.award(xp: Economy.habitXP, shells: Economy.habitShells)
            checked = true
        }
        try? context.save()
        return (levels, checked)
    }

    // MARK: Log

    static func saveLog(day: String, well: String, wrong: String, fix: String,
                        existing: LogEntry?, profile: Profile, context: ModelContext) -> Outcome {
        let w = well.trimmingCharacters(in: .whitespacesAndNewlines)
        let x = wrong.trimmingCharacters(in: .whitespacesAndNewlines)
        let f = fix.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !w.isEmpty || !x.isEmpty else {
            return Outcome(message: "Add at least one line: a win or a snag", ok: false)
        }
        if let e = existing {
            e.well = w
            e.wrong = x
            e.fix = f
            e.tag = Stats.frictionTag(for: x)
            e.updatedAt = Date()
            try? context.save()
            return Outcome(message: "Check-in updated")
        }
        context.insert(LogEntry(dayKey: day, well: w, wrong: x, fix: f))
        let lv = profile.award(xp: Economy.logXP, shells: Economy.logShells)
        try? context.save()
        return Outcome(message: "📝 Logged! +\(Economy.logXP) XP · +\(Economy.logShells) 🐚", levelsGained: lv)
    }

    // MARK: Shop

    static func buy(_ type: PropType, profile: Profile) -> Outcome {
        guard profile.level >= type.unlockLevel else { return Outcome(message: "Unlocks at level \(type.unlockLevel)", ok: false) }
        guard profile.shells >= type.price else {
            let missing = type.price - profile.shells
            return Outcome(message: "Need 🐚 \(missing) more. A \(missing)-minute focus session covers it.", ok: false)
        }
        profile.shells -= type.price
        profile.inventory.append(type.rawValue)
        return Outcome(message: "\(type.name) added to inventory")
    }

    static func buy(_ type: CompanionType, profile: Profile) -> Outcome {
        guard !profile.companions.contains(type.rawValue) else { return Outcome(message: "Already on your island", ok: false) }
        guard profile.level >= type.unlockLevel else { return Outcome(message: "Unlocks at level \(type.unlockLevel)", ok: false) }
        guard profile.shells >= type.price else {
            return Outcome(message: "Need 🐚 \(type.price - profile.shells) more", ok: false)
        }
        profile.shells -= type.price
        profile.companions.append(type.rawValue)
        return Outcome(message: "\(type.name) moved onto your island!")
    }

    static func expandIsland(profile: Profile) -> Outcome {
        let n = profile.islandSize
        guard n < Economy.maxIsland else { return Outcome(message: "Maximum size reached", ok: false) }
        let needLevel = Economy.expandLevel(to: n + 1)
        guard profile.level >= needLevel else { return Outcome(message: "Reach level \(needLevel) to expand to \(n + 1)×\(n + 1)", ok: false) }
        let price = Economy.expandPrice(from: n)
        guard profile.shells >= price else { return Outcome(message: "Need 🐚 \(price - profile.shells) more to expand", ok: false) }
        profile.shells -= price
        profile.islandSize = n + 1
        return Outcome(message: "🏝️ Island expanded to \(n + 1)×\(n + 1)")
    }

    // MARK: Island layout

    static func isFree(row: Int, col: Int, size: Int, props: [PlacedProp], ignoring: UUID? = nil) -> Bool {
        guard row >= 0, col >= 0, row < size, col < size else { return false }
        return !props.contains { $0.row == row && $0.col == col && $0.id != ignoring }
    }

    static func place(_ type: PropType, row: Int, col: Int, profile: Profile, props: [PlacedProp], context: ModelContext) -> Outcome {
        guard isFree(row: row, col: col, size: profile.islandSize, props: props) else {
            return Outcome(message: "Pick an empty tile", ok: false)
        }
        guard profile.removeFromInventory(type) else { return Outcome(message: "None left in inventory", ok: false) }
        context.insert(PlacedProp(type: type, row: row, col: col))
        try? context.save()
        return Outcome()
    }

    static func move(_ prop: PlacedProp, row: Int, col: Int, size: Int, props: [PlacedProp]) -> Outcome {
        guard isFree(row: row, col: col, size: size, props: props, ignoring: prop.id) else {
            return Outcome(message: row < 0 || col < 0 || row >= size || col >= size ? "Drop it on the island" : "That tile is taken", ok: false)
        }
        prop.row = row
        prop.col = col
        return Outcome()
    }

    static func store(_ prop: PlacedProp, profile: Profile, context: ModelContext) {
        profile.inventory.append(prop.typeRaw)
        context.delete(prop)
        try? context.save()
    }

    static func resetLayout(refund: Bool, props: [PlacedProp], profile: Profile, context: ModelContext) -> Outcome {
        let value = props.reduce(0) { $0 + $1.type.price }
        for p in props {
            if !refund { profile.inventory.append(p.typeRaw) }
            context.delete(p)
        }
        if refund { profile.shells += value }
        try? context.save()
        return Outcome(message: refund ? "🐚 \(value) refunded" : "Everything is back in your inventory")
    }
}
