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
}
