import SwiftUI

struct SplashView: View {
    var imageName: String = "splash_bg"   // Replace with your splash image name
    var background: Color = .black        // Color for letterbox areas

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width,
                       height: UIScreen.main.bounds.height)
                .clipped()
                .ignoresSafeArea()
        }
    }
}
