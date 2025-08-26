import SwiftUI
import SpriteKit

struct MainSceneView: View {
    
    @StateObject private var vm = SimulationViewModel()
    @StateObject private var hk = HealthKitManager()
    @State private var showStats = false
    @State private var showJournal = false
    @State private var showSettings = false
    
    @StateObject private var dialogQueue = DialogQueue()
    @State private var showDialog = false
    @State private var welcomeSeen = UserDefaults.standard.bool(forKey: "intro.seen")
    
    @State private var scene = ScrollableBackgroundScene(
        size: UIScreen.main.bounds.size,
        imageName: "background"
    )
    var charHeight = UIDevice.current.userInterfaceIdiom == .pad ? 600.0 : 400.0
    
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
            
            // Shared full-screen dimmer for any popup
            Color.black
                .ignoresSafeArea()
                .opacity((showJournal || showSettings || showStats) ? 0.28 : 0)
                .animation(.easeInOut(duration: 0.2), value: (showJournal || showSettings || showStats))
                .allowsHitTesting(showJournal || showSettings || showStats)
                .onTapGesture {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        if showSettings { showSettings = false }
                        else if showStats { showStats = false }
                        else if showJournal { showJournal = false }
                    }
                }
                .zIndex(10)

            PopupWrapper(isPresented: showJournal, z: 20) {
                JournalPopup(
                    events: vm.state.eventLog,
                    dayIndex: vm.state.currentDayIndex,
                    onClose: { withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { showJournal = false } }
                )
            }

            PopupWrapper(isPresented: showSettings, z: 30) {
                SettingsPopup(
                    isMuted: (UserDefaults.standard.object(forKey: "audio.musicMuted") as? Bool) ?? false,
                    appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
                    buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "",
                    healthAuthorized: hk.isAnyAuthorized,
                    onToggleMute: { newValue in
                        UserDefaults.standard.set(newValue, forKey: "audio.musicMuted")
                        NotificationCenter.default.post(name: .bgmMuteChanged, object: nil, userInfo: ["muted": newValue])
                    },
                    onConnectHealth: { hk.requestAuthorization() },
                    onDisconnectHealth: { hk.disconnect() },
                    onClose: { withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { showSettings = false } }
                )
            }

            PopupWrapper(isPresented: showStats, z: 25) {
                SettlementStatsPopup(
                    state: vm.state,
                    onClose: { withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { showStats = false } }
                )
            }

            // Dialog overlay (on top of all popups)
            if showDialog {
                DialogHost(
                    isPresented: $showDialog,
                    queue: dialogQueue,
                    onDismiss: { /* optional cleanup */ },
                    character: //CharacterSpriteView(imageName: "lir").erased()
                    dialogQueue.characterView!
                )
                .zIndex(40)
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
        .onAppear {
            if !welcomeSeen {
                dialogQueue.characterView = NodeSpriteView(
                    node: LirSpriteNode(),
                    height: charHeight
                ).erased()
                dialogQueue.load(
                    DialogLine.welcomeSequence(
                        onHelp: {
                            hk.requestAuthorization()
                        },
                        onSkip: { /* ... */ },
                        onDone: {
                            UserDefaults.standard.set(true, forKey: "intro.seen")
                        }
                    )
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showDialog = true
                    welcomeSeen = true
                }
            }
            scene.onCharacterTapped = { name in
                switch name {
                case "lir":
                    dialogQueue.characterView = NodeSpriteView(
                        node: LirSpriteNode(),
                        height: charHeight
                    ).erased()
                    dialogQueue.load([DialogLine(text: LirSpriteNode.presentLine(simulationVM: vm))])
                    showDialog = true
                case "beanie":
                    dialogQueue.characterView = NodeSpriteView(
                        node: BeanieSpriteNode(),
                        height: charHeight
                    ).erased()
                    dialogQueue.load([DialogLine(text: BeanieSpriteNode.presentLine(simulationVM: vm))])
                    showDialog = true
                
                case "naya":
                    dialogQueue.characterView = NodeSpriteView(
                        node: NayaSpriteNode(),
                        height: charHeight
                    ).erased()
                    dialogQueue.load([DialogLine(text: NayaSpriteNode.presentLine(simulationVM: vm))])
                    showDialog = true
                case "lune":
                    dialogQueue.characterView = NodeSpriteView(
                        node: LuneSpriteNode(),
                        height: charHeight
                    ).erased()
                    dialogQueue.load([DialogLine(text: LuneSpriteNode.presentLine(simulationVM: vm))])
                    showDialog = true
                default:
                    print("Unknown character tapped: \(name)")
                }
            }
        }
    }
}
