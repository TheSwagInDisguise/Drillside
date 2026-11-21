import SwiftUI

/// Art for the expanded shop catalogue. All coordinates are relative to the tile's ground centre (x, y)
/// at scale s, where a tile is 56 × 28 units at s = 1.
enum MoreArt {
    static func draw(_ type: PropType, _ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat, night: CGFloat) {
        switch type {
        case .bush: bush(c, x, y, s)
        case .sunflower: sunflower(c, x, y, s, t)
        case .pine: pine(c, x, y, s, t)
        case .mushrooms: mushrooms(c, x, y, s)
        case .cactus: cactus(c, x, y, s)
        case .bamboo: bamboo(c, x, y, s, t)
        case .cherry: cherry(c, x, y, s, t)
        case .pumpkins: pumpkins(c, x, y, s)
        case .bench: bench(c, x, y, s)
        case .mailbox: mailbox(c, x, y, s, t)
        case .umbrella: umbrella(c, x, y, s, t)
        case .picnic: picnic(c, x, y, s)
        case .well: well(c, x, y, s)
        case .cabin: cabin(c, x, y, s, t, night)
        case .windmill: windmill(c, x, y, s, t)
        case .lighthouse: lighthouse(c, x, y, s, night)
        case .signpost: signpost(c, x, y, s)
        case .bookshelf: bookshelf(c, x, y, s)
        case .chalkboard: chalkboard(c, x, y, s)
        case .easel: easel(c, x, y, s)
        case .torch: torch(c, x, y, s, t)
        case .streetlamp: streetlamp(c, x, y, s, night)
        case .fireflies: fireflies(c, x, y, s, t, night)
        case .sand: sand(c, x, y, s)
        case .path: path(c, x, y, s)
        case .meadow: meadow(c, x, y, s, t)
        case .deck: deck(c, x, y, s)
        case .pond: pond(c, x, y, s, t)
        default: ExtraArt.draw(type, c, x, y, s, t, night: night)
        }
    }

    // MARK: Nature

    static func bush(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        c.groundShadow(x, y, 13 * s)
        c.ell(x - 6 * s, y - 6 * s, 8 * s, 6.5 * s, Ink.leafDark)
        c.ell(x + 6 * s, y - 6 * s, 8 * s, 6.5 * s, Ink.leafMid)
        c.ell(x, y - 11 * s, 8.5 * s, 7 * s, Ink.leafLight)
        c.ell(x - 2 * s, y - 14 * s, 3 * s, 2 * s, Ink.leafHi)
        let berries: [(CGFloat, CGFloat)] = [(-7, -8), (4, -12), (8, -5), (-2, -6)]
        for b in berries {
            c.ell(x + b.0 * s, y + b.1 * s, 1.6 * s, 1.6 * s, Color(hex: 0x5C6BD6))
        }
    }

    static func sunflower(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 10 * s)
        let stems: [(CGFloat, CGFloat)] = [(-6, 24), (2, 31), (8, 20)]
        for (i, st) in stems.enumerated() {
            let sw: CGFloat = sin(t * 1.4 + CGFloat(i)) * 1.2 * s
            let bx = x + st.0 * s
            let top = y - st.1 * s
            c.line(bx, y, bx + sw, top, Color(hex: 0x4E9A43), 1.6 * s)
            c.ell(bx + 2.5 * s, y - st.1 * 0.45 * s, 3 * s, 1.4 * s, Color(hex: 0x5DAE4E))
            for k in 0..<10 {
                let an: CGFloat = CGFloat(k) / 10 * 2 * .pi
                c.ell(bx + sw + cos(an) * 4 * s, top + sin(an) * 4 * s, 2.2 * s, 2.2 * s, Color(hex: 0xFFC93C))
            }
            c.ell(bx + sw, top, 2.8 * s, 2.8 * s, Color(hex: 0x6B3F1F))
        }
    }

    static func pine(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 13 * s)
        c.rrect(x - 2.5 * s, y - 10 * s, 5 * s, 11 * s, 1.5 * s, Ink.trunk)
        let sw: CGFloat = sin(t * 1.2 + x * 0.05) * 0.8 * s
        let tiers: [(CGFloat, CGFloat, CGFloat, UInt32)] = [(8, 14, 18, 0x2F7A44), (18, 11, 18, 0x3A8C50), (28, 8, 16, 0x4FA35E)]
        for tier in tiers {
            let base = y - tier.0 * s
            let w = tier.1 * s
            c.poly([P(x - w, base), P(x + w, base), P(x + sw, base - tier.2 * s)], Color(hex: tier.3))
        }
    }

    static func mushrooms(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        c.groundShadow(x, y, 11 * s)
        let list: [(CGFloat, CGFloat, CGFloat)] = [(7, -4, 0.55), (-6, 0, 1.0), (4, 2, 0.7)]
        for m in list {
            let k = m.2 * s
            let mx = x + m.0 * s
            let my = y + m.1 * s
            c.rrect(mx - 2.2 * k, my - 9 * k, 4.4 * k, 9 * k, 1.5 * k, Color(hex: 0xF3E9D2))
            var cap = c
            cap.clip(to: Path(CGRect(x: mx - 9 * k, y: my - 18 * k, width: 18 * k, height: 9 * k)))
            cap.ell(mx, my - 9 * k, 8 * k, 8 * k, Color(hex: 0xE5483A))
            c.ell(mx - 3 * k, my - 13 * k, 1.3 * k, 1.1 * k, .white)
            c.ell(mx + 2.5 * k, my - 14.5 * k, 1.1 * k, 0.9 * k, .white)
            c.ell(mx + 4.5 * k, my - 10.5 * k, 0.9 * k, 0.8 * k, .white)
        }
    }

    static func cactus(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        c.groundShadow(x, y, 9 * s)
        let green = Color(hex: 0x4FA35E), light = Color(hex: 0x6CB874)
        c.rrect(x - 11 * s, y - 20 * s, 4 * s, 10 * s, 2 * s, green)
        c.rrect(x - 11 * s, y - 13 * s, 8 * s, 3.5 * s, 1.75 * s, green)
        c.rrect(x + 7 * s, y - 24 * s, 4 * s, 11 * s, 2 * s, green)
        c.rrect(x + 3 * s, y - 16 * s, 8 * s, 3.5 * s, 1.75 * s, green)
        c.rrect(x - 4 * s, y - 28 * s, 8 * s, 28 * s, 4 * s, green)
        c.rrect(x - 2 * s, y - 26 * s, 1.5 * s, 22 * s, 0.75 * s, light)
        c.ell(x, y - 28 * s, 2.6 * s, 2 * s, Color(hex: 0xFF8FB1))
    }

    static func bamboo(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 11 * s)
        let stalks: [(CGFloat, CGFloat)] = [(-7, 40), (-2, 50), (3, 36), (8, 45)]
        for (i, st) in stalks.enumerated() {
            let h = st.1 * s
            let sw: CGFloat = sin(t * 1.5 + CGFloat(i)) * 1.5 * s * (st.1 / 44)
            let bx = x + st.0 * s
            c.line(bx, y, bx + sw, y - h, Color(hex: 0x7CB342), 3 * s)
            var seg: CGFloat = 9
            while seg < st.1 - 2 {
                let k = seg / st.1
                c.line(bx + sw * k - 1.6 * s, y - seg * s, bx + sw * k + 1.6 * s, y - seg * s, Color(hex: 0x5E8F2F), 0.8 * s)
                seg += 9
            }
            for dir in [CGFloat(-1), CGFloat(1)] {
                var g = c
                g.translateBy(x: bx + sw, y: y - h + 4 * s)
                g.rotate(by: .radians(Double(dir * 0.5)))
                g.ell(dir * 5 * s, 0, 5.5 * s, 1.6 * s, Color(hex: 0x8BC34A))
            }
        }
    }

    static func cherry(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 15 * s)
        let w: CGFloat = sin(t * 1.3 + x * 0.07) * 1.2 * s
        c.rrect(x - 3 * s, y - 20 * s, 6 * s, 21 * s, 2 * s, Color(hex: 0x6B4A3A))
        c.line(x, y - 18 * s, x - 7 * s, y - 25 * s, Color(hex: 0x6B4A3A), 2 * s)
        c.ell(x + w * 0.5, y - 31 * s, 16 * s, 13 * s, Color(hex: 0xF29BB5))
        c.ell(x - 8 * s + w, y - 26 * s, 10 * s, 9 * s, Color(hex: 0xF7B6C8))
        c.ell(x + 8 * s + w, y - 27 * s, 10 * s, 9 * s, Color(hex: 0xF7B6C8))
        c.ell(x + w, y - 39 * s, 11 * s, 9 * s, Color(hex: 0xFFD1DE))
        for i in 0..<5 {
            let fi = CGFloat(i)
            let k: CGFloat = (t * 0.3 + fi * 0.2).truncatingRemainder(dividingBy: 1)
            let px = x + sin(fi * 2 + t) * 12 * s
            let py = y - 34 * s + k * 34 * s
            c.ell(px, py, 1.4 * s, 1 * s, Color(hex: 0xF7B6C8, opacity: Double(1 - k)))
        }
    }

    static func pumpkins(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        c.groundShadow(x, y, 13 * s)
        let list: [(CGFloat, CGFloat, CGFloat)] = [(1, -5, 0.7), (-6, 1, 1.0), (6, 2, 0.85)]
        for p in list {
            let k = p.2 * s
            let px = x + p.0 * s
            let py = y + p.1 * s - 5 * k
            c.ell(px, py, 7 * k, 5.5 * k, Color(hex: 0xF28C28))
            c.ell(px, py, 3.2 * k, 5.4 * k, Color(hex: 0xF7A043))
            c.stroke(Path(ellipseIn: CGRect(x: px - 4.5 * k, y: py - 5.5 * k, width: 9 * k, height: 11 * k)),
                     with: .color(Color(hex: 0xD96E12)), lineWidth: 0.7 * k)
            c.rrect(px - 0.8 * k, py - 7.5 * k, 1.6 * k, 3 * k, 0.6 * k, Color(hex: 0x5E8F2F))
        }
        c.ell(x - 10 * s, y - 2 * s, 3 * s, 1.5 * s, Color(hex: 0x5DAE4E))
    }

    // MARK: Cozy

    static func bench(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        c.groundShadow(x, y, 16 * s)
        let g = c.skewed(x, y + 3 * s)
        let wood = Color(hex: 0xC08A55), dark = Ink.trunkDark
        g.rrect(-12 * s, -8 * s, 2.5 * s, 8 * s, s, dark)
        g.rrect(9.5 * s, -8 * s, 2.5 * s, 8 * s, s, dark)
        g.rrect(-12 * s, -21 * s, 2 * s, 11 * s, s, dark)
        g.rrect(10 * s, -21 * s, 2 * s, 11 * s, s, dark)
        g.rrect(-14 * s, -21 * s, 28 * s, 3 * s, 1.5 * s, wood)
        g.rrect(-14 * s, -16.5 * s, 28 * s, 2.5 * s, 1.2 * s, wood)
        g.rrect(-14 * s, -11 * s, 28 * s, 3.5 * s, 1.5 * s, Color(hex: 0xB07A47))
    }

    static func mailbox(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 6 * s)
        c.rrect(x - 1.2 * s, y - 18 * s, 2.4 * s, 18 * s, s, Ink.trunkDark)
        let g = c.skewed(x, y)
        g.rrect(-5 * s, -27 * s, 12 * s, 9 * s, 4 * s, Color(hex: 0x4A7BD0))
        g.rrect(-5 * s, -23 * s, 12 * s, 5 * s, s, Color(hex: 0x4A7BD0))
        g.rrect(-5 * s, -26 * s, 2 * s, 7 * s, s, Color(hex: 0x3A63AD))
        let up = sin(t * 0.7) > 0.4
        g.line(7.5 * s, -19 * s, 7.5 * s, up ? -29 * s : -22 * s, Color(hex: 0x3C3F46), s)
        g.rrect(7.5 * s, up ? -29 * s : -22 * s, 4.5 * s, 3.2 * s, 0.8 * s, Color(hex: 0xE5483A))
    }

    static func umbrella(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x + 4 * s, y + 2 * s, 18 * s)
        c.poly([P(x - 14 * s, y + 2 * s), P(x - 2 * s, y + 8 * s), P(x + 6 * s, y + 4 * s), P(x - 6 * s, y - 2 * s)], Color(hex: 0x5BC0EB))
        c.poly([P(x - 10 * s, y + 4 * s), P(x - 6 * s, y + 6 * s), P(x + 2 * s, y + 2 * s), P(x - 2 * s, y)], .white.opacity(0.8))
        let sw: CGFloat = sin(t * 1.2) * 0.6 * s
        c.line(x, y, x + sw, y - 32 * s, Color(hex: 0xE9E2D0), 1.6 * s)
        let cx = x + sw, cy = y - 30 * s
        var dome = c
        dome.clip(to: Path(CGRect(x: cx - 22 * s, y: cy - 12 * s, width: 44 * s, height: 12 * s)))
        dome.ell(cx, cy, 20 * s, 10 * s, Color(hex: 0xE8574A))
        for k in [CGFloat(-2), CGFloat(0), CGFloat(2)] {
            dome.poly([P(cx, cy - 10 * s), P(cx + (k * 5 - 2.5) * s, cy), P(cx + (k * 5 + 2.5) * s, cy)], .white)
        }
        for k in -4...4 {
            c.ell(cx + CGFloat(k) * 4.5 * s, cy, 2.4 * s, 1.4 * s, k % 2 == 0 ? Color(hex: 0xE8574A) : .white)
        }
    }

    static func picnic(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        let blanket = c.groundDiamondPath(x, y, s, 0.78)
        c.fill(blanket, with: .color(Color(hex: 0xF4F1EA)))
        var g = c
        g.clip(to: blanket)
        for i in -3...3 {
            let o = CGFloat(i) * 6 * s
            g.line(x + o - 30 * s, y - o * 0.5 - 15 * s, x + o + 30 * s, y - o * 0.5 + 15 * s, Color(hex: 0xE5483A, opacity: 0.55), 3 * s)
            g.line(x + o - 30 * s, y + o * 0.5 + 15 * s, x + o + 30 * s, y + o * 0.5 - 15 * s, Color(hex: 0xE5483A, opacity: 0.55), 3 * s)
        }
        c.isoBox(x + 5 * s, y - 1 * s, 5 * s, 5 * s, top: Color(hex: 0xD9A866), left: Color(hex: 0xC08A55), right: Color(hex: 0xA0703F))
        var handle = Path()
        handle.move(to: P(x + 1 * s, y - 6 * s))
        handle.addQuadCurve(to: P(x + 9 * s, y - 6 * s), control: P(x + 5 * s, y - 13 * s))
        c.stroke(handle, with: .color(Color(hex: 0x8A5E33)), lineWidth: 1 * s)
        c.ell(x - 7 * s, y + 1 * s, 2.2 * s, 2.2 * s, Ink.apple)
        c.ell(x - 3 * s, y + 4 * s, 2.6 * s, 1.4 * s, Color(hex: 0xF2C14E))
    }

    static func well(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        c.groundShadow(x, y, 16 * s)
        let stone = Color(hex: 0xA9B0B9)
        c.ell(x, y, 12 * s, 5 * s, stone)
        c.rrect(x - 12 * s, y - 12 * s, 24 * s, 12 * s, 0, stone)
        c.rrect(x - 8 * s, y - 9 * s, 6 * s, 3 * s, s, Color(hex: 0x959DA7))
        c.rrect(x + 2 * s, y - 5 * s, 6 * s, 3 * s, s, Color(hex: 0x959DA7))
        c.ell(x, y - 12 * s, 12 * s, 5 * s, Color(hex: 0xC3C9D0))
        c.ell(x, y - 12 * s, 9.5 * s, 3.6 * s, Color(hex: 0x2E5A7A))
        c.rrect(x - 11 * s, y - 30 * s, 2.5 * s, 19 * s, s, Ink.trunk)
        c.rrect(x + 8.5 * s, y - 30 * s, 2.5 * s, 19 * s, s, Ink.trunk)
        c.line(x - 10 * s, y - 27 * s, x + 10 * s, y - 27 * s, Ink.trunkDark, 1.6 * s)
        c.line(x, y - 27 * s, x, y - 19 * s, Color(hex: 0xD9C7A3), 0.8 * s)
        c.rrect(x - 2 * s, y - 19 * s, 4 * s, 3.5 * s, 0.8 * s, Color(hex: 0x8A5E33))
        c.poly([P(x - 15 * s, y - 28 * s), P(x + 15 * s, y - 28 * s), P(x, y - 39 * s)], Color(hex: 0xB5523B))
        c.line(x - 15 * s, y - 28 * s, x + 15 * s, y - 28 * s, Color(hex: 0x8E3B2E), 1.4 * s)
    }

    static func cabin(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat, _ night: CGFloat) {
        c.groundShadow(x, y + 2 * s, 26 * s)
        let hx: CGFloat = 21 * s, h: CGFloat = 17 * s, hy: CGFloat = hx / 2
        c.isoBox(x, y, hx, h, top: Color(hex: 0xC99560), left: Color(hex: 0xC99560), right: Color(hex: 0xB07A47))
        for k in 1...3 {
            let yy: CGFloat = -h * CGFloat(k) / 4
            c.line(x - hx, y + yy, x, y + hy + yy, Color(hex: 0xA0703F), 0.8 * s)
            c.line(x, y + hy + yy, x + hx, y + yy, Color(hex: 0x8E6236), 0.8 * s)
        }
        // window on the left face
        func leftY(_ px: CGFloat) -> CGFloat { y + (px - (x - hx)) * 0.5 }
        let w0 = x - hx * 0.72, w1 = x - hx * 0.36
        let glass = night > 0.3 ? Color(hex: 0xFFD27A) : Color(hex: 0x9CC9F0)
        c.poly([P(w0, leftY(w0) - 12 * s), P(w1, leftY(w1) - 12 * s), P(w1, leftY(w1) - 6 * s), P(w0, leftY(w0) - 6 * s)], glass)
        // door on the right face
        func rightY(_ px: CGFloat) -> CGFloat { y + hy - (px - x) * 0.5 }
        let d0 = x + hx * 0.32, d1 = x + hx * 0.62
        c.poly([P(d0, rightY(d0)), P(d1, rightY(d1)), P(d1, rightY(d1) - 11 * s), P(d0, rightY(d0) - 11 * s)], Color(hex: 0x7A4A2A))
        // gable roof
        let T = P(x, y - h - hy), R = P(x + hx, y - h), B = P(x, y - h + hy), L = P(x - hx, y - h)
        let rh: CGFloat = 14 * s
        let m1 = P((L.x + T.x) / 2, (L.y + T.y) / 2 - rh)
        let m2 = P((B.x + R.x) / 2, (B.y + R.y) / 2 - rh)
        c.poly([T, R, m2, m1], Color(hex: 0x8E3B2E))
        let q = P((m1.x + T.x) / 2 + 2 * s, (m1.y + T.y) / 2)
        c.rrect(q.x - 2.5 * s, q.y - 9 * s, 5 * s, 10 * s, s, Color(hex: 0x8E96A0))
        for i in 0..<3 {
            let k: CGFloat = (t * 0.4 + CGFloat(i) / 3).truncatingRemainder(dividingBy: 1)
            let r: CGFloat = (2 + k * 3) * s
            c.ell(q.x + sin(t + CGFloat(i)) * 2 * s + k * 6 * s, q.y - 11 * s - k * 18 * s, r, r, Color.white.opacity(Double((1 - k) * 0.55)))
        }
        c.poly([B, R, m2], Color(hex: 0xC99560))
        c.poly([L, B, m2, m1], Color(hex: 0xB5523B))
        c.line(m1.x, m1.y, m2.x, m2.y, Color(hex: 0xD06A50), 1.4 * s)
    }

    static func windmill(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 16 * s)
        c.poly([P(x - 11 * s, y), P(x + 11 * s, y), P(x + 7 * s, y - 36 * s), P(x - 7 * s, y - 36 * s)], Color(hex: 0xEDE3CF))
        c.poly([P(x, y + 2 * s), P(x + 11 * s, y), P(x + 7 * s, y - 36 * s), P(x, y - 36 * s)], Color(hex: 0xD9CBB0))
        c.ell(x, y, 11 * s, 3 * s, Color(hex: 0xD9CBB0))
        c.rrect(x - 3 * s, y - 9 * s, 6 * s, 9 * s, 3 * s, Color(hex: 0x7A4A2A))
        c.ell(x, y - 24 * s, 2.5 * s, 2.5 * s, Color(hex: 0x9CC9F0))
        c.poly([P(x - 9 * s, y - 36 * s), P(x + 9 * s, y - 36 * s), P(x, y - 47 * s)], Color(hex: 0xB5523B))
        let a: CGFloat = t * 1.2
        for k in 0..<4 {
            var g = c
            g.translateBy(x: x, y: y - 39 * s)
            g.rotate(by: .radians(Double(a + CGFloat(k) * .pi / 2)))
            g.rrect(0, -1.2 * s, 24 * s, 2.4 * s, s, Color(hex: 0x8A5E33))
            g.rrect(8 * s, -5 * s, 15 * s, 4 * s, 0.8 * s, Color(hex: 0xF6EEDC))
        }
        c.ell(x, y - 39 * s, 2.5 * s, 2.5 * s, Color(hex: 0x5A3D25))
    }

    static func lighthouse(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ night: CGFloat) {
        c.groundShadow(x, y, 14 * s)
        c.ell(x, y, 13 * s, 6 * s, Ink.stone)
        func w(_ z: CGFloat) -> CGFloat { (10 - z * 0.08) * s }
        for i in 0..<5 {
            let z0 = CGFloat(i) * 10, z1 = CGFloat(i + 1) * 10
            let band = [P(x - w(z0), y - z0 * s), P(x + w(z0), y - z0 * s), P(x + w(z1), y - z1 * s), P(x - w(z1), y - z1 * s)]
            c.poly(band, i % 2 == 0 ? Color(hex: 0xF4F1EA) : Color(hex: 0xE5483A))
            c.poly([P(x, y - z0 * s), P(x + w(z0), y - z0 * s), P(x + w(z1), y - z1 * s), P(x, y - z1 * s)], Color.black.opacity(0.08))
        }
        c.rrect(x - 2.5 * s, y - 8 * s, 5 * s, 8 * s, 2.5 * s, Color(hex: 0x3C3F46))
        c.rrect(x - 8 * s, y - 53 * s, 16 * s, 3 * s, s, Color(hex: 0x3C3F46))
        c.rrect(x - 5 * s, y - 62 * s, 10 * s, 9 * s, 2 * s, night > 0.3 ? Color(hex: 0xFFF1A8) : Color(hex: 0xCFE8F5))
        c.poly([P(x - 7 * s, y - 62 * s), P(x + 7 * s, y - 62 * s), P(x, y - 71 * s)], Color(hex: 0xE5483A))
        c.ell(x, y - 71 * s, 1.5 * s, 1.5 * s, Color(hex: 0x3C3F46))
    }

    // MARK: Study

    static func signpost(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        c.groundShadow(x, y, 6 * s)
        c.rrect(x - 1.5 * s, y - 31 * s, 3 * s, 31 * s, s, Ink.trunk)
        let g = c.skewed(x, y)
        g.poly([P(-1 * s, -29 * s), P(12 * s, -29 * s), P(15 * s, -26.5 * s), P(12 * s, -24 * s), P(-1 * s, -24 * s)], Color(hex: 0xC99560))
        g.poly([P(1 * s, -21 * s), P(-12 * s, -21 * s), P(-15 * s, -18.5 * s), P(-12 * s, -16 * s), P(1 * s, -16 * s)], Color(hex: 0xB07A47))
        g.line(2 * s, -26.5 * s, 9 * s, -26.5 * s, Color(hex: 0x6B4A2E), 0.8 * s)
        g.line(-2 * s, -18.5 * s, -9 * s, -18.5 * s, Color(hex: 0x6B4A2E), 0.8 * s)
    }

    static func bookshelf(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        c.groundShadow(x, y, 12 * s)
        let g = c.skewed(x, y + 3 * s)
        g.rrect(-11 * s, -30 * s, 22 * s, 30 * s, 1.5 * s, Color(hex: 0x8A5E33))
        g.rrect(-9.5 * s, -28.5 * s, 19 * s, 27 * s, s, Color(hex: 0x4A3220))
        let cols: [UInt32] = [0xE5483A, 0x4A7BD0, 0xF2A541, 0x3FB47A, 0xA77BDB, 0xF4F1EA]
        let widths: [CGFloat] = [2.5, 2, 3, 2, 2.5, 2, 3]
        let bases: [CGFloat] = [-19.5, -10.5, -1.5]
        for (row, base) in bases.enumerated() {
            if row < 2 { g.rrect(-9.5 * s, base * s, 19 * s, 1.5 * s, 0, Color(hex: 0x8A5E33)) }
            var bx: CGFloat = -9
            var i = row
            while bx < 8.5 {
                let bw = widths[i % widths.count]
                let bh: CGFloat = 6.5 + CGFloat((i * 7) % 3) * 0.7
                g.rrect(bx * s, (base - bh) * s, (bw - 0.4) * s, bh * s, 0.4 * s, Color(hex: cols[i % cols.count]))
                bx += bw
                i += 1
            }
        }
    }

    static func chalkboard(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        c.groundShadow(x, y, 12 * s)
        let g = c.skewed(x, y + 2 * s)
        g.line(-9 * s, 0, -8 * s, -30 * s, Ink.trunk, 1.6 * s)
        g.line(9 * s, 0, 8 * s, -30 * s, Ink.trunk, 1.6 * s)
        g.rrect(-13 * s, -31 * s, 26 * s, 17 * s, 1.5 * s, Color(hex: 0x8A5E33))
        g.rrect(-11.5 * s, -29.5 * s, 23 * s, 14 * s, s, Color(hex: 0x2F5D46))
        g.draw(Text("DRILL").font(.system(size: max(1, 5.5 * s), weight: .heavy, design: .rounded)).foregroundColor(.white.opacity(0.85)),
               at: P(0, -24.5 * s))
        g.line(-6 * s, -20 * s, 6 * s, -20 * s, .white.opacity(0.7), 0.6 * s)
        g.line(-6 * s, -18 * s, 2 * s, -18 * s, .white.opacity(0.5), 0.6 * s)
        g.rrect(-13 * s, -14 * s, 26 * s, 1.5 * s, 0.5 * s, Color(hex: 0x8A5E33))
    }

    static func easel(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        c.groundShadow(x, y, 10 * s)
        c.line(x + 1 * s, y - 25 * s, x + 4 * s, y - 2 * s, Color(hex: 0x6B4A2E), 1.4 * s)
        let g = c.skewed(x, y)
        g.line(-7 * s, 0, -1 * s, -31 * s, Ink.trunk, 1.5 * s)
        g.line(7 * s, 0, 1 * s, -31 * s, Ink.trunk, 1.5 * s)
        g.rrect(-9 * s, -29 * s, 18 * s, 14 * s, s, Color(hex: 0xFBF8F0))
        g.rrect(-8 * s, -28 * s, 16 * s, 7 * s, 0, Color(hex: 0xA6E6E8))
        g.ell(0, -19 * s, 6 * s, 2.5 * s, Color(hex: 0x8DD26E))
        g.ell(4 * s, -25 * s, 2 * s, 2 * s, Color(hex: 0xFFC93C))
        g.rrect(-10 * s, -15.5 * s, 20 * s, 1.5 * s, 0.5 * s, Ink.trunk)
        c.ell(x + 9 * s, y + 3 * s, 4 * s, 2 * s, Color(hex: 0xE9D3A9))
        c.ell(x + 7.5 * s, y + 2.5 * s, 0.9 * s, 0.6 * s, Color(hex: 0xE5483A))
        c.ell(x + 9.5 * s, y + 2 * s, 0.9 * s, 0.6 * s, Color(hex: 0x4A7BD0))
        c.ell(x + 11 * s, y + 3.2 * s, 0.9 * s, 0.6 * s, Color(hex: 0xFFC93C))
    }

    // MARK: Lights

    static func torch(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 5 * s)
        c.line(x, y, x, y - 22 * s, Color(hex: 0xB98D5E), 2.4 * s)
        c.rrect(x - 1.6 * s, y - 14 * s, 3.2 * s, 1.4 * s, 0.5 * s, Color(hex: 0x8A5E33))
        c.poly([P(x - 4 * s, y - 23 * s), P(x + 4 * s, y - 23 * s), P(x + 2.5 * s, y - 18 * s), P(x - 2.5 * s, y - 18 * s)], Color(hex: 0x6B4A2E))
        c.flame(x, y - 23 * s, 11 * s, 4.5 * s, Color(hex: 0xFF6B2C), t, 0)
        c.flame(x, y - 23 * s, 7 * s, 3 * s, Color(hex: 0xFFC247), t, 2)
        c.flame(x, y - 23 * s, 3.5 * s, 1.5 * s, Color(hex: 0xFFF1B0), t, 4)
    }

    static func streetlamp(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ night: CGFloat) {
        c.groundShadow(x, y, 6 * s)
        let iron = Color(hex: 0x2F3238)
        c.rrect(x - 3 * s, y - 3 * s, 6 * s, 3 * s, s, iron)
        c.line(x, y - 2 * s, x, y - 40 * s, iron, 2.2 * s)
        var arm = Path()
        arm.move(to: P(x, y - 40 * s))
        arm.addQuadCurve(to: P(x + 9 * s, y - 41 * s), control: P(x + 2 * s, y - 47 * s))
        c.stroke(arm, with: .color(iron), lineWidth: 1.8 * s)
        c.poly([P(x + 6 * s, y - 42 * s), P(x + 12 * s, y - 42 * s), P(x + 13.5 * s, y - 37.5 * s), P(x + 4.5 * s, y - 37.5 * s)], iron)
        c.ell(x + 9 * s, y - 37 * s, 3.8 * s, 1.6 * s, night > 0.3 ? Color(hex: 0xFFF1A8) : Color(hex: 0xF3E3B0))
    }

    static func fireflies(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat, _ night: CGFloat) {
        c.groundShadow(x, y, 6 * s)
        c.rrect(x - 5 * s, y - 14 * s, 10 * s, 14 * s, 3 * s, Color(hex: 0xBFE6F2, opacity: 0.55))
        c.rrect(x - 3.5 * s, y - 12 * s, 1.5 * s, 9 * s, 0.75 * s, Color.white.opacity(0.5))
        c.rrect(x - 5.5 * s, y - 16.5 * s, 11 * s, 3 * s, s, Color(hex: 0x8A5E33))
        for i in 0..<4 {
            let fi = CGFloat(i)
            let px = x + sin(t * 1.7 + fi * 2) * 3 * s
            let py = y - 7 * s + cos(t * 1.3 + fi) * 4 * s
            c.ell(px, py, 1.3 * s, 1.3 * s, Color(hex: 0xE8F56A, opacity: Double(0.6 + 0.4 * night)))
        }
        if night > 0.1 {
            for i in 0..<6 {
                let fi = CGFloat(i)
                let px = x + sin(t * 0.6 + fi * 1.3) * 18 * s
                let py = y - 18 * s + cos(t * 0.8 + fi * 2.1) * 11 * s
                let a = Double(night * (0.5 + 0.5 * sin(t * 4 + fi)))
                c.ell(px, py, 1.2 * s, 1.2 * s, Color(hex: 0xF0FF7A, opacity: a))
            }
        }
    }

    // MARK: Terrain (flat)

    static func sand(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        c.fill(c.groundDiamondPath(x, y, s, 0.94), with: .color(Ink.sand))
        let dots: [(CGFloat, CGFloat)] = [(-10, -1), (-3, 4), (6, -3), (11, 2), (2, -7), (-6, -5), (4, 6)]
        for d in dots { c.ell(x + d.0 * s, y + d.1 * s, 0.9 * s, 0.6 * s, Color(hex: 0xD9BE7C)) }
        c.ell(x + 7 * s, y + 1 * s, 2 * s, 1.3 * s, Color(hex: 0xF7C5C9))
        c.ell(x + 7 * s, y + 1 * s, 0.9 * s, 0.6 * s, Color(hex: 0xE89AA3))
    }

    static func path(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        let stones: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [(-10, -1, 5, 2.6), (0, -5, 5.5, 2.8), (9, 0, 5, 2.5), (-1, 4, 5, 2.6), (10, -6, 3.5, 1.8), (-12, 4, 3.4, 1.7)]
        for st in stones {
            c.ell(x + st.0 * s, y + st.1 * s + 0.8 * s, st.2 * s, st.3 * s, Color(hex: 0x8F98A3))
            c.ell(x + st.0 * s, y + st.1 * s, st.2 * s, st.3 * s, Color(hex: 0xC7CDD4))
        }
    }

    static func meadow(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.fill(c.groundDiamondPath(x, y, s, 0.9), with: .color(Color(hex: 0x76C058)))
        let tufts: [(CGFloat, CGFloat)] = [(-12, 0), (-5, -5), (3, -3), (10, 1), (-2, 5), (6, 5), (14, -2), (-8, 3)]
        for (i, p) in tufts.enumerated() {
            let bx = x + p.0 * s, by = y + p.1 * s
            let sw: CGFloat = sin(t * 2 + CGFloat(i)) * 0.6 * s
            c.line(bx, by, bx - 1.2 * s + sw, by - 3.5 * s, Color(hex: 0x4E9A43), 0.8 * s)
            c.line(bx, by, bx + 1.2 * s + sw, by - 3.2 * s, Color(hex: 0x4E9A43), 0.8 * s)
            if i % 3 == 0 { c.ell(bx + sw, by - 4 * s, 1.1 * s, 1.1 * s, i % 2 == 0 ? .white : Color(hex: 0xFF8FB1)) }
        }
        for k in 0..<3 {
            let cx = x + CGFloat(k * 7 - 7) * s, cy = y + CGFloat(k % 2) * 3 * s - 1 * s
            c.ell(cx - 0.9 * s, cy, 1 * s, 0.8 * s, Color(hex: 0x3E8E3A))
            c.ell(cx + 0.9 * s, cy, 1 * s, 0.8 * s, Color(hex: 0x3E8E3A))
            c.ell(cx, cy - 0.9 * s, 1 * s, 0.8 * s, Color(hex: 0x3E8E3A))
        }
    }

    static func deck(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        let shape = c.groundDiamondPath(x, y, s, 0.96)
        c.fill(shape, with: .color(Color(hex: 0xC69A64)))
        var g = c
        g.clip(to: shape)
        for k in -5...5 {
            let ox = -CGFloat(k) * 5 * s, oy = CGFloat(k) * 2.5 * s
            g.line(x + ox - 30 * s, y + oy - 15 * s, x + ox + 30 * s, y + oy + 15 * s, Color(hex: 0x9C7148), 0.8 * s)
        }
        c.stroke(shape, with: .color(Color(hex: 0x9C7148)), lineWidth: 1 * s)
    }

    static func pond(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.ell(x, y, 23.5 * s, 12 * s, Color(hex: 0xE3D3A0))
        c.ell(x, y + 0.5 * s, 21 * s, 10.5 * s, Color(hex: 0x4FA8C9))
        c.ell(x - 2 * s, y - 1 * s, 15 * s, 6.5 * s, Color(hex: 0x6BC0DB))
        for i in 0..<3 {
            let fi = CGFloat(i)
            let sx = x - 10 * s + fi * 9 * s + sin(t + fi) * 1.5 * s
            let sy = y - 3 * s + fi * 2 * s
            c.line(sx, sy, sx + 4 * s, sy, Color.white.opacity(0.6), 0.8 * s)
        }
        let pads: [(CGFloat, CGFloat, CGFloat)] = [(-9, 2, 3.4), (6, -3, 2.8), (10, 4, 2.4)]
        for p in pads {
            let px = x + p.0 * s, py = y + p.1 * s
            c.ell(px, py, p.2 * s, p.2 * 0.55 * s, Color(hex: 0x5DAE4E))
            c.poly([P(px, py), P(px + p.2 * s, py - 0.6 * s), P(px + p.2 * s, py + 0.6 * s)], Color(hex: 0x4FA8C9))
        }
        c.ell(x - 9 * s, y + 0.5 * s, 1.5 * s, 1.2 * s, Color(hex: 0xFF8FB1))
        c.ell(x - 9 * s, y + 0.2 * s, 0.7 * s, 0.6 * s, Color(hex: 0xFFE07A))
    }
}
