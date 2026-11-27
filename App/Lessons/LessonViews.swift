// Author: Claude Opus 5.5 High
// Date: 21-November-2026
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
//                             folding phone, iPad and Mac): number or a tick once passed, title and one line. Nothing
//                             is locked: any lesson can be opened at any time.
//          LessonCard       - one compact glass card above the controls (or in the side column, or as a card of the
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
//          Standard controls (Liquid Glass buttons, a List, SF Symbols), Dynamic Type (button rows wrap, text wraps),
//          VoiceOver (the card's header and state read as one; the step line says which controls are locked), Reduce
//          Motion (the glow only fades; the card changes without animation).
// SRP/DRY check: Pass - views only. Flow is LessonMode, data Lessons; projection to the screen is AimProjector, card
//          styling the shared glassCard, the result card's retry pieces RetryWords and ContactButton, as in
//          TrickShotViews. The trick card itself is not reused because its phases and buttons differ step by step.
import BreakdownLensModel
import BreakdownPhysics
import SwiftUI

// MARK: The list

struct LessonList: View {
    let mode: LessonMode
    @Environment(\.palette) private var palette
    /// True when the list is a page of the notebook (iPad, Mac, the open Duo) rather than a sheet of its own.
    @Environment(\.inlinePages) private var inlinePages

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Lessons.all) { lesson in
                        Button { mode.begin(lesson) } label: { row(lesson) }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(spoken(lesson))
                            .accessibilityHint(String(localized: "Sets up the lesson on the table"))
                    }
                } footer: {
                    Text("Watch each lesson, try it three times with less help each time, then pass it on your own.")
                }
            }
            .navigationTitle("Lessons")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { mode.listOpen = false } }
            }
        }
        .tint(palette.accent)
        #if os(macOS)
        // A sheet's own minimum size; as a page of the Mac notebook it takes the panel's size (0.7.5: the minimum
        // pushed the list past the panel's edge). Nil sizes rather than an if, so the view keeps its identity.
        .frame(minWidth: inlinePages ? nil : 460, minHeight: inlinePages ? nil : 520)
        #endif
    }

    private func row(_ lesson: Lesson) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            ZStack {
                if mode.isDone(lesson) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(palette.accent)
                } else {
                    Text(verbatim: "\(lesson.number)").font(Theme.equation).foregroundStyle(palette.accent)
                }
            }
            .font(.title3)
            .frame(minWidth: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: lesson.title).font(Theme.heading).foregroundStyle(.primary)
                Text(verbatim: lesson.hook)
                    .font(Theme.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private func spoken(_ lesson: Lesson) -> String {
        let state = mode.isDone(lesson) ? String(localized: "passed") : String(localized: "not passed yet")
        return String(localized: "Lesson \(lesson.number), \(lesson.title), \(state). \(lesson.hook)")
    }
}

// MARK: The card

struct LessonCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    /// On a phone held upright while a guided Lens replay plays (set by ShowpieceView, App/LayoutFlags.swift): the slim
    /// card, heading and main button only, so the table keeps its height.
    @Environment(\.lensReplayCompact) private var compact

    private var mode: LessonMode { model.lessonMode }

    var body: some View {
        // While the Lens tips are showing over a held beat (model.holdForTips, set by the tips themselves), they are the
        // one card: this card steps back and returns when they are done, so the key moment's idea is never stacked
        // under the tips (review of 0.6.6, item 53). The replay cannot reach the key moment meanwhile: the clock holds.
        // While a what-if is open on the try (0.7.5, WhatIfFork.isShowing) its card is the one result card: this one
        // steps aside and comes back, unchanged, when the what-if closes.
        if let lesson = mode.current, mode.isActive, !model.holdForTips, !model.otherFutureShowing {
            VStack(alignment: .leading, spacing: 8) {
                // Paused on the lesson's moment the full card shows, slim or not: the idea is the reason the replay
                // stopped there (0.7.6, #38; the guided flag stays on while the clock is held on the moment).
                if compact && mode.phase != .keyMoment { slim(lesson) } else { content(lesson) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 22, padding: 12)
            .tint(palette.accent)
            .animation(reduceMotion ? nil : .snappy, value: mode.phase)
            // The pass's success haptic is LessonTableLayer's (with the glow and the sound), so it fires in every layout.
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private func content(_ lesson: Lesson) -> some View {
        switch mode.phase {
        case .ready:
            header(lesson, step: nil)
            line(lesson.hook)
            buttons {
                listButton
                // Watching first is the lesson's path, but nothing is gated: a player who knows the shot may go
                // straight to the first try.
                turnButton(prominent: false)
                styled(Button { mode.watch() } label: {
                    Label("Watch it", systemImage: "play.fill").font(.headline).lineLimit(1)
                        .frame(minHeight: Self.buttonHeight)
                }, prominent: true)
                .accessibilityHint(String(localized: "Plays a perfect example, then slows it down in the Physics Lens"))
            }
        case .watching, .replaying:
            header(lesson, step: nil)
            line(mode.phase == .watching ? String(localized: "Watch a perfect example. \(lesson.goalLine)")
                                         : String(localized: "Now slowed down in the Physics Lens. It stops on the moment that matters."))
            buttons { turnButton(prominent: false) }
        case .keyMoment:
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill").foregroundStyle(palette.paper).accessibilityHidden(true)
                Text("The idea").font(Theme.label).foregroundStyle(palette.paper)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            line(lesson.idea)
            buttons {
                watchAgainButton
                turnButton(prominent: true)
            }
        case .aiming(let step):
            header(lesson, step: step)
            line(stepLine(lesson, step))
            if step == .pass || step == .exercise { line(step == .exercise ? Lessons.stopExercise.trick.goalLine : lesson.goalLine) }
            buttons { listButton }
        case .judged(let step, let verdict):
            judged(lesson, step, verdict)
        case .offScript(let step):
            header(lesson, step: step)
            line(String(localized: "That shot started from where the balls stopped. Try again puts them back for the lesson."))
            buttons { tryAgainButton(prominent: true) }
        case .off:
            EmptyView()
        }
    }

    @ViewBuilder
    private func judged(_ lesson: Lesson, _ step: LessonMode.Step, _ verdict: TrickVerdict) -> some View {
        let passed = verdict.made && step == .pass
        HStack(spacing: 8) {
            Image(systemName: verdict.made ? "checkmark.seal.fill" : "arrow.uturn.backward.circle")
                .foregroundStyle(verdict.made ? palette.accent : palette.warning)
                .accessibilityHidden(true)
            Text(passed ? String(localized: "Lesson passed") : (verdict.made ? String(localized: "Made it!") : String(localized: "Missed")))
                .font(Theme.heading)
            Spacer(minLength: 0)
            Text(verbatim: stepName(step)).font(Theme.label).foregroundStyle(palette.paper2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        line(verdict.line)
        // After a retry, the one difference between the two tries, here on the one result card.
        if let c = model.retryComparison { line(RetryWords.sentence(c)) }
        if passed, let trick = mode.suggestedTrick {
            line(String(localized: "The trick shot \(trick.title) is built on this idea."))
        }
        buttons {
            // Back to the moment of contact, with the last try's trail beside it (shown when a ball was touched).
            ContactButton(model: model)
            if passed {
                if lesson.id == Lessons.stop.id {
                    plainButton(String(localized: "A new distance"), symbol: "arrow.left.and.right") { mode.startExercise() }
                        .accessibilityHint(String(localized: "The same pot with the cue ball further back"))
                }
                if mode.suggestedTrick != nil {
                    plainButton(String(localized: "Try the trick shot"), symbol: "wand.and.sparkles") { mode.playSuggestedTrick() }
                }
                nextLessonButton
            } else if step == .pass || step == .exercise {
                // A missed pass shot: Try again keeps the player's own settings; this puts the lesson's stroke back.
                if step == .pass && !verdict.made {
                    plainButton(String(localized: "Back to the lesson's stroke"), symbol: "arrow.counterclockwise") {
                        mode.backToLessonStroke()
                    }
                    .accessibilityHint(String(localized: "Puts the balls back with the lesson's own aim, power and spin"))
                }
                tryAgainButton(prominent: !verdict.made)
                if verdict.made { listButton }
            } else {
                tryAgainButton(prominent: !verdict.made)
                nextStepButton(prominent: verdict.made)
            }
        }
    }

    /// The slim card (0.7.5, lensReplayCompact): the lesson's heading and the one button that moves the lesson on, so a
    /// guided Lens replay on a phone held upright keeps the table its height. Your turn during the Watch beat; after a
    /// try, Next lesson for a pass, Next step for a made guided try, Try again otherwise; nothing more while aiming.
    /// Never used for the key moment itself (body shows the full card there, with the idea).
    @ViewBuilder
    private func slim(_ lesson: Lesson) -> some View {
        header(lesson, step: mode.step)
        switch mode.phase {
        case .ready, .watching, .replaying, .keyMoment:
            buttons { turnButton(prominent: true) }
        case .judged(let step, let verdict):
            buttons {
                if verdict.made && step == .pass {
                    nextLessonButton
                } else if verdict.made && step != .exercise {
                    nextStepButton(prominent: true)
                } else {
                    tryAgainButton(prominent: true)
                }
            }
        case .offScript:
            buttons { tryAgainButton(prominent: true) }
        case .aiming, .off:
            EmptyView()
        }
    }

    private var nextLessonButton: some View {
        styled(Button { mode.nextLesson() } label: {
            Label("Next lesson", systemImage: "arrow.forward").font(.headline).lineLimit(1)
                .frame(minHeight: Self.buttonHeight)
        }, prominent: true)
        .keyboardShortcut(.defaultAction)
    }

    private func nextStepButton(prominent: Bool) -> some View {
        styled(Button { mode.nextStep() } label: {
            Label("Next step", systemImage: "arrow.forward").font(.headline).lineLimit(1)
                .frame(minHeight: Self.buttonHeight)
        }, prominent: prominent)
        .accessibilityHint(String(localized: "Goes on to the next try, with less help"))
    }

    // MARK: Words

    /// The step's name and line (LessonWords, shared with the upright phone's blurbs).
    private func stepName(_ step: LessonMode.Step) -> String { LessonWords.stepName(step) }

    private func stepLine(_ lesson: Lesson, _ step: LessonMode.Step) -> String {
        LessonWords.stepLine(lesson, step, powerHeld: mode.powerHeld)
    }

    // MARK: Pieces

    private func header(_ lesson: Lesson, step: LessonMode.Step?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(String(localized: "Lesson \(lesson.number): \(lesson.title)")).font(Theme.heading).lineLimit(2)
            Spacer(minLength: 0)
            if let step { Text(verbatim: stepName(step)).font(Theme.label).foregroundStyle(palette.paper2) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func line(_ text: String) -> some View {
        Text(verbatim: text)
            .font(Theme.body)
            .foregroundStyle(palette.paper.opacity(0.9))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// One row of buttons, right-aligned; two rows when the text is too large for one (as the trick card).
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

    private func turnButton(prominent: Bool) -> some View {
        styled(Button { mode.yourTurn() } label: {
            Label("Your turn", systemImage: "target").font(.headline).lineLimit(1).frame(minHeight: Self.buttonHeight)
        }, prominent: prominent)
        .accessibilityHint(String(localized: "Puts the balls back and opens the aiming controls"))
    }

    private var watchAgainButton: some View {
        styled(Button { mode.watch() } label: {
            Label("Watch again", systemImage: "arrow.counterclockwise").font(.headline).lineLimit(1)
                .frame(minHeight: Self.buttonHeight)
        }, prominent: false)
    }

    private func tryAgainButton(prominent: Bool) -> some View {
        styled(Button { mode.tryAgain() } label: {
            Label("Try again", systemImage: "arrow.uturn.backward").font(.headline).lineLimit(1)
                .frame(minHeight: Self.buttonHeight)
        }, prominent: prominent)
        .accessibilityHint(String(localized: "Puts the balls back where the shot started, with your last aim, power and spin"))
    }

    private func plainButton(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol).font(.headline).lineLimit(1).frame(minHeight: Self.buttonHeight)
        }
        .buttonStyle(.glass)
    }

    private var listButton: some View {
        Button { mode.listOpen = true } label: {
            Label("All lessons", systemImage: "list.bullet").labelStyle(.iconOnly)
                .frame(minWidth: 30, minHeight: Self.buttonHeight)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(String(localized: "All lessons"))
    }

    @ViewBuilder
    private func styled(_ button: some View, prominent: Bool) -> some View {
        if prominent {
            // Dark text on the bright accent: white on cyan is too faint (as the Shoot button).
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
            RoundedRectangle(cornerRadius: 48, style: .continuous)
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
