import SwiftUI

struct LightSource {
    var r: Double, g: Double, b: Double
    var radius: CGFloat
    var dx: CGFloat = 0
    var dy: CGFloat = 0
    var flickers = false
    var color: Color { Color(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: 1) }
}

enum PropCategory: String, CaseIterable, Identifiable {
    case nature, cozy, landmarks, study, lights, terrain, trophies
    var id: String { rawValue }
    /// Categories sold in the shop (trophies are earned through achievements only).
    static var shop: [PropCategory] { allCases.filter { $0 != .trophies } }
    var title: String {
        switch self {
        case .nature: return "Nature"
        case .cozy: return "Cozy"
        case .landmarks: return "Landmarks"
        case .study: return "Study"
        case .lights: return "Lights"
        case .terrain: return "Terrain"
        case .trophies: return "Trophies"
        }
    }
    var icon: String {
        switch self {
        case .nature: return "leaf.fill"
        case .cozy: return "sofa.fill"
        case .landmarks: return "building.columns.fill"
        case .study: return "book.fill"
        case .lights: return "lightbulb.fill"
        case .terrain: return "square.grid.3x3.fill"
        case .trophies: return "trophy.fill"
        }
    }
}

enum PropType: String, CaseIterable, Codable, Identifiable {
    // Nature
    case bush, rock, flowers, tree, palm, sunflower, pine, mushrooms, cactus, bamboo, cherry, pumpkins
    case stump, tulips, fern, birch, maple, bonsai
    // Cozy
    case campfire, bench, mailbox, umbrella, hammock, picnic, tent, well
    case barrel, crates, beachchair, swing, rowboat
    // Landmarks
    case cabin, windmill, lighthouse, gazebo, fountain, treehouse, balloon, statue
    // Study
    case signpost, workbench, bookshelf, chalkboard, easel, telescope
    case noticeboard, globe, desk, trophy
    // Lights
    case lantern, torch, streetlamp, fireflies
    case candles, fairyarch, jackolantern, crystal
    // Terrain (flat)
    case sand, path, meadow, deck, pond
    case cobble, snow, mosaic
    // Trophies (achievement rewards, not for sale)
    case pennant, bell, obelisk, rainbow

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
        case .cabin: return Info(name: "Cozy Cabin", short: "Cabin", price: 400, level: 8, category: .landmarks, blurb: "A home base with a warm window", action: "🏡 cozy break", tall: 56)
        case .windmill: return Info(name: "Windmill", short: "Windmill", price: 350, level: 9, category: .landmarks, blurb: "Small turns, big power", action: "🌬️ watching blades", tall: 66)
        case .lighthouse: return Info(name: "Lighthouse", short: "Lighthouse", price: 600, level: 12, category: .landmarks, blurb: "Guides you home at night", action: "🗼 keeping watch", tall: 74)
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
        case .stump: return Info(name: "Tree Stump", short: "Stump", price: 12, level: 1, category: .nature, blurb: "Rings of past effort", action: "🪵 counting rings", tall: 18)
        case .tulips: return Info(name: "Tulip Bed", short: "Tulips", price: 25, level: 2, category: .nature, blurb: "Spring in a patch", action: "🌷 admiring tulips", tall: 20)
        case .fern: return Info(name: "Fern", short: "Fern", price: 30, level: 2, category: .nature, blurb: "Unfurls a little each day", action: "🌿 shade nap", tall: 20)
        case .birch: return Info(name: "Birch Tree", short: "Birch", price: 55, level: 3, category: .nature, blurb: "Tall, light and bright", action: "🌳 leaning on birch", tall: 54)
        case .maple: return Info(name: "Autumn Maple", short: "Maple", price: 120, level: 8, category: .nature, blurb: "Leaves of every colour", action: "🍁 leaf catching", tall: 50)
        case .bonsai: return Info(name: "Bonsai", short: "Bonsai", price: 260, level: 10, category: .nature, blurb: "Patience, pruned", action: "✂️ careful pruning", tall: 30)
        case .barrel: return Info(name: "Rain Barrel", short: "Barrel", price: 30, level: 2, category: .cozy, blurb: "Saves every drop", action: "💧 splashing", tall: 20)
        case .crates: return Info(name: "Supply Crates", short: "Crates", price: 35, level: 2, category: .cozy, blurb: "Stocked for the week", action: "📦 unpacking", tall: 24)
        case .beachchair: return Info(name: "Beach Chair", short: "Chair", price: 65, level: 3, category: .cozy, blurb: "Feet up, phone down", action: "😎 lounging", tall: 22)
        case .swing: return Info(name: "Swing Set", short: "Swing", price: 140, level: 6, category: .cozy, blurb: "Play is part of the plan", action: "🎠 swinging", tall: 34)
        case .rowboat: return Info(name: "Rowboat", short: "Boat", price: 160, level: 7, category: .cozy, blurb: "Ready for a little adventure", action: "🚣 rowing practice", tall: 14)
        case .gazebo: return Info(name: "Garden Gazebo", short: "Gazebo", price: 450, level: 9, category: .landmarks, blurb: "A calm spot for big thinking", action: "🍵 tea break", tall: 52)
        case .fountain: return Info(name: "Fountain", short: "Fountain", price: 500, level: 10, category: .landmarks, blurb: "Momentum, flowing", action: "⛲ coin toss", tall: 34)
        case .treehouse: return Info(name: "Treehouse", short: "Treehouse", price: 700, level: 11, category: .landmarks, blurb: "A hideout above it all", action: "🪜 climbing up", tall: 72)
        case .balloon: return Info(name: "Hot Air Balloon", short: "Balloon", price: 900, level: 14, category: .landmarks, blurb: "Rise above the noise", action: "🎈 sky dreaming", tall: 76)
        case .statue: return Info(name: "Golden Bitsy", short: "Statue", price: 1200, level: 15, category: .landmarks, blurb: "Monument to your consistency", action: "🏆 posing proudly", tall: 50)
        case .noticeboard: return Info(name: "Notice Board", short: "Board", price: 70, level: 4, category: .study, blurb: "Pin your top three", action: "📌 pinning notes", tall: 32)
        case .globe: return Info(name: "Desk Globe", short: "Globe", price: 150, level: 6, category: .study, blurb: "Spin to pick a topic", action: "🌍 exploring", tall: 30)
        case .desk: return Info(name: "Study Desk", short: "Desk", price: 180, level: 7, category: .study, blurb: "Laptop, lamp and a mug", action: "💻 deep work", tall: 28)
        case .trophy: return Info(name: "Trophy Pedestal", short: "Trophy", price: 300, level: 9, category: .study, blurb: "For streaks well kept", action: "🏅 polishing", tall: 34)
        case .candles: return Info(name: "Candle Cluster", short: "Candles", price: 40, level: 4, category: .lights, blurb: "Soft light for reflection", action: "🕯️ quiet moment", tall: 16)
        case .fairyarch: return Info(name: "Fairy-Light Arch", short: "Arch", price: 130, level: 5, category: .lights, blurb: "Twinkles at dusk", action: "✨ twinkle walk", tall: 42)
        case .jackolantern: return Info(name: "Jack-o’-Lantern", short: "Jack", price: 85, level: 7, category: .lights, blurb: "A friendly glowing grin", action: "🎃 spooky grin", tall: 18)
        case .crystal: return Info(name: "Glow Crystal", short: "Crystal", price: 220, level: 10, category: .lights, blurb: "Hums with purple light", action: "🔮 crystal gazing", tall: 30)
        case .cobble: return Info(name: "Cobblestones", short: "Cobble", price: 18, level: 4, category: .terrain, blurb: "Walkable · old-town charm", action: "👣 strolling", tall: 8)
        case .snow: return Info(name: "Snow Patch", short: "Snow", price: 15, level: 6, category: .terrain, blurb: "Walkable · always winter", action: "❄️ snow angels", tall: 8)
        case .mosaic: return Info(name: "Mosaic Tiles", short: "Mosaic", price: 45, level: 9, category: .terrain, blurb: "Walkable · colourful", action: "🎨 hopscotch", tall: 8)
        case .pennant: return Info(name: "Streak Pennant", short: "Pennant", price: 0, level: 1, category: .trophies, blurb: "Earned: a 7-day streak", action: "🚩 waving the flag", tall: 40)
        case .bell: return Info(name: "Check-in Bell", short: "Bell", price: 0, level: 1, category: .trophies, blurb: "Earned: 30-day log streak", action: "🔔 ringing in the day", tall: 40)
        case .obelisk: return Info(name: "Focus Obelisk", short: "Obelisk", price: 0, level: 1, category: .trophies, blurb: "Earned: 100 focus hours", action: "💎 humming along", tall: 50)
        case .rainbow: return Info(name: "Rainbow Arch", short: "Rainbow", price: 0, level: 1, category: .trophies, blurb: "Earned: reach level 10", action: "🌈 over the rainbow", tall: 44)
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
    /// Props that float above the ground (no tile-anchored base).
    var floats: Bool { self == .balloon }

    var light: LightSource? {
        switch self {
        case .campfire: return LightSource(r: 255, g: 140, b: 50, radius: 95, dy: -8, flickers: true)
        case .lantern: return LightSource(r: 255, g: 215, b: 120, radius: 70, dx: 6.5, dy: -22)
        case .tent: return LightSource(r: 255, g: 200, b: 120, radius: 42, dy: -6)
        case .torch: return LightSource(r: 255, g: 150, b: 60, radius: 62, dy: -27, flickers: true)
        case .candles: return LightSource(r: 255, g: 190, b: 90, radius: 50, dy: -10, flickers: true)
        case .fairyarch: return LightSource(r: 255, g: 220, b: 150, radius: 72, dy: -22)
        case .jackolantern: return LightSource(r: 255, g: 160, b: 60, radius: 52, dy: -6, flickers: true)
        case .crystal: return LightSource(r: 190, g: 140, b: 255, radius: 70, dy: -14)
        case .treehouse: return LightSource(r: 255, g: 200, b: 110, radius: 55, dy: -50)
        case .gazebo: return LightSource(r: 255, g: 210, b: 130, radius: 60, dy: -28)
        case .desk: return LightSource(r: 255, g: 220, b: 160, radius: 40, dx: -6, dy: -18)
        case .balloon: return LightSource(r: 255, g: 150, b: 60, radius: 40, dy: -36, flickers: true)
        case .fountain: return LightSource(r: 140, g: 210, b: 255, radius: 46, dy: -14)
        case .obelisk: return LightSource(r: 120, g: 230, b: 255, radius: 70, dy: -30)
        case .bell: return LightSource(r: 255, g: 210, b: 130, radius: 40, dy: -30)
        case .streetlamp: return LightSource(r: 255, g: 230, b: 150, radius: 88, dx: 9, dy: -34)
        case .fireflies: return LightSource(r: 220, g: 255, b: 120, radius: 44, dy: -8)
        case .cabin: return LightSource(r: 255, g: 200, b: 110, radius: 60, dx: -11, dy: -10)
        case .lighthouse: return LightSource(r: 255, g: 240, b: 170, radius: 130, dy: -57)
        default: return nil
        }
    }

    var isExclusive: Bool { category == .trophies }

    static func items(in category: PropCategory) -> [PropType] {
        allCases.filter { $0.category == category }.sorted { ($0.unlockLevel, $0.price) < ($1.unlockLevel, $1.price) }
    }
}

enum CompanionType: String, CaseIterable, Codable, Identifiable {
    case crab, duck, cat, frog, turtle, bunny, fox, penguin, owl

    var id: String { rawValue }

    var name: String {
        switch self {
        case .crab: return "Pinch the Crab"
        case .duck: return "Puddle the Duckling"
        case .cat: return "Biscuit the Cat"
        case .frog: return "Hops the Frog"
        case .turtle: return "Sage the Turtle"
        case .bunny: return "Clover the Bunny"
        case .fox: return "Rusty the Fox"
        case .penguin: return "Pip the Penguin"
        case .owl: return "Hoot the Owl"
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
        case .fox: return 320
        case .penguin: return 340
        case .owl: return 380
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
        case .fox: return 8
        case .penguin: return 9
        case .owl: return 10
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
        case .fox: return "Clever, curious, quick"
        case .penguin: return "Waddles with purpose"
        case .owl: return "Wise night watcher"
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
        case .fox: return 0.75
        case .penguin: return 0.4
        case .owl: return 0.25
        }
    }

    var hops: Bool { self == .frog || self == .bunny }
}

/// Ground styles for the whole island. Classic is free; others are bought with shells.
enum IslandTheme: String, CaseIterable, Identifiable {
    case classic, atoll, autumn, snowy, volcanic

    var id: String { rawValue }

    var name: String {
        switch self {
        case .classic: return "Classic Meadow"
        case .atoll: return "Sandy Atoll"
        case .autumn: return "Autumn Glade"
        case .snowy: return "Snowy Isle"
        case .volcanic: return "Volcanic Rock"
        }
    }

    var blurb: String {
        switch self {
        case .classic: return "Soft green grass"
        case .atoll: return "Sun-bleached sand and dune grass"
        case .autumn: return "Golden grass all year round"
        case .snowy: return "Fresh snow with icy cliffs"
        case .volcanic: return "Dark basalt with glowing lava seams"
        }
    }

    var price: Int {
        switch self {
        case .classic: return 0
        case .atoll: return 400
        case .autumn: return 600
        case .snowy: return 800
        case .volcanic: return 1200
        }
    }

    var unlockLevel: Int {
        switch self {
        case .classic: return 1
        case .atoll: return 4
        case .autumn: return 6
        case .snowy: return 8
        case .volcanic: return 11
        }
    }

    struct Palette {
        var grassA: UInt32, grassA2: UInt32, grassB: UInt32, grassB2: UInt32
        var dirtLeft: UInt32, dirtRight: UInt32, lipLeft: UInt32, lipRight: UInt32
        var shore: UInt32
        var lavaGlow = false
    }

    var palette: Palette {
        switch self {
        case .classic:
            return Palette(grassA: 0x8DD26E, grassA2: 0x8FD470, grassB: 0x83C964, grassB2: 0x86CC66,
                           dirtLeft: 0xB8875A, dirtRight: 0x9C6F45, lipLeft: 0x4E9A43, lipRight: 0x438A3A, shore: 0xF1DCA0)
        case .atoll:
            return Palette(grassA: 0xEBD9A6, grassA2: 0xE6D39C, grassB: 0xDFCB90, grassB2: 0xE2CF96,
                           dirtLeft: 0xD9B77E, dirtRight: 0xC29E66, lipLeft: 0x9CC56A, lipRight: 0x8AB55C, shore: 0xF7EBC8)
        case .autumn:
            return Palette(grassA: 0xD9B44A, grassA2: 0xDDB950, grassB: 0xCFA640, grassB2: 0xD3AB45,
                           dirtLeft: 0xA8744A, dirtRight: 0x8E6038, lipLeft: 0xB5852E, lipRight: 0x9E7226, shore: 0xEED39A)
        case .snowy:
            return Palette(grassA: 0xF2F7FB, grassA2: 0xEEF4FA, grassB: 0xE4EDF6, grassB2: 0xE8F0F8,
                           dirtLeft: 0x9FB6CC, dirtRight: 0x8199B2, lipLeft: 0xDCE8F3, lipRight: 0xC9DAEA, shore: 0xE9EEF2)
        case .volcanic:
            return Palette(grassA: 0x4A4550, grassA2: 0x4E4954, grassB: 0x423D48, grassB2: 0x46414C,
                           dirtLeft: 0x2F2A33, dirtRight: 0x25212A, lipLeft: 0xE0552B, lipRight: 0xC8461F, shore: 0x3A3540, lavaGlow: true)
        }
    }
}

enum Season: String {
    case spring, summer, autumn, winter

    static func current(at date: Date = Date(), timeZone: TimeZone = .current, calendar: Calendar = .current) -> Season {
        let month = calendar.component(.month, from: date)
        let southern = SkyClock.isSouthern(timeZone)
        let m = southern ? ((month + 5) % 12) + 1 : month
        switch m {
        case 3, 4, 5: return .spring
        case 6, 7, 8: return .summer
        case 9, 10, 11: return .autumn
        default: return .winter
        }
    }
}
