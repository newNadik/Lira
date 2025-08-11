import Foundation

struct DailyHealthMetrics: Codable {
    var steps: Double
    var daylightMinutes: Double
    var exerciseMinutes: Double
    var sleepHours: Double

    static let zero = DailyHealthMetrics(steps: 0, daylightMinutes: 0, exerciseMinutes: 0, sleepHours: 0)
}

struct BuildItem: Identifiable, Codable {
    enum BuildKind: String, Codable {
        case house
        case greenhouse
        case school
    }

    var id: UUID = UUID()
    var kind: BuildKind
    var costPoints: Double
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
    var buildPoints: Double
    var buildQueue: [BuildItem]
    var eventLog: [String]

    init() {
        currentDayIndex = 0
        population = 8
        foodStockRations = 50
        housingCapacity = 12
        sciencePoints = 0
        exploredRadiusKm = 0
        technologyLevel = 0
        buildPoints = 0
        greenhouseCount = 1
        buildQueue = []
        eventLog = []
    }
}
