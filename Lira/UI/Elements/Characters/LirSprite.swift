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
        leftLeaf.position  = CGPoint(x: 0, y: body.size.height*0.46)
        rightLeaf.position = CGPoint(x:  0, y: body.size.height*0.46)

        // Anchor at the stem so they pivot naturally
        leftLeaf.anchorPoint  = CGPoint(x: 1, y: 0)
        rightLeaf.anchorPoint = CGPoint(x: 0, y: 0)

        addChild(leftLeaf)
        addChild(rightLeaf)
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

    // MARK: Wind animation
    /// Gentle, natural sway with occasional gusts
    func startWind() {
        run(makeWindCycle(), withKey: "wind")
    }

    func stopWind() {
        removeAction(forKey: "wind")
        leftLeaf.removeAllActions()
        rightLeaf.removeAllActions()
    }

    private func makeWindCycle() -> SKAction {
        // base, always-on sway (slightly out of phase so they move differently)
        let baseLeft  = swayAction(amplitudeDeg: 7,  period: 1.6, phase: 0.0)
        let baseRight = swayAction(amplitudeDeg: 7,  period: 1.6, phase: .pi)

        leftLeaf.run(baseLeft,  withKey: "base")
        rightLeaf.run(baseRight, withKey: "base")

        // “Gusts”: briefly increase amplitude + add a tiny bend/offset
        func gust(_ leaf: SKSpriteNode, stronger: Bool) -> SKAction {
            let amp: CGFloat = stronger ? 18 : 12
            let dur: TimeInterval = stronger ? 0.9 : 0.7

            let push = SKAction.group([
                SKAction.customAction(withDuration: dur) { node, t in
                    // add a little squash for a bend illusion
                    let k = CGFloat(t)/CGFloat(dur)
                    let bend = 1 - 0.06 * sin(k * .pi)
                    node.xScale = bend
                    node.yScale = 1 + (1 - bend)
                },
                swayToPeak(leaf, amplitudeDeg: amp, duration: dur)
            ])

            let relax = SKAction.group([
                SKAction.scaleX(to: 1, duration: 0.4),
                SKAction.scaleY(to: 1, duration: 0.4)
            ])

            return .sequence([push, relax])
        }

        // Random gust scheduler
        let wait = SKAction.wait(forDuration: 1.2, withRange: 1.4)
        let schedule = SKAction.run { [weak self] in
            guard let self else { return }
            let strong = Bool.random()
            self.leftLeaf.run(gust(self.leftLeaf, stronger: strong))
            self.rightLeaf.run(gust(self.rightLeaf, stronger: !strong))
        }

        return .repeatForever(.sequence([wait, schedule]))
    }

    // MARK: Helpers
    /// Ping‑pong rotation around 0 with given amplitude & period (+ phase offset)
    private func swayAction(amplitudeDeg: CGFloat, period: TimeInterval, phase: CGFloat) -> SKAction {
        // rotate from -A to +A and back, eased
        let A = amplitudeDeg * .pi/180
        let half = period / 2
        let toPos = SKAction.rotate(toAngle:  A, duration: half, shortestUnitArc: true)
        toPos.timingMode = .easeInEaseOut
        let toNeg = SKAction.rotate(toAngle: -A, duration: half, shortestUnitArc: true)
        toNeg.timingMode = .easeInEaseOut

        // phase offset at start
        let startAngle = A * sin(phase)
        let setPhase = SKAction.rotate(toAngle: startAngle, duration: 0)

        return .sequence([setPhase, .repeatForever(.sequence([toPos, toNeg]))])
    }

    /// Briefly steer toward a higher angle, used inside gusts
    private func swayToPeak(_ leaf: SKSpriteNode, amplitudeDeg: CGFloat, duration: TimeInterval) -> SKAction {
        let A = amplitudeDeg * .pi/180
        // pick current side and push further that way
        let target = (leaf.zRotation >= 0) ? A : -A
        let rot = SKAction.rotate(toAngle: target, duration: duration, shortestUnitArc: true)
        rot.timingMode = .easeInEaseOut
        return rot
    }

    // MARK: SKAnimatableNode
    func startAnimation() { startWind() }
    func stopAnimation() { stopWind() }
    var size: CGSize { body.size }
}
