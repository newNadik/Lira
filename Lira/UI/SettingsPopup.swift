import SwiftUI

extension Notification.Name {
    static let bgmMuteChanged = Notification.Name("bgm.muteChanged")
    static let gameResetRequested = Notification.Name("game.resetRequested")
}

struct SettingsPopup: View {
    @State var isMuted: Bool
    let appVersion: String
    let buildNumber: String
    let healthAuthorized: Bool
    var onToggleMute: (Bool) -> Void
    var onConnectHealth: () -> Void
    var onDisconnectHealth: () -> Void
    var onClose: () -> Void
    @State private var showAbout: Bool = false
    @State private var showResetConfirm: Bool = false

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                // Header
                HStack {
                    HStack(spacing: 6) {
                        Image("settings_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("Settings")
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
                    .accessibilityLabel("Close settings")
                }

                // Mute toggle
                HStack {
                    Text("Music")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color("brown"))
                    Spacer()
                    Button {
                        let newVal = !isMuted
                        isMuted = newVal
                        onToggleMute(newVal)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isMuted ? "square" : "checkmark.square.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(Color("brown"))
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 6)

                // HealthKit access
                HStack(alignment: .center) {
                    Text("HealthKit")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color("brown"))
                    Spacer()
                    Button(action: {
                        if healthAuthorized { onDisconnectHealth() } else { onConnectHealth() }
                    }) {
                        Text(healthAuthorized ? "Disconnect" : "Connect")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(SoftPillButtonStyle())
                }
                .padding(.vertical, 6)
                
                Spacer()

                // Reset
                Button(action: { showResetConfirm = true }) {
                    Text("Reset settlement")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(SoftPillButtonStyle())
                .accessibilityLabel("Reset settlement data")
                .padding(.vertical, 6)
                .alert("Reset settlement?", isPresented: $showResetConfirm) {
                    Button("Cancel", role: .cancel) {}
                    Button("Reset", role: .destructive) {
                        NotificationCenter.default.post(name: .gameResetRequested, object: nil)
                    }
                } message: {
                    Text("This will clear your current progress and start a new settlement.")
                }

                // Simple footer with Version/Build
                Text("Version \(appVersion) (Build \(buildNumber))")
                    .font(.caption)
                    .foregroundColor(Color("brown").opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(14)
            .frame(maxWidth: 480, maxHeight: 480)
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
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundColor(Color("brown"))
        }
        .padding(.vertical, 6)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color("brown").opacity(0.2)), alignment: .bottom)
    }
}
