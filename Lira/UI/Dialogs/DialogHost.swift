import SwiftUI

struct DialogHost: View {
    @Binding var isPresented: Bool
    @ObservedObject var queue: DialogQueue
    var character: AnyView
    var onDismiss: (() -> Void)?
    @State private var isHiding: Bool = false
    @State private var presentedPhase: Bool = false
    @State private var bubblePhase: Bool = false

    init(
        isPresented: Binding<Bool>,
        queue: DialogQueue,
        onDismiss: (() -> Void)? = nil,
        character: AnyView
    ) {
        self._isPresented = isPresented
        self.queue = queue
        self.onDismiss = onDismiss
        self.character = character
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.black
                .opacity(isPresented ? 0.35 : 0.0)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.22), value: isPresented)
            
            // Persistent character — does not animate between lines
            if isPresented {
                character
                    .padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 50 : -50)
                    .padding(.bottom, 25)
                    .opacity(presentedPhase ? 1 : 0)
                    .scaleEffect(presentedPhase ? 1 : 0.98)
                    .offset(x: presentedPhase ? 0 : -18, y: presentedPhase ? 0 : 6)
                    .animation(.spring(response: 0.45, dampingFraction: 0.85, blendDuration: 0.2), value: presentedPhase)
                    .transition(.identity)
                    .shadow(color: Color("brown").opacity(0.4), radius: 10, x: 1, y: 1)
            }

            // Only the bubble (text + buttons) changes and animates
            if let line = queue.current, isPresented {
                DialogView(
                    character: AnyView(EmptyView()), // keep character out of the bubble
                    line: lineWithDefaultNext(line),
                    onChoice: handleChoice(_:),
                    isHiding: $isHiding,
                    onHidden: {
                        // actually dismiss after exit animation
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isPresented = false
                            isHiding = false
                        }
                        onDismiss?()
                    }
                )
                .id(queue.index) // trigger transition when line index changes
                .opacity(bubblePhase ? 1 : 0)
                .scaleEffect(bubblePhase ? 1 : 0.98)
                .offset(y: bubblePhase ? 0 : 8)
                .shadow(color: .black.opacity(bubblePhase ? 0.25 : 0.0), radius: bubblePhase ? 10 : 0, x: 0, y: 8)
                .animation(.spring(response: 0.35, dampingFraction: 0.88, blendDuration: 0.2), value: bubblePhase)
                .transition(.opacity)
            }
        }
        // Animate line changes and presentation/dismissal
        .animation(.spring(response: 0.35, dampingFraction: 0.88, blendDuration: 0.2), value: queue.index)
        .animation(.easeInOut(duration: 0.25), value: isPresented)
        .onAppear {
            if isPresented {
                presentedPhase = true
                bubblePhase = true
            }
        }
        .onChange(of: isPresented) { newValue in
            withAnimation(.easeInOut(duration: 0.22)) {
                presentedPhase = newValue
            }
            if newValue {
                // re-pop the bubble
                bubblePhase = false
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.88, blendDuration: 0.2)) {
                        bubblePhase = true
                    }
                }
            } else {
                bubblePhase = false
            }
        }
        .onChange(of: queue.index) { _ in
            // animate bubble on line advance
            bubblePhase = false
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.88, blendDuration: 0.2)) {
                    bubblePhase = true
                }
            }
        }
    }

    private func lineWithDefaultNext(_ line: DialogLine) -> DialogLine {
        guard line.buttons.isEmpty else { return line }
        var copy = line
        let isLast = (queue.lines.count > 0 && queue.index == queue.lines.count - 1)
        copy.buttons = [DialogChoice(title: isLast ? "Done" : "Next", role: .primary)]
        return copy
    }

    private func handleChoice(_ choice: DialogChoice?) {
        choice?.action?()

        // If this is the last line, do not advance the queue yet —
        // keep the current line on screen so DialogView can animate out.
        let isLast = (queue.lines.count > 0 && queue.index == queue.lines.count - 1)
        if isLast {
            isHiding = true
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.88, blendDuration: 0.2)) {
                queue.next()
            }
        }
    }
}
