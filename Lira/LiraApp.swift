import SwiftUI
import Foundation
import Combine

// MARK: - LiraSim v3.2 (hands-off, fully automatic, single file)
// The colony advances on its own. No user actions required.
// DEV mode: 1 Lira day = 3 seconds. Change to 86_400 for real-time days.

// ================================================================
// 0) Time scale (DEV vs PROD)
// ================================================================
private let tickIntervalSec: TimeInterval = 3 // DEV fast-forward (1 day / 3s)
// For production, use: private let tickIntervalSec: TimeInterval = 86_400

// ================================================================
// 1) Models
// ================================================================
struct DailyHealthMetrics: Equatable {
    var steps: Double            // steps taken
    var daylightMinutes: Double  // minutes outdoors / daylight
    var exerciseMinutes: Double  // minutes of exercise
    var sleepHours: Double       // hours of sleep

    static let zero = DailyHealthMetrics(steps: 0, daylightMinutes: 0, exerciseMinutes: 0, sleepHours: 0)
}

struct BuildItem: Identifiable, Equatable {
    enum Kind: String, CaseIterable { case house, greenhouse, school }
    let id = UUID()
    let kind: Kind
    let costPoints: Double
}

struct SimulationState: Equatable {
    // Calendar
    var currentDayIndex: Int = 0

    // Colony fundamentals (tuned for zero-health survivability)
    var population: Double = 8              // Liri count
    var housingCapacity: Double = 12        // beds (room to grow)
    var greenhouseCount: Double = 2         // farming capacity day 0
    var foodStockRations: Double = 40       // stored food in person-days

    // Progress stats
    var technologyLevel: Double = 0
    var exploredRadiusKm: Double = 0
    var buildPoints: Double = 0
    var sciencePoints: Double = 0

    // Planning (prioritize greenhouse early to stabilize food)
    var buildQueue: [BuildItem] = [
        .init(kind: .greenhouse, costPoints: 20),
        .init(kind: .house, costPoints: 15),
        .init(kind: .school, costPoints: 40)
    ]

    // UX
    var eventLog: [String] = []
}

// ================================================================
// 2) Tuning — zero-health is slow but survivable
// ================================================================
struct SimTuning {
    // Passive progress (works even when health metrics are zero)
    var passiveExplorationKmPerDay: Double = 0.15     // slow scouting
    var passiveSciencePointsPerDay: Double = 1.5     // thinking at night
    var baseBuildPointsPerDay: Double = 3.0          // steady construction

    // Exploration (health-boosted)
    var explorationPerSqrtSteps: Double = 0.6         // km per sqrt(steps/1000)
    var explorationTechMultiplierPerLevel: Double = 0.03

    // Sunlight → crop multiplier (zero daylight = multiplier 1.0)
    var sunlightMultiplierAlpha: Double = 0.6         // max extra multiplier
    var sunlightHalfSaturationMinutes: Double = 120

    // Building speed from exercise
    var buildPerSqrtExercise: Double = 0.7
    var buildTechBonusPerLevel: Double = 0.08

    // Science from sleep
    var sciencePerSleepQuality: Double = 1.0
    var sleepOptimalHours: Double = 7.5
    var sleepSigma: Double = 1.2                      // gaussian width
    var scienceTechBonusPerLevel: Double = 0.05
    var scienceBreakthroughThreshold: Double = 30

    // Food
    var rationPerPersonPerDay: Double = 1.0
    var baseYieldPerGreenhouse: Double = 4.0          // helps early survival
    var yieldTechBonusPerLevel: Double = 0.15
    var cropVarietyMaxUplift: Double = 0.5
    var cropVarietyRadiusScaleKm: Double = 10

    // Population
    var basePopulationGrowthRate: Double = 0.05      // per day when gated OK
    var starvationDeathRate: Double = 0.02            // gentler than 0.03

    // UX
    var minArrivalAnnouncement: Double = 0.1
}

// ================================================================
// 3) Engine
// ================================================================
struct SimulationEngine {
    var tuning = SimTuning()
    
    // Track construction progress milestones per BuildItem id for the current day
    private var constructionProgressMilestones: [UUID: Set<Double>] = [:]

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

        // 2) Exploration (passive + health-boosted + tech bonus)
        let explorationToday = tuning.passiveExplorationKmPerDay + explorationDeltaFromSteps
        let previousExploredRadiusKm = state.exploredRadiusKm
        state.exploredRadiusKm += explorationToday * (1 + tuning.explorationTechMultiplierPerLevel * state.technologyLevel)

        let prevKm = Int(floor(previousExploredRadiusKm))
        let newKm = Int(floor(state.exploredRadiusKm))
        var explorationLogAdded = false
        if newKm > prevKm {
            state.eventLog.append("Day \(state.currentDayIndex): Scouted out to \(newKm) km.")
            explorationLogAdded = true
        }
        if !explorationLogAdded {
            let deltaKm = state.exploredRadiusKm - previousExploredRadiusKm
            let deltaKmRounded = Double(round(100*deltaKm)/100)
            let totalKmRounded = Double(round(100*state.exploredRadiusKm)/100)
            state.eventLog.append("Day \(state.currentDayIndex): Explored surroundings (+\(deltaKmRounded) km total now \(totalKmRounded) km).")
        }

        // 3) Food production and consumption
        let cropVarietyMultiplier = 1 + tuning.cropVarietyMaxUplift * (1 - exp(-state.exploredRadiusKm / tuning.cropVarietyRadiusScaleKm))
        let yieldPerGreenhouse = tuning.baseYieldPerGreenhouse * (1 + tuning.yieldTechBonusPerLevel * state.technologyLevel) * cropVarietyMultiplier
        let dailyYield = state.greenhouseCount * yieldPerGreenhouse * sunlightMultiplier

        let effectivePopulation = floor(state.population)
        let effectiveBeds = floor(state.housingCapacity)
        let dailyConsumption = effectivePopulation * tuning.rationPerPersonPerDay
        state.foodStockRations = max(0, state.foodStockRations + dailyYield - dailyConsumption)

        let foodSurplusRatio = (dailyYield - dailyConsumption) / max(dailyConsumption, 1)
        let clampedFoodSurplus = max(-1, min(1, foodSurplusRatio))

        // 4) Building (passive + exercise + tech bonus)
        let previousBuildPoints = state.buildPoints
        state.buildPoints += (tuning.baseBuildPointsPerDay + buildPointGainFromExercise) * (1 + tuning.buildTechBonusPerLevel * state.technologyLevel)

        // Track progress milestones at 25%, 50%, 75% for only the first build item in the queue
        let progressMilestones: [Double] = [0.25, 0.5, 0.75]
        var milestonesForToday = constructionProgressMilestones // local copy for this day
        if let next = state.buildQueue.first {
            let prevRatio = previousBuildPoints / next.costPoints
            let progressRatio = state.buildPoints / next.costPoints
            let milestonesHit = milestonesForToday[next.id] ?? Set<Double>()
            for milestone in progressMilestones {
                // Only fire event if milestone was just crossed this day (previously below, now at or above)
                if prevRatio < milestone && progressRatio >= milestone && progressRatio < 1.0 && !milestonesHit.contains(milestone) {
                    state.eventLog.append("Day \(state.currentDayIndex): Construction underway: \(next.kind.rawValue.capitalized) is \(Int(milestone * 100))% complete.")
                    var updatedSet = milestonesHit
                    updatedSet.insert(milestone)
                    milestonesForToday[next.id] = updatedSet
                }
            }
        }
        constructionProgressMilestones = milestonesForToday

        // Only complete at most one build per day
        if let next = state.buildQueue.first, state.buildPoints >= next.costPoints {
            state.buildPoints -= next.costPoints
            switch next.kind {
            case .house:
                state.housingCapacity += 4
                state.eventLog.append("Day \(state.currentDayIndex): Built a House (+4 beds).")
            case .greenhouse:
                state.greenhouseCount += 1
                state.eventLog.append("Day \(state.currentDayIndex): Built a Greenhouse (+food).")
            case .school:
                state.technologyLevel += 0.5
                state.eventLog.append("Day \(state.currentDayIndex): Opened a School (+Tech).")
            }
            _ = state.buildQueue.removeFirst()
            // Remove milestones tracking for completed build item
            constructionProgressMilestones[next.id] = nil
        }

        // 5) Science (passive + sleep + tech bonus)
        state.sciencePoints += (tuning.passiveSciencePointsPerDay + sciencePointGainFromSleep) * (1 + tuning.scienceTechBonusPerLevel * state.technologyLevel)
        if state.sciencePoints >= tuning.scienceBreakthroughThreshold {
            state.sciencePoints -= tuning.scienceBreakthroughThreshold
            state.technologyLevel += 1
            state.eventLog.append("Day \(state.currentDayIndex): Breakthrough! Tech is now \(Int(state.technologyLevel)).")
        }

        // 6) Population (gated by beds + food; small growth even w/ low surplus)
        let capacityFactor = max(0, min(1, (effectiveBeds - effectivePopulation) / max(effectivePopulation, 1)))
        let foodFactor = max(0, min(1, 0.55 + 0.45 * clampedFoodSurplus)) // slight baseline > 0.5
        let births = tuning.basePopulationGrowthRate * state.population * capacityFactor * foodFactor
        let deaths = (state.foodStockRations == 0) ? tuning.starvationDeathRate * state.population : 0

        let previousPopulation = state.population
        state.population = max(0, state.population + births - deaths)

        let prevWhole = Int(floor(previousPopulation))
        let newWhole  = Int(floor(state.population))
        if newWhole > prevWhole {
            let delta = newWhole - prevWhole
            state.eventLog.append("Day \(state.currentDayIndex): New arrivals: +\(delta) Liri.")
        }
        if deaths > 0 {
            state.eventLog.append("Day \(state.currentDayIndex): Hard day. Starvation affected the colony.")
        }

        // Trim event log to latest 500 entries
        if state.eventLog.count > 500 {
            state.eventLog = Array(state.eventLog.suffix(500))
        }
    }
}

// ================================================================
// 4) ViewModel + Automatic Clock (DEV timer)
// ================================================================
@MainActor
final class SimulationViewModel: ObservableObject {
    @Published var state = SimulationState()

    // Until HealthKit is wired, we feed ZERO metrics every day.
    // Swap to a HealthKit-driven provider later.
    @Published var metrics = DailyHealthMetrics.zero

    private var engine = SimulationEngine()

    private var timer: Timer?

    func startDevTimer() {
        stopDevTimer()
        timer = Timer.scheduledTimer(withTimeInterval: tickIntervalSec, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.engine.advanceOneDay(state: &self.state, health: self.metrics)
        }
    }

    func stopDevTimer() { timer?.invalidate(); timer = nil }

    func advanceOneDay() { engine.advanceOneDay(state: &state, health: metrics) }
    func reset() { state = SimulationState() }
}

// ================================================================
// 5) UI (read-only, status + queue + log)
// ================================================================
struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var vm = SimulationViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    colonySection
                    inputsSection
                    buildQueueSection
                    logSection
                }
                .padding()
            }
            .navigationTitle("Planet Lira • Day \(vm.state.currentDayIndex + 1)")
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active: vm.startDevTimer()
            default: vm.stopDevTimer()
            }
        }
        .task { vm.startDevTimer() }
    }

    // MARK: - Sections
    private var colonySection: some View {
        GroupBox("Colony Status") {
            Grid(horizontalSpacing: 12, verticalSpacing: 10) {
                gridRow("Population", value: vm.state.population, asInt: true)
                gridRow("Beds", value: vm.state.housingCapacity, asInt: true)
                gridRow("Food stock (rations)", value: vm.state.foodStockRations)
                gridRow("Greenhouses", value: vm.state.greenhouseCount, asInt: true)
                gridRow("Tech level", value: vm.state.technologyLevel)
                gridRow("Explored radius (km)", value: vm.state.exploredRadiusKm)
                gridRow("Build points", value: vm.state.buildPoints)
                gridRow("Science points", value: vm.state.sciencePoints)
            }
        }
    }

    private var inputsSection: some View {
        GroupBox("Inputs") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Health data: not connected (using ZERO baseline)")
                    .foregroundStyle(.secondary)
                Text("Dev time: one day passes every \(Int(tickIntervalSec)) seconds while the app is open.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var buildQueueSection: some View {
        GroupBox("Build Queue (automatic)") {
            VStack(alignment: .leading, spacing: 10) {
                if vm.state.buildQueue.isEmpty {
                    Text("(queue empty — waiting for new plans)").foregroundStyle(.secondary)
                } else {
                    ForEach(vm.state.buildQueue) { item in
                        HStack {
                            Text(item.kind.rawValue.capitalized)
                            Spacer()
                            Text("cost: \(Int(item.costPoints)) pts").foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                Text("The colony spends Build Points automatically as they accrue.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var logSection: some View {
        GroupBox("Event Log") {
            if vm.state.eventLog.isEmpty {
                Text("No events yet. The Liri are settling in…")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(vm.state.eventLog.reversed().prefix(120), id: \.self) { line in
                        Text(line).font(.callout)
                    }
                }
            }
        }
    }

    // MARK: - Helpers
    private func gridRow(_ label: String, value: Double, asInt: Bool = false) -> some View {
        GridRow {
            Text(label)
            Spacer()
            if asInt { Text("\(Int(floor(value)))") }
            else { Text(String(format: "%.2f", value)) }
        }
    }
}

// ================================================================
// 6) App Entry
// ================================================================
@main
struct LiraApp: App {
    var body: some Scene { WindowGroup { ContentView() } }
}
