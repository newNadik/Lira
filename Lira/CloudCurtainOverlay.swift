import SwiftUI

struct CloudCurtainOverlay: View {
    let leftFront: String
    let leftBack: String
    let rightFront: String
    let rightBack: String
    var durationIn: Double = 0.7
    var durationOut: Double = 1.0
    var coveredPause: Double = 0.0
    var runOnceKey: String? = nil
    var outOvershoot: CGFloat = 2.0 // extra distance so clouds fully clear the screen

    var onCovered: () -> Void
    var onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var leftFrontX: CGFloat = 0
    @State private var leftBackX: CGFloat = 0
    @State private var rightFrontX: CGFloat = 0
    @State private var rightBackX: CGFloat = 0
    @State private var started = false
    @State private var fixedWidth: CGFloat? = nil
    @State private var fixedHeight: CGFloat? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // BACK layers
                Image(leftBack)
                    .resizable().scaledToFill()
                    .frame(width: fixedWidth ?? geo.size.width, height: fixedHeight ?? geo.size.height)
                    .offset(x: leftBackX)
                    .ignoresSafeArea()

                Image(rightBack)
                    .resizable().scaledToFill()
                    .frame(width: fixedWidth ?? geo.size.width, height: fixedHeight ?? geo.size.height)
                    .offset(x: rightBackX)
                    .ignoresSafeArea()

                // FRONT layers
                Image(leftFront)
                    .resizable().scaledToFill()
                    .frame(width: fixedWidth ?? geo.size.width, height: fixedHeight ?? geo.size.height)
                    .offset(x: leftFrontX)
                    .ignoresSafeArea()

                Image(rightFront)
                    .resizable().scaledToFill()
                    .frame(width: fixedWidth ?? geo.size.width, height: fixedHeight ?? geo.size.height)
                    .offset(x: rightFrontX)
                    .ignoresSafeArea()
            }
            .contentShape(Rectangle())
            .allowsHitTesting(false)
            .onAppear {
                if reduceMotion || (runOnceKey != nil && UserDefaults.standard.bool(forKey: runOnceKey!)) {
                    onCovered()
                    onFinished()
                    return
                }

                if fixedWidth == nil || fixedHeight == nil {
                    fixedWidth = geo.size.width
                    fixedHeight = geo.size.height
                }

                guard !started else { return }
                started = true

                let W = geo.size.width

                // Start off-screen
                leftFrontX  = -W
                rightFrontX =  W
                leftBackX   = -W
                rightBackX  =  W

                // Slide IN (back layers move a little less for depth)
                withAnimation(.easeOut(duration: durationIn)) {
                    leftFrontX  = 0
                    rightFrontX = 0
                    leftBackX   = -W * 0.1  // still slightly visible offset
                    rightBackX  =  W * 0.1
                }

                // After cover, swap content & slide OUT
                DispatchQueue.main.asyncAfter(deadline: .now() + durationIn + coveredPause) {
                    onCovered()
                    withAnimation(.easeIn(duration: durationOut)) {
                        let W = fixedWidth ?? geo.size.width
                        let frontOut = W * outOvershoot
                        let backOut  = W * 1.2 * outOvershoot

                        leftFrontX  =  frontOut   // continue moving right
                        rightFrontX = -frontOut   // continue moving left
                        leftBackX   =  backOut
                        rightBackX  = -backOut
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + durationOut) {
                        if let key = runOnceKey { UserDefaults.standard.set(true, forKey: key) }
                        onFinished()
                    }
                }
            }
        }
    }
}
