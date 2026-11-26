// Author: Claude Opus 5.5 High
// Date: 20-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 everyone, plans/25-Nov-2026-everyone-can-play-plan.md Part C:
//          "Controls on the left", controlsLeftKey, off by default, a toggle in a new Hands section.
//          ShowpieceView reads it once and hands it down as the shootSide environment value (Shoot, the tip picture and
//          the power bar swap sides on every layout) and, where the table and the notebook or column sit side by side,
//          puts the table on the right.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 gamecenter, plans/25-Nov-2026-everyone-can-play-plan.md Part E
//          item 2: "Hide the board", hideBoardKey and boardHidden, off by default. With it on the game never signs in to
//          Game Center and no Board button is drawn (GameCenter and BoardButton read it); the daily shot, its score and
//          its streak still work. A toggle in a new Board section before Version.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 bullet time, plans/23-Nov-2026-bullet-time-plan.md: "Freeze
//          the big hits", bulletTimeKey and bulletTimeOn, a toggle at the end of the Feel section, which gains a footer.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 model-flow: computerLevelKey, the computer's level the menu and
//          the Tables pages share, stored so it is remembered across launches; read and written by ShowpieceModel.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (two keys the model stores that are not Options toggles:
//          seenOpeningKey, set once the first-launch opening has played through, and freePlayRackKey, the rack free play
//          lays out: fifteen-ball triangle, nine-ball diamond or place balls. Kept here so every stored key lives in one
//          list.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (stroke stream: the straight-stroke drill's two remembered numbers,
//          strokeDrillBestKey and strokeDrillStraightKey, read and written by StrokeDrill.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, item 45 of plans/21-Nov-2026-bugs-after-0-6-6-plan.md: "Shoot
//          with the button only", buttonOnlyKey, off by default. When on, a finger's pull still sets the power and its
//          stroke is still measured, but a push through the cue ball never plays the shot; only Shoot (or Break) does.
//          For a player whose hand may slip forward. The touch stroke (StrokeGesture) reads shootWithButtonOnly at the
//          moment of the push. A touch-screen option, so it shows on iPhone and iPad only.)
// PURPOSE: The player's options, stored on the device: sound, vibration, shot explanations (the caption card in the
//          Physics Lens), the aim guide (ghost ball and where the balls head after contact), and whether the
//          explanation card shows its maths. One key per option, read by the views with @AppStorage and by the sound
//          and haptics players at the moment they play, so a change in Options applies at once. Also the Options sheet
//          itself, opened from the main menu.
// Edited: Claude Opus 5.5 High, 21-November-2026 ("Show the Lens tips again" beside "Show the aiming tips again": clears
//          the key LensCallouts.swift owns, so the three Lens callouts play once more.)
// SRP/DRY check: Pass - checked ShotPanel (aimHintSeen key, reused here for "show the aiming tips again") and
//          SoundBoard/Haptics (the -muteSound launch switch stays for testing; these options sit on top of it).
import SwiftUI

enum GameSettings {
    static let soundKey = "optionSound"
    static let hapticsKey = "optionHaptics"
    static let explanationsKey = "optionExplanations"
    static let aimGuideKey = "optionAimGuide"
    static let mathsKey = "optionShowMaths"
    /// True once the first-launch opening (break, Lens, hand-over, the player's first break) has been seen; later
    /// launches open on the menu. Read and written by ShowpieceModel.
    static let seenOpeningKey = "seenOpening"
    /// The rack free play lays out (FreePlayRack's raw value). Read and written by ShowpieceModel.
    static let freePlayRackKey = "optionFreePlayRack"
    /// The computer's level for a game against it (ComputerLevel's raw value: easy, medium or hard), shared by the
    /// menu's Play list and the Tables pages. Read and written by ShowpieceModel.computerLevel.
    static let computerLevelKey = "optionComputerLevel"
    /// The straight-stroke drill's best return, metres off the cue line (StrokeDrill).
    static let strokeDrillBestKey = "strokeDrillBest"
    /// How many dead-straight strokes the drill has seen (StrokeDrill).
    static let strokeDrillStraightKey = "strokeDrillStraight"
    /// "Shoot with the button only": the touch stroke sets power but never plays on the push; Shoot plays. Off by
    /// default (docs/v07-contracts.md 3.6). Read by StrokeGesture through shootWithButtonOnly.
    static let buttonOnlyKey = "optionShootWithButtonOnly"
    // 0.7.7 bullet-time: "Freeze the big hits", on by default like every option.
    /// Bullet time (BulletTime): on a rare hit the clock stops for a moment and the camera swings round the two balls.
    /// Read when a shot is struck and every frame, so switching it off ends a freeze at once.
    static let bulletTimeKey = "optionBulletTime"
    // 0.7.10 gamecenter: "Hide the board", for a classroom or anyone who wants no sign-in at all.
    /// With it on the game never signs in to Game Center and draws no Board button (GameCenter.boardAllowed,
    /// BoardButton). Off by default, so it is read with bool(forKey:), never through flag(), which reads a missing key
    /// as on and would hide the board on every fresh install.
    static let hideBoardKey = "optionHideBoard"
    // 0.7.10 everyone: "Controls on the left", for playing with the left hand.
    /// With it on, Shoot, the tip picture and the power bar sit on the left of every layout, and where the table and
    /// the notebook (or the side column) share the screen side by side, the table is on the right. Read once, by
    /// ShowpieceView (@AppStorage), which hands it down as the shootSide environment value. Off by default.
    static let controlsLeftKey = "optionControlsOnLeft"

    /// Options default to on; reading a missing key as "on" keeps a fresh install fully featured.
    private static func flag(_ key: String) -> Bool { UserDefaults.standard.object(forKey: key) as? Bool ?? true }
    static var soundOn: Bool { flag(soundKey) }
    static var hapticsOn: Bool { flag(hapticsKey) }
    // 0.7.7 bullet-time
    static var bulletTimeOn: Bool { flag(bulletTimeKey) }
    /// The one option that defaults to off: the push through the ball is the game's own way to shoot, and a fresh
    /// install plays it. Read at the moment of the push, so a change in Options applies to the next stroke.
    static var shootWithButtonOnly: Bool { UserDefaults.standard.bool(forKey: buttonOnlyKey) }
    // 0.7.10 gamecenter: off by default, like the button-only option.
    static var boardHidden: Bool { UserDefaults.standard.bool(forKey: hideBoardKey) }
}

struct OptionsSheet: View {
    @Binding var isOpen: Bool
    @AppStorage(GameSettings.soundKey) private var sound = true
    @AppStorage(GameSettings.hapticsKey) private var haptics = true
    @AppStorage(GameSettings.explanationsKey) private var explanations = true
    @AppStorage(GameSettings.aimGuideKey) private var aimGuide = true
    @AppStorage(GameSettings.mathsKey) private var maths = false
    @AppStorage("aimHintSeen") private var hintSeen = false
    @AppStorage(LensCallouts.seenKey) private var lensTipsSeen = false
    @AppStorage(GameSettings.buttonOnlyKey) private var buttonOnly = false
    // 0.7.7 bullet-time
    @AppStorage(GameSettings.bulletTimeKey) private var bulletTime = true
    // 0.7.10 gamecenter
    @AppStorage(GameSettings.hideBoardKey) private var hideBoard = false
    // 0.7.10 everyone
    @AppStorage(GameSettings.controlsLeftKey) private var controlsLeft = false

    private var version: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? ""
        let b = info?["CFBundleVersion"] as? String ?? ""
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            Form {
                // 0.7.7 bullet-time: written with a header and footer (the Physics Lens section's form) so the new
                // toggle can say what it does; the header's words are the same "Feel" key as before.
                Section {
                    Toggle("Sound", systemImage: "speaker.wave.2", isOn: $sound)
                    #if os(iOS)
                    Toggle("Vibration", systemImage: "iphone.radiowaves.left.and.right", isOn: $haptics)
                    #endif
                    // After the iOS-only block, so the Mac has it too.
                    Toggle("Freeze the big hits", systemImage: "pause.circle", isOn: $bulletTime)
                } header: {
                    Text("Feel")
                } footer: {
                    Text("On a rare hit, time stops for a moment and the camera swings round the two balls to show the push between them.")
                }
                Section {
                    Toggle("Shot explanations", systemImage: "text.bubble", isOn: $explanations)
                    Toggle("Show the maths", systemImage: "function", isOn: $maths)
                        .disabled(!explanations)
                } header: {
                    Text("Physics Lens")
                } footer: {
                    Text("Explanations say what happened at each moment of the shot. The maths adds the equation behind it.")
                }
                Section {
                    Toggle("Aim guide", systemImage: "scope", isOn: $aimGuide)
                    Button("Show the aiming tips again", systemImage: "questionmark.circle") { hintSeen = false }
                        .disabled(!hintSeen)
                    Button("Show the Lens tips again", systemImage: "scribble.variable") { lensTipsSeen = false }
                        .disabled(!lensTipsSeen)
                } header: {
                    Text("Aiming")
                } footer: {
                    Text("The guide shows the first ball you will hit and where both balls head next. Turn it off to judge the angle yourself.")
                }
                #if os(iOS)
                // Touch only: a pointer, the keys and a controller never shoot on a push.
                Section {
                    Toggle("Shoot with the button only", systemImage: "hand.tap", isOn: $buttonOnly)
                } header: {
                    Text("Stroke")
                } footer: {
                    Text("Pulling back from the white ball still sets the power and measures your stroke, but pushing through it no longer plays the shot. Only the Shoot or Break button does.")
                }
                #endif
                // 0.7.10 everyone: on every platform (the Mac's notebook swaps sides too).
                Section {
                    Toggle("Controls on the left", systemImage: "hand.raised", isOn: $controlsLeft)
                } header: {
                    Text("Hands")
                } footer: {
                    Text("Puts Shoot, the tip picture and the power bar on the left. Where the table shares the screen side by side, the table moves to the right.")
                }
                // 0.7.10 gamecenter: on every platform, the Mac's Settings window included.
                Section {
                    Toggle("Hide the board", systemImage: "eye.slash", isOn: $hideBoard)
                } header: {
                    Text("Board")
                } footer: {
                    Text("With this on, the game never signs in for the board and shows no Board button. Today's shot, its score and your streak still work.")
                }
                Section {
                    LabeledContent("Version", value: version)
                }
            }
            .navigationTitle("Options")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { isOpen = false } }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 460)
        #endif
    }
}
