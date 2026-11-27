// Author: Claude Opus 5.5 Medium
// Date: 22-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 6, the upright phone's thumb dock: the aiming
//          controls are a section of the dock that grows out of it (PhoneDock.swift), not a glass panel of their own,
//          and the camera frames the table above the dock's measured top, so it reframes as they open. Laid out as
//          mockup-aiming-iphone.png: the three live figures the ball gets (leaves at, top or back spin, side spin) as
//          the kit's figure tiles, then the tip picture beside the kit's swing bar (SwingBar, device .phone, a tap on
//          its figure still opens the strike sheet), then the small worded controls (the cue angle, and Shot options
//          with Put away as its first item). Break and Shoot moved to the dock's action row (PhoneStrip), the primary
//          at the right; Try again is the secondary beside it. In the first minute only the tip picture and the swing
//          bar show (the hint is the dock's word strip, Break the action row). PhonePowerBar is gone (wave 1 note 28: the kit's SwingBar replaces
//          it); the corner and padding are Theme tokens (wave 1 note 37); PhonePanelControl is the sunken strip, since
//          the controls now sit on the panel, not on glass.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2: the swing bar's warm stretch is gold, not the
//          sliding magenta.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.8.1: the hint is left out while the strike sheet is up, which
//          left it cut in half along the sheet's top edge.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 wiring: the strike sheet starts open in the -storeStrike
//          store scene.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 strike, plans/25-Nov-2026-strike-panel-and-controls-plan.md
//          stage 4 and stage 3 item 5: a tap on the swing figure opens the strike panel as a sheet over the lower half
//          (StrikeSheet); the first instruction and the Pencil line sit at the top of the panel (StrikeHint); the cue
//          angle is locked where the mode sets its own.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (aiming panel redesign, plans/26-Nov-2026-aiming-panel-redesign-plan.md
//          step 14: the swing figure is cyan (a set value); the strike sheet it opens is the slimmer opaque one with
//          What the ball gets and the physics line only; the tip picture takes the flat look.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (numbers are written in the game's own language, AppLocale.numbers
//          in NumberStyle.swift: French and German get "6,7" even on a phone set to another region.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 everyone, plans/25-Nov-2026-everyone-can-play-plan.md:
//          with Controls on the left (shootSide .left) the rows run the other way: Shoot, the
//          power bar and the tip picture mirror to the left hand.)
// PURPOSE: The upright phone's aiming controls (plans/22-Nov-2026-phone-ui-plan.md, Part 3 "The aiming panel", redrawn
//          by plans/26-Nov-2026-ui-rethink-plan.md package 6), in place of ShotPanel on that layout only. ShowpieceView's
//          dock shows them between the word strip and the action row while the aiming controls are open (and the
//          what-if's panel in their place while a what-if shows). From the top:
//            - the refusal or computer's-turn line (ShotStatusLine);
//            - the three figures the ball gets, live (FigureTile; not in the first minute nor at the accessibility
//              text sizes, where the strike sheet holds them);
//            - the tip picture (TipPicker) beside the swing bar (SwingBar, the one bar on every device), mirrored for
//              the left hand; the fine controls (FineControls) in their place while open;
//            - the call row (MatchCallRow) while a match shot needs its call, else the cue angle (CueAngleMenu's phone
//              form) and Shot options (Put away, then ShotOptionsItems' phone form), each a worded sunken capsule (not
//              in the first minute: calm first).
//          Reads and writes the model only through the calls ShotPanel uses (activeElevation, the gauges' own calls,
//          the options' calls); Put away sets the isOpen binding.
// SRP/DRY check: Pass - reuses TipPicker (AimGauges.swift), SwingBar and FigureTile (App/Kit), CueAngleMenu (phone
//          form), ShotOptionsItems, FineControls and ShotStatusLine (ShotPanel.swift), MatchCallRow (CallControl.swift),
//          StrikeReading and the StrikeWords and StrikeSpoken labels the console's tiles use, and StrikeSheet
//          (StrikePanel.swift). ShotPanel stays as it was for the notebook, the sideways column and the big window.
import SwiftUI

// MARK: Controls drawn on a panel

/// A control that sits on one of the upright phone's panels (the dock's aiming controls, the what-if's nudge panel, the
/// call row): a sunken capsule or circle behind a plain button's label (design language, "Sunken strip"). Package 6:
/// it was a faint white fill for controls on glass; the dock is the house panel now. With Increase Contrast the rule
/// colour, a step lighter, is the fill.
struct PhonePanelControl: ViewModifier {
    enum Outline { case capsule, circle }
    let shape: Outline
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.palette) private var palette

    private var fill: Color { contrast == .increased ? palette.rule : palette.panelSunken }

    @ViewBuilder
    func body(content: Content) -> some View {
        switch shape {
        case .capsule: content.background(fill, in: .capsule)
        case .circle: content.background(fill, in: .circle)
        }
    }
}

// MARK: The aiming controls

struct PhoneAimPanel: View {
    @Bindable var model: ShowpieceModel
    @Binding var isOpen: Bool

    /// The fine controls open inside the dock in place of the tip and the swing.
    @State private var slidersOpen = false
    /// Bumped by each refusal to bounce the status line's mark once (nothing moves under Reduce Motion).
    @State private var refusalPulse = 0
    /// 0.7.10 strike: the strike panel's sheet, opened by a tap on the swing figure (StrikeSheet).
    // 0.7.10 wiring: open from the start in the strike store scene (-storeStrike), so the upright phone's picture shows
    // the panel's figures as the bigger screens do.
    @State private var strikeOpen = StoreScene.requested == .strike

    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // 0.7.10 everyone: which hand the rows are laid out for ("Controls on the left", handed down by ShowpieceView).
    @Environment(\.shootSide) private var shootSide
    @Environment(\.layoutDirection) private var layoutDirection
    /// The open fine controls' height, scaled with the text: the aim row and about three sliders show, the rest
    /// scroll (ShotPanel's phone height).
    @ScaledMetric(relativeTo: .body) private var fineHeight: CGFloat = 260

    /// Kept for the what-if's and the every-surface fan's phone panels, which take this section's place and still
    /// draw their own surface with it: the design language's card corner and the phone's tile padding.
    static var corner: CGFloat { Theme.Corner.medium }
    static var padding: CGFloat { Theme.Space.sm }

    /// The first minute (the hand-over to the player's own break): only the tip picture and the swing bar show; the
    /// hint is the word strip's and Break the action row's (package 6, "First shot shows only...").
    private var firstMinute: Bool { model.openingStage != .none }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            ShotStatusLine(model: model, pulse: refusalPulse)
            if slidersOpen {
                FineControls(model: model, isOpen: $isOpen, sheetOpen: $slidersOpen)
                    .frame(height: fineHeight)
                    .transition(.opacity)
            } else {
                Group {
                    if !firstMinute && !typeSize.isAccessibilitySize { figures }
                    tipAndSwing
                }
                // The computer's turn: the person's controls stay visible but greyed out and still.
                .disabled(!model.personControlsLive)
                .opacity(model.personControlsLive ? 1 : 0.45)
            }
            if let match = model.match, Self.callDue(match, model: model) {
                MatchCallRow(match: match)
            } else if !firstMinute {
                smallControls
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tint(palette.accent)
        // Each refusal bounces the line once, even the same reason twice in a row (refusalSerial), and is spoken.
        .onChange(of: model.refusalSerial) { _, _ in
            if let reason = model.lastRefusal {
                AccessibilityNotification.Announcement(reason.sentence).post()
                if !reduceMotion { refusalPulse += 1 }
            }
        }
        // Test hook, as ShotPanel's: launch with -aimDemoSheet to open the fine controls straight away.
        .onAppear { if ProcessInfo.processInfo.arguments.contains("-aimDemoSheet") { slidersOpen = true } }
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: slidersOpen)
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: model.personControlsLive)
        // 0.7.10 strike: the strike in real units, over the lower half; the table stays in view and touchable above.
        .sheet(isPresented: $strikeOpen) { StrikeSheet(model: model, isOpen: $strikeOpen) }
    }

    // MARK: What the ball gets

    /// "2.74 m/s leaves at · 8.4 turns/s back spin · 7.6 turns/s right spin": the live figures of the strike set now
    /// (or, while the shot just struck still plays, what it delivered), as the kit's figure tiles in one row. The cut
    /// is in the word strip's sentence above.
    @ViewBuilder private var figures: some View {
        if let reading = StrikeReading.current(model) {
            let f = reading.shown
            FigureTileRow {
                FigureTile(label: StrikeWords.leavesShortLabel, figure: StrikeWords.speedFigure(f.leaves),
                           size: .control, spoken: StrikeSpoken.tile(.leaves, .live(f), differs: false))
                FigureTile(label: StrikeWords.topSpinLabel(f.topSpin), figure: StrikeWords.spinFigure(f.topSpin),
                           size: .control, spoken: StrikeSpoken.tile(.topSpin, .live(f), differs: false))
                FigureTile(label: StrikeWords.sideSpinLabel(f.sideSpin), figure: StrikeWords.spinFigure(f.sideSpin),
                           size: .control, spoken: StrikeSpoken.tile(.sideSpin, .live(f), differs: false))
            }
        }
    }

    // MARK: Tip and swing

    private var open: ShotControls { model.openControls }
    private var zones: LessonZones? { model.lessonZones }

    /// 0.7.10 everyone: true when the row runs in the right hand's order (the tip picture first, the swing toward the
    /// hand), as ShotPanel's shootLast: the physical corner nearest the chosen hand, in either reading direction.
    private var shootLast: Bool { (shootSide == .right) == (layoutDirection == .leftToRight) }

    private var tipAndSwing: some View {
        HStack(alignment: .center, spacing: Theme.Space.md) {
            if shootLast {
                TipPicker(model: model, open: open, zones: zones)
                swing
            } else {
                swing
                TipPicker(model: model, open: open, zones: zones)
            }
        }
    }

    /// The kit's swing bar at the phone's height; a tap on its figure opens the strike sheet (0.7.10 strike).
    private var swing: some View {
        SwingBar(model: model, open: open, zones: zones, device: .phone, onFigureTap: { strikeOpen = true })
            .frame(maxWidth: .infinity)
    }

    // MARK: Put away, cue angle, options (or the call)

    /// The cue angle and Shot options (Put away is its first item), each worded, wrapping to a second line when they
    /// do not fit.
    private var smallControls: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Theme.Space.xs) { smallControlItems }
            VStack(alignment: .leading, spacing: Theme.Space.xs) { smallControlItems }
        }
    }

    @ViewBuilder private var smallControlItems: some View {
        cueAngle
            .disabled(!model.personControlsLive)
            .opacity(model.personControlsLive ? 1 : 0.45)
        shotOptions
    }

    /// A call is due before this shot: a match whose rules use calls, after the break, while aiming, on the person's
    /// turn, with no call made yet. The call row then takes the small controls' place, and the dock's Shoot waits.
    static func callDue(_ match: MatchMode, model: ShowpieceModel) -> Bool {
        match.mustCall && match.currentCall == nil && match.phase == .aiming && match.personMayAct && model.aimReady
    }

    /// "Put away" shows once there is a shot to go back to: never in the first minute, whose controls open by
    /// themselves and have nothing behind them, and only when a recording is loaded for the reel to play.
    private var showsPutAway: Bool { model.openingStage == .none && model.duration > 0 }


    /// The raised cue, where the model allows it (free play and matches) and for a shot rather than the break: "Level"
    /// or its degrees, written through activeElevation, where a lesson's lock applies.
    @ViewBuilder private var cueAngle: some View {
        if model.elevationAllowed && !model.racked {
            CueAngleMenu(sine: Binding(get: { model.activeElevation }, set: { model.activeElevation = $0 }),
                         zone: zones?.cueAngles, zoneStrength: zones?.strength ?? 1,
                         // 0.7.10 strike: locked too where the mode sets its own angle.
                         locked: !open.contains(.elevation) || model.cueAngleLockedByMode, phone: true)
        }
    }

    /// The shot options behind a worded capsule (never a bare icon), Put away first: the aiming controls go back into
    /// the dock (the action row's "Aim" brings them back). The shot's own options wait for the computer's turn to end.
    private var shotOptions: some View {
        Menu {
            if showsPutAway {
                Button { isOpen = false } label: { Label(String(localized: "Put away"), systemImage: "chevron.down") }
                    .accessibilityHint(String(localized: "Puts the aiming controls away"))
            }
            Group {
                ShotOptionsItems(model: model, slidersOpen: $slidersOpen, phone: true)
            }
            .disabled(!model.personControlsLive)
        } label: {
            smallLabel(String(localized: "Shot options"), systemImage: "slider.horizontal.3")
        }
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
    }

    /// A small worded control on the panel: an outline icon and the word on a sunken capsule, 44 high.
    private func smallLabel(_ title: String, systemImage: String) -> some View {
        KitButtonLabel(title, systemImage: systemImage)
            .font(Theme.label)
            .foregroundStyle(palette.paper)
            .padding(.horizontal, Theme.Space.sm)
            .frame(minHeight: Theme.Size.minHit)
            .modifier(PhonePanelControl(shape: .capsule))
            .contentShape(Capsule())
    }
}
