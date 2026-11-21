import SwiftUI

struct LightSource {
    var r: Double, g: Double, b: Double
    var radius: CGFloat
    var dx: CGFloat = 0
    var dy: CGFloat = 0
    var color: Color { Color(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: 1) }
}

enum PropCategory: String, CaseIterable, Identifiable {
    case nature, cozy, study, lights, terrain
    var id: String { rawValue }
    var title: String {
        switch self {
        case .nature: return "Nature"
        case .cozy: return "Cozy"
        case .study: return "Study"
        case .lights: return "Lights"
        case .terrain: return "Terrain"
        }
    }
    var icon: String {
        switch self {
        case .nature: return "leaf.fill"
        case .cozy: return "house.fill"
        case .study: return "book.fill"
        case .lights: return "lightbulb.fill"
        case .terrain: return "square.grid.3x3.fill"
        }
    }
}

enum PropType: String, CaseIterable, Codable, Identifiable {
    // Nature
    case bush, rock, flowers, tree, palm, sunflower, pine, mushrooms, cactus, bamboo, cherry, pumpkins
    // Cozy
    case campfire, bench, mailbox, umbrella, hammock, picnic, tent, well, cabin, windmill, lighthouse
    // Study
    case signpost, workbench, bookshelf, chalkboard, easel, telescope
    // Lights
    case lantern, torch, streetlamp, fireflies
    // Terrain (flat)
    case sand, path, meadow, deck, pond

    var id: String { rawValue }

    private struct Info {
        let name: String
        let short: String
        let price: Int
        let level: Int
        let category: PropCategory
        let blurb: String
        let action: String
        var tall: CGFloat = 45
    }

    private var info: Info {
        switch self {
        case .bush: return Info(name: "Berry Bush", short: "Bush", price: 15, level: 1, category: .nature, blurb: "Small, round, snackable", action: "🫐 berry snack", tall: 22)
        case .rock: return Info(name: "Sitting Rock", short: "Rock", price: 15, level: 1, category: .nature, blurb: "Good for thinking", action: "🪨 pondering", tall: 16)
        case .flowers: return Info(name: "Flower Patch", short: "Flowers", price: 20, level: 1, category: .nature, blurb: "A pop of colour", action: "🌼 smelling flowers", tall: 16)
        case .tree: return Info(name: "Oak Tree", short: "Oak", price: 40, level: 1, category: .nature, blurb: "Shade & snacks", action: "🍎 snack break", tall: 50)
        case .palm: return Info(name: "Palm Tree", short: "Palm", price: 60, level: 1, category: .nature, blurb: "Peak island vibes", action: "🥥 coconut time", tall: 60)
        case .sunflower: return Info(name: "Sunflowers", short: "Sunflower", price: 30, level: 2, category: .nature, blurb: "Always facing the light", action: "🌻 sunbathing", tall: 36)
        case .pine: return Info(name: "Pine Tree", short: "Pine", price: 45, level: 2, category: .nature, blurb: "Evergreen, like your streak", action: "🌲 fresh air", tall: 48)
        case .mushrooms: return Info(name: "Mushroom Ring", short: "Shrooms", price: 35, level: 3, category: .nature, blurb: "Pops up after rain", action: "🍄 foraging", tall: 20)
        case .cactus: return Info(name: "Cactus", short: "Cactus", price: 40, level: 4, category: .nature, blurb: "Thrives on little", action: "🌵 careful…", tall: 34)
        case .bamboo: return Info(name: "Bamboo Grove", short: "Bamboo", price: 70, level: 5, category: .nature, blurb: "Grows a little every day", action: "🎋 zen moment", tall: 52)
        case .cherry: return Info(name: "Cherry Blossom", short: "Cherry", price: 140, level: 6, category: .nature, blurb: "Petals drift on the breeze", action: "🌸 petal watching", tall: 50)
        case .pumpkins: return Info(name: "Pumpkin Patch", short: "Pumpkins", price: 55, level: 7, category: .nature, blurb: "The harvest of consistency", action: "🎃 harvest time", tall: 18)
        case .campfire: return Info(name: "Campfire", short: "Campfire", price: 80, level: 2, category: .cozy, blurb: "Warm glow at night", action: "🔥 warming up", tall: 28)
        case .bench: return Info(name: "Park Bench", short: "Bench", price: 60, level: 2, category: .cozy, blurb: "Take five", action: "🪑 taking five", tall: 26)
        case .mailbox: return Info(name: "Mailbox", short: "Mailbox", price: 45, level: 3, category: .cozy, blurb: "Letters from future you", action: "📬 checking mail", tall: 32)
        case .umbrella: return Info(name: "Beach Umbrella", short: "Umbrella", price: 90, level: 3, category: .cozy, blurb: "Shade for long breaks", action: "⛱️ beach break", tall: 42)
        case .hammock: return Info(name: "Hammock", short: "Hammock", price: 120, level: 3, category: .cozy, blurb: "Rest is productive", action: "💤 recharging", tall: 32)
        case .picnic: return Info(name: "Picnic Blanket", short: "Picnic", price: 70, level: 4, category: .cozy, blurb: "Snacks for a job well done", action: "🧺 picnic time", tall: 12)
        case .tent: return Info(name: "Planning Tent", short: "Tent", price: 150, level: 4, category: .cozy, blurb: "Define tomorrow, tonight", action: "⛺ planning", tall: 36)
        case .well: return Info(name: "Wishing Well", short: "Well", price: 160, level: 6, category: .cozy, blurb: "Make a wish, then do the work", action: "🪣 making a wish", tall: 40)
        case .cabin: return Info(name: "Cozy Cabin", short: "Cabin", price: 400, level: 8, category: .cozy, blurb: "A home base with a warm window", action: "🏡 cozy break", tall: 56)
        case .windmill: return Info(name: "Windmill", short: "Windmill", price: 350, level: 9, category: .cozy, blurb: "Small turns, big power", action: "🌬️ watching blades", tall: 66)
        case .lighthouse: return Info(name: "Lighthouse", short: "Lighthouse", price: 600, level: 12, category: .cozy, blurb: "Guides you home at night", action: "🗼 keeping watch", tall: 74)
        case .signpost: return Info(name: "Signpost", short: "Sign", price: 40, level: 2, category: .study, blurb: "Pick a direction", action: "🧭 choosing a path", tall: 32)
        case .workbench: return Info(name: "Workbench", short: "Workbench", price: 100, level: 3, category: .study, blurb: "Where iteration happens", action: "🔨 iterating", tall: 24)
        case .bookshelf: return Info(name: "Bookshelf", short: "Books", price: 110, level: 4, category: .study, blurb: "A shelf of small lessons", action: "📚 reading", tall: 34)
        case .chalkboard: return Info(name: "Chalkboard", short: "Board", price: 90, level: 5, category: .study, blurb: "Write today’s outcomes", action: "📝 defining goals", tall: 34)
        case .easel: return Info(name: "Painter’s Easel", short: "Easel", price: 80, level: 5, category: .study, blurb: "Make something just for fun", action: "🎨 painting", tall: 32)
        case .telescope: return Info(name: "Telescope", short: "Telescope", price: 200, level: 5, category: .study, blurb: "Look further: Learn", action: "🔭 learning", tall: 26)
        case .lantern: return Info(name: "Lantern", short: "Lantern", price: 50, level: 2, category: .lights, blurb: "Lights up the night", action: "✨ cozy light", tall: 32)
        case .torch: return Info(name: "Tiki Torch", short: "Torch", price: 55, level: 3, category: .lights, blurb: "A flame that won’t quit", action: "🔥 warm hands", tall: 34)
        case .streetlamp: return Info(name: "Street Lamp", short: "Lamp", price: 120, level: 6, category: .lights, blurb: "For late-night walks", action: "💡 night walk", tall: 46)
        case .fireflies: return Info(name: "Firefly Jar", short: "Fireflies", price: 75, level: 7, category: .lights, blurb: "Tiny lights, big mood", action: "✨ firefly friends", tall: 22)
        case .sand: return Info(name: "Sand Patch", short: "Sand", price: 8, level: 1, category: .terrain, blurb: "Walkable · beachy", action: "🐚 shell hunting", tall: 8)
        case .path: return Info(name: "Stone Path", short: "Path", price: 10, level: 1, category: .terrain, blurb: "Walkable · Bitsy’s favourite", action: "👣 strolling", tall: 8)
        case .meadow: return Info(name: "Clover Meadow", short: "Meadow", price: 12, level: 2, category: .terrain, blurb: "Walkable · maybe lucky", action: "🍀 lucky clover", tall: 8)
        case .deck: return Info(name: "Wooden Deck", short: "Deck", price: 25, level: 3, category: .terrain, blurb: "Walkable · sunny boards", action: "🪵 stretching", tall: 8)
        case .pond: return Info(name: "Lily Pond", short: "Pond", price: 90, level: 4, category: .terrain, blurb: "Calm water with lily pads", action: "🐸 pond gazing", tall: 10)
        }
    }

    var name: String { info.name }
    var short: String { info.short }
    var price: Int { info.price }
    var unlockLevel: Int { info.level }
    var category: PropCategory { info.category }
    var blurb: String { info.blurb }
    /// What Bitsy says while using the prop.
    var action: String { info.action }
    /// Approximate height in art units, used to scale thumbnails.
    var tallness: CGFloat { info.tall }

    /// Flat props are drawn on the ground layer.
    var isFlat: Bool { category == .terrain || self == .picnic }
    /// Bitsy and companions can walk over these.
    var isWalkable: Bool { category == .terrain && self != .pond }

    var light: LightSource? {
        switch self {
        case .campfire: return LightSource(r: 255, g: 140, b: 50, radius: 95, dy: -8)
        case .lantern: return LightSource(r: 255, g: 215, b: 120, radius: 70, dx: 6.5, dy: -22)
        case .tent: return LightSource(r: 255, g: 200, b: 120, radius: 42, dy: -6)
        case .torch: return LightSource(r: 255, g: 150, b: 60, radius: 62, dy: -27)
        case .streetlamp: return LightSource(r: 255, g: 230, b: 150, radius: 88, dx: 9, dy: -34)
        case .fireflies: return LightSource(r: 220, g: 255, b: 120, radius: 44, dy: -8)
        case .cabin: return LightSource(r: 255, g: 200, b: 110, radius: 60, dx: -11, dy: -10)
        case .lighthouse: return LightSource(r: 255, g: 240, b: 170, radius: 130, dy: -57)
        default: return nil
        }
    }

    static func items(in category: PropCategory) -> [PropType] {
        allCases.filter { $0.category == category }.sorted { ($0.unlockLevel, $0.price) < ($1.unlockLevel, $1.price) }
    }
}

enum CompanionType: String, CaseIterable, Codable, Identifiable {
    case crab, duck, cat, frog, turtle, bunny

    var id: String { rawValue }

    var name: String {
        switch self {
        case .crab: return "Pinch the Crab"
        case .duck: return "Puddle the Duckling"
        case .cat: return "Biscuit the Cat"
        case .frog: return "Hops the Frog"
        case .turtle: return "Sage the Turtle"
        case .bunny: return "Clover the Bunny"
        }
    }

    var price: Int {
        switch self {
        case .crab: return 150
        case .duck: return 220
        case .cat: return 260
        case .frog: return 240
        case .turtle: return 300
        case .bunny: return 280
        }
    }

    var unlockLevel: Int {
        switch self {
        case .crab: return 2
        case .duck: return 3
        case .cat: return 4
        case .frog: return 5
        case .turtle: return 6
        case .bunny: return 7
        }
    }

    var blurb: String {
        switch self {
        case .crab: return "Scuttles sideways, cheers you on"
        case .duck: return "Waddles around your island"
        case .cat: return "Naps in the sunniest spot"
        case .frog: return "Hops between lily pads"
        case .turtle: return "Slow and steady wins"
        case .bunny: return "Bounces with every streak"
        }
    }

    /// Wander speed in tiles per second.
    var speed: CGFloat {
        switch self {
        case .crab: return 0.55
        case .duck: return 0.7
        case .cat: return 0.5
        case .frog: return 0.8
        case .turtle: return 0.3
        case .bunny: return 0.9
        }
    }

    var hops: Bool { self == .frog || self == .bunny }
}
