import SwiftUI
import SpriteKit

struct MainSceneView: View {

    @StateObject private var vm = SimulationViewModel()
    @State private var showStats = false
    
    @State private var scene = ScrollableBackgroundScene(
        size: UIScreen.main.bounds.size,
        imageName: "background"
    )

    var body: some View {

        ZStack(alignment: .top) {
            SpriteView(scene: scene, preferredFramesPerSecond: 60, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()

            VStack(alignment: .trailing) {
                HealthHUDView()
                    .padding(.top, 16)
                    .padding(.horizontal, 10)
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9, blendDuration: 0.2)) {
                        showStats.toggle()
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Label("Stats", systemImage: "chart.bar.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(SoftPillButtonStyle())
                .accessibilityLabel("Open settlement stats")
                .padding(.top, 16)
                .padding(.trailing, 10)
            }

            if showStats {
                // Dimmed background
                Color.black.opacity(0.28)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { withAnimation { showStats = false } }

                // Popup card
                SettlementStatsPopup(state: vm.state, onClose: { withAnimation { showStats = false } })
                    .padding(20)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.35, dampingFraction: 0.9), value: showStats)
            }
        }
    }
}
