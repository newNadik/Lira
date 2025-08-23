import SwiftUI

struct CharacterSpriteView: View {
    /// Name of the image in the asset catalog.
    var imageName: String
    /// Desired rendered height for the sprite block.
    var height: CGFloat = 400
    /// Optional accessibility label (kept hidden visually by default; supply if you want VO to announce the character).
    var accessibilityLabel: String? = nil
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: height)
                    .accessibilityHidden(accessibilityLabel == nil)
                    .accessibilityLabel(Text(accessibilityLabel ?? ""))
            }
        }
    }
}
