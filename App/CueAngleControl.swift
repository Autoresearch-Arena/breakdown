// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (lessons: optional target band and lock. The angles inside a lesson's
//          band (LessonZones.cueAngles) carry a target mark in the menu, and the label shows the mark while the chosen
//          angle is inside it; a locked menu is disabled and marked "Locked for this step". Defaults leave every other
//          caller exactly as before.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (access stream hook, 0.7.0 item 46: the spoken value says whether the angle is inside a
//          lesson's marked angles, and each marked angle in the menu is read as marked.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 learn-modes stream, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          item 8: the Behind the 8-Ball card's menu and EightBallMode's angle list are gone; this header and the
//          angles' comment say so. No change to the control.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream aim, plans/22-Nov-2026-phone-bug-hunt.md #47: when the
//          shot panel's row has no room for the words, the button shows its icon and the bare degrees ("40°",
//          shortWords) instead of cutting the words short; VoiceOver still hears the full words.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (phone UI plan, aiming panel: a `phone` form for the upright phone's
//          aiming panel (PhoneAimPanel): a text capsule showing "Level" or the bare degrees, no icon, drawn as content on
//          the panel's glass (a faint capsule, PhonePanelControl) so there is no glass on glass. The menu, the lesson
//          marks and everything VoiceOver hears are the same as before; the default form is unchanged.)
// PURPOSE: The cue-angle control, shared. A small glass menu button that shows how far the cue is raised ("Level",
//          "30° up") and offers the angles a player picks from: level for nearly every shot, a little raised for a
//          jump, steep for a massé. It reads and writes the solver's own unit, the SINE of the cue's angle above the
//          table, through a binding, and does the degrees-to-sine conversion itself, so every caller stores the same
//          number the solver is given.
//          Used by the shot panel (ShotPanel, whenever ShowpieceModel.elevationAllowed: free play, matches, trick shots,
//          lessons and Behind the 8-Ball). Before the rules plan the control lived only inside the 8-ball card; it moved
//          here so free play reuses it instead of growing a second one (rules plan, package 2 step 4), and since 0.7.5
//          the 8-ball card no longer shows its own copy beside the panel's, so there is one cue-angle control on screen.
//          EightBallFormat.cueAngle still borrows words(degrees:) for the "On a real table" card.
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (numbers are written in the game's own language, AppLocale.numbers
//          in NumberStyle.swift: French and German get "6,7" even on a phone set to another region.)
// SRP/DRY check: Pass - checked EightBallViews (EightBallFormat.cueAngle calls words(degrees:) here; the card's own
//          menu is gone) and EightBallMode (its copy of the angle list and its snapping getter are gone). The package
//          keeps its own copy of the angles (BreakProbe offeredCueAngles, AuthoredLibraryTests), since it cannot import
//          app files; the tests hold them equal to this list in effect (every authored raised cue is one of them).
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
    /// The upright phone's aiming panel: a plain text capsule ("Level", "30°") drawn on the panel's glass instead of a
    /// glass button with an icon (plans/22-Nov-2026-phone-ui-plan.md, "The aiming panel": the cue angle shows degrees).
    var phone: Bool = false

    /// The angles offered, in degrees above level: the one list in the app (the Behind the 8-Ball card's copy went in
    /// 0.7.5). Fine steps up to 30 degrees, where jumps live, then coarser ones for the massé, up to 80 degrees, short
    /// of the 84 degrees (sine 0.995) where the cue rig stops pitching the cue. Every authored raised cue (lessons and
    /// trick shots) is one of these, exactly as sine(forAngle:) writes it, so the player can always set the answer.
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
            : String(localized: "\(String(format: "%.0f", locale: AppLocale.numbers, degrees))° up")
    }

    /// The angle in its shortest form for a crowded row (0.7.6 #47): the degrees alone, "40°", "0°" for level, in the
    /// player's number style. Through the catalog's existing "%@°" entry, so a language that writes the degree sign
    /// differently can say so.
    static func shortWords(degrees: Int) -> String {
        String(localized: "\(degrees.formatted(.number.locale(AppLocale.numbers)))°")
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
            if phone {
                phoneLabel(angle)
            } else {
                // In a lesson's band the label wears the band's target mark, so the player sees they have landed in it.
                let icon = zone?.contains(angle) == true && zoneStrength >= 0.5 ? "scope" : "angle"
                // The words when the row has room; else the icon and the bare degrees ("40°"), so a long translation of
                // "40° up" is never cut to "40° vers le h…" beside Shoot (0.7.6 #47). VoiceOver hears the full words
                // either way (the value below).
                ViewThatFits(in: .horizontal) {
                    Label(Self.words(degrees: Double(angle)), systemImage: icon)
                    Label(Self.shortWords(degrees: angle), systemImage: icon)
                }
                .font(.headline).lineLimit(1)
                .frame(minHeight: minHeight)
            }
        }
        .modifier(CueAngleMenuStyle(phone: phone))
        .disabled(locked)
        .lockedForStep(locked)
        .accessibilityLabel(String(localized: "Cue angle"))
        .accessibilityValue(TableWords.cueAngleValue(words: Self.words(degrees: Double(angle)), degrees: angle, band: zone))
        .accessibilityHint(String(localized: "Raise the cue to jump or curve the cue ball"))
    }

    /// The phone form's label: "Level", or the bare degrees ("30°"), in the panel's control font, on a faint capsule
    /// 44 high. Inside a lesson's band a small target mark follows the words, as the default form's icon does.
    private func phoneLabel(_ angle: Int) -> some View {
        HStack(spacing: 4) {
            Text(verbatim: angle == 0 ? Self.words(degrees: 0) : Self.shortWords(degrees: angle))
                .font(Theme.phoneControl.monospacedDigit())
                .lineLimit(1)
            if zone?.contains(angle) == true && zoneStrength >= 0.5 {
                Image(systemName: "scope").font(.caption).accessibilityHidden(true)
            }
        }
        .fixedSize()
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
        .modifier(PhonePanelControl(shape: .capsule))
        .contentShape(Capsule())
    }
}

/// The default form is a glass menu button; the phone form is a plain one, its capsule drawn by phoneLabel, because it
/// sits on the aiming panel's own glass.
private struct CueAngleMenuStyle: ViewModifier {
    let phone: Bool
    @ViewBuilder
    func body(content: Content) -> some View {
        if phone {
            content.buttonStyle(.plain).menuIndicator(.hidden)
        } else {
            content.buttonStyle(.glass)
        }
    }
}
