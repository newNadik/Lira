import SwiftUI

@main
struct LiraApp: App {
    @State private var showingMain = false
    @State private var showCurtain = true
    
    @StateObject private var bgm = BGMPlayer()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showingMain {
                    MainSceneView() // your scrolling background
//                    ContentView()
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
                
                Image("grain")
                    .resizable(resizingMode: .tile)
                    .ignoresSafeArea()
                    .blendMode(.overlay)
                    .opacity(0.9)
                    .allowsHitTesting(false)
                
//                DayNightOverlay()
//                    .ignoresSafeArea()
//                    .blendMode(.overlay) // overlay or .multiply if you want stronger tinting
//                    .allowsHitTesting(false)
                
            }
            .onAppear {
                // List all your track base names (without extension)
                // e.g. "bgm_forest.mp3" → "bgm_forest"
                bgm.loadAndPlay(
                    tracks: ["calm-sound-of-the-benjo-255105 Novifi", "WMNE_A001_BanjoLoving"], // add more like "bgm_menu", "bgm_calm"
                    preferredExtension: "mp3" // or "m4a" if that’s your files’ ext
                )
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:   bgm.resume()
                case .inactive: bgm.pause()
                case .background: bgm.pause()
                @unknown default: break
                }
            }
        }
    }
}
