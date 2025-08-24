import SpriteKit

final class ScrollableBackgroundScene: SKScene {
    private let imageName: String
    private var bg: SKSpriteNode!
    private var cam = SKCameraNode()

    // Touch & pan state
    private var lastTouchX: CGFloat?
    private var lastTouchTime: TimeInterval?
    private var isDragging = false

    // Camera smoothing/inertia
    private var targetCamX: CGFloat = 0
    private var camVelocity: CGFloat = 0 // points/sec in scene space
    private var lastUpdateTime: TimeInterval = 0

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

        layoutBackgroundToFitHeight()
        centerCamera()

        targetCamX = cam.position.x
        camVelocity = 0
        
        // TEST Char
        let lir = LirSpriteNode()
        lir.setHeight(300)
        lir.position = CGPoint(x: 0, y: -100)
        addChild(lir)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        // Make sure nodes exist if size changes early
        ensureBackground()
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

        // Update target position (grab world)
        targetCamX -= dxScene
        clampTarget()

        // Instantaneous velocity for flicks (points/sec)
        camVelocity = (-dxScene) / dt

        lastTouchX = x
        lastTouchTime = touch.timestamp
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDragging = false
        lastTouchX = nil
        lastTouchTime = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
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
}
