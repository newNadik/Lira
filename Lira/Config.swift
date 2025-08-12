import Foundation

struct Config {
    static let tickIntervalSecDev: TimeInterval = 3.0       // 1 day = 3s (DEV)
    static let tickIntervalSecProd: TimeInterval = 86_400.0 // 1 day = 24h (PROD)
    static let isDevMode: Bool = true
    
    static var tickInterval: TimeInterval {
        isDevMode ? tickIntervalSecDev : tickIntervalSecProd
    }
    
    /// Default starter plans for a fresh colony.
    static var initialBuildQueue: [Building] {
        [
            Building(kind: .greenhouse, displayName: "Greenhouse",     costPoints: 20, minTechLevel: 0.0)
        ]
    }
    
    /// Catalog of available buildings with cost and tech requirements.
    static let buildingCatalog: [Building] = [
        // Food Production
        Building(kind: .greenhouse, displayName: "Greenhouse",     costPoints: 15, minTechLevel: 0.0),
        Building(kind: .greenhouse, displayName: "Hydroponics Bay", costPoints: 35, minTechLevel: 2.0),
        Building(kind: .greenhouse, displayName: "Vertical Farm",   costPoints: 55, minTechLevel: 3.0),
        
        // Housing
        Building(kind: .house, displayName: "Small Cabin",      costPoints: 20, minTechLevel: 0.0),
        Building(kind: .house, displayName: "Apartment Block",  costPoints: 30, minTechLevel: 2.0),
        Building(kind: .house, displayName: "Residential Dome", costPoints: 50, minTechLevel: 3.0),
        
        // Infrastructure / Tech
        Building(kind: .school, displayName: "School",         costPoints: 40, minTechLevel: 0.0),
        Building(kind: .school, displayName: "Research Lab",   costPoints: 60, minTechLevel: 2.0),
        Building(kind: .school, displayName: "Science Complex", costPoints: 85, minTechLevel: 3.0)
    ]
}
