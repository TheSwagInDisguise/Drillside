import SwiftUI

/// Small drawing vocabulary on top of SwiftUI's GraphicsContext, mirroring the HTML mock-up.
extension GraphicsContext {
    func ell(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ color: Color) {
        let w = max(0.1, rx) * 2
        let h = max(0.1, ry) * 2
        fill(Path(ellipseIn: CGRect(x: x - w / 2, y: y - h / 2, width: w, height: h)), with: .color(color))
    }

    func poly(_ pts: [CGPoint], _ color: Color) {
        var p = Path()
        p.addLines(pts)
        p.closeSubpath()
        fill(p, with: .color(color))
    }

    func polyStroke(_ pts: [CGPoint], _ color: Color, _ width: CGFloat) {
        var p = Path()
        p.addLines(pts)
        p.closeSubpath()
        stroke(p, with: .color(color), lineWidth: width)
    }

    func rrect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat, _ color: Color) {
        fill(Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r), with: .color(color))
    }

    func line(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat, _ color: Color, _ width: CGFloat) {
        var p = Path()
        p.move(to: CGPoint(x: x1, y: y1))
        p.addLine(to: CGPoint(x: x2, y: y2))
        stroke(p, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    func groundShadow(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) {
        ell(x, y + 1, r, r * 0.45, Color(hex: 0x14321E, opacity: 0.18))
    }

    /// Isometric box whose footprint is centred on (x, y).
    func isoBox(_ x: CGFloat, _ y: CGFloat, _ hx: CGFloat, _ h: CGFloat, top: Color, left: Color, right: Color) {
        let hy = hx / 2
        poly([P(x - hx, y - h), P(x, y - h + hy), P(x, y + hy), P(x - hx, y)], left)
        poly([P(x, y - h + hy), P(x + hx, y - h), P(x + hx, y), P(x, y + hy)], right)
        poly([P(x, y - h - hy), P(x + hx, y - h), P(x, y - h + hy), P(x - hx, y - h)], top)
    }
}

extension GraphicsContext {
    /// Context translated to (x, y) and sheared so flat shapes read as an isometric face (facing down-right).
    func skewed(_ x: CGFloat, _ y: CGFloat) -> GraphicsContext {
        var g = self
        g.translateBy(x: x, y: y)
        g.concatenate(CGAffineTransform(a: 1, b: -0.5, c: 0, d: 1, tx: 0, ty: 0))
        return g
    }

    func groundDiamondPath(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ k: CGFloat) -> Path {
        let hw = 28 * s * k, hh = 14 * s * k
        var p = Path()
        p.addLines([P(x, y - hh), P(x + hw, y), P(x, y + hh), P(x - hw, y)])
        p.closeSubpath()
        return p
    }

    func flame(_ fx: CGFloat, _ base: CGFloat, _ h: CGFloat, _ w: CGFloat, _ color: Color, _ t: CGFloat, _ ph: CGFloat) {
        let flick: CGFloat = 1 + sin(t * 11 + ph) * 0.12 + sin(t * 7.3 + ph) * 0.08
        let hh = h * flick
        var p = Path()
        p.move(to: P(fx, base - hh))
        p.addQuadCurve(to: P(fx, base + 2), control: P(fx + w, base - hh * 0.35))
        p.addQuadCurve(to: P(fx, base - hh), control: P(fx - w, base - hh * 0.35))
        fill(p, with: .color(color))
    }
}

@inline(__always) func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

enum Ink {
    static let trunk = Color(hex: 0x7A5233)
    static let trunkDark = Color(hex: 0x6B4A2E)
    static let leafDark = Color(hex: 0x3F8C4B)
    static let leafMid = Color(hex: 0x4FA25A)
    static let leafLight = Color(hex: 0x66BB67)
    static let leafHi = Color(hex: 0x8FD48A)
    static let apple = Color(hex: 0xE8574A)
    static let stone = Color(hex: 0x8F98A3)
    static let stoneLight = Color(hex: 0xB4BCC6)
    static let moss = Color(hex: 0x7FAF6B)
    static let grassA = Color(hex: 0x8DD26E)
    static let grassB = Color(hex: 0x83C964)
    static let grassA2 = Color(hex: 0x8FD470)
    static let grassB2 = Color(hex: 0x86CC66)
    static let dirtLeft = Color(hex: 0xB8875A)
    static let dirtRight = Color(hex: 0x9C6F45)
    static let lipLeft = Color(hex: 0x4E9A43)
    static let lipRight = Color(hex: 0x438A3A)
    static let sand = Color(hex: 0xF1DCA0)
    static let ink = Color(hex: 0x1F2633)
}

// MARK: - Props

enum PropArt {
    static func draw(_ type: PropType, _ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat, night: CGFloat) {
        switch type {
        case .flowers: flowers(c, x, y, s, t)
        case .rock: rock(c, x, y, s)
        case .tree: tree(c, x, y, s, t)
        case .palm: palm(c, x, y, s, t)
        case .campfire: campfire(c, x, y, s, t)
        case .lantern: lantern(c, x, y, s, night)
        case .workbench: workbench(c, x, y, s)
        case .hammock: hammock(c, x, y, s, t)
        case .tent: tent(c, x, y, s, t)
        case .telescope: telescope(c, x, y, s, t)
        default: MoreArt.draw(type, c, x, y, s, t, night: night)
        }
    }

    static func flowers(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 12 * s)
        let spots: [(CGFloat, CGFloat)] = [(-7, 1), (5, 3), (0, -3), (8, -3), (-3, 4)]
        let cols: [Color] = [Color(hex: 0xFF8FB1), Color(hex: 0xFFD447), .white, Color(hex: 0xB89CFF), Color(hex: 0xFF8FB1)]
        for (i, spot) in spots.enumerated() {
            let sw: CGFloat = sin(t * 2 + CGFloat(i)) * 0.8 * s
            let bx: CGFloat = x + spot.0 * s
            let by: CGFloat = y + spot.1 * s
            c.ell(bx - 2 * s, by - s, 2.6 * s, 1.2 * s, Color(hex: 0x5DAE4E))
            c.line(bx, by, bx + sw, by - 7 * s, Color(hex: 0x4E9A43), 1.2 * s)
            let hx: CGFloat = bx + sw
            let hy: CGFloat = by - 8 * s
            for k in 0..<5 {
                let an: CGFloat = CGFloat(k) / 5 * 2 * .pi
                c.ell(hx + cos(an) * 2 * s, hy + sin(an) * 2 * s, 1.5 * s, 1.5 * s, cols[i])
            }
            c.ell(hx, hy, 1.2 * s, 1.2 * s, Color(hex: 0xF2A541))
        }
    }

    static func rock(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        c.groundShadow(x, y, 13 * s)
        let body: [CGPoint] = [P(x - 12 * s, y), P(x - 9 * s, y - 9 * s), P(x - s, y - 13 * s), P(x + 9 * s, y - 9 * s),
                               P(x + 12 * s, y - s), P(x + 4 * s, y + 4 * s), P(x - 6 * s, y + 4 * s)]
        c.poly(body, Ink.stone)
        let top: [CGPoint] = [P(x - 9 * s, y - 9 * s), P(x - s, y - 13 * s), P(x + 9 * s, y - 9 * s), P(x + 2 * s, y - 6 * s)]
        c.poly(top, Ink.stoneLight)
        c.ell(x + 5 * s, y - s, 3 * s, 1.4 * s, Ink.moss)
    }

    static func tree(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 15 * s)
        let w: CGFloat = sin(t * 1.3 + x * 0.07) * 1.2 * s
        c.rrect(x - 3 * s, y - 20 * s, 6 * s, 21 * s, 2 * s, Ink.trunk)
        c.ell(x + w * 0.5, y - 31 * s, 16 * s, 13 * s, Ink.leafDark)
        c.ell(x - 8 * s + w, y - 26 * s, 10 * s, 9 * s, Ink.leafMid)
        c.ell(x + 8 * s + w, y - 27 * s, 10 * s, 9 * s, Ink.leafMid)
        c.ell(x + w, y - 39 * s, 11 * s, 9 * s, Ink.leafLight)
        c.ell(x - 3 * s + w, y - 42 * s, 4 * s, 3 * s, Ink.leafHi)
        let apples: [(CGFloat, CGFloat)] = [(-6, -30), (5, -35), (9, -24)]
        for a in apples {
            c.ell(x + a.0 * s + w, y + a.1 * s, 1.8 * s, 1.8 * s, Ink.apple)
        }
    }

    static func palm(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 14 * s)
        let sw: CGFloat = sin(t * 1.1 + x * 0.03) * 1.5 * s
        for i in 0..<9 {
            let k: CGFloat = CGFloat(i) / 8
            let px: CGFloat = x + 12 * s * k * k + sw * k
            let py: CGFloat = y - 4 * s - 44 * s * k
            let rx: CGFloat = 3.8 * s * (1 - k * 0.35)
            c.ell(px, py, rx, 2.6 * s, i % 2 == 0 ? Color(hex: 0xB98D5E) : Color(hex: 0x9C7148))
        }
        let tx: CGFloat = x + 12 * s + sw
        let ty: CGFloat = y - 50 * s
        let angles: [CGFloat] = [-2.9, -2.3, -1.6, -0.9, -0.25, 0.35]
        for (i, a) in angles.enumerated() {
            var g = c
            g.translateBy(x: tx, y: ty)
            g.rotate(by: .radians(Double(a + sin(t * 1.6 + CGFloat(i)) * 0.06)))
            g.translateBy(x: 13 * s, y: 3 * s)
            g.rotate(by: .radians(0.25))
            g.ell(0, 0, 15 * s, 4.2 * s, i % 2 == 0 ? Color(hex: 0x3E9B52) : Color(hex: 0x52B062))
        }
        c.ell(tx - 2 * s, ty + 3 * s, 2.6 * s, 2.6 * s, Ink.trunk)
        c.ell(tx + 2.5 * s, ty + 3.5 * s, 2.6 * s, 2.6 * s, Color(hex: 0x6A4426))
    }

    static func campfire(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        for i in 0..<7 {
            let a: CGFloat = CGFloat(i) / 7 * 2 * .pi
            c.ell(x + cos(a) * 11 * s, y + sin(a) * 5.5 * s, 3.4 * s, 2.4 * s, i % 2 == 0 ? Color(hex: 0xA9B0B9) : Color(hex: 0x8E96A0))
        }
        var logs = c
        logs.translateBy(x: x, y: y - 2 * s)
        logs.rotate(by: .radians(0.35))
        logs.rrect(-10 * s, -2 * s, 20 * s, 4 * s, 2 * s, Color(hex: 0x7A4E2E))
        logs.rotate(by: .radians(-0.7))
        logs.rrect(-10 * s, -2 * s, 20 * s, 4 * s, 2 * s, Color(hex: 0x8B5A35))

        func flame(_ dx: CGFloat, _ h: CGFloat, _ w: CGFloat, _ color: Color, _ ph: CGFloat) {
            let flick: CGFloat = 1 + sin(t * 11 + ph) * 0.12 + sin(t * 7.3 + ph) * 0.08
            let hh: CGFloat = h * s * flick
            let ww: CGFloat = w * s
            let fx: CGFloat = x + dx * s
            let base: CGFloat = y - 3 * s
            var p = Path()
            p.move(to: P(fx, base - hh))
            p.addQuadCurve(to: P(fx, y - s), control: P(fx + ww, base - hh * 0.35))
            p.addQuadCurve(to: P(fx, base - hh), control: P(fx - ww, base - hh * 0.35))
            c.fill(p, with: .color(color))
        }
        flame(-3, 13, 5.5, Color(hex: 0xFF6B2C), 0)
        flame(3, 11, 5, Color(hex: 0xFF6B2C), 2)
        flame(0, 17, 7, Color(hex: 0xFF8C2F), 1)
        flame(0, 11, 4.5, Color(hex: 0xFFC247), 3)
        flame(0, 6, 2.6, Color(hex: 0xFFF1B0), 4)
        for i in 0..<4 {
            let k: CGFloat = (t * 0.6 + CGFloat(i) * 0.27).truncatingRemainder(dividingBy: 1)
            let ex: CGFloat = x + sin(CGFloat(i) * 3 + t * 2) * 5 * s
            c.ell(ex, y - 10 * s - k * 26 * s, 1.2 * s, 1.2 * s, Color(hex: 0xFFB450, opacity: Double(1 - k)))
        }
    }

    static func lantern(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ night: CGFloat) {
        c.groundShadow(x, y, 6 * s)
        let iron = Color(hex: 0x3C3F46)
        c.line(x, y, x, y - 28 * s, iron, 2.2 * s)
        c.line(x, y - 28 * s, x + 6.5 * s, y - 28 * s, iron, 1.8 * s)
        c.rrect(x + 3 * s, y - 27 * s, 7 * s, 9.5 * s, 2 * s, iron)
        c.rrect(x + 4.2 * s, y - 25.8 * s, 4.6 * s, 7 * s, 1.5 * s, night > 0.3 ? Color(hex: 0xFFE58A) : Color(hex: 0xF7D774))
    }

    static func workbench(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        c.groundShadow(x, y + 2 * s, 18 * s)
        c.isoBox(x, y + 2 * s, 15 * s, 13 * s, top: Color(hex: 0xC99560), left: Color(hex: 0xA0703F), right: Color(hex: 0x8A5E33))
        let paper: [CGPoint] = [P(x + 3 * s, y - 11 * s), P(x + 9 * s, y - 14 * s), P(x + 13 * s, y - 12 * s), P(x + 7 * s, y - 9 * s)]
        c.poly(paper, Color(hex: 0x9CC9F0))
        c.line(x - 9 * s, y - 11 * s, x - 2 * s, y - 15 * s, Ink.trunk, 1.8 * s)
        c.rrect(x - 3.5 * s, y - 18.5 * s, 5 * s, 3.4 * s, s, Color(hex: 0x8E96A0))
    }

    static func hammock(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 18 * s)
        let lx: CGFloat = x - 17 * s, ly: CGFloat = y + 3 * s
        let rx: CGFloat = x + 17 * s, ry: CGFloat = y - 5 * s
        let sw: CGFloat = sin(t * 1.6) * 2 * s
        let rope = Color(hex: 0xD9C7A3)
        c.rrect(rx - 2 * s, ry - 26 * s, 4 * s, 27 * s, 1.5 * s, Ink.trunkDark)
        c.line(rx, ry - 25 * s, rx - 2 * s, ry - 19 * s, rope, s)
        var cloth = Path()
        cloth.move(to: P(lx + s, ly - 19 * s))
        cloth.addQuadCurve(to: P(rx - s, ry - 19 * s), control: P(x + sw * 0.3, y + sw))
        cloth.addLine(to: P(rx - s, ry - 15 * s))
        cloth.addQuadCurve(to: P(lx + s, ly - 15 * s), control: P(x + sw * 0.3, y + 7 * s + sw))
        cloth.closeSubpath()
        c.fill(cloth, with: .color(Color(hex: 0xE8604C)))
        var stripe = Path()
        stripe.move(to: P(lx + s, ly - 17 * s))
        stripe.addQuadCurve(to: P(rx - s, ry - 17 * s), control: P(x + sw * 0.3, y + 3.5 * s + sw))
        c.stroke(stripe, with: .color(Color(hex: 0xFFE7C2)), lineWidth: 1.6 * s)
        c.line(lx, ly - 25 * s, lx + 2 * s, ly - 19 * s, rope, s)
        c.rrect(lx - 2 * s, ly - 26 * s, 4 * s, 27 * s, 1.5 * s, Ink.trunk)
    }

    static func tent(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 19 * s)
        let dX: CGFloat = 8 * s, dY: CGFloat = 4 * s
        let eX: CGFloat = -13 * s, eY: CGFloat = 6.5 * s
        let h: CGFloat = 26 * s
        let fc = P(x + dX, y + dY)
        let bc = P(x - dX, y - dY)
        let fa = P(fc.x, fc.y - h)
        let ba = P(bc.x, bc.y - h)
        let fcPlus = P(fc.x + eX, fc.y + eY), fcMinus = P(fc.x - eX, fc.y - eY)
        let bcPlus = P(bc.x + eX, bc.y + eY), bcMinus = P(bc.x - eX, bc.y - eY)
        c.poly([bcMinus, fcMinus, fa, ba], Color(hex: 0xD9824A))
        c.line(ba.x, ba.y, ba.x, ba.y - 9 * s, Ink.trunkDark, 1.2 * s)
        let wave: CGFloat = sin(t * 4) * 1.5 * s
        c.poly([P(ba.x, ba.y - 9 * s), P(ba.x + 7 * s + wave, ba.y - 7 * s), P(ba.x, ba.y - 5 * s)], Color(hex: 0xFF7A2F))
        c.poly([bcPlus, fcPlus, fa, ba], Color(hex: 0xE89A5C))
        c.poly([fcPlus, fcMinus, fa], Color(hex: 0xF6C38B))
        c.poly([P(fc.x - 4 * s, fc.y + 2 * s), P(fc.x + 5 * s, fc.y - 2.5 * s), P(fc.x + 0.5 * s, fc.y - 14 * s)], Color(hex: 0x7A3E22))
    }

    static func telescope(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 11 * s)
        let hy: CGFloat = y - 15 * s
        c.line(x, hy, x - 8 * s, y + 2 * s, Ink.trunkDark, 1.8 * s)
        c.line(x, hy, x + 8 * s, y + 2 * s, Ink.trunkDark, 1.8 * s)
        c.line(x, hy, x + s, y + 5 * s, Color(hex: 0x5A3D25), 1.8 * s)
        var g = c
        g.translateBy(x: x, y: hy)
        g.rotate(by: .radians(Double(-0.55 + sin(t * 0.5) * 0.05)))
        g.rrect(-10 * s, -3.2 * s, 26 * s, 6.4 * s, 3 * s, Color(hex: 0x3D5A80))
        g.rrect(12 * s, -4 * s, 5 * s, 8 * s, 2 * s, Color(hex: 0xC9A227))
        g.rrect(-12 * s, -2.2 * s, 3 * s, 4.4 * s, s, Color(hex: 0xC9A227))
    }
}

// MARK: - Companions

enum CompanionArt {
    static func draw(_ type: CompanionType, _ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat, face: CGFloat) {
        switch type {
        case .crab: crab(c, x, y, s, t)
        case .duck: duck(c, x, y, s, t, face)
        case .turtle: turtle(c, x, y, s, t, face)
        case .cat: cat(c, x, y, s, t, face)
        case .frog: frog(c, x, y, s, t, face)
        case .bunny: bunny(c, x, y, s, t, face)
        }
    }

    static func cat(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat, _ face: CGFloat) {
        c.groundShadow(x, y, 8 * s)
        var g = c
        g.translateBy(x: x, y: y)
        g.scaleBy(x: face, y: 1)
        let fur = Color(hex: 0xF2A14A), dark = Color(hex: 0xD9822B)
        var tail = Path()
        tail.move(to: P(-6 * s, -5 * s))
        tail.addQuadCurve(to: P(-11 * s, -14 * s + sin(t * 3) * 2 * s), control: P(-13 * s, -4 * s))
        g.stroke(tail, with: .color(fur), style: StrokeStyle(lineWidth: 2.2 * s, lineCap: .round))
        g.ell(-4 * s, -1 * s, 2 * s, 1.5 * s, dark)
        g.ell(4 * s, -1 * s, 2 * s, 1.5 * s, dark)
        g.ell(0, -6 * s, 7.5 * s, 5 * s, fur)
        g.line(-2 * s, -10 * s, -2 * s, -7 * s, dark, 1 * s)
        g.line(1 * s, -10.5 * s, 1 * s, -7.5 * s, dark, 1 * s)
        g.ell(6 * s, -12 * s, 4.6 * s, 4 * s, fur)
        g.poly([P(3 * s, -15 * s), P(4.5 * s, -19.5 * s), P(6.5 * s, -15.5 * s)], fur)
        g.poly([P(6.5 * s, -15.5 * s), P(9 * s, -19 * s), P(9.8 * s, -14 * s)], fur)
        g.ell(5.5 * s, -12.5 * s, 0.8 * s, 1 * s, Color(hex: 0x2A1C12))
        g.ell(8.5 * s, -12.5 * s, 0.8 * s, 1 * s, Color(hex: 0x2A1C12))
        g.ell(7.2 * s, -10.6 * s, 0.8 * s, 0.6 * s, Color(hex: 0xF08AA0))
    }

    static func frog(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat, _ face: CGFloat) {
        c.groundShadow(x, y, 7 * s)
        var g = c
        g.translateBy(x: x, y: y)
        g.scaleBy(x: face, y: 1)
        let green = Color(hex: 0x6CC24A)
        g.ell(-5 * s, -1 * s, 3 * s, 1.6 * s, Color(hex: 0x58A83A))
        g.ell(5 * s, -1 * s, 3 * s, 1.6 * s, Color(hex: 0x58A83A))
        g.ell(0, -4.5 * s, 6.5 * s, 4.5 * s, green)
        g.ell(1 * s, -3 * s, 4 * s, 2.4 * s, Color(hex: 0xC8E9A0))
        for ex in [CGFloat(-2.5), CGFloat(3)] {
            g.ell(ex * s, -9 * s, 2.4 * s, 2.4 * s, green)
            g.ell(ex * s, -9.3 * s, 1.4 * s, 1.4 * s, .white)
            g.ell(ex * s + 0.3 * s, -9.3 * s, 0.7 * s, 0.8 * s, Color(hex: 0x222222))
        }
        var mouth = Path()
        mouth.move(to: P(-2 * s, -5.5 * s))
        mouth.addQuadCurve(to: P(4 * s, -5.5 * s), control: P(1 * s, -3.8 * s))
        g.stroke(mouth, with: .color(Color(hex: 0x3E7F2A)), lineWidth: 0.6 * s)
    }

    static func bunny(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat, _ face: CGFloat) {
        c.groundShadow(x, y, 7 * s)
        var g = c
        g.translateBy(x: x, y: y)
        g.scaleBy(x: face, y: 1)
        let white = Color(hex: 0xF5F2EC), shade = Color(hex: 0xE2DCD2)
        g.ell(-6.5 * s, -6 * s, 2.4 * s, 2.4 * s, .white)
        g.ell(0, -6 * s, 6.5 * s, 5.5 * s, white)
        g.ell(-1 * s, -4 * s, 4 * s, 2.6 * s, shade)
        let flop: CGFloat = sin(t * 2.5) * 0.12
        for (i, ex) in [CGFloat(3.5), CGFloat(6.5)].enumerated() {
            var ear = g
            ear.translateBy(x: ex * s, y: -14 * s)
            ear.rotate(by: .radians(Double(CGFloat(i) * 0.35 - 0.1 + flop)))
            ear.ell(0, -4 * s, 1.6 * s, 4.5 * s, white)
            ear.ell(0, -4 * s, 0.8 * s, 3.2 * s, Color(hex: 0xF7B6C8))
        }
        g.ell(5 * s, -11 * s, 4 * s, 3.6 * s, white)
        g.ell(6.2 * s, -11.6 * s, 0.8 * s, 0.9 * s, Color(hex: 0x2A1C12))
        g.ell(8.6 * s, -10.4 * s, 0.7 * s, 0.5 * s, Color(hex: 0xF08AA0))
    }

    static func crab(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat) {
        c.groundShadow(x, y, 9 * s)
        let red = Color(hex: 0xE8574A), dark = Color(hex: 0xC9443A)
        let claw: CGFloat = abs(sin(t * 5)) * 0.35
        for side in [CGFloat(-1), CGFloat(1)] {
            c.line(x + side * 5 * s, y - 3 * s, x + side * 10 * s, y, dark, 1.4 * s)
            c.line(x + side * 4 * s, y - 3 * s, x + side * 8 * s, y + s, dark, 1.4 * s)
        }
        c.ell(x, y - 5 * s, 8 * s, 5.5 * s, red)
        c.ell(x, y - 6.5 * s, 5 * s, 2.5 * s, Color(hex: 0xF27E6F))
        for side in [CGFloat(-1), CGFloat(1)] {
            c.line(x + side * 2.5 * s, y - 9 * s, x + side * 3 * s, y - 13 * s, dark, 1.2 * s)
            c.ell(x + side * 3 * s, y - 13.5 * s, 1.8 * s, 1.8 * s, .white)
            c.ell(x + side * 3.2 * s, y - 13.5 * s, 0.9 * s, 0.9 * s, Color(hex: 0x222222))
            var g = c
            g.translateBy(x: x + side * 10 * s, y: y - 8 * s)
            g.rotate(by: .radians(Double(side * claw)))
            g.ell(0, 0, 3.4 * s, 2.8 * s, red)
        }
    }

    static func duck(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat, _ face: CGFloat) {
        c.groundShadow(x, y, 7 * s)
        var g = c
        g.translateBy(x: x, y: y)
        g.rotate(by: .radians(Double(sin(t * 8) * 0.08)))
        g.scaleBy(x: face, y: 1)
        let yellow = Color(hex: 0xFFD447)
        g.ell(0, -6 * s, 7 * s, 5.5 * s, yellow)
        g.ell(-2 * s, -6 * s, 4 * s, 3 * s, Color(hex: 0xF5C431))
        g.ell(4 * s, -13 * s, 4.5 * s, 4.5 * s, yellow)
        g.poly([P(8 * s, -13.5 * s), P(12 * s, -12.5 * s), P(8 * s, -11.3 * s)], Color(hex: 0xFF9A3C))
        g.ell(5.5 * s, -14.5 * s, 0.9 * s, 0.9 * s, Color(hex: 0x222222))
    }

    static func turtle(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ t: CGFloat, _ face: CGFloat) {
        c.groundShadow(x, y, 11 * s)
        var g = c
        g.translateBy(x: x, y: y)
        g.scaleBy(x: face, y: 1)
        let step: CGFloat = sin(t * 4) * s
        let skin = Color(hex: 0x7FB879)
        g.ell(-6 * s, -s + step, 2.5 * s, 2 * s, skin)
        g.ell(6 * s, -s - step, 2.5 * s, 2 * s, skin)
        g.ell(11 * s, -4 * s, 3.6 * s, 3 * s, Color(hex: 0x8CC184))
        g.ell(12.5 * s, -5 * s, 0.8 * s, 0.8 * s, Color(hex: 0x222222))
        var dome = g
        dome.clip(to: Path(CGRect(x: -11 * s, y: -12 * s, width: 22 * s, height: 9 * s)))
        dome.ell(0, -3 * s, 10 * s, 8 * s, Color(hex: 0x4E9A5A))
        g.rrect(-10.5 * s, -4 * s, 21 * s, 2.6 * s, 1.3 * s, Color(hex: 0x3E7F49))
        let spots: [(CGFloat, CGFloat)] = [(-4, -6), (3, -7), (0, -9.5)]
        for sp in spots {
            g.ell(sp.0 * s, sp.1 * s, 2.4 * s, 1.6 * s, Color(hex: 0x6CB874))
        }
    }
}

// MARK: - Bitsy the mole

struct MolePose {
    var t: CGFloat
    var bob: CGFloat = 0
    var face: CGFloat = 1
    var lying = false
    var action: PropType?
    var night: CGFloat = 0
    var walking = false
    var sleeping = false
    var cheering = false
    var hammering = false
}

enum MoleArt {
    static let fur = Color(hex: 0x8C5E3B)
    static let furDark = Color(hex: 0x7A4F30)
    static let feet = Color(hex: 0x6A4226)
    static let belly = Color(hex: 0xE6C7A2)
    static let eye = Color(hex: 0x2A1C12)
    static let hat = Color(hex: 0xFFC63A)
    static let brim = Color(hex: 0xE9A51C)

    static func draw(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ o: MolePose) {
        if !o.lying { c.groundShadow(x, y, 12 * s) }
        var g = c
        g.translateBy(x: x, y: y - o.bob)
        if o.lying {
            g.rotate(by: .radians(Double(-1.3 * o.face)))
            g.translateBy(x: 0, y: 6 * s)
        }
        g.scaleBy(x: o.face, y: 1)

        let step: CGFloat = o.walking ? sin(o.t * 14) : 0
        g.ell(-6 * s, -s + step * 1.2 * s, 4.2 * s, 2.6 * s, feet)
        g.ell(6 * s, -s - step * 1.2 * s, 4.2 * s, 2.6 * s, feet)
        g.ell(0, -14 * s, 13 * s, 14 * s, fur)
        g.ell(0, -9 * s, 8.5 * s, 8 * s, belly)
        g.ell(-10.5 * s, -11 * s, 2.8 * s, 4 * s, furDark)

        let hammer = o.action == .workbench || o.hammering
        var armAngle: CGFloat = 0
        if hammer { armAngle = sin(o.t * 12) * 0.7 }
        else if o.action == .campfire { armAngle = -0.5 }
        else if o.cheering { armAngle = -1.2 }
        var arm = g
        arm.translateBy(x: 10 * s, y: -12 * s)
        arm.rotate(by: .radians(Double(-0.3 + armAngle)))
        arm.ell(2 * s, 0, 4 * s, 2.7 * s, furDark)
        if hammer {
            arm.line(4 * s, 0, 4 * s, -8 * s, Ink.trunk, 1.6 * s)
            arm.rrect(s, -11 * s, 6 * s, 3.5 * s, s, Color(hex: 0x8E96A0))
        }

        let blink = o.t.truncatingRemainder(dividingBy: 3.7) < 0.12
        if o.sleeping || blink {
            g.line(-6 * s, -18 * s, -3 * s, -18 * s, eye, 1.4 * s)
            g.line(3 * s, -18 * s, 6 * s, -18 * s, eye, 1.4 * s)
        } else {
            g.ell(-4.5 * s, -18.5 * s, 1.9 * s, 2.2 * s, eye)
            g.ell(4.5 * s, -18.5 * s, 1.9 * s, 2.2 * s, eye)
            g.ell(-4 * s, -19.3 * s, 0.7 * s, 0.7 * s, .white)
            g.ell(5 * s, -19.3 * s, 0.7 * s, 0.7 * s, .white)
        }
        let blush = Color(hex: 0xFF7878, opacity: 0.45)
        g.ell(-8 * s, -14.5 * s, 2.4 * s, 1.5 * s, blush)
        g.ell(8 * s, -14.5 * s, 2.4 * s, 1.5 * s, blush)
        g.ell(0, -15 * s, 3.2 * s, 2.3 * s, Color(hex: 0xF08AA0))
        g.ell(-0.8 * s, -15.8 * s, s, 0.6 * s, Color.white.opacity(0.7))

        var dome = g
        dome.clip(to: Path(CGRect(x: -12 * s, y: -36 * s, width: 24 * s, height: 12 * s)))
        dome.ell(0, -24 * s, 10.5 * s, 10.5 * s, hat)
        g.rrect(-13 * s, -25 * s, 26 * s, 3.4 * s, 1.7 * s, brim)
        g.ell(0, -30.5 * s, 2.8 * s, 2.8 * s, o.night > 0.3 ? Color(hex: 0xFFF6C8) : .white)
        g.ell(0, -30.5 * s, 1.6 * s, 1.6 * s, Color(hex: 0xFFE07A))
    }
}

// MARK: - Tiles

enum TileArt {
    /// A single grass tile with dirt sides, centred at (x, y).
    static func tile(_ c: GraphicsContext, _ x: CGFloat, _ y: CGFloat, halfWidth hw: CGFloat, depth: CGFloat) {
        let hh = hw / 2
        c.poly([P(x - hw, y), P(x, y + hh), P(x, y + hh + depth), P(x - hw, y + depth)], Ink.dirtLeft)
        c.poly([P(x, y + hh), P(x + hw, y), P(x + hw, y + depth), P(x, y + hh + depth)], Ink.dirtRight)
        c.poly([P(x, y - hh), P(x + hw, y), P(x, y + hh), P(x - hw, y)], Ink.grassA)
    }
}
