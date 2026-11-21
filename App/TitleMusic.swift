// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The opening music. Plays the approved "Pool Table Take" mix (App/Audio/PoolTableTake.mp3, an unchanged copy of
//          docs/audio/pool-table-take.mp3) once per launch while the main menu is up, recorded rack break first and
//          the music after it, as the audio handoff in docs/audio/README.md asks. It only starts when Sound is on, it
//          fades out when the menu closes and live play begins (or when Sound is switched off), and it never loops, so
//          its baked-in shots are never heard over the player's own. The live table sounds stay in SoundBoard.
// SRP/DRY check: Pass - checked SoundBoard (generated, event-driven table sounds on an AVAudioEngine; it sets the
//          shared ambient audio session this player uses) and GameSettings (the Sound option, read here, not copied).
import AVFoundation
import Foundation

@MainActor
final class TitleMusic {
    static let shared = TitleMusic()

    private var player: AVAudioPlayer?
    /// Once per launch: reopening the menu later does not start the cue again.
    private var played = false
    /// Seconds the fade takes when play starts.
    private let fade: TimeInterval = 1.2

    /// Start the cue, if it has not played yet this launch and Sound is on. Tests launch with -muteSound and stay silent.
    func start() {
        guard !played, GameSettings.soundOn, !ProcessInfo.processInfo.arguments.contains("-muteSound"),
              let url = Bundle.main.url(forResource: "PoolTableTake", withExtension: "mp3"),
              let p = try? AVAudioPlayer(contentsOf: url) else { return }
        played = true
        #if os(iOS)
        // The same polite category SoundBoard uses: the player's own music keeps playing and the mute switch is obeyed.
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        p.numberOfLoops = 0
        p.volume = 0.8
        p.play()
        player = p
    }

    /// Fade the cue out and let it go: live play is starting, or Sound was switched off.
    func stop() {
        guard let p = player else { return }
        player = nil
        p.setVolume(0, fadeDuration: fade)
        Task { @MainActor [fade] in
            try? await Task.sleep(for: .seconds(fade))
            p.stop()
        }
    }
}
