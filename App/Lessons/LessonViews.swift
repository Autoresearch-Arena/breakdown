// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink wave 3 note 22: every result card (passed, made, missed,
//          in each step) carries the one share picture's quiet Share, ResultShare from App/SharePicture.swift.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 5, the mode frame: the list is the kit's sheet
//          page with the kit's list rows (number or tick, title and hook, five dots from the trick shot built on the
//          lesson's idea, a small drawing of the start layout); the card is the kit's mode card in every phase, with
//          "How forgiving" tiles from the lesson's measured window while it is set up and lined up, and the kit-style
//          result card once judged (the step's name on its right). The slim form keeps its own rule: the full card on
//          the lesson's moment (#38). The glow follows the screen's own corners.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2: one meaning per colour. Fouls, misses and
//          refusals take Palette.warning; headings, try counts, tags and difficulty take paper or paper2; the sliding
//          magenta is left for sliding and friction.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream cards, plans/22-Nov-2026-phone-bug-hunt.md #38: paused
//          on the lesson's moment the card shows the idea and its buttons even in the slim form, so the lesson no longer
//          freezes on its moment with only a heading and Your turn.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan items 11, 36 and 53: the made-it sound plays with the pass
//          glow (SoundBoard.play, the big one for the sixth lesson); a missed pass shot also offers "Back to the lesson's
//          stroke"; the try-3 and pass-shot lines say when the power is held at the lesson's stroke; the card steps back
//          while the Lens tips are up (model.holdForTips), so the tips never stack on the lesson's own card.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (access stream hook, 0.7.0 item 44: Next lesson's and Next step's arrows follow the
//          reading direction, so they point left in Arabic.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 gaps, item 53: the rings LessonTableLayer draws on the cloth
//          stand back while the Lens tips are up too, as the card already did, so the tips are alone on screen.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 learn-modes stream, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          items 9, 11 and 12: the rings and the finish circle are drawn by GoalMarks (TrickShotViews.swift), shared with
//          the trick-shot layer; the card steps aside while a what-if is open and shows its slim form (the heading and
//          the main button) during a guided Lens replay on a phone held upright; the list's Mac minimum size applies
//          only as a sheet, not as a page of the notebook.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (phone UI plan, Part 4 step 5: LessonPhoneBlurbs, the lesson card's
//          words as blurbs on the phone held upright, and PhonePrimaryAction.lesson, its main button as the strip's
//          primary action; the step words moved into LessonWords so the card and the blurbs say the same; the pass's
//          success haptic moved from the card to LessonTableLayer, which is on screen in every layout.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 coordinator: what steps aside for the what-if now also steps
//          aside for the every-surface fan, through model.otherFutureShowing.)
// PURPOSE: Everything the player sees of lesson mode (LessonMode), kept small so the table stays big, on the trick-shot
//          views' pattern:
//          LessonList       - the six lessons in a sheet from the menu's Learn (a page of the notebook on the open
//                             folding phone, iPad and Mac): number or a tick once passed, title and one line, five
//                             dots and the start layout drawn small. Nothing is locked: any lesson can be opened at any
//                             time.
//          LessonCard       - the kit's mode card above the controls (or in the side column, or as a card of the
//                             notebook panel): the lesson and Watch it; what to watch for while it plays; the idea while
//                             the replay is paused on the lesson's moment, with Your turn; for each try a line saying
//                             what is set, what is open and where the marks are; then Made it or Missed with the judge's
//                             one line, the retry's one-sentence difference (RetryWords) and See the contact
//                             (ContactButton), with Try again and Next step. A passed lesson suggests the trick shot that
//                             uses the idea and the next lesson; the stop shot also offers its second exercise. This is
//                             the one result card while a lesson is up (the general comparison card steps aside).
//          LessonPhoneBlurbs - the phone held upright only (ShowpieceView's dock): the card's words without the card, as
//                             blurbs (App/Phone/Blurb.swift). The lesson's name is the title row's, the main button is the
//                             strip's primary action (PhonePrimaryAction.lesson, below), the list and Watch again are in
//                             the title row's More menu; what is left is the hook, what to watch for, the idea (folded to
//                             one line while the replay runs toward the moment, three lines once it holds there), each
//                             step's line, the verdict with the retry's difference, and at most two small buttons.
//          LessonWords      - the step's name ("Try 2 of 3") and its line (what is set, open and marked), shared by the
//                             card and the blurbs.
//          LessonTableLayer - over the 3D table, never taking touches: rings on the balls the goal names and on their
//                             pocket, the cue ball's finish circle, and a short glow when a lesson is passed. It hosts the
//                             list sheet, forwards the model's playback changes to LessonMode.update() and its clock to
//                             tick() (so the Lens replay stops on the lesson's moment), and opens or closes the shot panel
//                             when the mode asks.
//          The kit's sheet page, list row, mode card and buttons, Dynamic Type (button rows wrap, text wraps),
//          VoiceOver (the card's header and state read as one; the step line says which controls are locked), Reduce
//          Motion (the glow only fades; the card changes without animation).
// SRP/DRY check: Pass - views only. Flow is LessonMode, data Lessons; projection to the screen is AimProjector, the
//          card, rows and sheet the kit's (difficulty, forgiving tiles and result card from ModeFrameKit.swift), the result card's retry pieces RetryWords and ContactButton, as in
//          TrickShotViews. The trick card itself is not reused because its phases and buttons differ step by step.
import BreakdownLensModel
import BreakdownPhysics
import SwiftUI

// MARK: The list

struct LessonList: View {
    let mode: LessonMode
    /// True when the list is a page of the notebook (iPad, Mac, the open Duo) rather than a sheet of its own.
    @Environment(\.inlinePages) private var inlinePages

    var body: some View {
        // UI rethink package 5: the kit's sheet page and list rows, as the trick shots and Behind the 8-Ball lists.
        // Done closes the list, as Close did.
        SheetPage(title: String(localized: "Lessons"), onDone: { mode.listOpen = false }) {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                ForEach(Lessons.all) { lesson in
                    Button { mode.begin(lesson) } label: { row(lesson) }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(spoken(lesson))
                        .accessibilityHint(String(localized: "Sets up the lesson on the table"))
                }
            }
        } footer: {
            Text("Watch each lesson, try it three times with less help each time, then pass it on your own.")
        }
        #if os(macOS)
        // A sheet's own minimum size; as a page of the Mac notebook it takes the panel's size (0.7.5: the minimum
        // pushed the list past the panel's edge). Nil sizes rather than an if, so the view keeps its identity.
        .frame(minWidth: inlinePages ? nil : 460, minHeight: inlinePages ? nil : 520)
        #endif
    }

    /// The kit's list row: the lesson's number (a tick once passed), title and hook, five dots, and its start layout.
    private func row(_ lesson: Lesson) -> some View {
        let leading: ListRow<DifficultyDots, ModeStartThumb>.Leading = mode.isDone(lesson) ? .done : .number(lesson.number)
        return ListRow(leading: leading, title: lesson.title, line: lesson.hook,
                       difficulty: { DifficultyDots(level: ModeDifficulty.dots(lesson: lesson)) },
                       picture: { ModeStartThumb(layout: lesson.layout) })
    }

    private func spoken(_ lesson: Lesson) -> String {
        let state = mode.isDone(lesson) ? String(localized: "passed") : String(localized: "not passed yet")
        return String(localized: "Lesson \(lesson.number), \(lesson.title), \(state). \(lesson.hook)")
    }
}

// MARK: The card

struct LessonCard: View {
    let model: ShowpieceModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// On a phone held upright while a guided Lens replay plays (set by ShowpieceView, App/LayoutFlags.swift): the slim
    /// card, heading and main button only, so the table keeps its height. The kit's ModeCard slims itself on the same
    /// flag; this card picks the one action it keeps.
    @Environment(\.lensReplayCompact) private var compact

    private var mode: LessonMode { model.lessonMode }

    var body: some View {
        // While the Lens tips are showing over a held beat (model.holdForTips, set by the tips themselves), they are the
        // one card: this card steps back and returns when they are done, so the key moment's idea is never stacked
        // under the tips (review of 0.6.6, item 53). The replay cannot reach the key moment meanwhile: the clock holds.
        // While a what-if is open on the try (0.7.5, WhatIfFork.isShowing) its card is the one result card: this one
        // steps aside and comes back, unchanged, when the what-if closes.
        if let lesson = mode.current, mode.isActive, !model.holdForTips, !model.otherFutureShowing {
            Group {
                // Paused on the lesson's moment the full card shows, slim or not: the idea is the reason the replay
                // stopped there (0.7.6, #38; the guided flag stays on while the clock is held on the moment). The kit
                // card's own slimming is turned off there for the same reason.
                if compact && mode.phase != .keyMoment {
                    slim(lesson)
                } else {
                    content(lesson).environment(\.lensReplayCompact, false)
                }
            }
            .animation(reduceMotion ? nil : Theme.Motion.standard, value: mode.phase)
            // The pass's success haptic is LessonTableLayer's (with the glow and the sound), so it fires in every layout.
            .transition(.opacity)
        }
    }

    /// The lesson's name as the card's name: "Lesson 2: Follow".
    private func name(_ lesson: Lesson) -> String { String(localized: "Lesson \(lesson.number): \(lesson.title)") }

    @ViewBuilder
    private func content(_ lesson: Lesson) -> some View {
        let dots = ModeDifficulty.dots(lesson: lesson)
        switch mode.phase {
        case .ready:
            // Watching first is the lesson's path, but nothing is gated: a player who knows the shot may go straight to
            // the first try.
            ModeCard(name: name(lesson), difficulty: dots, goal: lesson.hook,
                     primary: watchAction, secondary: turnAction, more: [listAction]) {
                ForgivingTiles(window: lesson.window, isBreak: false)
            }
            .modeShortcut(watchAction, .defaultAction)
        case .watching, .replaying:
            ModeCard(name: name(lesson), difficulty: dots,
                     goal: mode.phase == .watching
                        ? String(localized: "Watch a perfect example. \(lesson.goalLine)")
                        : String(localized: "Now slowed down in the Physics Lens. It stops on the moment that matters."),
                     primary: turnAction)
        case .keyMoment:
            ModeCard(name: name(lesson), difficulty: dots, goal: lesson.idea,
                     primary: turnAction, secondary: watchAgainAction)
                .modeShortcut(turnAction, .defaultAction)
        case .aiming(let step):
            // Lining up: the aiming panel's Shoot is the screen's one primary. The step's name leads its line, as the
            // card's corner said it before.
            ModeCard(name: name(lesson), difficulty: dots, goal: aimingLine(lesson, step),
                     primary: nil, more: [listAction]) {
                ForgivingTiles(window: step == .exercise ? Lessons.stopExercise.window : lesson.window, isBreak: false)
            }
        case .judged(let step, let verdict):
            judged(lesson, step, verdict)
        case .offScript:
            ModeCard(name: name(lesson), difficulty: dots,
                     goal: String(localized: "That shot started from where the balls stopped. Try again puts them back for the lesson."),
                     primary: tryAgainAction)
                .modeShortcut(tryAgainAction, .defaultAction)
        case .off:
            EmptyView()
        }
    }

    /// The step's name, what is set, open and marked in it, and for the pass shot and the exercise their goal.
    private func aimingLine(_ lesson: Lesson, _ step: LessonMode.Step) -> String {
        var parts = [LessonWords.stepName(step) + ".", LessonWords.stepLine(lesson, step, powerHeld: mode.powerHeld)]
        if step == .pass { parts.append(lesson.goalLine) }
        if step == .exercise { parts.append(Lessons.stopExercise.trick.goalLine) }
        return parts.joined(separator: " ")
    }

    /// Lesson passed, Made it or Missed in the result card, the step's name on its right; the judge's line, the retry's
    /// one difference (RetryWords) and, after a pass, the trick shot built on the idea. The way on bottom right:
    ///   passed:               Next lesson, with Try the trick shot beside it; A new distance (the stop lesson) under More;
    ///   the pass shot missed: Try again, with Back to the lesson's stroke beside it;
    ///   the exercise:         Try again (primary after a miss), All lessons under More after a make;
    ///   a guided try:         Next step after a make, Try again after a miss, the other beside it.
    /// See the contact is under More whenever the cue ball touched a ball; Share is quiet on the left of every result.
    @ViewBuilder
    private func judged(_ lesson: Lesson, _ step: LessonMode.Step, _ verdict: TrickVerdict) -> some View {
        let passed = verdict.made && step == .pass
        let contact = ContactButton.kitAction(model: model, reduceMotion: reduceMotion)
        let word = passed ? String(localized: "Lesson passed")
            : (verdict.made ? String(localized: "Made it!") : String(localized: "Missed"))
        let tone: ResultTone = verdict.made ? .passed : .foul
        let corner = LessonWords.stepName(step)
        let lines = judgedLines(passed: passed, verdict)
        // The one share picture's quiet Share (package 10), nil while no shot is on the table.
        let share = ResultShare.action(model: model, mode: String(localized: "Lessons"), corner: corner,
                                       verdict: word, tone: tone)
        if passed {
            let trick = mode.suggestedTrick.map { _ in
                KitAction(String(localized: "Try the trick shot"), systemImage: "wand.and.sparkles") {
                    mode.playSuggestedTrick()
                }
            }
            let distance = lesson.id == Lessons.stop.id
                ? KitAction(String(localized: "A new distance"), systemImage: "arrow.left.and.right") { mode.startExercise() }
                : nil
            ModeResultCard(verdict: word, tone: tone, corner: corner, lines: lines,
                           tryAgain: trick, next: nextLessonAction,
                           share: share, more: [distance, contact].compactMap { $0 })
                .modeShortcut(nextLessonAction, .defaultAction)
        } else if step == .pass {
            // A missed pass shot: Try again keeps the player's own settings; this puts the lesson's stroke back.
            let back = KitAction(String(localized: "Back to the lesson's stroke"), systemImage: "arrow.counterclockwise") {
                mode.backToLessonStroke()
            }
            ModeResultCard(verdict: word, tone: tone, corner: corner, lines: lines,
                           tryAgain: back, next: tryAgainAction, share: share, more: [contact].compactMap { $0 })
                .modeShortcut(tryAgainAction, .defaultAction)
        } else if step == .exercise {
            if verdict.made {
                ModeResultCard(verdict: word, tone: tone, corner: corner, lines: lines,
                               tryAgain: tryAgainAction, share: share, more: [listAction, contact].compactMap { $0 })
            } else {
                ModeResultCard(verdict: word, tone: tone, corner: corner, lines: lines,
                               next: tryAgainAction, share: share, more: [contact].compactMap { $0 })
                    .modeShortcut(tryAgainAction, .defaultAction)
            }
        } else if verdict.made {
            ModeResultCard(verdict: word, tone: tone, corner: corner, lines: lines,
                           tryAgain: tryAgainAction, next: nextStepAction, share: share, more: [contact].compactMap { $0 })
                .modeShortcut(nextStepAction, .defaultAction)
        } else {
            ModeResultCard(verdict: word, tone: tone, corner: corner, lines: lines,
                           tryAgain: nextStepAction, next: tryAgainAction, share: share, more: [contact].compactMap { $0 })
                .modeShortcut(tryAgainAction, .defaultAction)
        }
    }

    /// The judge's line, the retry's difference and, after a pass, the trick shot built on the idea.
    private func judgedLines(passed: Bool, _ verdict: TrickVerdict) -> [String] {
        var lines = [verdict.line]
        // After a retry, the one difference between the two tries, here on the one result card.
        if let c = model.retryComparison { lines.append(RetryWords.sentence(c)) }
        if passed, let trick = mode.suggestedTrick {
            lines.append(String(localized: "The trick shot \(trick.title) is built on this idea."))
        }
        return lines
    }

    /// The slim card (0.7.5, lensReplayCompact): the lesson's name and the one action that moves the lesson on, so a
    /// guided Lens replay on a phone held upright keeps the table its height. Your turn during the Watch beat; after a
    /// try, Next lesson for a pass, Next step for a made guided try, Try again otherwise; the name alone while aiming.
    /// Never used for the key moment itself (body shows the full card there, with the idea).
    @ViewBuilder
    private func slim(_ lesson: Lesson) -> some View {
        let dots = ModeDifficulty.dots(lesson: lesson)
        switch mode.phase {
        case .ready, .watching, .replaying, .keyMoment:
            ModeCard(name: name(lesson), difficulty: dots, goal: lesson.hook, primary: turnAction)
        case .judged(let step, let verdict):
            let action = verdict.made && step == .pass ? nextLessonAction
                : (verdict.made && step != .exercise ? nextStepAction : tryAgainAction)
            ModeCard(name: name(lesson), difficulty: dots, goal: verdict.line, primary: action)
        case .offScript:
            ModeCard(name: name(lesson), difficulty: dots, goal: lesson.goalLine, primary: tryAgainAction)
        case .aiming:
            ModeCard(name: name(lesson), difficulty: dots, goal: lesson.goalLine, primary: nil)
        case .off:
            EmptyView()
        }
    }

    // MARK: Actions

    private var watchAction: KitAction {
        KitAction(String(localized: "Watch it"), systemImage: "play") { mode.watch() }
    }

    private var watchAgainAction: KitAction {
        KitAction(String(localized: "Watch again"), systemImage: "arrow.counterclockwise") { mode.watch() }
    }

    private var turnAction: KitAction {
        KitAction(String(localized: "Your turn"), systemImage: "target") { mode.yourTurn() }
    }

    private var tryAgainAction: KitAction {
        KitAction(String(localized: "Try again"), systemImage: "arrow.uturn.backward") { mode.tryAgain() }
    }

    private var nextLessonAction: KitAction {
        KitAction(String(localized: "Next lesson"), systemImage: "arrow.forward") { mode.nextLesson() }
    }

    private var nextStepAction: KitAction {
        KitAction(String(localized: "Next step"), systemImage: "arrow.forward") { mode.nextStep() }
    }

    private var listAction: KitAction {
        KitAction(String(localized: "All lessons"), systemImage: "list.bullet") { mode.listOpen = true }
    }
}

// MARK: Words shared by the card and the blurbs

/// The lesson's step words, one copy for LessonCard and LessonPhoneBlurbs.
enum LessonWords {
    /// "Try 1 of 3" and so on, for the card's corner.
    static func stepName(_ step: LessonMode.Step) -> String {
        switch step {
        case .try1: return String(localized: "Try 1 of 3")
        case .try2: return String(localized: "Try 2 of 3")
        case .try3: return String(localized: "Try 3 of 3")
        case .pass: return String(localized: "Pass shot")
        case .exercise: return String(localized: "A new distance")
        }
    }

    /// What is set, what is open and what is marked in this step.
    static func stepLine(_ lesson: Lesson, _ step: LessonMode.Step, powerHeld: Bool) -> String {
        switch step {
        case .try1:
            return String(localized: "Everything is set for you and locked. Just shoot and watch it work.")
        case .try2:
            switch lesson.control {
            case .tipUp: return String(localized: "Only the tip height is open. Move the dot on the cue ball into the marked band.")
            case .tipSide: return String(localized: "Only the side spin is open. Move the dot on the cue ball into the marked band.")
            case .aim: return String(localized: "Only the aim is open. Swing the line into the marked fan.")
            case .power: return String(localized: "Only the power is open. Set it inside the marked part of the bar.")
            case .elevation: return String(localized: "Only the cue angle is open. Pick one of the marked angles.")
            }
        // In a lesson not about power, try 3 and the pass shot hold the power at the lesson's stroke (LessonMode.powerHeld),
        // and the line says so: the power bar shows a lock.
        case .try3:
            return powerHeld
                ? String(localized: "Every control but the power is open now, and the marks are faint. The power stays at the lesson's stroke.")
                : String(localized: "Every control is open now, and the marks are faint.")
        case .pass:
            return powerHeld
                ? String(localized: "No marks now. Everything but the power is yours, and the power stays at the lesson's stroke. Make it on your own to pass.")
                : String(localized: "No marks and nothing locked. Make it on your own to pass.")
        case .exercise:
            return String(localized: "Same line, the cue ball further back, your lesson stroke set up. Before you shoot, say where the cue ball will go. Then change only the tip height to stop it dead.")
        }
    }
}

// MARK: The phone held upright

/// The lesson card's words as blurbs, docked at the top of the table area on the phone held upright (ShowpieceView's
/// dock; phone UI plan, Part 3 and Part 4 step 5). One blurb for the phase, plus the idea while the demonstration
/// replays and holds on its moment, or whenever the title has opened it. Shows nothing outside a lesson, while the Lens
/// tips hold a beat and while a what-if is open, as the card stepped back for both.
struct LessonPhoneBlurbs: View {
    let model: ShowpieceModel
    /// The idea is open: the title row's tap and a tap on the idea blurb both toggle it (ShowpieceView owns it).
    @Binding var ideaOpen: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var mode: LessonMode { model.lessonMode }

    var body: some View {
        if let lesson = mode.current, mode.isActive, !model.holdForTips, !model.otherFutureShowing {
            if mode.phase == .replaying || mode.phase == .keyMoment || ideaOpen { idea(lesson) }
            phaseBlurb(lesson)
        }
    }

    /// Blurb's fold switch is true when folded; ideaOpen is true when open. One binding turns one into the other.
    private var ideaFolded: Binding<Bool> {
        Binding(get: { !ideaOpen }, set: { ideaOpen = !$0 })
    }

    /// "The idea": one line with its more dot while the slow replay runs toward the moment, so the table keeps the
    /// room; three lines once the replay holds on the moment, because the idea is why it stopped there (0.7.6, #38).
    private func idea(_ lesson: Lesson) -> some View {
        Blurb(title: String(localized: "The idea"), sentence: lesson.idea, folded: ideaFolded,
              foldedLines: mode.phase == .keyMoment ? 3 : 1)
    }

    /// The phase's own words. Watch it, Your turn, Next step, Next lesson and Try again are the strip's primary action
    /// (PhonePrimaryAction.lesson); the replay and the moment have the idea alone.
    @ViewBuilder
    private func phaseBlurb(_ lesson: Lesson) -> some View {
        switch mode.phase {
        case .ready:
            // The hook, and Your turn for a player who knows the shot (nothing is gated; Watch it is the primary action).
            Blurb(sentence: lesson.hook, buttons: [
                BlurbButton(String(localized: "Your turn"),
                            hint: String(localized: "Puts the balls back and opens the aiming controls")) { mode.yourTurn() }
            ])
        case .watching:
            Blurb(sentence: String(localized: "Watch a perfect example. \(lesson.goalLine)"))
        case .aiming(let step):
            Blurb(title: LessonWords.stepName(step), sentence: aimingSentence(lesson, step))
        case .judged(let step, let verdict):
            judged(lesson, step, verdict)
        case .offScript(let step):
            Blurb(title: LessonWords.stepName(step),
                  sentence: String(localized: "That shot started from where the balls stopped. Try again puts them back for the lesson."))
        case .replaying, .keyMoment, .off:
            EmptyView()
        }
    }

    /// What is set, open and marked in this step; the pass shot and the exercise add their goal, as the card did.
    private func aimingSentence(_ lesson: Lesson, _ step: LessonMode.Step) -> String {
        let line = LessonWords.stepLine(lesson, step, powerHeld: mode.powerHeld)
        switch step {
        case .pass: return line + " " + lesson.goalLine
        case .exercise: return line + " " + Lessons.stopExercise.trick.goalLine
        case .try1, .try2, .try3: return line
        }
    }

    /// Lesson passed, Made it or Missed with the step's name; the judge's line, the retry's one difference (RetryWords)
    /// and, after a pass, the trick shot built on the idea. Two small buttons at most, in this order of need:
    ///   passed:                the suggested trick shot, then the stop lesson's new distance (See the contact drops);
    ///   a guided try made:     Try again, See the contact;
    ///   a guided try missed:   Next step (nothing is gated), See the contact;
    ///   the pass shot missed:  Back to the lesson's stroke, See the contact;
    ///   the exercise:          Try again once made, See the contact.
    private func judged(_ lesson: Lesson, _ step: LessonMode.Step, _ verdict: TrickVerdict) -> some View {
        let passed = verdict.made && step == .pass
        var sentence = verdict.line
        if let c = model.retryComparison { sentence += " " + RetryWords.sentence(c) }
        if passed, let trick = mode.suggestedTrick {
            sentence += " " + String(localized: "The trick shot \(trick.title) is built on this idea.")
        }
        let contact = ContactButton.blurbButton(model: model, reduceMotion: reduceMotion)
        var buttons: [BlurbButton] = []
        if passed {
            if mode.suggestedTrick != nil {
                buttons.append(BlurbButton(String(localized: "Try the trick shot")) { mode.playSuggestedTrick() })
            }
            if lesson.id == Lessons.stop.id {
                buttons.append(BlurbButton(String(localized: "A new distance"),
                                           hint: String(localized: "The same pot with the cue ball further back")) {
                    mode.startExercise()
                })
            }
        } else if step == .pass {
            buttons.append(BlurbButton(String(localized: "Back to the lesson's stroke"),
                                       hint: String(localized: "Puts the balls back with the lesson's own aim, power and spin")) {
                mode.backToLessonStroke()
            })
        } else if step == .exercise {
            if verdict.made { buttons.append(tryAgain) }
        } else if verdict.made {
            buttons.append(tryAgain)
        } else {
            buttons.append(BlurbButton(String(localized: "Next step"),
                                       hint: String(localized: "Goes on to the next try, with less help")) { mode.nextStep() })
        }
        if let contact { buttons.append(contact) }
        let word = passed ? String(localized: "Lesson passed")
            : (verdict.made ? String(localized: "Made it!") : String(localized: "Missed"))
        // "Missed · Try 2 of 3": the result, then the step, as the card's header and its corner said. The Blurb draws
        // at most two buttons, so the order above decides which survive.
        return Blurb(title: "\(word) · \(LessonWords.stepName(step))", sentence: sentence, buttons: buttons)
    }

    private var tryAgain: BlurbButton {
        BlurbButton(String(localized: "Try again"),
                    hint: String(localized: "Puts the balls back where the shot started, with your last aim, power and spin")) {
            mode.tryAgain()
        }
    }
}

extension PhonePrimaryAction {
    /// The lesson's way on, the old card's prominent button (phone UI plan, Part 3 "The control strip"), in the
    /// lesson's own words: "Watch it" before the demonstration; "Your turn" while it plays, replays and holds on its
    /// moment (one word for the whole demonstration); after a guided try "Next step" for a make and "Try again" for a
    /// miss; "Next lesson" once passed; "Try again" after a missed pass shot, a missed exercise or an off-script shot.
    /// Nil while lining up (the aiming panel is the way on), after a made exercise (the card's way on there was the
    /// list, now in the title row's More menu), outside a lesson, and while a what-if is open.
    static func lesson(_ model: ShowpieceModel) -> PhonePrimaryAction? {
        let mode = model.lessonMode
        guard mode.isActive, !model.otherFutureShowing else { return nil }
        let tryAgain = PhonePrimaryAction(
            title: String(localized: "Try again"),
            hint: String(localized: "Puts the balls back where the shot started, with your last aim, power and spin")) {
            mode.tryAgain()
        }
        switch mode.phase {
        case .ready:
            return PhonePrimaryAction(title: String(localized: "Watch it"),
                                      hint: String(localized: "Plays a perfect example, then slows it down in the Physics Lens")) {
                mode.watch()
            }
        case .watching, .replaying, .keyMoment:
            return PhonePrimaryAction(title: String(localized: "Your turn"),
                                      hint: String(localized: "Puts the balls back and opens the aiming controls")) {
                mode.yourTurn()
            }
        case .judged(let step, let verdict):
            switch (step, verdict.made) {
            case (.pass, true):
                return PhonePrimaryAction(title: String(localized: "Next lesson")) { mode.nextLesson() }
            case (.exercise, true):
                return nil
            case (.pass, false), (.exercise, false):
                return tryAgain
            case (_, true):
                return PhonePrimaryAction(title: String(localized: "Next step"),
                                          hint: String(localized: "Goes on to the next try, with less help")) {
                    mode.nextStep()
                }
            case (_, false):
                return tryAgain
            }
        case .offScript:
            return tryAgain
        case .aiming, .off:
            return nil
        }
    }
}

// MARK: Over the table

struct LessonTableLayer: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    @Binding var shotPanelOpen: Bool
    @Environment(\.inlinePages) private var inlinePages
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var cameraBox = AimProjector.CameraBox()
    @State private var glow = 0.0

    private var mode: LessonMode { model.lessonMode }

    var body: some View {
        @Bindable var mode = mode
        ZStack {
            if mode.markers != nil {
                TimelineView(.animation) { _ in
                    Canvas { ctx, size in drawMarkers(&ctx, size: size) }
                }
            }
            // A lesson passed: a short glow around the edge of the screen. It only fades, the same with Reduce Motion.
            // The screen's own corners (ContainerRelativeShape), not a card's: no corner number of its own.
            ContainerRelativeShape()
                .strokeBorder(palette.accent, lineWidth: 6)
                .blur(radius: 10)
                .opacity(glow)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .accessibilityHidden(true)
        // In the notebook the list is a page of the side panel (inlinePages), so the table is never covered. The setter
        // ignores the dismissal SwiftUI sends when the screen turns into that layout (as TrickTableLayer).
        .sheet(isPresented: Binding(get: { mode.listOpen && !inlinePages }, set: { if !inlinePages { mode.listOpen = $0 } })) {
            LessonList(mode: mode)
        }
        // The mode learns that a shot finished from these two, and watches the clock for the Watch beat's moment.
        .onChange(of: model.aimReady) { _, _ in mode.update() }
        .onChange(of: model.timelineVersion) { _, _ in mode.update() }
        .onChange(of: model.time) { _, _ in mode.tick() }
        .onChange(of: mode.aimingRequests) { _, _ in shotPanelOpen = mode.wantsAiming }
        .onChange(of: mode.celebrations) { _, _ in
            glow = 1
            withAnimation(.easeOut(duration: reduceMotion ? 0.8 : 1.4)) { glow = 0 }
            // The made-it sound starts with the glow's flash (the success haptic fires on the same change, below); the
            // mode says whether it is the big one. SoundBoard honours the Sound option.
            SoundBoard.play(mode.celebrationMoment)
        }
        // One success haptic per pass, with the glow and the sound. Here rather than on the card (phone UI plan): this
        // layer is on screen in every layout and already mounted when the pass lands, while the upright phone has no
        // card. The Vibration option is read as it fires.
        .sensoryFeedback(trigger: mode.celebrations) { _, _ in GameSettings.hapticsOn ? .success : nil }
    }

    /// Rings on the balls the goal names (where they rest now), on the pocket they must drop in, and the circle the cue
    /// ball must finish in, lying on the cloth.
    private func drawMarkers(_ ctx: inout GraphicsContext, size: CGSize) {
        // Not while the Lens tips are up (model.holdForTips): like the card and the caption's ring, the rings on the
        // cloth stand back so the tips are the one thing on screen during their held beat (item 53). The Canvas
        // redraws every frame, so they come back the moment the tips close.
        guard !model.holdForTips, let marks = mode.markers, model.aimReady || mode.phase == .keyMoment,
              model.layout.count == 16,
              let root = bridge.table?.root,
              let proj = AimProjector(camera: cameraBox.find(in: root), size: size, frame: TableFrame(model.timeline.table))
        else { return }
        // Drawn by GoalMarks (TrickShotViews.swift), the one drawing shared with the trick-shot layer (0.7.5). The
        // ball rings are left out while the replay is paused on the moment: the balls there are mid-shot, not where
        // the goal names them.
        GoalMarks.draw(balls: model.aimReady ? marks.balls : [], pockets: marks.pockets, zone: marks.zone,
                       layout: model.layout, table: model.timeline.table, accent: palette.accent, in: &ctx, proj)
    }
}
