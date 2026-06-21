import AVFoundation
import Foundation

/// Plays a single looping, soft instrumental track as gentle background
/// ambience while the devotee is in the app.
///
/// The feature is fully wired but ships dormant: it only surfaces once a track
/// named `ambient_darshan.m4a` (or `.mp3`) is added to the app bundle. Until
/// then `isAvailable` is false, the Settings toggle is hidden, and no audio
/// session is ever activated. See `Docs/BACKGROUND_MUSIC.md` for how to add the
/// licensed track.
@MainActor
final class AudioManager: ObservableObject {
    static let shared = AudioManager()

    /// Persisted user preference. Toggling it starts or pauses playback.
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
            if isEnabled { play() } else { pause() }
        }
    }

    private var player: AVAudioPlayer?
    private static let enabledKey = "backgroundMusicEnabled"
    private static let trackName = "ambient_darshan"
    private static let trackExtensions = ["m4a", "mp3"]
    private static let targetVolume: Float = 0.55

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
    }

    /// True only when a bundled track exists. Drives whether the music UI shows.
    var isAvailable: Bool { trackURL != nil }

    private var trackURL: URL? {
        for ext in Self.trackExtensions {
            if let url = Bundle.main.url(forResource: Self.trackName, withExtension: ext) {
                return url
            }
        }
        return nil
    }

    /// Starts (or resumes) the loop with a gentle fade-in. No-op unless the
    /// user has enabled music and a track is present.
    func play() {
        guard isEnabled, let url = trackURL else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            // .mixWithOthers keeps us polite: if the devotee is already playing
            // their own bhajan or a podcast, we layer softly instead of stopping it.
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)

            if player == nil {
                let newPlayer = try AVAudioPlayer(contentsOf: url)
                newPlayer.numberOfLoops = -1
                newPlayer.volume = 0
                newPlayer.prepareToPlay()
                player = newPlayer
            }
            player?.play()
            player?.setVolume(Self.targetVolume, fadeDuration: 1.5)
        } catch {
            player = nil
        }
    }

    /// Pauses without forgetting the user's preference (used on backgrounding).
    func pause() {
        player?.pause()
    }

    /// Fully tears down playback and releases the audio session.
    func stop() {
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance()
            .setActive(false, options: .notifyOthersOnDeactivation)
    }
}
