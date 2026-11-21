import SwiftUI

/// Third batch of shop art (v1.2). Same conventions as `MoreArt`.
enum ExtraArt {
    static func draw(_ type: PropType, _ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat, night: CGFloat) {
        switch type {
        case .stump: stump(c, x, y, s)
        case .tulips: tulips(c, x, y, s, t)
        case .fern: fern(c, x, y, s, t)
        case .birch: birch(c, x, y, s, t)
        case .maple: maple(c, x, y, s, t)
        case .bonsai: bonsai(c, x, y, s)
        case .barrel: barrel(c, x, y, s)
        case .crates: crates(c, x, y, s)
        case .beachchair: beachchair(c, x, y, s)
        case .swing: swing(c, x, y, s, t)
        case .rowboat: rowboat(c, x, y, s, t)
        case .gazebo: gazebo(c, x, y, s, night)
        case .fountain: fountain(c, x, y, s, t)
        case .treehouse: treehouse(c, x, y, s, t, night)
        case .balloon: balloon(c, x, y, s, t)
        case .statue: statue(c, x, y, s, t)
        case .noticeboard: noticeboard(c, x, y, s)
        case .globe: globe(c, x, y, s, t)
        case .desk: desk(c, x, y, s, night)
        case .trophy: trophy(c, x, y, s, t)
        case .candles: candles(c, x, y, s, t)
        case .fairyarch: fairyarch(c, x, y, s, t, night)
        case .jackolantern: jackolantern(c, x, y, s, t, night)
        case .crystal: crystal(c, x, y, s, t)
        case .cobble: cobble(c, x, y, s)
        case .snow: snow(c, x, y, s, t)
        case .mosaic: mosaic(c, x, y, s)
        case .pennant: pennant(c, x, y, s, t)
        case .bell: bell(c, x, y, s, t)
        case .obelisk: obelisk(c, x, y, s, t)
        case .rainbow: rainbow(c, x, y, s, t)
        default: break
        }
    }

    // MARK: Nature

    static func stump(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        c.groundShadow(x, y, 11 * s)
        c.ell(x, y, 9 * s, 4 * s, Color(hex: 0x7A5233))
        c.rrect(x - 9 * s, y - 9 * s, 18 * s, 9 * s, 0, Color(hex: 0x8A5E3B))
        c.line(x - 4 * s, y - 8 * s, x - 4 * s, y + 1 * s, Color(hex: 0x6B4A2E), 0.8 * s)
        c.line(x + 3 * s, y - 8 * s, x + 3 * s, y + 2 * s, Color(hex: 0x6B4A2E), 0.8 * s)
        c.ell(x, y - 9 * s, 9 * s, 4 * s, Color(hex: 0xD9B98A))
        c.stroke(Path(ellipseIn: CGRect(x: x - 6 * s, y: y - 11.7 * s, width: 12 * s, height: 5.4 * s)), with: .color(Color(hex: 0xB89464)), lineWidth: 0.7 * s)
        c.stroke(Path(ellipseIn: CGRect(x: x - 3 * s, y: y - 10.3 * s, width: 6 * s, height: 2.6 * s)), with: .color(Color(hex: 0xB89464)), lineWidth: 0.7 * s)
        c.rrect(x + 7 * s, y - 3 * s, 1.6 * s, 3 * s, 0.6 * s, Color(hex: 0xF3E9D2))
        var cap = c
        cap.clip(to: Path(CGRect(x: x + 4.5 * s, y: y - 6.5 * s, width: 7 * s, height: 3.5 * s)))
        cap.ell(x + 7.8 * s, y - 3 * s, 3 * s, 3 * s, Color(hex: 0xE5483A))
    }

    static func tulips(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.ell(x, y, 13 * s, 5 * s, Color(hex: 0x6E4A2E, opacity: 0.55))
        let spots: [(CGFloat, CGFloat, UInt32)] = [(-8, -1, 0xE5483A), (-3, 2, 0xFFC93C), (2, -2, 0xFF8FB1), (7, 1, 0xE5483A), (-5, -4, 0xA77BDB), (4, -5, 0xFFC93C)]
        for (i, sp) in spots.enumerated() {
            let bx = x + sp.0 * s, by = y + sp.1 * s
            let sw: CGFloat = sin(t * 1.8 + CGFloat(i)) * 0.7 * s
            c.line(bx, by, bx + sw, by - 9 * s, Color(hex: 0x4E9A43), 1 * s)
            c.ell(bx + 1.6 * s, by - 3 * s, 1.8 * s, 0.8 * s, Color(hex: 0x5DAE4E))
            let hx = bx + sw, hy = by - 10.5 * s
            c.ell(hx, hy, 2.2 * s, 2.6 * s, Color(hex: sp.2))
            c.poly([P(hx - 2.2 * s, hy - 1 * s), P(hx - 1.1 * s, hy - 3.6 * s), P(hx, hy - 1.5 * s), P(hx + 1.1 * s, hy - 3.6 * s), P(hx + 2.2 * s, hy - 1 * s)], Color(hex: sp.2))
        }
    }

    static func fern(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 11 * s)
        let angles: [CGFloat] = [-2.7, -2.25, -1.85, -1.3, -0.9, -0.45]
        for (i, a) in angles.enumerated() {
            var g = c
            g.translateBy(x: x, y: y - 2 * s)
            g.rotate(by: .radians(Double(a + sin(t * 1.3 + CGFloat(i)) * 0.04)))
            g.line(0, 0, 16 * s, 0, Color(hex: 0x3E8E3A), 0.9 * s)
            for k in 1..<7 {
                let d = CGFloat(k) * 2.3 * s
                let leaf = (7 - CGFloat(k)) * 0.55 * s + 0.8 * s
                g.ell(d, -leaf * 0.6, leaf, 0.9 * s, i % 2 == 0 ? Color(hex: 0x4FA35E) : Color(hex: 0x5DB56A))
                g.ell(d, leaf * 0.6, leaf, 0.9 * s, Color(hex: 0x45984F))
            }
        }
    }

    static func birch(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 12 * s)
        let w: CGFloat = sin(t * 1.4 + x * 0.05) * 1.2 * s
        c.rrect(x - 2.2 * s, y - 34 * s, 4.4 * s, 35 * s, 1.5 * s, Color(hex: 0xF1EEE6))
        let marks: [CGFloat] = [6, 13, 19, 26, 31]
        for (i, m) in marks.enumerated() {
            let off: CGFloat = i % 2 == 0 ? -2.2 : 0.4
            c.rrect(x + off * s, y - m * s, 1.8 * s, 0.9 * s, 0.4 * s, Color(hex: 0x2E2A26))
        }
        c.ell(x + w * 0.6, y - 36 * s, 10 * s, 9 * s, Color(hex: 0x9CCB4E))
        c.ell(x - 6 * s + w, y - 31 * s, 7 * s, 6.5 * s, Color(hex: 0xB5D965))
        c.ell(x + 6 * s + w, y - 32 * s, 7 * s, 6.5 * s, Color(hex: 0x8DBE45))
        c.ell(x + w, y - 44 * s, 7 * s, 6 * s, Color(hex: 0xC9E57B))
    }

    static func maple(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 15 * s)
        let w: CGFloat = sin(t * 1.3 + x * 0.07) * 1.2 * s
        c.rrect(x - 3 * s, y - 20 * s, 6 * s, 21 * s, 2 * s, Color(hex: 0x6B4A2E))
        c.ell(x + w * 0.5, y - 31 * s, 16 * s, 13 * s, Color(hex: 0xD9541E))
        c.ell(x - 8 * s + w, y - 26 * s, 10 * s, 9 * s, Color(hex: 0xF08A24))
        c.ell(x + 8 * s + w, y - 27 * s, 10 * s, 9 * s, Color(hex: 0xC73E1D))
        c.ell(x + w, y - 39 * s, 11 * s, 9 * s, Color(hex: 0xF5B83D))
        let leafCols: [UInt32] = [0xF08A24, 0xD9541E, 0xF5B83D]
        for i in 0..<4 {
            let fi = CGFloat(i)
            let k: CGFloat = (t * 0.25 + fi * 0.25).truncatingRemainder(dividingBy: 1)
            let px = x + sin(fi * 2.4 + t * 1.5) * 14 * s
            let py = y - 30 * s + k * 32 * s
            c.ell(px, py, 1.6 * s, 1 * s, Color(hex: leafCols[i % 3], opacity: Double(1 - k)))
        }
        c.ell(x - 9 * s, y + 2 * s, 2 * s, 1 * s, Color(hex: 0xF08A24))
        c.ell(x + 7 * s, y + 3 * s, 2 * s, 1 * s, Color(hex: 0xD9541E))
    }

    static func bonsai(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        c.groundShadow(x, y, 11 * s)
        c.poly([P(x - 10 * s, y - 6 * s), P(x + 10 * s, y - 6 * s), P(x + 7 * s, y + 1 * s), P(x - 7 * s, y + 1 * s)], Color(hex: 0x3D5A80))
        c.rrect(x - 11 * s, y - 8 * s, 22 * s, 2.5 * s, 1 * s, Color(hex: 0x4A6D96))
        var trunk = Path()
        trunk.move(to: P(x - 1 * s, y - 7 * s))
        trunk.addCurve(to: P(x + 3 * s, y - 24 * s), control1: P(x - 7 * s, y - 13 * s), control2: P(x + 8 * s, y - 16 * s))
        c.stroke(trunk, with: .color(Color(hex: 0x6B4A2E)), style: StrokeStyle(lineWidth: 2.6 * s, lineCap: .round))
        c.line(x + 1 * s, y - 17 * s, x - 7 * s, y - 20 * s, Color(hex: 0x6B4A2E), 1.6 * s)
        c.ell(x - 8 * s, y - 21 * s, 6 * s, 2.6 * s, Color(hex: 0x3E8E3A))
        c.ell(x + 4 * s, y - 25 * s, 8 * s, 3.2 * s, Color(hex: 0x4FA35E))
        c.ell(x + 8 * s, y - 18 * s, 5 * s, 2.2 * s, Color(hex: 0x3E8E3A))
        c.ell(x + 3 * s, y - 27 * s, 4 * s, 1.4 * s, Color(hex: 0x6CB874))
    }

    // MARK: Cozy

    static func barrel(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        c.groundShadow(x, y, 9 * s)
        c.ell(x, y, 7 * s, 3 * s, Color(hex: 0x8A5E33))
        c.rrect(x - 7 * s, y - 16 * s, 14 * s, 16 * s, 2 * s, Color(hex: 0xA0703F))
        c.rrect(x - 7 * s, y - 16 * s, 3 * s, 16 * s, 1 * s, Color(hex: 0xB98451))
        for band in [CGFloat(3), CGFloat(13)] {
            c.rrect(x - 7.3 * s, y - band * s - 0.8 * s, 14.6 * s, 1.6 * s, 0.5 * s, Color(hex: 0x4A4E57))
        }
        c.ell(x, y - 16 * s, 7 * s, 3 * s, Color(hex: 0x8A5E33))
        c.ell(x, y - 16 * s, 5.5 * s, 2.2 * s, Color(hex: 0x4F8FB0))
    }

    static func crates(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        c.groundShadow(x, y, 15 * s)
        c.isoBox(x - 5 * s, y + 1 * s, 8 * s, 9 * s, top: Color(hex: 0xD9A866), left: Color(hex: 0xC08A55), right: Color(hex: 0xA0703F))
        c.isoBox(x + 6 * s, y + 1 * s, 7 * s, 8 * s, top: Color(hex: 0xD9A866), left: Color(hex: 0xC08A55), right: Color(hex: 0xA0703F))
        c.isoBox(x - 2 * s, y - 9 * s, 6.5 * s, 7 * s, top: Color(hex: 0xE2B676), left: Color(hex: 0xC9955E), right: Color(hex: 0xAA7845))
        c.line(x - 13 * s, y - 4 * s, x - 5 * s, y, Color(hex: 0x8A5E33), 0.8 * s)
        c.line(x + 6 * s, y + 4.5 * s, x + 13 * s, y + 1 * s, Color(hex: 0x8A5E33), 0.8 * s)
    }

    static func beachchair(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        c.groundShadow(x, y, 13 * s)
        let g = c.skewed(x, y + 2 * s)
        let frame = Color(hex: 0xB98D5E)
        g.line(-10 * s, 0, -4 * s, -18 * s, frame, 1.4 * s)
        g.line(10 * s, 0, 4 * s, -18 * s, frame, 1.4 * s)
        g.line(-10 * s, -6 * s, 10 * s, -6 * s, frame, 1.4 * s)
        g.poly([P(-9 * s, -6 * s), P(9 * s, -6 * s), P(5 * s, -18 * s), P(-5 * s, -18 * s)], Color(hex: 0x5BC0EB))
        g.poly([P(-3 * s, -6 * s), P(3 * s, -6 * s), P(1.7 * s, -18 * s), P(-1.7 * s, -18 * s)], .white)
        c.ell(x + 10 * s, y + 3 * s, 3 * s, 1.5 * s, Color(hex: 0xF2C14E))
    }

    static func swing(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 16 * s)
        let g = c.skewed(x, y + 2 * s)
        let wood = Color(hex: 0x8A5E33)
        g.line(-15 * s, 0, -11 * s, -32 * s, wood, 1.8 * s)
        g.line(-7 * s, 0, -11 * s, -32 * s, wood, 1.8 * s)
        g.line(15 * s, 0, 11 * s, -32 * s, wood, 1.8 * s)
        g.line(7 * s, 0, 11 * s, -32 * s, wood, 1.8 * s)
        g.line(-12 * s, -32 * s, 12 * s, -32 * s, Color(hex: 0x6B4A2E), 2 * s)
        let a: CGFloat = sin(t * 2.2) * 0.35
        var seat = g
        seat.translateBy(x: 0, y: -32 * s)
        seat.rotate(by: .radians(Double(a)))
        seat.line(-4 * s, 0, -4 * s, 24 * s, Color(hex: 0xD9C7A3), 0.8 * s)
        seat.line(4 * s, 0, 4 * s, 24 * s, Color(hex: 0xD9C7A3), 0.8 * s)
        seat.rrect(-5.5 * s, 23 * s, 11 * s, 2.5 * s, 1 * s, Color(hex: 0xE5483A))
    }

    static func rowboat(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y + 1 * s, 17 * s)
        let rock: CGFloat = sin(t * 1.5) * 0.6 * s
        var hull = Path()
        hull.move(to: P(x - 17 * s, y - 6 * s + rock))
        hull.addQuadCurve(to: P(x + 17 * s, y - 6 * s - rock), control: P(x, y + 6 * s))
        hull.addQuadCurve(to: P(x - 17 * s, y - 6 * s + rock), control: P(x, y - 13 * s))
        c.fill(hull, with: .color(Color(hex: 0x4A7BD0)))
        c.ell(x, y - 6 * s, 14 * s, 3.6 * s, Color(hex: 0xC08A55))
        c.rrect(x - 1.5 * s, y - 9 * s, 3 * s, 6 * s, 0.5 * s, Color(hex: 0x8A5E33))
        c.line(x - 8 * s, y - 9 * s, x - 3 * s, y + 4 * s, Color(hex: 0x8A5E33), 1.2 * s)
        c.line(x + 9 * s, y - 10 * s, x + 4 * s, y + 3 * s, Color(hex: 0x8A5E33), 1.2 * s)
        c.line(x - 15 * s, y - 6 * s, x + 15 * s, y - 6 * s, .white.opacity(0.7), 0.8 * s)
    }

    // MARK: Landmarks

    static func gazebo(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ night: CGFloat) {
        c.groundShadow(x, y, 24 * s)
        c.ell(x, y, 22 * s, 10 * s, Color(hex: 0xD9CBB0))
        c.ell(x, y - 2 * s, 22 * s, 10 * s, Color(hex: 0xEDE3CF))
        let posts: [(CGFloat, CGFloat)] = [(-18, -2), (18, -2), (-8, 5), (8, 5)]
        c.rrect(x - 1.2 * s, y - 34 * s, 2.4 * s, 26 * s, 1 * s, Color(hex: 0xF4F1EA))
        for p in posts {
            c.rrect(x + p.0 * s - 1.4 * s, y + p.1 * s - 30 * s, 2.8 * s, 28 * s, 1 * s, Color(hex: 0xF4F1EA))
        }
        c.rrect(x - 1.6 * s, y - 28 * s, 3.2 * s, 4 * s, 1 * s, night > 0.3 ? Color(hex: 0xFFE58A) : Color(hex: 0xE9D7A0))
        c.poly([P(x - 25 * s, y - 31 * s), P(x + 25 * s, y - 31 * s), P(x, y - 50 * s)], Color(hex: 0x5E8F6E))
        c.poly([P(x, y - 31 * s), P(x + 25 * s, y - 31 * s), P(x, y - 50 * s)], Color(hex: 0x4E7D5E))
        c.ell(x, y - 31 * s, 25 * s, 3 * s, Color(hex: 0x4E7D5E))
        c.ell(x, y - 51 * s, 1.6 * s, 1.6 * s, Color(hex: 0xC9A227))
    }

    static func fountain(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 20 * s)
        c.ell(x, y, 20 * s, 9 * s, Color(hex: 0x9AA3AD))
        c.rrect(x - 20 * s, y - 6 * s, 40 * s, 6 * s, 0, Color(hex: 0x9AA3AD))
        c.ell(x, y - 6 * s, 20 * s, 9 * s, Color(hex: 0xC3C9D0))
        c.ell(x, y - 6 * s, 17 * s, 7.4 * s, Color(hex: 0x4FA8C9))
        c.ell(x - 3 * s, y - 7 * s, 10 * s, 3.5 * s, Color(hex: 0x6BC0DB))
        c.rrect(x - 2.5 * s, y - 24 * s, 5 * s, 18 * s, 1 * s, Color(hex: 0xB4BCC6))
        c.ell(x, y - 24 * s, 8 * s, 3 * s, Color(hex: 0xC3C9D0))
        c.ell(x, y - 24.5 * s, 6 * s, 2 * s, Color(hex: 0x6BC0DB))
        for i in 0..<10 {
            let fi = CGFloat(i)
            let k: CGFloat = (t * 0.9 + fi / 10).truncatingRemainder(dividingBy: 1)
            let dir: CGFloat = i % 2 == 0 ? 1 : -1
            let spread = (1 + fi.truncatingRemainder(dividingBy: 3)) * 3 * s
            let px = x + dir * k * spread * 2.2
            let py = y - 26 * s - sin(k * .pi) * 9 * s + k * k * 16 * s
            c.ell(px, py, 1 * s, 1.3 * s, Color(hex: 0xBFE6F2, opacity: Double(1 - k * 0.6)))
        }
        c.ell(x, y - 30 * s, 1.6 * s, 3 * s, Color(hex: 0xBFE6F2, opacity: 0.9))
    }

    static func treehouse(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat, _ night: CGFloat) {
        c.groundShadow(x, y, 20 * s)
        c.rrect(x - 4 * s, y - 40 * s, 8 * s, 41 * s, 2.5 * s, Ink.trunk)
        c.line(x - 3 * s, y - 30 * s, x - 13 * s, y - 40 * s, Ink.trunk, 2.4 * s)
        // ladder
        c.line(x + 8 * s, y + 1 * s, x + 6 * s, y - 34 * s, Color(hex: 0xB98D5E), 1 * s)
        c.line(x + 12 * s, y, x + 10 * s, y - 34 * s, Color(hex: 0xB98D5E), 1 * s)
        var rung: CGFloat = 4
        while rung < 34 {
            c.line(x + 8 * s - rung * 0.06 * s, y - rung * s, x + 12 * s - rung * 0.06 * s, y - rung * s - 0.5 * s, Color(hex: 0xB98D5E), 0.9 * s)
            rung += 5
        }
        let w: CGFloat = sin(t * 1.2) * 1 * s
        c.ell(x - 10 * s + w, y - 52 * s, 14 * s, 11 * s, Ink.leafDark)
        c.ell(x + 12 * s + w, y - 54 * s, 12 * s, 10 * s, Ink.leafMid)
        // house
        c.isoBox(x, y - 34 * s, 13 * s, 12 * s, top: Color(hex: 0xC99560), left: Color(hex: 0xC08A55), right: Color(hex: 0xA0703F))
        c.poly([P(x - 15 * s, y - 46 * s), P(x + 15 * s, y - 46 * s), P(x, y - 60 * s)], Color(hex: 0xB5523B))
        c.poly([P(x, y - 46 * s), P(x + 15 * s, y - 46 * s), P(x, y - 60 * s)], Color(hex: 0x9E4530))
        c.rrect(x - 9 * s, y - 43 * s, 5 * s, 5 * s, 1 * s, night > 0.3 ? Color(hex: 0xFFD27A) : Color(hex: 0x9CC9F0))
        c.ell(x + w + 2 * s, y - 64 * s, 11 * s, 7 * s, Ink.leafLight)
        c.line(x - 14 * s, y - 34 * s, x + 14 * s, y - 34 * s, Color(hex: 0x8A5E33), 1.6 * s)
    }

    static func balloon(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        let bob: CGFloat = sin(t * 1.1) * 3 * s
        c.ell(x, y + 1 * s, 10 * s - bob * 0.3, 4 * s, Color(hex: 0x14321E, opacity: 0.14))
        let by = y - 22 * s + bob
        // ropes + basket
        c.line(x - 4 * s, by - 2 * s, x - 9 * s, by - 18 * s, Color(hex: 0x6B4A2E), 0.7 * s)
        c.line(x + 4 * s, by - 2 * s, x + 9 * s, by - 18 * s, Color(hex: 0x6B4A2E), 0.7 * s)
        c.isoBox(x, by, 5 * s, 5 * s, top: Color(hex: 0x8A5E33), left: Color(hex: 0xC08A55), right: Color(hex: 0xA0703F))
        c.flame(x, by - 9 * s, 4 * s, 1.6 * s, Color(hex: 0xFFC247), t, 1)
        // envelope with stripes
        let cy = by - 34 * s
        var env = Path()
        env.move(to: P(x - 9 * s, cy + 15 * s))
        env.addCurve(to: P(x, cy - 19 * s), control1: P(x - 26 * s, cy + 2 * s), control2: P(x - 20 * s, cy - 19 * s))
        env.addCurve(to: P(x + 9 * s, cy + 15 * s), control1: P(x + 20 * s, cy - 19 * s), control2: P(x + 26 * s, cy + 2 * s))
        env.closeSubpath()
        c.fill(env, with: .color(Color(hex: 0xE5483A)))
        var stripes = c
        stripes.clip(to: env)
        let cols: [UInt32] = [0xFFC93C, 0xF4F1EA, 0x5B8DEF]
        for (i, dx) in [CGFloat(-11), CGFloat(-2), CGFloat(7)].enumerated() {
            stripes.ell(x + dx * s, cy, 3 * s, 22 * s, Color(hex: cols[i]))
        }
        stripes.ell(x + 8 * s, cy - 2 * s, 14 * s, 20 * s, Color.black.opacity(0.1))
    }

    static func statue(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 15 * s)
        c.isoBox(x, y, 13 * s, 10 * s, top: Color(hex: 0xD6DBE1), left: Color(hex: 0xB4BCC6), right: Color(hex: 0x9AA3AD))
        c.rrect(x - 6 * s, y - 2 * s, 7 * s, 2 * s, 0.5 * s, Color(hex: 0xC9A227))
        var gold = c
        gold.addFilter(.colorMultiply(Color(hex: 0xFFD54A)))
        gold.addFilter(.brightness(0.12))
        MoleArt.draw(gold, x, y - 10 * s, s * 1.15, MolePose(t: 0.5, cheering: true))
        for i in 0..<3 {
            let fi = CGFloat(i)
            let k: CGFloat = (t * 0.7 + fi / 3).truncatingRemainder(dividingBy: 1)
            let a = Double(sin(k * .pi))
            let px = x + (fi - 1) * 10 * s
            let py = y - 30 * s - fi * 6 * s
            c.ell(px, py, 1.6 * s * CGFloat(a), 1.6 * s * CGFloat(a), Color(hex: 0xFFF6C8, opacity: a))
        }
    }

    // MARK: Study

    static func noticeboard(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        c.groundShadow(x, y, 12 * s)
        let g = c.skewed(x, y + 2 * s)
        g.rrect(-12 * s, -14 * s, 2.5 * s, 14 * s, 1 * s, Ink.trunk)
        g.rrect(9.5 * s, -14 * s, 2.5 * s, 14 * s, 1 * s, Ink.trunk)
        g.rrect(-14 * s, -32 * s, 28 * s, 19 * s, 1.5 * s, Color(hex: 0x8A5E33))
        g.rrect(-12.5 * s, -30.5 * s, 25 * s, 16 * s, 1 * s, Color(hex: 0xD9A866))
        let notes: [(CGFloat, CGFloat, UInt32)] = [(-10.5, -29, 0xFFF3A6), (-2.5, -28, 0xBFE6F2), (5, -29.5, 0xF7B6C8), (-6, -21.5, 0xC8E9A0), (3, -21, 0xFFF3A6)]
        for n in notes {
            g.rrect(n.0 * s, n.1 * s, 6 * s, 6 * s, 0.4 * s, Color(hex: n.2))
            g.ell(n.0 * s + 3 * s, n.1 * s + 0.8 * s, 0.7 * s, 0.7 * s, Color(hex: 0xE5483A))
            g.line(n.0 * s + 1 * s, n.1 * s + 3 * s, n.0 * s + 5 * s, n.1 * s + 3 * s, Color.black.opacity(0.3), 0.4 * s)
        }
    }

    static func globe(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 9 * s)
        c.ell(x, y - 1 * s, 7 * s, 2.6 * s, Color(hex: 0x6B4A2E))
        c.rrect(x - 1 * s, y - 10 * s, 2 * s, 9 * s, 0.5 * s, Color(hex: 0x6B4A2E))
        let cy = y - 20 * s
        var arc = Path()
        arc.addArc(center: P(x, cy), radius: 11 * s, startAngle: .degrees(100), endAngle: .degrees(280), clockwise: false)
        c.stroke(arc, with: .color(Color(hex: 0xC9A227)), lineWidth: 1.4 * s)
        let sphere = Path(ellipseIn: CGRect(x: x - 9 * s, y: cy - 9 * s, width: 18 * s, height: 18 * s))
        c.fill(sphere, with: .color(Color(hex: 0x4F8FD6)))
        var land = c
        land.clip(to: sphere)
        let off: CGFloat = (t * 4).truncatingRemainder(dividingBy: 36) * s
        for base in [CGFloat(-18), CGFloat(18)] {
            land.ell(x - 9 * s + off + base * s, cy - 3 * s, 4 * s, 3 * s, Color(hex: 0x6CC24A))
            land.ell(x - 2 * s + off + base * s, cy + 4 * s, 3 * s, 2.4 * s, Color(hex: 0x6CC24A))
            land.ell(x + 6 * s + off + base * s, cy - 5 * s, 2.5 * s, 2 * s, Color(hex: 0x6CC24A))
        }
        land.ell(x + 4 * s, cy + 2 * s, 9 * s, 9 * s, Color.black.opacity(0.12))
        c.ell(x - 3.5 * s, cy - 4 * s, 2 * s, 1.4 * s, .white.opacity(0.55))
    }

    static func desk(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ night: CGFloat) {
        c.groundShadow(x, y, 16 * s)
        c.isoBox(x, y + 1 * s, 15 * s, 12 * s, top: Color(hex: 0xC99560), left: Color(hex: 0xA0703F), right: Color(hex: 0x8A5E33))
        let g = c.skewed(x + 2 * s, y - 11 * s)
        g.rrect(-6 * s, -9 * s, 12 * s, 8 * s, 1 * s, Color(hex: 0x3C3F46))
        g.rrect(-5 * s, -8 * s, 10 * s, 6 * s, 0.6 * s, night > 0.3 ? Color(hex: 0x9CC9F0) : Color(hex: 0x6BA4D9))
        g.rrect(-7 * s, -1 * s, 14 * s, 1.5 * s, 0.5 * s, Color(hex: 0x8E96A0))
        c.rrect(x - 11 * s, y - 15 * s, 3.2 * s, 4 * s, 1 * s, .white)
        c.ell(x - 9.4 * s, y - 15 * s, 1.6 * s, 0.6 * s, Color(hex: 0x6B4A2E))
        c.line(x + 10 * s, y - 12 * s, x + 9 * s, y - 22 * s, Color(hex: 0x3C3F46), 1 * s)
        c.poly([P(x + 6 * s, y - 21 * s), P(x + 11 * s, y - 24 * s), P(x + 12 * s, y - 21 * s)], Color(hex: 0x3C3F46))
    }

    static func trophy(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 11 * s)
        c.isoBox(x, y, 9 * s, 11 * s, top: Color(hex: 0x5A3D25), left: Color(hex: 0x6B4A2E), right: Color(hex: 0x4A3220))
        let gold = Color(hex: 0xF2C14E), dark = Color(hex: 0xD9A22C)
        c.rrect(x - 4 * s, y - 15 * s, 8 * s, 2 * s, 0.6 * s, dark)
        c.rrect(x - 1 * s, y - 20 * s, 2 * s, 5 * s, 0.6 * s, gold)
        c.poly([P(x - 7 * s, y - 33 * s), P(x + 7 * s, y - 33 * s), P(x + 4 * s, y - 22 * s), P(x - 4 * s, y - 22 * s)], gold)
        c.ell(x, y - 21 * s, 4 * s, 2 * s, gold)
        c.stroke(Path(ellipseIn: CGRect(x: x - 11 * s, y: y - 32 * s, width: 6 * s, height: 7 * s)), with: .color(dark), lineWidth: 1.2 * s)
        c.stroke(Path(ellipseIn: CGRect(x: x + 5 * s, y: y - 32 * s, width: 6 * s, height: 7 * s)), with: .color(dark), lineWidth: 1.2 * s)
        c.ell(x, y - 33 * s, 7 * s, 1.6 * s, dark)
        c.rrect(x - 4.5 * s, y - 31 * s, 1.5 * s, 7 * s, 0.7 * s, .white.opacity(0.5))
        let tw = Double(0.5 + 0.5 * sin(t * 3))
        c.ell(x + 6 * s, y - 36 * s, 1.4 * s, 1.4 * s, Color.white.opacity(tw))
    }

    // MARK: Lights

    static func candles(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.ell(x, y, 10 * s, 4 * s, Color(hex: 0x14321E, opacity: 0.15))
        let list: [(CGFloat, CGFloat, CGFloat)] = [(-5, -1, 10), (1, -3, 14), (5, 2, 7), (-1, 3, 5)]
        for (i, cd) in list.enumerated() {
            let cx = x + cd.0 * s, cy = y + cd.1 * s
            c.ell(cx, cy, 2.4 * s, 1 * s, Color(hex: 0xE9DFC8))
            c.rrect(cx - 2.4 * s, cy - cd.2 * s, 4.8 * s, cd.2 * s, 0.6 * s, Color(hex: 0xF7F0DE))
            c.ell(cx, cy - cd.2 * s, 2.4 * s, 1 * s, Color(hex: 0xFFF8E8))
            c.flame(cx, cy - cd.2 * s - 1 * s, 4 * s, 1.4 * s, Color(hex: 0xFFC247), t, CGFloat(i))
            c.flame(cx, cy - cd.2 * s - 1 * s, 2 * s, 0.7 * s, Color(hex: 0xFFF1B0), t, CGFloat(i) + 1)
        }
    }

    static func fairyarch(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat, _ night: CGFloat) {
        c.groundShadow(x, y, 15 * s)
        let g = c.skewed(x, y + 2 * s)
        let p0 = P(-13 * s, 0), p1 = P(0, -46 * s), p2 = P(13 * s, 0)
        var arch = Path()
        arch.move(to: p0)
        arch.addQuadCurve(to: p2, control: p1)
        g.stroke(arch, with: .color(Color(hex: 0x5E8F2F)), style: StrokeStyle(lineWidth: 2.4 * s, lineCap: .round))
        let cols: [UInt32] = [0xFFE58A, 0xFF8FB1, 0x9CC9F0, 0xC8E9A0, 0xFFC247]
        for i in 0..<13 {
            let u = CGFloat(i) / 12
            let px = (1 - u) * (1 - u) * p0.x + 2 * (1 - u) * u * p1.x + u * u * p2.x
            let py = (1 - u) * (1 - u) * p0.y + 2 * (1 - u) * u * p1.y + u * u * p2.y
            g.ell(px, py, 1.6 * s, 1.6 * s, Color(hex: 0x4E9A43))
            let tw = 0.55 + 0.45 * sin(t * 3 + CGFloat(i) * 1.7)
            let lit = Double(0.45 + 0.55 * night) * Double(tw)
            g.ell(px, py + 1.4 * s, 1.1 * s, 1.1 * s, Color(hex: cols[i % cols.count], opacity: max(0.5, lit)))
        }
    }

    static func jackolantern(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat, _ night: CGFloat) {
        c.groundShadow(x, y, 10 * s)
        let py = y - 7 * s
        c.ell(x, py, 10 * s, 7.5 * s, Color(hex: 0xF28C28))
        c.ell(x, py, 4.5 * s, 7.4 * s, Color(hex: 0xF7A043))
        c.stroke(Path(ellipseIn: CGRect(x: x - 6.5 * s, y: py - 7.5 * s, width: 13 * s, height: 15 * s)), with: .color(Color(hex: 0xD96E12)), lineWidth: 0.7 * s)
        c.rrect(x - 1 * s, py - 10.5 * s, 2 * s, 4 * s, 0.8 * s, Color(hex: 0x5E8F2F))
        let flick = 0.85 + 0.15 * sin(t * 10)
        let glow = night > 0.25 ? Color(hex: 0xFFE07A, opacity: Double(flick)) : Color(hex: 0x6B2E0E)
        c.poly([P(x - 6 * s, py - 1 * s), P(x - 2.5 * s, py - 1 * s), P(x - 4.2 * s, py - 4.5 * s)], glow)
        c.poly([P(x + 2.5 * s, py - 1 * s), P(x + 6 * s, py - 1 * s), P(x + 4.2 * s, py - 4.5 * s)], glow)
        var mouth = Path()
        mouth.move(to: P(x - 6 * s, py + 2 * s))
        mouth.addQuadCurve(to: P(x + 6 * s, py + 2 * s), control: P(x, py + 8 * s))
        mouth.addQuadCurve(to: P(x - 6 * s, py + 2 * s), control: P(x, py + 4.5 * s))
        c.fill(mouth, with: .color(glow))
    }

    static func crystal(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 11 * s)
        c.ell(x, y, 10 * s, 4 * s, Ink.stone)
        let pulse = Double(0.75 + 0.25 * sin(t * 2))
        let shards: [(CGFloat, CGFloat, CGFloat, UInt32, UInt32)] = [(-6, 16, 4, 0x8E6BE0, 0xB79CF5), (6, 18, 4, 0x6B8BE0, 0x9CB5F5), (0, 28, 5.5, 0xA77BDB, 0xD2B8FF)]
        for sh in shards {
            let bx = x + sh.0 * s, h = sh.1 * s, w = sh.2 * s
            c.poly([P(bx - w, y - 1 * s), P(bx, y + 1 * s), P(bx, y - h), P(bx - w * 0.8, y - h * 0.8)], Color(hex: sh.3, opacity: pulse))
            c.poly([P(bx, y + 1 * s), P(bx + w, y - 1 * s), P(bx + w * 0.8, y - h * 0.8), P(bx, y - h)], Color(hex: sh.4, opacity: pulse))
            c.poly([P(bx - w * 0.8, y - h * 0.8), P(bx, y - h), P(bx + w * 0.8, y - h * 0.8), P(bx, y - h - 3 * s)], Color(hex: 0xEDE2FF, opacity: pulse))
        }
    }

    // MARK: Terrain

    static func cobble(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        let shape = c.groundDiamondPath(x, y, s, 0.96)
        c.fill(shape, with: .color(Color(hex: 0x8F98A3)))
        var g = c
        g.clip(to: shape)
        for r in -4...4 {
            for col in -6...6 {
                let ox = CGFloat(col) * 5 * s + CGFloat(r % 2) * 2.5 * s
                let oy = CGFloat(r) * 3.2 * s
                let shade: UInt32 = (r + col) % 3 == 0 ? 0xC7CDD4 : ((r + col) % 3 == 1 ? 0xB4BCC6 : 0xA9B0B9)
                g.ell(x + ox, y + oy, 2.2 * s, 1.3 * s, Color(hex: shade))
            }
        }
    }

    static func snow(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.fill(c.groundDiamondPath(x, y, s, 0.95), with: .color(Color(hex: 0xF4F8FC)))
        c.ell(x - 6 * s, y + 2 * s, 7 * s, 2.5 * s, Color(hex: 0xDDE8F3))
        c.ell(x + 7 * s, y - 2 * s, 5 * s, 2 * s, Color(hex: 0xDDE8F3))
        for i in 0..<4 {
            let fi = CGFloat(i)
            let a = Double(0.5 + 0.5 * sin(t * 2.5 + fi * 1.9))
            c.ell(x + (fi * 7 - 10) * s, y + (fi.truncatingRemainder(dividingBy: 2) * 4 - 2) * s, 0.8 * s, 0.8 * s, Color.white.opacity(a))
        }
        c.ell(x + 2 * s, y - 2 * s, 2.6 * s, 2.2 * s, .white)
        c.ell(x + 2 * s, y - 5.5 * s, 1.8 * s, 1.6 * s, .white)
        c.ell(x + 2.6 * s, y - 5.4 * s, 0.6 * s, 0.3 * s, Color(hex: 0xFF8A3D))
    }

    static func mosaic(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        let shape = c.groundDiamondPath(x, y, s, 0.96)
        c.fill(shape, with: .color(Color(hex: 0xF4F1EA)))
        let cols: [UInt32] = [0x5B8DEF, 0xF2A541, 0x3FB47A, 0xE5675A, 0xA77BDB, 0x7FD3D8]
        let n = 4
        let hw: CGFloat = 28 * s * 0.96 / CGFloat(n), hh: CGFloat = hw / 2
        for r in 0..<n {
            for col in 0..<n {
                let cx = x + CGFloat(col - r) * hw
                let cy = y - 14 * s * 0.96 + CGFloat(col + r + 1) * hh
                let pts = [P(cx, cy - hh * 0.8), P(cx + hw * 0.8, cy), P(cx, cy + hh * 0.8), P(cx - hw * 0.8, cy)]
                c.poly(pts, Color(hex: cols[(r * 2 + col * 3) % cols.count]))
            }
        }
    }

    // MARK: Trophies

    static func pennant(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 8 * s)
        c.ell(x, y, 5 * s, 2.2 * s, Color(hex: 0x8F98A3))
        c.line(x, y, x, y - 38 * s, Color(hex: 0xC9A227), 1.6 * s)
        c.ell(x, y - 39 * s, 1.6 * s, 1.6 * s, Color(hex: 0xF2C14E))
        var flag = Path()
        let w1: CGFloat = sin(t * 4) * 2 * s, w2: CGFloat = sin(t * 4 + 1.2) * 2.5 * s
        flag.move(to: P(x, y - 37 * s))
        flag.addQuadCurve(to: P(x + 18 * s, y - 31 * s + w2), control: P(x + 9 * s, y - 37 * s + w1))
        flag.addQuadCurve(to: P(x, y - 24 * s), control: P(x + 9 * s, y - 26 * s + w1))
        flag.closeSubpath()
        c.fill(flag, with: .color(Color(hex: 0xE5483A)))
        c.draw(Text("7").font(.system(size: max(1, 6 * s), weight: .black, design: .rounded)).foregroundColor(.white),
               at: P(x + 6 * s, y - 30.5 * s + w1 * 0.5))
    }

    static func bell(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 13 * s)
        c.rrect(x - 12 * s, y - 32 * s, 3 * s, 32 * s, 1 * s, Ink.trunk)
        c.rrect(x + 9 * s, y - 32 * s, 3 * s, 32 * s, 1 * s, Ink.trunk)
        c.poly([P(x - 15 * s, y - 31 * s), P(x + 15 * s, y - 31 * s), P(x, y - 42 * s)], Color(hex: 0xB5523B))
        var g = c
        g.translateBy(x: x, y: y - 30 * s)
        g.rotate(by: .radians(Double(sin(t * 2.2) * 0.15)))
        var body = Path()
        body.move(to: P(-3 * s, 1 * s))
        body.addQuadCurve(to: P(-7 * s, 13 * s), control: P(-5 * s, 6 * s))
        body.addLine(to: P(7 * s, 13 * s))
        body.addQuadCurve(to: P(3 * s, 1 * s), control: P(5 * s, 6 * s))
        body.closeSubpath()
        g.fill(body, with: .color(Color(hex: 0xF2C14E)))
        g.rrect(-7.5 * s, 12 * s, 15 * s, 2 * s, 1 * s, Color(hex: 0xD9A22C))
        g.ell(0, 15 * s, 1.6 * s, 1.6 * s, Color(hex: 0x8A6A1A))
        g.rrect(-1.5 * s, 3 * s, 1.5 * s, 7 * s, 0.7 * s, Color.white.opacity(0.5))
    }

    static func obelisk(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 12 * s)
        c.isoBox(x, y, 11 * s, 4 * s, top: Color(hex: 0xD6DBE1), left: Color(hex: 0xB4BCC6), right: Color(hex: 0x9AA3AD))
        c.poly([P(x - 6 * s, y - 4 * s), P(x, y - 1 * s), P(x, y - 44 * s), P(x - 4 * s, y - 42 * s)], Color(hex: 0x3B4A6B))
        c.poly([P(x, y - 1 * s), P(x + 6 * s, y - 4 * s), P(x + 4 * s, y - 42 * s), P(x, y - 44 * s)], Color(hex: 0x2C3854))
        c.poly([P(x - 4 * s, y - 42 * s), P(x, y - 44 * s), P(x + 4 * s, y - 42 * s), P(x, y - 50 * s)], Color(hex: 0x7FD3F0))
        let pulse = Double(0.6 + 0.4 * sin(t * 1.8))
        for k in 0..<4 {
            let yy = y - (10 + CGFloat(k) * 8) * s
            c.line(x - 3.5 * s, yy, x + 3.5 * s, yy - 1 * s, Color(hex: 0x7FD3F0, opacity: pulse), 1 * s)
        }
    }

    static func rainbow(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.ell(x - 16 * s, y, 6 * s, 3 * s, .white)
        c.ell(x + 16 * s, y, 6 * s, 3 * s, .white)
        let g = c.skewed(x, y)
        let cols: [UInt32] = [0xE5483A, 0xF28C28, 0xFFC93C, 0x6CC24A, 0x5B8DEF, 0xA77BDB]
        for (i, col) in cols.enumerated() {
            let r = (19 - CGFloat(i) * 2.2) * s
            var arc = Path()
            arc.addArc(center: P(0, 0), radius: r, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
            g.stroke(arc, with: .color(Color(hex: col)), lineWidth: 2.3 * s)
        }
        for k in 0..<3 {
            let fk = CGFloat(k)
            let a = Double(0.5 + 0.5 * sin(t * 3 + fk * 2))
            c.ell(x - 10 * s + fk * 10 * s, y - 24 * s - fk * 2 * s, 1.2 * s, 1.2 * s, Color.white.opacity(a))
        }
        c.ell(x - 16 * s, y - 2 * s, 7 * s, 3.5 * s, .white)
        c.ell(x + 16 * s, y - 2 * s, 7 * s, 3.5 * s, .white)
    }
}
