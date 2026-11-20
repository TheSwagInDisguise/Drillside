import SwiftUI
import SwiftData
import Charts

struct LogView: View {
    @Bindable var profile: Profile
    @Environment(\.modelContext) private var context
    @Environment(Router.self) private var router
    @Environment(ToastCenter.self) private var toasts
    @Query(sort: \LogEntry.dayKey, order: .reverse) private var logs: [LogEntry]
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query private var sessions: [FocusSession]

    enum Mode: String, CaseIterable, Identifiable { case timeline = "Timeline", heatmap = "Heatmap", trends = "Trends"; var id: String { rawValue } }

    @AppStorage("log.mode") private var mode: Mode = .timeline
    @State private var well = ""
    @State private var wrong = ""
    @State private var fix = ""
    @State private var editingToday = false
    @State private var savedTick = 0
    @FocusState private var focused: Field?

    enum Field { case well, wrong, fix }

    private var today: String { Day.today }
    private var todayEntry: LogEntry? { logs.first { $0.dayKey == today } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if todayEntry == nil || editingToday { checkInForm } else { checkInSummary }

                    Picker("View", selection: $mode) {
                        ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 4)

                    switch mode {
                    case .timeline: TimelineList(logs: Array(logs.prefix(30)), rules: rules, focusByDay: focusByDay)
                    case .heatmap: HeatmapView(rules: rules, focusByDay: focusByDay, logs: logs, habits: habits)
                    case .trends: TrendsView(profile: profile, habits: habits, focusByDay: focusByDay, logs: logs)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Log")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Chip(text: "🔥 \(logStreak)-day streak")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focused = nil }
                }
            }
            .sensoryFeedback(.success, trigger: savedTick)
        }
    }

    private var rules: [HabitRules] { habits.map(\.rules) }

    private var focusByDay: [String: Int] {
        var d: [String: Int] = [:]
        for s in sessions { d[s.dayKey, default: 0] += s.minutes }
        return d
    }

    private var logStreak: Int {
        let keys = Set(logs.map(\.dayKey))
        var k = keys.contains(today) ? today : Day.add(today, -1)
        var n = 0
        while keys.contains(k) {
            n += 1
            k = Day.add(k, -1)
        }
        return n
    }

    // MARK: Check-in

    private var checkInForm: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DAILY CHECK-IN").font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(.secondary)
                        Text(Day.long(today)).font(.system(size: 17, weight: .heavy, design: .rounded))
                    }
                    Spacer()
                    Chip(text: "~60 sec")
                }
                prompt("✅ What went well", color: Theme.good, text: $well, placeholder: "Wins & momentum, e.g. shipped the fix before lunch", field: .well, multiline: true)
                prompt("⚠️ What went wrong", color: Theme.bad, text: $wrong, placeholder: "Friction & blockers, e.g. doom-scrolled after 9pm", field: .wrong, multiline: true)
                prompt("🔧 One-line fix for tomorrow", color: .primary, text: $fix, placeholder: "e.g. Phone charges in the kitchen from 9pm", field: .fix, multiline: false)
                    .padding(.leading, 14)
                    .overlay(alignment: .leading) { Rectangle().fill(Color(.separator)).frame(width: 3) }
                HStack {
                    Text(todayEntry == nil ? "+\(Economy.logXP) XP · +\(Economy.logShells) 🐚 for checking in" : "Editing today’s entry")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                    Spacer()
                    if editingToday {
                        Button("Cancel") { editingToday = false }.buttonStyle(.bordered)
                    }
                    Button(todayEntry == nil ? "Save check-in" : "Update", action: save)
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.accent)
                        .fontWeight(.heavy)
                }
            }
        }
    }

    private func prompt(_ title: String, color: Color, text: Binding<String>, placeholder: String, field: Field, multiline: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 13, weight: .heavy, design: .rounded)).foregroundStyle(color)
            Group {
                if multiline {
                    TextField(placeholder, text: text, axis: .vertical).lineLimit(2...5)
                } else {
                    TextField(placeholder, text: text)
                }
            }
            .focused($focused, equals: field)
            .font(.system(size: 15))
            .padding(10)
            .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var checkInSummary: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TODAY · CHECKED IN ✓").font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(.secondary)
                        Text(Day.long(today)).font(.system(size: 17, weight: .heavy, design: .rounded))
                    }
                    Spacer()
                    Button("Edit") {
                        if let e = todayEntry {
                            well = e.well
                            wrong = e.wrong
                            fix = e.fix
                        }
                        editingToday = true
                    }
                    .fontWeight(.bold)
                    .tint(Theme.accent)
                }
                if let e = todayEntry {
                    if !e.well.isEmpty { Text("✅ \(e.well)") }
                    if !e.wrong.isEmpty { Text("⚠️ \(e.wrong)") }
                    if !e.fix.isEmpty { Text("🔧 \(e.fix)").foregroundStyle(.secondary) }
                }
            }
            .font(.system(size: 15))
        }
    }

    private func save() {
        let out = Game.saveLog(day: today, well: well, wrong: wrong, fix: fix, existing: todayEntry, profile: profile, context: context)
        if let m = out.message { toasts.show(m) }
        guard out.ok else { return }
        focused = nil
        well = ""
        wrong = ""
        fix = ""
        editingToday = false
        savedTick += 1
        if out.levelsGained > 0 { toasts.levelUp(out.levelsGained, level: profile.level) { router.tab = .shop } }
    }
}

// MARK: - Timeline

private struct TimelineList: View {
    let logs: [LogEntry]
    let rules: [HabitRules]
    let focusByDay: [String: Int]

    var body: some View {
        if logs.isEmpty {
            ContentUnavailableView("No check-ins yet", systemImage: "book.closed",
                                   description: Text("Log one win and one snag each day. Patterns show up here."))
        } else {
            LazyVStack(spacing: 10) {
                ForEach(Array(logs.enumerated()), id: \.element.dayKey) { idx, entry in
                    if idx > 0 {
                        let gap = Day.between(entry.dayKey, logs[idx - 1].dayKey) - 1
                        if gap > 0 {
                            Text("· \(gap) day\(gap == 1 ? "" : "s") without a check-in ·")
                                .font(.system(size: 12)).foregroundStyle(.secondary)
                        }
                    }
                    row(entry)
                }
            }
        }
    }

    private func row(_ e: LogEntry) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 0) {
                Text("\(Day.dayOfMonth(e.dayKey))").font(.system(size: 19, weight: .heavy, design: .rounded))
                Text(Day.weekday(e.dayKey)).font(.system(size: 11, weight: .heavy)).textCase(.uppercase).foregroundStyle(.secondary)
            }
            .frame(width: 38)
            .padding(.top, 8)
            Card(padding: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Chip(text: "✓ \(Int((Stats.dayRatio(rules, e.dayKey) * 100).rounded()))% habits")
                        Chip(text: "⏱ \(focusByDay[e.dayKey] ?? 0)m focus")
                        if !e.tag.isEmpty { Chip(text: e.tag) }
                    }
                    if !e.well.isEmpty { Text("✅ \(e.well)") }
                    if !e.wrong.isEmpty { Text("⚠️ \(e.wrong)") }
                    if !e.fix.isEmpty { Text("🔧 \(e.fix)").foregroundStyle(.secondary) }
                }
                .font(.system(size: 14))
            }
        }
    }
}

// MARK: - Heatmap

private struct HeatmapView: View {
    let rules: [HabitRules]
    let focusByDay: [String: Int]
    let logs: [LogEntry]
    let habits: [Habit]

    @AppStorage("log.heatMetric") private var metric = "habits"
    @State private var selected: String?

    private let weeks = 13
    private let cell: CGFloat = 19
    private let gap: CGFloat = 4

    private var today: String { Day.today }
    private var firstDay: String { Day.add(Day.weekStart(today), -(weeks - 1) * 7) }

    var body: some View {
        VStack(spacing: 12) {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Consistency").font(.system(size: 15, weight: .heavy, design: .rounded))
                        Spacer()
                        Picker("Metric", selection: $metric) {
                            Text("Habits").tag("habits")
                            Text("Focus").tag("focus")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 150)
                    }
                    grid
                    legend
                    detail
                }
            }
            stats
        }
    }

    private var grid: some View {
        HStack(alignment: .top, spacing: 6) {
            VStack(spacing: gap) {
                Color.clear.frame(height: 14)
                ForEach(0..<7, id: \.self) { i in
                    Text(["M", "", "W", "", "F", "", "S"][i])
                        .font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary)
                        .frame(height: cell)
                }
            }
            HStack(alignment: .top, spacing: gap) {
                ForEach(0..<weeks, id: \.self) { w in
                    let weekKey = Day.add(firstDay, w * 7)
                    let prevMonth = w == 0 ? -1 : Day.month(Day.add(firstDay, (w - 1) * 7))
                    VStack(spacing: gap) {
                        Text(Day.month(weekKey) != prevMonth ? Day.monthName(weekKey) : "")
                            .font(.system(size: 9.5, weight: .bold)).foregroundStyle(.secondary)
                            .fixedSize()
                            .frame(width: cell, height: 14, alignment: .leading)
                        ForEach(0..<7, id: \.self) { d in
                            dayCell(Day.add(weekKey, d))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func dayCell(_ key: String) -> some View {
        let future = Day.between(today, key) > 0
        let level = future ? 0 : (metric == "habits" ? Stats.heatLevel(ratio: Stats.dayRatio(rules, key))
                                                    : Stats.heatLevel(focusMinutes: focusByDay[key] ?? 0))
        RoundedRectangle(cornerRadius: 5)
            .fill(color(level))
            .frame(width: cell, height: cell)
            .opacity(future ? 0.25 : 1)
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(key == selected ? Theme.accent : (key == today ? Color.primary : .clear), lineWidth: 2).padding(-1.5))
            .onTapGesture { if !future { selected = key } }
            .accessibilityLabel(Day.long(key))
    }

    private func color(_ level: Int) -> Color {
        let habitsRamp: [Color] = [Color(.tertiarySystemFill), Color(hex: 0xBFE5CC), Color(hex: 0x7FCB9C), Color(hex: 0x3FAE70), Color(hex: 0x1E8550)]
        let focusRamp: [Color] = [Color(.tertiarySystemFill), Color(hex: 0xFFD9BD), Color(hex: 0xFFB27E), Color(hex: 0xFF8A3D), Color(hex: 0xD9601A)]
        return (metric == "habits" ? habitsRamp : focusRamp)[max(0, min(4, level))]
    }

    private var legend: some View {
        HStack(spacing: 4) {
            Spacer()
            Text("Less").font(.system(size: 11)).foregroundStyle(.secondary)
            ForEach(0..<5, id: \.self) { RoundedRectangle(cornerRadius: 3).fill(color($0)).frame(width: 12, height: 12) }
            Text("More").font(.system(size: 11)).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var detail: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let k = selected {
                let done = habits.filter { $0.isDone(k) }.map(\.name)
                Text("**\(Day.long(k))** · \(Int((Stats.dayRatio(rules, k) * 100).rounded()))% habits · \(focusByDay[k] ?? 0)m focus")
                Text(done.isEmpty ? "No habits checked" : "✓ " + done.prefix(4).joined(separator: ", ") + (done.count > 4 ? " +\(done.count - 4)" : ""))
                    .foregroundStyle(.secondary)
                if let e = logs.first(where: { $0.dayKey == k }) {
                    if !e.well.isEmpty { Text("✅ \(e.well)") }
                    if !e.wrong.isEmpty { Text("⚠️ \(e.wrong)") }
                }
            } else {
                Text("Tap a day to see habits, focus and that day’s retro.").foregroundStyle(.secondary)
            }
        }
        .font(.system(size: 13.5))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12))
    }

    private var stats: some View {
        let last30 = (1...30).map { Day.add(today, -$0) }
        let avg = last30.map { Stats.dayRatio(rules, $0) }.reduce(0, +) / 30
        let focus = (0..<30).map { focusByDay[Day.add(today, -$0)] ?? 0 }.reduce(0, +)
        let best = rules.filter { $0.schedule != .week }.map { $0.streak(today) }.max() ?? 0
        let checkins = logs.filter { Day.between($0.dayKey, today) < 30 }.count
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            statTile("\(Int((avg * 100).rounded()))%", "Habit completion · 30d")
            statTile(String(format: "%.1fh", Double(focus) / 60), "Focus · 30d")
            statTile("\(best)", "Best active streak")
            statTile("\(checkins)/30", "Check-ins · 30d")
        }
    }

    private func statTile(_ value: String, _ label: String) -> some View {
        Card(padding: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.system(size: 22, weight: .black, design: .rounded))
                Text(label).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Trends

private struct TrendsView: View {
    let profile: Profile
    let habits: [Habit]
    let focusByDay: [String: Int]
    let logs: [LogEntry]

    struct DayValue: Identifiable { let key: String; let minutes: Int; var id: String { key } }
    struct HabitRate: Identifiable { let habit: Habit; let rate: Double; var id: UUID { habit.id } }
    struct PillarRate: Identifiable { let pillar: Int; let rate: Double; var id: Int { pillar } }
    struct TagCount: Identifiable { let tag: String; let count: Int; var id: String { tag } }

    private var today: String { Day.today }

    var body: some View {
        let days = (0..<14).map { DayValue(key: Day.add(today, $0 - 13), minutes: focusByDay[Day.add(today, $0 - 13)] ?? 0) }
        let avg = Double(days.map(\.minutes).reduce(0, +)) / 14
        let rates = habits.map { HabitRate(habit: $0, rate: $0.rules.rate30(today: today)) }.sorted { $0.rate < $1.rate }
        let pillars = (0..<5).map { p -> PillarRate in
            let rs = rates.filter { $0.habit.pillar == p }
            return PillarRate(pillar: p, rate: rs.isEmpty ? 0 : rs.map(\.rate).reduce(0, +) / Double(rs.count))
        }
        var counts: [String: Int] = [:]
        for l in logs where !l.tag.isEmpty { counts[l.tag, default: 0] += 1 }
        let tags = counts.map { TagCount(tag: $0.key, count: $0.value) }.sorted { $0.count > $1.count }

        return VStack(spacing: 12) {
            Card {
                VStack(alignment: .leading, spacing: 8) {
                    header("Focus minutes", "avg \(Int(avg.rounded()))/day · last 14 days")
                    Chart {
                        ForEach(days) { d in
                            BarMark(x: .value("Day", Day.date(d.key), unit: .day), y: .value("Minutes", d.minutes))
                                .foregroundStyle(d.key == today ? Theme.accent : Color(.systemGray4))
                                .cornerRadius(4)
                        }
                        RuleMark(y: .value("Average", avg))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                            .foregroundStyle(.secondary)
                            .annotation(position: .top, alignment: .trailing) {
                                Text("avg").font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary)
                            }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                            AxisValueLabel(format: .dateTime.day(), centered: true)
                        }
                    }
                    .frame(height: 150)
                }
            }

            Card {
                VStack(alignment: .leading, spacing: 4) {
                    header("Weak habits", "30-day completion")
                    if rates.isEmpty {
                        Text("Add habits to see trends.").foregroundStyle(.secondary)
                    }
                    ForEach(Array(rates.prefix(3).enumerated()), id: \.element.id) { i, r in
                        weakRow(r, tip: ["Shrink it: make a 2-minute version", "Stack it right after a strong habit", "Move it to your best-energy hour"][i])
                        if i < min(2, rates.count - 1) { Divider() }
                    }
                }
            }

            Card {
                VStack(alignment: .leading, spacing: 8) {
                    header("Pillar balance", "avg completion")
                    Chart(pillars) { p in
                        BarMark(x: .value("Pillar", "\(p.pillar)"), y: .value("Rate", p.rate * 100))
                            .foregroundStyle(Pillars.color(p.pillar))
                            .cornerRadius(6)
                            .annotation(position: .top) {
                                Text("\(Int((p.rate * 100).rounded()))%").font(.system(size: 11, weight: .heavy)).foregroundStyle(.secondary)
                            }
                    }
                    .chartYScale(domain: 0...110)
                    .chartYAxis(.hidden)
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let s = value.as(String.self), let i = Int(s) {
                                    Text(Pillars.letter(profile.pillarName(i))).font(.system(size: 12, weight: .heavy))
                                }
                            }
                        }
                    }
                    .frame(height: 140)
                }
            }

            Card {
                VStack(alignment: .leading, spacing: 8) {
                    header("Recurring friction", "from “What went wrong”")
                    if tags.isEmpty {
                        Text("Nothing yet. Patterns appear after a few check-ins.").font(.footnote).foregroundStyle(.secondary)
                    } else {
                        FlowLayout {
                            ForEach(tags) { Chip(text: "\($0.tag) ×\($0.count)") }
                        }
                    }
                }
            }
        }
    }

    private func header(_ title: String, _ sub: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.system(size: 15, weight: .heavy, design: .rounded))
            Spacer()
            Text(sub).font(.system(size: 12)).foregroundStyle(.secondary)
        }
    }

    private func weakRow(_ r: HabitRate, tip: String) -> some View {
        HStack(spacing: 10) {
            Circle().fill(Pillars.color(r.habit.pillar)).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 3) {
                Text(r.habit.name).font(.system(size: 14, weight: .bold, design: .rounded)).lineLimit(1)
                Text("💡 \(tip)").font(.system(size: 11.5)).foregroundStyle(.secondary)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.tertiarySystemFill))
                        Capsule().fill(Pillars.color(r.habit.pillar)).frame(width: g.size.width * r.rate)
                    }
                }
                .frame(height: 6)
            }
            Text("\(Int((r.rate * 100).rounded()))%").font(.system(size: 14, weight: .black, design: .rounded)).frame(width: 44, alignment: .trailing)
        }
        .padding(.vertical, 6)
    }
}
