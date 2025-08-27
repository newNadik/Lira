import SpriteKit

final class ScrollableBackgroundScene: SKScene {
    private let imageName: String
    private var bg: SKSpriteNode!
    private var cam = SKCameraNode()

    // Touch & pan state
    private var lastTouchX: CGFloat?
    private var lastTouchTime: TimeInterval?
    private var isDragging = false

    // Tap vs. drag discrimination
    private var dragAccumulated: CGFloat = 0
    private let tapDragThreshold: CGFloat = 12 // in scene points

    // Character tap callback and references
    var onCharacterTapped: ((String) -> Void)?
    // Building tap callback
    var onBuildingTapped: ((String) -> Void)?
    private weak var lirNode: SKNode?
    private weak var beanieNode: SKNode?
    private weak var nayaNode: SKNode?
    private weak var luneNode: SKNode?

    // Camera smoothing/inertia
    private var targetCamX: CGFloat = 0
    private var camVelocity: CGFloat = 0 // points/sec in scene space
    private var lastUpdateTime: TimeInterval = 0

    // Building layering
    private static var nextBuildingZ: CGFloat = -3

    // Content sizing
    private let imgWidth: CGFloat = 2648
    private let imgHeight: CGFloat = 2048

    init(size: CGSize, imageName: String) {
        self.imageName = imageName
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5) // center origin
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func ensureBackground() {
        if bg == nil {
            bg = SKSpriteNode(imageNamed: imageName)
            bg.zPosition = -100
            addChild(bg)
        }
    }

    override func didMove(to view: SKView) {
        // Camera
        camera = cam
        addChild(cam)

        // Ensure background exists
        ensureBackground()
        setupCharacters()
        setupBuildings()

        layoutBackgroundToFitHeight()
        centerCamera()

        targetCamX = cam.position.x
        camVelocity = 0
    }

    override func didChangeSize(_ oldSize: CGSize) {
        // Make sure nodes exist if size changes early
        ensureBackground()
//        setupCharacters()
        layoutBackgroundToFitHeight()
        clampCamera()

        targetCamX = cam.position.x
    }

    private func layoutBackgroundToFitHeight() {
        guard let bg = bg, imgHeight > 0, size.height > 0 else { return }
        // Fit background to scene HEIGHT, preserve aspect
        let scale = size.height / imgHeight
        let targetWidth = imgWidth * scale
        let targetHeight = imgHeight * scale

        bg.size = CGSize(width: targetWidth, height: targetHeight)
        clampTarget()
        bg.position = .zero
    }

    private var maxPanOffsetX: CGFloat {
        // how far we can move left/right from center
        let halfScrollable = max(0, (bg.size.width - size.width) / 2)
        return halfScrollable
    }

    private func centerCamera() {
        cam.position = .zero
    }

    private func clampCamera() {
        let limit = maxPanOffsetX
        cam.position.x = min(max(cam.position.x, -limit), limit)
        cam.position.y = 0
    }

    private func clampTarget() {
        let limit = maxPanOffsetX
        targetCamX = min(max(targetCamX, -limit), limit)
    }

    // MARK: - Touch/drag to pan
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let skView = self.view else { return }
        lastTouchX = touch.location(in: skView).x
        lastTouchTime = touch.timestamp
        isDragging = true
        camVelocity = 0 // stop inertia while dragging
        dragAccumulated = 0
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let skView = self.view,
              let lastX = lastTouchX, let lastT = lastTouchTime else { return }
        let x = touch.location(in: skView).x
        let dxView = x - lastX
        let dt = max(0.0001, touch.timestamp - lastT)

        // Convert view-space delta to scene-space delta using current scale
        // We fit by height, so X scale equals Y scale.
        let scenePerPoint = size.height / skView.bounds.height
        let dxScene = dxView * scenePerPoint
        dragAccumulated += abs(dxScene)

        // Update target position (grab world)
        targetCamX -= dxScene
        clampTarget()

        // Instantaneous velocity for flicks (points/sec)
        camVelocity = (-dxScene) / dt

        lastTouchX = x
        lastTouchTime = touch.timestamp
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer {
            isDragging = false
            lastTouchX = nil
            lastTouchTime = nil
        }
        guard let touch = touches.first else { return }

        // If the user didn't drag much, treat as a tap.
        if dragAccumulated < tapDragThreshold {
            let location = touch.location(in: self)
            if let tapped = tappableSprite(at: location),
               let (kind, id) = tappableInfo(from: tapped) {
                switch kind {
                case .character:
                    onCharacterTapped?(id)
                case .building:
                    onBuildingTapped?(id)
                }
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        dragAccumulated = 0
        isDragging = false
        lastTouchX = nil
        lastTouchTime = nil
    }

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdateTime == 0 ? 1.0/60.0 : min(0.05, currentTime - lastUpdateTime)
        lastUpdateTime = currentTime

        // Smooth follow (critically-damped like) towards targetCamX
        // Convert a per-second smoothing factor into per-frame using dt
        let smoothingPerSecond: CGFloat = 12.0 // higher = snappier
        let alpha = 1 - exp(-smoothingPerSecond * dt)
        let newX = cam.position.x + (targetCamX - cam.position.x) * alpha
        cam.position.x = newX
        clampCamera()

        // Inertia when not dragging
        if !isDragging {
            // Exponential decay of velocity
            let decelPerSecond: CGFloat = 3.0
            let decay = exp(-decelPerSecond * dt)
            camVelocity *= decay

            // Advance target by remaining velocity
            if abs(camVelocity) > 1 { // threshold to stop tiny drift
                targetCamX += camVelocity * dt
                clampTarget()

                // If we hit an edge, zero velocity to avoid shudder
                let limit = maxPanOffsetX
                if targetCamX <= -limit || targetCamX >= limit { camVelocity = 0 }
            } else {
                camVelocity = 0
            }
        }
    }
    
    /// Naming convention for tappables:
    /// - Characters: name nodes as "character:<id>" (e.g., character:lir)
    /// - Buildings:  name the *group/root* node as "building:<groupId>" (e.g., building:greenhouse)
    ///   Children within the group can share the same name or be unnamed; taps bubble up via parent search.
    func setupCharacters() {
        
        let width = size.width
        let height = size.height
        
        let characterHeight = 130.0
        
        let lir = LirSpriteNode()
        lir.setHeight(characterHeight)
        lir.name = "character:lir"
        lirNode = lir
        lir.position = CGPoint(x: width * 0.65, y: height * -0.05)
        addChild(lir)
                
        let beanie = BeanieSpriteNode()
        beanie.setHeight(characterHeight)
        beanie.name = "character:beanie"
        beanieNode = beanie
        beanie.position = CGPoint(x: width * -0.5, y: height * -0.07)
        addChild(beanie)
        
        let naya = NayaSpriteNode()
        naya.setHeight(characterHeight)
        naya.name = "character:naya"
        nayaNode = naya
        naya.position = CGPoint(x: width * 0.04, y: height * 0.17)
        addChild(naya)
        
        
        let lune = LuneSpriteNode()
        lune.setHeight(characterHeight)
        lune.name = "character:lune"
        luneNode = lune
        lune.position = CGPoint(x: width * 0.025, y: height * -0.18)
        addChild(lune)
    }
    
    // MARK: - Hit testing helpers
    private enum TappableKind { case character, building }

    /// Returns the topmost tappable sprite under a point, preferring the front-most node.
    private func tappableSprite(at point: CGPoint) -> SKNode? {
        for node in nodes(at: point).reversed() {
            if tappableInfo(from: node) != nil { return node }
        }
        return nil
    }

    /// Walks up the parent chain to find a node named with a supported prefix and returns (kind, id).
    private func tappableInfo(from node: SKNode) -> (TappableKind, String)? {
        var current: SKNode? = node
        while let n = current {
            if let name = n.name {
                if name.hasPrefix("character:") {
                    let id = String(name.dropFirst("character:".count))
                    return (.character, id)
                } else if name.hasPrefix("building:") {
                    let id = String(name.dropFirst("building:".count))
                    return (.building, id)
                }
            }
            current = n.parent
        }
        return nil
    }

    func setupBuildings() {
        let width = size.width
        let height = size.height
        
        /// HOUSES
        addChild(makeBuilding(imageName: "house", height: 120, id: "house",
                              position: CGPoint(x: width * -0.75, y: height * -0.02)))
        addChild(makeBuilding(imageName: "house", height: 120, id: "house",
                              position: CGPoint(x: width * -0.57, y: height * 0.07)))
//        
//        addChild(makeBuilding(imageName: "house_big", height: 190, id: "house",
//                              position: CGPoint(x: width * -1.1, y: height * -0.04)))
//        
//        addChild(makeConstruction(id: "house", position: CGPoint(x: width * -1, y: height * 0.09)))
//        
//        addChild(makeBuilding(imageName: "house_big", height: 190, id: "house",
//                              position: CGPoint(x: width * -1.28, y: height * 0.05)))
//        
//        addChild(makeBuilding(imageName: "house", height: 120, id: "house",
//                              position: CGPoint(x: width * -0.85, y: height * 0.09)))
        
        /// GREENHOUSES
        addChild(makeBuilding(imageName: "greenhouse", height: 160, id: "greenhouse",
                              position: CGPoint(x: width * -0.23, y: height * 0.21)))
        
//        addChild(makeBuilding(imageName: "greenhouse_big", height: 200, id: "greenhouse",
//                              position: CGPoint(x: width * 0.13, y: height * 0.31)))
//        
//        addChild(makeConstruction(id: "greenhouse", position: CGPoint(x: width * -0.07, y: height * 0.33)))
//        
//        
//        addChild(makeBuilding(imageName: "greenhouse", height: 160, id: "greenhouse",
//                              position: CGPoint(x: width * -0.25, y: height * 0.35)))
    }
    
    func makeConstruction(id: String,
                          position: CGPoint) -> SKSpriteNode {
        let sprite = DustSprite()
        sprite.setHeight(240)
        sprite.position = position
        sprite.name = "building:\(id)"
        
        // Each new building goes behind the previous one
        sprite.zPosition = ScrollableBackgroundScene.nextBuildingZ
        ScrollableBackgroundScene.nextBuildingZ -= 1
            
        sprite.startAnimation()
        
        return sprite
    }
    
    func makeBuilding(imageName: String,
                      height: CGFloat,
                      id: String,
                      position: CGPoint) -> SKSpriteNode {
        
        let texture = SKTexture(imageNamed: imageName)
        let sprite = SKSpriteNode(texture: texture)
        
        // Preserve aspect ratio while setting height
        let aspect = texture.size().width / texture.size().height
        sprite.size = CGSize(width: height * aspect, height: height)
        
        sprite.position = position
        sprite.name = "building:\(id)"
        
        // Each new building goes behind the previous one
        sprite.zPosition = ScrollableBackgroundScene.nextBuildingZ
        ScrollableBackgroundScene.nextBuildingZ -= 1
        
        addShadow(to: sprite, color: UIColor(named: "brown") ?? .black)
        
        return sprite
    }
    
    func addShadow(to node: SKSpriteNode,
                   color: UIColor = .black,
                   offset: CGPoint = CGPoint(x: 4, y: -2),
                   alpha: CGFloat = 0.3,
                   blur: CGFloat = 6) {
        
        let shadow = SKSpriteNode(texture: node.texture)
        shadow.size = node.size
        shadow.color = color
        shadow.colorBlendFactor = 1.0
        shadow.alpha = alpha
        shadow.position = CGPoint(x: offset.x, y: offset.y)
        shadow.zPosition = node.zPosition - 1
        
        // Apply blur effect with an SKEffectNode
        let effect = SKEffectNode()
        effect.shouldRasterize = true
        effect.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": blur])
        effect.addChild(shadow)
        
        node.addChild(effect)
    }
    
}

