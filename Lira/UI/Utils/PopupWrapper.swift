import SwiftUI

struct PopupWrapper<Content: View>: View {
    let isPresented: Bool
    let z: Double
    @ViewBuilder var content: () -> Content

    var body: some View {
        Group {
            if isPresented {
                content()
                    .padding(20)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(z)
            }
        }
    }
}
