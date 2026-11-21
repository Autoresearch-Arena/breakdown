// Author: Claude Sonnet 5.5 Medium
// Date: 21-November-2026
// PURPOSE: The two information strips of the iPhone Duo's side panel (DuoPanel):
//          DuoNumbers - the shot at a glance, in tiles (the cue's launch speed, how many ball hits, rail hits and
//            pocketed balls the recording holds), and the surface and table it was played on with the four numbers
//            that decide how a ball moves (sliding friction, rolling resistance, the cushions' bounce, gravity).
//            Every figure is counted or read from the recorded timeline or the surface's own parameters, the values the
//            solver was given; none is typed in.
//          DuoDossier - what the mode on the table has to say beyond its card. Trick shots: the idea and its equation
//            once the answer has been shown, and how forgiving the shot is (how far aim, power and cue-tip height can
//            stray and still work). Behind the 8-Ball: your group and the balls you may hit first, and after the shot
//            the lesson and the trick shots that teach it.
// SRP/DRY check: Pass - reading and display only. The data are TrickShots, EightBallSituations and the model's timeline;
//          nothing is repeated, and no new rules live here.
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

// MARK: Numbers

struct DuoNumbers: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette

    /// What the recording holds, counted once per redraw (the timeline changes only when a shot does).
    private struct Facts {
        var cueSpeed: Double?
        var ballHits = 0
        var railHits = 0
        var pocketed = 0

        init(_ timeline: Timeline) {
            for e in timeline.events {
                switch e.kind {
                case .cueStrike:
                    if cueSpeed == nil, let b = e.balls.first { cueSpeed = b.velocityAfter.length }
                case .ballBall: ballHits += 1
                case .cushion: if e.edge == .rail { railHits += 1 }
                case .pocket: pocketed += 1
                default: break
                }
            }
        }
    }

    var body: some View {
        let facts = Facts(model.timeline)
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                tile(facts.cueSpeed.map(Self.speedText) ?? "–", "Cue speed")
                tile(facts.ballHits.formatted(), "Ball hits")
                tile(facts.railHits.formatted(), "Rail hits")
                tile(facts.pocketed.formatted(), "Pocketed")
            }
            surfaceCard
        }
    }

    private func tile(_ value: String, _ label: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text(verbatim: value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(palette.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 52)
        .padding(.vertical, 6)
        .padding(.horizontal, 2)
        .glassEffect(.regular, in: .rect(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    /// The surface (and the table, when it is not the standard one) with the numbers that make it play the way it does.
    private var surfaceCard: some View {
        let p = model.physicsSurface.parameters
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: model.surface.symbol).foregroundStyle(palette.accent).accessibilityHidden(true)
                Text(verbatim: model.surface.title).font(Theme.heading).lineLimit(1)
                if model.tableKind != .standard {
                    Text(verbatim: "·").foregroundStyle(.secondary)
                    Text(verbatim: model.tableKind.title).font(Theme.body).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 0) {
                constant("μ", p.slidingFriction)
                constant("c", p.rollingResistance)
                constant("e", p.cushionRestitution)
                constant("g", p.gravity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .glassEffect(.regular, in: .rect(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    /// One physical constant: its symbol (the one the equations use) and its value to two significant figures.
    private func constant(_ symbol: String, _ value: Double) -> some View {
        HStack(spacing: 4) {
            Text(verbatim: symbol).font(Theme.equation).foregroundStyle(palette.slide)
            Text(verbatim: value.formatted(.number.precision(.significantDigits(1...3))))
                .font(Theme.number)
        }
        .frame(maxWidth: .infinity)
    }

    private static func speedText(_ v: Double) -> String {
        Measurement(value: v, unit: UnitSpeed.metersPerSecond)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided,
                                    numberFormatStyle: .number.precision(.fractionLength(1))))
    }
}

// MARK: Dossier

struct DuoDossier: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette

    var body: some View {
        if let shot = model.trickMode.current, model.trickMode.isActive {
            trick(shot)
        } else if let situation = model.eightBallMode.current, model.eightBallMode.isActive {
            eightBall(situation)
        }
    }

    // MARK: Trick shots

    /// The idea and its equation wait until the answer has been shown (the card gives the idea itself while it explains,
    /// so it is not repeated then); how forgiving the shot is can be read at any time.
    private func trick(_ shot: TrickShot) -> AnyView {
        let mode = model.trickMode
        var showsIdea = false
        var showsWindow = true
        switch mode.phase {
        case .aiming, .judged: showsIdea = true
        // The card is giving the idea itself, and the room is wanted for the commentary beside the Lens replay.
        case .explaining: showsWindow = false
        default: break
        }
        guard showsIdea || showsWindow else { return AnyView(EmptyView()) }
        return AnyView(VStack(alignment: .leading, spacing: 10) {
            if showsIdea {
                VStack(alignment: .leading, spacing: 4) {
                    heading("The idea", symbol: "lightbulb.fill")
                    Text(verbatim: shot.idea)
                        .font(Theme.body)
                        .fixedSize(horizontal: false, vertical: true)
                    if let maths = shot.maths {
                        Text(verbatim: maths)
                            .font(.system(.callout, design: .serif, weight: .medium).italic())
                            .foregroundStyle(palette.paper)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            if showsWindow {
                VStack(alignment: .leading, spacing: 6) {
                    heading("How forgiving", symbol: "scope")
                    HStack(spacing: 8) {
                        window("Aim", shot.isBreak ? Self.millimetres(shot.window.aim)
                                                   : Self.degrees(shot.window.aim))
                        window("Power", Self.metresPerSecond(shot.window.power))
                        window("Tip", Self.millimetres(shot.window.tipUp))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22, padding: 12))
    }

    // MARK: Behind the 8-Ball

    private func eightBall(_ s: EightBallSituation) -> some View {
        let mode = model.eightBallMode
        var scored = false
        if case .scored = mode.phase { scored = true }
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(verbatim: s.group.title).font(Theme.heading)
                Spacer(minLength: 0)
                ForEach(s.legalBalls, id: \.self) { ball in
                    Text(verbatim: "\(ball)")
                        .font(Theme.number)
                        .frame(minWidth: 26, minHeight: 26)
                        .background(Circle().stroke(palette.accent, lineWidth: 1.5))
                }
            }
            .accessibilityElement(children: .combine)
            if scored {
                VStack(alignment: .leading, spacing: 4) {
                    heading("Lesson", symbol: "graduationcap.fill")
                    Text(verbatim: s.lesson)
                        .font(Theme.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                let names = s.taughtBy.compactMap { TrickShots.shot(id: $0)?.title }
                if !names.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        heading("Practise it with", symbol: "wand.and.sparkles")
                        Text(verbatim: names.formatted(.list(type: .and)))
                            .font(Theme.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22, padding: 12)
    }

    // MARK: Pieces

    private func heading(_ title: LocalizedStringKey, symbol: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol).foregroundStyle(palette.slide).accessibilityHidden(true)
            Text(title).font(Theme.label).foregroundStyle(palette.slide)
        }
        .accessibilityAddTraits(.isHeader)
    }

    /// One setting and how far it may stray, as a small tile.
    private func window(_ label: LocalizedStringKey, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(verbatim: "±" + value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label).font(Theme.label).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(palette.track.opacity(0.5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private static func degrees(_ v: Double) -> String {
        Measurement(value: v, unit: UnitAngle.degrees)
            .formatted(.measurement(width: .narrow, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0...2))))
    }

    private static func millimetres(_ metres: Double) -> String {
        Measurement(value: metres * 1000, unit: UnitLength.millimeters)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0...1))))
    }

    private static func metresPerSecond(_ v: Double) -> String {
        Measurement(value: v, unit: UnitSpeed.metersPerSecond)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0...2))))
    }
}
