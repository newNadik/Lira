
import SwiftUI
import SpriteKit

#if canImport(UIKit)
import UIKit
private typealias _PlatformViewRepresentable = UIViewRepresentable
private typealias _PlatformView = SKView
#else
import AppKit
private typealias _PlatformViewRepresentable = NSViewRepresentable
private typealias _PlatformView = SKView
#endif
private struct TransparentSpriteContainer: _PlatformViewRepresentable {
    let scene: SKScene

    #if canImport(UIKit)
    func makeUIView(context: Context) -> _PlatformView {
        let v = SKView()
        v.allowsTransparency = true
        v.ignoresSiblingOrder = false
        v.isAsynchronous = true
        v.backgroundColor = .clear
        v.presentScene(scene)
        return v
    }

    func updateUIView(_ uiView: _PlatformView, context: Context) {
        if uiView.scene !== scene { uiView.presentScene(scene) }
        uiView.allowsTransparency = true
        uiView.backgroundColor = .clear
    }
    #else
    func makeNSView(context: Context) -> _PlatformView {
        let v = SKView()
        v.allowsTransparency = true
        v.ignoresSiblingOrder = false
        v.isAsynchronous = true
        v.backgroundColor = .clear
        v.presentScene(scene)
        return v
    }

    func updateNSView(_ nsView: _PlatformView, context: Context) {
        if nsView.scene !== scene { nsView.presentScene(scene) }
        nsView.allowsTransparency = true
        nsView.backgroundColor = .clear
    }
    #endif
}

protocol SKAnimatableNode: AnyObject {
    func startAnimation()
    func stopAnimation()
    var size: CGSize { get }
    
    /// scale the node so its height matches `targetHeight`
    func setHeight(_ targetHeight: CGFloat)
    
    func runSineSway(on node: SKSpriteNode,
                              amplitudeDeg: CGFloat,
                              period: TimeInterval,
                              phase: CGFloat,
                              key: String)
    
    func runSineBob(on node: SKSpriteNode,
                             amplitude: CGFloat,
                             period: TimeInterval,
                             key: String)
    
    func addDropShadow(
        offset: CGPoint,
        color: SKColor,
        alpha: CGFloat,
        scale: CGFloat)
}

extension SKAnimatableNode where Self: SKNode {
    func setHeight(_ targetHeight: CGFloat) {
        let scale = targetHeight / size.height
        self.setScale(scale)
    }
    
    
    // MARK: Helpers
    /// Continuous sine-based rotation (very smooth). Repeats forever without hard edges.
    func runSineSway(on node: SKSpriteNode,
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
    func runSineBob(on node: SKSpriteNode,
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
    
    func addDropShadow(
        offset: CGPoint = CGPoint(x: 1, y: 2),
        color: SKColor = .black,
        alpha: CGFloat = 0.2,
        scale: CGFloat = 3.0
    ) {
        // Render this node into a texture
        if let scene = self.scene,
           let texture = scene.view?.texture(from: self) {
            
            let shadow = SKSpriteNode(texture: texture)
            shadow.color = color
            shadow.colorBlendFactor = 1.0
            shadow.alpha = alpha
            shadow.zPosition = self.zPosition - 1
            shadow.setScale(scale)
            shadow.position = CGPoint(
                x: self.position.x + offset.x,
                y: self.position.y + offset.y
            )
            
            self.parent?.addChild(shadow)
        }
    }
}

struct NodeSpriteView<NodeType: SKNode & SKAnimatableNode>: View {
    let node: NodeType
    let height: CGFloat
    var background: SKColor = .clear

    private let scene: SKScene
    private let width: CGFloat

    init(node: NodeType, height: CGFloat, background: SKColor = .clear) {
        self.node = node
        self.height = height
        self.background = background

        // Measure the unscaled visual bounds (including children)
        // by temporarily parenting the node to a container.
        let tempParent = SKNode()
        tempParent.addChild(node)
        let unscaledBounds = node.calculateAccumulatedFrame() // in tempParent's coords
        node.removeFromParent()

        // Add a small headroom so leaf rotation/bobbing doesn't clip
        let safety: CGFloat = 1.12 // 12% extra height
        let targetContentHeight = height / safety

        // Compute scale to fit the full visual height, and resulting width
        let scale = targetContentHeight / unscaledBounds.height
        let computedWidth = unscaledBounds.width * scale
        self.width = computedWidth

        // Build scene once
        let s = SKScene(size: CGSize(width: computedWidth, height: height))
        s.scaleMode = .resizeFill
        s.backgroundColor = background // .clear by default

        // Add, scale, and visually center the node by its accumulated bounds
        s.addChild(node)
        node.setScale(scale)
        node.position = CGPoint(x: computedWidth/2, y: height/2)
        // Now nudge so the *visual* bounds center matches the scene center
        let boundsAfterScale = node.calculateAccumulatedFrame()
        let dx = computedWidth/2 - boundsAfterScale.midX
        let dy = height/2 - boundsAfterScale.midY
        node.position = CGPoint(x: node.position.x + dx, y: node.position.y + dy)

        self.scene = s
    }

    var body: some View {
        TransparentSpriteContainer(scene: scene)
            .frame(width: width, height: height)
            .background(Color.clear)
            .onAppear { node.startAnimation() }
            .onDisappear { node.stopAnimation() }
    }
}
