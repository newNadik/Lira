import SwiftUI
import AVFoundation

final class BGMPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleMuteChanged(_:)), name: .bgmMuteChanged, object: nil)
    }
    private var playlist: [URL] = []
    private var currentIndex: Int = 0
    private var player: AVAudioPlayer?
    private var isPrepared = false

    // MARK: Published/UI-facing state
    @Published var isMuted: Bool = false
    @Published var musicVolume: Float = 1.0

    // Persisted keys
    private let musicVolumeKey = "audio.musicVolume"
    private let musicMutedKey  = "audio.musicMuted"
    private let sfxVolumeKey   = "audio.sfxVolume" // for your future SFX player

    // Fade support
    private var fadeTimer: Timer?
    
    // MARK: Public API
    func loadAndPlay(tracks: [String], preferredExtension: String) {
        // Configure audio session (mix with other audio)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true, options: [])

        // Load persisted settings
        let savedMusicVolume = UserDefaults.standard.object(forKey: musicVolumeKey) as? Float
        let savedMuted = UserDefaults.standard.object(forKey: musicMutedKey) as? Bool
        let defaultSFX: Float = (UserDefaults.standard.object(forKey: sfxVolumeKey) as? Float) ?? 1.0
        // Initialize state
        self.musicVolume = savedMusicVolume ?? 1.0
        self.isMuted = savedMuted ?? false
        // Ensure there is at least a default SFX volume saved for future use
        UserDefaults.standard.set(defaultSFX, forKey: sfxVolumeKey)

        // Build URLs
        playlist = tracks.compactMap { name in
            Bundle.main.url(forResource: name, withExtension: preferredExtension)
        }

        // If nothing found, bail silently
        guard !playlist.isEmpty else { return }

        // Shuffle for randomness
        playlist.shuffle()
        currentIndex = 0

        playCurrent()
        // Apply initial volume state to the active player
        if let p = player {
            p.volume = isMuted ? 0.0 : musicVolume
        }
    }
    
    func pause() {
        player?.pause()
    }
    
    func resume() {
        // If there’s already a player, resume it; otherwise start current.
        if let p = player, !p.isPlaying {
            p.play()
        } else if player == nil, !playlist.isEmpty {
            playCurrent()
        }
    }
    
    func skip() {
        advanceIndex()
        playCurrent()
    }
    
    /// Mute/unmute music with optional fade.
    func setMuted(_ muted: Bool, animated: Bool = true, fadeDuration: TimeInterval = 0.5) {
        isMuted = muted
        UserDefaults.standard.set(muted, forKey: musicMutedKey)
        let target: Float = muted ? 0.0 : musicVolume
        if animated { fade(to: target, duration: fadeDuration) } else { player?.volume = target }
        // Broadcast so Settings UI (or others) can sync
        NotificationCenter.default.post(name: .bgmMuteChanged, object: nil, userInfo: ["muted": muted])
    }
    @objc private func handleMuteChanged(_ note: Notification) {
        guard let muted = note.userInfo?["muted"] as? Bool else { return }
        // Avoid redundant work
        if muted != isMuted { setMuted(muted) }
    }

    /// Set music volume (0.0...1.0). If currently muted, the stored value updates but output stays 0 until unmuted.
    func setMusicVolume(_ volume: Float, animated: Bool = true, fadeDuration: TimeInterval = 0.2) {
        let clamped = max(0.0, min(1.0, volume))
        musicVolume = clamped
        UserDefaults.standard.set(clamped, forKey: musicVolumeKey)
        guard !isMuted else { return }
        if animated { fade(to: clamped, duration: fadeDuration) } else { player?.volume = clamped }
    }

    /// Store SFX volume for use by your future SFX player.
    func setSFXVolume(_ volume: Float) {
        let clamped = max(0.0, min(1.0, volume))
        UserDefaults.standard.set(clamped, forKey: sfxVolumeKey)
    }

    /// Read the stored SFX volume (defaults to 1.0 if unset).
    func getSFXVolume() -> Float {
        (UserDefaults.standard.object(forKey: sfxVolumeKey) as? Float) ?? 1.0
    }
    
    // MARK: Core playback
    private func playCurrent() {
        guard playlist.indices.contains(currentIndex) else { return }
        let url = playlist[currentIndex]

        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.delegate = self
            newPlayer.numberOfLoops = 0 // play once; we’ll move to the next track when finished
            newPlayer.prepareToPlay()
            newPlayer.volume = isMuted ? 0.0 : musicVolume
            newPlayer.play()
            player = newPlayer
            isPrepared = true
        } catch {
            // If one track fails, try skipping to the next
            advanceIndex()
            playCurrent()
        }
    }
    
    private func advanceIndex() {
        if playlist.isEmpty { return }
        currentIndex = (currentIndex + 1) % playlist.count
        
        // Re-shuffle when we loop back to keep it fresh
        if currentIndex == 0 {
            playlist.shuffle()
        }
    }
    
    // MARK: AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        advanceIndex()
        playCurrent()
    }
    // MARK: Volume fading
    private func fade(to target: Float, duration: TimeInterval) {
        fadeTimer?.invalidate()
        guard let p = player else { return }
        let start = p.volume
        let delta = target - start
        guard duration > 0, abs(delta) > 0.0001 else { p.volume = target; return }

        let stepInterval: TimeInterval = 1.0 / 30.0 // ~30 FPS
        var elapsed: TimeInterval = 0

        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { [weak self] t in
            guard let self = self, let player = self.player else { t.invalidate(); return }
            elapsed += stepInterval
            if elapsed >= duration {
                player.volume = target
                t.invalidate()
                return
            }
            let progress = Float(elapsed / duration)
            player.volume = start + delta * progress
        }
    }

    deinit {
        fadeTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}
