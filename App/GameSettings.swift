// Author: Claude Opus 5.5 High
// Date: 20-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 7, "The front door and the sheets": Options is
//          the kit's SheetPage on the ground (serif title, cyan Done top right) in four panel groups, Feel, Physics
//          Lens, Aiming and hands (the old Aiming, Stroke and Hands sections) and Board, with cyan switches, each
//          section's explanation as a caption under its switch, one "Show all tips again" row in place of the two tip
//          buttons (it clears both keys), and the version in caption at the foot. The switches are switches on the Mac
//          too (its default outside a form is a checkbox). No system grouped grey or blue.)
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
    @Environment(\.palette) private var palette
    /// True when shown as a page of the notebook rather than a sheet (NotebookPanel sets it).
    @Environment(\.inlinePages) private var inlinePages

    private var version: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? ""
        let b = info?["CFBundleVersion"] as? String ?? ""
        return "\(v) (\(b))"
    }

    /// UI rethink package 7: the kit's sheet page in four groups (Feel, Physics Lens, Aiming and hands, Board), the
    /// switches in the cyan tint, one "Show all tips again" row, and the version in caption at the foot. Each group's
    /// explanation is now a caption under the switch it explains (a sheet group has no footer), so no words are lost.
    var body: some View {
        SheetPage(title: String(localized: "Options"), onDone: { isOpen = false }) {
            SheetGroup(String(localized: "Feel")) {
                OptionSwitch("Sound", systemImage: "speaker.wave.2", isOn: $sound)
                #if os(iOS)
                OptionSwitch("Vibration", systemImage: "iphone.radiowaves.left.and.right", isOn: $haptics)
                #endif
                // After the iOS-only row, so the Mac has it too.
                OptionSwitch("Freeze the big hits", systemImage: "pause.circle", isOn: $bulletTime,
                             note: "On a rare hit, time stops for a moment and the camera swings round the two balls to show the push between them.")
            }
            SheetGroup(String(localized: "Physics Lens")) {
                OptionSwitch("Shot explanations", systemImage: "text.bubble", isOn: $explanations)
                OptionSwitch("Show the maths", systemImage: "function", isOn: $maths,
                             note: "Explanations say what happened at each moment of the shot. The maths adds the equation behind it.")
                    .disabled(!explanations)
            }
            SheetGroup(String(localized: "Options group: aiming and hands", defaultValue: "Aiming and hands",
                              comment: "Options group heading over the aim guide, shooting with the button only, controls on the left and showing the tips again.")) {
                OptionSwitch("Aim guide", systemImage: "scope", isOn: $aimGuide,
                             note: "The guide shows the first ball you will hit and where both balls head next. Turn it off to judge the angle yourself.")
                #if os(iOS)
                // Touch only: a pointer, the keys and a controller never shoot on a push.
                OptionSwitch("Shoot with the button only", systemImage: "hand.tap", isOn: $buttonOnly,
                             note: "Pulling back from the white ball still sets the power and measures your stroke, but pushing through it no longer plays the shot. Only the Shoot or Break button does.")
                #endif
                // 0.7.10 everyone: on every platform (the Mac's notebook swaps sides too).
                OptionSwitch("Controls on the left", systemImage: "hand.raised", isOn: $controlsLeft,
                             note: "Puts Shoot, the tip picture and the power bar on the left. Where the table shares the screen side by side, the table moves to the right.")
                // One row for every tip: the aiming tips (ShotPanel's aimHintSeen) and the three Lens callouts
                // (LensCallouts.seenKey) play again. Quiet, cyan, and dimmed once nothing is left to show again.
                QuietButton(String(localized: "Options: show all tips again", defaultValue: "Show all tips again",
                                   comment: "Options row that shows the aiming tips and the Physics Lens tips again."),
                            systemImage: "questionmark.circle", isEnabled: hintSeen || lensTipsSeen) {
                    hintSeen = false
                    lensTipsSeen = false
                }
            }
            // 0.7.10 gamecenter: on every platform, the Mac's Settings window included.
            SheetGroup(String(localized: "Board")) {
                OptionSwitch("Hide the board", systemImage: "eye.slash", isOn: $hideBoard,
                             note: "With this on, the game never signs in for the board and shows no Board button. Today's shot, its score and your streak still work.")
            }
        } footer: {
            Text(String(localized: "Options: version line", defaultValue: "Version \(version)",
                        comment: "The last line of Options: the game's version and build, e.g. Version 0.8.2 (41)."))
        }
        #if os(macOS)
        // A sheet's or the Settings window's minimum size only: as a notebook page it takes the panel's size.
        .frame(minWidth: inlinePages ? nil : 420, minHeight: inlinePages ? nil : 460)
        #endif
    }
}

/// UI rethink package 7: one switch in Options: its outline icon in paper2, its name, the cyan switch, and, where the
/// option needs it, one caption under it saying what it does. The words are the existing catalog keys.
private struct OptionSwitch: View {
    let title: LocalizedStringKey
    let systemImage: String
    @Binding var isOn: Bool
    var note: LocalizedStringKey? = nil
    @Environment(\.palette) private var palette
    @Environment(\.isEnabled) private var isEnabled
    private var device = KitDeviceReader()

    init(_ title: LocalizedStringKey, systemImage: String, isOn: Binding<Bool>, note: LocalizedStringKey? = nil) {
        self.title = title
        self.systemImage = systemImage
        self._isOn = isOn
        self.note = note
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xxs) {
            Toggle(isOn: $isOn) {
                Label {
                    Text(title)
                        .font(device.current == .phone ? Theme.bodyCompact : Theme.body)
                        .foregroundStyle(isEnabled ? palette.paper : palette.paper3)
                } icon: {
                    Image(systemName: systemImage)
                        .fontWeight(.medium)
                        .foregroundStyle(palette.paper2)
                }
            }
            // A switch on the Mac too (its default outside a form is a checkbox), in the cyan of "you can act here".
            .toggleStyle(.switch)
            .tint(palette.accent)
            .frame(minHeight: Theme.Size.minHit)
            if let note {
                Text(note)
                    .font(Theme.caption)
                    .foregroundStyle(palette.paper2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
