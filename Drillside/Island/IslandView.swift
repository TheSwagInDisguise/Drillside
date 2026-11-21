import SwiftUI
import SwiftData

struct IslandView: View {
    @Bindable var profile: Profile
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(Router.self) private var router
    @Environment(ToastCenter.self) private var toasts
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @Query private var placed: [PlacedProp]
    @Query private var sessions: [FocusSession]
    @Query private var logs: [LogEntry]

    @State private var engine = IslandEngine()
    @State private var editing = false
    @State private var placing: PropType?
    @State private var selected: UUID?
    @State private var showPicker = false
    @State private var showReset = false
    @State private var baseZoom: CGFloat = 1
    @State private var cameraMoved = false

    private var today: String { Day.today }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                canvas(safeTop: geo.safeAreaInsets.top)
                    .ignoresSafeArea(edges: .top)
                VStack(spacing: 8) {
                    hud
                    Spacer()
                    if editing { editTray } else { focusBar }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .padding(.top, 2)
            }
        }
        .sheet(isPresented: $showPicker) {
            FocusPickerSheet(profile: profile, habits: habits) { habit in
                showPicker = false
                startTimer(habit)
            }
            .presentationDetents([.medium, .large])
        }
        .confirmationDialog(resetTitle, isPresented: $showReset, titleVisibility: .visible) {
            Button("Refund 🐚 \(placedValue)") { reset(refund: true) }
            Button("Return all to inventory") { reset(refund: false) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Companions and island size are not affected.")
        }
        .onAppear(perform: consumePendingPlacement)
        .onChange(of: router.openEditor) { _, open in if open { consumePendingPlacement() } }
    }

    // MARK: Canvas

    private func canvas(safeTop: CGFloat) -> some View {
        let active = router.tab == .island && router.timer == nil && scenePhase == .active
        return TimelineView(.animation(minimumInterval: nil, paused: !active)) { tl in
            Canvas { ctx, size in
                let e = engine
                e.gridSize = profile.islandSize
                e.props = placed.map { PropSnapshot(id: $0.id, type: $0.type, row: $0.row, col: $0.col) }
                e.companions = profile.ownedCompanions
                e.isNight = profile.isNight
                e.editing = editing
                e.placing = placing
                e.selected = selected
                e.layout(size: size, topInset: safeTop + 110, bottomInset: editing ? 200 : 100)
                e.step(to: tl.date)
                e.draw(ctx)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged(dragChanged)
                .onEnded(dragEnded)
        )
        .simultaneousGesture(
            MagnifyGesture()
                .onChanged { v in
                    engine.pinching = true
                    engine.zoom = min(3, max(1, baseZoom * v.magnification))
                }
                .onEnded { _ in
                    baseZoom = engine.zoom
                    engine.pinching = false
                    cameraMoved = engine.isCameraMoved
                }
        )
        .accessibilityLabel("Your island. Bitsy the mole is wandering between your decorations.")
    }

    private func dragChanged(_ v: DragGesture.Value) {
        let e = engine
        if e.downPoint == nil {
            e.downPoint = v.startLocation
            e.panStart = e.pan
            e.panning = false
            e.dragMoved = false
            let cell = e.cell(at: v.startLocation)
            e.hover = cell
            if editing {
                if let type = placing {
                    let out = Game.place(type, row: cell.row, col: cell.col, profile: profile, props: placed, context: context)
                    if out.ok {
                        e.layoutChanged()
                        if profile.inventoryCount(type) == 0 { placing = nil }
                    } else if !e.inGrid(cell) {
                        e.panning = true
                    } else if let m = out.message {
                        toasts.show(m)
                    }
                } else if e.inGrid(cell), let p = e.prop(at: cell) {
                    e.dragID = p.id
                    selected = p.id
                } else {
                    selected = nil
                    e.panning = true
                }
            } else {
                e.panning = true
            }
        }
        if e.pinching { return }
        e.hover = e.cell(at: v.location)
        if hypot(v.translation.width, v.translation.height) > 6 { e.dragMoved = true }
        if e.panning && e.dragMoved {
            e.pan = CGSize(width: e.panStart.width + v.translation.width, height: e.panStart.height + v.translation.height)
        }
    }

    private func dragEnded(_ v: DragGesture.Value) {
        let e = engine
        defer {
            e.downPoint = nil
            e.dragID = nil
            e.dragMoved = false
            e.panning = false
            cameraMoved = e.isCameraMoved
        }
        let moved = hypot(v.translation.width, v.translation.height) > 6
        if e.pinching { return }
        if editing {
            if let id = e.dragID, moved, let prop = placed.first(where: { $0.id == id }) {
                let cell = e.cell(at: v.location)
                let out = Game.move(prop, row: cell.row, col: cell.col, size: profile.islandSize, props: placed)
                if out.ok {
                    try? context.save()
                    e.layoutChanged()
                } else if let m = out.message {
                    toasts.show(m)
                }
            }
            if placing == nil { e.hover = nil }
            return
        }
        if !moved { e.tap(at: v.location) }
    }

    private func recenter() {
        engine.resetCamera()
        baseZoom = 1
        cameraMoved = false
    }

    // MARK: HUD

    private var hud: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                HStack(spacing: 10) {
                    Text("\(profile.level)")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(LinearGradient(colors: [Color(hex: 0xFFB85C), Theme.accent], startPoint: .top, endPoint: .bottom),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("Level \(profile.level)")
                            Spacer()
                            Text("\(profile.xp) / \(Economy.xpNeeded(forLevel: profile.level)) XP").opacity(0.65)
                        }
                        .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(.gray.opacity(0.2))
                                Capsule()
                                    .fill(LinearGradient(colors: [Color(hex: 0xFFB85C), Theme.accent], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: g.size.width * CGFloat(profile.xp) / CGFloat(Economy.xpNeeded(forLevel: profile.level)))
                                    .animation(.easeOut(duration: 0.5), value: profile.xp)
                            }
                        }
                        .frame(height: 7)
                    }
                }
                .padding(.vertical, 7).padding(.leading, 7).padding(.trailing, 12)
                .glass(night: profile.isNight)
                .accessibilityElement(children: .combine)

                Text("🐚 \(profile.shells)")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .padding(.horizontal, 12)
                    .frame(maxHeight: .infinity)
                    .glass(night: profile.isNight)
                    .accessibilityLabel("\(profile.shells) shells")

                Button {
                    withAnimation { profile.isNight.toggle() }
                } label: {
                    Image(systemName: profile.isNight ? "sun.max" : "moon")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 48)
                        .frame(maxHeight: .infinity)
                }
                .glass(night: profile.isNight)
                .accessibilityLabel(profile.isNight ? "Switch to day" : "Switch to night")
            }
            .fixedSize(horizontal: false, vertical: true)

            HStack {
                HStack(spacing: 10) {
                    Text("✓ \(todayDone)/\(todayDue) today")
                    Text("⏱ \(todayFocus) min")
                    Text("🔥 \(logStreak)-day log")
                }
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .padding(.horizontal, 11).padding(.vertical, 6)
                .glass(night: profile.isNight, radius: 12)
                Spacer()
                if cameraMoved {
                    Button(action: recenter) {
                        Label("Recenter", systemImage: "scope")
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                            .padding(.horizontal, 10).padding(.vertical, 6)
                    }
                    .glass(night: profile.isNight, radius: 12)
                    .transition(.opacity)
                }
            }
        }
    }

    private var focusBar: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.spring(duration: 0.3)) { editing = true }
            } label: {
                Image(systemName: "pencil").font(.system(size: 20, weight: .semibold)).frame(width: 60, height: 60)
            }
            .glass(night: profile.isNight, radius: 20)
            .accessibilityLabel("Edit island")

            Button {
                startTimer(recommended)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 15))
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.25), in: Circle())
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Start Focus").font(.system(size: 16, weight: .heavy, design: .rounded))
                        Text(recommended.map { "\($0.name) · \($0.focusMinutes) min" } ?? "Quick focus · \(profile.workMinutes) min")
                            .font(.system(size: 12.5, weight: .medium, design: .rounded))
                            .lineLimit(1)
                            .opacity(0.92)
                    }
                    Spacer(minLength: 0)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(LinearGradient(colors: [Theme.accentLight, Theme.accent], startPoint: .top, endPoint: .bottom),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Theme.accent.opacity(0.38), radius: 10, y: 8)
            }

            Button {
                showPicker = true
            } label: {
                Image(systemName: "list.bullet").font(.system(size: 20, weight: .semibold)).frame(width: 60, height: 60)
            }
            .glass(night: profile.isNight, radius: 20)
            .accessibilityLabel("Choose a focus block")
        }
    }

    private var editTray: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Edit Island").font(.system(size: 15, weight: .heavy, design: .rounded))
                    Text(placing.map { "Tap an empty tile to place \($0.name)" } ?? "Drag props to move · drag empty space to pan · pinch to zoom")
                        .font(.system(size: 11.5)).opacity(0.7)
                }
                Spacer()
                Button("Reset") { showReset = true }
                    .buttonStyle(.bordered).tint(.gray)
                Button("Done") {
                    withAnimation(.spring(duration: 0.3)) {
                        editing = false
                        placing = nil
                        selected = nil
                    }
                }
                .buttonStyle(.borderedProminent).tint(Theme.accent)
            }
            .font(.system(size: 13.5, weight: .bold, design: .rounded))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    let inv = profile.inventoryCounts
                    if inv.isEmpty {
                        Text("Inventory empty. Buy props in the Shop, or store placed ones here.")
                            .font(.system(size: 13)).opacity(0.75)
                            .padding(.vertical, 12)
                    }
                    ForEach(inv) { item in
                        Button {
                            placing = placing == item.type ? nil : item.type
                            selected = nil
                        } label: {
                            VStack(spacing: 0) {
                                ThumbView(kind: .prop(item.type)).frame(width: 48, height: 48)
                                Text(item.type.short).font(.system(size: 10.5, weight: .bold, design: .rounded))
                            }
                            .frame(width: 68)
                            .padding(.vertical, 4)
                            .background(placing == item.type ? Theme.accent.opacity(0.15) : Color.gray.opacity(0.12),
                                        in: RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(placing == item.type ? Theme.accent : .clear, lineWidth: 2))
                            .overlay(alignment: .topTrailing) {
                                Text("\(item.count)")
                                    .font(.system(size: 10.5, weight: .heavy))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 5)
                                    .background(Theme.accent, in: Capsule())
                                    .padding(4)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(item.type.name), \(item.count) in inventory")
                    }
                }
            }

            if let id = selected, let prop = placed.first(where: { $0.id == id }) {
                Divider()
                HStack {
                    Text("Selected: \(prop.type.name)").font(.system(size: 13.5, weight: .bold, design: .rounded))
                    Spacer()
                    Button("Store in inventory") {
                        let name = prop.type.name
                        Game.store(prop, profile: profile, context: context)
                        selected = nil
                        engine.layoutChanged()
                        toasts.show("\(name) moved to inventory")
                    }
                    .buttonStyle(.bordered)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                }
            }
        }
        .padding(12)
        .glass(night: profile.isNight, radius: 20)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: Data helpers

    private var recommended: Habit? {
        habits.first { $0.kind == .focus && $0.rules.meta(today).due && !$0.isDone(today) }
    }

    private var todayDue: Int { habits.filter { $0.rules.meta(today).due }.count }
    private var todayDone: Int { habits.filter { $0.rules.meta(today).due && $0.isDone(today) }.count }
    private var todayFocus: Int { sessions.filter { $0.dayKey == today }.reduce(0) { $0 + $1.minutes } }

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

    private var placedValue: Int { placed.reduce(0) { $0 + $1.type.price } }

    private var resetTitle: String {
        "Reset layout? \(placed.count) placed decoration\(placed.count == 1 ? "" : "s") worth 🐚 \(placedValue)"
    }

    private func reset(refund: Bool) {
        let out = Game.resetLayout(refund: refund, props: placed, profile: profile, context: context)
        selected = nil
        engine.layoutChanged()
        if let m = out.message { toasts.show(m) }
    }

    private func startTimer(_ habit: Habit?) {
        if let h = habit {
            let isBlock = h.kind == .focus
            router.timer = FocusTimer(title: h.name, pillar: h.pillar, habitID: h.id,
                                      work: isBlock ? h.focusMinutes : profile.workMinutes,
                                      rest: profile.breakMinutes, rounds: isBlock ? 1 : profile.rounds)
        } else {
            router.timer = FocusTimer(title: "Quick focus", pillar: 4, habitID: nil,
                                      work: profile.workMinutes, rest: profile.breakMinutes, rounds: profile.rounds)
        }
    }

    private func consumePendingPlacement() {
        guard router.openEditor else { return }
        router.openEditor = false
        editing = true
        selected = nil
        if let p = router.pendingPlacement, profile.inventoryCount(p) > 0 { placing = p }
        router.pendingPlacement = nil
    }
}

struct FocusPickerSheet: View {
    let profile: Profile
    let habits: [Habit]
    var onPick: (Habit?) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { onPick(nil) } label: {
                        row(letter: "⏱", color: Theme.accent, title: "Quick focus",
                            subtitle: "\(profile.workMinutes)m work / \(profile.breakMinutes)m break × \(profile.rounds)")
                    }
                }
                Section("Focus blocks") {
                    ForEach(habits.filter { $0.kind == .focus }) { h in
                        let done = h.isDone(Day.today)
                        let due = h.rules.meta(Day.today).due
                        Button { onPick(h) } label: {
                            row(letter: Pillars.letter(profile.pillarName(h.pillar)), color: Pillars.color(h.pillar), title: h.name,
                                subtitle: "\(h.focusMinutes) min · " + (done ? "done today ✓" : (due ? "due today" : "not due")))
                        }
                    }
                }
                Section {
                    Text("Every completed focus minute = +1 XP and +1 🐚. Any habit can be timed from the DRILL tab.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Start focus")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func row(letter: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Text(letter)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(color, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading) {
                Text(title).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(.primary)
                Text(subtitle).font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "play.fill").foregroundStyle(Theme.accent)
        }
    }
}

private struct GlassModifier: ViewModifier {
    var night: Bool
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .foregroundStyle(night ? Color(hex: 0xEEF1F8) : Color(hex: 0x1F2633))
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(night ? Color(hex: 0x161C34, opacity: 0.62) : Color.white.opacity(0.8))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
                    .shadow(color: Color(hex: 0x14283C, opacity: 0.12), radius: 7, y: 4)
            )
    }
}

extension View {
    func glass(night: Bool, radius: CGFloat = 16) -> some View {
        modifier(GlassModifier(night: night, radius: radius))
    }
}
