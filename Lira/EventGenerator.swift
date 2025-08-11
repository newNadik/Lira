import Foundation

/// Central place for formatting + appending events to the state's log.
/// Keeps the engine clean and makes it easy to expand later.
enum EventGenerator {
    static let maxLogLines = 500

    private static func push(_ text: String, into state: inout SimulationState) {
        state.eventLog.append(text)
        if state.eventLog.count > maxLogLines {
            state.eventLog.removeFirst(state.eventLog.count - maxLogLines)
        }
    }

    // MARK: Exploration
    static func explorationDaily(day: Int, deltaKm: Double, totalKm: Double, state: inout SimulationState) {
        push(String(format: "Day %d: Explored surroundings (+%.2f km, total %.2f km).", day, deltaKm, totalKm), into: &state)
    }

    static func explorationMilestone(day: Int, km: Int, state: inout SimulationState) {
        push("Day \(day): Scouted out to \(km) km.", into: &state)
    }

    // MARK: Construction
    static func constructionProgress(day: Int, kind: BuildItem.BuildKind, percent: Int, state: inout SimulationState) {
        push("Day \(day): Construction underway: \(kind.rawValue.capitalized) \(percent)% complete.", into: &state)
    }

    static func builtHouse(day: Int, state: inout SimulationState) {
        push("Day \(day): Built a House (+4 beds).", into: &state)
    }

    static func builtGreenhouse(day: Int, state: inout SimulationState) {
        push("Day \(day): Built a Greenhouse (+food).", into: &state)
    }

    static func openedSchool(day: Int, state: inout SimulationState) {
        push("Day \(day): Opened a School (+Tech).", into: &state)
    }

    // MARK: Science
    static func breakthrough(day: Int, techLevel: Int, state: inout SimulationState) {
        push("Day \(day): Breakthrough! Tech is now \(techLevel).", into: &state)
    }

    // MARK: Population
    static func arrivals(day: Int, count: Int, state: inout SimulationState) {
        push("Day \(day): New arrivals: +\(count) Liri.", into: &state)
    }

    static func growthPausedForFood(day: Int, state: inout SimulationState) {
        push("Day \(day): Growth paused due to food shortage.", into: &state)
    }
}
