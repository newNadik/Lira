import Foundation
import Combine
import SwiftUI

final class DialogQueue: ObservableObject {
    @Published private(set) var lines: [DialogLine] = []
    @Published private(set) var index: Int = 0

    var characterView: AnyView? = nil
    
    var isFinished: Bool { index >= lines.count }
    var current: DialogLine? { isFinished ? nil : lines[index] }

    func load(_ lines: [DialogLine]) { self.lines = lines; index = 0 }
    func append(_ line: DialogLine) { lines.append(line) }
    func next() { index = min(index + 1, lines.count) }
    func reset() { lines.removeAll(); index = 0 }
}
