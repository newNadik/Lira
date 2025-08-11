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

        let effectivePopulation = floor(state.population)
        let effectiveBeds = floor(state.housingCapacity)
        
        // Soft-cap runaway food: if rations per person are very high, gently dampen yield
        let bufferPerCapita = (effectivePopulation > 0)
            ? state.foodStockRations / effectivePopulation
            : state.foodStockRations // if pop==0, keep as-is (edge case)
        let start = max(1.0, tuning.foodSoftCapStartDays)
        let alpha = max(0, tuning.foodSoftCapStrength)
        // Damping grows with how far we are beyond the start buffer; never below 50%
        let softCapFactor: Double = (bufferPerCapita <= start)
            ? 1.0
            : max(0.5, 1.0 / (1.0 + alpha * ((bufferPerCapita - start) / start)))

        let dailyYield = state.greenhouseCount * yieldPerGreenhouse * sunlightMultiplier * softCapFactor
        
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
        // Use buffer days (rations per person) to decide priorities
        let effectivePop = max(1.0, floor(state.population))
        let dailyConsumptionCheck = effectivePop * tuning.rationPerPersonPerDay

        let cropVarietyMultiplierCheck = 1 + tuning.cropVarietyMaxUplift * (1 - exp(-state.exploredRadiusKm / tuning.cropVarietyRadiusScaleKm))
        let yieldPerGreenhouseCheck = tuning.baseYieldPerGreenhouse
            * (1 + tuning.yieldTechBonusPerLevel * state.technologyLevel)
            * cropVarietyMultiplierCheck
        let dailyYieldCheck = state.greenhouseCount * yieldPerGreenhouseCheck // baseline; zero-daylight never penalizes

        let bufferDays = state.foodStockRations / dailyConsumptionCheck
        let freeBeds = Int(floor(state.housingCapacity - effectivePop))

        // Eligible specs by tech
        let eligible = Config.buildingCatalog.filter { $0.minTechLevel <= state.technologyLevel }
        
        // If there is nothing planned, pick something from the catalog based on current needs
        if state.buildQueue.isEmpty {
            // (keep your existing effectivePop/bufferDays/freeBeds/eligible calcs)

            let desiredKind: BuildKind? = {
                if bufferDays < tuning.foodBufferTargetDays,
                   state.greenhouseCount < tuning.greenhousesPerCapitaTarget * effectivePop,
                   eligible.contains(where: { $0.kind == .greenhouse }) {
                    return .greenhouse
                }

                let overbuildGuard = (state.housingCapacity < (effectivePop + tuning.housingOverbuildBeds))
                if freeBeds < 2, overbuildGuard,
                   eligible.contains(where: { $0.kind == .house }) {
                    return .house
                }

                let targetSchools = floor(effectivePop / max(1.0, tuning.studentsPerSchool))
                if state.schoolCount < targetSchools,
                   eligible.contains(where: { $0.kind == .school }) {
                    return .school
                }

                // No current need → don't enqueue anything.
                return nil
            }()

            if let kind = desiredKind {
                // Highest tier available for that kind at current tech
                let candidates = eligible.filter { $0.kind == kind }
                if let spec = candidates.max(by: { $0.minTechLevel < $1.minTechLevel }) {
                    state.buildQueue.append(
                        Building(kind: spec.kind,
                                 displayName: spec.displayName,
                                 costPoints: spec.costPoints,
                                 minTechLevel: spec.minTechLevel)
                    )
                    // Optional planning log:
                    // EventGenerator.constructionPlanned(day: state.currentDayIndex, displayName: spec.displayName, state: &state)
                }
            }
        }
        
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
                    let techMult = max(1.0, next.minTechLevel)
                    let bedsAdded = 4.0 * techMult   // 4 beds baseline, scaled by tech
                    state.housingCapacity += bedsAdded
                    EventGenerator.builtHouse(day: state.currentDayIndex, state: &state, displayName: next.displayName, bedsAdded: Int(bedsAdded))
                case .greenhouse:
                    state.greenhouseCount += 1
                    EventGenerator.builtGreenhouse(day: state.currentDayIndex, state: &state, displayName: next.displayName)
                case .school:
                    state.technologyLevel += 0.5
                    state.schoolCount += 1
                    EventGenerator.openedSchool(day: state.currentDayIndex, state: &state, displayName: next.displayName)
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

        // Cozy rule: no deaths; if food is zero, growth pauses.
        // Add a small comfort bonus to births when the pantry is healthy.
        let baseBirths = tuning.basePopulationGrowthRate * state.population * capacityFactor * foodFactor

        let bufferDaysForBonus = (effectivePopulation > 0)
            ? state.foodStockRations / (effectivePopulation * tuning.rationPerPersonPerDay)
            : 0
        let t0 = tuning.foodBufferTargetDays
        let tMax = max(t0 + 0.1, tuning.birthsComfortAtDays)
        let comfortProgress = max(0, min(1, (bufferDaysForBonus - t0) / (tMax - t0)))
        let comfortMult = 1.0 + tuning.birthsComfortBonusMax * comfortProgress

        let births = shortageToday ? 0 : (baseBirths * comfortMult)
        let deaths: Double = 0

        let previousPopulation = state.population
        state.population = max(0, state.population + births - deaths)

        if floor(state.population) > floor(previousPopulation) {
            let delta = Int(floor(state.population) - floor(previousPopulation))
            EventGenerator.arrivals(day: state.currentDayIndex, count: delta, state: &state)
        }
    }
}
