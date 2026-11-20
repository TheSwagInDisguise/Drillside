import SwiftUI

struct LightSource {
    var r: Double, g: Double, b: Double
    var radius: CGFloat
    var dx: CGFloat = 0
    var dy: CGFloat = 0
    var color: Color { Color(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: 1) }
}

enum PropType: String, CaseIterable, Codable, Identifiable {
    case flowers, rock, tree, palm, campfire, lantern, workbench, hammock, tent, telescope

    var id: String { rawValue }

    var name: String {
        switch self {
        case .flowers: return "Flower Patch"
        case .rock: return "Sitting Rock"
        case .tree: return "Oak Tree"
        case .palm: return "Palm Tree"
        case .campfire: return "Campfire"
        case .lantern: return "Lantern"
        case .workbench: return "Workbench"
        case .hammock: return "Hammock"
        case .tent: return "Planning Tent"
        case .telescope: return "Telescope"
        }
    }

    var short: String {
        switch self {
        case .flowers: return "Flowers"
        case .rock: return "Rock"
        case .tree: return "Oak"
        case .palm: return "Palm"
        case .campfire: return "Campfire"
        case .lantern: return "Lantern"
        case .workbench: return "Bench"
        case .hammock: return "Hammock"
        case .tent: return "Tent"
        case .telescope: return "Telescope"
        }
    }

    var price: Int {
        switch self {
        case .flowers: return 20
        case .rock: return 15
        case .tree: return 40
        case .palm: return 60
        case .campfire: return 80
        case .lantern: return 50
        case .workbench: return 100
        case .hammock: return 120
        case .tent: return 150
        case .telescope: return 200
        }
    }

    var unlockLevel: Int {
        switch self {
        case .flowers, .rock, .tree, .palm: return 1
        case .campfire, .lantern: return 2
        case .workbench, .hammock: return 3
        case .tent: return 4
        case .telescope: return 5
        }
    }

    var blurb: String {
        switch self {
        case .flowers: return "A pop of colour"
        case .rock: return "Good for thinking"
        case .tree: return "Shade & snacks"
        case .palm: return "Peak island vibes"
        case .campfire: return "Warm glow at night"
        case .lantern: return "Lights up the night"
        case .workbench: return "Where iteration happens"
        case .hammock: return "Rest is productive"
        case .tent: return "Define tomorrow, tonight"
        case .telescope: return "Look further: Learn"
        }
    }

    /// What Bitsy says while using the prop.
    var action: String {
        switch self {
        case .flowers: return "🌼 smelling flowers"
        case .rock: return "🪨 pondering"
        case .tree: return "🍎 snack break"
        case .palm: return "🥥 coconut time"
        case .campfire: return "🔥 warming up"
        case .lantern: return "✨ cozy light"
        case .workbench: return "🔨 iterating"
        case .hammock: return "💤 recharging"
        case .tent: return "⛺ planning"
        case .telescope: return "🔭 learning"
        }
    }

    var light: LightSource? {
        switch self {
        case .campfire: return LightSource(r: 255, g: 140, b: 50, radius: 95, dy: -8)
        case .lantern: return LightSource(r: 255, g: 215, b: 120, radius: 70, dx: 6.5, dy: -22)
        case .tent: return LightSource(r: 255, g: 200, b: 120, radius: 42, dy: -6)
        default: return nil
        }
    }
}

enum CompanionType: String, CaseIterable, Codable, Identifiable {
    case crab, duck, turtle

    var id: String { rawValue }

    var name: String {
        switch self {
        case .crab: return "Pinch the Crab"
        case .duck: return "Puddle the Duckling"
        case .turtle: return "Sage the Turtle"
        }
    }

    var price: Int {
        switch self {
        case .crab: return 150
        case .duck: return 220
        case .turtle: return 300
        }
    }

    var unlockLevel: Int {
        switch self {
        case .crab: return 2
        case .duck: return 3
        case .turtle: return 5
        }
    }

    var blurb: String {
        switch self {
        case .crab: return "Scuttles sideways, cheers you on"
        case .duck: return "Waddles around your island"
        case .turtle: return "Slow and steady wins"
        }
    }

    /// Wander speed in tiles per second.
    var speed: CGFloat {
        switch self {
        case .crab: return 0.55
        case .duck: return 0.7
        case .turtle: return 0.3
        }
    }
}
