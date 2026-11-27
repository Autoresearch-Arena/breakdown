// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 5, the mode frame: created.)
// PURPOSE: UI rethink package 5, "The mode frame" (plans/26-Nov-2026-ui-rethink-plan.md; design language, "Mode card",
//          "Result card", "Ruling card", "List row"). The small pieces every mode's views share so that a screenshot of
//          one mode's card could be swapped with any other's and only the words and figures change:
//          - ModeDifficulty: the one mapping from each mode's own difficulty data to the kit's five DifficultyDots
//            (trick shots and the shot of the day have easy, medium, hard; a lesson takes the difficulty of the trick
//            shot built on its idea; an 8-ball situation its top authored rating, already 1 to 5; a table game against
//            the computer the computer's level).
//          - ForgivingTiles: the "How forgiving" tiles (aim in degrees, or a distance in cm for the break; speed in
//            m/s; tip in mm), each the measured half-window either way, from the mode's own TrickWindow.
//          - ModeResultCard: the kit's result card (ResultCard) laid out the same way, plus the two things a mode's
//            result needs and the kit's card does not take yet: the judge's line(s) under the verdict, a "More" menu
//            for the extra actions, and an optional extra section (8-ball's "On a real table").
//          - ModeStartThumb: a small drawing of a start layout (no path), for the lesson and 8-ball list rows, drawn
//            by the trick list's own TrickPathThumb so every list's picture is the same table.
//          - RulingVerdict.init(_ ruling:): the rules package's Ruling turned into the kit's three verdicts.
//          - ModeBallColour: a ball's colour in the interface, from the 3D balls' own palette (BallTextures).
//          - View.modeShortcut: a keyboard shortcut for a kit action (Return for the main button, Command-S for
//            Share), since the kit's buttons do not take one yet.
//          Read by TrickShotViews, LessonViews, EightBallViews, DailyViews, MatchViews, CallControl, TableGamePage,
//          NotebookInfo and OwnShotViews.
// SRP/DRY check: Pass - checked App/Kit (ModeCard, ResultCard, RulingCard, FigureTile, ListRow, DifficultyDots: used,
//          not copied, except ModeResultCard, which repeats ResultCard's layout with lines and more added; when the kit's
//          ResultCard takes those two, ModeResultCard should become a call to it), NotebookInfo's old forgiving tiles
//          (moved here and shared with the cards) and TrickPathThumb (reused for the start drawings, no second canvas).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import SwiftUI

// MARK: Difficulty, five dots

/// Every mode's difficulty on the kit's five-dot scale. Difficulty is never a colour and never a word tag.
enum ModeDifficulty {
    /// Trick shots and the shot of the day: easy, medium, hard spread over the scale (1, 3, 5), so the three steps
    /// read as far apart as they are.
    static func dots(_ d: TrickDifficulty) -> Int {
        switch d {
        case .easy: return 1
        case .medium: return 3
        case .hard: return 5
        }
    }

    /// An 8-ball situation: its hardest authored way out, rated 1 to 5 by the authors, straight onto the scale.
    static func dots(rating: Int) -> Int { min(max(rating, 1), 5) }

    /// A lesson: the difficulty of the trick shot built on its idea (Lesson.trickID), so the path's last lessons read
    /// as harder than its first. A lesson whose trick is missing reads as the easiest.
    static func dots(lesson: Lesson) -> Int {
        TrickShots.shot(id: lesson.trickID).map { dots($0.difficulty) } ?? 1
    }

    /// A table game against the computer: the computer's level (1, 3, 5).
    static func dots(_ level: ComputerLevel) -> Int {
        switch level {
        case .easy: return 1
        case .medium: return 3
        case .hard: return 5
        }
    }
}

// MARK: How forgiving

/// "How forgiving": how far each setting can stray from the answer, either way, and the shot still works. The values
/// are the mode's own measured half-windows (TrickWindow); nothing is worked out here. Aim is degrees for a shot and
/// metres along the head string for the break (written as a table distance in cm). The tip tile is the tip height's
/// window, or the side's when only side is judged; with neither judged there is no tip tile.
struct ForgivingTiles: View {
    let window: TrickWindow
    let isBreak: Bool

    var body: some View {
        FigureTileRow {
            tile(String(localized: "Aim"),
                 isBreak ? NumberStyle.distance(metres: window.aim) : NumberStyle.angle(degrees: window.aim))
            tile(String(localized: "Speed"), NumberStyle.speed(metresPerSecond: window.power))
            if let tip {
                tile(String(localized: "Tip"), NumberStyle.tipOffset(metres: tip))
            }
        }
    }

    /// The tip window shown: height first, side when height is not judged, none when neither is.
    private var tip: Double? {
        if window.tipUp > 0 { return window.tipUp }
        if window.tipSide > 0 { return window.tipSide }
        return nil
    }

    /// One tile: the label, the figure with a plus-or-minus sign, and VoiceOver's "1.5° either way".
    private func tile(_ label: String, _ reading: NumberStyle.Reading) -> some View {
        let either = NumberStyle.Reading(number: "±" + reading.number, unitKey: reading.unitKey)
        return FigureTile(label: label, reading: either,
                          spoken: String(localized: "\(reading.text) either way",
                                         comment: "VoiceOver on a How forgiving tile: how far a setting may stray from the answer in each direction, e.g. 1.5° either way."))
    }
}

// MARK: The result card with the judge's words

/// The result of a try, in the kit's result-card layout (ResultCard): the verdict word coloured by its tone, then the
/// judge's line(s) in body paper, then the one figure that matters at the lead size, a status line, the score with its
/// breakdown behind "More", an optional extra section, and the button row ("Try again" secondary, the way on primary,
/// "Share" quiet, the rest under "More"). Each piece but the verdict is optional.
struct ModeResultCard<Extra: View>: View {
    let verdict: String
    var tone: ResultTone = .plain
    /// A short word on the right of the verdict ("Try 2 of 3", "Gold medal"), paper2.
    var corner: String? = nil
    var lines: [String] = []
    var figure: NumberStyle.Reading? = nil
    var figureCaption: String? = nil
    var status: [KitStatusItem] = []
    var score: String? = nil
    var scoreLabel: String = String(localized: "Score")
    var scoreBreakdown: [KitStatusItem] = []
    var tryAgain: KitAction? = nil
    var next: KitAction? = nil
    var share: KitAction? = nil
    var more: [KitAction] = []
    @ViewBuilder var extra: Extra

    @Environment(\.palette) private var palette
    private var deviceReader = KitDeviceReader()

    init(verdict: String, tone: ResultTone = .plain, corner: String? = nil, lines: [String] = [],
         figure: NumberStyle.Reading? = nil, figureCaption: String? = nil, status: [KitStatusItem] = [],
         score: String? = nil, scoreLabel: String = String(localized: "Score"), scoreBreakdown: [KitStatusItem] = [],
         tryAgain: KitAction? = nil, next: KitAction? = nil, share: KitAction? = nil, more: [KitAction] = [],
         @ViewBuilder extra: () -> Extra) {
        self.verdict = verdict
        self.tone = tone
        self.corner = corner
        self.lines = lines
        self.figure = figure
        self.figureCaption = figureCaption
        self.status = status
        self.score = score
        self.scoreLabel = scoreLabel
        self.scoreBreakdown = scoreBreakdown
        self.tryAgain = tryAgain
        self.next = next
        self.share = share
        self.more = more
        self.extra = extra()
    }

    /// The verdict's colour, as the kit's ResultCard sets it: warning for a foul or a miss, pocket gold for a pot or a
    /// pass, paper otherwise.
    private var verdictColour: Color {
        switch tone {
        case .foul: return palette.warning
        case .pocketed, .passed: return palette.pocket
        case .plain: return palette.paper
        }
    }

    var body: some View {
        let device = deviceReader.current
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.sm) {
                Text(verbatim: verdict)
                    .font(Theme.heading)
                    .foregroundStyle(verdictColour)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Theme.Space.xs)
                if let corner {
                    Text(verbatim: corner)
                        .font(Theme.label)
                        .foregroundStyle(palette.paper2)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(verbatim: line)
                    .font(device == .phone ? Theme.bodyCompact : Theme.body)
                    .foregroundStyle(palette.paper)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let figure {
                VStack(alignment: .leading, spacing: Theme.Space.figureToLabel) {
                    KitFigure(figure, size: .lead)
                    if let figureCaption {
                        Text(verbatim: figureCaption)
                            .font(Theme.caption)
                            .foregroundStyle(palette.paper2)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(figureCaption ?? verdict)
                .accessibilityValue(figure.text)
            }
            if !status.isEmpty { KitStatusLine(items: status) }
            if let score {
                VStack(alignment: .leading, spacing: 0) {
                    KitStatusLine(items: [KitStatusItem(scoreLabel, figure: score)])
                    if !scoreBreakdown.isEmpty {
                        MoreDisclosure {
                            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                                ForEach(scoreBreakdown) { part in
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(verbatim: part.label)
                                            .font(Theme.caption)
                                            .foregroundStyle(palette.paper2)
                                        Spacer(minLength: Theme.Space.sm)
                                        KitFigure(number: part.figure, unit: part.unit, size: .inline)
                                    }
                                    .accessibilityElement(children: .combine)
                                }
                            }
                            .padding(Theme.Space.sm)
                            .background(palette.panelSunken, in: Theme.Corner.tileShape)
                        }
                    }
                }
            }
            extra
            if tryAgain != nil || next != nil || share != nil || !more.isEmpty {
                KitButtonRow(primary: next, secondary: tryAgain, quiet: share, more: more)
                    .padding(.top, Theme.Space.xxs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .kitPanel()
        .accessibilityElement(children: .contain)
    }
}

extension ModeResultCard where Extra == EmptyView {
    /// A result with no extra section.
    init(verdict: String, tone: ResultTone = .plain, corner: String? = nil, lines: [String] = [],
         figure: NumberStyle.Reading? = nil, figureCaption: String? = nil, status: [KitStatusItem] = [],
         score: String? = nil, scoreLabel: String = String(localized: "Score"), scoreBreakdown: [KitStatusItem] = [],
         tryAgain: KitAction? = nil, next: KitAction? = nil, share: KitAction? = nil, more: [KitAction] = []) {
        self.init(verdict: verdict, tone: tone, corner: corner, lines: lines, figure: figure,
                  figureCaption: figureCaption, status: status, score: score, scoreLabel: scoreLabel,
                  scoreBreakdown: scoreBreakdown, tryAgain: tryAgain, next: next, share: share, more: more,
                  extra: { EmptyView() })
    }
}

// MARK: The idea and its maths

/// A shot's worked equation, in the equation style (serif italic), read aloud in words. Shown in the mode card's one
/// section, under the section label "The maths".
struct ModeMaths: View {
    let maths: String
    let spoken: String?
    @Environment(\.palette) private var palette

    var body: some View {
        Text(verbatim: maths)
            .font(Theme.equation)
            .foregroundStyle(palette.paper)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(String(localized: "The maths: \(spoken ?? maths)"))
    }
}

// MARK: Start drawings for the lists

/// A small drawing of a start layout (the bed, the pockets, the balls where they start; no path), for the lesson and
/// 8-ball list rows. Drawn by TrickPathThumb, the trick list's own drawing, from a path with no strokes, so the three
/// lists show the same little table. The table is the standard pool table, as every lesson and situation is.
struct ModeStartThumb: View {
    let layout: [Vec2]

    var body: some View {
        TrickPathThumb(path: Self.path(layout))
    }

    /// The layout as a drawing's data: every ball that starts on the table, at its place; no cue or object paths.
    static func path(_ layout: [Vec2]) -> TrickPath {
        let table = PoolParameters().tableSpec
        let balls = layout.indices.filter { NextShot.isOnTable(layout[$0]) }
            .map { TrickPath.StartBall(ball: $0, position: layout[$0]) }
        return TrickPath(length: table.length, width: table.width, ballRadius: table.ballRadius,
                         pockets: table.pockets, balls: balls, cue: [], objects: [])
    }
}

// MARK: Rulings

extension RulingVerdict {
    /// The rules' ruling as one of the kit's three verdicts: a foul, else a loss of turn when the turn passes, else a
    /// legal shot (the shooter keeps the table). A ruling that ends the game is shown by its result instead (the
    /// match card heads it "You win!" and so on), so callers only ask this for a game still going.
    init(_ ruling: Ruling) {
        if ruling.fouled {
            self = .foul
        } else if ruling.turnPasses {
            self = .lossOfTurn
        } else {
            self = .legal
        }
    }
}

// MARK: Ball colours in the interface

/// A ball's colour as the 3D table paints it, for the small ball pictures in the interface (the call chips' dots, the
/// ball icons). One place turns BallTextures' swatch into a SwiftUI colour.
enum ModeBallColour {
    static func colour(_ look: BallLook) -> Color {
        let c = BallTextures.swatch(look)
        return Color(red: c.0, green: c.1, blue: c.2) // design-lint: allow a ball's own colour, from BallTextures (the 3D balls' palette)
    }
}

// MARK: See the contact, as a kit action

extension ContactButton {
    /// "See the contact" as a card's action (it goes in the card's More menu): the same seek as the button, or nil when
    /// the shot on screen touched no ball, as the button hides itself then.
    @MainActor static func kitAction(model: ShowpieceModel, reduceMotion: Bool) -> KitAction? {
        guard model.firstContactTime != nil else { return nil }
        return KitAction(String(localized: "See the contact"), systemImage: symbol) {
            seek(model, reduceMotion: reduceMotion)
        }
    }
}

// MARK: Keyboard

extension View {
    /// Gives a kit action a keyboard shortcut (Return for a card's main button, Command-S for Share). The kit's
    /// buttons do not take a shortcut, so an invisible twin button carries it; VoiceOver never meets the twin. Nothing
    /// is added when the action is nil.
    func modeShortcut(_ action: KitAction?, _ key: KeyboardShortcut) -> some View {
        background {
            if let action {
                Button(action.title) { action.action() }
                    .keyboardShortcut(key)
                    .disabled(!action.isEnabled)
                    .opacity(0)
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
            }
        }
    }
}
