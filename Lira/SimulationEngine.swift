import Foundation

struct SimulationEngine {
    var tuning = SimTuning()
    private var buildDayAccumulator: Double = 0 // accumulates fractional days for construction
    init() {}

    mutating func advanceOneDay(state: inout SimulationState,
                                       health: DailyHealthMetrics? = .zero,
                                       useZeroWhenNil: Bool = true) {
        // Keep the original day-based API, but route through a fraction-based engine.
        // Here, `health` is interpreted as a full-day total (as before).
        let m: DailyHealthMetrics = {
            if let health { return health }
            return useZeroWhenNil ? .zero : .zero
        }()

        // Advance exactly one full in-game day.
        advanceFractionOfDay(state: &state, healthDeltas: m, fractionOfDay: 1.0, emitDailySummary: true)
    }

    // MARK: - Real-time friendly partial-day advance
    /// Advances the simulation by a fraction of a day.
    /// - Parameters:
    ///   - state: Simulation state to mutate.
    ///   - healthDeltas: Health *deltas since the last call* (for real-time). If you call this once per full day, pass the day totals.
    ///   - fractionOfDay: 0..1 (can be less than 1 for partial progress). Multiple calls may be made per real day.
    ///   - emitDailySummary: If true, emits the once-per-day summary events (used by the legacy one-day step).
    mutating func advanceFractionOfDay(state: inout SimulationState,
                                       healthDeltas: DailyHealthMetrics = .zero,
                                       fractionOfDay f: Double,
                                       emitDailySummary: Bool = false) {
        // Clamp fraction to sensible bounds
        let f = max(0.0, min(1.0, f))
        if f == 0 { return }

        // --- HEALTH INFLUENCES (interpret deltas for partial updates) ---
        // Steps/exercise are treated as deltas since the previous tick.
        let explorationDeltaFromSteps = tuning.explorationPerSqrtSteps * sqrt(max(healthDeltas.steps, 0) / 1000.0)
        let sunlightMultiplierRaw = 1 + tuning.sunlightMultiplierAlpha * (healthDeltas.daylightMinutes / (healthDeltas.daylightMinutes + tuning.sunlightHalfSaturationMinutes))
        let sunlightMultiplier = max(1.0, sunlightMultiplierRaw) // never penalize zero daylight
        let buildPointGainFromExercise = tuning.buildPerSqrtExercise * sqrt(max(healthDeltas.exerciseMinutes, 0))

        // Sleep is better applied as a gentle trickle over the day fraction
        let sleepQualityFactor = exp(-pow((healthDeltas.sleepHours - tuning.sleepOptimalHours), 2) / (2 * pow(tuning.sleepSigma, 2)))
        let sciencePointGainFromSleep = tuning.sciencePerSleepQuality * sleepQualityFactor * f

        // -- Keep previous values for milestone detection --
        let previousExplored = state.exploredRadiusKm
        _ = state.buildPoints

        // 2) Exploration (passive per-day scaled by f + steps delta + tech bonus)
        let explorationToday = (tuning.passiveExplorationKmPerDay * f) + explorationDeltaFromSteps
        state.exploredRadiusKm += explorationToday * (1 + tuning.explorationTechMultiplierPerLevel * state.technologyLevel)

        // Milestone: whole-km crossings (handle multiple in a partial)
        let prevKm = Int(floor(previousExplored))
        let newKm = Int(floor(state.exploredRadiusKm))
        if newKm > prevKm {
            for km in (prevKm + 1)...newKm {
                EventGenerator.explorationMilestone(day: state.currentDayIndex, km: km, state: &state)
            }
        }
        // Live exploration ping (lightweight)
        let deltaKm = max(0, state.exploredRadiusKm - previousExplored)
        EventGenerator.explorationDaily(day: state.currentDayIndex, deltaKm: deltaKm, totalKm: state.exploredRadiusKm, state: &state)

        // 3) Food production and consumption (scale daily rates by f)
        let cropVarietyMultiplier = 1 + tuning.cropVarietyMaxUplift * (1 - exp(-state.exploredRadiusKm / tuning.cropVarietyRadiusScaleKm))
        let yieldPerGreenhouse = tuning.baseYieldPerGreenhouse * (1 + tuning.yieldTechBonusPerLevel * state.technologyLevel) * cropVarietyMultiplier

        let effectivePopulation = floor(state.population)
        let effectiveBeds = floor(state.housingCapacity)

        // Soft-cap runaway food: same as before
        let bufferPerCapita = (effectivePopulation > 0)
            ? state.foodStockRations / effectivePopulation
            : state.foodStockRations
        let start = max(1.0, tuning.foodSoftCapStartDays)
        let alpha = max(0, tuning.foodSoftCapStrength)
        let softCapFactor: Double = (bufferPerCapita <= start)
            ? 1.0
            : max(0.5, 1.0 / (1.0 + alpha * ((bufferPerCapita - start) / start)))

        let yieldPerDay = state.greenhouseCount * yieldPerGreenhouse * sunlightMultiplier * softCapFactor
        let consumptionPerDay = effectivePopulation * tuning.rationPerPersonPerDay

        let previousFood = state.foodStockRations
        state.foodStockRations = max(0, state.foodStockRations + (yieldPerDay - consumptionPerDay) * f)
        let shortageToday = (state.foodStockRations == 0)
        let shortageStarted = previousFood > 0 && shortageToday
        if shortageStarted {
            EventGenerator.growthPausedForFood(day: state.currentDayIndex, state: &state)
        }

        let foodSurplusRatio = (yieldPerDay - consumptionPerDay) / max(consumptionPerDay, 1)
        let clampedFoodSurplus = max(-1, min(1, foodSurplusRatio))

        // Surplus/Deficit event (kept modest)
        let netFood = (yieldPerDay - consumptionPerDay) * f
        if netFood > 2 {
            EventGenerator.foodSurplus(day: state.currentDayIndex, surplus: Int(netFood.rounded()), state: &state)
        } else if netFood < -2 {
            EventGenerator.generalInfo(day: state.currentDayIndex, message: "Food deficit today (~\(Int((-netFood).rounded())) rations)", state: &state)
        }

        // 4) Building (passive per-day scaled by f + exercise + tech bonus)
        let effectivePop = max(1.0, floor(state.population))
        let dailyConsumptionCheck = effectivePop * tuning.rationPerPersonPerDay

        let cropVarietyMultiplierCheck = 1 + tuning.cropVarietyMaxUplift * (1 - exp(-state.exploredRadiusKm / tuning.cropVarietyRadiusScaleKm))
        let yieldPerGreenhouseCheck = tuning.baseYieldPerGreenhouse
            * (1 + tuning.yieldTechBonusPerLevel * state.technologyLevel)
            * cropVarietyMultiplierCheck
        _ = state.greenhouseCount * yieldPerGreenhouseCheck

        let bufferDays = state.foodStockRations / dailyConsumptionCheck
        let freeBeds = Int(floor(state.housingCapacity - effectivePop))

        if freeBeds <= 0 {
            EventGenerator.populationCapReached(day: state.currentDayIndex, state: &state)
        }

        let eligible = Config.buildingCatalog.filter { $0.minTechLevel <= state.technologyLevel }

        if state.buildQueue.isEmpty {
            let desiredKind: BuildKind? = {
                if bufferDays < tuning.foodBufferTargetDays,
                   state.greenhouseCount < tuning.greenhousesPerCapitaTarget * effectivePop,
                   eligible.contains(where: { $0.kind == .greenhouse }) { return .greenhouse }

                let overbuildGuard = (state.housingCapacity < (effectivePop + tuning.housingOverbuildBeds))
                if freeBeds < 2, overbuildGuard,
                   eligible.contains(where: { $0.kind == .house }) { return .house }

                let targetSchools = floor(effectivePop / max(1.0, tuning.studentsPerSchool))
                if state.schoolCount < targetSchools,
                   eligible.contains(where: { $0.kind == .school }) { return .school }

                EventGenerator.idleBuilders(day: state.currentDayIndex, state: &state)
                return nil
            }()

            if let kind = desiredKind {
                let candidates = eligible.filter { $0.kind == kind }
                if let spec = candidates.max(by: { $0.minTechLevel < $1.minTechLevel }) {
                    state.buildQueue.append(
                        Building(kind: spec.kind,
                                 displayName: spec.displayName,
                                 costPoints: spec.costPoints,
                                 minTechLevel: spec.minTechLevel)
                    )
                    EventGenerator.constructionPlanned(day: state.currentDayIndex, name: spec.displayName, state: &state)
                }
            }
        }

        // Accrue build points continuously
        state.buildPoints += (tuning.baseBuildPointsPerDay * f + buildPointGainFromExercise) * (1 + tuning.buildTechBonusPerLevel * state.technologyLevel)

        // If we have an active build, consume fractional days via accumulator; else try to start one
        if let active = state.activeBuild {
            let total = max(1, state.activeBuildTotalDays)
            let before = state.activeBuildDaysRemaining

            // Convert fractional day progress into whole-day decrements
            buildDayAccumulator += f
            var remaining = before
            while buildDayAccumulator >= 1.0 && remaining > 0 {
                remaining -= 1
                buildDayAccumulator -= 1.0
            }
            state.activeBuildDaysRemaining = max(0, remaining)
            let after = state.activeBuildDaysRemaining

            // Progress milestones at 25/50/75% based on days elapsed
            let completedFracBefore = 1.0 - (Double(before) / Double(total))
            let completedFracAfter  = 1.0 - (Double(after)  / Double(total))
            for m in [0.25, 0.5, 0.75] where completedFracBefore < m && completedFracAfter >= m {
                EventGenerator.constructionProgress(day: state.currentDayIndex, displayName: active.displayName, percent: Int(m * 100), state: &state)
            }

            if state.activeBuildDaysRemaining == 0 {
                switch active.kind {
                case .house:
                    let techMult = 1.0 + active.minTechLevel
                    let bedsAdded = 4.0 * techMult
                    state.housingCapacity += bedsAdded
                    EventGenerator.builtHouse(day: state.currentDayIndex, state: &state, displayName: active.displayName, bedsAdded: Int(bedsAdded))
                case .greenhouse:
                    state.greenhouseCount += 1
                    EventGenerator.builtGreenhouse(day: state.currentDayIndex, state: &state, displayName: active.displayName)
                case .school:
                    state.technologyLevel += 0.5
                    state.schoolCount += 1
                    EventGenerator.openedSchool(day: state.currentDayIndex, state: &state, displayName: active.displayName)
                }
                state.activeBuild = nil
                state.activeBuildTotalDays = 0
            }
        } else if let next = state.buildQueue.first, state.buildPoints >= next.costPoints {
            state.buildPoints -= next.costPoints
            let totalDays = Int(max(1.0, next.minTechLevel))
            state.activeBuild = next
            state.activeBuildDaysRemaining = totalDays
            state.activeBuildTotalDays = totalDays
            EventGenerator.constructionStarted(day: state.currentDayIndex, name: next.displayName, days: totalDays, state: &state)
            _ = state.buildQueue.removeFirst()
        }

        // 5) Science (passive per-day scaled by f + sleep drip + tech bonus)
        state.sciencePoints += (tuning.passiveSciencePointsPerDay * f + sciencePointGainFromSleep) * (1 + tuning.scienceTechBonusPerLevel * state.technologyLevel)
        if state.sciencePoints >= tuning.scienceBreakthroughThreshold {
            state.sciencePoints -= tuning.scienceBreakthroughThreshold
            state.technologyLevel += 1
            EventGenerator.breakthrough(day: state.currentDayIndex, techLevel: Int(state.technologyLevel), state: &state)
        }

        // 6) Population (scale the growth by f)
        let capacityFactor = max(0, min(1, (effectiveBeds - effectivePopulation) / max(effectivePopulation, 1)))
        let foodFactor = max(0, min(1, 0.55 + 0.45 * clampedFoodSurplus))

        let baseBirths = tuning.basePopulationGrowthRate * (state.population/2) * capacityFactor * foodFactor

        let bufferDaysForBonus = (effectivePopulation > 0)
            ? state.foodStockRations / (effectivePopulation * tuning.rationPerPersonPerDay)
            : 0
        let t0 = tuning.foodBufferTargetDays
        let tMax = max(t0 + 0.1, tuning.birthsComfortAtDays)
        let comfortProgress = max(0, min(1, (bufferDaysForBonus - t0) / (tMax - t0)))
        let comfortMult = 1.0 + tuning.birthsComfortBonusMax * comfortProgress

        let births = shortageToday ? 0 : (baseBirths * comfortMult * f)
        let previousPopulation = state.population
        state.population = max(0, state.population + births)

        if floor(state.population) > floor(previousPopulation) {
            let delta = Int(floor(state.population) - floor(previousPopulation))
            EventGenerator.arrivals(day: state.currentDayIndex, count: delta, state: &state)
        }

        // For legacy callers that step exactly once per day, keep the daily summary emission
        if emitDailySummary {
            // Daily exploration summary at end of day
            EventGenerator.explorationDaily(day: state.currentDayIndex, deltaKm: max(0, state.exploredRadiusKm - previousExplored), totalKm: state.exploredRadiusKm, state: &state)

            // Advance the day index because we've simulated a full day here
            state.currentDayIndex += 1
        }
    }
}
