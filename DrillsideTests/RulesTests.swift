import XCTest
import SwiftData
@testable import Drillside

final class DayTests: XCTestCase {
    func testKeyRoundTrip() {
        let k = "2026-03-29" // DST change in many regions
        XCTAssertEqual(Day.key(Day.date(k)), k)
        XCTAssertEqual(Day.add(k, 1), "2026-03-30")
        XCTAssertEqual(Day.add(k, -29), "2026-02-28")
        XCTAssertEqual(Day.between("2026-02-28", "2026-03-02"), 2)
        XCTAssertEqual(Day.between("2026-03-02", "2026-02-28"), -2)
    }

    func testWeekStartsMonday() {
        XCTAssertEqual(Day.weekStart("2026-11-20"), "2026-11-16") // Friday → Monday
        XCTAssertEqual(Day.weekStart("2026-11-16"), "2026-11-16") // Monday
        XCTAssertEqual(Day.weekStart("2026-11-22"), "2026-11-16") // Sunday
    }

    func testRetroWindowIsTwoDays() {
        let today = "2026-11-20"
        XCTAssertTrue(Day.canEdit("2026-11-20", today: today))
        XCTAssertTrue(Day.canEdit("2026-11-19", today: today))
        XCTAssertTrue(Day.canEdit("2026-11-18", today: today))
        XCTAssertFalse(Day.canEdit("2026-11-17", today: today))
        XCTAssertFalse(Day.canEdit("2026-11-21", today: today))
    }
}

final class RulesTests: XCTestCase {
    func testDailyStreakCountsBackFromYesterdayWhenTodayOpen() {
        let r = HabitRules(schedule: .daily, n: 1, startKey: "2026-11-01", done: ["2026-11-17", "2026-11-18", "2026-11-19"])
        XCTAssertEqual(r.streak("2026-11-20"), 3)
        XCTAssertEqual(r.streak("2026-11-19"), 3)
        XCTAssertTrue(r.meta("2026-11-20").due)
    }

    func testDailyStreakBreaksOnMiss() {
        let r = HabitRules(schedule: .daily, n: 1, startKey: "2026-11-01", done: ["2026-11-20", "2026-11-18"])
        XCTAssertEqual(r.streak("2026-11-20"), 1)
    }

    func testEveryNDaysDueDates() {
        let r = HabitRules(schedule: .every, n: 3, startKey: "2026-11-01", done: [])
        XCTAssertTrue(r.isDue("2026-11-01"))
        XCTAssertFalse(r.isDue("2026-11-02"))
        XCTAssertTrue(r.isDue("2026-11-04"))
        XCTAssertFalse(r.isDue("2026-10-29")) // before start
        XCTAssertEqual(r.meta("2026-11-02").nextInDays, 2)
    }

    func testEveryNStreakSkipsRestDays() {
        let r = HabitRules(schedule: .every, n: 2, startKey: "2026-11-01", done: ["2026-11-01", "2026-11-03", "2026-11-05"])
        XCTAssertEqual(r.streak("2026-11-06"), 3)
    }

    func testWeeklyTargetBecomesRestWhenMet() {
        let r = HabitRules(schedule: .week, n: 2, startKey: "2026-11-01", done: ["2026-11-16", "2026-11-17"])
        let m = r.meta("2026-11-20")
        XCTAssertEqual(m.weekDone, 2)
        XCTAssertFalse(m.due)
        XCTAssertTrue(r.meta("2026-11-17").due) // done that day still shows as due/done
    }

    func testDayRatioIgnoresWeeklyHabits() {
        let a = HabitRules(schedule: .daily, n: 1, startKey: "2026-11-01", done: ["2026-11-20"])
        let b = HabitRules(schedule: .daily, n: 1, startKey: "2026-11-01", done: [])
        let w = HabitRules(schedule: .week, n: 3, startKey: "2026-11-01", done: [])
        XCTAssertEqual(Stats.dayRatio([a, b, w], "2026-11-20"), 0.5, accuracy: 0.0001)
    }

    func testFrictionTags() {
        XCTAssertEqual(Stats.frictionTag(for: "Doom-scrolled after 9pm"), "Late screens")
        XCTAssertEqual(Stats.frictionTag(for: "Back-to-back meetings"), "Meetings")
        XCTAssertEqual(Stats.frictionTag(for: ""), "")
    }
}

final class EconomyTests: XCTestCase {
    func testLevelCurve() {
        XCTAssertEqual(Economy.xpNeeded(forLevel: 1), 100)
        XCTAssertEqual(Economy.xpNeeded(forLevel: 3), 200)
    }

    func testRewardsLevelUpAndCarryOver() {
        var w = Economy.Wallet(level: 1, xp: 95, shells: 0)
        let gained = w.apply(xp: 10, shells: 10)
        XCTAssertEqual(gained, 1)
        XCTAssertEqual(w.level, 2)
        XCTAssertEqual(w.xp, 5)
        XCTAssertEqual(w.shells, 10)
    }

    func testReversalNeverGoesNegative() {
        var w = Economy.Wallet(level: 2, xp: 3, shells: 1)
        w.apply(xp: -5, shells: -2)
        XCTAssertEqual(w.xp, 0)
        XCTAssertEqual(w.shells, 0)
        XCTAssertEqual(w.level, 2)
    }

    func testExpandPrices() {
        XCTAssertEqual(Economy.expandPrice(from: 6), 150)
        XCTAssertEqual(Economy.expandPrice(from: 8), 450)
        XCTAssertEqual(Economy.expandPrice(from: 15), 2445)
        XCTAssertEqual(Economy.expandLevel(to: 7), 2)
        XCTAssertEqual(Economy.expandLevel(to: 16), 11)
        XCTAssertEqual(Economy.maxIsland, 16)
    }

    func testCatalogIsConsistent() {
        XCTAssertGreaterThanOrEqual(PropType.allCases.count, 60)
        for cat in PropCategory.allCases { XCTAssertFalse(PropType.items(in: cat).isEmpty, "\(cat) is empty") }
        XCTAssertEqual(Set(PropType.allCases.map(\.name)).count, PropType.allCases.count, "names must be unique")
        for p in PropType.allCases where !p.isExclusive {
            XCTAssertGreaterThan(p.price, 0)
            XCTAssertGreaterThanOrEqual(p.unlockLevel, 1)
            if p.isWalkable { XCTAssertTrue(p.isFlat) }
        }
        XCTAssertFalse(PropType.pond.isWalkable)
        XCTAssertTrue(PropType.path.isWalkable)
        XCTAssertEqual(CompanionType.allCases.count, 9)
        XCTAssertEqual(Set(CompanionType.allCases.map(\.name)).count, 9)
    }
}

final class FocusTimerTests: XCTestCase {
    func testWallClockPhasesAndEarnings() {
        let t0 = Date(timeIntervalSince1970: 1_000_000)
        let timer = FocusTimer(title: "Test", pillar: 4, habitID: nil, work: 25, rest: 5, rounds: 2)
        timer.start(at: t0)
        timer.tick(t0.addingTimeInterval(10 * 60 + 30))
        XCTAssertEqual(timer.earnedMinutes, 10)
        XCTAssertEqual(timer.phase, .work)

        timer.tick(t0.addingTimeInterval(26 * 60)) // into the break
        XCTAssertEqual(timer.phase, .rest)
        XCTAssertEqual(timer.earnedMinutes, 25)

        timer.tick(t0.addingTimeInterval(61 * 60)) // past the end of round 2
        XCTAssertTrue(timer.finished)
        XCTAssertTrue(timer.completed)
        XCTAssertEqual(timer.earnedMinutes, 50)
    }

    func testPauseStopsEarning() {
        let t0 = Date(timeIntervalSince1970: 2_000_000)
        let timer = FocusTimer(title: "Test", pillar: 0, habitID: nil, work: 25, rest: 5, rounds: 1)
        timer.start(at: t0)
        timer.pause(at: t0.addingTimeInterval(5 * 60))
        timer.tick(t0.addingTimeInterval(60 * 60))
        XCTAssertEqual(timer.earnedMinutes, 5)
        XCTAssertFalse(timer.finished)
        timer.resume(at: t0.addingTimeInterval(60 * 60))
        timer.end(at: t0.addingTimeInterval(62 * 60 + 10))
        XCTAssertEqual(timer.earnedMinutes, 7)
        XCTAssertFalse(timer.completed)
    }
}

final class SkyClockTests: XCTestCase {
    func testDayNightAndGolden() {
        let noon = SkyClock.state(hour: 13, sunrise: 6.5, sunset: 20)
        XCTAssertEqual(noon.night, 0, accuracy: 0.001)
        XCTAssertEqual(noon.golden, 0, accuracy: 0.001)
        let midnight = SkyClock.state(hour: 0.5, sunrise: 6.5, sunset: 20)
        XCTAssertEqual(midnight.night, 1, accuracy: 0.001)
        let sunset = SkyClock.state(hour: 19.9, sunrise: 6.5, sunset: 20)
        XCTAssertGreaterThan(sunset.golden, 0.5)
        XCTAssertLessThan(sunset.night, 0.4)
        let lateDusk = SkyClock.state(hour: 20.5, sunrise: 6.5, sunset: 20)
        XCTAssertGreaterThan(lateDusk.night, 0.3)
        XCTAssertLessThan(lateDusk.night, 1)
        let dawn = SkyClock.state(hour: 6.5, sunrise: 6.5, sunset: 20)
        XCTAssertGreaterThan(dawn.golden, 0.3)
    }

    func testSeasonsChangeDayLength() {
        let cal = Calendar(identifier: .gregorian)
        let tz = TimeZone(identifier: "Europe/Amsterdam")!
        let june = cal.date(from: DateComponents(timeZone: tz, year: 2026, month: 6, day: 21, hour: 12))!
        let december = cal.date(from: DateComponents(timeZone: tz, year: 2026, month: 12, day: 21, hour: 12))!
        let j = SkyClock.sunTimes(for: june, calendar: cal, timeZone: tz)
        let d = SkyClock.sunTimes(for: december, calendar: cal, timeZone: tz)
        XCTAssertGreaterThan(j.sunset - j.sunrise, d.sunset - d.sunrise + 5)
        let syd = TimeZone(identifier: "Australia/Sydney")!
        let sj = SkyClock.sunTimes(for: june, calendar: cal, timeZone: syd)
        XCTAssertLessThan(sj.sunset - sj.sunrise, 11)
    }

    func testForcedModes() {
        XCTAssertEqual(SkyClock.resolved(mode: .day, at: Date()).night, 0)
        XCTAssertEqual(SkyClock.resolved(mode: .night, at: Date()).night, 1)
        XCTAssertEqual(SkyClock.Mode.auto.next, .day)
        XCTAssertEqual(SkyClock.Mode.night.next, .auto)
    }
}

final class ArchiveTests: XCTestCase {
    func testArchivedHabitStopsBeingDueButKeepsHistory() {
        let r = HabitRules(schedule: .daily, n: 1, startKey: "2026-11-01", done: ["2026-11-10", "2026-11-11"], endKey: "2026-11-15")
        XCTAssertTrue(r.isDue("2026-11-14"))
        XCTAssertFalse(r.isDue("2026-11-15"))
        XCTAssertFalse(r.isDue("2026-12-01"))
        XCTAssertEqual(Stats.dayRatio([r], "2026-11-10"), 1, accuracy: 0.001)
        XCTAssertEqual(Stats.dayRatio([r], "2026-11-20"), 0, accuracy: 0.001) // not due → not counted as missed
    }

    func testPausesAreSkippedNotMissed() {
        let pauses = HabitRules.parsePauses(["2026-11-05..2026-11-08", "bad"])
        XCTAssertEqual(pauses.count, 1)
        let r = HabitRules(schedule: .daily, n: 1, startKey: "2026-11-01",
                           done: ["2026-11-03", "2026-11-04", "2026-11-09", "2026-11-10"], pauses: pauses)
        XCTAssertFalse(r.isDue("2026-11-06"))
        XCTAssertEqual(r.streak("2026-11-10"), 4) // 10, 9, (5–8 paused), 4, 3
    }
}

final class FocusSessionStoreTests: XCTestCase {
    func testSnapshotRoundTripKeepsProgress() throws {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let t0 = Date().addingTimeInterval(-10 * 60)
        let timer = FocusTimer(title: "Deep work", pillar: 4, habitID: UUID(), work: 25, rest: 5, rounds: 2)
        timer.start(at: t0)
        FocusSessionStore.save(timer, defaults: defaults)

        let restored = try XCTUnwrap(FocusSessionStore.load(defaults: defaults))
        XCTAssertEqual(restored.snapshot, timer.snapshot)
        restored.tick(Date())
        XCTAssertEqual(restored.earnedMinutes, 10)
        XCTAssertTrue(restored.running)

        FocusSessionStore.clear(defaults: defaults)
        XCTAssertNil(FocusSessionStore.load(defaults: defaults))
    }

    func testRestoredSessionThatEndedMeanwhileIsFinished() throws {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let timer = FocusTimer(title: "Quick", pillar: 0, habitID: nil, work: 25, rest: 5, rounds: 1)
        timer.start(at: Date().addingTimeInterval(-40 * 60))
        FocusSessionStore.save(timer, defaults: defaults)
        let restored = try XCTUnwrap(FocusSessionStore.load(defaults: defaults))
        restored.tick(Date())
        XCTAssertTrue(restored.finished)
        XCTAssertTrue(restored.completed)
        XCTAssertEqual(restored.earnedMinutes, 25)
    }
}

final class AutoBackupTests: XCTestCase {
    func testDueWeeklyAndOnVersionChange() {
        let now = Date()
        XCTAssertTrue(AutoBackup.isDue(now: now, last: nil, lastVersion: nil, currentVersion: "1.3.0 (5)"))
        XCTAssertFalse(AutoBackup.isDue(now: now, last: now.addingTimeInterval(-3600), lastVersion: "1.3.0 (5)", currentVersion: "1.3.0 (5)"))
        XCTAssertTrue(AutoBackup.isDue(now: now, last: now.addingTimeInterval(-8 * 86400), lastVersion: "1.3.0 (5)", currentVersion: "1.3.0 (5)"))
        XCTAssertTrue(AutoBackup.isDue(now: now, last: now.addingTimeInterval(-3600), lastVersion: "1.2.0 (3)", currentVersion: "1.3.0 (5)"))
    }

    func testPruneKeepsNewest() {
        let names = (1...11).map { String(format: "drillside-2026-11-%02d-120000.json", $0) } + ["notes.txt", "other.json"]
        let prune = AutoBackup.filesToPrune(names, keep: 8)
        XCTAssertEqual(prune.count, 3)
        XCTAssertTrue(prune.contains("drillside-2026-11-01-120000.json"))
        XCTAssertFalse(prune.contains("drillside-2026-11-11-120000.json"))
        XCTAssertFalse(prune.contains("notes.txt"))
    }
}

final class MigrationTests: XCTestCase {
    /// A store written with the frozen v1.2.0 schema must open with the migration plan and keep its data.
    func testV1StoreMigratesToLatest() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("migration-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }
        do {
            let schema = Schema(versionedSchema: SchemaV1.self)
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
            let ctx = ModelContext(container)
            let habit = SchemaV1.Habit(name: "Old habit")
            habit.doneKeys = ["2026-11-01", "2026-11-02"]
            ctx.insert(habit)
            let profile = SchemaV1.Profile()
            profile.shells = 321
            ctx.insert(profile)
            ctx.insert(SchemaV1.LogEntry(dayKey: "2026-11-02"))
            try ctx.save()
        }
        let latest = Schema(versionedSchema: DrillsideSchemaLatest.self)
        let container = try ModelContainer(for: latest, migrationPlan: DrillsideMigrationPlan.self,
                                           configurations: [ModelConfiguration(schema: latest, url: url)])
        let ctx = ModelContext(container)
        let habits = try ctx.fetch(FetchDescriptor<Habit>())
        XCTAssertEqual(habits.count, 1)
        XCTAssertEqual(habits.first?.name, "Old habit")
        XCTAssertEqual(habits.first?.doneKeys.count, 2)
        XCTAssertEqual(habits.first?.archived, false)
        XCTAssertEqual(habits.first?.pauses, [])
        XCTAssertEqual(try ctx.fetch(FetchDescriptor<Profile>()).first?.shells, 321)
        XCTAssertEqual(try ctx.fetchCount(FetchDescriptor<LogEntry>()), 1)
    }
}


final class V14Tests: XCTestCase {
    func testV2StoreMigratesToLatest() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("migration2-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }
        do {
            let schema = Schema(versionedSchema: SchemaV2.self)
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
            let ctx = ModelContext(container)
            let habit = SchemaV2.Habit(name: "Archived reader")
            habit.archived = true
            habit.pauses = ["2026-11-01..2026-11-03"]
            ctx.insert(habit)
            let profile = SchemaV2.Profile()
            profile.skyMode = "night"
            ctx.insert(profile)
            try ctx.save()
        }
        let latest = Schema(versionedSchema: DrillsideSchemaLatest.self)
        let container = try ModelContainer(for: latest, migrationPlan: DrillsideMigrationPlan.self,
                                           configurations: [ModelConfiguration(schema: latest, url: url)])
        let ctx = ModelContext(container)
        let h = try XCTUnwrap(try ctx.fetch(FetchDescriptor<Habit>()).first)
        XCTAssertTrue(h.archived)
        XCTAssertEqual(h.pauses, ["2026-11-01..2026-11-03"])
        XCTAssertEqual(h.unit, "")
        XCTAssertEqual(h.amounts, [])
        let p = try XCTUnwrap(try ctx.fetch(FetchDescriptor<Profile>()).first)
        XCTAssertEqual(p.skyMode, "night")
        XCTAssertEqual(p.islandTheme, "classic")
        XCTAssertEqual(p.ownedThemes, ["classic"])
    }

    func testDayValues() {
        var list: [String] = []
        list = DayValues.set(list, "2026-11-20", "32")
        list = DayValues.set(list, "2026-11-21", "note with = sign")
        list = DayValues.set(list, "2026-11-20", "40")
        XCTAssertEqual(DayValues.get(list, "2026-11-20"), "40")
        XCTAssertEqual(DayValues.get(list, "2026-11-21"), "note with = sign")
        list = DayValues.set(list, "2026-11-20", nil)
        XCTAssertNil(DayValues.get(list, "2026-11-20"))
        XCTAssertEqual(list.count, 1)
    }

    func testAchievementsProgress() {
        var s = AchievementStats()
        s.focusMinutes = 650
        s.bestStreak = 7
        s.level = 10
        XCTAssertTrue(Achievement.focus10h.isMet(s))
        XCTAssertFalse(Achievement.focus100h.isMet(s))
        XCTAssertTrue(Achievement.streak7.isMet(s))
        XCTAssertEqual(Achievement.level10.reward, .prop(.rainbow))
        XCTAssertTrue(Achievement.allCases.allSatisfy { !$0.title.isEmpty && !$0.detail.isEmpty })
        for case .prop(let p) in Achievement.allCases.map(\.reward) { XCTAssertTrue(p.isExclusive) }
    }

    func testWeeklyReviewWeek() {
        XCTAssertEqual(WeeklyReview.weekStart(today: "2026-11-20"), "2026-11-16") // Friday → this week
        XCTAssertEqual(WeeklyReview.weekStart(today: "2026-11-18"), "2026-11-09") // Wednesday → last week
        XCTAssertEqual(WeeklyReview.days(today: "2026-11-18").count, 7)
        XCTAssertEqual(WeeklyReview.days(today: "2026-11-21").count, 6)
    }

    func testSeasonsAndThemes() {
        let cal = Calendar(identifier: .gregorian)
        let ams = TimeZone(identifier: "Europe/Amsterdam")!
        let syd = TimeZone(identifier: "Australia/Sydney")!
        let jan = cal.date(from: DateComponents(timeZone: ams, year: 2026, month: 1, day: 15, hour: 12))!
        XCTAssertEqual(Season.current(at: jan, timeZone: ams, calendar: cal), .winter)
        XCTAssertEqual(Season.current(at: jan, timeZone: syd, calendar: cal), .summer)
        XCTAssertEqual(IslandTheme.classic.price, 0)
        XCTAssertTrue(IslandTheme.allCases.dropFirst().allSatisfy { $0.price > 0 })
        XCTAssertFalse(PropCategory.shop.contains(.trophies))
    }

    func testSynthStaysInRange() {
        let synth = SoundSynth()
        for kind in FocusSound.allCases {
            synth.kind = kind
            synth.targetGain = 1
            synth.chimeT = 0
            for _ in 0..<20_000 {
                let v = synth.next()
                XCTAssertTrue(v.isFinite && v >= -1 && v <= 1)
            }
        }
    }
}
