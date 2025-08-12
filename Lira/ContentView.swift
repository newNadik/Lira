import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var vm = SimulationViewModel()
    @StateObject private var hk = HealthKitManager()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    colonySection
                    inputsSection
                    buildQueueSection
                    logSection
                    Button("Reset Simulation") {
                        vm.reset()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
            }
            .navigationTitle("Planet Lira • Day \(vm.state.currentDayIndex + 1)")
        }
        .onReceive(hk.$snapshot) { snap in
            vm.metrics = DailyHealthMetrics(
                steps: snap.stepsToday,
                daylightMinutes: snap.daylightMinutesToday,
                exerciseMinutes: snap.exerciseMinutesToday,
                sleepHours: snap.sleepHoursPrevNight
            )
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
                gridRow("Schools", value: vm.state.schoolCount, asInt: true)
            }
        }
    }

    private var inputsSection: some View {
        GroupBox("Inputs") {
            VStack(alignment: .leading, spacing: 8) {
                if Config.isDevMode {
                    Text("Dev mode: using simulated ZERO inputs")
                        .foregroundStyle(.secondary)
                } else {
                    if #available(iOS 17.0, *) {
                        VStack(alignment: .leading, spacing: 6) {
                            Button("Connect Health") { hk.requestAuthorization() }
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Steps")
                                    Spacer()
                                    Text("\(Int(hk.snapshot.stepsToday))")
                                }
                                HStack {
                                    Text("Exercise")
                                    Spacer()
                                    Text("\(Int(hk.snapshot.exerciseMinutesToday)) min")
                                }
                                HStack {
                                    Text("Daylight")
                                    Spacer()
                                    Text("\(Int(hk.snapshot.daylightMinutesToday)) min")
                                }
                                HStack {
                                    Text("Sleep")
                                    Spacer()
                                    let hours = Int(hk.snapshot.sleepHoursPrevNight)
                                    let minutes = Int((hk.snapshot.sleepHoursPrevNight - Double(hours)) * 60)
                                    Text("\(hours)h \(minutes)m")
                                }
                            }
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Requires iOS 17+ for daylight. Health inputs disabled.")
                            .foregroundStyle(.secondary)
                    }
                }
                Text("One game day equals one real day. Progress accrues while the app is closed.")
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
                            Text(item.displayName.capitalized)
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
                    ForEach(Array(vm.state.eventLog.enumerated().reversed().prefix(120)), id: \.offset) { item in
                        Text(item.element).font(.callout)
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
