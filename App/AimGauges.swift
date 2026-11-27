// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 4, the shot console: PowerGauge is now a thin
//          wrapper over the kit's SwingBar on every layout (the big bar on iPad, Mac and the open folding phone, the
//          phone bar with its minus and plus in the small layouts), so the swing bar is one design everywhere; its
//          statics (calmLabelKey, calmLabelShowings, labelledMarks) stay for their callers. The tip picture shows only
//          the live tip: the planned-to-delivered ring, dot and arrow figures moved to the "Last shot" card. The cue
//          ball's own greys and ink are named once (CueBallInk) and the figures take the kit's tokens.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2: the swing bar's warm stretch is gold, not the
//          sliding magenta.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 1: the swing scale labels thin out by width so no
//          two touch; the upright iPad printed "11 12" as "1112".)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 strike, plans/25-Nov-2026-strike-panel-and-controls-plan.md
//          stage 3 items 1 and 2: in the notebook (iPad, Mac, the open folding phone) the tip picture is at least 132
//          points with the millimetres beside it, and the power bar is at least 28 points tall with no minus and plus.
//          The phone and the small layouts are unchanged.)
// Edited: Claude Haiku 5.5 High, 20-November-2026 (player-facing words wrapped for translation: String(localized:) so they reach the string catalog, and numbers formatted for the player's language).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the power readout and its spoken value carry a plain word before the
//          number, soft to hard or break, from PowerWords).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the tip travel is the model's own model.tipLimit, an instance value
//          per mode, in place of the old fixed ShowpieceModel.tipLimit.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (accessibility plan, package 5: minus and plus buttons beside the
//          power bar, so power can be set with single taps instead of a drag or a pull-back.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (lessons: both gauges take the open controls and the lesson's target
//          bands (ShotControls, LessonZones from Lessons.swift). A band is drawn where the shot works: across the cue-ball
//          picture for tip height, down it for side, a rectangle for both, and a stretch of the power bar. A locked
//          control is dimmed, shows a lock and tells VoiceOver "Locked for this step" (lockedForStep, shared with the
//          shot panel's sliders and the cue-angle menu). The model refuses the change anyway; this is what is seen.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (stroke stream: the power bar shows the swing ("firm · swing 2.6 m/s",
//          StrokeWords) with the ball's speed spoken and in the help; a calm zone and a warm zone on the bar, a mark at
//          the calm zone's top (model.strokeZones, which moves with the bridge finger) and the warm part tinted, so
//          the player sees where a harder swing starts to cost control.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (proof plan package 4: the cue-ball picture is to scale, so the dot's
//          reach and the dashed miscue ring sit where the default physics puts them: the ring at the miscue limit,
//          about half the radius, the dot a tenth of the radius beyond it.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, gauges-pointer stream, items 1 and 11 of
//          plans/21-Nov-2026-bugs-after-0-6-6-plan.md: the power bar's calm mark carries a short label, "Calm zone ends",
//          the first three times the mark shows, so the white line is explained where it is seen. While a lesson marks a
//          tip band, the centre snap is off (it swallowed part of the stop band) and a dot let go inside a band, or
//          touching it, settles on the band's middle, so a band narrower than the dot can still be hit. While a lesson
//          marks a power band, a tap of minus or plus (and a VoiceOver adjust) moves a third of that band, never more
//          than the usual step, so the window cannot be stepped over. The help names the cue in hand (model.cueInHand).)
// Edited: Claude Opus 5.5 High, 21-November-2026 (access stream hooks, 0.7.0 item 46: the tip picture's spoken value, band status and actions
//          come from TipAccessActions, and the power value adds the lesson's band, TableWords.powerBandLine.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 gaps, item 57: the power readout, its spoken value and the
//          help's ball speed are worked out for the cue the game picked (model.cueInHand), the cue the help names.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 learn-modes stream, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          item 5: the tip picture snaps each axis to its centre line on its own (side within about 1.5 mm of zero
//          becomes exactly zero while the height stays free, and the other way round), never on an axis a lesson marks.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream aim, plans/22-Nov-2026-phone-bug-hunt.md #53: the calm
//          mark's label wraps to the bar's width instead of running past the plus button, the room kept under the bar
//          follows the bar's and the label's real heights instead of a fixed 8 points, and at the accessibility text
//          sizes only the caret shows, so the label never hangs over the panel's next row.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (aiming panel redesign, plans/26-Nov-2026-aiming-panel-redesign-plan.md
//          step 5: on the big screens the tip picture is a flat technical drawing at the size the layout hands it (rings
//          every 5 mm with 10 and 20 labelled, a full crosshair, the dashed miscue ring, dotted leader lines from the
//          axes to the handle), with the instrument kit's handle and its two millimetre figures under it (typeable,
//          dotted underline); after a shot a hollow ring at the planned spot, a yellow dot where the tip hit and a line
//          between, and the figures read "10.0 → 14.0 mm below". The power bar on the big screens (RoomyPowerBar) is a
//          48-point bar (40 on the Mac) with a cyan fill, the white handle, a quiet hatch past the calm mark, the mark
//          labelled "calm limit" with its figure, a whole-number m/s scale under it up to the cue's top swing, the
//          Swing figure (typeable) and its zone word above it, and a yellow tick at the delivered swing after a shot.
//          The small "draw, −10.0 mm" and "firm · swing 2.4 m/s" lines are gone there, so each figure is printed once.
//          The phone's small picture takes the flat look and the kit's handle; its bar is unchanged.)
// PURPOSE: The two small gauges beside the table in the shot panel. TipPicker is a picture of the cue ball: touch or
//          drag on it to place the cue tip (up for follow, down for draw, left and right for side spin), with a faint
//          ring marking how far from the middle the tip can go before the cue would slip off. PowerGauge is a bar
//          that shows the strike power as a number and a fill; it moves while the player pulls back on the table, and
//          it can also be touched or dragged directly. Both write only the model's "active" values (break values while
//          the balls are racked, shot values afterwards), so the sliders in the fine-controls sheet and these gauges
//          always agree. Both are 44 points or more in every direction, scale with the text size, and speak a value
//          and offer actions to VoiceOver, so they are usable without touching the picture.
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (numbers are written in the game's own language, AppLocale.numbers
//          in NumberStyle.swift: French and German get "6,7" even on a phone set to another region.)
// SRP/DRY check: Pass - checked ShotPanel's slider rows, which stay as the accessible fallback; these are the new
//          touch-first versions of the same three values (power, tip height, tip side), not a second copy of the logic.
import SwiftUI

// MARK: Cue ball picture

struct TipPicker: View {
    let model: ShowpieceModel
    /// Which controls are open (a lesson's guided tries close some); tip height and side are this picture's two.
    var open: ShotControls = .all
    /// The lesson's target bands, if any: tip height across, side down.
    var zones: LessonZones? = nil
    @Environment(\.palette) private var palette
    @ScaledMetric(relativeTo: .body) private var side: CGFloat = 52
    /// 0.7.10 strike: iPad, Mac and the open folding phone (the notebook) draw the picture large, with the millimetres.
    @Environment(\.inlinePages) private var roomy

    /// The picture is the cue ball to scale. The dot travels as far as the mode's tip travel (model.tipLimit) as a
    /// share of the ball's radius, and the dashed ring sits at the miscue limit (model.miscueLimit), where the tip slips
    /// on the default physics: about half the radius, a little inside the dot's reach.
    private func share(_ metres: Double) -> CGFloat {
        CGFloat(min(max(metres / model.cueBallRadius, 0.1), 0.95))
    }

    /// The picture's side on the big screens, handed in by the shot panel's layout (nil: the panel's own minimum).
    var size: CGFloat? = nil
    /// The millimetre figures' size on the big screens, points (the layout picks it, scaled with the text there).
    var figureSize: CGFloat = 26

    var body: some View {
        if roomy {
            // Aiming panel redesign: the flat drawing and its two millimetre figures, each printed once: under the
            // picture, or beside it with the control's name over them (the console's narrow column).
            let reading = StrikeReading.current(model)
            let layout = figuresBeside ? AnyLayout(HStackLayout(alignment: .top, spacing: Theme.Space.sm))
                                       : AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Space.sm))
            layout {
                flatPicture(size: max(88, size ?? 148))
                if showsFigures {
                    VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                        if figuresBeside {
                            Text(verbatim: String(localized: "Tip"))
                                .font(Theme.label)
                                .foregroundStyle(palette.paper2)
                                .accessibilityHidden(true)
                        }
                        millimetres(reading)
                    }
                }
            }
        } else {
            picture
        }
    }

    /// UI rethink package 4: the first minute shows the picture alone (the calm console), no figures with it.
    var showsFigures = true
    /// UI rethink package 4: the figures beside the picture with "Tip" over them, instead of under it.
    var figuresBeside = false

    /// The tip's height and side in millimetres under the big picture, typeable. UI rethink package 4: always the live
    /// tip; what the stroke delivered is in the "Last shot" card, never here.
    @ViewBuilder
    private func millimetres(_ reading: StrikeReading.Reading?) -> some View {
        let up = model.activeTipUp, side = model.activeTipSide
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            TypeableFigure(model: model, kind: .tipUp, spokenLabel: StrikeWords.tipUpLabel(up),
                           spokenValue: StrikeSpoken.millimetres(up)) {
                Readout(figure: StrikeWords.millimetresFigure(up), size: figureSize, role: .set,
                        editable: StrikeEntry.Kind.tipUp.isOpen(model),
                        trailing: StrikeWords.tipUpWord(up))
            }
            TypeableFigure(model: model, kind: .tipSide, spokenLabel: StrikeWords.tipSideLabel(side),
                           spokenValue: StrikeSpoken.millimetres(side)) {
                Readout(figure: StrikeWords.millimetresFigure(side), size: figureSize, role: .set,
                        editable: StrikeEntry.Kind.tipSide.isOpen(model),
                        trailing: StrikeWords.tipSideWord(side))
            }
        }
    }

    /// The big screens' picture: a flat technical drawing of the cue ball to scale. Rings every 5 mm (10 and 20
    /// labelled), a full crosshair, the dashed ring at the miscue limit, dotted leader lines from the axes to the
    /// handle, a lesson's band, and the kit's handle. UI rethink package 4: the live tip only; where the stroke's tip
    /// landed is drawn in the "Last shot" card's words, not here.
    private func flatPicture(size: CGFloat) -> some View {
        let radius = size / 2
        let limit = radius * share(model.tipLimit)
        let ring = radius * share(model.miscueLimit)
        // Points per metre on the ball's face.
        let scale = radius / CGFloat(model.cueBallRadius)
        let travel = model.tipLimit
        func spot(up: Double, side: Double) -> CGPoint {
            CGPoint(x: radius + CGFloat(side / travel) * limit, y: radius - CGFloat(up / travel) * limit)
        }
        let handle = spot(up: model.activeTipUp, side: model.activeTipSide)
        let accent = palette.accent
        let handleSize = max(22, size * 0.12)
        return ZStack {
            Canvas { ctx, _ in
                let disc = Path(ellipseIn: CGRect(x: 0, y: 0, width: size, height: size))
                // A soft grey shade, no gloss: lighter toward the upper left, as a flat drawing hints the light.
                ctx.fill(disc, with: .radialGradient(Gradient(colors: [CueBallInk.light, CueBallInk.shade]),
                                                     center: CGPoint(x: radius * 0.8, y: radius * 0.7),
                                                     startRadius: 0, endRadius: radius * 1.25))
                ctx.stroke(disc, with: .color(CueBallInk.ink.opacity(0.35)), lineWidth: 1)
                // Rings every 5 mm out to the ball's edge.
                var mm = 5.0
                while CGFloat(mm / 1000) * scale < radius - 1 {
                    let r = CGFloat(mm / 1000) * scale
                    ctx.stroke(Path(ellipseIn: CGRect(x: radius - r, y: radius - r, width: r * 2, height: r * 2)),
                               with: .color(CueBallInk.ink.opacity(0.13)), lineWidth: 1)
                    mm += 5
                }
                // The full crosshair: where centre is.
                var cross = Path()
                cross.move(to: CGPoint(x: 0, y: radius)); cross.addLine(to: CGPoint(x: size, y: radius))
                cross.move(to: CGPoint(x: radius, y: 0)); cross.addLine(to: CGPoint(x: radius, y: size))
                ctx.stroke(cross, with: .color(CueBallInk.ink.opacity(0.30)), lineWidth: 1)
                // 10 and 20 mm labelled on the horizontal axis, both sides.
                let labelSize = max(9, size * 0.05)
                for value in [10.0, 20.0] {
                    let r = CGFloat(value / 1000) * scale
                    guard r < radius - labelSize else { continue }
                    let text = Text(verbatim: StrikeWords.number(value, decimals: 0))
                        .font(Theme.figure(size: labelSize).weight(.medium))
                        .foregroundStyle(CueBallInk.ink.opacity(0.55))
                    ctx.draw(text, at: CGPoint(x: radius + r, y: radius - labelSize * 0.8), anchor: .center)
                    ctx.draw(text, at: CGPoint(x: radius - r, y: radius - labelSize * 0.8), anchor: .center)
                }
                // The miscue ring: past it the tip slips.
                ctx.stroke(Path(ellipseIn: CGRect(x: radius - ring, y: radius - ring, width: ring * 2, height: ring * 2)),
                           with: .color(CueBallInk.ink.opacity(0.55)), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                // Dotted leader lines from each axis to the handle, so its height and side read off the rings.
                var leaders = Path()
                leaders.move(to: CGPoint(x: handle.x, y: radius)); leaders.addLine(to: handle)
                leaders.move(to: CGPoint(x: radius, y: handle.y)); leaders.addLine(to: handle)
                ctx.stroke(leaders, with: .color(accent.opacity(0.9)),
                           style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [0.1, 4]))
            }
            .frame(width: size, height: size)
            // A lesson's target band: where on the cue ball the shot works, clipped to the reachable disc.
            if let band = tipBand(radius: radius, limit: limit) {
                Path(band)
                    .fill(palette.accent.opacity(0.30 * (zones?.strength ?? 1)))
                    .overlay { Path(band).stroke(palette.accent.opacity(0.9 * (zones?.strength ?? 1)), lineWidth: 1) }
                    .clipShape(Circle().inset(by: radius - limit))
                    .allowsHitTesting(false)
            }
            InstrumentHandle(diameter: handleSize).position(handle)
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .gesture(tipDrag(radius: radius, limit: limit, dot: handleSize))
        .modifier(TipPictureAccess(model: model, open: open, zones: zones, locked: !tipOpen))
    }

    /// The picture's side, points. On a phone it grows with text size for easy touching but stops at 72 points: past
    /// that it would crowd out the table.
    private var pictureSize: CGFloat { min(max(44, side), 72) }

    /// The chalked tip's drawn width on the phone's small picture, points.
    private var dot: CGFloat { Self.dot }

    @ViewBuilder private var picture: some View {
        let size = pictureSize
        let radius = size / 2
        let limit = radius * share(model.tipLimit)
        let ring = radius * share(model.miscueLimit)
        let up = model.activeTipUp / model.tipLimit
        let across = model.activeTipSide / model.tipLimit
        ZStack {
            // Aiming panel redesign: the flat look (a soft grey shade, no gloss), as the big picture.
            Circle()
                .fill(RadialGradient(colors: [CueBallInk.light, CueBallInk.shade], center: .init(x: 0.4, y: 0.35),
                                     startRadius: 0, endRadius: radius * 1.25))
                .overlay(Circle().strokeBorder(CueBallInk.ink.opacity(0.35), lineWidth: 1))
            // Cross hairs through the middle: where "centre" is.
            Path { p in
                p.move(to: CGPoint(x: 0, y: radius)); p.addLine(to: CGPoint(x: radius * 2, y: radius))
                p.move(to: CGPoint(x: radius, y: 0)); p.addLine(to: CGPoint(x: radius, y: radius * 2))
            }
            .stroke(CueBallInk.ink.opacity(0.25), lineWidth: 1)
            Circle().strokeBorder(CueBallInk.ink.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .frame(width: ring * 2, height: ring * 2)
            // A lesson's target band: where on the cue ball the shot works, clipped to the reachable disc.
            if let band = tipBand(radius: radius, limit: limit) {
                Path(band)
                    .fill(palette.accent.opacity(0.30 * (zones?.strength ?? 1)))
                    .overlay { Path(band).stroke(palette.accent.opacity(0.9 * (zones?.strength ?? 1)), lineWidth: 1) }
                    .clipShape(Circle().inset(by: radius - limit))
                    .allowsHitTesting(false)
            }
            // The chalked tip: the instrument kit's handle (aiming panel redesign).
            InstrumentHandle(diameter: dot)
                .offset(x: CGFloat(across) * limit, y: CGFloat(-up) * limit)
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .gesture(tipDrag(radius: radius, limit: limit, dot: dot))
        .modifier(TipPictureAccess(model: model, open: open, zones: zones, locked: !tipOpen))
    }

    /// The drag on either picture: the touch's place relative to the middle, as a share of the reachable disc.
    private func tipDrag(radius: CGFloat, limit: CGFloat, dot: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                // Locked in this lesson step: the touch does nothing (the model would refuse the change too).
                guard tipOpen else { return }
                // Touch position relative to the middle, as a fraction of the reachable disc, then clamped to the disc.
                var x = Double((value.location.x - radius) / limit)
                var y = Double(-(value.location.y - radius) / limit)
                let len = (x * x + y * y).squareRoot()
                if len > 1 { x /= len; y /= len }
                // A tiny region around the middle snaps to exactly centre so "centre" is easy to hit, but never while a
                // lesson marks a tip band: the stop band sits a couple of millimetres below centre, inside this region.
                if len < Self.centreSnap, !hasTipBand { x = 0; y = 0 }
                // Each axis also snaps to its centre line on its own (0.7.5): side within about 1.5 mm of zero becomes
                // exactly zero while the height stays where the finger is, and the same for height, so a plain draw or
                // follow carries no stray side (and a plain side no stray height). Not on an axis a lesson marks a band
                // on, where the band may sit just off the centre line.
                if abs(x) < Self.axisSnap, zones?.tipSide == nil { x = 0 }
                if abs(y) < Self.axisSnap, zones?.tipUp == nil { y = 0 }
                // Only the open one of the two moves when a lesson has opened just one: the other stays where it was set.
                if open.contains(.tipSide) { model.activeTipSide = x * model.tipLimit }
                if open.contains(.tipUp) { model.activeTipUp = y * model.tipLimit }
            }
            .onEnded { _ in
                guard tipOpen else { return }
                // The dot is drawn `dot` points wide; in metres of tip travel, half of that is how far outside a band
                // the dot's centre can be while the dot still visibly overlaps it.
                settleInBand(tolerance: Double(dot / 2 / max(1, limit)) * model.tipLimit)
            }
    }

    /// True when at least one of the picture's two values may change in this step.
    private var tipOpen: Bool { open.contains(.tipUp) || open.contains(.tipSide) }

    /// The chalked tip's drawn width, points: big enough to see under a fingertip's edge on the 52-point picture.
    private static let dot: CGFloat = 13
    /// The centre snap's reach, as a share of the dot's travel: about two millimetres of tip on the default physics,
    /// a fingertip's wobble on the picture, so "centre" is easy to hit outside a lesson band.
    private static let centreSnap = 0.12
    /// The per-axis snap's reach, as a share of the dot's travel (0.7.5): about 1.5 millimetres of tip on the default
    /// physics' travel, the wobble of a finger moving the dot straight up or down (or across) the picture.
    private static let axisSnap = 0.09

    /// True while the lesson marks a tip band (height, side or both).
    private var hasTipBand: Bool { zones?.tipUp != nil || zones?.tipSide != nil }

    /// A dot let go inside a lesson's tip band, or touching it (within `tolerance` metres), settles on the band's
    /// middle, for each banded value this step lets the player change. The bands are a few millimetres wide, narrower
    /// than the dot itself, so a finger that lands the dot on the band has done what the lesson asks; the middle is
    /// where the shot works best. A dot that ends off the band is left exactly where it was put.
    private func settleInBand(tolerance: Double) {
        guard let z = zones else { return }
        let upBand = open.contains(.tipUp) ? z.tipUp : nil
        let sideBand = open.contains(.tipSide) ? z.tipSide : nil
        guard upBand != nil || sideBand != nil else { return }
        func touches(_ value: Double, _ band: ClosedRange<Double>) -> Bool {
            value >= band.lowerBound - tolerance && value <= band.upperBound + tolerance
        }
        // Both marked values must be on their bands (a rectangle on the picture) before either moves.
        if let band = upBand, !touches(model.activeTipUp, band) { return }
        if let band = sideBand, !touches(model.activeTipSide, band) { return }
        if let band = upBand { model.activeTipUp = (band.lowerBound + band.upperBound) / 2 }
        if let band = sideBand { model.activeTipSide = (band.lowerBound + band.upperBound) / 2 }
    }

    /// The band to draw, in the picture's own points: the marked tip-height range across the whole ball, the marked
    /// side range down it, or the rectangle where both meet. Nil when nothing is marked.
    private func tipBand(radius: CGFloat, limit: CGFloat) -> CGRect? {
        guard let z = zones, z.tipUp != nil || z.tipSide != nil else { return nil }
        let travel = model.tipLimit
        // Metres to points: the dot moves `limit` points for `travel` metres; up is toward the top of the picture.
        func x(_ m: Double) -> CGFloat { radius + CGFloat(min(max(m / travel, -1), 1)) * limit }
        func y(_ m: Double) -> CGFloat { radius - CGFloat(min(max(m / travel, -1), 1)) * limit }
        let left = z.tipSide.map { x($0.lowerBound) } ?? 0
        let right = z.tipSide.map { x($0.upperBound) } ?? radius * 2
        let top = z.tipUp.map { y($0.upperBound) } ?? 0
        let bottom = z.tipUp.map { y($0.lowerBound) } ?? radius * 2
        return CGRect(x: left, y: top, width: max(1, right - left), height: max(1, bottom - top))
    }

    /// "follow, left" and so on; "centre" when the tip is in the middle.
    static func spoken(up: Double, side: Double) -> String {
        let v = up < -0.002 ? ShotPanel.shownWord("draw") : (up > 0.002 ? ShotPanel.shownWord("follow") : nil)
        let h = side < -0.002 ? ShotPanel.shownWord("left") : (side > 0.002 ? ShotPanel.shownWord("right") : nil)
        switch (v, h) {
        case (nil, nil): return ShotPanel.shownWord("centre")
        case let (v?, nil): return v
        case let (nil, h?): return h
        case let (v?, h?): return String(localized: "\(v), \(h)")
        }
    }
}

/// The tip picture's VoiceOver element, help and lock, shared by the big and the small picture.
private struct TipPictureAccess: ViewModifier {
    let model: ShowpieceModel
    let open: ShotControls
    let zones: LessonZones?
    let locked: Bool

    func body(content: Content) -> some View {
        content
            .accessibilityElement()
            .accessibilityLabel("Cue tip position")
            .accessibilityHint("Drag on the ball to place the tip. Or use the actions.")
            .accessibilityAddTraits(.allowsDirectInteraction)
            // Access stream hook (0.7.0 item 46): the spoken amount and band, fine steps, band-aware quick actions and
            // Into the marked band, none while locked (TableAccessLayer.swift).
            .modifier(TipAccessActions(model: model, open: open, zones: zones))
            .help("Cue tip: drag to choose follow, draw or side")
            .lockedForStep(locked)
    }
}

// MARK: The cue ball's own colours

/// The cue ball drawn to scale on the tip picture: a physical object, not interface chrome, so its greys and its dark
/// ink are the ball's own, named once here (UI rethink package 4).
enum CueBallInk {
    static let light = Color(white: 0.86)  // design-lint: allow the cue ball's own colour, drawn to scale
    static let shade = Color(white: 0.72)  // design-lint: allow the cue ball's own colour, drawn to scale
    static let dial = Color(white: 0.80)   // design-lint: allow the cue ball's own colour on the cue-angle dial
    static let ink = Color.black           // design-lint: allow the printed rings and figures on the cue ball
}

// MARK: Power

/// The swing control: the kit's SwingBar on every layout (UI rethink package 4). On iPad, Mac and the open folding phone
/// (the notebook's inline pages) the big bar, whose swing figure is typeable; in the small layouts (a phone turned
/// sideways, a small window) the phone bar with a minus and a plus beside it, so the swing can be set by single taps
/// (accessibility plan, package 5). The SwingBar draws the calm limit, the scale and the lesson's band, and is the one
/// VoiceOver element ("Power"); the inputs are the old gauge's.
struct PowerGauge: View {
    let model: ShowpieceModel
    /// Which controls are open (a lesson's guided tries close some).
    var open: ShotControls = .all
    /// The lesson's target bands, if any: the power band is drawn over the bar.
    var zones: LessonZones? = nil
    /// The layout it sits in; nil follows the inline pages (big on the notebook's screens, phone elsewhere).
    var device: Theme.Device? = nil
    @Environment(\.inlinePages) private var roomy

    /// The stored count behind the old calm mark's label (the upright phone's bar still counts its showings with it).
    static let calmLabelKey = "calmMarkLabelShows"
    /// Showings of the calm mark that carried its label on the old bars (read by the upright phone's bar).
    static let calmLabelShowings = 3

    private var resolved: Theme.Device { device ?? (roomy ? .big : .phone) }

    var body: some View {
        if resolved == .phone {
            HStack(alignment: .center, spacing: Theme.Space.xs) {
                stepButton(-1, systemImage: "minus", label: "Less power")
                // The planned-against-delivered tick stays off: the comparison lives in the "Last shot" card.
                SwingBar(model: model, open: open, zones: zones, device: .phone, showsDelivered: false)
                stepButton(1, systemImage: "plus", label: "More power")
            }
        } else {
            SwingBar(model: model, open: open, zones: zones, device: resolved, showsDelivered: false)
        }
    }

    /// The marks that carry a label at this width: the smallest step of one, two, five or ten that keeps neighbouring
    /// labels a label apart, plus the last mark, with any label crowding the last (which also carries the unit) dropped.
    /// `position` maps a mark to its x on the scale. Read by the kit's SwingBar.
    nonisolated static func labelledMarks(_ marks: [Int], width: CGFloat, position: (Int) -> CGFloat) -> Set<Int> {
        guard let first = marks.first, let last = marks.last else { return [] }
        // A two-digit label at the scale's caption size is about 15 points wide; keep a label's width clear between
        // neighbours, and the wider last label (number and unit) about 46 points from the one before it.
        let gap: CGFloat = 30, lastGap: CGFloat = 46
        let perUnit = marks.count > 1 ? abs(position(last) - position(first)) / CGFloat(last - first) : width
        let step = [1, 2, 5, 10].first { CGFloat($0) * perUnit >= gap } ?? 10
        var shown = Set(marks.filter { ($0 - first) % step == 0 })
        shown = shown.filter { $0 == last || abs(position(last) - position($0)) >= lastGap }
        shown.insert(last)
        return shown
    }

    /// Power change per tap of the step buttons: a twentieth of the range.
    private static let tapStep = 0.05

    /// While a lesson marks a power band and power may change: a third of that band's share of the bar, so no single
    /// tap can jump from one side of the window to the other. Nil with no band, or a band of no width.
    private var bandStep: Double? {
        guard open.contains(.power), let band = zones?.power else { return nil }
        let r = model.powerRange
        let width = (band.upperBound - band.lowerBound) / max(0.0001, r.upperBound - r.lowerBound)
        return width > 0 ? width / 3 : nil
    }

    /// A round minus or plus beside the phone bar (`direction` -1 or +1), one step a tap. Hidden from VoiceOver: the bar
    /// is one adjustable element already.
    private func stepButton(_ direction: Double, systemImage: String, label: LocalizedStringKey) -> some View {
        Button { model.powerFraction += direction * min(Self.tapStep, bandStep ?? Self.tapStep) } label: {
            Image(systemName: systemImage)
        }
        .buttonStyle(RoundStepButtonStyle())
        .help(Text(label))
        .disabled(!open.contains(.power))
        .accessibilityHidden(true)
    }
}

// MARK: A round step button

/// A round minus, plus or nudge button beside a control: the secondary button's surface in a circle (panel fill,
/// hairline rule edge, paper symbol), at least the 44-point hit size. Shared by the swing bar's steps and the fine
/// controls' aim nudges (UI rethink package 4).
struct RoundStepButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        RoundStepButtonBody(configuration: configuration)
    }
}

private struct RoundStepButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @Environment(\.palette) private var palette
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(Theme.label)
            .foregroundStyle(isEnabled ? palette.paper : palette.paper3)
            .frame(width: Theme.Size.minHit, height: Theme.Size.minHit)
            .background(palette.panel, in: Circle())
            .overlay(Circle().strokeBorder(palette.rule, lineWidth: Theme.Size.hairline))
            .contentShape(Circle())
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}

// MARK: Locked for this step

extension View {
    /// A shot control a lesson has locked for this step: dimmed, a small lock at its corner, and VoiceOver told why it
    /// does not respond. Used by the gauges here, the shot panel's sliders and the cue-angle menu.
    @ViewBuilder func lockedForStep(_ locked: Bool) -> some View {
        if locked {
            self.opacity(0.45)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "lock.fill").font(Theme.caption).foregroundStyle(.secondary).accessibilityHidden(true)
                }
                .accessibilityHint(String(localized: "Locked for this step"))
        } else {
            self
        }
    }
}
