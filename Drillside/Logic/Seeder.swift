import Foundation
import SwiftData

@MainActor
enum Seeder {
    /// Creates the profile, a starter habit set and a starter island on first launch.
    static func seedIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Profile>())) ?? 0
        guard existing == 0 else { return }

        let profile = Profile()
        profile.shells = 120
        profile.inventory = [PropType.lantern.rawValue]
        context.insert(profile)

        let today = Day.add(Day.today, -Day.retroWindow)
        let starters: [(String, Int, HabitKind, Int, ScheduleKind, Int)] = [
            ("Write top 3 outcomes", 0, .habit, 25, .daily, 1),
            ("Weekly review", 0, .focus, 30, .week, 1),
            ("Morning walk", 1, .habit, 25, .daily, 1),
            ("Gym session", 1, .habit, 25, .week, 3),
            ("Ship one small improvement", 2, .focus, 25, .daily, 1),
            ("Read 20 pages", 3, .habit, 25, .daily, 1),
            ("Deep work block", 4, .focus, 50, .daily, 1),
            ("Phone in drawer by 9pm", 4, .habit, 25, .daily, 1)
        ]
        var perPillar: [Int: Int] = [:]
        for s in starters {
            let idx = perPillar[s.1, default: 0]
            perPillar[s.1] = idx + 1
            context.insert(Habit(name: s.0, pillar: s.1, kind: s.2, focusMinutes: s.3, schedule: s.4, n: s.5,
                                 startKey: today, sortOrder: s.1 * 1000 + idx))
        }

        let island: [(PropType, Int, Int)] = [
            (.tree, 0, 1), (.palm, 0, 4), (.campfire, 3, 3), (.hammock, 1, 2), (.flowers, 5, 3), (.rock, 4, 5)
        ]
        for p in island {
            context.insert(PlacedProp(type: p.0, row: p.1, col: p.2))
        }
        try? context.save()
    }

    static func eraseEverything(_ context: ModelContext) {
        try? context.delete(model: Habit.self)
        try? context.delete(model: FocusSession.self)
        try? context.delete(model: LogEntry.self)
        try? context.delete(model: PlacedProp.self)
        try? context.delete(model: Profile.self)
        try? context.save()
    }
}
