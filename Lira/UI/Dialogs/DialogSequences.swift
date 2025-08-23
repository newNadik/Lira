import Foundation

extension DialogLine {
    static func welcomeSequence(onHelp: @escaping () -> Void,
                                onSkip: @escaping () -> Void,
                                onDone: @escaping () -> Void) -> [DialogLine] {
        [
            DialogLine(text: "Oh, visitor!\nWelcome to planet Lira"),
            DialogLine(text: "We’ve just begun this settlement, and there’s plenty to do"),
            DialogLine(text: "[steps_icon] Go on expeditions to gather resources"),
            DialogLine(text: "[sleep_icon] Dream of new technologies with our researchers"),
            DialogLine(text: "[sun_icon] Nurture the greenhouses"),
            DialogLine(text: "[exercise_icon] Raise new buildings"),
            DialogLine(
                text: "Would you like to join?",
                buttons: [
                    DialogChoice(title: "Not now", role: .secondary, action: onSkip),
                    DialogChoice(title: "I’ll help", role: .primary, action: onHelp)
                ],
                allowTapToAdvance: false
            ),
            DialogLine(text: "Great! See you around",
                       buttons: [
                           DialogChoice(title: "Done", role: .primary, action: onDone)
                       ],
                       allowTapToAdvance: false)
        ]
    }
}
