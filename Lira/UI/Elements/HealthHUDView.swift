import SwiftUI

struct HealthHUDView: View {
    
    @ObservedObject var hk: HealthKitManager

    @Environment(\.horizontalSizeClass) private var hSizeClass
    
    private var gridColumns: [GridItem] {
        // iPhone (compact width): 2 columns -> 2 rows of 2
        // iPad (regular width): 4 columns -> single row of 4
        let count = 4 //(hSizeClass == .compact) ? 2 : 4
        return Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .center), count: count)
    }

    var body: some View {
        LazyVGrid(columns: gridColumns, alignment: .center, spacing: 10) {
            HealthStatCard(
                title: "Steps",
                iconName: "steps_icon", // Replace with your asset name
                valueText: "\(Int(hk.snapshot.stepsToday))"
            )

            HealthStatCard(
                title: "Sun",
                iconName: "sun_icon", // Replace with your asset name
                valueText: formatMinutes(Int(hk.snapshot.daylightMinutesToday))
            )

            HealthStatCard(
                title: "Sleep",
                iconName: "sleep_icon", // Replace with your asset name
                valueText: formatHoursMinutes(hk.snapshot.sleepHoursPrevNight)
            )

            HealthStatCard(
                title: "Exercise",
                iconName: "exercise_icon", // Replace with your asset name
                valueText: formatMinutes(Int(hk.snapshot.exerciseMinutesToday))
            )
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(.vertical, 4)
        .background(Color.clear)
    }

    private func formatMinutes(_ minutes: Int) -> String {
        return "\(minutes)m"
    }

    private func formatHoursMinutes(_ minutes: Double) -> String {
        let hours = Int(hk.snapshot.sleepHoursPrevNight)
        let minutes = Int((hk.snapshot.sleepHoursPrevNight - Double(hours)) * 60)
        if hours > 0 {
            return String(format: "%d:%d", hours, minutes)
        } else {
            return "\(minutes)"
        }
    }
}

// MARK: - Card View

struct HealthStatCard: View {
    let title: String
    let iconName: String
    let valueText: String

    var body: some View {
        HStack(spacing: 0) {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 30)
            
            Text(valueText)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(Color("brown"))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .padding(.horizontal, 5)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color("beige"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color("brown"), lineWidth: 2.5)
        )
        .shadow(color: Color("brown").opacity(0.2), radius: 3, x: 1, y: 2)
    }
}

#if DEBUG
struct HealthHUDView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            HealthHUDView(hk: HealthKitManager())
                .padding(.top, 16)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}
#endif
