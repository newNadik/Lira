import SwiftUI

struct DialogButtonStyle: ButtonStyle {
    let role: DialogChoice.Role
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(role == .primary ? Color.brown.opacity(configuration.isPressed ? 0.85 : 1.0)
                                           : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.brown, lineWidth: 2)
            )
            .foregroundColor(role == .primary ? Color("beige") : .brown)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
