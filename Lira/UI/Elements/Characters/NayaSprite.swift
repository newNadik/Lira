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
}
