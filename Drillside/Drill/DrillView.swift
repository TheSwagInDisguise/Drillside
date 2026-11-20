import SwiftUI
import SwiftData

struct DrillView: View {
    @Bindable var profile: Profile
    @Environment(\.modelContext) private var context
    @Environment(Router.self) private var router
    @Environment(ToastCenter.self) private var toasts
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]

    @State private var selectedDay = Day.today
    @State private var editing: Habit?
    @State private var creating = false
    @State private var checkTick = 0

    private var today: String { Day.today }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    summary
                    dateStrip
                    if selectedDay != today {
                        Text("↩︎ **Retro check-off** for \(Day.long(selectedDay)). You can edit up to \(Day.retroWindow) days back.")
                            .font(.system(size: 13, design: .rounded))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                .listRowSeparator(.hidden)

                ForEach(0..<5, id: \.self) { pillar in
                    pillarSection(pillar)
                }

                Section {
                    Button {
                        creating = true
                    } label: {
                        Label("Add habit or focus block", systemImage: "plus")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity)
                    }
                } footer: {
                    Text("Tap a habit to start a focus timer · swipe for edit/delete · Edit to reorder")
                        .frame(maxWidth: .infinity)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Text(profile.acronym.map(String.init).joined(separator: "·")))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { router.showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
            }
            .sheet(item: $editing) { h in
                HabitEditor(profile: profile, habit: h, habits: habits)
            }
            .sheet(isPresented: $creating) {
                HabitEditor(profile: profile, habit: nil, habits: habits)
            }
            .sensoryFeedback(.success, trigger: checkTick)
            .onAppear { if !Day.canEdit(selectedDay) { selectedDay = today } }
        }
    }

    // MARK: Header

    private var summary: some View {
        let due = habits.filter { $0.rules.meta(selectedDay).due }
        let done = due.filter { $0.isDone(selectedDay) }.count
        let pct = due.isEmpty ? 0 : Double(done) / Double(due.count)
        return Card {
            HStack(spacing: 14) {
                ZStack {
                    ProgressRing(progress: pct, color: Theme.good)
                    Text("\(Int((pct * 100).rounded()))%").font(.system(size: 14, weight: .black, design: .rounded))
                }
                .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(done) of \(due.count) done").font(.system(size: 16, weight: .heavy, design: .rounded))
                    + Text(selectedDay == today ? "  today" : "  \(Day.short(selectedDay))").font(.system(size: 14)).foregroundColor(.secondary)
                    Text("+\(Economy.habitXP) XP +\(Economy.habitShells) 🐚 per check · focus pays 1/min")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var dateStrip: some View {
        HStack(spacing: 6) {
            ForEach(-6...0, id: \.self) { offset in
                let key = Day.add(today, offset)
                let locked = !Day.canEdit(key)
                let on = key == selectedDay
                let due = habits.filter { $0.rules.meta(key).due }
                let doneCount = due.filter { $0.isDone(key) }.count
                Button {
                    selectedDay = key
                } label: {
                    VStack(spacing: 2) {
                        Text(offset == 0 ? "Today" : Day.weekday(key))
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .textCase(.uppercase)
                            .opacity(on ? 0.75 : 1)
                            .foregroundStyle(on ? AnyShapeStyle(.background) : AnyShapeStyle(.secondary))
                        Text("\(Day.dayOfMonth(key))").font(.system(size: 16, weight: .heavy, design: .rounded))
                        if locked {
                            Image(systemName: "lock.fill").font(.system(size: 8))
                        } else {
                            Circle()
                                .fill(due.isEmpty || doneCount == 0 ? Color.clear : (doneCount == due.count ? Theme.good : Theme.accent))
                                .frame(width: 5, height: 5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .foregroundStyle(on ? AnyShapeStyle(.background) : AnyShapeStyle(.primary))
                    .background(on ? AnyShapeStyle(.primary) : AnyShapeStyle(Color(.secondarySystemGroupedBackground)),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(locked)
                .opacity(locked ? 0.45 : 1)
                .accessibilityLabel(locked ? "\(Day.long(key)), locked" : Day.long(key))
            }
        }
    }

    // MARK: Pillars

    @ViewBuilder
    private func pillarSection(_ pillar: Int) -> some View {
        let items = habits.filter { $0.pillar == pillar }
        let due = items.filter { $0.rules.meta(selectedDay).due }
        let doneCount = due.filter { $0.isDone(selectedDay) }.count
        Section {
            if items.isEmpty {
                Text("Nothing here yet. Add a habit below.").font(.footnote).foregroundStyle(.secondary)
            }
            ForEach(items) { h in
                HabitRow(habit: h, day: selectedDay, pillar: pillar,
                         onToggle: { toggle(h) },
                         onFocus: { startTimer(h) })
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { delete(h) } label: { Label("Delete", systemImage: "trash") }
                    Button { editing = h } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                }
                .contextMenu {
                    Button { editing = h } label: { Label("Edit", systemImage: "pencil") }
                    Button { startTimer(h) } label: { Label("Start focus timer", systemImage: "timer") }
                    Button(role: .destructive) { delete(h) } label: { Label("Delete", systemImage: "trash") }
                }
            }
            .onMove { from, to in
                var arr = items
                arr.move(fromOffsets: from, toOffset: to)
                Game.reorder(arr)
                try? context.save()
            }
        } header: {
            HStack(spacing: 10) {
                PillarBadge(pillar: pillar, name: profile.pillarName(pillar))
                VStack(alignment: .leading, spacing: 0) {
                    Text(profile.pillarName(pillar)).font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(.primary)
                    Text(profile.pillarHint(pillar)).font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer()
                Chip(text: "\(doneCount)/\(due.count)")
            }
            .textCase(nil)
            .padding(.bottom, 4)
        }
    }

    // MARK: Actions

    private func toggle(_ h: Habit) {
        let wasDone = h.isDone(selectedDay)
        let out = Game.toggle(h, day: selectedDay, profile: profile)
        if !out.ok, let m = out.message { toasts.show(m); return }
        try? context.save()
        if !wasDone {
            checkTick += 1
            if out.levelsGained > 0 {
                toasts.levelUp(out.levelsGained, level: profile.level) { router.tab = .shop }
            }
            let due = habits.filter { $0.rules.meta(selectedDay).due }
            if !due.isEmpty && due.allSatisfy({ $0.isDone(selectedDay) }) {
                toasts.show("🏝️ Every due habit done\(selectedDay == today ? " today" : "")! Bitsy is proud.")
            }
        }
    }

    private func startTimer(_ h: Habit) {
        let isBlock = h.kind == .focus
        router.timer = FocusTimer(title: h.name, pillar: h.pillar, habitID: h.id,
                                  work: isBlock ? h.focusMinutes : profile.workMinutes,
                                  rest: profile.breakMinutes, rounds: isBlock ? 1 : profile.rounds)
    }

    private func delete(_ h: Habit) {
        context.delete(h)
        try? context.save()
        toasts.show("Habit deleted")
    }
}

struct HabitRow: View {
    let habit: Habit
    let day: String
    let pillar: Int
    var onToggle: () -> Void
    var onFocus: () -> Void

    var body: some View {
        let meta = habit.rules.meta(day)
        let done = habit.isDone(day)
        let rest = !meta.due && !done
        let color = Pillars.color(pillar)
        HStack(spacing: 10) {
            Button(action: onToggle) {
                ZStack {
                    Circle().stroke(color, lineWidth: 2.5)
                    if done {
                        Circle().fill(color)
                        Image(systemName: "checkmark").font(.system(size: 13, weight: .black)).foregroundStyle(.white)
                    }
                }
                .frame(width: 30, height: 30)
                .contentShape(Circle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(done ? "Mark \(habit.name) not done" : "Mark \(habit.name) done")

            Button(action: onFocus) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(habit.name)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .strikethrough(done)
                            .foregroundStyle(done ? .secondary : .primary)
                            .lineLimit(1)
                        Text(subtitle(meta, done: done))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 4)
                    HStack(spacing: 3) {
                        Image(systemName: "play.fill").font(.system(size: 10))
                        if habit.kind == .focus { Text("\(habit.focusMinutes)m") }
                    }
                    .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                    .background(color.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityHint("Starts a focus timer")
        }
        .opacity(rest ? 0.55 : 1)
        .animation(.spring(duration: 0.25), value: done)
    }

    private func subtitle(_ m: HabitMeta, done: Bool) -> String {
        var s = m.label
        switch habit.schedule {
        case .week:
            s += " · \(m.weekDone)/\(m.weekTarget) this week"
        case .every:
            if m.streak > 0 { s += " · 🔥 \(m.streak)" }
            if !m.due && !done { s += " · next in \(m.nextInDays)d" }
        case .daily:
            if m.streak > 0 { s += " · 🔥 \(m.streak)" }
        }
        return s
    }
}
