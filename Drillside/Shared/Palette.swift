import SwiftUI

extension Color {
    /// Packs an RGB triple as 0xRRGGBB-style components (0…1).
    struct RGB { var r: Double, g: Double, b: Double }

    init(rgb: RGB) { self.init(.sRGB, red: rgb.r, green: rgb.g, blue: rgb.b, opacity: 1) }

    static func rgb(_ hex: UInt32) -> RGB {
        RGB(r: Double((hex >> 16) & 0xFF) / 255, g: Double((hex >> 8) & 0xFF) / 255, b: Double(hex & 0xFF) / 255)
    }

    static func mixRGB(_ a: RGB, _ b: RGB, _ k: CGFloat) -> RGB {
        let kk = Double(min(1, max(0, k)))
        return RGB(r: a.r + (b.r - a.r) * kk, g: a.g + (b.g - a.g) * kk, b: a.b + (b.b - a.b) * kk)
    }

    static func mixRGB(_ a: UInt32, _ b: UInt32, _ k: CGFloat) -> RGB { mixRGB(rgb(a), rgb(b), k) }
    static func mixRGB(_ a: RGB, _ b: UInt32, _ k: CGFloat) -> RGB { mixRGB(a, rgb(b), k) }

    /// Linear blend between two hex colours (k = 0 → a, k = 1 → b).
    static func mix(_ a: UInt32, _ b: UInt32, _ k: CGFloat) -> Color {
        let kk = Double(min(1, max(0, k)))
        func ch(_ v: UInt32, _ shift: UInt32) -> Double { Double((v >> shift) & 0xFF) / 255 }
        let r = ch(a, 16) + (ch(b, 16) - ch(a, 16)) * kk
        let g = ch(a, 8) + (ch(b, 8) - ch(a, 8)) * kk
        let bl = ch(a, 0) + (ch(b, 0) - ch(a, 0)) * kk
        return Color(.sRGB, red: r, green: g, blue: bl, opacity: 1)
    }
}

enum Theme {
    static let accent = Color(hex: 0xFF7A2F)
    static let accentLight = Color(hex: 0xFF9A4D)
    static let good = Color(hex: 0x2FA36B)
    static let bad = Color(hex: 0xD0533F)
    static let timerBackground = Color(hex: 0x121521)
}

enum Pillars {
    static let defaultNames = ["Define", "Routine", "Iterate", "Learn", "Lock-in"]
    static let defaultHints = [
        "Clarify the day’s 1–3 outcomes",
        "Repeatable basics that keep you steady",
        "Improve one thing, ship small",
        "Grow a skill a little every day",
        "Protected deep-focus time"
    ]
    static let colors: [Color] = [
        Color(hex: 0xF2A541), Color(hex: 0x3FB47A), Color(hex: 0x5B8DEF), Color(hex: 0xA77BDB), Color(hex: 0xE5675A)
    ]

    static let hexes: [UInt32] = [0xF2A541, 0x3FB47A, 0x5B8DEF, 0xA77BDB, 0xE5675A]

    static func color(_ i: Int) -> Color { colors[max(0, min(colors.count - 1, i))] }
    static func hex(_ i: Int) -> UInt32 { hexes[max(0, min(hexes.count - 1, i))] }

    static func letter(_ name: String) -> String {
        guard let ch = name.trimmingCharacters(in: .whitespaces).first else { return "?" }
        return String(ch).uppercased()
    }
}
