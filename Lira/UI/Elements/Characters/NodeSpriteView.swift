import SwiftUI
import SpriteKit

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

    private var scene: SKScene {
        let aspect = node.size.width / node.size.height
        let width = height * aspect
        let scene = SKScene(size: CGSize(width: width, height: height))
        scene.scaleMode = .resizeFill
        scene.backgroundColor = background
        node.position = CGPoint(x: width/2, y: height/2)
        scene.addChild(node)
        return scene
    }

    var body: some View {
        SpriteView(scene: scene)
            .frame(height: height) // width follows scene size
            .onAppear { node.startAnimation() }
            .onDisappear { node.stopAnimation() }
    }
}
