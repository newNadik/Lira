import SwiftUI

struct DialogHost: View {
    @Binding var isPresented: Bool
    @ObservedObject var queue: DialogQueue
    var character: AnyView
    var onDismiss: (() -> Void)?
    @State private var isHiding: Bool = false

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
        Group {
            if let line = queue.current, isPresented {
                DialogView(
                    character: character,
                    line: lineWithDefaultNext(line),
                    onChoice: handleChoice(_:),
                    isHiding: $isHiding,
                    onHidden: {
                        // actually dismiss after exit animation
                        isPresented = false
                        isHiding = false
                        onDismiss?()
                    }
                )
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
            queue.next()
        }
    }
}
