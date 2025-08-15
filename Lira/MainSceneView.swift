import SwiftUI
import SpriteKit

struct MainSceneView: View {

    @State private var scene = ScrollableBackgroundScene(
        size: UIScreen.main.bounds.size,
        imageName: "background"
    )

    var body: some View {

        ZStack(alignment: .top) {
            SpriteView(scene: scene, preferredFramesPerSecond: 60, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()

            HealthHUDView()
                .padding(.top, 16)
                .padding(.horizontal, 10)
            
        }
    }
}
