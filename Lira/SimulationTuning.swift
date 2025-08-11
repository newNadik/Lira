import Foundation

public struct SimTuning {
    // MARK: Passive progress (works even with zero health metrics)
    public var passiveExplorationKmPerDay: Double = 0.15
    public var passiveSciencePointsPerDay: Double = 1.5
    public var baseBuildPointsPerDay: Double = 3.0

    // MARK: Exploration (health-boosted)
    public var explorationPerSqrtSteps: Double = 0.6              // km per sqrt(steps/1000)
    public var explorationTechMultiplierPerLevel: Double = 0.03    // tech makes scouting more efficient

    // MARK: Sunlight -> crops (zero daylight never penalizes)
    public var sunlightMultiplierAlpha: Double = 0.6               // max extra multiplier from daylight
    public var sunlightHalfSaturationMinutes: Double = 120         // ~2h gives half the bonus

    // MARK: Building speed (exercise helps)
    public var buildPerSqrtExercise: Double = 0.7
    public var buildTechBonusPerLevel: Double = 0.08

    // MARK: Science (sleep helps)
    public var sciencePerSleepQuality: Double = 1.0
    public var sleepOptimalHours: Double = 7.5
    public var sleepSigma: Double = 1.2                             // Gaussian width around optimal sleep
    public var scienceTechBonusPerLevel: Double = 0.05
    public var scienceBreakthroughThreshold: Double = 30            // points per tech level

    // MARK: Food / yields
    public var rationPerPersonPerDay: Double = 1.0
    public var baseYieldPerGreenhouse: Double = 3.0
    public var yieldTechBonusPerLevel: Double = 0.05
    public var cropVarietyMaxUplift: Double = 0.5                   // asymptotic boost from exploration
    public var cropVarietyRadiusScaleKm: Double = 10.0              // exploration scale for variety

    // MARK: Population
    public var basePopulationGrowthRate: Double = 0.15              // births/day at ideal gates
    public var starvationDeathRate: Double = 0.02                   // deaths/day if food == 0

    // MARK: UX thresholds
    public var minArrivalAnnouncement: Double = 0.1                 // not used now (we log on int change)
    
    // Balancing: food soft-cap & comfort growth
    public var foodBufferTargetDays: Double = 1.3      // target rations per person
    public var foodSoftCapStartDays: Double = 10.0     // start damping yield above this buffer
    public var foodSoftCapStrength: Double = 0.6       // higher = stronger damping

    public var birthsComfortBonusMax: Double = 0.25    // +25% max boost when pantry is very comfy
    public var birthsComfortAtDays: Double = 12.0      // reach max bonus by this buffer

    // Planning guard: don't overbuild housing
    public var housingOverbuildBeds: Double = 6.0      // only add beds if free beds < 2 AND
                                                       // total beds < population + this
    public var greenhousesPerCapitaTarget: Double = 2.0
    public var studentsPerSchool: Double = 12.0  // target: one school per 12 settlers
}
