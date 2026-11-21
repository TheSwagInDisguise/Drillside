import SwiftUI
import SwiftData

struct HabitEditor: View {
    let profile: Profile
    let habit: Habit?
    let habits: [Habit]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toasts

    @State private var name = ""
    @State private var pillar = 0
    @State private var kind: HabitKind = .habit
    @State private var minutes = 25
    @State private var schedule: ScheduleKind = .daily
    @State private var n = 3
    @State private var confirmDelete = false
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. Read 20 pages", text: $name)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .focused($nameFocused)
                        .submitLabel(.done)
                }
                Section("Pillar") {
                    Picker("Pillar", selection: $pillar) {
                        ForEach(0..<5, id: \.self) { i in
                            HStack {
                                PillarBadge(pillar: i, name: profile.pillarName(i), size: 22)
                                Text(profile.pillarName(i))
                            }
                            .tag(i)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section("Type") {
                    Picker("Type", selection: $kind) {
                        Text("✓ Habit").tag(HabitKind.habit)
                        Text("⏱ Focus block").tag(HabitKind.focus)
                    }
                    .pickerStyle(.segmented)
                    if kind == .focus {
                        StepperRow(title: "Block length", value: minutes, unit: "min", range: 5...180, step: 5) { minutes = $0 }
                    }
                }
                Section {
                    Picker("Schedule", selection: $schedule) {
                        ForEach(ScheduleKind.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    if schedule == .every {
                        StepperRow(title: "Repeat every", value: n, unit: "days", range: 2...14) { n = $0 }
                    } else if schedule == .week {
                        StepperRow(title: "Times per week", value: n, unit: "×", range: 1...6) { n = $0 }
                    }
                } header: {
                    Text("Schedule")
                } footer: {
                    Text(explanation)
                }
                if habit != nil {
                    Section {
                        Button("Archive (keep history)") {
                            if let h = habit {
                                Game.archive(h)
                                try? context.save()
                                toasts.show("📦 “\(h.name)” archived. History kept.")
                            }
                            dismiss()
                        }
                        .tint(.orange)
                        Button("Delete", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .navigationTitle(habit == nil ? (kind == .focus ? "New focus block" : "New habit") : "Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.heavy)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Delete this habit and all its history? Archive keeps the history instead.", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let h = habit {
                        context.delete(h)
                        try? context.save()
                        toasts.show("Habit deleted")
                    }
                    dismiss()
                }
            }
            .onChange(of: schedule) { _, s in
                n = s == .every ? max(2, min(14, n)) : max(1, min(6, n))
            }
            .onAppear(perform: load)
        }
    }

    private var explanation: String {
        switch schedule {
        case .daily: return "Due every day. The streak counts consecutive days."
        case .every: return "Due every \(n) days from the start date. Doing it early still counts."
        case .week: return "Flexible: any \(n) day\(n == 1 ? "" : "s") each week (Mon–Sun)."
        }
    }

    private func load() {
        guard let h = habit else {
            nameFocused = true
            return
        }
        name = h.name
        pillar = h.pillar
        kind = h.kind
        minutes = h.focusMinutes
        schedule = h.schedule
        n = h.schedule == .daily ? 3 : h.scheduleN
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let count = schedule == .daily ? 1 : n
        if let h = habit {
            if h.pillar != pillar { h.sortOrder = Game.nextSortOrder(pillar: pillar, habits: habits) }
            h.name = trimmed
            h.pillar = pillar
            h.kind = kind
            h.focusMinutes = minutes
            if schedule == .every && (h.schedule != .every || h.scheduleN != count) { h.startKey = Day.today }
            h.schedule = schedule
            h.scheduleN = count
            toasts.show("Saved")
        } else {
            context.insert(Habit(name: trimmed, pillar: pillar, kind: kind, focusMinutes: minutes, schedule: schedule, n: count,
                                 startKey: schedule == .every ? Day.today : Day.add(Day.today, -Day.retroWindow), sortOrder: Game.nextSortOrder(pillar: pillar, habits: habits)))
            toasts.show("Added to \(profile.pillarName(pillar))")
        }
        try? context.save()
        dismiss()
    }
}
