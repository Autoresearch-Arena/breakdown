// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The reach ladder on screen (App/Stroke/Reach.swift), apart from the bridge mark on the cloth (AimOverlay):
//          - EquipmentCard: the single equipment indicator. A small card beside the power and tip controls (inside the
//            shot panel on a phone, among the notebook's cards on big screens and the open Duo) with a flat pictogram
//            drawn in code and one plain line for each thing worth saying about how the next strike is played: the
//            stance when it is not a square one ("Stretch: one foot off the floor"), and a cue raised over a ball. A
//            square stance with a clear path shows nothing, so the screen stays clean. The first few times it appears
//            it pulses gently (counted on the device, never with Reduce Motion), and VoiceOver reads the same lines.
//            Its rows come from EquipmentRows.current, the one place a future automatic cue pick adds its own row (the
//            cue's name and the reason); there is no cue row until there are cues to pick.
//          - StancePictogram: the flat pictograms, a side view of a figure at the rail for each rung and a cue raised
//            over a ball, drawn with paths in a Canvas (no images), in the dark palette.
//          - BridgeReadout: the bridge's length for the fine controls ("20 cm, automatic bridge"), spoken the same.
// SRP/DRY check: Pass - checked StrokeViews (StrokeResultCard is the same small-card pattern, its glass card and fonts
//          reused), AimGauges (the panel's own controls; this card sits beside them, it does not change them) and
//          StanceWords (every line comes from there).
import BreakdownLensModel
import BreakdownRules
import SwiftUI

// MARK: The rows

/// One row of the equipment card: what its pictogram shows and its line.
struct EquipmentRow: Identifiable, Equatable {
    enum Picture: Equatable { case stance(Stance.Rung), raisedCue }
    let id: String
    let picture: Picture
    let line: String
}

@MainActor
enum EquipmentRows {
    /// The rows for the strike being lined up, once the balls are at rest and the cue ball is down: the stance unless
    /// it is a square one, then the raised cue. Empty when there is nothing to say. The automatic cue pick (the
    /// cues-and-bridges plan) appends its row here when cues exist.
    static func current(_ model: ShowpieceModel) -> [EquipmentRow] {
        guard model.aimReady, !model.placingCueBall, let stance = model.stance, !stance.isNormal else { return [] }
        var rows: [EquipmentRow] = []
        if stance.rung != .normal {
            rows.append(EquipmentRow(id: "stance", picture: .stance(stance.rung), line: StanceWords.rungLine(stance.rung)))
        }
        if let ball = stance.raisedOver {
            rows.append(EquipmentRow(id: "raised", picture: .raisedCue,
                                     line: StanceWords.raisedLine(over: ball, kind: model.match?.rules.kind)))
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
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// How many times the card has pulsed on this device; it stops after `pulseLimit`.
    @AppStorage("equipmentCardPulses") private var pulses = 0
    @State private var lifted = false

    /// The card pulses the first three times it appears: enough to be noticed, then it simply shows.
    private static let pulseLimit = 3

    var body: some View {
        let rows = EquipmentRows.current(model)
        if !rows.isEmpty {
            let spoken = rows.map(\.line).joined(separator: ". ")
            content(rows)
                .scaleEffect(lifted ? 1.035 : 1)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(spoken)
                // A VoiceOver player aiming by swipes hears the stance as it comes and as it changes.
                .onAppear {
                    pulseIfNew()
                    ShotNarration.announce(spoken)
                }
                .onChange(of: spoken) { _, now in ShotNarration.announce(now) }
                .transition(.opacity)
        }
    }

    @ViewBuilder private func content(_ rows: [EquipmentRow]) -> some View {
        let stack = VStack(alignment: .leading, spacing: 6) {
            ForEach(rows) { row in
                HStack(spacing: 10) {
                    StancePictogram(picture: row.picture)
                        .frame(width: 44, height: 30)
                    Text(row.line)
                        .font(Theme.body)
                        .foregroundStyle(palette.paper)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        if embedded {
            stack
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 14).fill(palette.paper.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(palette.slide.opacity(lifted ? 0.8 : 0.3), lineWidth: 1))
        } else {
            stack
                .glassCard(cornerRadius: 20, padding: 12)
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(palette.slide.opacity(lifted ? 0.8 : 0), lineWidth: 1.5))
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

// MARK: Pictograms

/// A flat side view drawn with paths: the table's edge on the right (its top and a leg), the floor, and a figure at the
/// rail in the rung's posture, the cue in the lamp's amber. Coordinates are shares of the drawing's width and height,
/// (0, 0) top left; the table's top sits at 0.45 of the height and its rail's outer edge at 0.56 of the width.
struct StancePictogram: View {
    let picture: EquipmentRow.Picture
    @Environment(\.palette) private var palette

    var body: some View {
        Canvas { ctx, size in
            Self.draw(picture, in: &ctx, size: size, ink: palette.paper, cue: palette.slide)
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
        // The floor, and the table: its top from the rail's edge to the right, one leg.
        stroke([p(0.02, 0.96), p(0.98, 0.96)], ink.opacity(0.25))
        let tableLeft: CGFloat = picture == .raisedCue ? 0.02 : 0.56
        ctx.fill(Path(CGRect(x: tableLeft * size.width, y: 0.45 * size.height, width: (1 - tableLeft) * size.width,
                             height: 0.07 * size.height)), with: .color(ink.opacity(0.35)))
        if picture != .raisedCue { stroke([p(0.64, 0.52), p(0.64, 0.96)], ink.opacity(0.35)) }

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
            // Standing tall, the cue carried on the rest: its long handle on the table and the cross head near the
            // far end.
            stroke([p(0.24, 0.95), p(0.30, 0.55), p(0.36, 0.95)], ink)
            stroke([p(0.30, 0.55), p(0.32, 0.24)], ink)
            stroke([p(0.32, 0.27), p(0.24, 0.42)], ink)
            stroke([p(0.32, 0.28), p(0.46, 0.40)], ink)
            head(p(0.33, 0.13))
            stroke([p(0.46, 0.41), p(0.84, 0.42)], ink.opacity(0.8))
            stroke([p(0.80, 0.34), p(0.88, 0.44)], ink.opacity(0.8))
            stroke([p(0.88, 0.34), p(0.80, 0.44)], ink.opacity(0.8))
            stroke([p(0.20, 0.38), p(0.98, 0.34)], cue)
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

    /// Where the length comes from: the rest when the stance needs it (or the shot shows it), the finger while one
    /// rests on the cloth, otherwise the automatic bridge.
    private var source: StanceWords.BridgeSource {
        if model.stance?.rung == .rest || model.showsBridge { return .rest }
        return model.strokeBridge == nil ? .automatic : .finger
    }
}
