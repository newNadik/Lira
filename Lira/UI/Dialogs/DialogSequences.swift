import Foundation

extension DialogLine {
    static func welcomeSequence(onHelp: @escaping () -> Void,
                                onSkip: @escaping () -> Void) -> [DialogLine] {
        [
            DialogLine(text: "Oh, visitor!\nWelcome to planet Lira"),
            DialogLine(text: "We’ve just begun this settlement, and there’s plenty to do:"),
            DialogLine(text: "You can [steps_icon] walk with our expeditions to explore nearby lands and gather resources"),
            DialogLine(text: "Or [sleep_icon] dream with our researchers to spark new technologies"),
            DialogLine(text: "You can tend the [sun_icon] greenhouses"),
            DialogLine(text: "or [exercise_icon] help raise new buildings"),
            
            DialogLine(
                text: "Would you like to lend a hand?",
                buttons: [
                    DialogChoice(title: "Next time", role: .secondary, action: onSkip),
                    DialogChoice(title: "Yes", role: .primary, action: onHelp)
                ],
                allowTapToAdvance: false
            ),
            DialogLine(text: "Great! See you around")
        ]
    }
}
