// Author: Claude Opus 5.5 Medium
// Date: 22-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 strike, plans/25-Nov-2026-strike-panel-and-controls-plan.md
//          stage 4 and stage 3 item 5: a tap on the swing figure opens the strike panel as a sheet over the lower half
//          (StrikeSheet); the first instruction and the Pencil line sit at the top of the panel (StrikeHint); the cue
//          angle is locked where the mode sets its own.)
// PURPOSE: The upright phone's aiming panel (plans/22-Nov-2026-phone-ui-plan.md, Part 3 "The aiming panel"), in place of
//          ShotPanel on that layout only. ShowpieceView puts it in the bottom bar's one glass container, above
//          PhoneStrip, while Your shot is open (and WhatIfPhonePanel in its place while a what-if shows). One regular
//          glass shape, sized to its content, with corner 24 and padding 12; every control on it is drawn as content on
//          that glass (a faint capsule or circle, PhonePanelControl), so there is no glass on glass. Two rows:
//            1. the cue-ball picture for the tip (TipPicker, 52 points) and the power bar filling the rest
//               (PhonePowerBar): the swing figure ("2.6 m/s") in headline monospaced with "Swing speed · firm" in
//               caption beside it, the bar with its calm-zone mark, no minus or plus (the drag, or a pull-back on the
//               table, sets power; VoiceOver adjusts the bar in fixed steps);
//            2. "Put away" (chevron.down, once there is a shot to go back to), the cue angle as a text capsule ("Level",
//               "30°", CueAngleMenu's phone form), "Shot options" (slider.horizontal.3, ShotOptionsItems' phone form:
//               Try again, Fine controls, Aim at nearest ball, Change the call, Move cue ball, Undo, Rack, Re-rack), then
//               "Break" or "Shoot", the white capsule with dark text, about 96 by 44.
//          While a match shot needs its call, the call row (MatchCallRow, App/Match/CallControl.swift) takes row 2's
//          place, and Shoot comes back once the call is made. "Fine controls" opens the labelled sliders (FineControls,
//          ShotPanel.swift) inside the panel in place of row 1, as ShotPanel does on a phone, so no sheet covers the
//          table. The refusal or computer's-turn line (ShotStatusLine) sits above the rows. ShotPanel's one-time gesture
//          hint card is not used here (Part 3, "Stop using on the upright phone"): the first-minute instruction is the
//          docked opening blurb, so the bar never grows by a second copy of it.
//          The panel shares its glass identity with the strip's primary action (PhoneGlassID.primaryAction in the
//          environment's phoneGlassNamespace), so "Your shot" grows into the panel and the panel shrinks back into it;
//          the identity is dropped while the strip shows a primary action of its own beside the open panel, so two
//          shapes never claim it at once.
//          Reads and writes the model only through the calls ShotPanel uses (fireStroke, activeElevation, powerFraction,
//          the gauges' own calls, the options' calls); Put away sets the isOpen binding, as Your shot's toggle does.
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (numbers are written in the game's own language, AppLocale.numbers
//          in NumberStyle.swift: French and German get "6,7" even on a phone set to another region.)
// SRP/DRY check: Pass - reuses TipPicker (AimGauges.swift), CueAngleMenu (phone form), ShotOptionsItems, FineControls
//          and ShotStatusLine (ShotPanel.swift), MatchCallRow (CallControl.swift) and StrokeWords (the
//          figure and caption). PhonePowerBar redraws PowerGauge's bar (AimGauges.swift is not part of this change):
//          the same fill, lesson band, warm zone and calm mark, the same stored count for the calm label, and the same
//          spoken value and adjust steps, without PowerGauge's minus and plus buttons and with the figure over the bar.
//          ShotPanel stays as it was for the notebook, the sideways column and the big-window layout.
import SwiftUI

// MARK: Controls drawn on the panel's glass

/// A control that sits on one of the upright phone's glass panels (the aiming panel, the what-if's nudge panel): a
/// faint white capsule or circle behind a plain button's label, instead of a glass button, because glass is never laid
/// on glass (plans/22-Nov-2026-phone-ui-plan.md, "Liquid Glass"). With Increase Contrast the fill is stronger.
struct PhonePanelControl: ViewModifier {
    enum Outline { case capsule, circle }
    let shape: Outline
    @Environment(\.colorSchemeContrast) private var contrast

    private var fill: Color { .white.opacity(contrast == .increased ? 0.24 : 0.12) }

    @ViewBuilder
    func body(content: Content) -> some View {
        switch shape {
        case .capsule: content.background(fill, in: .capsule)
        case .circle: content.background(fill, in: .circle)
        }
    }
}

// MARK: The panel

struct PhoneAimPanel: View {
    @Bindable var model: ShowpieceModel
    @Binding var isOpen: Bool

    /// The one-time gesture hint's seen flag (the same stored key ShotPanel and the aim overlay use): a shot marks it
    /// seen, as ShotPanel's Shoot does, so the hint does not greet the player on a bigger screen later.
    @AppStorage("aimHintSeen") private var hintSeen = false
    /// The fine controls open inside the panel in place of row 1.
    @State private var slidersOpen = false
    /// Bumped by each refusal to bounce the status line's mark once (nothing moves under Reduce Motion).
    @State private var refusalPulse = 0
    /// 0.7.10 strike: the strike panel's sheet, opened by a tap on the swing figure (StrikeSheet).
    @State private var strikeOpen = false

    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.phoneGlassNamespace) private var sharedGlass
    /// Stands in when the panel is shown outside the bottom bar (no shared namespace), so the modifier always has one.
    @Namespace private var localGlass
    /// The open fine controls' height, scaled with the text: the aim row and about three sliders show, the rest
    /// scroll (ShotPanel's phone height).
    @ScaledMetric(relativeTo: .body) private var fineHeight: CGFloat = 260

    /// The panel's corner and padding (shared with WhatIfPhonePanel, which takes its place).
    static let corner: CGFloat = 24
    static let padding: CGFloat = 12
    /// Break or Shoot: at least this wide, 44 high (Part 3: "about 96 by 44").
    private static let fireWidth: CGFloat = 96

    var body: some View {
        panel
        // Each refusal bounces the line once, even the same reason twice in a row (refusalSerial), and is spoken.
        .onChange(of: model.refusalSerial) { _, _ in
            if let reason = model.lastRefusal {
                AccessibilityNotification.Announcement(reason.sentence).post()
                if !reduceMotion { refusalPulse += 1 }
            }
        }
        // Test hook, as ShotPanel's: launch with -aimDemoSheet to open the fine controls straight away.
        .onAppear { if ProcessInfo.processInfo.arguments.contains("-aimDemoSheet") { slidersOpen = true } }
        .animation(reduceMotion ? nil : .smooth, value: slidersOpen)
        .animation(reduceMotion ? nil : .snappy, value: model.personControlsLive)
        // 0.7.10 strike: the strike in real units, over the lower half; the table stays in view and touchable above.
        .sheet(isPresented: $strikeOpen) { StrikeSheet(model: model, isOpen: $strikeOpen) }
    }

    // MARK: Glass

    /// The glass shape with its two rows (or the fine controls in place of row 1).
    private var panel: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 0.7.10 strike: the first instruction (and the Pencil line) below the table, in the panel, instead of a
            // blurb docked over the top of the table.
            StrikeHint(model: model, phone: true)
            ShotStatusLine(model: model, pulse: refusalPulse)
            if slidersOpen {
                FineControls(model: model, isOpen: $isOpen, sheetOpen: $slidersOpen)
                    .frame(height: fineHeight)
                    .transition(.opacity)
            } else {
                rowOne
                    // The computer's turn: the person's controls stay visible but greyed out and still.
                    .disabled(!model.personControlsLive)
                    .opacity(model.personControlsLive ? 1 : 0.45)
            }
            rowTwo
        }
        .padding(Self.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tint(palette.accent)
        // Regular glass (it carries words). Not interactive: the whole panel would swell under every drag on the power
        // bar and the tip picture; its buttons give their own feedback.
        .glassEffect(.regular, in: .rect(cornerRadius: Self.corner, style: .continuous))
        .glassEffectID(morphID, in: sharedGlass ?? localGlass)
    }

    /// The identity shared with the strip's primary action, so "Your shot" morphs into the panel and back. Dropped
    /// while the strip shows a primary action of its own beside the open panel (a trick's "Your turn", the drill's
    /// "Again"): that capsule carries the identity then, and one identity must belong to one shape.
    private var morphID: String? {
        PhonePrimaryAction.resolve(model, shotPanelOpen: true, shotLive: false) == nil ? PhoneGlassID.primaryAction : nil
    }

    // MARK: Row 1: tip and power

    private var open: ShotControls { model.openControls }
    private var zones: LessonZones? { model.lessonZones }

    private var rowOne: some View {
        HStack(alignment: .center, spacing: 12) {
            TipPicker(model: model, open: open, zones: zones)
            // 0.7.10 strike: a tap on the swing figure opens the strike panel (stage 4).
            PhonePowerBar(model: model, open: open, zones: zones, onFigureTap: { strikeOpen = true })
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: Row 2: put away, cue angle, options, fire (or the call)

    @ViewBuilder private var rowTwo: some View {
        if let match = model.match, Self.callDue(match, model: model) {
            MatchCallRow(match: match)
        } else if typeSize.isAccessibilitySize {
            stackedRowTwo
        } else {
            // One row; when a long translation or a large text size does not fit, Shoot takes a row of its own.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    smallControls
                    Spacer(minLength: 0)
                    fireButton(wide: false)
                }
                stackedRowTwo
            }
        }
    }

    private var stackedRowTwo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) { smallControls }
            fireButton(wide: true)
        }
    }

    /// Put away, the cue angle and Shot options, left to right.
    @ViewBuilder private var smallControls: some View {
        if showsPutAway { putAway }
        Group {
            cueAngle
            shotOptions
        }
        .disabled(!model.personControlsLive)
        .opacity(model.personControlsLive ? 1 : 0.45)
    }

    /// A call is due before this shot: a match whose rules use calls, after the break, while aiming, on the person's
    /// turn, with no call made yet. The call row then takes row 2's place.
    static func callDue(_ match: MatchMode, model: ShowpieceModel) -> Bool {
        match.mustCall && match.currentCall == nil && match.phase == .aiming && match.personMayAct && model.aimReady
    }

    /// "Put away" shows once there is a shot to go back to: never in the first minute, whose panel opens by itself and
    /// has nothing behind it, and only when a recording is loaded for the strip to play.
    private var showsPutAway: Bool { model.openingStage == .none && model.duration > 0 }

    private var putAway: some View {
        Button { isOpen = false } label: {
            Image(systemName: "chevron.down")
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .modifier(PhonePanelControl(shape: .circle))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Put away"))
        .accessibilityHint(String(localized: "Puts the aiming controls away"))
    }

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

    private var shotOptions: some View {
        Menu {
            ShotOptionsItems(model: model, slidersOpen: $slidersOpen, phone: true)
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .modifier(PhonePanelControl(shape: .circle))
                .contentShape(Circle())
        }
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Shot options"))
    }

    /// Break or Shoot: the white capsule with dark text (the accent is cyan, and cyan means rolling). Disabled, and
    /// dimmed, while a stroke would be refused; the reason is the hint, so VoiceOver hears why.
    private func fireButton(wide: Bool) -> some View {
        let refusal = model.strokeRefusal
        return Button {
            hintSeen = true
            // A break hands the screen to its replay, so the panel closes; a shot keeps it open; a refusal says why.
            if model.fireStroke() == .breakStruck { isOpen = false }
        } label: {
            Text(ShotPanel.actionWord(racked: model.racked))
                .font(Theme.phoneControl)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 16)
                .frame(minWidth: Self.fireWidth, maxWidth: wide ? .infinity : nil, minHeight: 44)
                .foregroundStyle(palette.ground)
                .background(.white, in: .capsule)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(refusal != nil)
        .opacity(refusal == nil ? 1 : 0.5)
        .accessibilityHint(refusal?.sentence
                           ?? (model.racked ? String(localized: "Plays your own break") : String(localized: "Plays your shot")))
    }
}

// MARK: The power bar

/// The upright phone's power bar: the swing figure in headline monospaced with its caption ("Swing speed · firm") on
/// one line, then the bar. The bar is PowerGauge's (AimGauges.swift): a warming fill, a lesson's target band, the warm
/// wash past the calm zone and a thin mark where the calm zone ends, labelled "Calm zone ends" the first few times it
/// shows (the same stored count as PowerGauge, so the label stops for good after three showings on either layout). No
/// minus or plus: a drag on the bar or a pull-back on the table sets power. For VoiceOver the whole bar is one
/// adjustable element: a tenth of the range per swipe, a lesson band's third when that is finer.
struct PhonePowerBar: View {
    let model: ShowpieceModel
    var open: ShotControls = .all
    var zones: LessonZones? = nil
    /// 0.7.10 strike: a tap on the swing figure (and a VoiceOver action) opens the strike panel; nil: plain figure.
    var onFigureTap: (() -> Void)? = nil
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .body) private var barHeight: CGFloat = 12
    @ScaledMetric(relativeTo: .caption2) private var calmLineHeight: CGFloat = 14
    @AppStorage(PowerGauge.calmLabelKey) private var calmLabelShows = 0
    /// True while this showing of the bar labels the calm mark; decided once per appearance, never while drawing.
    @State private var labelsCalm = false
    @State private var calmLabelWidth: CGFloat = 0

    /// The hard end of the bar: the same warm red as PowerGauge's.
    private static let hot = Color(red: 1.0, green: 0.30, blue: 0.25)
    /// Power change per VoiceOver swipe outside a lesson band: a tenth of the range (PowerGauge's adjust step).
    private static let adjustStep = 0.1

    var body: some View {
        let fraction = model.powerFraction
        let calm = calmFraction
        let warm = model.activePower > model.strokeZones.calmTopPower
        VStack(alignment: .leading, spacing: 6) {
            figureRow
            bar(fraction: fraction, calm: calm)
            // The calm mark's label, the first few showings; at the accessibility sizes the mark alone (the words
            // would be wider than the bar).
            if labelsCalm, calm < 1, !typeSize.isAccessibilitySize { calmLabel(calm) }
        }
        .padding(.vertical, 4)
        .frame(minHeight: 44)
        .onAppear { noteCalmMark() }
        .onChange(of: calm < 1) { noteCalmMark() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Power"))
        .accessibilityValue(TableWords.joined(String(localized: "\(String(format: "%.0f", locale: AppLocale.numbers, fraction * 100)) percent, \(StrokeWords.spoken(power: model.activePower, racked: model.racked, warm: warm, cue: model.cueInHand))"),
                                              TableWords.powerBandLine(model, zones: zones)))
        .accessibilityAdjustableAction { direction in
            let swipe = min(Self.adjustStep, bandStep ?? Self.adjustStep)
            switch direction {
            case .increment: model.powerFraction += swipe
            case .decrement: model.powerFraction -= swipe
            @unknown default: break
            }
        }
        // 0.7.10 strike: the bar is one adjustable element, so the figure's button is offered as an action too.
        .accessibilityAction(named: Text(StrikeWords.liveHeading)) { onFigureTap?() }
        .disabled(!open.contains(.power))
        .lockedForStep(!open.contains(.power))
    }

    /// The swing figure and its caption. 0.7.10 strike: a button that opens the strike panel when onFigureTap is set,
    /// with a small chevron saying there is more behind it.
    @ViewBuilder private var figureRow: some View {
        let row = HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(verbatim: StrokeWords.swingFigure(power: model.activePower))
                .font(.system(.headline, design: .monospaced))
                .lineLimit(1)
                .fixedSize()
            Text(verbatim: StrokeWords.swingCaption(power: model.activePower, racked: model.racked,
                                                    cue: model.cueInHand))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if onFigureTap != nil {
                Image(systemName: "chevron.up.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        if let onFigureTap {
            Button(action: onFigureTap) { row.contentShape(Rectangle()) }
                .buttonStyle(.plain)
        } else {
            row
        }
    }

    private func bar(fraction: Double, calm: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(palette.track)
                // The gradient spans the whole bar and a capsule mask reveals the part below the power level, so the
                // fill warms as power rises.
                Capsule()
                    .fill(LinearGradient(colors: [palette.accent, palette.slide, Self.hot],
                                         startPoint: .leading, endPoint: .trailing))
                    .mask(alignment: .leading) {
                        Capsule().frame(width: max(barHeight, geo.size.width * fraction))
                    }
                // A lesson's target band: the stretch of the bar where the shot works.
                if let band = zones?.power {
                    let lo = share(band.lowerBound), hi = share(band.upperBound)
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(palette.paper.opacity(0.95 * (zones?.strength ?? 1)), lineWidth: 1.5)
                        .background(RoundedRectangle(cornerRadius: 3).fill(palette.paper.opacity(0.25 * (zones?.strength ?? 1))))
                        .frame(width: max(4, geo.size.width * (hi - lo)), height: barHeight + 6)
                        .offset(x: geo.size.width * lo)
                        .allowsHitTesting(false)
                }
                // Past the calm zone: a faint warm wash, and a thin mark where the calm zone ends.
                if calm < 1 {
                    Capsule()
                        .fill(Self.hot.opacity(0.16))
                        .frame(width: geo.size.width * (1 - calm))
                        .offset(x: geo.size.width * calm)
                        .allowsHitTesting(false)
                    Rectangle()
                        .fill(palette.paper.opacity(0.75))
                        .frame(width: 2, height: barHeight + 6)
                        .offset(x: geo.size.width * calm - 1)
                        .allowsHitTesting(false)
                }
            }
            // A generous touch area around the thin bar (at least 44 points tall with the inset).
            .contentShape(Rectangle().inset(by: -16))
            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                guard open.contains(.power) else { return }
                model.powerFraction = Double(value.location.x / max(1, geo.size.width))
            })
        }
        .frame(height: barHeight)
    }

    /// "Calm zone ends" centred under the mark, slid back inside the bar's width if it would hang over an end.
    private func calmLabel(_ calm: Double) -> some View {
        GeometryReader { geo in
            let markX = geo.size.width * calm
            let half = calmLabelWidth / 2
            Text("Calm zone ends")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .fixedSize()
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { calmLabelWidth = $0 }
                .position(x: min(max(markX, half), max(half, geo.size.width - half)), y: geo.size.height / 2)
        }
        .frame(height: calmLineHeight)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// As PowerGauge: label the mark only while it is on the bar, for the first few showings, counted once a showing.
    private func noteCalmMark() {
        guard !labelsCalm, calmFraction < 1, calmLabelShows < PowerGauge.calmLabelShowings else { return }
        labelsCalm = true
        calmLabelShows += 1
    }

    /// A launch speed as a share of the bar, 0 at its soft end, 1 at its hard end.
    private func share(_ speed: Double) -> CGFloat {
        let r = model.powerRange
        return CGFloat(min(max((speed - r.lowerBound) / (r.upperBound - r.lowerBound), 0), 1))
    }

    /// Where the calm zone ends on the bar, 0 to 1 (1: the whole bar is calm, so no mark is drawn).
    private var calmFraction: Double {
        let range = model.powerRange
        let top = model.strokeZones.calmTopPower
        return min(1, max(0, (top - range.lowerBound) / (range.upperBound - range.lowerBound)))
    }

    /// While a lesson marks a power band and power may change: a third of that band's share of the bar, so no single
    /// swipe can jump over the window (PowerGauge's bandStep). Nil with no band.
    private var bandStep: Double? {
        guard open.contains(.power), let band = zones?.power else { return nil }
        let width = Double(share(band.upperBound) - share(band.lowerBound))
        return width > 0 ? width / 3 : nil
    }
}
