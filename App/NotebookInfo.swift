// Author: Claude Sonnet 5.5 Medium
// Date: 21-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 5, the mode frame: the cloth card is the kit's
//          panel with its own cloth icon, its figures spelled out on a status line ("Sliding friction 0.15, Rolling
//          resistance 0.015, Gravity 9.81 m/s²", through NumberStyle) instead of the symbols in the sliding colour, and
//          the edge named by the table ("Cushions", or "Cushions and bumpers" on bumper pool) with the pace in m/s; the
//          cue speed tile follows NumberStyle's speed rule; the dossier is a kit panel with section labels, its "How
//          forgiving" tiles the shared ForgivingTiles (left out while the trick card shows its own), and the legal balls
//          as the kit's chips. The old degree, millimetre and speed formatters are gone (NumberStyle).)
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
//          the numbers are NumberStyle's, the panel, chips, section labels and status line the kit's, the forgiving tiles
//          ModeFrameKit's (shared with the trick, lesson and daily cards); no new rules live here.
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

// MARK: Numbers

struct NotebookNumbers: View {
    let model: ShowpieceModel
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
        VStack(spacing: Theme.Space.xs) {
            if shot {
                HStack(spacing: Theme.Space.xs) {
                    tile(facts.cueSpeed.map { NumberStyle.speed(metresPerSecond: $0).text } ?? "–", "Cue speed")
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
}

// MARK: Surface

/// The cloth card: the surface (and the table) the next shot is played on, with the three numbers that decide how a
/// ball moves on it spelled out on a status line ("Sliding friction 0.15", "Rolling resistance 0.015", "Gravity
/// 9.81 m/s²"), and what the table's edge gives back, named by the table ("Cushions", "Cushions and bumpers"). Its own
/// cloth icon leads it. With `detailed`, the surface's sentence (the same line the surface picker shows) and, on another
/// table, the table's own sentence, so before any shot has been played the panel still has something worth reading,
/// and nothing that gives an answer away.
struct NotebookSurfaceCard: View {
    let model: ShowpieceModel
    var detailed = false
    @Environment(\.palette) private var palette

    var body: some View {
        let p = model.physicsSurface.parameters
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
                Image(systemName: Self.clothSymbol)
                    .fontWeight(.medium)
                    .foregroundStyle(palette.paper2)
                    .accessibilityHidden(true)
                Text(verbatim: model.surface.title).font(Theme.heading).foregroundStyle(palette.paper).lineLimit(1)
                if !detailed && model.tableKind != .standard {
                    Text(verbatim: "·").foregroundStyle(palette.paper2)
                    Text(verbatim: model.tableKind.title).font(Theme.label).foregroundStyle(palette.paper2).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            if detailed {
                Text(verbatim: model.surface.summary)
                    .font(Theme.body)
                    .foregroundStyle(palette.paper2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            KitStatusLine(items: [
                KitStatusItem(String(localized: "Sliding friction"), reading: NumberStyle.coefficient(p.slidingFriction)),
                KitStatusItem(String(localized: "Rolling resistance"), reading: NumberStyle.coefficient(p.rollingResistance)),
                KitStatusItem(String(localized: "Gravity"), reading: NumberStyle.gravity(metresPerSecondSquared: p.gravity)),
            ])
            // The edge as what a ball gets from it, worked out with the solver's rail rules at a stated pace (RailKeep),
            // not the raw restitution: the tilted nose and the bounce that falls with speed mean the raw number is no
            // longer what a ball keeps.
            Text(String(localized: "\(edgeName): a ball rolling straight in at \(NumberStyle.speed(metresPerSecond: RailKeep.pace).text) keeps \(RailKeep.percent(parameters: p)) percent of its speed.",
                        comment: "The cloth card's edge line. The first argument is the edge's name (Cushions, or Cushions and bumpers), the second the pace with its unit."))
                .font(Theme.body)
                .foregroundStyle(palette.paper2)
                .fixedSize(horizontal: false, vertical: true)
            // The standard table needs no introduction; any other table is described, since it changes the whole game.
            if detailed && model.tableKind != .standard {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
                    Image(systemName: model.tableKind.symbol)
                        .fontWeight(.medium)
                        .foregroundStyle(palette.paper2)
                        .accessibilityHidden(true)
                    Text(verbatim: model.tableKind.title).font(Theme.heading).foregroundStyle(palette.paper).lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.top, Theme.Space.xxs)
                Text(verbatim: model.tableKind.summary)
                    .font(Theme.body)
                    .foregroundStyle(palette.paper2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .kitPanel()
        .accessibilityElement(children: .combine)
    }

    /// The cloth card's own icon: a woven square, one icon for one meaning (the surface itself has its own symbol in
    /// the surface picker).
    static let clothSymbol = "checkerboard.rectangle"

    /// The table's edge by its name: cushions on every table, and the bumpers too on bumper pool, which share the
    /// cushions' rubber.
    private var edgeName: String {
        model.tableKind == .bumperPool
            ? String(localized: "Cushions and bumpers", comment: "The cloth card: the edge of a bumper pool table.")
            : String(localized: "Cushions", comment: "The cloth card: the edge of the table a ball bounces off.")
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
    /// so it is not repeated then); how forgiving the shot is can be read at any time the trick card does not show its
    /// own tiles (UI rethink package 5: the card carries them while the shot is set up and lined up).
    private func trick(_ shot: TrickShot) -> AnyView {
        let mode = model.trickMode
        var showsIdea = false
        var showsWindow = !TrickShotCard.cardShowsForgiving(mode)
        switch mode.phase {
        case .aiming, .judged: showsIdea = true
        // The card is giving the idea itself, and the room is wanted for the commentary beside the Lens replay.
        case .explaining: showsWindow = false
        default: break
        }
        // 0.7.7 make-it-again: a saved shot's window is not measured yet: show no made-up numbers.
        if !TrickShotCard.showsForgiving(shot) { showsWindow = false }
        // 0.7.10 daily: a shot of the day's idea says how it is done, so it waits until the day is finished.
        if DailyMode.showing(model), !model.dailyMode.finished { showsIdea = false }
        guard showsIdea || showsWindow else { return AnyView(EmptyView()) }
        return AnyView(VStack(alignment: .leading, spacing: Theme.Space.md) {
            if showsIdea {
                VStack(alignment: .leading, spacing: Theme.Space.sectionToContent) {
                    SectionLabel(String(localized: "The idea"))
                    Text(verbatim: shot.idea)
                        .font(Theme.body)
                        .foregroundStyle(palette.paper)
                        .fixedSize(horizontal: false, vertical: true)
                    if let maths = shot.maths {
                        ModeMaths(maths: maths, spoken: shot.mathsSpoken)
                    }
                }
            }
            if showsWindow {
                VStack(alignment: .leading, spacing: Theme.Space.sectionToContent) {
                    SectionLabel(String(localized: "How forgiving"))
                    ForgivingTiles(window: shot.window, isBreak: shot.isBreak)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .kitPanel())
    }

    // MARK: Behind the 8-Ball

    /// Your group and the balls you may hit first (the kit's chips), and after the shot the lesson and the trick shots
    /// that teach it.
    private func eightBall(_ s: EightBallSituation) -> some View {
        let mode = model.eightBallMode
        var scored = false
        if case .scored = mode.phase { scored = true }
        return VStack(alignment: .leading, spacing: Theme.Space.md) {
            VStack(alignment: .leading, spacing: Theme.Space.sectionToContent) {
                Text(verbatim: s.group.title).font(Theme.heading).foregroundStyle(palette.paper)
                CallChipWrap(spacing: Theme.Space.xs, lineSpacing: Theme.Space.xxs) {
                    ForEach(s.legalBalls, id: \.self) { ball in
                        Chip(value: ball.formatted(.number.locale(AppLocale.numbers)))
                    }
                }
            }
            .accessibilityElement(children: .combine)
            if scored {
                VStack(alignment: .leading, spacing: Theme.Space.sectionToContent) {
                    SectionLabel(String(localized: "Lesson"))
                    Text(verbatim: s.lesson)
                        .font(Theme.body)
                        .foregroundStyle(palette.paper)
                        .fixedSize(horizontal: false, vertical: true)
                }
                let names = s.taughtBy.compactMap { TrickShots.shot(id: $0)?.title }
                if !names.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Space.sectionToContent) {
                        SectionLabel(String(localized: "Practise it with"))
                        Text(verbatim: names.formatted(.list(type: .and).locale(AppLocale.numbers)))
                            .font(Theme.body)
                            .foregroundStyle(palette.paper2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .kitPanel()
    }
}
