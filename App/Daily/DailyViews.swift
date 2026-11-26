// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 wiring: the result card's Board is the board's own
//          BoardButton (App/GameCenter/GameCenterViews.swift); the phone's result blurb offers Board only while the
//          board may show, with the board's sign-in line when a sign-in from it failed.)
// PURPOSE: Everything the player sees of the shot of the day on the table (plans/25-Nov-2026-shot-of-the-day-plan.md,
//          stage 2 items 2 and 3), kept small so the table stays big:
//          DailyCard - the one card, where the trick card goes (TrickShotCard hands a daily shot to it, so on iPad, the
//            Mac and the open folding phone it sits in the notebook half and never covers the table). While playing:
//            the goal in one line and five dots for the tries, with Take your shot or Try again and, after a miss, the
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
//          (balls and pockets) GoalMarks through TrickTableLayer; the card's pieces follow TrickShotCard's (glassCard,
//          the button rows, the prominent style), the blurbs are App/Phone/Blurb.swift's, the rings and labels on the
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

    /// Centimetres, one decimal at most, in the game's number locale: "4.5".
    static func centimetres(_ metres: Double) -> String {
        (metres * 100).formatted(.number.locale(AppLocale.numbers).precision(.fractionLength(0...1)))
    }

    /// "4.5 cm from the mark", for the card and VoiceOver.
    static func fromMark(_ metres: Double) -> String {
        String(localized: "\(centimetres(metres)) cm from the mark")
    }

    /// "4.5 cm", the label beside the line on the cloth.
    static func centimetreLabel(_ metres: Double) -> String { String(localized: "\(centimetres(metres)) cm") }

    static var scoreLabel: String { String(localized: "Score") }
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
        HStack(spacing: 6) {
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

    private func colour(_ i: Int) -> Color {
        if madeOnTry == i { return palette.accent }
        if i <= tries { return palette.slide }
        return palette.paper.opacity(0.5)
    }
}

// MARK: The card

struct DailyCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    /// The slim card on a phone held upright during a guided Lens replay (as TrickShotCard).
    @Environment(\.lensReplayCompact) private var compact

    private var trick: TrickShotMode { model.trickMode }
    private var daily: DailyMode { model.dailyMode }

    var body: some View {
        // Steps back for the Lens tips and a what-if, as the trick card does.
        if DailyMode.showing(model), let shot = daily.shot, !model.holdForTips, !model.otherFutureShowing {
            VStack(alignment: .leading, spacing: 8) {
                header(shot)
                if let day = daily.current, day.finished {
                    finished(shot, day)
                } else {
                    playing(shot)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 22, padding: 12)
            .tint(palette.accent)
            .animation(reduceMotion ? nil : .snappy, value: trick.phase)
            .transition(.opacity)
        }
    }

    private func header(_ shot: DailyShot) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(verbatim: DailyWords.title).font(Theme.heading).lineLimit(2)
            Spacer(minLength: 0)
            Text(verbatim: DailyWords.day(shot.dayLabel)).font(Theme.label).foregroundStyle(palette.slide)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: Playing

    @ViewBuilder
    private func playing(_ shot: DailyShot) -> some View {
        let tries = daily.triesUsed
        switch trick.phase {
        case .judged(let verdict) where !verdict.made:
            line(verdict.line)
            if !compact, let c = model.retryComparison { line(RetryWords.sentence(c)) }
            dotsRow(tries: tries, made: nil, note: DailyWords.triesLeft(DailyRecord.maxTries - tries))
            buttons { tryAgainButton }
        case .offScript:
            line(DailyWords.offScript)
            dotsRow(tries: tries, made: nil, note: DailyWords.triesLeft(DailyRecord.maxTries - tries))
            buttons { tryAgainButton }
        case .aiming:
            if !compact {
                line(shot.trick.usesBridge
                     ? String(localized: "\(shot.trick.goalLine) The ball is out of reach, so the bridge holds the cue.")
                     : shot.trick.goalLine)
            }
            dotsRow(tries: tries, made: nil, note: DailyWords.triesLeft(DailyRecord.maxTries - tries))
        default:
            if !compact { line(shot.trick.goalLine) }
            dotsRow(tries: tries, made: nil, note: DailyWords.triesLeft(DailyRecord.maxTries - tries))
            buttons {
                styled(Button { daily.takeShot() } label: {
                    Label(DailyWords.takeShot, systemImage: "target").font(.headline).lineLimit(1)
                        .frame(minHeight: Self.buttonHeight)
                }, prominent: true)
                .keyboardShortcut(.defaultAction)
                .accessibilityHint(DailyWords.takeShotHint)
            }
        }
    }

    // MARK: Finished

    @ViewBuilder
    private func finished(_ shot: DailyShot, _ day: DailyRecord.Day) -> some View {
        switch trick.phase {
        case .watching:
            line(DailyWords.watching)
        case .explaining:
            if !compact {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill").foregroundStyle(palette.slide).accessibilityHidden(true)
                    Text(verbatim: DailyWords.idea).font(Theme.label).foregroundStyle(palette.slide)
                }
                line(shot.trick.idea)
                if trick.showMaths, let maths = shot.trick.maths {
                    Text(verbatim: maths)
                        .font(Theme.equation)
                        .foregroundStyle(palette.paper)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(shot.trick.mathsSpoken ?? maths)
                }
            }
        default:
            EmptyView()
        }
        if !compact {
            HStack(spacing: 8) {
                Image(systemName: day.made ? "checkmark.seal.fill" : "calendar.badge.clock")
                    .foregroundStyle(day.made ? palette.accent : palette.slide)
                    .accessibilityHidden(true)
                Text(verbatim: DailyWords.resultTitle(day)).font(Theme.heading)
            }
            .accessibilityElement(children: .combine)
            DailyTryDots(tries: day.tries, madeOnTry: day.madeOnTry)
            stats(shot, day)
            TimelineView(.periodic(from: .now, by: 30)) { context in
                Text(verbatim: DailyWords.nextShot(after: shot.day, now: context.date))
                    .font(Theme.label)
                    .foregroundStyle(.secondary)
            }
        }
        if trick.phase != .watching {
            buttons {
                styled(Button { daily.watchAnswer() } label: {
                    Label(DailyWords.watchAnswer, systemImage: "play.fill").font(.headline).lineLimit(1)
                        .frame(minHeight: Self.buttonHeight)
                }, prominent: trick.phase != .explaining)
                // 0.7.10 everyone: Return watches the answer while it is the card's main button (keyboard alone).
                .keyboardShortcut(trick.phase != .explaining ? KeyboardShortcut.defaultAction : nil)
                .accessibilityHint(DailyWords.watchAnswerHint)
                if !compact {
                    styled(Button { DailyShare.share(model: model) } label: {
                        Label(DailyWords.share, systemImage: "square.and.arrow.up").font(.headline).lineLimit(1)
                            .frame(minHeight: Self.buttonHeight)
                    }, prominent: false)
                    // 0.7.10 everyone: Command-S shares, so the day reaches a shared result from the keyboard alone.
                    .keyboardShortcut("s", modifiers: .command)
                    .accessibilityHint(DailyWords.shareHint)
                    // Wave 2: hidden until Game Center is connected (DailyMode.openBoard).
                    // 0.7.10 wiring: the board's own button (GameCenterViews.swift): it draws nothing with "Hide the
                    // board" on, signs in the first time it is pressed, and says where to sign in if that fails.
                    if daily.openBoard != nil {
                        styled(BoardButton().font(.headline), prominent: false)
                            .frame(minHeight: Self.buttonHeight)
                            // 0.7.10 everyone: Command-B opens the board from the keyboard.
                            .keyboardShortcut("b", modifiers: .command)
                            .accessibilityHint(DailyWords.boardHint)
                    }
                }
            }
        }
    }

    /// Score, distance from the mark (a make only) and streak, side by side.
    private func stats(_ shot: DailyShot, _ day: DailyRecord.Day) -> some View {
        HStack(spacing: 8) {
            stat(DailyWords.scoreLabel, DailyWords.number(day.score))
            if day.made, let d = day.distance {
                stat(DailyWords.markLabel, DailyWords.centimetreLabel(d))
            }
            stat(DailyWords.streakLabel, DailyWords.number(daily.streak(asOf: shot.day)))
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: value).font(Theme.figure)
            Text(verbatim: label).font(Theme.figureLabel).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 10))
        .accessibilityElement(children: .combine)
    }

    // MARK: Pieces (as TrickShotCard's)

    private func dotsRow(tries: Int, made: Int?, note: String) -> some View {
        HStack(spacing: 10) {
            DailyTryDots(tries: tries, madeOnTry: made)
            Text(verbatim: note).font(Theme.label).foregroundStyle(.secondary)
        }
    }

    private var tryAgainButton: some View {
        styled(Button { daily.tryAgain() } label: {
            Label(DailyWords.tryAgain, systemImage: "arrow.uturn.backward").font(.headline).lineLimit(1)
                .frame(minHeight: Self.buttonHeight)
        }, prominent: true)
        .keyboardShortcut(.defaultAction)
        .accessibilityHint(DailyWords.tryAgainHint)
    }

    private func line(_ text: String) -> some View {
        Text(verbatim: text)
            .font(Theme.body)
            .foregroundStyle(palette.paper.opacity(0.9))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// One row of buttons, right-aligned; two rows when the text is too large for one.
    private func buttons<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        let row = content()
        return Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .trailing, spacing: 8) { row }.frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { Spacer(minLength: 0); row }
                    WrappingRow { row }.frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .controlSize(.regular)
    }

    @ViewBuilder
    private func styled(_ button: some View, prominent: Bool) -> some View {
        if prominent {
            // Dark text on the bright accent, as the trick card's.
            button.buttonStyle(.glassProminent).foregroundStyle(palette.ground)
        } else {
            button.buttonStyle(.glass)
        }
    }

    /// The glass button adds its own padding; this lands the buttons on 44 points or more on a touch screen.
    #if os(iOS)
    private static let buttonHeight: CGFloat = 30
    #else
    private static let buttonHeight: CGFloat = 0
    #endif
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
        var parts = [DailyWords.scoreSpoken(day.score)]
        if day.made, let d = day.distance { parts.append(DailyWords.fromMark(d)) }
        parts.append(DailyWords.streakSpoken(daily.streak(asOf: shot.day)))
        parts.append(DailyWords.nextShot(after: shot.day, now: Date()))
        var buttons = [BlurbButton(DailyWords.share, hint: DailyWords.shareHint) { DailyShare.share(model: model) }]
        // 0.7.10 wiring: Board only while the board may show (not hidden, not a test launch), as BoardButton decides;
        // when a sign-in from it did not work, the board's one line on where to sign in joins the sentence.
        var sentence = parts.joined(separator: ". ") + "."
        if let open = daily.openBoard, !boardHidden, GameCenter.enabled {
            buttons.append(BlurbButton(DailyWords.board, hint: DailyWords.boardHint) { open() })
            if GameCenter.shared.state == .unavailable { sentence += " " + GameCenterWords.signInNeeded }
        }
        return Blurb(title: DailyWords.resultTitle(day), sentence: sentence, buttons: buttons)
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
