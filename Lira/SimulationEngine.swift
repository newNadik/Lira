import Foundation

public struct SimulationEngine {
    public var tuning = SimTuning()
    public init() {}

    mutating func advanceOneDay(state: inout SimulationState,
                                       health: DailyHealthMetrics? = .zero,
                                       useZeroWhenNil: Bool = true) {
        state.currentDayIndex += 1

        // Choose metrics (default to ZERO when nil)
        let m: DailyHealthMetrics = {
            if let health { return health }
            return useZeroWhenNil ? .zero : .zero
        }()

        // 1) Modifiers from health
        let explorationDeltaFromSteps = tuning.explorationPerSqrtSteps * sqrt(max(m.steps, 0) / 1000.0)
        let sunlightMultiplierRaw = 1 + tuning.sunlightMultiplierAlpha * (m.daylightMinutes / (m.daylightMinutes + tuning.sunlightHalfSaturationMinutes))
        let sunlightMultiplier = max(1.0, sunlightMultiplierRaw) // never penalize zero daylight
        let buildPointGainFromExercise = tuning.buildPerSqrtExercise * sqrt(max(m.exerciseMinutes, 0))
        let sleepQualityFactor = exp(-pow((m.sleepHours - tuning.sleepOptimalHours), 2) / (2 * pow(tuning.sleepSigma, 2)))
        let sciencePointGainFromSleep = tuning.sciencePerSleepQuality * sleepQualityFactor

        // -- Keep previous values for milestone detection --
        let previousExplored = state.exploredRadiusKm
        let previousBuildPoints = state.buildPoints

        // 2) Exploration (passive + health-boosted + tech bonus)
        let explorationToday = tuning.passiveExplorationKmPerDay + explorationDeltaFromSteps
        state.exploredRadiusKm += explorationToday * (1 + tuning.explorationTechMultiplierPerLevel * state.technologyLevel)

        // Milestone: whole-km crossing
        let prevKm = Int(floor(previousExplored))
        let newKm = Int(floor(state.exploredRadiusKm))
        if newKm > prevKm {
            EventGenerator.explorationMilestone(day: state.currentDayIndex, km: newKm, state: &state)
        }
        // Daily exploration ping
        let deltaKm = max(0, state.exploredRadiusKm - previousExplored)
        EventGenerator.explorationDaily(day: state.currentDayIndex, deltaKm: deltaKm, totalKm: state.exploredRadiusKm, state: &state)

        // 3) Food production and consumption (use integer-effective counts)
        let cropVarietyMultiplier = 1 + tuning.cropVarietyMaxUplift * (1 - exp(-state.exploredRadiusKm / tuning.cropVarietyRadiusScaleKm))
        let yieldPerGreenhouse = tuning.baseYieldPerGreenhouse * (1 + tuning.yieldTechBonusPerLevel * state.technologyLevel) * cropVarietyMultiplier
        let dailyYield = state.greenhouseCount * yieldPerGreenhouse * sunlightMultiplier

        let effectivePopulation = floor(state.population)
        let effectiveBeds = floor(state.housingCapacity)
        let dailyConsumption = effectivePopulation * tuning.rationPerPersonPerDay
        
        let previousFood = state.foodStockRations
        state.foodStockRations = max(0, state.foodStockRations + dailyYield - dailyConsumption)
        let shortageToday = (state.foodStockRations == 0)
        let shortageStarted = previousFood > 0 && shortageToday
        if shortageStarted {
            EventGenerator.growthPausedForFood(day: state.currentDayIndex, state: &state)
        }
        
        let foodSurplusRatio = (dailyYield - dailyConsumption) / max(dailyConsumption, 1)
        let clampedFoodSurplus = max(-1, min(1, foodSurplusRatio))

        // 4) Building (passive + exercise + tech bonus)
        state.buildPoints += (tuning.baseBuildPointsPerDay + buildPointGainFromExercise) * (1 + tuning.buildTechBonusPerLevel * state.technologyLevel)

        // Progress milestones only for the first item; at most one completion/day
        if let next = state.buildQueue.first {
            let prevRatio = previousBuildPoints / max(next.costPoints, 0.0001)
            let newRatio  = state.buildPoints     / max(next.costPoints, 0.0001)
            let milestones: [Double] = [0.25, 0.5, 0.75]
            for milestone in milestones where prevRatio < milestone && newRatio >= milestone {
                EventGenerator.constructionProgress(day: state.currentDayIndex, kind: next.kind, percent: Int(milestone * 100), state: &state)
            }

            if state.buildPoints >= next.costPoints {
                state.buildPoints -= next.costPoints
                switch next.kind {
                case .house:
                    state.housingCapacity += 4
                    EventGenerator.builtHouse(day: state.currentDayIndex, state: &state)
                case .greenhouse:
                    state.greenhouseCount += 1
                    EventGenerator.builtGreenhouse(day: state.currentDayIndex, state: &state)
                case .school:
                    state.technologyLevel += 0.5
                    EventGenerator.openedSchool(day: state.currentDayIndex, state: &state)
                }
                _ = state.buildQueue.removeFirst()
                // Only one completion per day; do not attempt additional builds today.
            }
        }

        // 5) Science (passive + sleep + tech bonus)
        state.sciencePoints += (tuning.passiveSciencePointsPerDay + sciencePointGainFromSleep) * (1 + tuning.scienceTechBonusPerLevel * state.technologyLevel)
        if state.sciencePoints >= tuning.scienceBreakthroughThreshold {
            state.sciencePoints -= tuning.scienceBreakthroughThreshold
            state.technologyLevel += 1
            EventGenerator.breakthrough(day: state.currentDayIndex, techLevel: Int(state.technologyLevel), state: &state)
        }

        // 6) Population (gated by beds + food; integer gating)
        let capacityFactor = max(0, min(1, (effectiveBeds - effectivePopulation) / max(effectivePopulation, 1)))
        let foodFactor = max(0, min(1, 0.55 + 0.45 * clampedFoodSurplus))

        // Cozy rule: no deaths; if food is zero, growth pauses instead.
        let births = shortageToday ? 0 : (tuning.basePopulationGrowthRate * state.population * capacityFactor * foodFactor)
        let deaths: Double = 0

        let previousPopulation = state.population
        state.population = max(0, state.population + births - deaths)

        if floor(state.population) > floor(previousPopulation) {
            let delta = Int(floor(state.population) - floor(previousPopulation))
            EventGenerator.arrivals(day: state.currentDayIndex, count: delta, state: &state)
        }
    }
}
