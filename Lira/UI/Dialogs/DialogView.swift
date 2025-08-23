import SwiftUI

struct DialogView: View {
    var character: AnyView                // pass CharacterSpriteView().erased()
    var line: DialogLine
    var onChoice: (DialogChoice?) -> Void // nil means default next
    @Binding var isHiding: Bool           // host toggles this to start exit animation
    var onHidden: (() -> Void)? = nil     // called after exit animation completes

    @State private var isAppeared: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black
                .opacity(isAppeared ? 0.35 : 0.0)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.22), value: isAppeared)
            
            ZStack(alignment: .bottomLeading) {
                character
                    .padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 50 : -50)
                    .padding(.bottom, 25)
                
                VStack(spacing: -10) {
                    
                    // Speaker name badge — overlap top-left corner of the box
                    if let name = line.speakerName, !name.isEmpty {
                        HStack {
                            Text(name)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(Color("brown"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color("beige"))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color("brown"), lineWidth: 3)
                                )
                                .accessibilityLabel(Text("\(name) says"))
                                .offset(x: -10)
                            
                            Spacer()
                        }
                        .zIndex(10)
                    }
                    
                    // Main text box
                    InlineImageText(text: line.text, imageSize: 27, imageBaselineOffset: -7, textColor: UIColor(named: "brown") ?? .black)
                        .padding(15)
                        .padding(.bottom, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color("beige"))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("brown"), lineWidth: 3)
                        )
                    
                    HStack(spacing: 8) {
                        Spacer()
                        
                        if line.buttons.isEmpty {
                            Button("Next") { onChoice(nil) }
                                .buttonStyle(SoftPillButtonStyle())
                                .keyboardShortcut(.defaultAction)
                                .frame(height: 40)
                        } else {
                            ForEach(line.buttons) { choice in
                                Button(choice.title) { onChoice(choice) }
                                    .buttonStyle(SoftPillButtonStyle())
                                    .keyboardShortcut(choice.role == .primary ? .defaultAction : .cancelAction)
                                    .frame(height: 40)
                            }
                        }
                    }
                    .offset(y: -10)
                    .padding(.trailing, 10)
                }
                .padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 250 : 50)
                .padding(.trailing, 10)
                .frame(maxWidth: 700)
            }
            .offset(y: isAppeared ? 0 : 40)
            .opacity(isAppeared ? 1 : 0)
            .animation(.spring(response: 0.35, dampingFraction: 0.9, blendDuration: 0.2), value: isAppeared)
            .onChange(of: isHiding) { hiding in
                if hiding {
                    // trigger exit animation
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9, blendDuration: 0.2)) {
                        isAppeared = false
                    }
                    // call back after the animation finishes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        onHidden?()
                    }
                }
            }
        }
        .onAppear {
            // Trigger self-contained entrance animation when this view mounts
            isAppeared = true
        }
        .onDisappear {
            // Prepare for a clean exit animation
            isAppeared = false
        }
    }
}

extension View {
    func erased() -> AnyView { AnyView(self) }
}
