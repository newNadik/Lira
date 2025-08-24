import Foundation

extension DialogLine {
    static func welcomeSequence(onHelp: @escaping () -> Void,
                                onSkip: @escaping () -> Void,
                                onDone: @escaping () -> Void) -> [DialogLine] {
        [
            DialogLine(text: "Oh, visitor!\nWelcome to planet Lira"),
            DialogLine(text: "We’ve just begun this settlement, and there’s plenty to do"),
            DialogLine(text: "• [steps_icon] Go on expeditions — your steps power our scouts"),
            DialogLine(text: "• [sleep_icon] Dream up new tech — your sleep fuels research"),
            DialogLine(text: "• [sun_icon] Nurture the greenhouses — daylight helps crops grow"),
            DialogLine(text: "• [exercise_icon] Raise new buildings — workouts speed construction"),
            DialogLine(
                text: "Would you like to help? (Connect your Health data so it can power Lira)",
                buttons: [
                    DialogChoice(title: "Not now", role: .secondary, action: onSkip),
                    DialogChoice(title: "I’ll help", role: .primary, action: onHelp)
                ],
                allowTapToAdvance: false
            ),
            DialogLine(text: "Great! Feel free to look around the settlement — explore the city, open the Journal, and check stats",
                       buttons: [
                           DialogChoice(title: "Done", role: .primary, action: onDone)
                       ],
                       allowTapToAdvance: false),
        ]
    }
}
