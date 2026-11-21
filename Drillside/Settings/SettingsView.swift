import SwiftUI
import SwiftData

struct SettingsView: View {
    @Bindable var profile: Profile
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toasts

    @State private var exportDoc: BackupDocument?
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var confirmReset = false
    @State private var pendingImport: Data?

    var body: some View {
        NavigationStack {
            Form {
                pillarsSection
                timerSection
                reminderSection
                Section("Appearance") {
                    Picker("Theme", selection: $profile.theme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }
                backupSection
                Section {
                    LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                } footer: {
                    Text("Drillside is 100% local: no account, no network, no iCloud, no ads, no subscriptions.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        try? context.save()
                        dismiss()
                    }
                    .fontWeight(.heavy)
                }
            }
            .fileExporter(isPresented: $showExporter, document: exportDoc, contentType: .json,
                          defaultFilename: "drillside-backup-\(Day.today)") { result in
                switch result {
                case .success: toasts.show("📦 Backup exported")
                case .failure(let e): toasts.show("Export failed: \(e.localizedDescription)")
                }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    if let data = try? Data(contentsOf: url) { pendingImport = data } else { toasts.show("Couldn’t read that file") }
                case .failure(let e):
                    toasts.show("Import failed: \(e.localizedDescription)")
                }
            }
            .confirmationDialog("Replace all data with this backup?", isPresented: Binding(get: { pendingImport != nil }, set: { if !$0 { pendingImport = nil } }),
                                titleVisibility: .visible) {
                Button("Replace everything", role: .destructive) {
                    guard let data = pendingImport else { return }
                    pendingImport = nil
                    guard (try? BackupFile.decoder.decode(BackupFile.self, from: data)) != nil else {
                        toasts.show("That file isn’t a Drillside backup")
                        return
                    }
                    // Close the sheet before swapping out the data it is bound to.
                    let ctx = context
                    let toastCenter = toasts
                    dismiss()
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 450_000_000)
                        do {
                            try BackupService.restore(data, context: ctx)
                            toastCenter.show("✅ Backup imported")
                        } catch {
                            toastCenter.show("Import failed: \(error.localizedDescription)")
                        }
                    }
                }
            } message: {
                Text("Your current habits, logs, island and progress will be overwritten.")
            }
            .confirmationDialog("Erase all Drillside data?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive) {
                    Notifier.cancelDailyReminder()
                    let ctx = context
                    dismiss()
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 450_000_000)
                        Seeder.eraseEverything(ctx)
                    }
                }
            } message: {
                Text("This can’t be undone. Export a backup first if you might want it back.")
            }
        }
    }

    private var pillarsSection: some View {
        Section {
            HStack(spacing: 2) {
                Spacer()
                ForEach(0..<5, id: \.self) { i in
                    if i > 0 { Text("·").foregroundStyle(.secondary) }
                    Text(Pillars.letter(profile.pillarName(i))).foregroundStyle(Pillars.color(i))
                }
                Spacer()
            }
            .font(.system(size: 28, weight: .black, design: .rounded))
            ForEach(0..<5, id: \.self) { i in
                HStack(spacing: 10) {
                    PillarBadge(pillar: i, name: profile.pillarName(i))
                    VStack(alignment: .leading, spacing: 2) {
                        TextField("Pillar \(i + 1)", text: nameBinding(i))
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                        TextField("Description", text: hintBinding(i))
                            .font(.system(size: 12.5))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Button("Restore Define · Routine · Iterate · Learn · Lock-in") {
                profile.pillarNames = Pillars.defaultNames
                profile.pillarHints = Pillars.defaultHints
            }
            .font(.system(size: 14, weight: .semibold))
            .tint(Theme.accent)
        } header: {
            Text("DRILL pillars")
        } footer: {
            Text("Rename the pillars to tweak the acronym. Habits keep their pillar.")
        }
    }

    private var timerSection: some View {
        Section {
            Toggle("Show in Dynamic Island", isOn: $profile.liveActivityOn)
                .tint(Theme.good)
            StepperRow(title: "Work", value: profile.workMinutes, unit: "min", range: 5...120, step: 5) { profile.workMinutes = $0 }
            StepperRow(title: "Break", value: profile.breakMinutes, unit: "min", range: 1...30) { profile.breakMinutes = $0 }
            StepperRow(title: "Rounds", value: profile.rounds, unit: "", range: 1...8) { profile.rounds = $0 }
        } header: {
            Text("Focus timer")
        } footer: {
            Text("Running sessions appear as a Live Activity in the Dynamic Island and on the Lock Screen. Live Activities must also be allowed for Drillside in iOS Settings.")
        }
    }

    private var reminderSection: some View {
        Section {
            Toggle("Daily check-in reminder", isOn: Binding(get: { profile.reminderOn }, set: { on in
                profile.reminderOn = on
                updateReminder()
            }))
            .tint(Theme.good)
            if profile.reminderOn {
                DatePicker("Time", selection: Binding(get: { reminderDate }, set: { d in
                    let c = Calendar.current.dateComponents([.hour, .minute], from: d)
                    profile.reminderHour = c.hour ?? 21
                    profile.reminderMinute = c.minute ?? 0
                    updateReminder()
                }), displayedComponents: .hourAndMinute)
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("Local notifications only. Nothing leaves your device.")
        }
    }

    private var backupSection: some View {
        Section {
            Button {
                do {
                    exportDoc = BackupDocument(data: try BackupService.makeBackup(context: context))
                    showExporter = true
                } catch {
                    toasts.show("Couldn’t create the backup")
                }
            } label: { Label("Export JSON backup", systemImage: "square.and.arrow.up") }
            Button { showImporter = true } label: { Label("Import JSON backup", systemImage: "square.and.arrow.down") }
            Button(role: .destructive) { confirmReset = true } label: { Label("Erase all data", systemImage: "trash") }
        } header: {
            Text("Backup")
        } footer: {
            Text("Backups are plain JSON files you can keep in Files, iCloud Drive or anywhere you like.")
        }
    }

    private var reminderDate: Date {
        Calendar.current.date(bySettingHour: profile.reminderHour, minute: profile.reminderMinute, second: 0, of: Date()) ?? Date()
    }

    private func updateReminder() {
        let on = profile.reminderOn, h = profile.reminderHour, m = profile.reminderMinute
        if on {
            Task {
                if await Notifier.requestAuthorization() {
                    await Notifier.scheduleDailyReminder(hour: h, minute: m)
                } else {
                    await MainActor.run {
                        profile.reminderOn = false
                        toasts.show("Notifications are off for Drillside in iOS Settings")
                    }
                }
            }
        } else {
            Notifier.cancelDailyReminder()
        }
    }

    private func nameBinding(_ i: Int) -> Binding<String> {
        Binding(get: { profile.pillarName(i) }, set: { v in
            var names = profile.pillarNames
            while names.count < 5 { names.append(Pillars.defaultNames[names.count]) }
            names[i] = String(v.prefix(16))
            profile.pillarNames = names
        })
    }

    private func hintBinding(_ i: Int) -> Binding<String> {
        Binding(get: { profile.pillarHint(i) }, set: { v in
            var hints = profile.pillarHints
            while hints.count < 5 { hints.append(Pillars.defaultHints[hints.count]) }
            hints[i] = String(v.prefix(44))
            profile.pillarHints = hints
        })
    }
}
