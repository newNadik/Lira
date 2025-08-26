import SpriteKit

final class LirSpriteNode: SKNode, SKAnimatableNode {
    // MARK: Sprites
    private let body = SKSpriteNode(texture: SKTexture(imageNamed: "lir_body"))   // body w/o leaves
    private let leftLeaf  = SKSpriteNode(texture: SKTexture(imageNamed: "lir_left_leaf"))
    private let rightLeaf = SKSpriteNode(texture: SKTexture(imageNamed: "lir_right_leaf"))

    /// Internal setup for body and leaves
    private func configure() {
        addChild(body)

        // Position leaves on top of the head; tweak these to match your art.
        leftLeaf.position  = CGPoint(x: body.size.width * 0.01, y: body.size.height * 0.46)
        rightLeaf.position = CGPoint(x: body.size.width * -0.01, y: body.size.height * 0.46)

        // Anchor at the stem so they pivot naturally
        leftLeaf.anchorPoint  = CGPoint(x: 1, y: 0)
        rightLeaf.anchorPoint = CGPoint(x: 0, y: 0)

        addChild(leftLeaf)
        addChild(rightLeaf)
        
        // Set zPositions so the body is behind the leaves
        body.zPosition = 0
        leftLeaf.zPosition = 1
        rightLeaf.zPosition = 1
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
        
        let amplitudeDeg = 6.0
        let period = Config.animationPeriod
        // Gentle opposite-phase sway on leaves
        runSineSway(on: leftLeaf,  amplitudeDeg: amplitudeDeg, period: period, phase: 0.0,  key: "sine_sway")
        runSineSway(on: rightLeaf, amplitudeDeg: amplitudeDeg, period: period, phase: .pi, key: "sine_sway")

    }

    func stopWind() {
        removeAction(forKey: "wind")
        leftLeaf.removeAllActions()
        rightLeaf.removeAllActions()
        body.removeAllActions()
    }

    // MARK: SKAnimatableNode
    func startAnimation() { startWind() }
    func stopAnimation() { stopWind() }
    var size: CGSize { body.size }
    
    static func presentLine(simulationVM: SimulationViewModel?) -> String {
        guard let vm = simulationVM else {
            return "Hi visitor!"
        }
        var options: [String] = []

        // Self-introduction / role
        options.append("I’m Lir - keeper of our plans and curious machines")

        // Science / research flavor
        options.append(contentsOf: [
            "Dream well; we turn [sleep_icon] into science",
            "I filed today’s hypotheses - care to review a blueprint?",
            "Small questions make big discoveries",
            "The lab hums like a friendly beehive",
            "A tidy workshop is faster than a messy genius, usually",
            "If we log it in the journal, we can build it tomorrow"
        ])

        // Settlement oversight (general guidance)
        options.append(contentsOf: [
            "Shelter, food, light—keep those steady and we thrive",
            "Greenhouses grow comfort; workshops grow possibility",
            "I like plans that start small and finish sturdy",
            "Let’s balance building with rest; tired minds miss simple answers [sleep_icon]",
            "Explorers bring stories; I turn them into checklists",
            "When in doubt, measure it twice and write it down"
        ])

        // Health-driven gentle nudges (compile-safe)
        if vm.metrics.exerciseMinutes > 0 {
            options.append("Your [exercise_icon] \(vm.metrics.exerciseMinutes) min sharpen thinking. The lab says thanks")
        }

        // Journal flavor if available
        if let note = vm.state.eventLog.first(where: { log in
            log.contains("👥")
        }) {
            options.append("I noted this for the council: \(note)")
        }

        return options.randomElement() ?? "Oh, hi there!"
    }
}
