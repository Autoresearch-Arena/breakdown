// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2: the lifted card's edge is cyan (selected) and the
//          drawn cue paper2; the sliding magenta means sliding only.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 model-flow, first minute: EquipmentCard draws nothing during
//          the first-launch hand-over, so no pulsing "Break cue picked" card sits beside the one instruction. The break
//          cue is still picked, and EquipmentRows.current is unchanged, since it also feeds the spoken stance line.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (access stream hook, 0.7.0 item 47: the card no longer announces the stance on every
//          change; VoiceOver hears it inside the aim's words and after a finished shot, TableWords.stanceLine.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream aim, plans/22-Nov-2026-phone-bug-hunt.md #44: inside the
//          shot panel the card keeps its room while Your shot is open (reservesRoom). Swinging the aim made the stance
//          row come and go, the panel grew and shrank by a row, and the table slid under the finger. Now the room is at
//          least one row and never shrinks while the panel is up; with nothing to say it is an empty faint plate. Not
//          during the first-launch hand-over, which still draws nothing here.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (phone UI plan, aiming panel step: the rows' drawing moved into
//          EquipmentRowList, so the upright phone's stance blurb (StrokePhoneBlurbs, StrokeViews.swift) draws the same
//          pictograms and lines without the card; EquipmentCard looks exactly as before.)
// PURPOSE: The reach ladder on screen (App/Stroke/Reach.swift), apart from the bridge mark on the cloth (BridgeRing,
//          placed by TableStage; AimOverlay's flat copy went in 0.7.6):
//          - EquipmentCard: the single equipment indicator. A small card beside the power and tip controls (inside the
//            shot panel on a phone, among the notebook's cards on big screens and the open Duo) with a flat pictogram
//            drawn in code and one plain line for each thing worth saying about how the next strike is played: the
//            stance when it is not a square one ("Stretch: one foot off the floor"), and a cue raised over a ball. A
//            square stance with a clear path shows nothing, so the screen stays clean. The first few times it appears
//            it pulses gently (counted on the device, never with Reduce Motion), and VoiceOver reads the same lines.
//            Its rows come from EquipmentRows.current, which also adds the automatic cue pick's row (the cue's name and
//            the reason) whenever the pick is not the house cue.
//          - StancePictogram: the flat pictograms, a side view of a figure at the rail for each rung, a cue raised
//            over a ball, and the picked cue at its angle over a ball, drawn with paths in a Canvas (no images), in the
//            dark palette.
//          - BridgeReadout: the bridge's length for the fine controls ("20 cm, automatic bridge"), spoken the same.
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 equipment, plan item 57: the card's cue row. When the game
//          picks a cue other than the house cue for the shot (the break cue, the jump cue, the massé cue), the card
//          names it in one line (StanceWords.cueLine) beside a pictogram of that cue at its angle, so the pick is
//          always said; it shows even with a square stance. The rest's pictogram is now the swan-neck rest the table
//          draws, and the bridge readout says "the rest" whenever the model uses it (model.restInUse).)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.2: the pictograms' cue and the card's outline take Palette.slide,
//          now magenta; one comment updated.)
// SRP/DRY check: Pass - checked StrokeViews (StrokeResultCard is the same small-card pattern, its glass card and fonts
//          reused), AimGauges (the panel's own controls; this card sits beside them, it does not change them) and
//          StanceWords (every line comes from there).
import BreakdownLensModel
import BreakdownRules
import SwiftUI

// MARK: The rows

/// One row of the equipment card: what its pictogram shows and its line.
struct EquipmentRow: Identifiable, Equatable {
    enum Picture: Equatable { case stance(Stance.Rung), raisedCue, cue(CueKind) }
    let id: String
    let picture: Picture
    let line: String
}

@MainActor
enum EquipmentRows {
    /// The rows for the strike being lined up, once the balls are at rest and the cue ball is down: the stance unless
    /// it is a square one, then the raised cue, then the cue the game picked when it is not the house cue (plan item
    /// 57: the pick is automatic and always said). Empty when there is nothing to say.
    static func current(_ model: ShowpieceModel) -> [EquipmentRow] {
        guard model.aimReady, !model.placingCueBall else { return [] }
        var rows: [EquipmentRow] = []
        if let stance = model.stance {
            if stance.rung != .normal {
                rows.append(EquipmentRow(id: "stance", picture: .stance(stance.rung),
                                         line: StanceWords.rungLine(stance.rung)))
            }
            if let ball = stance.raisedOver {
                rows.append(EquipmentRow(id: "raised", picture: .raisedCue,
                                         line: StanceWords.raisedLine(over: ball, kind: model.match?.rules.kind)))
            }
        }
        // The pick (model.cueChoice, from CueProfile.choice) follows the break, the cue's angle and the side, so the
        // row comes and goes as the player sets them; VoiceOver says its line with the rest of the card.
        let choice = model.cueChoice
        if let line = StanceWords.cueLine(choice) {
            rows.append(EquipmentRow(id: "cue", picture: .cue(choice.kind), line: line))
        }
        return rows
    }
}

// MARK: The card

struct EquipmentCard: View {
    let model: ShowpieceModel
    /// True inside the shot panel, which is already a glass card: the rows sit on a faint plate instead of a second
    /// glass card.
    var embedded = false
    /// True where the card's height reaches the table's framing (the shot panel under or beside the table): the card
    /// keeps its room while it is on screen, so the table does not slide as the stance row comes and goes with the aim
    /// (0.7.6 #44). The room is at least one row (oneRowRoom) and never shrinks while the card is up (keptHeight);
    /// with no rows an empty faint plate holds it.
    var reservesRoom = false
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// How many times the card has pulsed on this device; it stops after `pulseLimit`.
    @AppStorage("equipmentCardPulses") private var pulses = 0
    @State private var lifted = false
    /// The tallest the rows have been while this card has been up (reservesRoom only), points. It resets when the card
    /// leaves the screen, which is when the shot panel closes.
    @State private var keptHeight: CGFloat = 0
    /// One row's height inside the shot panel at the default text size, points: the 30-point pictogram or a line of
    /// body text, whichever is taller, plus the plate's padding. Scaled with the text.
    @ScaledMetric(relativeTo: .body) private var oneRowRoom: CGFloat = 42

    /// The card pulses the first three times it appears: enough to be noticed, then it simply shows.
    private static let pulseLimit = 3

    var body: some View {
        // The first minute (0.7.5): during the hand-over the player sees a racked table and one instruction, nothing
        // else. No rows means nothing is drawn, so onAppear never runs and no pulse is counted on the device; the cue
        // pick itself (model.cueChoice) is untouched and the break is still struck with the break cue.
        let handOver = model.openingStage == .handOver
        let rows = handOver ? [] : EquipmentRows.current(model)
        // The room kept while the card is up (reservesRoom, #44): never less than one row, never less than the rows
        // have been. Both branches below take exactly this height, so a row coming or going moves nothing.
        let room: CGFloat = reservesRoom && !handOver ? max(keptHeight, oneRowRoom) : 0
        if !rows.isEmpty {
            let spoken = rows.map(\.line).joined(separator: ". ")
            content(rows)
                // The rows' own height, measured before the kept room is applied, so the kept height only ever
                // follows what the rows needed (no feedback from the frame below).
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                    if reservesRoom, height > keptHeight { keptHeight = height }
                }
                .frame(minHeight: room, alignment: .top)
                .scaleEffect(lifted ? 1.035 : 1)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(spoken)
                // VoiceOver hears the stance inside the Aim element's words and after a finished shot
                // (TableWords.stanceLine), not as an announcement on every change, which talked over the aim
                // (access stream hook, 0.7.0 item 47).
                .onAppear { pulseIfNew() }
                .transition(.opacity)
        } else if room > 0 {
            // Nothing to say: the same room as an empty faint plate (the rows' plate without its outline), so the
            // panel keeps its height as the aim swings. Silent for VoiceOver.
            RoundedRectangle(cornerRadius: 14)
                .fill(palette.paper.opacity(0.03))
                .frame(maxWidth: .infinity)
                .frame(height: room)
                .accessibilityHidden(true)
                .transition(.opacity)
        }
    }

    @ViewBuilder private func content(_ rows: [EquipmentRow]) -> some View {
        let stack = EquipmentRowList(rows: rows)
            .frame(maxWidth: .infinity, alignment: .leading)
        if embedded {
            stack
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 14).fill(palette.paper.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(palette.accent.opacity(lifted ? 0.8 : 0.3), lineWidth: 1))
        } else {
            stack
                .glassCard(cornerRadius: 20, padding: 12)
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(palette.accent.opacity(lifted ? 0.8 : 0), lineWidth: 1.5))
        }
    }

    /// Count this appearance and, while the count is low, pulse twice: lift, settle, lift, settle. Reduce Motion
    /// counts it without moving anything.
    private func pulseIfNew() {
        guard pulses < Self.pulseLimit else { return }
        pulses += 1
        guard !reduceMotion else { return }
        Task { @MainActor in
            for _ in 0..<2 {
                withAnimation(.easeInOut(duration: 0.3)) { lifted = true }
                try? await Task.sleep(for: .milliseconds(320))
                withAnimation(.easeInOut(duration: 0.4)) { lifted = false }
                try? await Task.sleep(for: .milliseconds(450))
            }
        }
    }
}

// MARK: The rows, drawn

/// The equipment rows themselves: a pictogram and its line for each, with no plate or card around them. Drawn inside
/// EquipmentCard (on its plate or glass card) and inside the upright phone's stance blurb (StrokePhoneBlurbs), so both
/// show exactly the same pictures and words.
struct EquipmentRowList: View {
    let rows: [EquipmentRow]
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(rows) { row in
                HStack(spacing: 10) {
                    StancePictogram(picture: row.picture)
                        .frame(width: 44, height: 30)
                    Text(row.line)
                        .font(Theme.body)
                        .foregroundStyle(palette.paper)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: Pictograms

/// A flat side view drawn with paths: the table's edge on the right (its top and a leg), the floor, and a figure at the
/// rail in the rung's posture, the cue in the sliding magenta (Palette.slide). Coordinates are shares of the drawing's width and height,
/// (0, 0) top left; the table's top sits at 0.45 of the height and its rail's outer edge at 0.56 of the width.
struct StancePictogram: View {
    let picture: EquipmentRow.Picture
    @Environment(\.palette) private var palette

    var body: some View {
        Canvas { ctx, size in
            Self.draw(picture, in: &ctx, size: size, ink: palette.paper, cue: palette.paper2)
        }
        .accessibilityHidden(true)
    }

    static func draw(_ picture: EquipmentRow.Picture, in ctx: inout GraphicsContext, size: CGSize, ink: Color, cue: Color) {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * size.width, y: y * size.height) }
        let line = StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
        func stroke(_ points: [CGPoint], _ color: Color, dash: [CGFloat] = []) {
            var path = Path()
            path.addLines(points)
            var style = line
            style.dash = dash
            ctx.stroke(path, with: .color(color), style: style)
        }
        func head(_ c: CGPoint) {
            let r = size.height * 0.08
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(ink))
        }
        // The floor, and the table: its top from the rail's edge to the right, one leg. The cue pictures are close-ups
        // on the cloth, so their table runs the whole width and has no leg.
        let closeUp: Bool
        switch picture {
        case .raisedCue, .cue: closeUp = true
        case .stance: closeUp = false
        }
        stroke([p(0.02, 0.96), p(0.98, 0.96)], ink.opacity(0.25))
        let tableLeft: CGFloat = closeUp ? 0.02 : 0.56
        ctx.fill(Path(CGRect(x: tableLeft * size.width, y: 0.45 * size.height, width: (1 - tableLeft) * size.width,
                             height: 0.07 * size.height)), with: .color(ink.opacity(0.35)))
        if !closeUp { stroke([p(0.64, 0.52), p(0.64, 0.96)], ink.opacity(0.35)) }

        switch picture {
        case .stance(.normal):
            // Bent at the hips over the rail, both feet down.
            stroke([p(0.34, 0.95), p(0.42, 0.50), p(0.48, 0.95)], ink)
            stroke([p(0.42, 0.50), p(0.64, 0.33)], ink)
            stroke([p(0.64, 0.33), p(0.82, 0.43)], ink)
            head(p(0.72, 0.28))
            stroke([p(0.28, 0.46), p(0.98, 0.40)], cue)
        case .stance(.stretch):
            // Laid along the cue, one foot down, the other leg lifted behind as a counterweight.
            stroke([p(0.46, 0.95), p(0.52, 0.42), p(0.18, 0.36)], ink)
            stroke([p(0.52, 0.42), p(0.78, 0.34)], ink)
            stroke([p(0.78, 0.34), p(0.94, 0.43)], ink)
            head(p(0.86, 0.29))
            stroke([p(0.34, 0.40), p(0.99, 0.39)], cue)
        case .stance(.behindTheBack):
            // Upright, side-on to the table, the cue passing behind the back (dashed where the body hides it).
            stroke([p(0.38, 0.95), p(0.44, 0.55), p(0.50, 0.95)], ink)
            stroke([p(0.44, 0.55), p(0.46, 0.24)], ink)
            stroke([p(0.46, 0.26), p(0.70, 0.36), p(0.86, 0.43)], ink)
            stroke([p(0.46, 0.28), p(0.30, 0.46)], ink)
            head(p(0.47, 0.13))
            stroke([p(0.22, 0.50), p(0.38, 0.48)], cue)
            stroke([p(0.38, 0.48), p(0.52, 0.46)], cue, dash: [2, 3])
            stroke([p(0.52, 0.46), p(0.98, 0.41)], cue)
        case .stance(.sittingOnRail):
            // One hip up on the rail, a leg hanging to the floor, leaning out over the table.
            stroke([p(0.50, 0.95), p(0.50, 0.66), p(0.60, 0.44)], ink)
            stroke([p(0.60, 0.44), p(0.80, 0.30)], ink)
            stroke([p(0.80, 0.30), p(0.96, 0.43)], ink)
            head(p(0.88, 0.24))
            stroke([p(0.40, 0.38), p(0.99, 0.40)], cue)
        case .stance(.rest):
            // Standing tall, the cue carried on the swan-neck rest the table draws: its long handle low on the table,
            // feet near the far end, the neck reaching forward and up to a small V cradle under the cue.
            stroke([p(0.24, 0.95), p(0.30, 0.55), p(0.36, 0.95)], ink)
            stroke([p(0.30, 0.55), p(0.32, 0.24)], ink)
            stroke([p(0.32, 0.27), p(0.24, 0.42)], ink)
            stroke([p(0.32, 0.28), p(0.46, 0.40)], ink)
            head(p(0.33, 0.13))
            stroke([p(0.46, 0.41), p(0.76, 0.41)], ink.opacity(0.8))
            stroke([p(0.72, 0.44), p(0.76, 0.40), p(0.80, 0.44)], ink.opacity(0.8))       // the feet
            stroke([p(0.76, 0.40), p(0.82, 0.36), p(0.88, 0.36)], ink.opacity(0.8))       // the neck
            stroke([p(0.86, 0.31), p(0.88, 0.35), p(0.90, 0.31)], ink.opacity(0.8))       // the cradle
            stroke([p(0.20, 0.38), p(0.98, 0.31)], cue)
        case .cue(let kind):
            drawCue(kind, in: &ctx, size: size, ink: ink, cue: cue)
        case .raisedCue:
            // A ball behind the cue ball and the cue tilted up over it to strike down at the cue ball.
            let r = size.height * 0.10
            for x in [0.62, 0.88] as [CGFloat] {
                let c = p(x, 0.45)
                ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - 2 * r, width: r * 2, height: r * 2)),
                           with: .color(ink), lineWidth: 1.5)
            }
            stroke([p(0.84, 0.30), p(0.20, 0.06)], cue)
        }
    }

    /// The picked cue over a ball on the cloth, its tip just short of it: near level for the break cue (and the plain
    /// cues), raised for the jump cue, steeper still for the massé cue, and drawn as long beside the house cue as the
    /// real cue is (the jump cue's 1.05 m and the massé cue's 1.26 m against 1.47 m), so a short cue reads as short.
    /// The heavy cues (break, massé) get a thicker butt. The angles are the picture's, chosen to read at 44 by 30
    /// points (a 40 degree jump, a 70 degree massé), not the strike's own angle, which the cue angle control shows.
    private static func drawCue(_ kind: CueKind, in ctx: inout GraphicsContext, size: CGSize, ink: Color, cue: Color) {
        let r = size.height * 0.10
        let ball = CGPoint(x: size.width * 0.86, y: size.height * 0.45 - r)
        ctx.stroke(Path(ellipseIn: CGRect(x: ball.x - r, y: ball.y - r, width: r * 2, height: r * 2)),
                   with: .color(ink), lineWidth: 1.5)
        let degrees: CGFloat
        switch kind {
        case .jump: degrees = 40
        case .masse: degrees = 70
        case .house, .breakCue, .rosewoodFourPoint, .cobalt: degrees = 4
        }
        let angle = degrees * .pi / 180
        // From the tip back toward the butt: left, and up the screen (negative y) by the cue's angle.
        let back = CGVector(dx: -cos(angle), dy: -sin(angle))
        let tip = CGPoint(x: ball.x + back.dx * r * 1.4, y: ball.y + back.dy * r * 1.4)
        let length = size.width * 0.85 * CGFloat(CueProfile.profile(for: kind).length / CueProfile.houseLength)
        let joint = CGPoint(x: tip.x + back.dx * length * 0.5, y: tip.y + back.dy * length * 0.5)
        let butt = CGPoint(x: tip.x + back.dx * length, y: tip.y + back.dy * length)
        var shaft = Path()
        shaft.move(to: tip)
        shaft.addLine(to: joint)
        ctx.stroke(shaft, with: .color(cue), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        var rear = Path()
        rear.move(to: joint)
        rear.addLine(to: butt)
        let heavy = kind == .breakCue || kind == .masse
        ctx.stroke(rear, with: .color(cue), style: StrokeStyle(lineWidth: heavy ? 3.5 : 2.5, lineCap: .round))
    }
}

// MARK: The bridge's length

/// The bridge's length for the fine controls: the finger's while it rests on the cloth, the automatic one, or the
/// rest's head. Read-only: the bridge is set on the table, by a second finger while stroking.
struct BridgeReadout: View {
    let model: ShowpieceModel

    var body: some View {
        let readout = StanceWords.bridgeReadout(length: model.strokeBridgeLength, source: source)
        HStack(spacing: 8) {
            Text("Bridge").font(Theme.label).foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(readout).font(Theme.number).multilineTextAlignment(.trailing)
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Bridge"))
        .accessibilityValue(readout)
    }

    /// Where the length comes from: the rest whenever the model uses it (the stance needs it, or the mode shows it:
    /// model.restInUse, the same answer the table uses to draw it), the finger while one rests on the cloth, otherwise
    /// the automatic bridge.
    private var source: StanceWords.BridgeSource {
        if model.restInUse { return .rest }
        return model.strokeBridge == nil ? .automatic : .finger
    }
}
