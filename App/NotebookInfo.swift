// Author: Claude Sonnet 5.5 Medium
// Date: 21-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2: one meaning per colour. Fouls, misses and
//          refusals take Palette.warning; headings, try counts, tags and difficulty take paper or paper2; the sliding
//          magenta is left for sliding and friction.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 strike: NotebookNumbers' tile is lifted into NumberTile,
//          App/Strike/NumberTile.swift, which the strike panel reuses; it draws exactly as before.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 words, plans/25-Nov-2026-fewer-words-and-honest-claims-plan.md
//          Part A rows 3 and 4: NotebookNumbers draws no tiles before a shot exists (no "0.0 m/s, 0, 0, 0"), and no
//          surface card of its own then while the commentary draws the detailed one, so the card is never drawn twice.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 daily: the dossier keeps a shot of the day's idea back until
//          the day is finished, as the card does.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 make it again, plans/23-Nov-2026-make-it-again-plan.md N1: How
//          forgiving is not shown for a saved shot of the player's own until its window has been measured.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (renamed, file NotebookInfo.swift (it was DuoInfo.swift), for the notebook layout it now serves on every big screen:
//          NotebookNumbers, NotebookSurfaceCard and NotebookDossier (they were DuoNumbers, DuoSurfaceCard, DuoDossier).
//          On a big screen (notebookRoomy) the number tiles' labels follow the reader's text size instead of a fixed
//          10 points; the folding phone keeps the size its narrow tiles were laid out for.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (version 0.7.0, plans/21-Nov-2026-bugs-after-0-6-6-plan.md item 27: the
//          surface card no longer shows the raw cushion restitution "e", which the tuned rail no longer makes equal to
//          what a ball keeps; it says what a ball rolling straight into a rail at a stated pace keeps, worked out with
//          the solver's rail rules (RailKeep in Captions.swift).)
// PURPOSE: The two information strips of the notebook panel (NotebookPanel), on the open folding phone and on iPad and
//          Mac windows:
//          NotebookNumbers - the shot at a glance, in tiles (the cue's launch speed, how many ball hits, rail hits and
//            pocketed balls the recording holds), and the surface and table it was played on with the numbers that
//            decide how a ball moves (sliding friction, rolling resistance, gravity) and what its rails give back.
//            Every figure is counted or read from the recorded timeline or the surface's own parameters, the values the
//            solver was given; none is typed in.
//          NotebookDossier - what the mode on the table has to say beyond its card. Trick shots: the idea and its equation
//            once the answer has been shown, and how forgiving the shot is (how far aim, power and cue-tip height can
//            stray and still work). Behind the 8-Ball: your group and the balls you may hit first, and after the shot
//            the lesson and the trick shots that teach it.
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (numbers are written in the game's own language, AppLocale.numbers
//          in NumberStyle.swift: French and German get "6,7" even on a phone set to another region.)
// SRP/DRY check: Pass - reading and display only. The data are TrickShots, EightBallSituations and the model's timeline;
//          nothing is repeated, and no new rules live here.
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

// MARK: Numbers

struct NotebookNumbers: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    @Environment(\.notebookRoomy) private var roomy
    // 0.7.10 words: with Explanations on, the commentary (NotebookStory) draws the detailed surface card before a shot.
    @AppStorage(GameSettings.explanationsKey) private var explanations = true

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
        // 0.7.10 words: before any shot there is nothing to count, so no tiles of zeros (row 4); the surface card waits
        // too while the commentary shows its detailed one (row 3).
        let shot = NotebookStory.hasShot(model)
        VStack(spacing: 8) {
            if shot {
            HStack(spacing: 8) {
                tile(facts.cueSpeed.map(Self.speedText) ?? "–", "Cue speed")
                tile(facts.ballHits.formatted(.number.locale(AppLocale.numbers)), "Ball hits")
                tile(facts.railHits.formatted(.number.locale(AppLocale.numbers)), "Rail hits")
                tile(facts.pocketed.formatted(.number.locale(AppLocale.numbers)), "Pocketed")
            }
            }
            if shot || !explanations {
                NotebookSurfaceCard(model: model)
            }
        }
    }

    // 0.7.10 strike: the tile itself is NumberTile (App/Strike/NumberTile.swift), shared with the strike panel.
    private func tile(_ value: String, _ label: LocalizedStringKey) -> some View {
        NumberTile(value: value, label: Text(label))
    }

    private static func speedText(_ v: Double) -> String {
        Measurement(value: v, unit: UnitSpeed.metersPerSecond)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided,
                                    numberFormatStyle: .number.locale(AppLocale.numbers).precision(.fractionLength(1))).locale(AppLocale.numbers))
    }
}

// MARK: Surface

/// The surface (and the table) the next shot is played on, with the four numbers that decide how a ball moves on it. With
/// `detailed`, each also says in a sentence what it does to the balls (the same lines the surface picker shows), so before
/// any shot has been played the panel still has something worth reading, and nothing that gives an answer away.
struct NotebookSurfaceCard: View {
    let model: ShowpieceModel
    var detailed = false
    @Environment(\.palette) private var palette

    var body: some View {
        let p = model.physicsSurface.parameters
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: model.surface.symbol).foregroundStyle(palette.accent).accessibilityHidden(true)
                Text(verbatim: model.surface.title).font(Theme.heading).lineLimit(1)
                if !detailed && model.tableKind != .standard {
                    Text(verbatim: "·").foregroundStyle(.secondary)
                    Text(verbatim: model.tableKind.title).font(Theme.body).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            if detailed {
                Text(verbatim: model.surface.summary)
                    .font(Theme.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 0) {
                constant("μ", p.slidingFriction)
                constant("c", p.rollingResistance)
                constant("g", p.gravity)
            }
            // The rails as what a ball gets from them, worked out with the solver's rail rules at a stated pace
            // (RailKeep), not the raw restitution: the tilted nose and the bounce that falls with speed mean the raw
            // number is no longer what a ball keeps.
            Text(String(localized: "Rails: a ball rolling straight in at \(Self.pace) m/s keeps \(RailKeep.percent(parameters: p)) percent of its speed."))
                .font(Theme.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            // The standard table needs no introduction; any other table is described, since it changes the whole game.
            if detailed && model.tableKind != .standard {
                HStack(spacing: 8) {
                    Image(systemName: model.tableKind.symbol).foregroundStyle(palette.accent).accessibilityHidden(true)
                    Text(verbatim: model.tableKind.title).font(Theme.heading).lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.top, 4)
                Text(verbatim: model.tableKind.summary)
                    .font(Theme.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, detailed ? 12 : 9)
        .glassEffect(.regular, in: .rect(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    /// The stated pace for the rails line, in the player's number style.
    private static var pace: String { String(format: "%.0f", locale: AppLocale.numbers, RailKeep.pace) }

    /// One physical constant: its symbol (the one the equations use) and its value to three significant figures.
    private func constant(_ symbol: String, _ value: Double) -> some View {
        HStack(spacing: 4) {
            Text(verbatim: symbol).font(Theme.equation).foregroundStyle(palette.slide)
            Text(verbatim: value.formatted(.number.locale(AppLocale.numbers).precision(.significantDigits(1...3))))
                .font(Theme.number)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: Dossier

struct NotebookDossier: View {
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
        // 0.7.7 make-it-again: a saved shot's window is not measured yet: show no made-up numbers.
        if OwnShotShelf.shared.isUnmeasured(shot) { showsWindow = false }
        // 0.7.10 daily: a shot of the day's idea says how it is done, so it waits until the day is finished.
        if DailyMode.showing(model), !model.dailyMode.finished { showsIdea = false }
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
                        Text(verbatim: names.formatted(.list(type: .and).locale(AppLocale.numbers)))
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
            Image(systemName: symbol).foregroundStyle(palette.paper).accessibilityHidden(true)
            Text(title).font(Theme.label).foregroundStyle(palette.paper)
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
            .formatted(.measurement(width: .narrow, usage: .asProvided, numberFormatStyle: .number.locale(AppLocale.numbers).precision(.fractionLength(0...2))).locale(AppLocale.numbers))
    }

    private static func millimetres(_ metres: Double) -> String {
        Measurement(value: metres * 1000, unit: UnitLength.millimeters)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.locale(AppLocale.numbers).precision(.fractionLength(0...1))).locale(AppLocale.numbers))
    }

    private static func metresPerSecond(_ v: Double) -> String {
        Measurement(value: v, unit: UnitSpeed.metersPerSecond)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.locale(AppLocale.numbers).precision(.fractionLength(0...2))).locale(AppLocale.numbers))
    }
}
