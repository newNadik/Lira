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
    case environment
    case warning
    case celebration
    case narrative
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
        case .environment: return "🌦"
        case .warning:     return "⚠️"
        case .celebration: return "🎉"
        case .narrative:   return "📖"
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

    // Flavor pools for early- and mid-game ambience
    private static let starterSupplies: [String] = [
        "seed packs", "tool kits", "water filters", "bandages",
        "solar cells", "spare antennae clips", "camp stoves",
        "blankets", "navigation beacons", "field notebooks"
    ]

    private static let skyPhenomena: [String] = [
        "a soft twin-moon rise", "a slow meteor ribbon",
        "emerald auroras over the dunes", "glow-clouds drifting low",
        "a ring-shadow sweeping the valley"
    ]

    private static let weatherSnippets: [String] = [
        "gentle rain freshened the greenhouses",
        "a dust breeze coated everything in gold",
        "a cool fog curled along the river flats",
        "bright sun made the reeds sing",
        "night frost sparkled on the walkways"
    ]

    private static let localFaunaRumors: [String] = [
        "tiny shellbacks nest near the sweetwater pool",
        "reed-mice gather around lanterns",
        "glow beetles dance at dusk",
        "sandcrabs like shiny stones",
        "wind moths follow footsteps"
    ]

    private static func join(_ a: String, _ b: String) -> String { "\(a) and \(b)" }
    
    private static func push(_ text: String, into state: inout SimulationState) {
        state.eventLog.append(text)
        if state.eventLog.count > maxLogLines {
            state.eventLog.removeFirst(state.eventLog.count - maxLogLines)
        }
    }
    
    // MARK: Prologue / Start-of-game
    /// Call this once on the first playable day to seed a welcoming journal.
    static func prologue(day: Int, state: inout SimulationState) {
        push(day: day, kind: .narrative, body: "Touchdown successful. Instruments nominal", into: &state)
        push(day: day, kind: .construction, body: "Raised first shelter and set a small campfire", into: &state)
        // Unpack two random supply items for flavor
        if let a = starterSupplies.randomElement(), let b = starterSupplies.filter({ $0 != a }).randomElement() {
            push(day: day, kind: .general, body: "Unpacked \(join(a, b))", into: &state)
        }
        push(day: day, kind: .construction, body: "Started building a greenhouse", into: &state)
    }

    /// First night flavor
    static func firstNight(day: Int, state: inout SimulationState) {
        if let sky = skyPhenomena.randomElement() {
            push(day: day, kind: .narrative, body: "Camp quiet. We watched \(sky)", into: &state)
        }
    }

    // MARK: Exploration
    static func explorationDaily(day: Int, deltaKm: Double, totalKm: Double, state: inout SimulationState) {
        var msg = String(format: "Explored surroundings (+%.2f km, total %.2f km)", deltaKm, totalKm)
        if Int.random(in: 0..<100) < 35,
           let item = discoveryItems.randomElement(),
           let verb = discoveryVerbs.randomElement() {
            msg += " \(verb.capitalized) \(item)"
        }
        push(day: day, kind: .exploration, body: msg, into: &state)
    }
    
    static func explorationMilestone(day: Int, km: Int, state: inout SimulationState) {
        push(day: day, kind: .milestone, body: "Scouted out to \(km) km", into: &state)
    }
    
    // MARK: Construction
    static func constructionProgress(day: Int, displayName: String, percent: Int, state: inout SimulationState) {
        push(day: day, kind: .construction, body: "Construction underway: \(displayName) \(percent)% complete", into: &state)
    }
    
    static func constructionProgress(day: Int, kind: BuildKind, percent: Int, state: inout SimulationState) {
        constructionProgress(day: day, displayName: kind.rawValue.capitalized, percent: percent, state: &state)
    }
    
    static func builtHouse(day: Int, state: inout SimulationState, displayName: String = "House", bedsAdded: Int) {
        push(day: day, kind: .construction, body: "Built a \(displayName) (+\(bedsAdded) beds)", into: &state)
    }
    
    static func builtGreenhouse(day: Int, state: inout SimulationState, displayName: String = "Greenhouse") {
        push(day: day, kind: .construction, body: "Built a \(displayName) (+food)", into: &state)
    }
    
    static func openedSchool(day: Int, state: inout SimulationState, displayName: String = "School") {
        push(day: day, kind: .construction, body: "Opened a \(displayName) (+Tech)", into: &state)
    }
    
    // MARK: Science
    static func breakthrough(day: Int, techLevel: Int, state: inout SimulationState) {
        var message = "Breakthrough! Tech is now \(techLevel)"
        if let discoveries = techDiscoveries[techLevel], let item = discoveries.randomElement() {
            message += " Mastered: \(item)"
        }
        push(day: day, kind: .research, body: message, into: &state)
    }
    
    // MARK: Population
    static func arrivals(day: Int, count: Int, state: inout SimulationState) {
        push(day: day, kind: .population, body: "New arrivals: +\(count) Liri", into: &state)
    }
    
    static func growthPausedForFood(day: Int, state: inout SimulationState) {
        push(day: day, kind: .capacity, body: "Growth paused due to food shortage", into: &state)
    }
    
    static func constructionPlanned(day: Int, name: String, state: inout SimulationState) {
        push(day: day, kind: .construction, body: "Queued: \(name)", into: &state)
    }

    static func constructionStarted(day: Int, name: String, days: Int, state: inout SimulationState) {
        push(day: day, kind: .construction, body: "Started building \(name), estimated \(days) days to complete", into: &state)
    }
    
    static func researchProgress(day: Int, percent: Int, state: inout SimulationState) {
        push(day: day, kind: .research, body: "Research is advancing — \(percent)% complete", into: &state)
    }
    
    // MARK: Surplus & Capacity Events
    static func foodSurplus(day: Int, surplus: Int, state: inout SimulationState) {
        push(day: day, kind: .resources, body: "Surplus food detected (+\(surplus) units)", into: &state)
    }
    
    static func housingSurplus(day: Int, surplusBeds: Int, state: inout SimulationState) {
        push(day: day, kind: .capacity, body: "Extra housing available (+\(surplusBeds) beds)", into: &state)
    }
    
    static func populationCapReached(day: Int, state: inout SimulationState) {
        push(day: day, kind: .capacity, body: "Population growth halted — housing at capacity", into: &state)
    }
    
    static func idleBuilders(day: Int, state: inout SimulationState) {
        push(day: day, kind: .construction, body: "Builders idle — no projects in queue", into: &state)
    }
    
    static func greenhouseLimitReached(day: Int, state: inout SimulationState) {
        push(day: day, kind: .capacity, body: "Greenhouse per capita target reached", into: &state)
    }
    
    static func generalInfo(day: Int, message: String, state: inout SimulationState) {
        push(day: day, kind: .general, body: message, into: &state)
    }

    // MARK: Ambient & Special Events
    /// Light-weather note that makes the world feel alive.
    static func weatherUpdate(day: Int, state: inout SimulationState) {
        if Int.random(in: 0..<100) < 70, let note = weatherSnippets.randomElement() {
            push(day: day, kind: .environment, body: note, into: &state)
        }
    }

    /// Occasional warning to add drama without gameplay effect (can be hooked later).
    static func minorWarning(day: Int, state: inout SimulationState) {
        let warnings = [
            "Dust gusts expected by evening",
            "Watch for loose walkway planks near the river",
            "Conserve lantern oil — shipment delayed",
            "Radio static increasing around the ridge"
        ]
        if let w = warnings.randomElement() { push(day: day, kind: .warning, body: w, into: &state) }
    }

    /// Flavor: locals, critters, and small discoveries.
    static func rumor(day: Int, state: inout SimulationState) {
        if let r = localFaunaRumors.randomElement() {
            push(day: day, kind: .narrative, body: "Report: \(r)", into: &state)
        }
    }

    /// Celebration hook for achievements or story beats.
    static func celebrate(day: Int, message: String, state: inout SimulationState) {
        push(day: day, kind: .celebration, body: message, into: &state)
    }

    // MARK: Auto wiring convenience
    /// Call this once per day to automatically sprinkle ambience.
    /// Safe to call on any day; it will pick items probabilistically.
    static func autoDaily(day: Int, state: inout SimulationState) {
        
        // Soft early-game narrative moments
        if day == 1 {
            prologue(day: day, state: &state)
            firstNight(day: day, state: &state)
        }
        
        // Always try a small weather note
        weatherUpdate(day: day, state: &state)
        
        // ~40% chance of a rumor, ~20% of a minor warning
        if Int.random(in: 0..<100) < 40 { rumor(day: day, state: &state) }
        if Int.random(in: 0..<100) < 20 { minorWarning(day: day, state: &state) }
        
    }
}
