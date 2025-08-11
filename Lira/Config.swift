import Foundation

struct Config {
    static let tickIntervalSecDev: TimeInterval = 3.0       // 1 day = 3s (DEV)
    static let tickIntervalSecProd: TimeInterval = 86_400.0 // 1 day = 24h (PROD)
    static let isDevMode: Bool = true
    
    static var tickInterval: TimeInterval {
        isDevMode ? tickIntervalSecDev : tickIntervalSecProd
    }
    
    /// Default starter plans for a fresh colony.
    static var initialBuildQueue: [BuildItem] {
        [
            BuildItem(kind: .greenhouse, costPoints: 20),
            BuildItem(kind: .house,      costPoints: 15),
            BuildItem(kind: .school,     costPoints: 40)
        ]
    }
}
