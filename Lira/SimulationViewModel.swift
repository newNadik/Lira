import SwiftUI
import Foundation
import Combine

@MainActor
final class SimulationViewModel: ObservableObject {
    @Published var state = SimulationState()
    @Published var metrics = DailyHealthMetrics(steps: 0, daylightMinutes: 0, exerciseMinutes: 0, sleepHours: 0)

    private var engine = SimulationEngine()
    private var timer: Timer?

    init() {
        // Seed starter plans from Config so models stay pure.
        state.buildQueue = Config.initialBuildQueue
    }

    func startDevTimer() {
        stopDevTimer()
        timer = Timer.scheduledTimer(withTimeInterval: Config.tickInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.engine.advanceOneDay(state: &self.state, health: self.metrics)
        }
    }

    func stopDevTimer() { timer?.invalidate(); timer = nil }
    func advanceOneDay() { engine.advanceOneDay(state: &state, health: metrics) }
    func reset() { state = SimulationState(); state.buildQueue = Config.initialBuildQueue }
}
