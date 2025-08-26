import SpriteKit

final class NayaSpriteNode: SKNode, SKAnimatableNode {
    // MARK: Sprites
    private let body = SKSpriteNode(texture: SKTexture(imageNamed: "naya_body"))   // body w/o leaves
    private let leftAntenna  = SKSpriteNode(texture: SKTexture(imageNamed: "naya_left_antenna"))
    private let rightAntenna = SKSpriteNode(texture: SKTexture(imageNamed: "naya_right_antenna"))

    /// Internal setup for body and leaves
    private func configure() {
        addChild(body)

        // Position leaves on top of the head; tweak these to match your art.
        leftAntenna.position  = CGPoint(x: body.size.width * -0.16, y: body.size.height * 0.35)
        rightAntenna.position = CGPoint(x: body.size.width * 0.18, y: body.size.height * 0.35)

        // Anchor at the stem so they pivot naturally
        leftAntenna.anchorPoint  = CGPoint(x: 0.5, y: 0)
        rightAntenna.anchorPoint = CGPoint(x: 0.5, y: 0)

        addChild(leftAntenna)
        addChild(rightAntenna)
        
        body.zPosition = 0
        leftAntenna.zPosition = 1
        rightAntenna.zPosition = -1
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
        
        let amplitudeDeg = 3.0
        let period = Config.animationPeriod
        // Gentle opposite-phase sway on leaves
        runSineSway(on: leftAntenna,  amplitudeDeg: amplitudeDeg, period: period, phase: 0.0,  key: "sine_sway")
        runSineSway(on: rightAntenna, amplitudeDeg: amplitudeDeg, period: period, phase: .pi, key: "sine_sway")

    }

    func stopWind() {
        removeAction(forKey: "wind")
        leftAntenna.removeAllActions()
        rightAntenna.removeAllActions()
        body.removeAllActions()
    }

    // MARK: SKAnimatableNode
    func startAnimation() { startWind() }
    func stopAnimation() { stopWind() }
    var size: CGSize { body.size }
        
    static func presentLine(simulationVM: SimulationViewModel?) -> String {
        guard let vm = simulationVM else {
            return "Naya? Yep, that's me!"
        }
        var options: [String] = []

        // Core greenhouse chatter (always available)
        options.append(contentsOf: [
            "I checked the seedlings - leaves look happy today",
            "Water, light, patience… that’s my recipe",
            "I talk to the sprouts. They’re good listeners",
            "If you smell fresh basil, that’s totally me",
            "One more tray and we’ll have a tiny jungle",
            "Naya? Yep, that's me!",
            "Oh, hi there!"
        ])

        // Health-driven flavour (safe checks)
        if vm.metrics.exerciseMinutes > 0 {
            options.append("Your [exercise_icon] \(vm.metrics.exerciseMinutes) min keeps our watering arms strong!")
        }

        // Journal flavour if available
        if let note = vm.state.eventLog.first(where: { log in
            log.contains("🍎")
        }) {
            options.append("I pressed a leaf in the journal: \(note)")
        }

        // Gentle world flavour without direct counts (keeps it compile-safe)
        options.append(contentsOf: [
            "More [sun_icon] makes sweeter tomatoes",
            "I saved a corner for herbs",
            "Promise to visit later? The cucumbers love an audience",
            "If you walk a bit more [steps_icon], I’ll plant a victory carrot"
        ])

        return options.randomElement() ?? "Oh, hi there!"
    }
}
