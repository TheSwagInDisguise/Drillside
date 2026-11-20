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
    static let maxIsland = 9

    static func xpNeeded(forLevel level: Int) -> Int { 100 + (max(1, level) - 1) * 50 }

    static func expandPrice(from size: Int) -> Int { 150 + (size - minIsland) * 100 }

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
