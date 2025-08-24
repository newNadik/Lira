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
        let period = 2.2
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

    // MARK: Helpers
    /// Continuous sine-based rotation (very smooth). Repeats forever without hard edges.
    private func runSineSway(on node: SKSpriteNode,
                              amplitudeDeg: CGFloat,
                              period: TimeInterval,
                              phase: CGFloat,
                              key: String) {
        let A = amplitudeDeg * .pi / 180
        let w = 2 * CGFloat.pi / CGFloat(period)
        let duration: TimeInterval = 600 // long duration; we repeat forever
        let action = SKAction.customAction(withDuration: duration) { n, t in
            let time = CGFloat(t)
            (n as? SKSpriteNode)?.zRotation = A * sin(w * time + phase)
        }
        node.run(.repeatForever(action), withKey: key)
    }

    /// Subtle vertical bob for the body to feel alive
    private func runSineBob(on node: SKSpriteNode,
                             amplitude: CGFloat,
                             period: TimeInterval,
                             key: String) {
        let w = 2 * CGFloat.pi / CGFloat(period)
        let baseY = node.position.y
        let duration: TimeInterval = 600
        let action = SKAction.customAction(withDuration: duration) { n, t in
            let time = CGFloat(t)
            n.position.y = baseY + amplitude * sin(w * time)
        }
        node.run(.repeatForever(action), withKey: key)
    }

    // MARK: SKAnimatableNode
    func startAnimation() { startWind() }
    func stopAnimation() { stopWind() }
    var size: CGSize { body.size }
}
