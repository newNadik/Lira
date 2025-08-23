import SwiftUI

struct SettlementStatsPopup: View {
    struct StateSnapshot {
        let population: Double
        let housingCapacity: Double
        let foodStockRations: Double
        let greenhouseCount: Double
        let technologyLevel: Double
        let exploredRadiusKm: Double
        let buildPoints: Double
        let sciencePoints: Double
        let schoolCount: Double
        let currentDayIndex: Int
    }

    // Accept a strongly-typed state. If your vm.state is a custom type,
    // you can add an init to map it to this snapshot.
    let state: StateSnapshot
    var onClose: () -> Void

    init(state: SimulationState, onClose: @escaping () -> Void) {
        self.state = .init(
            population: state.population,
            housingCapacity: state.housingCapacity,
            foodStockRations: state.foodStockRations,
            greenhouseCount: state.greenhouseCount,
            technologyLevel: state.technologyLevel,
            exploredRadiusKm: state.exploredRadiusKm,
            buildPoints: state.buildPoints,
            sciencePoints: state.sciencePoints,
            schoolCount: state.schoolCount,
            currentDayIndex: state.currentDayIndex
        )
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Settlement Overview", systemImage: "building.2.crop.circle")
                    .font(.headline)
                    .foregroundColor(Color("brown"))
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

            ScrollView {
                VStack(spacing: 24) {
                    StatsSection(title: "Population") {
                        gridRow("Population", value: state.population, asInt: true)
                        gridRow("Beds", value: state.housingCapacity, asInt: true)
                        gridRow("Schools", value: state.schoolCount, asInt: true)
                    }
                    StatsSection(title: "Resources") {
                        gridRow("Food stock (rations)", value: state.foodStockRations)
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
                        gridRow("Explored radius (km)", value: state.exploredRadiusKm)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .frame(maxWidth: 420)
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
    private func gridRow(_ title: String, value: Double, asInt: Bool = false) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(Color("brown"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 12)
            Text(format(value, asInt: asInt))
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
        f.maximumFractionDigits = 1
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
