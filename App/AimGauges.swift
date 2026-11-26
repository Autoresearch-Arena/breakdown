// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
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
            // Aiming panel redesign: the flat drawing, then its two millimetre figures under it, each printed once.
            let reading = StrikeReading.current(model)
            VStack(alignment: .leading, spacing: 10) {
                flatPicture(size: max(120, size ?? 148), comparison: reading?.comparison)
                millimetres(reading)
            }
        } else {
            picture
        }
    }

    /// The tip's height and side in millimetres under the big picture, typeable; after a shot the delivered figure
    /// follows the planned one with an arrow, in yellow, when the stroke moved it.
    @ViewBuilder
    private func millimetres(_ reading: StrikeReading.Reading?) -> some View {
        let c = reading?.comparison
        let up = model.activeTipUp, side = model.activeTipSide
        let deliveredUp = c.flatMap { $0.differs(.tipUp) ? $0.delivered.tipUp : nil }
        let deliveredSide = c.flatMap { $0.differs(.tipSide) ? $0.delivered.tipSide : nil }
        VStack(alignment: .leading, spacing: 6) {
            TypeableFigure(model: model, kind: .tipUp, spokenLabel: StrikeWords.tipUpLabel(up),
                           spokenValue: reading.map { StrikeSpoken.tile(.tipUp, $0, differs: deliveredUp != nil) }
                               ?? StrikeSpoken.millimetres(up)) {
                Readout(figure: StrikeWords.millimetresFigure(up), size: figureSize, role: .set,
                        editable: StrikeEntry.Kind.tipUp.isOpen(model),
                        trailing: StrikeWords.tipUpWord(deliveredUp ?? up),
                        delivered: deliveredUp.map(StrikeWords.millimetresFigure))
            }
            TypeableFigure(model: model, kind: .tipSide, spokenLabel: StrikeWords.tipSideLabel(side),
                           spokenValue: reading.map { StrikeSpoken.tile(.tipSide, $0, differs: deliveredSide != nil) }
                               ?? StrikeSpoken.millimetres(side)) {
                Readout(figure: StrikeWords.millimetresFigure(side), size: figureSize, role: .set,
                        editable: StrikeEntry.Kind.tipSide.isOpen(model),
                        trailing: StrikeWords.tipSideWord(deliveredSide ?? side),
                        delivered: deliveredSide.map(StrikeWords.millimetresFigure))
            }
        }
    }

    /// The big screens' picture: a flat technical drawing of the cue ball to scale. Rings every 5 mm (10 and 20
    /// labelled), a full crosshair, the dashed ring at the miscue limit, dotted leader lines from the axes to the
    /// handle, a lesson's band, and the kit's handle. After a shot that moved the tip: a hollow cyan ring where it was
    /// set, a yellow dot where it hit and a line between them.
    private func flatPicture(size: CGFloat, comparison c: StrikeComparison?) -> some View {
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
        let moved = c.map { $0.differs(.tipUp) || $0.differs(.tipSide) } ?? false
        let hit = c.map { spot(up: $0.delivered.tipUp, side: $0.delivered.tipSide) } ?? handle
        let accent = palette.accent, delta = palette.delta
        let handleSize = max(22, size * 0.12)
        return ZStack {
            Canvas { ctx, _ in
                let disc = Path(ellipseIn: CGRect(x: 0, y: 0, width: size, height: size))
                // A soft grey shade, no gloss: lighter toward the upper left, as a flat drawing hints the light.
                ctx.fill(disc, with: .radialGradient(Gradient(colors: [Color(white: 0.86), Color(white: 0.72)]),
                                                     center: CGPoint(x: radius * 0.8, y: radius * 0.7),
                                                     startRadius: 0, endRadius: radius * 1.25))
                ctx.stroke(disc, with: .color(.black.opacity(0.35)), lineWidth: 1)
                // Rings every 5 mm out to the ball's edge.
                var mm = 5.0
                while CGFloat(mm / 1000) * scale < radius - 1 {
                    let r = CGFloat(mm / 1000) * scale
                    ctx.stroke(Path(ellipseIn: CGRect(x: radius - r, y: radius - r, width: r * 2, height: r * 2)),
                               with: .color(.black.opacity(0.13)), lineWidth: 1)
                    mm += 5
                }
                // The full crosshair: where centre is.
                var cross = Path()
                cross.move(to: CGPoint(x: 0, y: radius)); cross.addLine(to: CGPoint(x: size, y: radius))
                cross.move(to: CGPoint(x: radius, y: 0)); cross.addLine(to: CGPoint(x: radius, y: size))
                ctx.stroke(cross, with: .color(.black.opacity(0.30)), lineWidth: 1)
                // 10 and 20 mm labelled on the horizontal axis, both sides.
                let labelSize = max(9, size * 0.05)
                for value in [10.0, 20.0] {
                    let r = CGFloat(value / 1000) * scale
                    guard r < radius - labelSize else { continue }
                    let text = Text(verbatim: StrikeWords.number(value, decimals: 0))
                        .font(.system(size: labelSize, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.black.opacity(0.55))
                    ctx.draw(text, at: CGPoint(x: radius + r, y: radius - labelSize * 0.8), anchor: .center)
                    ctx.draw(text, at: CGPoint(x: radius - r, y: radius - labelSize * 0.8), anchor: .center)
                }
                // The miscue ring: past it the tip slips.
                ctx.stroke(Path(ellipseIn: CGRect(x: radius - ring, y: radius - ring, width: ring * 2, height: ring * 2)),
                           with: .color(.black.opacity(0.55)), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                // Dotted leader lines from each axis to the handle, so its height and side read off the rings.
                var leaders = Path()
                leaders.move(to: CGPoint(x: handle.x, y: radius)); leaders.addLine(to: handle)
                leaders.move(to: CGPoint(x: radius, y: handle.y)); leaders.addLine(to: handle)
                ctx.stroke(leaders, with: .color(accent.opacity(0.9)),
                           style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [0.1, 4]))
                if moved {
                    // Planned (hollow ring) to delivered (solid yellow dot).
                    var line = Path()
                    line.move(to: handle); line.addLine(to: hit)
                    ctx.stroke(line, with: .color(delta), lineWidth: 1.5)
                }
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
            if moved {
                Circle().strokeBorder(palette.accent, lineWidth: 2.5)
                    .frame(width: handleSize, height: handleSize)
                    .position(handle)
                    .allowsHitTesting(false)
                Circle().fill(palette.delta)
                    .overlay(Circle().strokeBorder(Color.black.opacity(0.7), lineWidth: 1.5))
                    .frame(width: handleSize * 0.7, height: handleSize * 0.7)
                    .position(hit)
                    .allowsHitTesting(false)
            } else {
                InstrumentHandle(diameter: handleSize).position(handle)
            }
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
                .fill(RadialGradient(colors: [Color(white: 0.86), Color(white: 0.72)], center: .init(x: 0.4, y: 0.35),
                                     startRadius: 0, endRadius: radius * 1.25))
                .overlay(Circle().strokeBorder(.black.opacity(0.35), lineWidth: 1))
            // Cross hairs through the middle: where "centre" is.
            Path { p in
                p.move(to: CGPoint(x: 0, y: radius)); p.addLine(to: CGPoint(x: radius * 2, y: radius))
                p.move(to: CGPoint(x: radius, y: 0)); p.addLine(to: CGPoint(x: radius, y: radius * 2))
            }
            .stroke(.black.opacity(0.25), lineWidth: 1)
            Circle().strokeBorder(.black.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
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

// MARK: Power

struct PowerGauge: View {
    let model: ShowpieceModel
    /// Which controls are open (a lesson's guided tries close some).
    var open: ShotControls = .all
    /// The lesson's target bands, if any: the power band is drawn over the bar.
    var zones: LessonZones? = nil
    @Environment(\.palette) private var palette
    @ScaledMetric(relativeTo: .body) private var scaledBarHeight: CGFloat = 12
    /// 0.7.10 strike: iPad, Mac and the open folding phone (the notebook) draw a tall bar with no minus and plus.
    @Environment(\.inlinePages) private var roomy
    /// The bar's height: 12 points scaled with the text, or at least 28 on the big screens (plan stage 3 item 2), where
    /// it is big enough to drag and the strike panel's Swing tile takes exact values.
    private var barHeight: CGFloat { roomy ? max(Self.roomyBarHeight, scaledBarHeight) : scaledBarHeight }
    private static let roomyBarHeight: CGFloat = 28
    /// How many times the calm mark has been shown with its label (item 1). Stored on the device, so the label stops
    /// for good after the first few showings; the store-picture scripts can pin it (key in calmLabelKey).
    @AppStorage(PowerGauge.calmLabelKey) private var calmLabelShows = 0
    /// True while this showing of the gauge carries the label. Decided once per appearance (or when the mark first
    /// appears during one), never while the body is being drawn.
    @State private var labelsCalm = false
    /// The calm label's measured height, points (one caption2 line, or two when it wraps to the bar's width), so the
    /// room under the bar follows it (#53). Starts at one default line (defaultCalmLabelHeight).
    @State private var calmLabelHeight: CGFloat = 13.5
    @Environment(\.dynamicTypeSize) private var typeSize

    /// The stored count behind the calm mark's label.
    static let calmLabelKey = "calmMarkLabelShows"
    /// Showings of the calm mark that carry its label: enough for a newcomer to read it over the hand-over, the first
    /// break and the first shot after it (the first three times the shot panel shows the mark), after which the mark
    /// alone is familiar and the label would only take room from the panel.
    static let calmLabelShowings = 3

    /// Aiming panel redesign, the big screens: the swing figure's size, points (the layout picks it), and whether the
    /// "Swing" label sits on the figure's line (the Mac and the fold) or on its own line above it (the upright iPad).
    var figureSize: CGFloat = 26
    var labelInline = false

    var body: some View {
        if roomy {
            roomyBody
        } else {
            smallBody
        }
    }

    /// The phone's and the small layouts' bar, unchanged.
    @ViewBuilder private var smallBody: some View {
        let fraction = model.powerFraction
        let calm = calmFraction
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Power").font(Theme.label).foregroundStyle(.secondary)
                Spacer(minLength: 4)
                Text(StrokeWords.readout(power: model.activePower, racked: model.racked, cue: model.cueInHand))
                    .font(Theme.number)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            HStack(spacing: 6) {
                // One-finger power without a drag: a tap a step down, a tap a step up (accessibility plan, package 5).
                // 0.7.10 strike: not on the big screens, where the tall bar and the Swing tile do this.
                if !roomy { stepButton(-1, systemImage: "minus", label: "Less power") }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(palette.track)
                        // The gradient spans the whole bar and a capsule-shaped mask reveals the part below the power
                        // level, so the fill gets warmer as power rises instead of squashing the colours into the fill.
                        Capsule()
                            .fill(LinearGradient(colors: [palette.accent, palette.slide, Self.hot], startPoint: .leading, endPoint: .trailing))
                            .mask(alignment: .leading) { Capsule().frame(width: max(barHeight, geo.size.width * fraction)) }
                        // A lesson's target band: the stretch of the bar where the shot works.
                        if let band = zones?.power {
                            let lo = powerFraction(band.lowerBound), hi = powerFraction(band.upperBound)
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(palette.paper.opacity(0.95 * (zones?.strength ?? 1)), lineWidth: 1.5)
                                .background(RoundedRectangle(cornerRadius: 3).fill(palette.paper.opacity(0.25 * (zones?.strength ?? 1))))
                                .frame(width: max(4, geo.size.width * (hi - lo)), height: barHeight + 6)
                                .offset(x: geo.size.width * lo)
                                .allowsHitTesting(false)
                        }
                        // The warm zone: past the calm top a faint warm wash over the track, and a thin mark where the
                        // calm zone ends (the stroke plan: past it, a harder swing drifts more).
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
                    .contentShape(Rectangle().inset(by: -16))
                    .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                        guard open.contains(.power) else { return }
                        model.powerFraction = Double(value.location.x / max(1, geo.size.width))
                    })
                }
                .frame(height: barHeight)
                // The calm mark's label, the first few times the mark shows (item 1): a small caret under the mark and
                // "Calm zone ends" centred on it, slid back inside the bar if it would hang over an end. Laid over the
                // bar rather than in the layout, so it measures against the bar's own width and the bar and buttons stay
                // exactly where they always are.
                .overlay(alignment: .topLeading) {
                    if labelsCalm, calm < 1 {
                        GeometryReader { geo in
                            let markX = geo.size.width * calm
                            ZStack(alignment: .topLeading) {
                                Image(systemName: "arrowtriangle.up.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(.secondary)
                                    .offset(x: markX - 3, y: barHeight + 4)
                                // At the accessibility sizes the caret alone (0.7.6 #53): the words would be far
                                // wider than the bar and hang over the row below.
                                if !typeSize.isAccessibilitySize {
                                    Text("Calm zone ends")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        // Never wider than the bar (#53): a label longer than the bar wraps to a second
                                        // line instead of running past the plus button. Its height is measured, so the
                                        // room under the bar follows it.
                                        .fixedSize(horizontal: false, vertical: true)
                                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { calmLabelHeight = $0 }
                                        // The guide is minus the label's left edge: centred on the mark, then held
                                        // inside the bar's width.
                                        .alignmentGuide(.leading) { d in
                                            -min(max(markX - d.width / 2, 0), max(0, geo.size.width - d.width))
                                        }
                                        .offset(y: barHeight + 10)
                                }
                            }
                        }
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    }
                }
                if !roomy { stepButton(1, systemImage: "plus", label: "More power") }
            }
            // Room under the bar for the calm mark's label while it shows. The bar sits in the middle of the 44-point
            // step buttons, so the label first falls beside them; this keeps its lower half clear of whatever the shot
            // panel puts under the gauge.
            if labelsCalm, calm < 1, calmLabelRoom > 0 {
                Color.clear.frame(height: calmLabelRoom).accessibilityHidden(true)
            }
        }
        .padding(.vertical, 6)
        .frame(minHeight: 44)
        .onAppear { noteCalmMark() }
        .onChange(of: calm < 1) { noteCalmMark() }
        .modifier(PowerAccess(gauge: self))
    }

    // MARK: The big screens' bar (aiming panel redesign)

    /// The swing range the bar spans, metres per second: the swing of the soft end and of the hard end (the cue's top
    /// swing), from the cue profile, as the typed entry's range is.
    private var swingRange: ClosedRange<Double> {
        let r = model.powerRange
        return CueProfile.swing(forPower: r.lowerBound)...CueProfile.swing(forPower: r.upperBound)
    }

    /// A swing as a share of the bar.
    private func swingFraction(_ swing: Double) -> CGFloat {
        let r = swingRange
        return CGFloat(min(max((swing - r.lowerBound) / max(0.0001, r.upperBound - r.lowerBound), 0), 1))
    }

    private var roomyBarHeightNow: CGFloat {
        #if os(macOS)
        return 40
        #else
        return 48
        #endif
    }

    /// The Swing figure (typeable) with its zone word, the bar with its calm mark and label, and the m/s scale.
    @ViewBuilder private var roomyBody: some View {
        let reading = StrikeReading.current(model)
        let c = reading?.comparison
        let swing = CueProfile.swing(forPower: model.activePower)
        let word = PowerWords.word(speed: model.cueInHand.launchSpeed(forPower: model.activePower), racked: model.racked)
        VStack(alignment: .leading, spacing: 6) {
            Group {
                if labelInline {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        swingLabel
                        swingFigure(swing, reading)
                        zoneWords(word, c)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        swingLabel
                        HStack(alignment: .firstTextBaseline, spacing: 18) {
                            swingFigure(swing, reading)
                            zoneWords(word, c)
                        }
                    }
                }
            }
            .lineLimit(1)
            VStack(alignment: .leading, spacing: 4) {
                // Upright iPad: the calm label on its own line over the bar; Mac and fold: inside the hatch.
                if !labelInline { calmLabelRow }
                roomyBar(delivered: c?.delivered.swing)
                    .overlay(alignment: .leading) { if labelInline { calmLabelInside } }
                scale
            }
            .modifier(PowerAccess(gauge: self))
        }
        .onAppear { noteCalmMark() }
        .onChange(of: calmFraction < 1) { noteCalmMark() }
    }

    private var swingLabel: some View {
        Text(verbatim: StrikeWords.swingLabel)
            .font(.system(size: max(13, figureSize * 0.55), weight: .semibold))
            .foregroundStyle(.secondary)
    }

    private func swingFigure(_ swing: Double, _ reading: StrikeReading.Reading?) -> some View {
        let moved = reading?.comparison?.differs(.swing) == true
        return TypeableFigure(model: model, kind: .swing, spokenLabel: StrikeWords.swingLabel,
                              spokenValue: reading.map { StrikeSpoken.tile(.swing, $0, differs: moved) }
                                  ?? StrikeSpoken.speed(swing)) {
            FigureLine(figure: StrikeWords.speedFigure(swing), size: figureSize, role: .set,
                       editable: StrikeEntry.Kind.swing.isOpen(model))
                .padding(.bottom, 4)
        }
    }

    /// The zone word ("firm"), and after a shot "as planned" or the delta chip.
    @ViewBuilder private func zoneWords(_ word: String, _ c: StrikeComparison?) -> some View {
        Text(verbatim: c == nil || c?.differs(.swing) == true ? word : word + " · " + StrikeWords.asPlanned)
            .font(.system(size: max(13, figureSize * 0.55)))
            .foregroundStyle(.secondary)
            .layoutPriority(-1)
        if let c, c.differs(.swing) {
            DeltaChip(text: StrikeWords.deltaChip(StrikeWords.signed(c.delivered.swing - c.planned.swing, decimals: 2),
                                                  planned: StrikeWords.number(c.planned.swing, decimals: 2)))
        }
    }

    /// The calm label inside the hatch past the mark (the Mac and the fold, where height is short); left out when the
    /// hatch is narrower than the words.
    private var calmLabelInside: some View {
        GeometryReader { geo in
            let calm = calmFraction
            let room = geo.size.width * (1 - calm) - 24
            if labelsCalm, calm < 1, !typeSize.isAccessibilitySize {
                ViewThatFits(in: .horizontal) {
                    Text(verbatim: StrikeWords.calmLimit(model.strokeZones.calmTopSwing))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .fixedSize()
                    Color.clear.frame(width: 0)
                }
                .frame(width: max(0, room), alignment: .leading)
                .frame(maxHeight: .infinity)
                .offset(x: geo.size.width * calm + 12)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// "calm limit 3.5 m/s" over the bar, starting at the mark, while this showing labels it (the count is unchanged:
    /// the first few showings, calmLabelShowings); otherwise an empty line of the same height so the bar never moves.
    private var calmLabelRow: some View {
        GeometryReader { geo in
            let calm = calmFraction
            let barWidth = geo.size.width
            if labelsCalm, calm < 1, !typeSize.isAccessibilitySize {
                Text(verbatim: StrikeWords.calmLimit(model.strokeZones.calmTopSwing))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize()
                    .alignmentGuide(.leading) { d in
                        // Starts just past the mark, slid back inside the bar if it would run off its end.
                        -min(barWidth * calm + 8, max(0, barWidth - d.width))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(height: 18)
        .accessibilityHidden(true)
    }

    /// The bar: the track, the hatch past the calm mark, the cyan fill, a lesson's band, the calm mark, the delivered
    /// tick after a shot, and the white handle at the fill's end. Dragged anywhere to set the swing.
    private func roomyBar(delivered: Double?) -> some View {
        let height = roomyBarHeightNow
        let fraction = CGFloat(model.powerFraction)
        let calm = CGFloat(calmFraction)
        return GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.07))
                // Past the calm mark: a quiet grey hatch (a harder swing drifts more there).
                if calm < 1 {
                    Canvas { ctx, size in
                        var stripes = Path()
                        var x = -size.height
                        while x < size.width {
                            stripes.move(to: CGPoint(x: x, y: size.height)); stripes.addLine(to: CGPoint(x: x + size.height, y: 0))
                            x += 9
                        }
                        ctx.stroke(stripes, with: .color(.white.opacity(0.10)), lineWidth: 1.5)
                    }
                    .frame(width: w * (1 - calm), height: height)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0,
                                                      bottomTrailingRadius: height / 2, topTrailingRadius: height / 2))
                    .offset(x: w * calm)
                    .allowsHitTesting(false)
                }
                Capsule()
                    .fill(palette.accent)
                    .frame(width: max(height, w * fraction))
                // A lesson's target band: the stretch of the bar where the shot works.
                if let band = zones?.power {
                    let lo = powerFraction(band.lowerBound), hi = powerFraction(band.upperBound)
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(palette.paper.opacity(0.95 * (zones?.strength ?? 1)), lineWidth: 1.5)
                        .background(RoundedRectangle(cornerRadius: 4).fill(palette.paper.opacity(0.25 * (zones?.strength ?? 1))))
                        .frame(width: max(4, w * (hi - lo)), height: height + 6)
                        .offset(x: w * lo)
                        .allowsHitTesting(false)
                }
                if calm < 1 {
                    Rectangle()
                        .fill(palette.paper.opacity(0.85))
                        .frame(width: 2, height: height + 10)
                        .offset(x: w * calm - 1)
                        .allowsHitTesting(false)
                }
                if let delivered {
                    // Where the stroke's swing landed, in yellow, after a shot.
                    Rectangle()
                        .fill(palette.delta)
                        .frame(width: 3, height: height + 8)
                        .offset(x: w * swingFraction(delivered) - 1.5)
                        .allowsHitTesting(false)
                }
                InstrumentHandle(diameter: height * 0.9, style: .paper)
                    .position(x: min(max(w * fraction - height / 2, height / 2), w - height / 2), y: height / 2)
            }
            .frame(height: height)
            .contentShape(Rectangle().inset(by: -10))
            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                guard open.contains(.power) else { return }
                model.powerFraction = Double(value.location.x / max(1, w))
            })
        }
        .frame(height: height)
    }

    /// The whole-number m/s scale under the bar, from the soft end to the cue's top swing, the unit after the last.
    private var scale: some View {
        let r = swingRange
        let marks = Array(Int(r.lowerBound.rounded(.up))...max(Int(r.lowerBound.rounded(.up)), Int(r.upperBound.rounded(.down))))
        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(marks, id: \.self) { n in
                    let scaleWidth = geo.size.width
                    let x = scaleWidth * swingFraction(Double(n))
                    let last = n == marks.last
                    VStack(spacing: 2) {
                        Rectangle().fill(Color.secondary.opacity(0.7)).frame(width: 1, height: 6)
                        Text(verbatim: last ? "\(StrikeWords.number(Double(n), decimals: 0)) \(UnitSymbol.shown("m/s"))"
                                            : StrikeWords.number(Double(n), decimals: 0))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .fixedSize()
                    }
                    // Centred on its mark; the first and last held inside the bar's width.
                    .alignmentGuide(.leading) { d in
                        -min(max(x - d.width / 2, 0), max(0, scaleWidth - d.width))
                    }
                }
            }
        }
        .frame(height: 20)
        .accessibilityHidden(true)
    }
}

/// The power bar's VoiceOver element, help and lock, shared by the small and the big bar.
private struct PowerAccess: ViewModifier {
    let gauge: PowerGauge

    func body(content: Content) -> some View {
        gauge.accessible(content)
    }
}

extension PowerGauge {
    /// One adjustable VoiceOver element: the swing in a word and in metres per second, and the lesson's band.
    fileprivate func accessible<Content: View>(_ content: Content) -> some View {
        let fraction = model.powerFraction
        let warm = model.activePower > model.strokeZones.calmTopPower
        return content
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Power")
        // The lesson's power band, when one is marked, after the value (access stream hook, 0.7.0 item 46).
        .accessibilityValue(TableWords.joined(String(localized: "\(String(format: "%.0f", locale: AppLocale.numbers, fraction * 100)) percent, \(StrokeWords.spoken(power: model.activePower, racked: model.racked, warm: warm, cue: model.cueInHand))"),
                                              TableWords.powerBandLine(model, zones: zones)))
        .accessibilityAdjustableAction { direction in
            // A tenth of the bar per swipe, or the lesson band's finer step while one is up (see tapStep).
            let swipe = min(Self.adjustStep, bandStep ?? Self.adjustStep)
            switch direction {
            case .increment: model.powerFraction += swipe
            case .decrement: model.powerFraction -= swipe
            @unknown default: break
            }
        }
        .help(Text(verbatim: StrokeWords.ballReadout(power: model.activePower, racked: model.racked, cue: model.cueInHand) + " · "
                   + String(localized: "Cue: \(model.cueInHand.name). Pull back from the cue ball on the table, or drag here.")))
        .disabled(!open.contains(.power))
        .lockedForStep(!open.contains(.power))
    }

    /// Decide whether this showing of the gauge labels the calm mark: only while the mark is on the bar, only for the
    /// first calmLabelShowings showings, and counted once per showing. Called from onAppear and when the mark first
    /// appears (a break hands over to a shot, whose calm zone ends inside the bar), never from the body itself.
    private func noteCalmMark() {
        guard !labelsCalm, calmFraction < 1, calmLabelShows < Self.calmLabelShowings else { return }
        labelsCalm = true
        calmLabelShows += 1
    }

    /// Extra height under the bar row while the calm label shows, points. At the default text size the label's line
    /// (caption2, about 13 points tall) starts 10 points below the bar's lower edge, and that edge is 16 points above
    /// the 44-point buttons' lower edge, so the line runs about 7 points past the row; 8 points here plus the stack's
    /// own 6-point gap keeps it inside the gauge (calmLabelRoomAtDefault).
    /// Since 0.7.6 (#53) the room follows the real sizes instead of that fixed sum: a taller bar (barHeight is scaled
    /// with the text, and its lower edge drops by half of any growth) and a taller label (larger text, or a second
    /// line when it wraps to the bar's width) each add what they add. At the accessibility sizes only the caret shows,
    /// which sits inside the row unless the bar has grown past half the buttons' height.
    private var calmLabelRoom: CGFloat {
        let barGrowth = (barHeight - Self.defaultBarHeight) / 2
        if typeSize.isAccessibilitySize {
            // The caret: about 6 points tall, 4 below the bar; at the default size it ends 6 points above the row's
            // lower edge, so it needs room only once the bar has grown more than that (less the stack's gap).
            return max(0, barGrowth - 6 - 6 + 2)
        }
        let labelGrowth = max(0, calmLabelHeight - Self.defaultCalmLabelHeight)
        return max(0, Self.calmLabelRoomAtDefault + barGrowth + labelGrowth)
    }

    /// The fixed room the label was given at the default text size, and the bar and label heights it was worked out
    /// for (barHeight's own default, a caption2 line).
    private static let calmLabelRoomAtDefault: CGFloat = 8
    private static let defaultBarHeight: CGFloat = 12
    private static let defaultCalmLabelHeight: CGFloat = 13.5

    /// A launch speed as a share of the bar, 0 at its soft end, 1 at its hard end (the gauge's own fraction).
    private func powerFraction(_ speed: Double) -> CGFloat {
        let r = model.powerRange
        return CGFloat(min(max((speed - r.lowerBound) / (r.upperBound - r.lowerBound), 0), 1))
    }

    /// Where the calm zone ends on the bar, 0 to 1 (1: the whole bar is calm, so no mark is drawn).
    private var calmFraction: Double {
        let range = model.powerRange
        let top = model.strokeZones.calmTopPower
        return min(1, max(0, (top - range.lowerBound) / (range.upperBound - range.lowerBound)))
    }

    /// The hard end of the bar: a warm red that still reads on glass.
    private static let hot = Color(red: 1.0, green: 0.30, blue: 0.25)

    /// Power change per tap of the step buttons: a twentieth of the range, fine enough to set a soft roll by
    /// tapping and coarse enough to cross the bar in a handful of taps.
    private static let tapStep = 0.05
    /// Power change per VoiceOver swipe outside a lesson band: a tenth of the range, so the bar is crossed in ten swipes.
    private static let adjustStep = 0.1

    /// While a lesson marks a power band and power may change: a third of that band's share of the bar, so at least
    /// three taps land inside it and no single tap can jump from one side of the window to the other (the follow
    /// lesson's window is narrower than the usual step, finding 60). Nil with no band, or a band of no width.
    private var bandStep: Double? {
        guard open.contains(.power), let band = zones?.power else { return nil }
        let width = Double(powerFraction(band.upperBound) - powerFraction(band.lowerBound))
        return width > 0 ? width / 3 : nil
    }

    /// A small round minus or plus button beside the bar (`direction` -1 or +1). Each tap is one step, the usual step
    /// or a lesson band's finer one, whichever is smaller; nothing repeats while held.
    private func stepButton(_ direction: Double, systemImage: String, label: LocalizedStringKey) -> some View {
        Button { model.powerFraction += direction * min(Self.tapStep, bandStep ?? Self.tapStep) } label: {
            Image(systemName: systemImage).font(Theme.label).frame(width: 30, height: 30)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .controlSize(.regular)   // 30 points plus the bordered circle lands on 44 or more (as ShotPanel's nudge buttons)
        .help(Text(label))
        // The whole gauge is one adjustable element for VoiceOver already; these are for touch and pointer.
        .accessibilityHidden(true)
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
                    Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.secondary).accessibilityHidden(true)
                }
                .accessibilityHint(String(localized: "Locked for this step"))
        } else {
            self
        }
    }
}
