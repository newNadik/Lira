import SwiftUI
import Foundation
import Combine

@MainActor
final class SimulationViewModel: ObservableObject {
    @Published var state = SimulationState()
    @Published var metrics = DailyHealthMetrics(steps: 0, daylightMinutes: 0, exerciseMinutes: 0, sleepHours: 0)

    private var engine = SimulationEngine()
    private var lastUpdate = Date()
    private var stepsBaseline: Double = 0
    private var exerciseBaseline: Double = 0
    private var daylightBaseline: Double = 0
    private var timer: Timer?

    private var cancellables = Set<AnyCancellable>()

    private let stateKey = "simulation.state.v1"
    private let metaKey  = "simulation.meta.v1"

    private struct Meta: Codable {
        var lastUpdate: Date
        var stepsBaseline: Double
        var exerciseBaseline: Double
        var daylightBaseline: Double
    }

    init() {
        // Try to restore saved state
        if let data = UserDefaults.standard.data(forKey: stateKey),
           let saved = try? JSONDecoder().decode(SimulationState.self, from: data) {
            state = saved
        } else {
            // Seed starter plans from Config so models stay pure when no saved data
            state.buildQueue = Config.initialBuildQueue
        }

        // Restore meta (timing & baselines) or initialize
        if let mdata = UserDefaults.standard.data(forKey: metaKey),
           let meta = try? JSONDecoder().decode(Meta.self, from: mdata) {
            lastUpdate = meta.lastUpdate
            stepsBaseline = meta.stepsBaseline
            exerciseBaseline = meta.exerciseBaseline
            daylightBaseline = meta.daylightBaseline
        } else {
            lastUpdate = Date()
            stepsBaseline = metrics.steps
            exerciseBaseline = metrics.exerciseMinutes
            daylightBaseline = metrics.daylightMinutes
        }

        // Auto-save state on any change (debounced lightly)
        $state
            .dropFirst()
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] newState in
                self?.saveState(newState)
            }
            .store(in: &cancellables)
    }

    func startDevTimer() {
        stopDevTimer()
        let interval = Config.tickInterval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }

            if Config.isDevMode {
                // Old fast-sim dev loop: one full in-game day per tick
                self.engine.advanceOneDay(state: &self.state, health: self.metrics)
            } else {
                // Real-time loop: advance by the fraction of a day that actually elapsed
                let now = Date()
                let elapsed = max(0, now.timeIntervalSince(self.lastUpdate))
                if elapsed <= 0 { return }
                let f = min(1.0, elapsed / 86_400.0)

                // Health *deltas since last tick* (metrics are assumed cumulative since midnight)
                let deltas = DailyHealthMetrics(
                    steps: max(0, self.metrics.steps - self.stepsBaseline),
                    daylightMinutes: max(0, self.metrics.daylightMinutes - self.daylightBaseline),
                    exerciseMinutes: max(0, self.metrics.exerciseMinutes - self.exerciseBaseline),
                    // Sleep from the previous night: pass full value each tick; engine drips it by `f`
                    sleepHours: self.metrics.sleepHours
                )

                self.engine.advanceFractionOfDay(state: &self.state, healthDeltas: deltas, fractionOfDay: f)

                // Update baselines for next tick
                self.lastUpdate = now
                self.stepsBaseline = self.metrics.steps
                self.exerciseBaseline = self.metrics.exerciseMinutes
                self.daylightBaseline = self.metrics.daylightMinutes
                self.saveMeta()
            }
        }
    }

    func stopDevTimer() { timer?.invalidate(); timer = nil }
    func advanceOneDay() { engine.advanceOneDay(state: &state, health: metrics) }
    func reset() { state = SimulationState(); state.buildQueue = Config.initialBuildQueue }

    private func saveState(_ s: SimulationState) {
        if let data = try? JSONEncoder().encode(s) {
            UserDefaults.standard.set(data, forKey: stateKey)
        }
    }

    private func saveMeta() {
        let meta = Meta(lastUpdate: lastUpdate,
                        stepsBaseline: stepsBaseline,
                        exerciseBaseline: exerciseBaseline,
                        daylightBaseline: daylightBaseline)
        if let data = try? JSONEncoder().encode(meta) {
            UserDefaults.standard.set(data, forKey: metaKey)
        }
    }
}
