// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (lessons: optional target band and lock. The angles inside a lesson's
//          band (LessonZones.cueAngles) carry a target mark in the menu, and the label shows the mark while the chosen
//          angle is inside it; a locked menu is disabled and marked "Locked for this step". Defaults leave every other
//          caller exactly as before.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (access stream hook, 0.7.0 item 46: the spoken value says whether the angle is inside a
//          lesson's marked angles, and each marked angle in the menu is read as marked.)
// PURPOSE: The cue-angle control, shared. A small glass menu button that shows how far the cue is raised ("Level",
//          "30° up") and offers the angles a player picks from: level for nearly every shot, a little raised for a
//          jump, steep for a massé. It reads and writes the solver's own unit, the SINE of the cue's angle above the
//          table, through a binding, and does the degrees-to-sine conversion itself, so every caller stores the same
//          number the solver is given.
//          Used by the Behind the 8-Ball card while aiming (EightBallViews) and by the shot panel in free play and
//          matches (ShotPanel, when ShowpieceModel.elevationAllowed). Before this file the control lived only inside
//          the 8-ball card; it moved here so free play reuses it instead of growing a second one (rules plan,
//          package 2 step 4).
// SRP/DRY check: Pass - checked EightBallViews (the old private cueAngleMenu and EightBallFormat.cueAngle, both now
//          call this file) and EightBallMode.cueAngle (its snapping getter is left as it is; it reads the same list).
import SwiftUI

struct CueAngleMenu: View {
    /// The sine of the cue's angle above the table, 0 for a level cue: the value the solver reads.
    @Binding var sine: Double
    /// Height of the label: the cards pass their own button height so the row lines up.
    var minHeight: CGFloat = 0
    /// A lesson's target band, degrees: the offered angles inside it are marked. Nil outside a lesson's guided tries.
    var zone: ClosedRange<Int>? = nil
    /// How strongly the band is marked (1 in try 2, faint in try 3): below a half, only the menu items are marked.
    var zoneStrength: Double = 1
    /// True while a lesson has locked the cue angle for this step.
    var locked: Bool = false

    /// The angles offered, in degrees above level. The same steps the Behind the 8-Ball card has always offered (the
    /// list EightBallMode.cueAngles snaps to; written out here so this control does not reach into a puzzle mode):
    /// fine steps up to 30 degrees, where jumps live, then coarser ones for the massé, up to 80 degrees, short of the
    /// 84 degrees (sine 0.995) where the cue rig stops pitching the cue.
    nonisolated static let angles: [Int] = [0, 5, 10, 15, 20, 25, 30, 40, 50, 60, 70, 80]

    /// The offered angle nearest to a sine. Clamped to the rig's limit so a stray value can never ask for asin of more
    /// than one.
    static func nearestAngle(toSine s: Double) -> Int {
        let degrees = asin(min(max(s, 0), 0.995)) * 180 / .pi
        return angles.min { abs(Double($0) - degrees) < abs(Double($1) - degrees) } ?? 0
    }

    /// The sine for an angle in whole degrees; exactly zero for level, so a level cue is never a tiny float.
    nonisolated static func sine(forAngle a: Int) -> Double { a <= 0 ? 0 : sin(Double(a) * .pi / 180) }

    /// The angle as words: "Level", or "30° up". Shared with the "On a real table" card, whose number formatter is not
    /// on the main actor, hence nonisolated (it touches nothing but its argument).
    nonisolated static func words(degrees: Double) -> String {
        degrees < 0.5 ? String(localized: "Level")
            : String(localized: "\(String(format: "%.0f", locale: Locale.current, degrees))° up")
    }

    var body: some View {
        let angle = Self.nearestAngle(toSine: sine)
        Menu {
            Picker(String(localized: "Cue angle"),
                   selection: Binding(get: { Self.nearestAngle(toSine: sine) },
                                      set: { sine = Self.sine(forAngle: $0) })) {
                ForEach(Self.angles, id: \.self) { a in
                    if zone?.contains(a) == true {
                        // "Marked" is said as well as drawn, so the band is heard (access stream hook, item 46).
                        Label(Self.words(degrees: Double(a)), systemImage: "scope")
                            .accessibilityLabel(TableWords.markedAngle(words: Self.words(degrees: Double(a))))
                            .tag(a)
                    } else {
                        Text(Self.words(degrees: Double(a))).tag(a)
                    }
                }
            }
        } label: {
            // In a lesson's band the label wears the band's target mark, so the player sees they have landed in it.
            Label(Self.words(degrees: Double(angle)),
                  systemImage: zone?.contains(angle) == true && zoneStrength >= 0.5 ? "scope" : "angle")
                .font(.headline).lineLimit(1)
                .frame(minHeight: minHeight)
        }
        .buttonStyle(.glass)
        .disabled(locked)
        .lockedForStep(locked)
        .accessibilityLabel(String(localized: "Cue angle"))
        .accessibilityValue(TableWords.cueAngleValue(words: Self.words(degrees: Double(angle)), degrees: angle, band: zone))
        .accessibilityHint(String(localized: "Raise the cue to jump or curve the cue ball"))
    }
}
