// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 4 follow-up: in the side column the tip picture
//          tops out at 128 points and the cue angle's dial at six tenths of it, so Shoot shows in a 900-point window.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 4, the shot console,
//          plans/26-Nov-2026-ui-rethink-plan.md: on iPad, Mac and the open folding phone the panel is the console's
//          controls: "WHAT YOU SET", the controls in a row (Tip, Cue angle, Swing, Bridge), and the action column: Shoot
//          as a tall cyan capsule (the kit's primary) with Try again under it, a secondary capsule the same width, and
//          the worded More. In the narrow side column (the iPad sideways, the Mac, the fold) the same controls stack
//          (tip picture with its figures beside it and the cue-angle dial, the swing bar, the bridge and More) and
//          Try again and Shoot share the last row, as the iPad mockup draws them; at the accessibility sizes one control
//          a row. The first minute (the hand-over) is the calm console: the sentence, the tip picture, the swing in m/s
//          and Break, nothing else. Inside the notebook's console card (`framed` false) it draws no surface of its own;
//          elsewhere the kit's panel. The small layouts (the phone sideways, small windows) keep their rows with the
//          kit's buttons: Shoot the primary, Try again secondary, a worded More, the cue-angle menu a secondary capsule,
//          the swing the kit's SwingBar. ShootFace, the band metrics and the bare sizes are gone.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2: one meaning per colour. Fouls, misses and
//          refusals take Palette.warning; headings, try counts, tags and difficulty take paper or paper2; the sliding
//          magenta is left for sliding and friction.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 1: onChromeHeight reports the status and hint
//          lines' measured height, so the notebook keeps their real room and the band no longer rides over the strike.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.8.1 upright iPad: BandMetrics.wide takes the dial column's real
//          overhead (it was undercounted, so the band always fell back to its scroll view, cut off), puts the swing
//          label inline when the band is short, and keeps Shoot's column wide enough for Try again's words.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 strike, plans/25-Nov-2026-strike-panel-and-controls-plan.md
//          stage 3: on iPad, Mac and the open folding phone the panel lays out large (roomyRow, roomyStacked): the
//          132-point tip picture, the tall power bar without minus and plus, the cue-angle dial (CueAngleDial) and Shoot
//          as the largest control in the bottom corner on the hand side (the shootSide environment value). The hint is
//          StrikeHint (one hint, in one place, with the Pencil line). Fine controls leave the More menu on those screens
//          except for VoiceOver. The cue-angle menu and slider are locked where the mode sets its own angle.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 make it again, plans/23-Nov-2026-make-it-again-plan.md S1:
//          Shot options offers Make it again / Play it now after Undo last shot (MakeItAgainMenuItem).)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 coordinator: Try again falls back to its arrow alone when the
//          row has no room, instead of being cut short).
// Edited: Claude Haiku 5.5 High, 20-November-2026 (player-facing words wrapped for translation: String(localized:) so they reach the string catalog, and numbers formatted for the player's language).
// Edited: Claude Opus 5.5 High, 20-November-2026 (a Try again button beside Shoot once a shot of yours has played out:
//          the balls go back where it started with the same settings, and the last try stays on the table as a ghost).
// PURPOSE: The player's panel, now small enough to leave the table alone. The aiming itself happens on the table
//          (AimOverlay: drag to swing the line, pull back from the cue ball to set power). This panel is only what has
//          to sit beside it: a picture of the cue ball to touch for tip placement (TipPicker), the power gauge
//          (PowerGauge), the Break or Shoot button, and a More menu (fine controls, aim at the nearest ball, re-rack,
//          show the hint again). One row on a phone and in a wide column, two rows when space or text size demands it.
//          The first time it opens it also shows a short hint that explains the gestures; the hint is dismissed with
//          its own button, or by the first pull or shot, and never comes back unless asked for (stored as aimHintSeen).
//          The sliders did not go away: "Fine controls" opens them in a sheet, labelled and with spoken values, so
//          VoiceOver, keyboard and switch users have a complete route that does not need the picture of the table.
//          Break and Shoot call the same model methods as before.
// Edited: Claude Sonnet 5.5 Medium, 21-November-2026 (iPhone Duo: the fine controls open inside the side panel instead of
//          in a sheet, so nothing covers the table.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (the power slider's readout says the power in a word beside the number,
//          from PowerWords.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (free play finished, rules plan package 2: the cue-angle control
//          (CueAngleMenu, the one the Behind the 8-Ball card uses) sits in the panel wherever the model opens the
//          raised cue (free play and matches), with a matching slider in the fine controls; the More menu gains Move
//          cue ball, Undo last shot and the rack choice in free play; Shoot waits while the cue ball is lifted, while a
//          shot is being solved, and in a match until the call is made; the tip sliders use the model's own tip
//          travel (model.tipLimit) instead of the old fixed value.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (the gesture hint no longer caps the text size; it scrolls inside its
//          own height at the largest sizes instead.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (lessons: the panel hands the model's open controls and the lesson's
//          target bands (ShotControls, LessonZones) to the tip picture, the power gauge and the cue-angle menu; a
//          locked control is dimmed with a lock mark and VoiceOver hears "Locked for this step"; Aim at nearest ball
//          and the fine-control sliders respect the same locks; the free-play items stay out of a lesson.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (stroke stream: the fine-controls power slider reads the ball's speed,
//          "firm · ball 3.4 m/s" (StrokeWords.ballReadout), beside the power bar's swing, so the number is on hand.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (reach: the equipment card (EquipmentCard, App/Stroke/StanceViews.swift)
//          sits at the top of the panel, beside the tip and power controls, when the stance is not a square one; in the
//          notebook it is one of the notebook's cards instead, so it is never shown twice. The fine controls read the
//          bridge's length (BridgeReadout) under the power slider.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, plans/21-Nov-2026-bugs-after-0-6-6-plan.md items 1, 2, 5, 12,
//          13 and 16: the one-time hint is the first instruction for the input in use (FirstInstruction) and stays
//          hidden during the hand-over, so one line teaches; Break and Shoot go through the model's fireStroke and are
//          disabled with the reason while a stroke would be refused (strokeRefusal); a refused stroke's reason shows
//          on the panel as one line, pulsing each time (lastRefusal, refusalSerial); on the computer's turn the
//          person's controls are greyed out with a line saying whose turn it is (personControlsLive); the cue-angle
//          control writes through activeElevation, where a lesson's lock applies; the fine controls gain a bridge
//          slider beside the bridge readout.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 learn-modes stream, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          item 4: the fine controls' Cue tip and Side readouts show the signed millimetres beside the word
//          (tipReadout: "follow, +8.5 mm"), so the judge's millimetre advice can be followed; the readout column is wider
//          to hold them. tipWord and sideWord are unchanged. Review fix: a value a hair below zero no longer reads
//          "-0.0 mm".)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream aim, plans/22-Nov-2026-phone-bug-hunt.md #44, #47, #48,
//          #49, #61: the equipment card keeps its room while the panel is open, so the table no longer slides as the
//          stance row comes and goes with the aim; when the button row has no room the panel falls back to a layout
//          with Shoot alone on a full-width row (at every text size, not only the accessibility sizes), and the
//          cue-angle button shortens itself to its icon and degrees; on a phone the fine controls open inside the
//          panel in place of the tip picture and power bar, as on the folding phone, so no sheet covers the table;
//          each slider's name and readout sit on one line beside it where they fit and above it where they do not; the
//          aim and break-aim readouts follow the player's number style.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (phone UI plan, aiming panel step: the More menu's items moved into
//          ShotOptionsItems, which the upright phone's "Shot options" menu (PhoneAimPanel) also uses, with Try again,
//          Change the call and the phone's clearer Undo and Re-rack symbols in its form only (and no Show the hint
//          again there); the status line moved into ShotStatusLine, shared with the phone's panel; the fine controls
//          (FineControls) are no longer private, so the phone's panel opens the same sliders inside itself. This panel
//          looks and behaves exactly as before.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (numbers are written in the game's own language, AppLocale.numbers
//          in NumberStyle.swift: French and German get "6,7" even on a phone set to another region.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (Show the hint again is back in the upright phone's Shot options,
//          plan Part 3: it brings back the aiming layer's groove hint, which the phone draws too.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 everyone, plans/25-Nov-2026-everyone-can-play-plan.md
//          Part C: every layout of the panel runs in the hand's order (shootSide, set by "Controls on the left"): for
//          the left hand Shoot, the tip picture and the power bar sit on the left, on the phone sideways and in small
//          windows as on the big screens.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (aiming panel redesign, plans/26-Nov-2026-aiming-panel-redesign-plan.md
//          step 8: on iPad, Mac and the open folding phone the panel is the What-you-set band (roomyPanel), a flat band
//          where each control carries its own figure, printed once: the tip picture with its millimetres, the swing over
//          a power bar with its m/s scale, the cue-angle dial with its degrees, the bridge with minus and plus, and Shoot
//          the largest control in the bottom corner on the hand's side (a solid cyan rounded rectangle; disabled, an
//          outline with grey "Rolling" while the balls move). Three columns on a band 760 points wide or more (the
//          upright iPad); stacked on the Mac, the iPad sideways and the fold. With `fills` it takes the notebook's
//          leftover height and grows the tip picture and dial into it (BandMetrics). The hint is one plain line under
//          the band. Mirrored for the left hand. The old roomy row and stacked layouts are gone; the phone sideways and
//          small windows keep the compact panel unchanged.)
// SRP/DRY check: Pass - checked the 0.3.0 panel, whose slider row is kept (now only in the sheet) and whose model
//          calls are unchanged; the break-or-shot choice is hidden behind the model's active values, so this file
//          has one set of controls, not two.
import SwiftUI

struct ShotPanel: View {
    @Bindable var model: ShowpieceModel
    @Binding var isOpen: Bool
    @AppStorage("aimHintSeen") private var hintSeen = false
    @State private var slidersOpen = false
    @Environment(\.inlinePages) private var inlinePages
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // 0.7.10 strike: which bottom corner Shoot takes (the left-handed option flips it).
    @Environment(\.shootSide) private var shootSide
    @Environment(\.layoutDirection) private var layoutDirection
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSize
    @Environment(\.verticalSizeClass) private var verticalSize
    #endif
    /// Bumped by each refusal to pulse its line (a symbol bounce; nothing moves under Reduce Motion).
    @State private var refusalPulse = 0
    /// The height of the fine controls when they open inside the panel on a phone (#48), points, scaled with the text.
    @ScaledMetric(relativeTo: .body) private var phoneFineHeight: CGFloat = 260
    /// The height of the fine controls inside the open folding phone's panel (VoiceOver's route there), points.
    @ScaledMetric(relativeTo: .body) private var foldFineHeight: CGFloat = 340
    /// In the notebook while the strike shows, the console takes all the height it is given (NotebookPanel's
    /// strikeColumn) and grows the tip picture and the dial into it.
    var fills = false
    /// UI rethink package 4: draws the kit's panel round itself. Off inside the notebook's console card, which draws
    /// one panel round "Your strike" and these controls together.
    var framed = true
    /// Told the height of the panel's parts round the controls (the status line and the hint line, with their gaps),
    /// so the notebook can keep that room for them (UI rethink package 1).
    var onChromeHeight: ((CGFloat) -> Void)? = nil
    @State private var statusHeight: CGFloat = 0
    @State private var hintHeight: CGFloat = 0
    /// The console's inner size, measured (its width and, when it fills, its height come from the notebook, never from
    /// what is drawn inside it, so measuring it cannot loop).
    @State private var bandSize: CGSize = .zero
    /// The figures on the controls: the control figure, scaled as Title is.
    @ScaledMetric(relativeTo: .title) private var controlFigure: CGFloat = Theme.FigureSize.control.baseSize
    /// The tip picture's side at the default text size before the console has room to grow it.
    @ScaledMetric(relativeTo: .body) private var baseTip: CGFloat = 112

    var body: some View {
        Group {
            if inlinePages { roomyPanel } else { compactPanel.kitDevice(.phone) }
        }
        .tint(palette.accent)
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: model.personControlsLive)
        // Each refusal pulses the line once, even the same reason twice in a row (refusalSerial), and is spoken.
        .onChange(of: model.refusalSerial) { _, _ in
            if let reason = model.lastRefusal {
                AccessibilityNotification.Announcement(reason.sentence).post()
                if !reduceMotion { refusalPulse += 1 }
            }
        }
        // Test hook: launch with -aimDemoSheet to open the fine controls straight away.
        .onAppear { if ProcessInfo.processInfo.arguments.contains("-aimDemoSheet") { slidersOpen = true } }
        // On a folding phone and on a phone the sliders open inside the panel, so no sheet covers the table; the sheet
        // is left for the iPad and the Mac, where it opens beside or over a table with room to spare.
        .sheet(isPresented: Binding(get: { slidersOpen && !finesInline }, set: { if !finesInline { slidersOpen = $0 } })) {
            FineControls(model: model, isOpen: $isOpen, sheetOpen: $slidersOpen)
        }
    }

    // MARK: The small layouts (the phone sideways, small windows)

    private var compactPanel: some View {
        VStack(spacing: Theme.Space.xs) {
            // 0.7.10 strike: one hint, in one place (StrikeHint).
            StrikeHint(model: model)
            // Why the last stroke was refused, or that the computer is playing (items 2 and 16).
            statusLine
            // The stance, when it is not a square one. Its room is kept while the panel is open, so the table does not
            // slide as the stance changes with the aim (#44).
            EquipmentCard(model: model, embedded: true, reservesRoom: true)
            // On a phone the open fine controls take the place of the tip picture and swing bar (#48).
            if !(slidersOpen && phoneFine) {
                Group {
                    if typeSize.isAccessibilitySize {
                        stacked
                    } else {
                        // Last, when neither row fits: Shoot alone on a full-width row, so it is never cut short (#47).
                        ViewThatFits(in: .horizontal) { oneRow; twoRows; stacked }
                    }
                }
                // The computer's turn: the person's controls stay visible but greyed out and still (item 16).
                .disabled(!model.personControlsLive)
                .opacity(model.personControlsLive ? 1 : 0.45)
            }
            if slidersOpen && finesInline {
                FineControls(model: model, isOpen: $isOpen, sheetOpen: $slidersOpen)
                    .frame(height: phoneFineHeight)
                    .transition(.opacity)
            }
        }
    }

    /// True on a phone (a compact width upright, a compact height sideways): the fine controls open inside the panel
    /// there instead of a sheet over a third of the table (#48).
    private var phoneFine: Bool {
        #if os(iOS)
        return !inlinePages && (horizontalSize == .compact || verticalSize == .compact)
        #else
        return false
        #endif
    }

    /// The fine controls open inside the panel: on the folding phone's side panel (inlinePages) and on a phone.
    private var finesInline: Bool { inlinePages || phoneFine }

    // 0.7.10 everyone (plans/25-Nov-2026-everyone-can-play-plan.md Part C): every row runs in the hand's order. For a
    // right hand the tip picture leads and Shoot ends the row; with "Controls on the left" the same controls run the
    // other way. shootLast already accounts for a right-to-left language, so the corner is the physical one either way.

    private var oneRow: some View {
        HStack(spacing: Theme.Space.sm) {
            if shootLast {
                smallTip
                smallSwing.frame(minWidth: 160)
                smallCueAngle
                tryAgainButton(fullWidth: false)
                fireButton()
                moreMenu
            } else {
                moreMenu
                fireButton()
                tryAgainButton(fullWidth: false)
                smallCueAngle
                smallSwing.frame(minWidth: 160)
                smallTip
            }
        }
    }

    private var twoRows: some View {
        VStack(spacing: Theme.Space.xs) {
            tipAndSwing
            HStack(spacing: Theme.Space.sm) {
                if shootLast {
                    moreMenu
                    smallCueAngle
                    Spacer(minLength: 0)
                    tryAgainButton(fullWidth: false)
                    fireButton()
                } else {
                    fireButton()
                    tryAgainButton(fullWidth: false)
                    Spacer(minLength: 0)
                    smallCueAngle
                    moreMenu
                }
            }
        }
    }

    /// Largest text, or any size where the two rows above do not fit: the picture and bar share a row, the small
    /// buttons the next, and Shoot has a full-width row of its own under them (#47).
    private var stacked: some View {
        VStack(spacing: Theme.Space.sm) {
            tipAndSwing
            HStack(spacing: Theme.Space.sm) {
                if shootLast {
                    moreMenu
                    smallCueAngle
                    Spacer(minLength: 0)
                    tryAgainButton(fullWidth: false)
                } else {
                    tryAgainButton(fullWidth: false)
                    Spacer(minLength: 0)
                    smallCueAngle
                    moreMenu
                }
            }
            fireButton(wide: true)
        }
    }

    /// The tip picture and the swing bar side by side, the picture on the hand's outer side.
    private var tipAndSwing: some View {
        HStack(spacing: Theme.Space.sm) {
            if shootLast { smallTip; smallSwing } else { smallSwing; smallTip }
        }
    }

    private var smallTip: some View { TipPicker(model: model, open: open, zones: zones) }
    /// The kit's swing bar, the phone size, with its minus and plus (PowerGauge).
    private var smallSwing: some View { PowerGauge(model: model, open: open, zones: zones, device: .phone) }

    /// The raised cue, where the model allows it (free play and matches) and for a shot rather than the break: the
    /// menu, through activeElevation, where a lesson's lock applies (item 12); locked too where the mode sets its angle.
    @ViewBuilder private var smallCueAngle: some View {
        if model.elevationAllowed && !model.racked {
            CueAngleMenu(sine: Binding(get: { model.activeElevation }, set: { model.activeElevation = $0 }),
                         zone: zones?.cueAngles, zoneStrength: zones?.strength ?? 1,
                         locked: !open.contains(.elevation) || model.cueAngleLockedByMode)
        }
    }

    /// True when Shoot comes last in a row: on the right for a right hand in a left-to-right layout, mirrored for a
    /// right-to-left one, so it always sits in the physical corner nearest the chosen hand.
    private var shootLast: Bool { (shootSide == .right) == (layoutDirection == .leftToRight) }

    // MARK: The console (iPad, Mac and the open folding phone)

    /// The status line, then the first minute's calm console or the full one, then the hint as one plain line.
    private var roomyPanel: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            // Why the last stroke was refused, or that the computer is playing (items 2 and 16).
            statusLine
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { statusHeight = $0; reportChrome() }
            if slidersOpen && finesInline {
                // The folding phone's fine controls open inside the panel (VoiceOver's route there), not in a sheet.
                FineControls(model: model, isOpen: $isOpen, sheetOpen: $slidersOpen)
                    .frame(height: foldFineHeight)
                    .transition(.opacity)
            } else if calm {
                calmConsole
            } else if fills && !typeSize.isAccessibilitySize {
                // Every control at its smallest still taller than the room (a short window): it scrolls, never
                // overlaps what is under it.
                ViewThatFits(in: .vertical) { console; ScrollView { console } }
            } else {
                console
            }
            if !calm {
                // One hint, in one place: a plain line under the controls (StrikeHint's rules unchanged).
                StrikeHint(model: model, plain: true)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { hintHeight = $0; reportChrome() }
            }
        }
        // minHeight 0 when filling: the height is the notebook's leftover room, never what is drawn inside, so
        // measuring it (bandSize) cannot feed back into the sizes it picks.
        .frame(maxWidth: .infinity, minHeight: fills ? 0 : nil, maxHeight: fills ? .infinity : nil, alignment: .topLeading)
        .onGeometryChange(for: CGSize.self) { $0.size } action: { bandSize = $0 }
        .modifier(ConsoleSurface(framed: framed))
    }

    /// The status and hint lines' heights with the gaps they bring (a line drawn empty brings none).
    private func reportChrome() {
        let gaps = CGFloat((statusHeight > 0.5 ? 1 : 0) + (hintHeight > 0.5 ? 1 : 0)) * Theme.Space.sm
        onChromeHeight?(statusHeight + hintHeight + gaps)
    }

    /// The first minute (the hand-over): the table beside one card with the sentence, the tip picture, the swing in m/s
    /// and Break (UI rethink package 4; principle 7, calm first). Nothing else until the first shot lands.
    private var calm: Bool { model.openingStage == .handOver }

    private var calmConsole: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            StrikeHint(model: model, plain: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { hintHeight = $0; reportChrome() }
            TipPicker(model: model, open: open, zones: zones, size: baseTip, showsFigures: false)
            PowerGauge(model: model, open: open, zones: zones, device: .big)
            shootButton(tall: false)
        }
        .disabled(!model.personControlsLive)
    }

    /// "WHAT YOU SET", the controls and the action column, greyed and still on the computer's turn (item 16).
    private var console: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sectionToContent) {
            BandCaption(text: StrikeWords.youSetCaption)
            Group {
                if typeSize.isAccessibilitySize {
                    accessibleConsole
                } else if bandSize.width >= Self.wideWidth {
                    wideConsole
                } else {
                    narrowConsole
                }
            }
            .disabled(!model.personControlsLive)
            .opacity(model.personControlsLive ? 1 : 0.45)
        }
    }

    /// A console at least this wide lays its controls in one row with the action column beside them (the upright
    /// iPad's full-width console); narrower ones stack them (the side column).
    static let wideWidth: CGFloat = 640

    /// The room the console's other parts take in the narrow column (the caption, the swing bar, the bridge row, the
    /// action row and their gaps), points at the default text size: what is left grows the tip picture and the dial.
    private static let narrowOverhead: CGFloat = 300
    /// The same for the wide console: the caption and the tip's two figure lines under the picture.
    private static let wideOverhead: CGFloat = 100

    /// The least height the console's controls need with every control at its smallest, for a console `width` points
    /// wide inside its card (without the status and hint lines, which the notebook measures). The notebook keeps this
    /// much for the controls, so "Your strike" above scrolls before Shoot would ever be pushed out of sight.
    static func consoleMinimumHeight(width: CGFloat) -> CGFloat {
        // The caption over the controls, then the tallest of the wide console's three columns at their smallest (the
        // action column: Shoot's tall capsule, Try again and More), or the narrow stack.
        if width >= wideWidth {
            return Theme.Space.lg + Theme.Size.actionColumnMin + Theme.Size.buttonBig + Theme.Size.minHit
                + 2 * Theme.Space.sm
        }
        return 88 + narrowOverhead
    }

    /// The status and hint lines with their gaps, as reportChrome adds them.
    private var chrome: CGFloat {
        statusHeight + hintHeight + CGFloat((statusHeight > 0.5 ? 1 : 0) + (hintHeight > 0.5 ? 1 : 0)) * Theme.Space.sm
    }

    /// The tip picture's side: the base size, grown into the height the notebook hands a filling console, never wider
    /// than its share of the console's width.
    private var tipSize: CGFloat {
        let wide = bandSize.width >= Self.wideWidth
        let widthCap = bandSize.width > 0 ? bandSize.width * (wide ? 0.2 : 0.32) : baseTip
        let room = fills && bandSize.height > 0
            ? bandSize.height - chrome - (wide ? Self.wideOverhead : Self.narrowOverhead)
            : baseTip
        return min(max(88, room), wide ? 200 : 128, max(88, widthCap))
    }

    /// The figures on the controls: the control size on the wide console, a step smaller in the side column.
    private var figureSize: CGFloat { bandSize.width >= Self.wideWidth ? controlFigure : controlFigure * 0.8 }

    /// The upright iPad: Tip, then the swing over the cue angle and the bridge, then the action column, split by hairline
    /// rules, the action column on the hand's side.
    private var wideConsole: some View {
        HStack(alignment: .top, spacing: Theme.Space.lg) {
            if shootLast {
                tipControl; HairlineRule(); swingAngleBridge; HairlineRule(); actionColumn
            } else {
                actionColumn; HairlineRule(); swingAngleBridge; HairlineRule(); tipControl
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var tipControl: some View {
        TipPicker(model: model, open: open, zones: zones, size: tipSize, figureSize: figureSize * 0.9)
    }

    /// The swing bar, then the cue angle and the bridge side by side.
    private var swingAngleBridge: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            PowerGauge(model: model, open: open, zones: zones, device: .big)
            HStack(alignment: .top, spacing: Theme.Space.lg) {
                cueAngleControl(dial: min(tipSize, 140), figureBelow: false)
                Spacer(minLength: 0)
                BridgeControl(model: model, figureSize: figureSize)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The action column: Shoot, a tall cyan capsule; Try again under it, a secondary capsule the same width; More.
    private var actionColumn: some View {
        VStack(spacing: Theme.Space.sm) {
            shootButton(tall: true)
            tryAgainButton(fullWidth: true)
            moreMenu
        }
        .frame(width: min(240, max(180, bandSize.width * 0.22)))
    }

    /// The side column (the iPad sideways, the Mac, the fold): the tip picture with its figures beside it and the
    /// cue-angle dial; the swing bar; the bridge and More; then Try again and Shoot on the last row, Shoot in the corner
    /// on the hand's side (the iPad mockup's order).
    private var narrowConsole: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: Theme.Space.md) {
                    TipPicker(model: model, open: open, zones: zones, size: tipSize, figureSize: figureSize * 0.9,
                              figuresBeside: true)
                    Spacer(minLength: 0)
                    // A smaller dial than the tip picture, so the row stays short enough for Shoot to show in a
                    // 900-point Mac window (UI rethink package 4 follow-up).
                    cueAngleControl(dial: tipSize * 0.6, figureBelow: true)
                }
                VStack(alignment: .leading, spacing: Theme.Space.md) {
                    TipPicker(model: model, open: open, zones: zones, size: tipSize, figureSize: figureSize * 0.9,
                              figuresBeside: true)
                    cueAngleControl(dial: tipSize * 0.8, figureBelow: false)
                }
            }
            PowerGauge(model: model, open: open, zones: zones, device: .big)
            HStack(alignment: .center, spacing: Theme.Space.sm) {
                if shootLast {
                    BridgeControl(model: model, figureSize: figureSize, inline: true).fixedSize()
                    Spacer(minLength: 0)
                    moreMenu
                } else {
                    moreMenu
                    Spacer(minLength: 0)
                    BridgeControl(model: model, figureSize: figureSize, inline: true).fixedSize()
                }
            }
            actionRow
        }
    }

    /// Try again and Shoot sharing a row, Shoot taking the rest of the width on the hand's side.
    private var actionRow: some View {
        HStack(spacing: Theme.Space.sm) {
            if shootLast {
                tryAgainButton(fullWidth: false)
                shootButton(tall: false)
            } else {
                shootButton(tall: false)
                tryAgainButton(fullWidth: false)
            }
        }
    }

    /// The accessibility text sizes: one control a row, nothing shrunk; Shoot and Try again full width at the foot.
    private var accessibleConsole: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            TipPicker(model: model, open: open, zones: zones, size: baseTip, figureSize: figureSize)
            cueAngleControl(dial: baseTip, figureBelow: true)
            PowerGauge(model: model, open: open, zones: zones, device: .big)
            BridgeControl(model: model, figureSize: figureSize)
            moreMenu
            shootButton(tall: false)
            tryAgainButton(fullWidth: true)
        }
    }

    /// "Cue angle" over the dial with its degrees, where the model allows a raised cue (free play and matches) and for a
    /// shot; a mode that sets its own angle shows it locked (CueAngleDial reads model.cueAngleLockedByMode).
    @ViewBuilder private func cueAngleControl(dial: CGFloat, figureBelow: Bool) -> some View {
        if model.elevationAllowed && !model.racked {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                Text(verbatim: StrikeWords.cueAngleLabel)
                    .font(Theme.label)
                    .foregroundStyle(palette.paper2)
                    .accessibilityHidden(true)
                CueAngleDial(model: model, zone: zones?.cueAngles, zoneStrength: zones?.strength ?? 1, size: max(64, dial),
                             figureSize: figureSize, figureBelow: figureBelow)
            }
        }
    }

    // MARK: The buttons

    /// Which controls are open now and the lesson's target bands, if any. Handed to each control so it can dim itself
    /// and draw its band.
    private var open: ShotControls { model.openControls }
    private var zones: LessonZones? { model.lessonZones }

    /// Break or Shoot in the console: the kit's primary capsule, tall in the action column. Disabled while a stroke
    /// would be refused: "Rolling" while the balls still move, else the word on the sunken face (the status line says
    /// why, and VoiceOver hears it as the hint).
    private func shootButton(tall: Bool) -> some View {
        let refused = model.strokeRefusal != nil
        let rolling = refused && !model.aimReady && !model.isSolving
        return Button {
            hintSeen = true
            // The big screens' hint line has no close button, so a shot also puts the Pencil line away (StrikeHint).
            UserDefaults.standard.set(true, forKey: "pencilHintSeen")
            if model.fireStroke() == .breakStruck { isOpen = false }
        } label: {
            Text(verbatim: rolling ? StrikeWords.rollingWord : Self.actionWord(racked: model.racked))
                .lineLimit(1)
                .minimumScaleFactor(typeSize.isAccessibilitySize ? 1 : 0.7)
        }
        .buttonStyle(PrimaryButtonStyle(fullWidth: true, tall: tall))
        .disabled(refused)
        .accessibilityHint(model.strokeRefusal?.sentence
                           ?? (model.racked ? String(localized: "Plays your own break") : String(localized: "Plays your shot")))
    }

    /// Break or Shoot in the small layouts: the kit's primary capsule. `wide` stretches it across its row (the stacked
    /// layout's own row, #47).
    private func fireButton(wide: Bool = false) -> some View {
        Button {
            hintSeen = true
            // A break hands the screen to its replay, so the panel closes; a shot keeps it open; a refusal says why.
            if model.fireStroke() == .breakStruck { isOpen = false }
        } label: {
            Text(verbatim: Self.actionWord(racked: model.racked))
                .lineLimit(1)
        }
        .buttonStyle(PrimaryButtonStyle(fullWidth: wide))
        // Disabled while a stroke would be refused; the reason is the hint, so VoiceOver hears why.
        .disabled(model.strokeRefusal != nil)
        .accessibilityHint(model.strokeRefusal?.sentence
                           ?? (model.racked ? String(localized: "Plays your own break") : String(localized: "Plays your shot")))
    }

    /// Back to where the last shot started, same settings, with the last try kept as a ghost to compare against. Only
    /// there once a shot of the player's own has played out, so it never jumps in mid-shot. The kit's secondary
    /// capsule; its words when the row has room, else the arrow alone (VoiceOver still hears "Try again").
    @ViewBuilder private func tryAgainButton(fullWidth: Bool) -> some View {
        if model.canTryAgain {
            Button {
                hintSeen = true
                model.tryAgain()
            } label: {
                ViewThatFits(in: .horizontal) {
                    KitButtonLabel(String(localized: "Try again"), systemImage: "arrow.uturn.backward")
                    Image(systemName: "arrow.uturn.backward")
                }
                .lineLimit(1)
            }
            .buttonStyle(SecondaryButtonStyle(fullWidth: fullWidth))
            .accessibilityLabel("Try again")
            .accessibilityHint("Puts the balls back where your last shot started, with the same aim, power and spin")
            .transition(.opacity)
        }
    }

    /// The worded More: the shot options (ShotOptionsItems) behind a quiet "More", never a bare dots icon.
    private var moreMenu: some View {
        Menu {
            ShotOptionsItems(model: model, slidersOpen: $slidersOpen)
        } label: {
            KitButtonLabel(String(localized: "More"), systemImage: "ellipsis")
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)
        .buttonStyle(.kitQuiet)
        .fixedSize()
        .accessibilityLabel("More shot options")
    }

    /// One line above the controls: on the computer's turn, that it is its turn; otherwise the reason the last stroke
    /// was refused, until the next stroke is accepted (the model clears it). Nothing when there is nothing to say.
    private var statusLine: some View { ShotStatusLine(model: model, pulse: refusalPulse) }

    /// The words for each free-play rack.
    static func rackName(_ rack: FreePlayRack) -> String {
        switch rack {
        case .fifteen: return String(localized: "Fifteen-ball triangle")
        case .nineBall: return String(localized: "Nine-ball diamond")
        case .placeBalls: return String(localized: "No rack: place the balls")
        }
    }

    static func tipWord(_ v: Double) -> String { v < -0.002 ? "draw" : (v > 0.002 ? "follow" : "centre") }
    static func sideWord(_ v: Double) -> String { v < -0.002 ? "left" : (v > 0.002 ? "right" : "centre") }

    /// The words the player actually sees for a tip or side setting. tipWord and sideWord return fixed identifiers for
    /// comparisons; this turns one of those into its translated word for the screen and for the retry comparison.
    static func shownWord(_ word: String) -> String {
        switch word {
        case "draw": return String(localized: "draw")
        case "follow": return String(localized: "follow")
        case "left": return String(localized: "left")
        case "right": return String(localized: "right")
        default: return String(localized: "centre")
        }
    }

    /// The fine controls' tip and side readout (0.7.5): the word the player sees and the signed offset in millimetres,
    /// "follow, +8.5 mm", "left, −3.0 mm", "centre, 0.0 mm", so a judge's "about 2 millimetres lower" can be set by
    /// eye. tipWord and sideWord are left exactly as they are: the retry comparison (ShotAttempt) reads them.
    static func tipReadout(_ metres: Double, vertical: Bool) -> String {
        let word = shownWord(vertical ? tipWord(metres) : sideWord(metres))
        // Rounded to the tenth first, so a value a hair either side of zero reads "0.0" with no sign (a hair below zero
        // rounds to negative zero; assigning a plain 0 drops the sign bit).
        var tenths = (metres * 10_000).rounded() / 10
        if tenths == 0 { tenths = 0 }
        let mm = tenths.formatted(.number.locale(AppLocale.numbers).precision(.fractionLength(1)).sign(strategy: .always(includingZero: false)))
        return String(localized: "\(word), \(mm) mm")
    }

    /// The word on the main shot button: Break for the opening rack, Shoot after that.
    static func actionWord(racked: Bool) -> String {
        racked ? String(localized: "Break") : String(localized: "Shoot")
    }
}

/// The console's surface: the kit's panel when it stands alone, nothing inside the notebook's console card.
private struct ConsoleSurface: ViewModifier {
    let framed: Bool
    @ViewBuilder
    func body(content: Content) -> some View {
        if framed { content.kitPanel() } else { content }
    }
}

// MARK: The status line

/// One line above the shot controls: on the computer's turn, that it is its turn; otherwise the reason the last stroke
/// was refused, until the next stroke is accepted (the model clears it). Nothing when there is nothing to say. Shared by
/// ShotPanel and the upright phone's PhoneAimPanel; each bumps `pulse` on a refusal to bounce the mark once.
struct ShotStatusLine: View {
    let model: ShowpieceModel
    var pulse = 0
    @Environment(\.palette) private var palette

    var body: some View {
        // personControlsLive is false on the computer's turn or while a solve is in flight; without the solve it is the
        // computer's turn (read this way so no comparison with a case named "none" can be taken for an optional's).
        let computer = !model.personControlsLive && !model.isSolving
        if let text = computer ? Optional(ShotRefusal.notYourTurn.sentence) : model.lastRefusal?.sentence {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
                Image(systemName: computer ? "cpu" : "exclamationmark.circle")
                    .foregroundStyle(computer ? palette.accent : palette.warning)
                    .symbolEffect(.bounce, value: pulse)
                    .accessibilityHidden(true)
                Text(text)
                    .font(Theme.body)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
            .transition(.opacity)
        }
    }
}

// MARK: Shot options (the More menu's items)

/// The items of the shot panel's More menu, shared by ShotPanel and the upright phone's "Shot options" menu
/// (PhoneAimPanel), so both offer the same things with the same rules: Fine controls, Aim at nearest ball, and in plain
/// free play Move cue ball, Undo last shot, the rack and Re-rack, then Show the hint again once the hint has been seen.
/// The phone's form (`phone`) adds Try again first (it left the phone's main row) and Change the call in a match whose
/// call is made, and uses the symbols the phone plan chose (Undo's plain back arrow, Re-rack's circling arrows); it
/// keeps Show the hint again, last, as the plan orders it. The phone has no hint card, but the item still brings back
/// the aiming layer's groove hint (AimOverlay.showsGrooveHint), which is drawn on every layout, the upright phone
/// included. The shot panel's form is exactly the menu it always had. The hint's seen flag is the same stored
/// "aimHintSeen" key the panel and the aim overlay read, so Show the hint again works from either menu.
struct ShotOptionsItems: View {
    let model: ShowpieceModel
    /// Opens the fine controls (the panel shows them inside itself, or in a sheet on iPad and Mac).
    @Binding var slidersOpen: Bool
    var phone = false
    @AppStorage("aimHintSeen") private var hintSeen = false
    // 0.7.10 strike: on the big screens the strike panel's typed entries replace the sliders, except for VoiceOver.
    @Environment(\.inlinePages) private var inlinePages
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

    /// True in plain free play: no match, no trick shot, no Behind the 8-Ball situation, no lesson on the table.
    private var freePlay: Bool {
        model.match == nil && !model.trickMode.isActive && !model.eightBallMode.isActive && !model.lessonMode.isActive
    }

    var body: some View {
        let open = model.openControls
        if phone && model.canTryAgain {
            Button {
                hintSeen = true
                model.tryAgain()
            } label: { Label("Try again", systemImage: "arrow.uturn.backward") }
            .accessibilityHint("Puts the balls back where your last shot started, with the same aim, power and spin")
        }
        // 0.7.10 strike: kept on the upright phone, in the small layouts and for VoiceOver; on iPad, Mac and the open
        // folding phone the strike panel's tiles take exact values instead (plan stage 2 item 5).
        if phone || !inlinePages || voiceOver {
            Button { slidersOpen = true } label: { Label("Fine controls", systemImage: "slider.horizontal.3") }
        }
        if !model.racked {
            Button { model.aimAtNearestBall() } label: { Label("Aim at nearest ball", systemImage: "scope") }
                .disabled(!open.contains(.aim))
        }
        if phone, let match = model.match, match.mustCall, match.currentCall != nil, match.phase == .aiming,
           match.personMayAct {
            // Back to the call row in the aiming panel, to call something else before shooting.
            Button { match.setCall(nil) } label: { Label("Change the call", systemImage: "pencil") }
        }
        if freePlay {
            // Practice players move the cue ball all the time: the same placement state as ball in hand.
            Button { model.beginPlacingCueBall() } label: { Label("Move cue ball", systemImage: "hand.raised") }
                .disabled(!model.aimReady || model.placingCueBall)
            Button { model.undoLastShot() } label: {
                Label("Undo last shot", systemImage: phone ? "arrow.uturn.backward" : "arrow.uturn.backward.circle")
            }
            .disabled(!model.canUndo)
            .keyboardShortcut("z", modifiers: .command)
            // 0.7.7 make-it-again: Make it again / Play it now for any saveable shot, remarkable or not.
            MakeItAgainMenuItem(model: model)
            Picker(selection: Binding(get: { model.freePlayRack }, set: { model.setFreePlayRack($0) })) {
                ForEach(FreePlayRack.allCases, id: \.self) { rack in Text(ShotPanel.rackName(rack)).tag(rack) }
            } label: {
                Label("Rack", systemImage: "triangle")
            }
            .pickerStyle(.menu)
            if !model.racked {
                Button { model.rerack() } label: {
                    Label("Re-rack for a break", systemImage: phone ? "arrow.triangle.2.circlepath" : "triangle")
                }
            }
        }
        // On every layout, the upright phone too: clearing the flag brings back the aiming layer's groove hint
        // everywhere, and on the iPad and Mac the panel's hint card as well.
        if hintSeen {
            // 0.7.10 strike: the Pencil line comes back with it (StrikeHint's own stored key).
            Button {
                hintSeen = false
                UserDefaults.standard.set(false, forKey: "pencilHintSeen")
            } label: { Label("Show the hint again", systemImage: "questionmark.circle") }
        }
    }
}

// MARK: Fine controls (the sliders, in a sheet)

/// Every value the gestures set, as standard labelled sliders. The complete accessible route into the shot: it needs
/// no picture of the table, no drag and no pointer. Also handy on a Mac for typing a precise value with the keyboard.
/// Also opened inside the upright phone's aiming panel (PhoneAimPanel), in place of its tip picture and power bar.
struct FineControls: View {
    @Bindable var model: ShowpieceModel
    @Binding var isOpen: Bool
    @Binding var sheetOpen: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                    // A lesson's locked controls are greyed out here too (the model refuses the change anyway).
                    let open = model.openControls
                    if model.racked {
                        SliderRow(label: "Aim", value: $model.aimOffset, range: -ShowpieceModel.breakAimLimit...ShowpieceModel.breakAimLimit,
                                  // In the player's number style, as the other readouts are (#61).
                                  readout: String(format: "%+.0f mm", locale: AppLocale.numbers, model.aimOffset * 1000))
                    } else {
                        aimRow.disabled(!open.contains(.aim)).lockedForStep(!open.contains(.aim))
                    }
                    SliderRow(label: "Power", value: Binding(get: { model.activePower }, set: { model.activePower = $0 }),
                              range: model.powerRange, readout: StrokeWords.ballReadout(power: model.activePower, racked: model.racked, cue: model.cueInHand))
                        .disabled(!open.contains(.power)).lockedForStep(!open.contains(.power))
                    // The bridge's length: read here, set on the table by a resting second finger, or here with the
                    // slider (item 5). The rest fixes its own length, so the slider waits while the rest is in use.
                    BridgeReadout(model: model)
                    SliderRow(label: "Bridge",
                              value: Binding(get: { model.strokeBridge ?? StrokeModel.automaticBridge },
                                             set: { model.strokeBridge = $0 }),
                              range: StrokeModel.bridgeRange,
                              readout: Measurement(value: ((model.strokeBridge ?? StrokeModel.automaticBridge) * 100).rounded(),
                                                   unit: UnitLength.centimeters)
                                  .formatted(.measurement(width: .abbreviated, usage: .asProvided).locale(AppLocale.numbers)))
                        .disabled(model.restInUse)
                    SliderRow(label: "Cue tip", value: Binding(get: { model.activeTipUp }, set: { model.activeTipUp = $0 }),
                              range: -model.tipLimit...model.tipLimit,
                              readout: ShotPanel.tipReadout(model.activeTipUp, vertical: true))
                        .disabled(!open.contains(.tipUp)).lockedForStep(!open.contains(.tipUp))
                    SliderRow(label: "Side", value: Binding(get: { model.activeTipSide }, set: { model.activeTipSide = $0 }),
                              range: -model.tipLimit...model.tipLimit,
                              readout: ShotPanel.tipReadout(model.activeTipSide, vertical: false))
                        .disabled(!open.contains(.tipSide)).lockedForStep(!open.contains(.tipSide))
                    if model.elevationAllowed && !model.racked {
                        // Degrees on the slider, the sine in the model (the solver's unit). The top is the last angle
                        // the cue-angle menu offers, short of where the cue rig stops pitching the cue.
                        SliderRow(label: "Cue angle",
                                  value: Binding(get: { asin(min(max(model.activeElevation, 0), 0.995)) * 180 / .pi },
                                                 set: { model.activeElevation = $0 < 0.5 ? 0 : sin($0 * .pi / 180) }),
                                  range: 0...Double(CueAngleMenu.angles.last ?? 80),
                                  readout: CueAngleMenu.words(degrees: asin(min(max(model.activeElevation, 0), 0.995)) * 180 / .pi))
                        // 0.7.10 strike: refused too where the mode sets its own angle (the model refuses anyway).
                        .disabled(!open.contains(.elevation) || model.cueAngleLockedByMode)
                        .lockedForStep(!open.contains(.elevation))
                    }
                    Button {
                        sheetOpen = false
                        if model.fireStroke() == .breakStruck { isOpen = false }
                    } label: {
                        Text(verbatim: ShotPanel.actionWord(racked: model.racked))
                    }
                    // UI rethink package 4: the kit's primary capsule, full width.
                    .buttonStyle(PrimaryButtonStyle(fullWidth: true))
                    .disabled(model.strokeRefusal != nil)
                    .accessibilityHint(model.strokeRefusal?.sentence ?? "")
                    .padding(.top, Theme.Space.sm)
                }
                .padding(Theme.Space.md)
            }
            .background(palette.ground)
            .navigationTitle("Fine controls")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { sheetOpen = false } } }
        }
        .tint(palette.accent)
        // As a sheet (iPad and Mac only since 0.7.6 #48; a phone shows these inside the panel): half height leaves the
        // table in view above it, and the table stays touchable while the sheet is half open.
        .presentationDetents([.medium, .large])
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        #if os(macOS)
        .frame(minWidth: 380, minHeight: 360)
        #endif
    }

    /// The aim row has nudge buttons either side of its slider, so it gets two lines: name and value, then the control.
    private var aimRow: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Aim").font(Theme.label).foregroundStyle(palette.paper2).accessibilityHidden(true)
                Spacer()
                // In the player's number style ("+12,5°" where a comma is the decimal mark), as Power and Cue tip
                // below already are (#61).
                Text(verbatim: Self.degreesReadout(model.aimDegrees)).font(Theme.inlineFigure).accessibilityHidden(true)
            }
            HStack(spacing: Theme.Space.xs) {
                Button { model.aimDegrees -= 0.25 } label: { Image(systemName: "minus") }
                    .accessibilityLabel("Aim right a little")
                Slider(value: $model.aimDegrees, in: -180...180) { Text("Aim") }
                    .labelsHidden()   // the Mac draws a slider's label unless told not to; the row already shows it
                    .accessibilityValue(String(localized: "\(String(format: "%.1f", locale: AppLocale.numbers, model.aimDegrees)) degrees"))
                Button { model.aimDegrees += 0.25 } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Aim left a little")
            }
            // UI rethink package 4: the round step button (AimGauges.swift), the secondary surface in a circle.
            .buttonStyle(RoundStepButtonStyle())
        }
    }

    /// The aim in degrees, signed, to a tenth, in the player's number style (#61): "+12.5°", "+12,5°". Rounded to the
    /// tenth first so a hair below zero reads "0.0°", not "-0.0°". UI rethink package 4: the figure and its degree sign
    /// come from NumberStyle's one rule for angles; the plus sign is this readout's own.
    private static func degreesReadout(_ degrees: Double) -> String {
        var tenths = (degrees * 10).rounded() / 10
        if tenths == 0 { tenths = 0 }
        return (tenths > 0 ? "+" : "") + NumberStyle.angle(degrees: tenths).text
    }
}

/// One labelled slider: name, system slider, and a readout in digits that do not jitter. The readout is also what
/// VoiceOver says as the slider's value, in place of the default percentage.
/// Two layouts (#49): the name, the slider and the readout side by side, with the name and the readout each kept on
/// one line at their own width, where that leaves the slider room; otherwise the name and the readout on a line above
/// the slider (the layout the accessibility sizes always use). The old fixed name and readout columns wrapped longer
/// translations into two or three short lines.
private struct SliderRow: View {
    let label: LocalizedStringKey
    @Binding var value: Double
    let range: ClosedRange<Double>
    let readout: String
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.palette) private var palette
    /// The narrowest the slider may be in the side-by-side row before the row gives way to the stacked one, points.
    @ScaledMetric(relativeTo: .caption) private var sliderMin: CGFloat = 110

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                stacked
            } else {
                // The side-by-side row is chosen only when its ideal width (both words whole, the slider at sliderMin)
                // fits; the slider then takes whatever width is left.
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Theme.Space.xs) {
                        name.fixedSize()
                        slider.frame(minWidth: sliderMin, idealWidth: sliderMin, maxWidth: .infinity)
                        readoutText.fixedSize()
                    }
                    stacked
                }
            }
        }
        .frame(minHeight: Theme.Size.minHit)
    }

    /// The name and the readout on one line (the readout may wrap under a long name), the slider under them.
    private var stacked: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                name
                Spacer(minLength: Theme.Space.xs)
                readoutText.multilineTextAlignment(.trailing)
            }
            slider
        }
    }

    private var name: some View {
        Text(label).font(Theme.label).foregroundStyle(palette.paper2).accessibilityHidden(true)
    }

    private var readoutText: some View {
        Text(readout).font(Theme.inlineFigure).accessibilityHidden(true)
    }

    private var slider: some View {
        Slider(value: $value, in: range) { Text(label) }
            .labelsHidden()
            .accessibilityValue(readout)
    }
}
