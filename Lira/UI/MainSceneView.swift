import SwiftUI
import SpriteKit

struct MainSceneView: View {
    
    @StateObject private var vm = SimulationViewModel()
    @StateObject private var hk = HealthKitManager()
    @State private var showStats = false
    @State private var showJournal = false
    @State private var showSettings = false
    
    @State private var scene = ScrollableBackgroundScene(
        size: UIScreen.main.bounds.size,
        imageName: "background"
    )

    var body: some View {

        ZStack(alignment: .top) {
            SpriteView(scene: scene, preferredFramesPerSecond: 60, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()

            VStack(alignment: .trailing) {
                HStack{
                    Text("• Day \(vm.state.currentDayIndex)")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(Color("brown"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9, blendDuration: 0.2)) {
                            showSettings.toggle()
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image("settings_icon")
                            .resizable()
                            .scaledToFit()
                            .padding(5)
                    }
                    .buttonStyle(IconChipButtonStyle())
                    .accessibilityLabel("Open settings")
                }
                .padding(.horizontal, 10)
                
                if (hk.isAnyAuthorized) {
                    HealthHUDView(hk: hk)
                        .padding(.horizontal, 10)
                }
                Spacer()

                VStack(alignment: .trailing, spacing: 10) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9, blendDuration: 0.2)) {
                            showJournal.toggle()
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image("log_icon")
                            .resizable()
                            .scaledToFit()
                            .padding(5)
                    }
                    .buttonStyle(IconChipButtonStyle())
                    .accessibilityLabel("Open journal")

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9, blendDuration: 0.2)) {
                            showStats.toggle()
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image("stats_icon")
                            .resizable()
                            .scaledToFit()
                            .padding(5)
                    }
                    .buttonStyle(IconChipButtonStyle())
                    .accessibilityLabel("Open settlement stats")
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 16)
                .padding(.bottom, 10)
                .padding(.trailing, 10)
            }
            
            if showJournal {
                Color.black.opacity(0.28)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { withAnimation { showJournal = false } }

                JournalPopup(events: vm.state.eventLog, dayIndex: vm.state.currentDayIndex, onClose: { withAnimation { showJournal = false } })
                    .padding(20)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.35, dampingFraction: 0.9), value: showJournal)
            }

            if showSettings {
                Color.black.opacity(0.28)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { withAnimation { showSettings = false } }

                SettingsPopup(
                    isMuted: (UserDefaults.standard.object(forKey: "audio.musicMuted") as? Bool) ?? false,
                    appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
                    buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "",
                    healthAuthorized: hk.isAnyAuthorized,
                    onToggleMute: { newValue in
                        UserDefaults.standard.set(newValue, forKey: "audio.musicMuted")
                        NotificationCenter.default.post(name: .bgmMuteChanged, object: nil, userInfo: ["muted": newValue])
                    },
                    onConnectHealth: {
                        hk.requestAuthorization()
                    },
                    onDisconnectHealth: {
                        hk.disconnect()
                    },
                    onClose: { withAnimation { showSettings = false } }
                )
                .padding(20)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.35, dampingFraction: 0.9), value: showSettings)
            }

            if showStats {
                // Dimmed background
                Color.black.opacity(0.28)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { withAnimation { showStats = false } }

                // Popup card
                SettlementStatsPopup(state: vm.state, onClose: { withAnimation { showStats = false } })
                    .padding(20)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.35, dampingFraction: 0.9), value: showStats)
            }
        }
        .onReceive(hk.$snapshot) { snap in
            vm.metrics = DailyHealthMetrics(
                steps: snap.stepsToday,
                daylightMinutes: snap.daylightMinutesToday,
                exerciseMinutes: snap.exerciseMinutesToday,
                sleepHours: snap.sleepHoursPrevNight
            )
        }
    }
}
