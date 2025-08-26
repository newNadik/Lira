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

    private let secondsPerDay: TimeInterval = 86_400

    private func startOfNextDay(after date: Date) -> Date {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        return cal.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(secondsPerDay)
    }

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
            EventGenerator.autoDaily(day: 1, state: &state)
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

        // Listen for reset notification
        NotificationCenter.default.publisher(for: .gameResetRequested)
            .sink { [weak self] _ in
                self?.reset()
            }
            .store(in: &cancellables)

        // Immediate catch-up on launch so we don't wait for the first timer tick
        if !Config.isDevMode {
            let now = Date()
            var cursor = self.lastUpdate
            if now > cursor {
                let cal = Calendar.current

                // Finish any full days crossed while app was closed
                while !cal.isDate(cursor, inSameDayAs: now) {
                    let nextMidnight = self.startOfNextDay(after: cursor)
                    let span = nextMidnight.timeIntervalSince(cursor)
                    let f = max(0, min(1, span / self.secondsPerDay))
                    let zero = DailyHealthMetrics(steps: 0, daylightMinutes: 0, exerciseMinutes: 0, sleepHours: self.metrics.sleepHours)
                    self.engine.advanceFractionOfDay(state: &self.state, healthDeltas: zero, fractionOfDay: f, emitDailySummary: true)
                    self.stepsBaseline = 0
                    self.exerciseBaseline = 0
                    self.daylightBaseline = 0
                    cursor = nextMidnight
                }

                // Advance partial for today using current cumulative metrics as deltas
                let elapsedToday = now.timeIntervalSince(cursor)
                if elapsedToday > 0 {
                    let f = min(1.0, elapsedToday / self.secondsPerDay)
                    let deltas = DailyHealthMetrics(
                        steps: max(0, self.metrics.steps - self.stepsBaseline),
                        daylightMinutes: max(0, self.metrics.daylightMinutes - self.daylightBaseline),
                        exerciseMinutes: max(0, self.metrics.exerciseMinutes - self.exerciseBaseline),
                        sleepHours: self.metrics.sleepHours
                    )
                    self.engine.advanceFractionOfDay(state: &self.state, healthDeltas: deltas, fractionOfDay: f)
                    self.stepsBaseline = self.metrics.steps
                    self.exerciseBaseline = self.metrics.exerciseMinutes
                    self.daylightBaseline = self.metrics.daylightMinutes
                }

                self.lastUpdate = now
                self.saveMeta()
            }
        }
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
                // Real-time loop with multi-day catch-up and midnight baseline reset
                let now = Date()
                var cursor = self.lastUpdate
                if now <= cursor { return }

                let cal = Calendar.current

                // 1) If we crossed one or more midnights while the app was closed, finish the previous day(s)
                while !cal.isDate(cursor, inSameDayAs: now) {
                    let nextMidnight = self.startOfNextDay(after: cursor)
                    let span = nextMidnight.timeIntervalSince(cursor)
                    let f = max(0, min(1, span / self.secondsPerDay))

                    // We don't have historical health deltas for closed days → advance passively to midnight
                    let zero = DailyHealthMetrics(steps: 0, daylightMinutes: 0, exerciseMinutes: 0, sleepHours: self.metrics.sleepHours)
                    self.engine.advanceFractionOfDay(state: &self.state, healthDeltas: zero, fractionOfDay: f, emitDailySummary: true)

                    // Reset baselines at midnight because Apple Health-style metrics reset at local midnight
                    self.stepsBaseline = 0
                    self.exerciseBaseline = 0
                    self.daylightBaseline = 0

                    // Move cursor to the start of the new day
                    cursor = nextMidnight
                }

                // 2) Now we're on the same day as `now`. Advance the partial day using today's deltas.
                let elapsedToday = now.timeIntervalSince(cursor)
                if elapsedToday > 0 {
                    let f = min(1.0, elapsedToday / self.secondsPerDay)
                    let deltas = DailyHealthMetrics(
                        steps: max(0, self.metrics.steps - self.stepsBaseline),
                        daylightMinutes: max(0, self.metrics.daylightMinutes - self.daylightBaseline),
                        exerciseMinutes: max(0, self.metrics.exerciseMinutes - self.exerciseBaseline),
                        // Sleep from the previous night: pass full value each tick; engine drips it by `f`
                        sleepHours: self.metrics.sleepHours
                    )
                    self.engine.advanceFractionOfDay(state: &self.state, healthDeltas: deltas, fractionOfDay: f)

                    // Update baselines to today's cumulative values after consuming them
                    self.stepsBaseline = self.metrics.steps
                    self.exerciseBaseline = self.metrics.exerciseMinutes
                    self.daylightBaseline = self.metrics.daylightMinutes
                }

                // 3) Commit the new timestamp and save metadata
                self.lastUpdate = now
                self.saveMeta()
            }
        }
        // Fire immediately so we don’t wait for a long interval (e.g., a day)
        self.timer?.fire()
    }

    func stopDevTimer() { timer?.invalidate(); timer = nil }
    func advanceOneDay() { engine.advanceOneDay(state: &state, health: metrics) }
    func reset() {
        state = SimulationState()
        state.buildQueue = Config.initialBuildQueue
        UserDefaults.standard.set(false, forKey: "intro.seen")
    }

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
