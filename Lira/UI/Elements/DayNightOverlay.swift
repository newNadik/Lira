import SwiftUI

struct DayNightOverlay: View {
    var body: some View {
        let (color, opacity) = Self.colorAndOpacity(for: Date())
        return color
            .opacity(opacity)
    }
    /// Returns a single color and recommended opacity for the current time of day.
    static func colorAndOpacity(for date: Date) -> (Color, Double) {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: date)
        let hour = comps.hour ?? 12
        let minute = comps.minute ?? 0
        let h = Double(hour) + Double(minute)/60.0

        // Choose one representative color per phase (kept close to your gradients)
        let morningColor = Color(red: 1.00, green: 0.80, blue: 0.88) // soft pink
        let dayColor     = Color(red: 1.00, green: 0.96, blue: 0.82) // pale yellow
        let eveningColor = Color(red: 0.78, green: 0.70, blue: 0.92) // lilac-pink mix
        let nightColor   = Color(red: 0.06, green: 0.10, blue: 0.22) // deep navy

        // Time ranges (24h clock)
        // Morning: 05:00–09:00
        // Day:     09:00–17:00
        // Evening: 17:00–20:00
        // Night:   20:00–05:00
        switch h {
        case 5..<9:
            // Fade morning opacity down toward day
            let t = (h - 5) / 4 // 0..1
            let opacity = 0.28 - 0.10 * t
            return (morningColor, opacity)
        case 9..<17:
            let opacity = 0.14
            return (dayColor, opacity)
        case 17..<20:
            let t = (h - 17) / 3 // 0..1
            let opacity = 0.22 + 0.10 * t
            return (eveningColor, opacity)
        default:
            let opacity = 0.34
            return (nightColor, opacity)
        }
    }
}
