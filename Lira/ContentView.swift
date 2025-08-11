import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var vm = SimulationViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    colonySection
                    inputsSection
                    buildQueueSection
                    logSection
                }
                .padding()
            }
            .navigationTitle("Planet Lira • Day \(vm.state.currentDayIndex + 1)")
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active: vm.startDevTimer()
            default: vm.stopDevTimer()
            }
        }
        .task { vm.startDevTimer() }
    }

    // MARK: - Sections
    private var colonySection: some View {
        GroupBox("Colony Status") {
            Grid(horizontalSpacing: 12, verticalSpacing: 10) {
                gridRow("Population", value: vm.state.population, asInt: true)
                gridRow("Beds", value: vm.state.housingCapacity, asInt: true)
                gridRow("Food stock (rations)", value: vm.state.foodStockRations)
                gridRow("Greenhouses", value: vm.state.greenhouseCount, asInt: true)
                gridRow("Tech level", value: vm.state.technologyLevel)
                gridRow("Explored radius (km)", value: vm.state.exploredRadiusKm)
                gridRow("Build points", value: vm.state.buildPoints)
                gridRow("Science points", value: vm.state.sciencePoints)
            }
        }
    }

    private var inputsSection: some View {
        GroupBox("Inputs") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Health data: not connected (using ZERO baseline)")
                    .foregroundStyle(.secondary)
                Text("Dev time: one day passes every \(Int(Config.tickInterval)) seconds while the app is open.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var buildQueueSection: some View {
        GroupBox("Build Queue (automatic)") {
            VStack(alignment: .leading, spacing: 10) {
                if vm.state.buildQueue.isEmpty {
                    Text("(queue empty — waiting for new plans)").foregroundStyle(.secondary)
                } else {
                    ForEach(vm.state.buildQueue) { item in
                        HStack {
                            Text(item.kind.rawValue.capitalized)
                            Spacer()
                            Text("cost: \(Int(item.costPoints)) pts").foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                Text("The colony spends Build Points automatically as they accrue.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var logSection: some View {
        GroupBox("Event Log") {
            if vm.state.eventLog.isEmpty {
                Text("No events yet. The Liri are settling in…")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(vm.state.eventLog.reversed().prefix(120), id: \.self) { line in
                        Text(line).font(.callout)
                    }
                }
            }
        }
    }

    // MARK: - Helpers
    private func gridRow(_ label: String, value: Double, asInt: Bool = false) -> some View {
        GridRow {
            Text(label)
            Spacer()
            if asInt { Text("\(Int(floor(value)))") }
            else { Text(String(format: "%.2f", value)) }
        }
    }
}
