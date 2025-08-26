import SpriteKit

final class BeanieSpriteNode: SKNode, SKAnimatableNode {
    // MARK: Sprites
    private let body = SKSpriteNode(texture: SKTexture(imageNamed: "beanie_body"))   // body w/o leaves
    private let leftAntenna  = SKSpriteNode(texture: SKTexture(imageNamed: "beanie_left_antenna"))
    private let rightAntenna = SKSpriteNode(texture: SKTexture(imageNamed: "beanie_right_antenna"))

    /// Internal setup for body and leaves
    private func configure() {
        addChild(body)

        // Position leaves on top of the head; tweak these to match your art.
        leftAntenna.position  = CGPoint(x: body.size.width * -0.17, y: body.size.height * 0.35)
        rightAntenna.position = CGPoint(x: body.size.width * 0.17, y: body.size.height * 0.35)

        // Anchor at the stem so they pivot naturally
        leftAntenna.anchorPoint  = CGPoint(x: 0.5, y: 0)
        rightAntenna.anchorPoint = CGPoint(x: 0.5, y: 0)

        addChild(leftAntenna)
        addChild(rightAntenna)
        
        body.zPosition = 0
        leftAntenna.zPosition = -1
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
        
        let amplitudeDeg = 4.0
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
            return "Beanie reporting for duty!"
        }

        var options: [String] = []

        // Building
        if let current = vm.state.buildQueue.first {
            options.append("Step by step, the \(current.displayName) rises tall.")
            if vm.state.activeBuildTotalDays > 0 {
                let progress = (vm.state.activeBuildTotalDays - vm.state.activeBuildDaysRemaining) / vm.state.activeBuildTotalDays
                let percent = Int(progress * 100)
                
                options.append("Working on \(current.displayName)… \(percent)% done")
                options.append("Only \(100 - percent)% more and the \(current.displayName) will be done!")
            }
        }

        // Exercise
        if vm.metrics.exerciseMinutes > 0 {
            options.append("Your [exercise_icon] \(Int(vm.metrics.exerciseMinutes)) min today keep us building strong!")
            options.append("Those \(Int(vm.metrics.exerciseMinutes)) [exercise_icon] minutes fuel our muscles and our walls")
        }
        
        // Journal highlight
        if let highlight = vm.state.eventLog.first(where: { log in
            log.contains("🏗")
        }) {
            options.append("In my notes: \(highlight)")
        }
        
        options.append("If you see a crooked plank, it wasn't me!")
        options.append("A little [steps_icon] walk clears my mind for straighter beams")
        options.append("Nothing beats the smell of fresh wood in the morning")
        options.append("Sturdy walls make happy settlers")
        options.append("Let's get back to work!")
        
        options.append("Measure twice, cut once… or maybe three times, just to be safe")
        options.append("If something looks upside-down, it’s artistic design")
        options.append("Nails keep disappearing… I think Lir is collecting them")
        options.append("Greenhouses shine brighter every day — feels like home")
        options.append("Science folks talk about stars; I just want a sturdy chair")
        options.append("Settlers will need somewhere to rest after all that [exercise_icon]")
        options.append("Beanie reporting for duty!")
        
        // Pick one line
        return options.randomElement() ?? "Beanie reporting for duty!"
    }
}
