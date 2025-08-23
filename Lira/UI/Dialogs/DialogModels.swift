import Foundation

public struct DialogLine: Identifiable, Equatable {
    public let id = UUID()
    public var speakerName: String? = nil
    public var text: String
    public var buttons: [DialogChoice] = []      // 0–2
    public var allowTapToAdvance: Bool = true

    public init(speakerName: String? = nil,
                text: String,
                buttons: [DialogChoice] = [],
                afterText: String? = nil,
                allowTapToAdvance: Bool = true) {
        self.speakerName = speakerName
        self.text = text
        self.buttons = buttons
        self.allowTapToAdvance = allowTapToAdvance
    }
}

public struct DialogChoice: Identifiable, Equatable {
    public static func == (lhs: DialogChoice, rhs: DialogChoice) -> Bool {
        lhs.title.elementsEqual(rhs.title)
    }
    
    public enum Role { case primary, secondary }
    public let id = UUID()
    public var title: String
    public var role: Role
    public var action: (() -> Void)?

    public init(title: String, role: Role = .primary, action: (() -> Void)? = nil) {
        self.title = title
        self.role = role
        self.action = action
    }
}
