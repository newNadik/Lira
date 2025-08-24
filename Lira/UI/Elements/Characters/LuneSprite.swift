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
}
