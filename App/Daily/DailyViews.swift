// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 5, the mode frame: the card is the kit's mode
//          card while the day is open (the name and five dots, the goal, the day and tries left in the status line,
//          "How forgiving" from the shot's measured window while it is set up and lined up, Take your shot or Try
//          again) and the kit-style result card after a miss and once the day is finished (made on which try in pocket
//          gold or five misses in warning, the distance from the mark at the lead size, the streak, the score, the next
//          shot's time, Watch the answer with Share quiet and Board under More; the keys are kept). Centimetres follow
//          NumberStyle's table-distance rule. The five dots mark the make in pocket gold and a try to come in paper3.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2: one meaning per colour. Fouls, misses and
//          refusals take Palette.warning; headings, try counts, tags and difficulty take paper or paper2; the sliding
//          magenta is left for sliding and friction.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.8.1 store: the phone's result blurb shows the score, the
//          distance from the mark and the streak as figure chips, as the big-screen card's stats, instead of one sentence.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 wiring: the result card's Board is the board's own
//          BoardButton (App/GameCenter/GameCenterViews.swift); the phone's result blurb offers Board only while the
//          board may show, with the board's sign-in line when a sign-in from it failed.)
// PURPOSE: Everything the player sees of the shot of the day on the table (plans/25-Nov-2026-shot-of-the-day-plan.md,
//          stage 2 items 2 and 3), kept small so the table stays big:
//          DailyCard - the kit's mode card, where the trick card goes (TrickShotCard hands a daily shot to it, so on iPad,
//            the Mac and the open folding phone it sits in the notebook half and never covers the table). While playing:
//            the goal in one line, the day and tries left, with Take your shot or Try again and, after a miss, the
//            judge's one sentence (TrickShotJudge, as trick shots show it). Once the day is finished (a make or five
//            tries): the result card, made on which try, the distance from the mark, the score and the streak, the
//            time until the next shot, and Watch the answer, Share and Board (Board only once wave 2 sets
//            DailyMode.openBoard). The already-played card is the same result card, shown whenever the shot is
//            opened again the same day. While the answer replays in the Lens, its one idea sits above the result.
//          DailyPhoneBlurbs - the phone held upright: the same words as blurbs (TrickPhoneBlurbs hands over to it).
//          PhonePrimaryAction.daily - the upright phone's main button: Take your shot, Try again, Watch the answer.
//          DailyMarks - drawn by TrickTableLayer on the cloth: the mark (a ring with a centre dot) and, after a make, a
//            thin line from the white ball to the mark with the distance beside it.
//          DailyTryDots - the five dots, each told by its symbol as well as its colour (a tick for the make, a cross
//            for a miss, an empty ring for a try not used), read by VoiceOver as one phrase.
//          DailyWords - every sentence of the daily screens, menu row and share picture, through String(localized:);
//            the new English lines are in localization/pending/v0710-daily.json with their translations.
//          Nothing here shows the answer, its path or its settings before the day is finished, VoiceOver included.
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 everyone, plans/25-Nov-2026-everyone-can-play-plan.md Part
//          B5: the result card's buttons have keys, so the day is played to a shared result from a keyboard alone:
//          Return watches the answer while it is the main button, Command-S shares, Command-B opens the board.)
// SRP/DRY check: Pass - views and words only. Flow is DailyMode, judging TrickShotJudge, the goal marks of the trick
//          (balls and pockets) GoalMarks through TrickTableLayer; the card is the kit's (ModeCard, ModeResultCard and
//          the forgiving tiles of ModeFrameKit.swift, as TrickShotCard), the blurbs are App/Phone/Blurb.swift's, the rings and labels on the
//          cloth TablePathStroke's.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import SwiftUI

// MARK: Words

enum DailyWords {
    static var title: String { DailyShot.title }

    /// "Day 12": the day as the player counts it.
    static func day(_ label: Int) -> String { String(localized: "Day \(label)") }

    static var takeShot: String { String(localized: "Take your shot") }
    /// The trick card's own hint for Your turn (already translated).
    static var takeShotHint: String { String(localized: "Puts the balls back and opens the aiming controls") }
    /// The trick card's own Try again (already translated).
    static var tryAgain: String { String(localized: "Try again") }
    static var tryAgainHint: String {
        String(localized: "Puts the balls back where the shot started, with your last aim, power and spin")
    }
    static var watchAnswer: String { String(localized: "Watch the answer") }
    /// The trick card's own hint for Watch it (already translated).
    static var watchAnswerHint: String { String(localized: "Plays the answer, then explains it in the Physics Lens") }
    static var share: String { String(localized: "Share") }
    static var shareHint: String { String(localized: "Shares a picture of your result. The answer is not in it.") }
    static var board: String { String(localized: "Board") }
    static var boardHint: String { String(localized: "Shows how everyone did today") }
    /// The trick card's own lines (already translated).
    static var idea: String { String(localized: "The idea") }
    static var madeIt: String { String(localized: "Made it!") }
    static var missed: String { String(localized: "Missed") }
    static var offScript: String {
        String(localized: "That shot started from where the balls stopped. Try again puts them back for the trick.")
    }
    static var watching: String { String(localized: "The answer, at full speed.") }

    /// Tries left while the day is open.
    static func triesLeft(_ n: Int) -> String {
        n == 1 ? String(localized: "One try left.") : String(localized: "\(n) tries left.")
    }

    /// The result's heading.
    static func resultTitle(_ day: DailyRecord.Day) -> String {
        if let t = day.madeOnTry { return String(localized: "Made it on try \(t).") }
        return String(localized: "Five misses today.")
    }

    /// Centimetres by NumberStyle's table-distance rule (whole, one decimal under 10 cm), in the game's number
    /// language: "4.5", "12".
    static func centimetres(_ metres: Double) -> String { NumberStyle.distance(metres: metres).number }

    /// "4.5 cm from the mark", for the card and VoiceOver.
    static func fromMark(_ metres: Double) -> String {
        String(localized: "\(centimetres(metres)) cm from the mark")
    }

    /// "4.5 cm", the label beside the line on the cloth.
    static func centimetreLabel(_ metres: Double) -> String { String(localized: "\(centimetres(metres)) cm") }

    static var scoreLabel: String { String(localized: "Score") }
    /// The status line's word before the tries still to play.
    static var triesLeftLabel: String {
        String(localized: "Tries left", comment: "Shot of the day card: the word before how many of the five tries are left.")
    }
    static var streakLabel: String { String(localized: "Streak") }
    static var markLabel: String { String(localized: "From the mark") }

    /// A whole number in the game's number locale.
    static func number(_ n: Int) -> String { n.formatted(.number.locale(AppLocale.numbers)) }

    /// The streak for VoiceOver and the menu: "Streak: 3".
    static func streakSpoken(_ n: Int) -> String { String(localized: "Streak: \(n)") }

    /// "Score: 1103".
    static func scoreSpoken(_ n: Int) -> String { String(localized: "Score: \(n)") }

    /// "Next shot in 5 hr, 12 min": the time until midnight in Coordinated Universal Time, hours and minutes.
    static func nextShot(after day: Int, now: Date) -> String {
        let next = DailyBank.startDate.addingTimeInterval(Double(day + 1) * DailyBank.secondsPerDay)
        let seconds = max(60, next.timeIntervalSince(now))
        var style = Duration.UnitsFormatStyle(allowedUnits: [.hours, .minutes], width: .abbreviated)
        style.locale = AppLocale.numbers
        let left = Duration.seconds(Int64(seconds)).formatted(style)
        return String(localized: "Next shot in \(left)")
    }

    /// The five dots for VoiceOver: "Try 2 of 5", "Made on try 2 of 5" or "All 5 tries used".
    static func dotsSpoken(tries: Int, madeOnTry: Int?, total: Int) -> String {
        if let t = madeOnTry { return String(localized: "Made on try \(t) of \(total)") }
        if tries >= total { return String(localized: "All \(total) tries used") }
        return String(localized: "Try \(tries + 1) of \(total)")
    }

    // MARK: The menu row (DailyMenuRow)

    static var menuNew: String { String(localized: "One shot, the same for everyone today. Five tries.") }
    static func menuOpen(triesLeft n: Int) -> String {
        n == 1 ? String(localized: "One try left today.") : String(localized: "\(n) tries left today.")
    }
    static func menuMade(onTry t: Int, score: Int) -> String {
        String(localized: "Made on try \(t) today. Score \(score).")
    }
    static var menuMissed: String { String(localized: "Missed today. A new shot tomorrow.") }
}

// MARK: The five dots

struct DailyTryDots: View {
    let tries: Int
    let madeOnTry: Int?
    @Environment(\.palette) private var palette

    var body: some View {
        let total = DailyRecord.maxTries
        HStack(spacing: Theme.Space.xxs) {
            ForEach(1...total, id: \.self) { i in
                Image(systemName: symbol(i))
                    .foregroundStyle(colour(i))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(DailyWords.dotsSpoken(tries: tries, madeOnTry: madeOnTry, total: total))
    }

    /// The make is a tick, a used try that missed a cross, a try still to come an empty ring: told by shape, not
    /// colour alone.
    private func symbol(_ i: Int) -> String {
        if madeOnTry == i { return "checkmark.circle.fill" }
        if i <= tries { return "xmark.circle" }
        return "circle"
    }

    /// The make in pocket gold (a pass, as the result card's verdict), a used try in paper, a try to come in paper3.
    private func colour(_ i: Int) -> Color {
        if madeOnTry == i { return palette.pocket }
        if i <= tries { return palette.paper }
        return palette.paper3
    }
}

// MARK: The card

struct DailyCard: View {
    let model: ShowpieceModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The slim card on a phone held upright during a guided Lens replay (as TrickShotCard): the kit's ModeCard slims
    /// itself to its name and primary on the same flag.
    @Environment(\.lensReplayCompact) private var compact
    /// 0.7.10 wiring: "Hide the board", read live so switching it hides Board at once, as BoardButton does.
    @AppStorage(GameSettings.hideBoardKey) private var boardHidden = false

    private var trick: TrickShotMode { model.trickMode }
    private var daily: DailyMode { model.dailyMode }

    var body: some View {
        // Steps back for the Lens tips and a what-if, as the trick card does.
        if DailyMode.showing(model), let shot = daily.shot, !model.holdForTips, !model.otherFutureShowing {
            Group {
                if let day = daily.current, day.finished {
                    finished(shot, day)
                } else {
                    playing(shot)
                }
            }
            // This card decides its own slim form (its compact branches below), so the kit cards' own slimming is
            // off: the miss's sentence and the tries left stay, as before.
            .environment(\.lensReplayCompact, false)
            .animation(reduceMotion ? nil : Theme.Motion.standard, value: trick.phase)
            .transition(.opacity)
        }
    }

    /// The tries still to play, as a status figure.
    private var triesLeft: KitStatusItem {
        KitStatusItem(DailyWords.triesLeftLabel, figure: DailyWords.number(DailyRecord.maxTries - daily.triesUsed))
    }

    /// The day ("Day 12") and the tries left, the status line of every playing card.
    private func status(_ shot: DailyShot) -> [KitStatusItem] {
        [KitStatusItem(DailyWords.day(shot.dayLabel), figure: ""), triesLeft]
    }

    // MARK: Playing

    /// While the day is open: the goal, the day and tries left, "How forgiving" while the shot is set up, Take your
    /// shot or Try again. After a miss, the result card with the judge's one sentence (TrickShotJudge, as trick shots
    /// show it) and the retry's difference.
    @ViewBuilder
    private func playing(_ shot: DailyShot) -> some View {
        let dots = ModeDifficulty.dots(shot.trick.difficulty)
        switch trick.phase {
        case .judged(let verdict) where !verdict.made:
            // The judge's sentence always; the retry's difference only in the full card (as before).
            let lines = [verdict.line] + (compact ? [] : (model.retryComparison.map { [RetryWords.sentence($0)] } ?? []))
            ModeResultCard(verdict: DailyWords.missed, tone: .foul, corner: DailyWords.day(shot.dayLabel),
                           lines: lines, status: [triesLeft], next: tryAgainAction)
                .modeShortcut(tryAgainAction, .defaultAction)
        case .offScript:
            ModeCard(name: DailyWords.title, difficulty: dots, goal: DailyWords.offScript, status: status(shot),
                     primary: tryAgainAction)
                .modeShortcut(tryAgainAction, .defaultAction)
        case .aiming:
            // Lining up: the aiming panel's Shoot is the screen's one primary. Slim: the name and the tries left.
            if compact {
                ModeCard(name: DailyWords.title, difficulty: dots, goal: DailyWords.triesLeft(DailyRecord.maxTries - daily.triesUsed),
                         primary: nil)
            } else {
                ModeCard(name: DailyWords.title, difficulty: dots,
                         goal: shot.trick.usesBridge
                            ? String(localized: "\(shot.trick.goalLine) The ball is out of reach, so the bridge holds the cue.")
                            : shot.trick.goalLine,
                         status: status(shot), primary: nil) {
                    ForgivingTiles(window: shot.trick.window, isBreak: shot.trick.isBreak)
                }
            }
        default:
            // Slim: the tries left and Take your shot, no goal line and no tiles (as before).
            if compact {
                ModeCard(name: DailyWords.title, difficulty: dots,
                         goal: DailyWords.triesLeft(DailyRecord.maxTries - daily.triesUsed), primary: takeShotAction)
                    .modeShortcut(takeShotAction, .defaultAction)
            } else {
                ModeCard(name: DailyWords.title, difficulty: dots, goal: shot.trick.goalLine, status: status(shot),
                         primary: takeShotAction) {
                    ForgivingTiles(window: shot.trick.window, isBreak: shot.trick.isBreak)
                }
                .modeShortcut(takeShotAction, .defaultAction)
            }
        }
    }

    // MARK: Finished

    /// Once the day is finished (a make or five tries), and whenever the shot is opened again the same day: the result
    /// card. Made on which try (pocket gold) or five misses (warning); the distance from the mark at the lead size
    /// after a make; the streak; the score; the time until the next shot; then Watch the answer, Share (quiet,
    /// Command-S) and Board under More (Command-B) while the board may show. While the answer replays in the Lens its
    /// one idea leads the words, with the maths under "The maths" when asked for.
    @ViewBuilder
    private func finished(_ shot: DailyShot, _ day: DailyRecord.Day) -> some View {
        let watch = trick.phase == .watching ? nil : watchAction
        if compact {
            // Slim: the result's title and Watch the answer (the old slim card's one button).
            ModeCard(name: DailyWords.title, difficulty: ModeDifficulty.dots(shot.trick.difficulty),
                     goal: DailyWords.resultTitle(day), primary: watch)
                .modeShortcut(watch, .defaultAction)
        } else {
            ModeResultCard(verdict: DailyWords.resultTitle(day), tone: day.made ? .passed : .foul,
                           corner: DailyWords.day(shot.dayLabel), lines: lines(shot),
                           figure: day.made ? day.distance.map { NumberStyle.distance(metres: $0) } : nil,
                           figureCaption: DailyWords.markLabel,
                           status: [KitStatusItem(DailyWords.streakLabel,
                                                  figure: DailyWords.number(daily.streak(asOf: shot.day)))],
                           score: DailyWords.number(day.score), scoreLabel: DailyWords.scoreLabel,
                           next: watch, share: shareAction, more: [boardAction].compactMap { $0 }) {
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    if trick.phase == .explaining, trick.showMaths, let maths = shot.trick.maths {
                        SectionLabel(String(localized: "The maths"))
                        ModeMaths(maths: maths, spoken: shot.trick.mathsSpoken)
                    }
                    DailyNextShotLine(day: shot.day)
                }
            }
            // 0.7.10 everyone: Return watches the answer while it is the card's main button, Command-S shares and
            // Command-B opens the board, so the day reaches a shared result from the keyboard alone.
            .modeShortcut(watch, .defaultAction)
            .modeShortcut(shareAction, KeyboardShortcut("s", modifiers: .command))
            .modeShortcut(boardAction, KeyboardShortcut("b", modifiers: .command))
        }
    }

    /// The finished card's words: the answer playing, or its idea while it is explained; then the board's sign-in line
    /// when a sign-in from it did not work.
    private func lines(_ shot: DailyShot) -> [String] {
        var out: [String] = []
        switch trick.phase {
        case .watching: out.append(DailyWords.watching)
        case .explaining: out.append(shot.trick.idea)
        default: break
        }
        if boardAction != nil, GameCenter.shared.state == .unavailable { out.append(GameCenterWords.signInNeeded) }
        return out
    }

    // MARK: Actions

    private var takeShotAction: KitAction {
        KitAction(DailyWords.takeShot, systemImage: "target") { daily.takeShot() }
    }

    private var tryAgainAction: KitAction {
        KitAction(DailyWords.tryAgain, systemImage: "arrow.uturn.backward") { daily.tryAgain() }
    }

    private var watchAction: KitAction {
        KitAction(DailyWords.watchAnswer, systemImage: "play") { daily.watchAnswer() }
    }

    private var shareAction: KitAction {
        KitAction(DailyWords.share, systemImage: "square.and.arrow.up") { DailyShare.share(model: model) }
    }

    /// Board, only while the board may show (wave 2 connected it, "Hide the board" is off, not a test launch), as
    /// BoardButton and the phone's blurb decide.
    private var boardAction: KitAction? {
        guard let open = daily.openBoard, !boardHidden, GameCenter.enabled else { return nil }
        return KitAction(DailyWords.board, systemImage: "list.number") { open() }
    }
}

/// "Next shot in 5 hr, 12 min", in caption paper2, refreshed every half minute.
private struct DailyNextShotLine: View {
    let day: Int
    @Environment(\.palette) private var palette

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            Text(verbatim: DailyWords.nextShot(after: day, now: context.date))
                .font(Theme.caption)
                .foregroundStyle(palette.paper2)
        }
    }
}

// MARK: The phone held upright

/// The daily card's words as blurbs, for the phone held upright (TrickPhoneBlurbs hands a daily shot to this). The main
/// button is the strip's (PhonePrimaryAction.daily); the blurbs carry the words and at most two small buttons.
struct DailyPhoneBlurbs: View {
    let model: ShowpieceModel
    /// 0.7.10 wiring: "Hide the board", read live so switching it hides Board at once, as BoardButton does.
    @AppStorage(GameSettings.hideBoardKey) private var boardHidden = false

    private var trick: TrickShotMode { model.trickMode }
    private var daily: DailyMode { model.dailyMode }

    var body: some View {
        if DailyMode.showing(model), let shot = daily.shot, !model.holdForTips, !model.otherFutureShowing {
            if let day = daily.current, day.finished {
                if trick.phase == .explaining { Blurb(title: DailyWords.idea, sentence: shot.trick.idea) }
                if trick.phase == .watching {
                    Blurb(sentence: DailyWords.watching)
                } else {
                    result(shot, day)
                }
            } else {
                playing(shot)
            }
        }
    }

    @ViewBuilder
    private func playing(_ shot: DailyShot) -> some View {
        let left = DailyWords.triesLeft(DailyRecord.maxTries - daily.triesUsed)
        switch trick.phase {
        case .judged(let verdict) where !verdict.made:
            Blurb(title: DailyWords.missed, sentence: verdict.line + " " + left)
        case .offScript:
            Blurb(sentence: DailyWords.offScript)
        case .aiming:
            Blurb(sentence: shot.trick.usesBridge
                  ? String(localized: "\(shot.trick.goalLine) The ball is out of reach, so the bridge holds the cue.")
                  : shot.trick.goalLine)
        default:
            Blurb(title: DailyWords.day(shot.dayLabel), sentence: shot.trick.goalLine + " " + left)
        }
    }

    /// The result in one blurb: made on which try, the distance, the score, the streak and the next shot, with Share
    /// and (once wave 2 connects it) Board.
    private func result(_ shot: DailyShot, _ day: DailyRecord.Day) -> some View {
        // 0.8.1 store: the score, the distance from the mark and the streak as figure chips (the big-screen card's
        // three stats), so the result reads at a glance on the phone too; the sentence keeps only the next shot.
        var chips = [CaptionFigure(amount: Double(day.score), value: DailyWords.number(day.score), unit: "",
                                   label: DailyWords.scoreLabel, mark: .rolling)]
        if day.made, let d = day.distance {
            chips.append(CaptionFigure(amount: d * 100, value: DailyWords.centimetres(d), unit: "cm",
                                       label: DailyWords.markLabel, mark: .sliding))
        }
        let streak = daily.streak(asOf: shot.day)
        chips.append(CaptionFigure(amount: Double(streak), value: DailyWords.number(streak), unit: "",
                                   label: DailyWords.streakLabel, mark: .pocket))
        let parts = [DailyWords.nextShot(after: shot.day, now: Date())]
        var buttons = [BlurbButton(DailyWords.share, hint: DailyWords.shareHint) { DailyShare.share(model: model) }]
        // 0.7.10 wiring: Board only while the board may show (not hidden, not a test launch), as BoardButton decides;
        // when a sign-in from it did not work, the board's one line on where to sign in joins the sentence.
        var sentence = parts.joined(separator: ". ")
        if let open = daily.openBoard, !boardHidden, GameCenter.enabled {
            buttons.append(BlurbButton(DailyWords.board, hint: DailyWords.boardHint) { open() })
            if GameCenter.shared.state == .unavailable { sentence += " " + GameCenterWords.signInNeeded }
        }
        return Blurb(title: DailyWords.resultTitle(day), chips: chips, sentence: sentence, buttons: buttons)
    }
}

extension PhonePrimaryAction {
    /// The shot of the day's way on, for the strip on the phone held upright: Take your shot while the day is open and
    /// nothing is being lined up, Try again after a miss, Watch the answer once the day is finished. Nil while lining up,
    /// while the answer plays, and outside a daily shot.
    static func daily(_ model: ShowpieceModel) -> PhonePrimaryAction? {
        guard DailyMode.showing(model), !model.otherFutureShowing else { return nil }
        let daily = model.dailyMode
        let phase = model.trickMode.phase
        if daily.finished {
            guard phase != .watching else { return nil }
            return PhonePrimaryAction(title: DailyWords.watchAnswer, hint: DailyWords.watchAnswerHint) {
                daily.watchAnswer()
            }
        }
        switch phase {
        case .judged, .offScript:
            return PhonePrimaryAction(title: DailyWords.tryAgain, hint: DailyWords.tryAgainHint) { daily.tryAgain() }
        case .aiming, .off:
            return nil
        case .ready, .watching, .explaining:
            return PhonePrimaryAction(title: DailyWords.takeShot, hint: DailyWords.takeShotHint) { daily.takeShot() }
        }
    }
}

// MARK: On the cloth

/// The mark, drawn by TrickTableLayer's canvas through the live camera: a dashed ring a little wider than a ball with a
/// solid dot at its centre, in the accent colour; after a make, a thin line from where the white ball stopped to the
/// mark, with the distance beside it. Only for the shot of the day.
@MainActor
enum DailyMarks {
    static func draw(_ model: ShowpieceModel, accent: Color, paper: Color, in ctx: inout GraphicsContext, size: CGSize,
                     _ proj: AimProjector) {
        guard DailyMode.showing(model), let mark = model.dailyMode.mark else { return }
        let r = model.timeline.table.ballRadius
        if let ring = TablePathStroke.ring(at: mark, radius: r * 1.6, proj) {
            ctx.stroke(ring, with: .color(accent.opacity(0.9)), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
        }
        if let dot = TablePathStroke.ring(at: mark, radius: r * 0.25, proj, minPoints: 2.5, segments: 16) {
            ctx.fill(dot, with: .color(accent))
        }
        // After the make: the white ball's resting place to the mark, and how far.
        guard case .judged(let verdict) = model.trickMode.phase, verdict.made, model.aimReady,
              let attempt = model.currentAttempt, !attempt.cueBallScratched else { return }
        let rest = attempt.cueRest
        TablePathStroke(points: [rest, mark], colour: paper.opacity(0.8), lineWidth: 1.2, dash: [],
                        underlayWidth: 2.5).draw(in: &ctx, proj)
        let middle = (rest + mark) * 0.5
        TablePathStroke.label(Text(verbatim: DailyWords.centimetreLabel((rest - mark).length)), at: middle,
                              colour: paper, in: &ctx, size: size, proj)
    }
}
