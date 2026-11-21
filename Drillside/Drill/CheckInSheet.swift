import SwiftUI
import SwiftData

/// Quick sheet for logging an amount ("32 pages") and/or a note for one habit on one day.
struct CheckInSheet: View {
    let habit: Habit
    let day: String
    let profile: Profile
    var onDone: (Game.Outcome?) -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""
    @State private var note = ""
    @FocusState private var focused: Bool

    private var amount: Int? { Int(amountText.trimmingCharacters(in: .whitespaces)) }

    var body: some View {
        NavigationStack {
            Form {
                if habit.tracksAmount {
                    Section {
                        HStack {
                            TextField("0", text: $amountText)
                                .keyboardType(.numberPad)
                                .font(.system(size: 34, weight: .heavy, design: .rounded))
                                .focused($focused)
                            Text(habit.unit).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
                        }
                        if habit.target > 0 {
                            let value = amount ?? 0
                            ProgressView(value: Double(min(value, habit.target)), total: Double(habit.target))
                                .tint(value >= habit.target ? Theme.good : Pillars.color(habit.pillar))
                            Text(value >= habit.target ? "🎯 Target of \(habit.target) \(habit.unit) reached"
                                                       : "Target: \(habit.target) \(habit.unit)")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        HStack(spacing: 8) {
                            ForEach(quickPicks, id: \.self) { v in
                                Button("\(v)") { amountText = "\(v)" }
                                    .buttonStyle(.bordered)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                        }
                    } header: {
                        Text("How many \(habit.unit)?")
                    }
                }
                Section {
                    TextField("Optional note: how it went, what helped…", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                } header: {
                    Text("Note")
                }
                if habit.isDone(day) {
                    Section {
                        Button("Mark as not done", role: .destructive) {
                            Game.uncheck(habit, day: day, profile: profile)
                            try? context.save()
                            onDone(nil)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(habit.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(habit.isDone(day) ? "Save" : "Check off") {
                        let out = Game.checkIn(habit, day: day, amount: amount, note: note, profile: profile)
                        try? context.save()
                        onDone(out)
                        dismiss()
                    }
                    .fontWeight(.heavy)
                }
            }
            .onAppear {
                if let a = habit.amount(on: day) { amountText = "\(a)" } else if habit.target > 0 { amountText = "\(habit.target)" }
                note = habit.note(on: day) ?? ""
                focused = habit.tracksAmount
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var quickPicks: [Int] {
        let t = max(1, habit.target)
        return Array(Set([max(1, t / 2), t, t + t / 2, t * 2])).sorted()
    }
}
