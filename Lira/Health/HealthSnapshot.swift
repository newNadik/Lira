import Foundation

public struct HealthSnapshot: Sendable {
    public var stepsToday: Double
    public var exerciseMinutesToday: Double
    public var daylightMinutesToday: Double
    public var sleepHoursPrevNight: Double

    public static let zero = HealthSnapshot(
        stepsToday: 0, exerciseMinutesToday: 0, daylightMinutesToday: 0, sleepHoursPrevNight: 0
    )
}

public enum HealthAuthState {
    case notDetermined
    case authorized
    case denied
}
