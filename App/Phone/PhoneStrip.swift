// Author: Claude Opus 5.5 Medium
// Date: 22-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 6, the upright phone's thumb dock: the strip is
//          the dock's two bottom rows. The scrub row is the kit's shot reel at the phone's height with no surface of its
//          own (it sits on the dock's panel); the hand-built rail, speed capsule and play and Replay circles are gone.
//          The button row is the action row: the views (Physics Lens and Ride, as the kit's chips, cyan-edged while on)
//          on the left, then the one secondary (the kit's secondary capsule: Try again while aiming, Skip while the
//          opening plays) and the one primary on the right (the kit's cyan capsule, 50 high): Break or Shoot while the
//          aiming controls are open (it moved here from the aiming panel), otherwise the modes' own action or "Aim"
//          (PhonePrimaryAction). No glass and no glass identity any more: the dock is the house panel. The first minute
//          shows no reel and no views (calm first). The overflow into the title row's menu stays for Ride and Lens.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (the button row's gaps match the fitting sum: at the largest
//          text sizes Lens was squeezed to "Le..." instead of moving into the menu.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (the strip's glass pieces other than the primary action come and go
//          with the materialize transition, plan Part 3 Morph.)
// PURPOSE: The upright phone's playback and action rows, the bottom of the thumb dock (PhoneDock.swift):
//            1. the shot reel (ShotReel, device .phone, no surface: play, the track with its beat and pot ticks, the
//               time in s, the speed pill, Replay), only once a shot exists, outside the first minute, and under the
//               open aiming controls only while one of the player's own shots is on screen;
//            2. the action row: Physics Lens and Ride on the left while the aiming controls are closed, then the
//               secondary and the primary on the right (design language, "Upright iPhone": secondary left, primary
//               right, 50 high). With the aiming controls open the row is the secondary beside a wide Break or Shoot,
//               as mockup-aiming-iphone.png draws it.
//          When the row is too wide (a long language, the accessibility text sizes) Ride, then Lens, move into the
//          title row's menu: the strip measures hidden copies of its pieces and writes the result to `overflow`, which
//          PhoneTitleRow reads. Also writes model.playbackRowTop (the third Lens tip anchors on it), as
//          PlaybackControls does elsewhere. Writes to the model only through setLens, setRide, fireStroke, tryAgain,
//          skipOpening and the primary action's own closure.
// SRP/DRY check: Pass - the reel is the kit's ShotReel, the buttons the kit's PrimaryButtonStyle and
//          SecondaryButtonStyle, the toggles the kit's Chip; Break and Shoot's word is ShotPanel.actionWord and the
//          refusal and hint rules are ShotPanel's and the old aiming panel's, moved here, not copied twice.
import SwiftUI

/// What the strip moved into the title row's menu because its row was too wide. Written by PhoneStrip, read by
/// PhoneTitleRow; ShowpieceView owns the value. `speed` is kept for the title row's menu but no longer set: the reel
/// keeps its speed pill.
struct PhoneStripOverflow: Equatable {
    var ride = false
    var lens = false
    var speed = false
}

struct PhoneStrip: View {
    let model: ShowpieceModel
    @Binding var shotPanelOpen: Bool
    /// A just-struck shot is still rolling: the primary action waits (PhonePrimaryAction.resolve).
    var shotLive = false
    @Binding var overflow: PhoneStripOverflow

    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The one-time gesture hint's seen flag: a shot marks it seen, as the console's Shoot does.
    @AppStorage("aimHintSeen") private var hintSeen = false

    /// Measured natural widths of the pieces (hidden copies, always present, so the choice never depends on itself).
    @State private var rowWidth: CGFloat = 0
    @State private var lensWidth: CGFloat = 0
    @State private var rideWidth: CGFloat = 0
    @State private var actionsWidth: CGFloat = 0

    /// Space between the row's pieces.
    private static let spacing: CGFloat = Theme.Space.xs

    // MARK: When things show

    /// The Lens toggle: from the end of the first minute on (never before the first shot ends), or while it is on.
    static func showsLens(_ model: ShowpieceModel) -> Bool {
        model.openingStage == .none || model.lensOn
    }

    /// The Ride toggle: for a finished-or-playing shot worth riding whose struck ball reaches another ball, during a
    /// trick's or lesson's own replay as before, and always while Ride is on (so it can be switched off). Never in the
    /// first minute.
    static func showsRide(_ model: ShowpieceModel) -> Bool {
        if model.rideOn { return true }
        guard model.openingStage == .none, model.ridePlan.rideable else { return false }
        return model.ridePlan.contactTime != nil || model.trickMode.isActive || model.lessonMode.isActive
    }

    /// The reel: once a recording exists, never in the first minute (calm first: the table, the sentence, the tip, the
    /// swing and Break), and under the open aiming controls only while one of the player's own shots is on screen.
    private var showsReel: Bool {
        model.duration > 0 && model.openingStage == .none && (!shotPanelOpen || model.playerShotOnScreen)
    }

    /// The views show only while the aiming controls are closed: aiming has its own calm row.
    private var showsViews: Bool { !shotPanelOpen }

    // MARK: The actions

    /// One button of the action row: its word, what VoiceOver says it does, whether it can be pressed, and what it does.
    private struct Action {
        let title: String
        var systemImage: String? = nil
        var hint: String? = nil
        var enabled = true
        let action: @MainActor () -> Void
    }

    /// The primary: Break or Shoot while the aiming controls are open (hidden while a match call is due: the call row
    /// is in the aiming controls), else the modes' own action or "Aim".
    private var primary: Action? {
        if shotPanelOpen {
            if let match = model.match, PhoneAimPanel.callDue(match, model: model) { return nil }
            let refusal = model.strokeRefusal
            return Action(title: ShotPanel.actionWord(racked: model.racked),
                          hint: refusal?.sentence ?? (model.racked ? String(localized: "Plays your own break")
                                                                   : String(localized: "Plays your shot")),
                          enabled: refusal == nil && model.personControlsLive) {
                hintSeen = true
                // A break hands the screen to its replay, so the controls close; a shot keeps them open.
                if model.fireStroke() == .breakStruck { shotPanelOpen = false }
            }
        }
        guard let a = PhonePrimaryAction.resolve(model, shotPanelOpen: false, shotLive: shotLive) else { return nil }
        return Action(title: a.title, hint: a.hint, action: a.action)
    }

    /// The one secondary beside the primary: Try again while aiming once a shot of the player's own has played out
    /// (never in the first minute), Skip while the opening plays.
    private var secondary: Action? {
        if shotPanelOpen {
            guard model.canTryAgain, model.openingStage == .none else { return nil }
            return Action(title: String(localized: "Try again"), systemImage: "arrow.uturn.backward",
                          hint: String(localized: "Puts the balls back where your last shot started, with the same aim, power and spin"),
                          enabled: model.personControlsLive) {
                hintSeen = true
                model.tryAgain()
            }
        }
        guard let a = PhonePrimaryAction.secondary(model, shotPanelOpen: shotPanelOpen) else { return nil }
        return Action(title: a.title, hint: a.hint, action: a.action)
    }

    // MARK: Body

    var body: some View {
        let primary = self.primary
        let secondary = self.secondary
        let lens = showsViews && Self.showsLens(model) && !overflow.lens
        let ride = showsViews && Self.showsRide(model) && !overflow.ride
        VStack(spacing: Theme.Space.sm) {
            if showsReel {
                ShotReel(model: model, device: .phone, surface: .none)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(StageSpace.name)) } action: { frame in
                        // The third Lens tip's anchor (0.7.6 coordinator, stream pacing hand-off).
                        let top = frame.height > 0.5 ? Double(frame.minY) : nil
                        if model.playbackRowTop != top { model.playbackRowTop = top }
                    }
                    .onDisappear { model.playbackRowTop = nil }
                    .transition(.opacity)
            }
            if primary != nil || secondary != nil || lens || ride {
                actionRow(primary: primary, secondary: secondary, lens: lens, ride: ride)
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { rowWidth = $0 }
            }
        }
        .background(alignment: .topLeading) { measurers(primary: primary, secondary: secondary) }
        .onChange(of: wanted(hasActions: primary != nil || secondary != nil), initial: true) { _, new in
            if overflow != new { overflow = new }
        }
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: showsReel)
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: primary?.title)
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: secondary?.title)
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: overflow)
        // Lens and Ride first appear after the first shot, not on any of the values above, so they animate in too.
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: Self.showsLens(model))
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: Self.showsRide(model))
    }

    /// Views on the left, the secondary then the primary on the right. While aiming (no views) the primary fills the
    /// room the secondary leaves, as the mockup draws Shoot.
    private func actionRow(primary: Action?, secondary: Action?, lens: Bool, ride: Bool) -> some View {
        HStack(spacing: Self.spacing) {
            if lens || ride {
                HStack(spacing: Self.spacing) {
                    if lens { lensToggle }
                    if ride { rideToggle }
                }
                .transition(.opacity)
            }
            if !(lens || ride) && primary == nil { Spacer(minLength: 0) }
            if lens || ride { Spacer(minLength: 0) }
            if let secondary { secondaryButton(secondary) }
            if let primary { primaryButton(primary, fill: !(lens || ride)) }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Overflow

    /// What has to move into the menu for the row to fit, in the plan's order: Ride, then Lens. Before anything is
    /// measured, nothing moves.
    private func wanted(hasActions: Bool) -> PhoneStripOverflow {
        guard rowWidth > 0, showsViews else { return PhoneStripOverflow() }
        let fixed: CGFloat = hasActions ? actionsWidth : 0
        let lens = Self.showsLens(model) ? lensWidth : 0
        let ride = Self.showsRide(model) ? rideWidth : 0
        var result = PhoneStripOverflow()
        // The views group plus the gap before the actions; the Spacer keeps at least nothing.
        func fits(_ views: CGFloat) -> Bool {
            fixed + (views > 0 ? views + (fixed > 0 ? Self.spacing : 0) : 0) <= rowWidth
        }
        if !fits(lens + (ride > 0 && lens > 0 ? Self.spacing : 0) + ride) {
            result.ride = ride > 0
            if !fits(lens) { result.lens = lens > 0 }
        }
        return result
    }

    /// Hidden copies of the worded pieces at their natural widths. Never drawn, never read aloud, never touched.
    private func measurers(primary: Action?, secondary: Action?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            toggleLabel(lensTitle, on: false).fixedSize()
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { lensWidth = $0 }
            toggleLabel(rideTitle, on: false).fixedSize()
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { rideWidth = $0 }
            HStack(spacing: Self.spacing) {
                if let secondary { secondaryButton(secondary) }
                if let primary { primaryButton(primary, fill: false) }
            }
            .fixedSize()
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { actionsWidth = $0 }
        }
        .hidden()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: The views

    /// The one name: "Physics Lens" (wave 2 note 44: never a bare "Lens").
    private var lensTitle: String { String(localized: "Physics Lens") }
    private var rideTitle: String { String(localized: "Ride") }

    private var lensToggle: some View {
        toggle(lensTitle, spoken: String(localized: "Physics Lens"), isOn: model.lensOn) { model.setLens(!model.lensOn) }
    }

    private var rideToggle: some View {
        toggle(rideTitle, spoken: String(localized: "Ride camera"), isOn: model.rideOn) { model.setRide(!model.rideOn) }
    }

    /// A view toggle: the kit's chip, selected (the cyan edge) while on. The word never changes, so nothing moves.
    private func toggle(_ title: String, spoken: String, isOn: Bool,
                        action: @escaping @MainActor () -> Void) -> some View {
        Button(action: action) { toggleLabel(title, on: isOn) }
            .buttonStyle(.plain)
            .accessibilityLabel(spoken)
            .accessibilityValue(isOn ? String(localized: "On") : String(localized: "Off"))
            .accessibilityAddTraits(isOn ? [.isToggle, .isSelected] : .isToggle)
    }

    private func toggleLabel(_ title: String, on: Bool) -> some View {
        Chip(word: title, selected: on)
            .frame(minHeight: Theme.Size.minHit)
            .contentShape(Rectangle())
    }

    // MARK: The buttons

    private func secondaryButton(_ a: Action) -> some View {
        Button { a.action() } label: { KitButtonLabel(a.title, systemImage: a.systemImage) }
            .buttonStyle(SecondaryButtonStyle())
            .fixedSize()
            .disabled(!a.enabled)
            .accessibilityHint(Text(verbatim: a.hint ?? ""))
    }

    /// The cyan capsule. `fill`: it takes the room the row leaves (aiming, and any row without the views).
    private func primaryButton(_ a: Action, fill: Bool) -> some View {
        Button { a.action() } label: { KitButtonLabel(a.title, systemImage: a.systemImage) }
            .buttonStyle(PrimaryButtonStyle(fullWidth: fill))
            .disabled(!a.enabled)
            .accessibilityHint(Text(verbatim: a.hint ?? ""))
    }
}
