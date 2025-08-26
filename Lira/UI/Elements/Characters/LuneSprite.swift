import SpriteKit

final class LuneSpriteNode: SKNode, SKAnimatableNode {
    // MARK: Sprites
    private let body = SKSpriteNode(texture: SKTexture(imageNamed: "lune_body"))   // body w/o leaves
    private let antenna  = SKSpriteNode(texture: SKTexture(imageNamed: "lune_antenna"))

    /// Internal setup for body and leaves
    private func configure() {
        addChild(body)

        // Position leaves on top of the head; tweak these to match your art.
        antenna.position  = CGPoint(x: 0, y: body.size.height * 0.48)

        // Anchor at the stem so they pivot naturally
        antenna.anchorPoint  = CGPoint(x: 0.5, y: 0)

        addChild(antenna)
        
        body.zPosition = 0
        antenna.zPosition = -1
    }

    // MARK: Init
    override init() {
        super.init()
        configure()
        startWind()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
        startWind()
    }

    // MARK: Wind animation (relaxing, continuous sine wave)
    /// Start a gentle continuous sway using a sine function. No jerky endpoints.
    func startWind() {
        // Clear any previous actions
        stopWind()

        // Optional: subtle bobbing of the whole body for added life
        runSineBob(on: body, amplitude: 3.0, period: 3.2, key: "body_bob")
        
        let amplitudeDeg = 9.0
        let period = Config.animationPeriod
        // Gentle opposite-phase sway on leaves
        runSineSway(on: antenna,  amplitudeDeg: amplitudeDeg, period: period, phase: 0.0,  key: "sine_sway")

    }

    func stopWind() {
        removeAction(forKey: "wind")
        antenna.removeAllActions()
        body.removeAllActions()
    }

    // MARK: SKAnimatableNode
    func startAnimation() { startWind() }
    func stopAnimation() { stopWind() }
    var size: CGSize { body.size }
    
    static func presentLine(simulationVM: SimulationViewModel?) -> String {
        guard let vm = simulationVM else {
            return "Hi! Ready for a walk?"
        }
        var options: [String] = []
        
        options.append("Interesting..")
        options.append("An dvantage!")
        options.append("This will help!")
        
        // Core expedition chatter (always available)
        options.append(contentsOf: [
            "Boots on, map open - ready when you are",
            "Every [steps_icon] we take, the map grows a little",
            "Scouted a new path beyond the ridge - soft ground, easy going",
            "I marked a safe shortcut around the marsh",
            "The wind smells like pine and secrets",
            "Trails look clear. Want to head out?",
            "I can carry back seeds and scrap—light but useful",
            "Found a sparkle of ore earlier; I left a cairn to find it again",
            "If the sun holds [sun_icon], we can push a bit farther",
            "Rest [sleep_icon] well and we’ll range wider tomorrow",
            "Oh, hi there!"
        ])

        // Journal flavour if available
        if let note = vm.state.eventLog.first(where: { log in
            log.contains("🔎")
        }) {
            options.append("I sketched a landmark in the journal: \(note)")
        }

        // Gentle world flavour
        options.append(contentsOf: [
            "I like quiet trails and loud discoveries",
            "If you bring the curiosity, I’ll bring the compass",
            "We bring back more than resources — we bring back stories",
            "Let’s check the map together before we go"
        ])

        options.append("I’m Lune - scout, pathfinder, and your walking companion")
        
        return options.randomElement() ?? "Oh, hi there!"
    }
}
