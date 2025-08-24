
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
}

extension SKAnimatableNode where Self: SKNode {
    func setHeight(_ targetHeight: CGFloat) {
        let scale = targetHeight / size.height
        self.setScale(scale)
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
