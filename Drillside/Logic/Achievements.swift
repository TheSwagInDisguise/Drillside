import Foundation

/// Snapshot of everything achievements are measured against.
struct AchievementStats: Equatable {
    var focusMinutes = 0
    var sessions = 0
    var bestStreak = 0
    var checkIns = 0
    var logStreak = 0
    var checkOffs = 0
    var level = 1
    var islandSize = 6
    var placedProps = 0
    var weeklyReviews = 0
    var allPillarsDays = 0
    var companions = 0
}

enum Achievement: String, CaseIterable, Identifiable {
    case firstFocus, focus10h, focus100h
    case streak7, streak30
    case checkins7, logStreak30
    case checkoffs100, checkoffs1000
    case allPillars
    case level5, level10, level15
    case island10, decorator, menagerie
    case reviewer

    var id: String { rawValue }

    enum Reward: Equatable {
        case shells(Int)
        case prop(PropType)
    }

    var title: String {
        switch self {
        case .firstFocus: return "First Drill"
        case .focus10h: return "Ten Hours Deep"
        case .focus100h: return "Hundred-Hour Focus"
        case .streak7: return "Week Warrior"
        case .streak30: return "Unbreakable"
        case .checkins7: return "Honest Week"
        case .logStreak30: return "Daily Chronicler"
        case .checkoffs100: return "Centurion"
        case .checkoffs1000: return "Thousand Ticks"
        case .allPillars: return "Full DRILL"
        case .level5: return "Rising Mole"
        case .level10: return "Seasoned Driller"
        case .level15: return "Island Legend"
        case .island10: return "Land Ho"
        case .decorator: return "Decorator"
        case .menagerie: return "Menagerie"
        case .reviewer: return "Big-Picture Thinker"
        }
    }

    var detail: String {
        switch self {
        case .firstFocus: return "Finish your first focus session"
        case .focus10h: return "Focus for 10 hours in total"
        case .focus100h: return "Focus for 100 hours in total"
        case .streak7: return "Keep any habit streak for 7 days"
        case .streak30: return "Keep any habit streak for 30 days"
        case .checkins7: return "Write 7 daily check-ins"
        case .logStreak30: return "Check in 30 days in a row"
        case .checkoffs100: return "Check off 100 habits"
        case .checkoffs1000: return "Check off 1,000 habits"
        case .allPillars: return "Complete a habit in all five pillars on one day"
        case .level5: return "Reach level 5"
        case .level10: return "Reach level 10"
        case .level15: return "Reach level 15"
        case .island10: return "Grow your island to 10×10"
        case .decorator: return "Place 25 decorations"
        case .menagerie: return "Adopt 4 companions"
        case .reviewer: return "Complete 4 weekly reviews"
        }
    }

    var icon: String {
        switch self {
        case .firstFocus: return "⛏️"
        case .focus10h: return "⏱️"
        case .focus100h: return "💎"
        case .streak7: return "🚩"
        case .streak30: return "🔥"
        case .checkins7: return "📝"
        case .logStreak30: return "🔔"
        case .checkoffs100: return "✅"
        case .checkoffs1000: return "🏅"
        case .allPillars: return "🖐️"
        case .level5: return "⭐️"
        case .level10: return "🌈"
        case .level15: return "👑"
        case .island10: return "🏝️"
        case .decorator: return "🎨"
        case .menagerie: return "🐾"
        case .reviewer: return "🧭"
        }
    }

    var reward: Reward {
        switch self {
        case .firstFocus: return .shells(25)
        case .focus10h: return .shells(150)
        case .focus100h: return .prop(.obelisk)
        case .streak7: return .prop(.pennant)
        case .streak30: return .shells(300)
        case .checkins7: return .shells(60)
        case .logStreak30: return .prop(.bell)
        case .checkoffs100: return .shells(150)
        case .checkoffs1000: return .shells(600)
        case .allPillars: return .shells(80)
        case .level5: return .shells(100)
        case .level10: return .prop(.rainbow)
        case .level15: return .shells(1000)
        case .island10: return .shells(200)
        case .decorator: return .shells(150)
        case .menagerie: return .shells(200)
        case .reviewer: return .shells(150)
        }
    }

    var rewardLabel: String {
        switch reward {
        case .shells(let n): return "🐚 \(n)"
        case .prop(let p): return "🎁 \(p.name)"
        }
    }

    /// (current, goal)
    func progress(_ s: AchievementStats) -> (Int, Int) {
        switch self {
        case .firstFocus: return (s.sessions, 1)
        case .focus10h: return (s.focusMinutes, 600)
        case .focus100h: return (s.focusMinutes, 6000)
        case .streak7: return (s.bestStreak, 7)
        case .streak30: return (s.bestStreak, 30)
        case .checkins7: return (s.checkIns, 7)
        case .logStreak30: return (s.logStreak, 30)
        case .checkoffs100: return (s.checkOffs, 100)
        case .checkoffs1000: return (s.checkOffs, 1000)
        case .allPillars: return (s.allPillarsDays, 1)
        case .level5: return (s.level, 5)
        case .level10: return (s.level, 10)
        case .level15: return (s.level, 15)
        case .island10: return (s.islandSize, 10)
        case .decorator: return (s.placedProps, 25)
        case .menagerie: return (s.companions, 4)
        case .reviewer: return (s.weeklyReviews, 4)
        }
    }

    func isMet(_ s: AchievementStats) -> Bool {
        let p = progress(s)
        return p.0 >= p.1
    }
}

enum AchievementEngine {
    static func stats(profile: Profile, habits: [Habit], sessions: [FocusSession], logs: [LogEntry], placedCount: Int,
                      today: String = Day.today) -> AchievementStats {
        var s = AchievementStats()
        s.focusMinutes = sessions.reduce(0) { $0 + $1.minutes }
        s.sessions = sessions.filter(\.completed).count
        s.bestStreak = habits.map { $0.rules.streak(today) }.max() ?? 0
        s.checkIns = logs.count
        let logKeys = Set(logs.map(\.dayKey))
        var k = logKeys.contains(today) ? today : Day.add(today, -1)
        while logKeys.contains(k) {
            s.logStreak += 1
            k = Day.add(k, -1)
        }
        s.checkOffs = habits.reduce(0) { $0 + $1.doneKeys.count }
        s.level = profile.level
        s.islandSize = profile.islandSize
        s.placedProps = placedCount
        s.weeklyReviews = profile.reviewWeeks.count
        s.companions = profile.companions.count
        var pillarsByDay: [String: Set<Int>] = [:]
        for h in habits {
            for d in h.doneKeys { pillarsByDay[d, default: []].insert(h.pillar) }
        }
        s.allPillarsDays = pillarsByDay.values.filter { $0.count >= 5 }.count
        return s
    }

    /// Unlocks every newly met achievement, pays out rewards and returns what was unlocked.
    @MainActor
    static func evaluate(profile: Profile, stats: AchievementStats) -> [Achievement] {
        let owned = Set(profile.achievements)
        let fresh = Achievement.allCases.filter { !owned.contains($0.rawValue) && $0.isMet(stats) }
        for a in fresh {
            profile.achievements.append(a.rawValue)
            switch a.reward {
            case .shells(let n): profile.award(xp: 20, shells: n)
            case .prop(let p):
                profile.award(xp: 20, shells: 0)
                profile.inventory.append(p.rawValue)
            }
        }
        return fresh
    }
}
