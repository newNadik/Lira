import Foundation

struct DailyHealthMetrics: Codable {
    var steps: Double
    var daylightMinutes: Double
    var exerciseMinutes: Double
    var sleepHours: Double

    static let zero = DailyHealthMetrics(steps: 0, daylightMinutes: 0, exerciseMinutes: 0, sleepHours: 0)
}

enum BuildKind: String, Codable {
    case house
    case greenhouse
    case school
}

// REPLACE BuildItem + BuildingSpec with a single Building
struct Building: Identifiable, Codable {
    var id: UUID = UUID()
    var kind: BuildKind
    var displayName: String
    var costPoints: Double
    var minTechLevel: Double

    init(kind: BuildKind, displayName: String? = nil, costPoints: Double, minTechLevel: Double) {
        self.kind = kind
        self.displayName = displayName ?? kind.rawValue.capitalized
        self.costPoints = costPoints
        self.minTechLevel = minTechLevel
    }
}

struct SimulationState: Codable {
    var currentDayIndex: Int
    var population: Double
    var foodStockRations: Double
    var housingCapacity: Double
    var sciencePoints: Double
    var exploredRadiusKm: Double
    var technologyLevel: Double
    var greenhouseCount: Double
    var schoolCount: Double
    var buildPoints: Double
    var buildQueue: [Building]
    var activeBuild: Building?
    var activeBuildTotalDays: Int
    var activeBuildDaysRemaining: Int
        
    var eventLog: [String]

    init() {
        currentDayIndex = 1
        population = 8
        foodStockRations = 55
        housingCapacity = 12
        sciencePoints = 0
        exploredRadiusKm = 0
        technologyLevel = 0
        buildPoints = 10
        greenhouseCount = 1
        schoolCount = 0
        buildQueue = []
        eventLog = []
        activeBuild = nil
        activeBuildTotalDays = 0
        activeBuildDaysRemaining = 0
    }
}
