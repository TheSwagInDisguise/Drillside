import Foundation

enum Economy {
    static let habitXP = 5
    static let habitShells = 2
    static let logXP = 10
    static let logShells = 5
    /// Each fully completed focus minute pays 1 XP and 1 shell.
    static let xpPerFocusMinute = 1
    static let shellsPerFocusMinute = 1

    static let minIsland = 6
    static let maxIsland = 16

    static func xpNeeded(forLevel level: Int) -> Int { 100 + (max(1, level) - 1) * 50 }

    /// Cost of growing the island from `size`×`size` to (size+1)×(size+1). Gets steeper as the island grows.
    static func expandPrice(from size: Int) -> Int {
        let k = max(0, size - minIsland)
        return 150 + k * 120 + k * k * 15
    }

    /// Player level required to grow the island to `size`×`size` (7×7 needs level 2 … 16×16 needs level 11).
    static func expandLevel(to size: Int) -> Int { max(1, size - 5) }

    struct Wallet: Equatable {
        var level: Int
        var xp: Int
        var shells: Int

        /// Applies a reward (or a reversal when negative). Returns how many levels were gained.
        @discardableResult
        mutating func apply(xp dx: Int, shells ds: Int) -> Int {
            xp = max(0, xp + dx)
            shells = max(0, shells + ds)
            var gained = 0
            while xp >= Economy.xpNeeded(forLevel: level) {
                xp -= Economy.xpNeeded(forLevel: level)
                level += 1
                gained += 1
            }
            return gained
        }
    }
}
