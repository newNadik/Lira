import SwiftUI

struct SettlementStatsPopup: View {

    // Accept a strongly-typed state. If your vm.state is a custom type,
    // you can add an init to map it to this snapshot.
    let state: SimulationState
    var onClose: () -> Void

    init(state: SimulationState, onClose: @escaping () -> Void) {
        self.state = state
        self.onClose = onClose
    }

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image("stats_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)   // keep it small, like the HUD icons
                        Text("Settlement Overview")
                            .font(.headline)
                            .foregroundColor(Color("brown"))
                    }
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color("brown"))
                            .padding(6)
                    }
                    .keyboardShortcut(.cancelAction)
                    .accessibilityLabel("Close stats")
                }
                Text("Day \(state.currentDayIndex)")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(Color("brown"))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 2)
                
                ViewThatFits(in: .vertical) {
                    // If content fits, no scrolling and the popup shrinks to content.
                    statsContent()
                    
                    // If it doesn't fit, fall back to a scrollable area with a sensible max height.
                    ScrollView {
                        statsContent()
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                    .frame(maxHeight: 500)
                }
            }
            .padding(14)
            .frame(maxWidth: 600)
            .frame(alignment: .bottom)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color("beige"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color("brown"), lineWidth: 2.5)
            )
            .shadow(color: Color("brown").opacity(0.18), radius: 12, x: 0, y: 6)
        }
    }

    @ViewBuilder
    private func statsContent() -> some View {
        VStack(spacing: 24) {
            StatsSection(title: "Population") {
                gridRow("Population", value: state.population, asInt: true)
                gridRow("Beds", value: state.housingCapacity, asInt: true)
                gridRow("Schools", value: state.schoolCount, asInt: true)
            }
            StatsSection(title: "Resources") {
                gridRow("Food stock (rations)", value: state.foodStockRations, asInt: true)
                gridRow("Build points", value: state.buildPoints)
            }
            StatsSection(title: "Infrastructure") {
                gridRow("Greenhouses", value: state.greenhouseCount, asInt: true)
            }
            StatsSection(title: "Research") {
                gridRow("Tech level", value: state.technologyLevel)
                gridRow("Science points", value: state.sciencePoints)
            }
            StatsSection(title: "Explored Area") {
                gridRow("Explored radius", value: state.exploredRadiusKm, unit: "km", metersIfSmall: true)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - UI Helpers
    @ViewBuilder
    private func StatsSection(
        title: String,
        alignment: HorizontalAlignment = .leading,
        titleAlignment: Alignment = .leading,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: alignment, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color("brown"))
                .padding(.top, 6)
                .frame(maxWidth: .infinity, alignment: titleAlignment)
            VStack(spacing: 6) { content() }
        }
    }

    @ViewBuilder
    private func gridRow(_ title: String, value: Double, asInt: Bool = false, unit: String? = nil, metersIfSmall: Bool = false) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(Color("brown"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 12)
            Text(formatWithUnit(value, asInt: asInt, unit: unit, metersIfSmall: metersIfSmall))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(Color("brown"))
        }
        .padding(.vertical, 6)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color("brown").opacity(0.2)),
            alignment: .bottom
        )
    }

    private func format(_ value: Double, asInt: Bool) -> String {
        if asInt { return String(Int(value.rounded())) }
        // Show up to one decimal for non-int values
        let f = NumberFormatter()
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func formatWithUnit(_ value: Double, asInt: Bool, unit: String?, metersIfSmall: Bool) -> String {
        var displayValue = value
        var displayUnit = unit ?? ""

        if metersIfSmall, value < 1.0 {
            displayValue = value * 1000.0
            displayUnit = "m"
            return "\(Int(displayValue.rounded())) \(displayUnit)"
        }

        let base = format(displayValue, asInt: asInt)
        if !displayUnit.isEmpty {
            return "\(base) \(displayUnit)"
        } else {
            return base
        }
    }
}
