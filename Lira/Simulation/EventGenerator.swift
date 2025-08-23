import Foundation

/// Lightweight classification for log entries. Used to decorate the text so the UI can show icons.
enum EventKind {
    case exploration
    case milestone
    case construction
    case research
    case population
    case resources
    case capacity
    case general
}

/// Central place for formatting + appending events to the state's log.
/// Keeps the engine clean and makes it easy to expand later.
enum EventGenerator {
    static let maxLogLines = 500
    
    private static func icon(for kind: EventKind) -> String {
        switch kind {
        case .exploration: return "🔎"
        case .milestone:   return "📍"
        case .construction:return "🏗"
        case .research:    return "🔬"
        case .population:  return "👥"
        case .resources:   return "🍎"
        case .capacity:    return "🏠"
        case .general:     return "ℹ️"
        }
    }

    /// Compose and push a typed message for a given day. Keeps existing string log for compatibility.
    private static func push(day: Int, kind: EventKind, body: String, into state: inout SimulationState) {
        let decorated = "\(icon(for: kind)) \(body)"
        push("Day \(day): \(decorated)", into: &state)
    }
    
    private static let discoveryItems: [String] = [
        "amber reeds", "salt flats", "basalt springs", "silver moss",
        "glow beetles", "lichen crystals", "reed sugar", "spice pods",
        "wind-polished stones", "luminescent fungi", "sweetwater pool",
        "iron shards", "mica dunes", "wild grain", "copper vines"
    ]

    // Tech discoveries keyed by tech level
    private static let techDiscoveries: [Int: [String]] = [
        1: ["basic irrigation", "stone masonry", "reed weaving", "fire pits"],
        2: ["metal tools", "greenhouse automation", "copper smelting", "basic medicine"],
        3: ["wind turbines", "water purification", "glassmaking", "simple machinery"],
        4: ["advanced optics", "chemical fertilizers", "steam engines", "solar stills"],
        5: ["bioluminescent lighting", "hydroponic towers", "electric storage", "radio beacons"]
    ]
    
    private static let discoveryVerbs: [String] = [
        "found", "spotted", "catalogued", "sampled", "noted"
    ]
    
    private static func push(_ text: String, into state: inout SimulationState) {
        state.eventLog.append(text)
        if state.eventLog.count > maxLogLines {
            state.eventLog.removeFirst(state.eventLog.count - maxLogLines)
        }
    }
    
    // MARK: Exploration
    static func explorationDaily(day: Int, deltaKm: Double, totalKm: Double, state: inout SimulationState) {
        var msg = String(format: "Explored surroundings (+%.2f km, total %.2f km).", deltaKm, totalKm)
        if Int.random(in: 0..<100) < 35,
           let item = discoveryItems.randomElement(),
           let verb = discoveryVerbs.randomElement() {
            msg += " \(verb.capitalized) \(item)."
        }
        push(day: day, kind: .exploration, body: msg, into: &state)
    }
    
    static func explorationMilestone(day: Int, km: Int, state: inout SimulationState) {
        push(day: day, kind: .milestone, body: "Scouted out to \(km) km.", into: &state)
    }
    
    // MARK: Construction
    static func constructionProgress(day: Int, displayName: String, percent: Int, state: inout SimulationState) {
        push(day: day, kind: .construction, body: "Construction underway: \(displayName) \(percent)% complete.", into: &state)
    }
    
    static func constructionProgress(day: Int, kind: BuildKind, percent: Int, state: inout SimulationState) {
        constructionProgress(day: day, displayName: kind.rawValue.capitalized, percent: percent, state: &state)
    }
    
    static func builtHouse(day: Int, state: inout SimulationState, displayName: String = "House", bedsAdded: Int) {
        push(day: day, kind: .construction, body: "Built a \(displayName) (+\(bedsAdded) beds).", into: &state)
    }
    
    static func builtGreenhouse(day: Int, state: inout SimulationState, displayName: String = "Greenhouse") {
        push(day: day, kind: .construction, body: "Built a \(displayName) (+food).", into: &state)
    }
    
    static func openedSchool(day: Int, state: inout SimulationState, displayName: String = "School") {
        push(day: day, kind: .construction, body: "Opened a \(displayName) (+Tech).", into: &state)
    }
    
    // MARK: Science
    static func breakthrough(day: Int, techLevel: Int, state: inout SimulationState) {
        var message = "Breakthrough! Tech is now \(techLevel)."
        if let discoveries = techDiscoveries[techLevel], let item = discoveries.randomElement() {
            message += " Mastered: \(item)."
        }
        push(day: day, kind: .research, body: message, into: &state)
    }
    
    // MARK: Population
    static func arrivals(day: Int, count: Int, state: inout SimulationState) {
        push(day: day, kind: .population, body: "New arrivals: +\(count) Liri.", into: &state)
    }
    
    static func growthPausedForFood(day: Int, state: inout SimulationState) {
        push(day: day, kind: .capacity, body: "Growth paused due to food shortage.", into: &state)
    }
    
    static func constructionPlanned(day: Int, name: String, state: inout SimulationState) {
        push(day: day, kind: .construction, body: "Queued: \(name).", into: &state)
    }

    static func constructionStarted(day: Int, name: String, days: Int, state: inout SimulationState) {
        push(day: day, kind: .construction, body: "Started building \(name), estimated \(days) days to complete.", into: &state)
    }
    
    static func researchProgress(day: Int, percent: Int, state: inout SimulationState) {
        push(day: day, kind: .research, body: "Research is advancing — \(percent)% complete.", into: &state)
    }
    
    // MARK: Surplus & Capacity Events
    static func foodSurplus(day: Int, surplus: Int, state: inout SimulationState) {
        push(day: day, kind: .resources, body: "Surplus food detected (+\(surplus) units).", into: &state)
    }
    
    static func housingSurplus(day: Int, surplusBeds: Int, state: inout SimulationState) {
        push(day: day, kind: .capacity, body: "Extra housing available (+\(surplusBeds) beds).", into: &state)
    }
    
    static func populationCapReached(day: Int, state: inout SimulationState) {
        push(day: day, kind: .capacity, body: "Population growth halted — housing at capacity.", into: &state)
    }
    
    static func idleBuilders(day: Int, state: inout SimulationState) {
        push(day: day, kind: .construction, body: "Builders idle — no projects in queue.", into: &state)
    }
    
    static func greenhouseLimitReached(day: Int, state: inout SimulationState) {
        push(day: day, kind: .capacity, body: "Greenhouse per capita target reached.", into: &state)
    }
    
    static func generalInfo(day: Int, message: String, state: inout SimulationState) {
        push(day: day, kind: .general, body: message, into: &state)
    }
    
}
