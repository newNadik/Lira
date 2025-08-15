import SwiftUI

@main
struct LiraApp: App {
    @State private var showingMain = false
    @State private var showCurtain = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showingMain {
                    MainSceneView() // your scrolling background
                } else {
                    SplashView()
                }

                if showCurtain {
                    CloudCurtainOverlay(
                        leftFront:  "clouds_left_front",
                        leftBack:   "clouds_left_back",
                        rightFront: "clouds_right_front",
                        rightBack:  "clouds_right_back",
                        runOnceKey: nil, //"didRunCloudCurtain",
                        onCovered:  { showingMain = true },
                        onFinished: { showCurtain = false }
                    )
                }
            }
        }
    }
}
