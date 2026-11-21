import SwiftUI
import SwiftData

enum WeeklyReview {
    static let xp = 25
    static let shells = 15

    /// The week being reviewed: from Friday on it's the current week, earlier in the week it's last week.
    static func weekStart(today: String = Day.today) -> String {
        let thisWeek = Day.weekStart(today)
        return Day.weekdayIndexMondayFirst(today) >= 4 ? thisWeek : Day.add(thisWeek, -7)
    }

    /// Days of the reviewed week up to today.
    static func days(today: String = Day.today) -> [String] {
        let start = weekStart(today: today)
        return (0..<7).map { Day.add(start, $0) }.filter { Day.between($0, today) >= 0 }
    }
}

struct WeeklyReviewView: View {
    @Bindable var profile: Profile
    let habits: [Habit]
    let sessions: [FocusSession]
    let logs: [LogEntry]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toasts
    @State private var focus = ""

    private var weekStart: String { WeeklyReview.weekStart() }
    private var days: [String] { WeeklyReview.days() }
    private var alreadyDone: Bool { profile.reviewWeeks.contains(weekStart) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    statGrid
                } header: {
                    Text("\(Day.short(weekStart)) – \(Day.short(Day.add(weekStart, 6)))")
                }

                Section("Pillars") {
                    ForEach(0..<5, id: \.self) { p in
                        let r = pillarRate(p)
                        HStack {
                            PillarBadge(pillar: p, name: profile.pillarName(p), size: 24)
                            Text(profile.pillarName(p)).font(.system(size: 15, weight: .semibold, design: .rounded))
                            Spacer()
                            Text(r.map { "\(Int(($0 * 100).rounded()))%" } ?? "–")
                                .font(.system(size: 14, weight: .heavy, design: .rounded))
                                .foregroundStyle(r.map { $0 >= 0.8 ? Theme.good : ($0 < 0.5 ? Theme.bad : .primary) } ?? .secondary)
                        }
                    }
                }

                let wins = logs.filter { days.contains($0.dayKey) && !$0.well.isEmpty }.sorted { $0.dayKey < $1.dayKey }
                if !wins.isEmpty {
                    Section("Wins") {
                        ForEach(wins, id: \.dayKey) { e in
                            Text("✅ \(e.well)").font(.system(size: 14))
                        }
                    }
                }

                let fixes = logs.filter { days.contains($0.dayKey) && !$0.fix.isEmpty }
                if let tag = topFriction {
                    Section {
                        Text("Most common friction: **\(tag.0)** (\(tag.1)×)")
                        ForEach(fixes, id: \.dayKey) { e in
                            Text("🔧 \(e.fix)").font(.system(size: 14)).foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Friction")
                    }
                }

                let amountHabits = habits.filter { $0.tracksAmount && !$0.archived }
                if !amountHabits.isEmpty {
                    Section("Totals") {
                        ForEach(amountHabits) { h in
                            let total = days.reduce(0) { $0 + (h.amount(on: $1) ?? 0) }
                            LabeledContent(h.name, value: "\(total) \(h.unit)")
                        }
                    }
                }

                Section {
                    TextField("e.g. Finish chapter 4 before noon every day", text: $focus, axis: .vertical)
                        .lineLimit(1...3)
                } header: {
                    Text("🎯 One focus for next week")
                } footer: {
                    Text("Shown at the top of DRILL all week.")
                }
            }
            .navigationTitle("Weekly review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(alreadyDone ? "Update" : "Finish") { finish() }.fontWeight(.heavy)
                }
            }
            .onAppear { focus = profile.weeklyFocus }
        }
    }

    private var statGrid: some View {
        let rules = habits.map(\.rules)
        let ratio = days.isEmpty ? 0 : days.map { Stats.dayRatio(rules, $0) }.reduce(0, +) / Double(days.count)
        let minutes = sessions.filter { days.contains($0.dayKey) }.reduce(0) { $0 + $1.minutes }
        let checkIns = logs.filter { days.contains($0.dayKey) }.count
        let checkOffs = habits.reduce(0) { acc, h in acc + days.filter { h.isDone($0) }.count }
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            tile("\(Int((ratio * 100).rounded()))%", "Habit completion")
            tile(String(format: "%.1fh", Double(minutes) / 60), "Focus")
            tile("\(checkOffs)", "Check-offs")
            tile("\(checkIns)/\(days.count)", "Daily check-ins")
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }

    private func tile(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 22, weight: .black, design: .rounded))
            Text(label).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    private func pillarRate(_ p: Int) -> Double? {
        var due = 0, done = 0
        for h in habits where h.pillar == p {
            let r = h.rules
            for d in days where r.isDue(d) && r.schedule != .week {
                due += 1
                if r.isDone(d) { done += 1 }
            }
            if r.schedule == .week {
                due += r.interval
                done += min(r.interval, days.filter { r.isDone($0) }.count)
            }
        }
        return due == 0 ? nil : Double(done) / Double(due)
    }

    private var topFriction: (String, Int)? {
        var counts: [String: Int] = [:]
        for l in logs where days.contains(l.dayKey) && !l.tag.isEmpty { counts[l.tag, default: 0] += 1 }
        return counts.max { $0.value < $1.value }.map { ($0.key, $0.value) }
    }

    private func finish() {
        profile.weeklyFocus = focus.trimmingCharacters(in: .whitespacesAndNewlines)
        if !alreadyDone {
            profile.reviewWeeks.append(weekStart)
            let lv = profile.award(xp: WeeklyReview.xp, shells: WeeklyReview.shells)
            toasts.show("🧭 Week reviewed! +\(WeeklyReview.xp) XP · +\(WeeklyReview.shells) 🐚")
            if lv > 0 { toasts.show("🎉 Level \(profile.level)!") }
        } else {
            toasts.show("Weekly focus updated")
        }
        try? context.save()
        dismiss()
    }
}
