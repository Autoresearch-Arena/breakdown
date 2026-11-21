// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Sonnet 5.5 Medium, 21-November-2026. The opening cue is now one of three approved takes picked at random
//          each launch: the original plus two jazz-funk Lyria clips with pool breaks (the Boss approved them).
// Edited: Claude Opus 5.5 High, 21-November-2026 (sound plan package 4: stop takes a fade length, so SoundBoard can send
//          the music out fast at the first table sound and it never overlaps a shot; duck() dips it briefly under a
//          match moment and brings it back.)
// PURPOSE: The opening music. Plays one of three approved mixes at random (the "Pool Table Take" in App/Audio/PoolTableTake.mp3,
//          an unchanged copy of docs/audio/pool-table-take.mp3, or the two jazz-funk takes beside it) once per launch while the main menu is up, recorded rack break first and
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

    /// The approved takes bundled in App/Audio; one is chosen at random for each launch.
    private let takes = ["PoolTableTake", "TitleFunkElectricPiano", "TitleFunkWahOrgan"]

    /// Start the cue, if it has not played yet this launch and Sound is on. Tests launch with -muteSound and stay silent.
    func start() {
        guard !played, GameSettings.soundOn, !ProcessInfo.processInfo.arguments.contains("-muteSound"),
              let url = takes.shuffled().lazy.compactMap({ Bundle.main.url(forResource: $0, withExtension: "mp3") }).first,
              let p = try? AVAudioPlayer(contentsOf: url) else { return }
        played = true
        #if os(iOS)
        // The same polite category SoundBoard uses: the player's own music keeps playing and the mute switch is obeyed.
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        p.numberOfLoops = 0
        p.volume = level
        p.play()
        player = p
    }

    /// The music's playing level (it starts here and comes back here after a duck).
    private let level: Float = 0.8
    /// The level it dips to under a match moment: low enough that the moment's voice stands clear of it.
    private let duckedLevel: Float = 0.25
    /// Bumped by every duck, so only the latest one brings the level back.
    private var duckCount = 0

    /// Fade the cue out and let it go: live play is starting, or Sound was switched off (the usual slow fade), or a
    /// table sound is about to play (SoundBoard passes a short fade so music and shot never overlap).
    func stop(fadeSeconds: TimeInterval? = nil) {
        guard let p = player else { return }
        player = nil
        let out = fadeSeconds ?? fade
        p.setVolume(0, fadeDuration: out)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(out))
            p.stop()
        }
    }

    /// Dip the music quickly under a short sound (a match moment), then bring it back over half a second once a
    /// second and a half has passed with no further dip. Nothing to do when no music is playing.
    func duck() {
        guard let p = player else { return }
        duckCount += 1
        let mine = duckCount
        p.setVolume(duckedLevel, fadeDuration: 0.12)
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            guard let self, self.duckCount == mine, self.player === p else { return }
            p.setVolume(self.level, fadeDuration: 0.6)
        }
    }
}
