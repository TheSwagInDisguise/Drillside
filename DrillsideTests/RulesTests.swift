import XCTest
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
        XCTAssertGreaterThanOrEqual(PropType.allCases.count, 35)
        XCTAssertEqual(Set(PropType.allCases.map(\.name)).count, PropType.allCases.count, "names must be unique")
        for p in PropType.allCases {
            XCTAssertGreaterThan(p.price, 0)
            XCTAssertGreaterThanOrEqual(p.unlockLevel, 1)
            if p.isWalkable { XCTAssertTrue(p.isFlat) }
        }
        XCTAssertFalse(PropType.pond.isWalkable)
        XCTAssertTrue(PropType.path.isWalkable)
        XCTAssertEqual(CompanionType.allCases.count, 6)
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
