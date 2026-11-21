import SwiftUI

struct PropSnapshot: Equatable {
    let id: UUID
    let type: PropType
    let row: Int
    let col: Int
}

struct GridCell: Equatable {
    var row: Int
    var col: Int
}

/// Runtime simulation + renderer for the isometric island. Not observable on purpose:
/// it is advanced and drawn from inside a `TimelineView`/`Canvas` every frame.
final class IslandEngine {
    // Layout
    private(set) var tileW: CGFloat = 56
    private(set) var tileH: CGFloat = 28
    private(set) var depth: CGFloat = 24
    private(set) var originX: CGFloat = 0
    private(set) var originY: CGFloat = 0
    private(set) var size: CGSize = .zero

    // World snapshot (refreshed by the view every frame)
    var gridSize = 6
    var props: [PropSnapshot] = []
    var companions: [CompanionType] = []
    var skyMode: SkyClock.Mode = .auto
    var editing = false
    var placing: PropType?
    var selected: UUID?

    // Camera
    var zoom: CGFloat = 1
    var pan: CGSize = .zero
    var panStart: CGSize = .zero
    var panning = false
    var pinching = false

    // Edit interaction
    var hover: GridCell?
    var dragID: UUID?
    var dragMoved = false
    var downPoint: CGPoint?

    // Clock
    private(set) var t: CGFloat = 0
    private var nightT: CGFloat = -1
    private var goldenT: CGFloat = 0
    private var sunP: CGFloat = 0.5
    private var moonP: CGFloat = 0.5
    private var sky = SkyClock.State(night: 0, golden: 0, sunProgress: 0.5, moonProgress: 0.5, sunrise: 6, sunset: 20)
    private var skyCheckedAt: Date = .distantPast
    private var lastSkyMode: SkyClock.Mode = .auto
    private var lastDate: Date?

    // Bitsy
    private var mR: CGFloat = 3.5
    private var mC: CGFloat = 2.5
    private var path: [CGPoint] = []
    private var goal: UUID?
    private var action: PropType?
    private var actionUntil: CGFloat = 0
    private var idle: CGFloat = 1.2
    private var bubble: String?
    private var bubbleUntil: CGFloat = 0
    private var jump: CGFloat = 0
    private var face: CGFloat = 1
    private var lie: CGPoint?
    private var walking = false

    private struct Critter {
        var r: CGFloat, c: CGFloat, tr: CGFloat, tc: CGFloat, wait: CGFloat, face: CGFloat
        var moving = false
    }
    private var critters: [CompanionType: Critter] = [:]

    private struct Wave { var x: CGFloat, y: CGFloat, len: CGFloat, ph: CGFloat }
    private struct Star { var x: CGFloat, y: CGFloat, r: CGFloat, ph: CGFloat }
    private let waves: [Wave]
    private let stars: [Star]

    static let cheers = ["Let’s drill in! ⛏️", "One block at a time 🌱", "You showed up today 💛", "Lock-in time?", "Tiny steps, big island 🏝️", "Proud of you!"]

    init() {
        var rng = SeededRandom(seed: 5)
        waves = (0..<34).map { _ in Wave(x: rng.next(), y: rng.next(), len: 10 + rng.next() * 16, ph: rng.next() * 6) }
        stars = (0..<50).map { _ in Star(x: rng.next(), y: rng.next(), r: 0.6 + rng.next() * 1.3, ph: rng.next() * 6) }
    }

    // MARK: Geometry

    func layout(size: CGSize, topInset: CGFloat, bottomInset: CGFloat) {
        self.size = size
        let n = CGFloat(gridSize)
        let baseW = min(60, (size.width - 34) / n)
        let baseH = baseW / 2
        let islandH = n * baseH + baseW * 0.45
        let avail = size.height - topInset - bottomInset
        let top1 = topInset + 50 + max(0, (avail - 50 - islandH) / 2)
        let centerY = top1 + n * baseH / 2
        tileW = baseW * zoom
        tileH = tileW / 2
        depth = tileW * 0.45
        let maxX = n * tileW / 2
        let maxY = n * tileH / 2 + 120
        pan.width = min(maxX, max(-maxX, pan.width))
        pan.height = min(maxY, max(-maxY, pan.height))
        originX = size.width / 2 + pan.width
        originY = centerY - n * tileH / 2 + pan.height
    }

    var isCameraMoved: Bool { zoom > 1.01 || abs(pan.width) > 1 || abs(pan.height) > 1 }

    func resetCamera() {
        zoom = 1
        pan = .zero
    }

    var scale: CGFloat { tileW / 56 }

    func project(_ r: CGFloat, _ c: CGFloat) -> CGPoint {
        CGPoint(x: originX + (c - r) * tileW / 2, y: originY + (c + r) * tileH / 2)
    }

    func cell(at p: CGPoint) -> GridCell {
        let u = (p.x - originX) / (tileW / 2)
        let v = (p.y - originY) / (tileH / 2)
        return GridCell(row: Int(floor((v - u) / 2)), col: Int(floor((u + v) / 2)))
    }

    func inGrid(_ g: GridCell) -> Bool { g.row >= 0 && g.col >= 0 && g.row < gridSize && g.col < gridSize }

    func prop(at g: GridCell) -> PropSnapshot? { props.first { $0.row == g.row && $0.col == g.col } }

    // MARK: Interaction

    func say(_ text: String, for seconds: CGFloat = 2.6) {
        bubble = text
        bubbleUntil = t + seconds
    }

    /// Call whenever the layout changed so Bitsy re-plans.
    func layoutChanged() {
        path = []
        action = nil
        lie = nil
        goal = nil
        bubble = nil
        idle = 0.6
    }

    func tap(at p: CGPoint) {
        let s = scale
        let pos = lie ?? CGPoint(x: mC, y: mR)
        let m = project(pos.y, pos.x)
        if hypot(p.x - m.x, p.y - (m.y - 16 * s)) < 22 * s + 6 {
            jump = 0.5
            say(Self.cheers.randomElement() ?? "Hi!")
            return
        }
        let g = cell(at: p)
        guard inGrid(g) else { return }
        if let pr = prop(at: g) { goTo(prop: pr, user: true) } else { goTo(cell: g) }
    }

    // MARK: Simulation

    func step(to date: Date) {
        let dt: CGFloat
        if let last = lastDate { dt = CGFloat(min(0.05, max(0, date.timeIntervalSince(last)))) } else { dt = 0 }
        lastDate = date
        t += dt
        if date.timeIntervalSince(skyCheckedAt) > 1 || skyMode != lastSkyMode {
            sky = SkyClock.resolved(mode: skyMode, at: date)
            skyCheckedAt = date
            lastSkyMode = skyMode
        }
        if nightT < 0 { nightT = CGFloat(sky.night); goldenT = CGFloat(sky.golden) }
        let k = min(1, dt * 1.5)
        nightT += (CGFloat(sky.night) - nightT) * k
        goldenT += (CGFloat(sky.golden) - goldenT) * k
        sunP += (CGFloat(sky.sunProgress) - sunP) * k
        moonP += (CGFloat(sky.moonProgress) - moonP) * k
        mR = min(CGFloat(gridSize) - 0.5, mR)
        mC = min(CGFloat(gridSize) - 0.5, mC)
        updateMole(dt)
        updateCritters(dt)
    }

    private func blocked() -> Set<Int> { Set(props.filter { !$0.type.isWalkable }.map { $0.row * 100 + $0.col }) }

    private func bfs(from start: GridCell, goals: Set<Int>) -> [CGPoint]? {
        let n = gridSize
        let blockedSet = blocked()
        let sr = max(0, min(n - 1, start.row)), sc = max(0, min(n - 1, start.col))
        var queue = [(sr, sc)]
        var head = 0
        var prev: [Int: Int] = [:]
        var seen: Set<Int> = [sr * 100 + sc]
        while head < queue.count {
            let (r, c) = queue[head]
            head += 1
            let k = r * 100 + c
            if goals.contains(k) {
                var result: [CGPoint] = []
                var cur: Int? = k
                while let cc = cur {
                    result.insert(CGPoint(x: CGFloat(cc % 100) + 0.5, y: CGFloat(cc / 100) + 0.5), at: 0)
                    cur = prev[cc]
                }
                return result
            }
            for (dr, dc) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                let nr = r + dr, nc = c + dc, nk = nr * 100 + nc
                if nr < 0 || nc < 0 || nr >= n || nc >= n || seen.contains(nk) || blockedSet.contains(nk) { continue }
                seen.insert(nk)
                prev[nk] = k
                queue.append((nr, nc))
            }
        }
        return nil
    }

    private var moleCell: GridCell { GridCell(row: Int(floor(mR)), col: Int(floor(mC))) }

    private func goTo(prop p: PropSnapshot, user: Bool = false) {
        var goals = Set<Int>()
        if p.type.isWalkable {
            goals.insert(p.row * 100 + p.col)
        } else {
            for (dr, dc) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                let g = GridCell(row: p.row + dr, col: p.col + dc)
                if inGrid(g), prop(at: g)?.type.isWalkable ?? true { goals.insert(g.row * 100 + g.col) }
            }
        }
        guard let route = bfs(from: moleCell, goals: goals) else {
            if user { say("Can’t reach that 🤔") }
            idle = 1
            return
        }
        path = route
        goal = p.id
        action = nil
        lie = nil
        if user { say("On my way!", for: 1.2) }
    }

    private func goTo(cell g: GridCell) {
        if let route = bfs(from: moleCell, goals: [g.row * 100 + g.col]) {
            path = route
            goal = nil
            action = nil
            lie = nil
        } else {
            idle = 1
        }
    }

    private func updateMole(_ dt: CGFloat) {
        if jump > 0 { jump = max(0, jump - dt) }
        if let target = path.first {
            // path points are (x: col, y: row)
            let dr = target.y - mR, dc = target.x - mC
            let dist = hypot(dr, dc)
            let sp = 1.7 * dt
            if abs(dc - dr) > 0.01 { face = (dc - dr) > 0 ? 1 : -1 }
            if dist <= sp {
                mR = target.y
                mC = target.x
                path.removeFirst()
                if path.isEmpty { arrive() }
            } else if dist > 0 {
                mR += dr / dist * sp
                mC += dc / dist * sp
            }
            walking = !path.isEmpty
            return
        }
        walking = false
        if action != nil {
            if t > actionUntil {
                action = nil
                lie = nil
                goal = nil
                idle = 1 + CGFloat.random(in: 0...2.5)
            }
        } else {
            idle -= dt
            if idle <= 0 && !editing { wander() }
        }
    }

    private func arrive() {
        guard let gid = goal, let p = props.first(where: { $0.id == gid }) else {
            goal = nil
            idle = 1.5 + CGFloat.random(in: 0...2)
            return
        }
        action = p.type
        actionUntil = t + 4.5
        say(p.type.action, for: 4.3)
        if p.type == .hammock { lie = CGPoint(x: CGFloat(p.col) + 0.5, y: CGFloat(p.row) + 0.5) }
        let px = project(CGFloat(p.row) + 0.5, CGFloat(p.col) + 0.5).x
        let mx = project(mR, mC).x
        face = px >= mx ? 1 : -1
    }

    private func wander() {
        if !props.isEmpty && Double.random(in: 0..<1) < 0.75, let p = props.randomElement() {
            goTo(prop: p)
            return
        }
        for _ in 0..<10 {
            let g = GridCell(row: Int.random(in: 0..<gridSize), col: Int.random(in: 0..<gridSize))
            if prop(at: g)?.type.isWalkable ?? true {
                goTo(cell: g)
                return
            }
        }
        idle = 1
    }

    private func randomFreeCenter() -> (CGFloat, CGFloat) {
        for _ in 0..<12 {
            let g = GridCell(row: Int.random(in: 0..<gridSize), col: Int.random(in: 0..<gridSize))
            if prop(at: g)?.type.isWalkable ?? true { return (CGFloat(g.row) + 0.5, CGFloat(g.col) + 0.5) }
        }
        return (CGFloat(gridSize) / 2, CGFloat(gridSize) / 2)
    }

    private func updateCritters(_ dt: CGFloat) {
        let limit = CGFloat(gridSize) - 0.3
        for type in companions {
            var o: Critter
            if let existing = critters[type] {
                o = existing
            } else {
                let p = randomFreeCenter()
                o = Critter(r: p.0, c: p.1, tr: p.0, tc: p.1, wait: CGFloat.random(in: 0...2), face: 1)
            }
            o.r = min(limit, o.r)
            o.c = min(limit, o.c)
            o.moving = o.wait <= 0
            if o.wait > 0 {
                o.wait -= dt
                if o.wait <= 0 {
                    let p = randomFreeCenter()
                    o.tr = p.0
                    o.tc = p.1
                }
            } else {
                let dr = o.tr - o.r, dc = o.tc - o.c
                let d = hypot(dr, dc)
                let sp = type.speed * dt
                if abs(dc - dr) > 0.01 { o.face = (dc - dr) > 0 ? 1 : -1 }
                if d <= sp {
                    o.r = o.tr
                    o.c = o.tc
                    o.wait = 1.5 + CGFloat.random(in: 0...3.5)
                } else {
                    o.r += dr / d * sp
                    o.c += dc / d * sp
                }
            }
            critters[type] = o
        }
    }

    // MARK: Rendering

    func draw(_ ctx: GraphicsContext) {
        let W = size.width, H = size.height
        guard W > 0, H > 0 else { return }
        let n = gridSize
        let s = scale
        let nt = max(0, nightT)
        let gt = goldenT

        // Sea: day blue → golden-hour peach → night navy
        let seaTop = Color.mixRGB(Color.mixRGB(0xA6E6E8, 0xF5B88E, gt * 0.85), 0x101C3E, nt)
        let seaBottom = Color.mixRGB(Color.mixRGB(0x4DB6C8, 0x5B86B5, gt * 0.7), 0x08112A, nt)
        let sea = Gradient(colors: [Color(rgb: seaTop), Color(rgb: seaBottom)])
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(sea, startPoint: .zero, endPoint: CGPoint(x: 0, y: H)))

        // Sun: arcs left → right over the day, warmer and lower near sunrise/sunset
        if nt < 0.98 {
            let sx = W * (0.12 + 0.76 * sunP)
            let sy = H * 0.24 - sin(sunP * .pi) * H * 0.1
            let a = Double(1 - nt)
            let sunCol = Color(rgb: Color.mixRGB(0xFFF4C2, 0xFF9A55, gt))
            let halo = Gradient(colors: [sunCol.opacity(0.75 * a), sunCol.opacity(0)])
            ctx.fill(Path(ellipseIn: CGRect(x: sx - 70, y: sy - 70, width: 140, height: 140)),
                     with: .radialGradient(halo, center: P(sx, sy), startRadius: 0, endRadius: 70))
            ctx.ell(sx, sy, 15, 15, sunCol.opacity(a))
            // reflection streak on the water
            ctx.ell(sx, sy + 26, 22, 3, sunCol.opacity(0.35 * a))
        }

        if nt > 0.02 {
            for st in stars {
                let a = Double(nt * (0.35 + 0.35 * sin(t * 2 + st.ph)))
                ctx.ell(st.x * W, st.y * H, st.r, st.r, Color(hex: 0xFFFFF0, opacity: a))
            }
            let moon = CGPoint(x: W * (0.12 + 0.76 * moonP), y: H * 0.22 - sin(moonP * .pi) * H * 0.08)
            let glow = Gradient(colors: [Color(hex: 0xFFFADC, opacity: Double(0.9 * nt)), Color(hex: 0xFFFADC, opacity: 0)])
            ctx.fill(Path(ellipseIn: CGRect(x: moon.x - 40, y: moon.y - 40, width: 80, height: 80)),
                     with: .radialGradient(glow, center: moon, startRadius: 0, endRadius: 40))
            ctx.ell(moon.x, moon.y, 11, 11, Color(hex: 0xFFFAE1, opacity: Double(nt)))
            ctx.ell(moon.x + 4, moon.y - 2, 8, 8, Color(rgb: Color.mixRGB(0xA6E6E8, 0x101C3E, nt)).opacity(Double(nt) * 0.9))
        }

        for w in waves {
            let x = (w.x * W + t * 7).truncatingRemainder(dividingBy: W + 40) - 20
            let y = w.y * H + sin(t + w.ph) * 2
            var p = Path()
            p.move(to: P(x, y))
            p.addQuadCurve(to: P(x + w.len, y), control: P(x + w.len / 2, y - 3))
            let a = Double((0.28 - 0.14 * nt) * (0.6 + 0.4 * sin(t * 0.8 + w.ph)))
            ctx.stroke(p, with: .color(.white.opacity(a)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }

        // Island base
        let nn = CGFloat(n)
        func at(_ r: CGFloat, _ c: CGFloat, _ dy: CGFloat = 0) -> CGPoint {
            let p = project(r, c)
            return CGPoint(x: p.x, y: p.y + dy)
        }
        let e: CGFloat = 0.6
        let foam: CGFloat = e + 0.25 + 0.1 * sin(t * 1.4)
        ctx.poly([at(-foam, -foam, depth), at(-foam, nn + foam, depth), at(nn + foam, nn + foam, depth), at(nn + foam, -foam, depth)],
                 .white.opacity(Double(0.35 - 0.2 * nt)))
        ctx.poly([at(-e, -e, depth), at(-e, nn + e, depth), at(nn + e, nn + e, depth), at(nn + e, -e, depth)], Ink.sand)
        let rightV = at(0, nn), bottomV = at(nn, nn), leftV = at(nn, 0)
        let lip = max(3, 4 * s)
        ctx.poly([leftV, bottomV, P(bottomV.x, bottomV.y + depth), P(leftV.x, leftV.y + depth)], Ink.dirtLeft)
        ctx.poly([bottomV, rightV, P(rightV.x, rightV.y + depth), P(bottomV.x, bottomV.y + depth)], Ink.dirtRight)
        ctx.poly([leftV, bottomV, P(bottomV.x, bottomV.y + lip), P(leftV.x, leftV.y + lip)], Ink.lipLeft)
        ctx.poly([bottomV, rightV, P(rightV.x, rightV.y + lip), P(bottomV.x, bottomV.y + lip)], Ink.lipRight)

        for r in 0..<n {
            for c in 0..<n {
                let v = (r * 7 + c * 13) % 3
                let odd = (r + c) % 2 == 1
                let color: Color = odd ? (v == 0 ? Ink.grassB : Ink.grassB2) : (v == 0 ? Ink.grassA : Ink.grassA2)
                let rr = CGFloat(r), cc = CGFloat(c)
                let tile = [at(rr, cc), at(rr, cc + 1), at(rr + 1, cc + 1), at(rr + 1, cc)]
                ctx.poly(tile, color)
                if editing { ctx.polyStroke(tile, .white.opacity(0.45), 1) }
            }
        }

        let dragging = dragID != nil && dragMoved
        if editing, let hv = hover, inGrid(hv), placing != nil || dragging {
            let occupant = prop(at: hv)
            let ok = occupant == nil || occupant?.id == dragID
            let rr = CGFloat(hv.row), cc = CGFloat(hv.col)
            ctx.poly([at(rr, cc), at(rr, cc + 1), at(rr + 1, cc + 1), at(rr + 1, cc)],
                     ok ? Color(hex: 0x50DC78, opacity: 0.45) : Color(hex: 0xF05046, opacity: 0.45))
        }

        // Flat terrain layer
        for p in props.filter({ $0.type.isFlat }).sorted(by: { $0.row + $0.col < $1.row + $1.col }) {
            if dragging && p.id == dragID { continue }
            let pt = project(CGFloat(p.row) + 0.5, CGFloat(p.col) + 0.5)
            if editing && selected == p.id {
                ctx.stroke(Path(ellipseIn: CGRect(x: pt.x - tileW * 0.42, y: pt.y - tileH * 0.42, width: tileW * 0.84, height: tileH * 0.84)),
                           with: .color(Color(hex: 0xFFC83C, opacity: Double(0.7 + 0.3 * sin(t * 6)))), lineWidth: 2.5)
            }
            PropArt.draw(p.type, ctx, pt.x, pt.y, s, t, night: nt)
        }

        // Entities sorted by depth
        var entities: [(CGFloat, (GraphicsContext) -> Void)] = []
        let tt = t
        for p in props {
            if p.type.isFlat { continue }
            if dragging && p.id == dragID { continue }
            let pt = project(CGFloat(p.row) + 0.5, CGFloat(p.col) + 0.5)
            let isSel = editing && selected == p.id
            entities.append((CGFloat(p.row + p.col + 1), { g in
                if isSel {
                    let ring = Path(ellipseIn: CGRect(x: pt.x - self.tileW * 0.42, y: pt.y - self.tileH * 0.42,
                                                      width: self.tileW * 0.84, height: self.tileH * 0.84))
                    g.stroke(ring, with: .color(Color(hex: 0xFFC83C, opacity: Double(0.7 + 0.3 * sin(tt * 6)))), lineWidth: 2.5)
                }
                PropArt.draw(p.type, g, pt.x, pt.y, s, tt, night: nt)
            }))
        }
        for type in companions {
            guard let o = critters[type] else { continue }
            let base = project(o.r, o.c)
            let hop: CGFloat = (type.hops && o.moving) ? abs(sin(t * 9)) * 4 * s : 0
            let pt = CGPoint(x: base.x, y: base.y - hop)
            let f = o.face
            entities.append((o.r + o.c, { g in
                if hop > 0 { g.groundShadow(base.x, base.y, 5 * s) }
                CompanionArt.draw(type, g, pt.x, pt.y, s, tt, face: f)
            }))
        }
        let posR = lie?.y ?? mR, posC = lie?.x ?? mC
        let mp = project(posR, posC)
        let jumpH: CGFloat = jump > 0 ? sin((1 - jump / 0.5) * .pi) * 14 * s : 0
        let bob: CGFloat = walking ? abs(sin(t * 10)) * 2.5 * s : (lie != nil ? sin(t * 1.6) * 1.5 * s : sin(t * 2) * 0.8 * s)
        let pose = MolePose(t: t, bob: bob + jumpH, face: face, lying: lie != nil, action: action, night: nt,
                            walking: walking, sleeping: action == .hammock)
        let moleY = mp.y + (lie != nil ? -8 * s : 0)
        entities.append((posR + posC + (lie != nil ? 0.05 : 0), { g in MoleArt.draw(g, mp.x, moleY, s, pose) }))
        for ent in entities.sorted(by: { $0.0 < $1.0 }) { ent.1(ctx) }

        // Ghost of the prop being placed / dragged
        if editing, let hv = hover, inGrid(hv) {
            var ghostType: PropType? = placing
            if dragging, let id = dragID { ghostType = props.first(where: { $0.id == id })?.type }
            if let gt = ghostType {
                var g = ctx
                g.opacity = 0.75
                let pt = project(CGFloat(hv.row) + 0.5, CGFloat(hv.col) + 0.5)
                PropArt.draw(gt, g, pt.x, pt.y - 4 * s, s, t, night: nt)
            }
        }

        // Golden-hour wash
        if gt > 0.01 {
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0xFF8C50, opacity: Double(0.16 * gt))))
        }

        // Night: a darkness layer with holes punched by every light source, then a warm additive glow.
        if nt > 0.01 {
            let lightsOn = Double(min(1, max(0, (nt - 0.15) / 0.4)))
            var sources: [(CGPoint, CGFloat, Color)] = []
            for p in props {
                guard let L = p.type.light else { continue }
                let pt = project(CGFloat(p.row) + 0.5, CGFloat(p.col) + 0.5)
                let flicker: CGFloat = L.flickers ? 1 + 0.05 * sin(t * 9 + CGFloat(p.row)) : 1
                sources.append((P(pt.x + L.dx * s, pt.y + L.dy * s), L.radius * s * flicker, L.color))
            }
            let lamp = P(mp.x, moleY - 31 * s - bob - jumpH)
            sources.append((lamp, 30 * s, Color(hex: 0xFFF5C8)))

            ctx.drawLayer { layer in
                layer.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0x0A1030, opacity: Double(0.6 * nt))))
                layer.blendMode = .destinationOut
                for src in sources {
                    let r = src.1 * 1.25
                    let grad = Gradient(stops: [.init(color: .black.opacity(0.92 * lightsOn), location: 0),
                                                .init(color: .black.opacity(0.55 * lightsOn), location: 0.45),
                                                .init(color: .black.opacity(0), location: 1)])
                    layer.fill(Path(ellipseIn: CGRect(x: src.0.x - r, y: src.0.y - r, width: r * 2, height: r * 2)),
                               with: .radialGradient(grad, center: src.0, startRadius: 0, endRadius: r))
                }
            }

            var light = ctx
            light.blendMode = .plusLighter
            for src in sources {
                let r = src.1
                let grad = Gradient(colors: [src.2.opacity(0.42 * Double(nt) * lightsOn), src.2.opacity(0)])
                light.fill(Path(ellipseIn: CGRect(x: src.0.x - r, y: src.0.y - r, width: r * 2, height: r * 2)),
                           with: .radialGradient(grad, center: src.0, startRadius: 0, endRadius: r))
            }
            for p in props where p.type == .lighthouse {
                let pt = project(CGFloat(p.row) + 0.5, CGFloat(p.col) + 0.5)
                let lampPt = P(pt.x, pt.y - 57 * s)
                let a = t * 0.8
                let len: CGFloat = 320 * s
                var beam = Path()
                beam.move(to: lampPt)
                beam.addLine(to: P(lampPt.x + cos(a - 0.09) * len, lampPt.y + sin(a - 0.09) * len * 0.5))
                beam.addLine(to: P(lampPt.x + cos(a + 0.09) * len, lampPt.y + sin(a + 0.09) * len * 0.5))
                beam.closeSubpath()
                let grad = Gradient(colors: [Color(hex: 0xFFF6C8, opacity: 0.35 * Double(nt) * lightsOn), Color(hex: 0xFFF6C8, opacity: 0)])
                light.fill(beam, with: .radialGradient(grad, center: lampPt, startRadius: 0, endRadius: len))
            }
        }

        // Speech bubble
        if let text = bubble, t < bubbleUntil {
            let by = mp.y - (lie != nil ? 30 : 44) * s - bob - jumpH
            drawBubble(ctx, text, at: P(mp.x, by))
        }
    }

    private func drawBubble(_ ctx: GraphicsContext, _ text: String, at p: CGPoint) {
        let resolved = ctx.resolve(Text(text).font(.system(size: 11.5, weight: .bold, design: .rounded)).foregroundColor(Ink.ink))
        let sz = resolved.measure(in: CGSize(width: 260, height: 40))
        let w = sz.width + 18
        let cx = min(max(p.x, w / 2 + 6), size.width - w / 2 - 6)
        ctx.rrect(cx - w / 2, p.y - 24, w, 22, 11, .white.opacity(0.96))
        ctx.poly([P(p.x - 5, p.y - 3), P(p.x + 5, p.y - 3), P(p.x, p.y + 3)], .white.opacity(0.96))
        ctx.draw(resolved, at: P(cx, p.y - 13), anchor: .center)
    }
}

/// Deterministic generator so the sea pattern is identical every launch.
struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 0x9E3779B97F4A7C15 | 1 }
    mutating func next() -> CGFloat {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return CGFloat(state % 1_000_000) / 1_000_000
    }
}
