// Author: Claude Opus 5.5 High
// Date: 20-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink wave 3 notes: each list row names the shot's technique
//          (TrickShot.techniqueLine, package 11) in its meta line beside the dots, and VoiceOver reads it after the
//          title; Made it and Missed carry the one share picture's quiet Share (ResultShare, package 10); on the phone
//          held upright the trick's main action before watching is Your turn, as on the card, with Watch it as the
//          blurb's small button.)
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 9's leftover note: the list's footer, Watch
//          yours and its hint say "Physics Lens", the Lens's one name. The list stays the kit's SheetPage with its
//          ListRow rows; as a page of the notebook it replaces the panel's whole content, as Options and How to play
//          do, so its title and Done are the only ones on screen.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 5, the mode frame: the list is the kit's sheet
//          page with the kit's list rows (number or tick, title and hook in paper and paper2, five difficulty dots, the
//          answer's drawing); the card is the kit's mode card in every phase (name and dots, one sentence, "How
//          forgiving" tiles while the shot is set up or lined up, the way on bottom right, the rest under More) and the
//          kit-style result card once judged (Made it in pocket gold, Missed in warning, the judge's line and the
//          retry's difference under it). The word tags for difficulty are gone. The slim form keeps its own rule, the
//          idea above Your turn while the answer is explained (#64). The glow follows the screen's own corners.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2: one meaning per colour. Fouls, misses and
//          refusals take Palette.warning; headings, try counts, tags and difficulty take paper or paper2; the sliding
//          magenta is left for sliding and friction.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 daily: a shot of the day is played as a trick shot but has
//          its own card, blurbs and main button (App/Daily/DailyViews.swift), so the trick card's Watch it, list and
//          Next shot never show for it; the table layer also draws its mark. Each hand-over is marked "0.7.10 daily".)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 make it again, plans/23-Nov-2026-make-it-again-plan.md V1 and
//          V2: the list gains the "Your shots" section (OwnShotsSection) after the authored shots; GoalMarks rings a bed
//          hole as well as an edge pocket, through TableSpec.holeCenter, for a saved shot on bumper pool or bar
//          billiards.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream cards, plans/22-Nov-2026-phone-bug-hunt.md #64: the slim
//          card shows the shot's one idea, two lines at most, beside Your turn while the answer is explained, instead of
//          a lone button under empty glass.)
// Edited: Claude Haiku 5.5 High, 20-November-2026 (strings that are built in code, such as the card lines, the spoken row
//          label and the "Coming next" line, are String(localized:); literal labels and buttons are already keys)
// Edited: Claude Opus 5.5 High, 21-November-2026 (the -trickAim store-screenshot flag.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (the list shows each shot's place in the easiest-first order,
//          TrickShots.listNumber, instead of its authored number)
// Edited: Claude Opus 5.5 High, 21-November-2026 (learn from a retry: the Made it / Missed card also says the one
//          difference from the last try (RetryWords) and offers See the contact (ContactButton), so a shot such as
//          Stop Dead can be taken back to the contact from the card the player is already reading.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan items 36 and 53: a make plays the made-it sound with the glow
//          (SoundBoard.play); the card steps back while the Lens tips are up (model.holdForTips), so the tips never
//          stack on the explanation card.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (access stream hook, 0.7.0 item 44: Next shot's arrow follows the reading direction.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 trick-shots stream: each list row carries a small drawing of
//          the answer's real solved path (TrickPathThumb); a made try offers Watch yours in the Lens; after the answer
//          has been watched, the card offers Show / Hide the answer's path, which the table layer draws faintly on the
//          cloth with the ghost's own path drawing (TablePathStroke); this header no longer counts the shots.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 learn-modes stream, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          items 9, 11 and 12: Stop Dead draws its finish circle, through GoalMarks, the one drawing of the goal marks
//          now shared with LessonTableLayer; the card steps aside while a what-if is open and shows its slim form (the
//          heading and the main button) during a guided Lens replay on a phone held upright (lensReplayCompact); the
//          list's Mac minimum size applies only as a sheet, not as a page of the notebook.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (phone UI plan, Part 4 step 5: TrickPhoneBlurbs, the trick card's
//          words as blurbs on the phone held upright, and PhonePrimaryAction.trick, its main button as the strip's
//          primary action ("Watch it", "Your turn", "Try again", "Next shot"). The make's success haptic moved from the
//          card to TrickTableLayer, which is on screen in every layout, so the upright phone (no card) keeps it.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 coordinator: what steps aside for the what-if now also steps
//          aside for the every-surface fan, through model.otherFutureShowing.)
// PURPOSE: Everything the player sees of trick-shot mode, kept small so the table stays big:
//          TrickShotList - the list of the trick shots, in a sheet from the menu: number (or a tick once made), title,
//            hook and difficulty, and beside them a small drawing of the answer's real path (above the text at
//            accessibility text sizes); a shot that waits on new physics shows as "Coming next" and cannot be opened.
//          TrickShotCard - the kit's mode card, above the controls (or at the top of the side column on iPad, Mac and
//            landscape): the shot's name and five dots, the hook and Your turn / Watch it with "How forgiving"; the one
//            idea while the answer replays in the Lens, with the maths under More; Made it or Missed in the result card
//            with one line on what to change, Next shot or Try again, and Watch yours in the Lens, See the contact and
//            the answer's path under More. One sentence and one row of buttons.
//          TrickPhoneBlurbs - the phone held upright only (ShowpieceView's dock): the card's words without the card, as
//            blurbs (App/Phone/Blurb.swift). The shot's name and difficulty are the title row's, the main button is the
//            strip's primary action (PhonePrimaryAction.trick, below), and the list, Watch again, Show the maths and
//            the answer's path are in the title row's More menu; what is left is the hook, the goal, the idea (folded to
//            one line with its more dot while the answer replays, opened by a tap here or on the title), the verdict
//            with the retry's one difference, and at most two small buttons (Your turn before watching; See the
//            contact and Watch yours after a try).
//          TrickTableLayer - laid over the 3D table, never taking touches: rings on the balls the shot names and on the
//            pockets they must drop in, the cue ball's finish circle for Stop Dead (GoalMarks, shared with the lesson
//            layer), the answer's cue-ball path when the player asks for it (white, dashed, faint,
//            labelled), and a short glow around the screen when a shot is made. It also hosts the list
//            sheet, handles the launch flags (-trickList, -trick <id>, -trickPlay <id>), forwards the model's playback
//            changes to TrickShotMode.update(), and opens or closes the shot panel when the mode asks.
//          The kit throughout (SheetPage, ListRow, DifficultyDots, ModeCard, the result card of ModeFrameKit.swift),
//          Dynamic Type (the kit's button row falls back to a column and the text wraps), VoiceOver labels, and Reduce
//          Motion (the glow fades without movement; the card changes without animation).
// SRP/DRY check: Pass - views only. Flow is TrickShotMode, data TrickShots; projection to the screen is AimProjector
//          (as in GhostOverlay and AimOverlay); the card, list row and sheet are the kit's (App/Kit), the difficulty
//          mapping and forgiving tiles ModeFrameKit's, shared with every mode. The goal marks are drawn once,
//          by GoalMarks here, for this layer and LessonTableLayer, with the ghost overlay's ring path
//          (TablePathStroke.ring) rather than a third copy of it.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import SwiftUI

// MARK: The list

struct TrickShotList: View {
    let mode: TrickShotMode
    /// True when the list is a page of the notebook (iPad, Mac, the open Duo) rather than a sheet of its own.
    @Environment(\.inlinePages) private var inlinePages
    /// The answers' drawings, solved once per run when this list first appears.
    private var paths: TrickPathCache { TrickPathCache.shared }

    var body: some View {
        // UI rethink package 5: the kit's sheet page (ground, serif title, Done top right) and the kit's list row, as
        // the lessons and Behind the 8-Ball lists. Done closes the list, as Close did.
        SheetPage(title: String(localized: "Trick shots"), onDone: { mode.listOpen = false }) {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                ForEach(TrickShots.all) { shot in
                    Button { mode.begin(shot) } label: { row(shot) }
                        .buttonStyle(.plain)
                        .disabled(shot.pending)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(spoken(shot))
                        .accessibilityHint(shot.pending ? "" : String(localized: "Sets up the shot on the table"))
                }
            }
            // 0.7.7 make-it-again: the player's own saved shots, "Your shots", after the authored ones.
            OwnShotsSection(mode: mode)
        } footer: {
            Text("Watch each shot, see the physics behind it in the Physics Lens, then make it yourself.")
        }
        // The drawings are solved when the list is first opened, never at launch (TrickPathCache).
        .onAppear { paths.start() }
        #if os(macOS)
        // A sheet's own minimum size; as a page of the Mac notebook it takes the panel's size instead (0.7.5: the
        // minimum pushed the list past the panel's edge). One frame with nil sizes, not an if, so the view keeps its
        // identity when the window changes layout.
        .frame(minWidth: inlinePages ? nil : 460, minHeight: inlinePages ? nil : 560)
        #endif
    }

    /// The kit's list row: the shot's place in the easiest-first order (a tick once made, no mark while it waits on
    /// new physics), its title and hook in paper and paper2, its five difficulty dots, and the answer's drawing.
    private func row(_ shot: TrickShot) -> some View {
        let leading: ListRow<DifficultyDots, AnyView>.Leading = mode.isDone(shot) ? .done
            : (shot.pending ? .none : .number(TrickShots.listNumber(of: shot)))
        // The playful title stays; the technique it uses is named in the meta line beside the dots (package 11).
        return ListRow(leading: leading, title: shot.title,
                       line: shot.pending ? String(localized: "Coming next. \(shot.hook)") : shot.hook,
                       best: shot.techniqueLine, showsChevron: !shot.pending,
                       difficulty: { DifficultyDots(level: ModeDifficulty.dots(shot.difficulty)) },
                       picture: { thumb(shot) })
            .opacity(shot.pending ? 0.6 : 1)
    }

    /// The answer's drawing (TrickPathThumb), or an empty table-sized room while it is being solved or when it failed,
    /// so the rows keep one shape.
    private func thumb(_ shot: TrickShot) -> AnyView {
        if let path = paths.paths[shot.id] { return AnyView(TrickPathThumb(path: path)) }
        return AnyView(Color.clear)
    }

    private func spoken(_ shot: TrickShot) -> String {
        let state = shot.pending ? String(localized: "coming next")
            : (mode.isDone(shot) ? String(localized: "made") : String(localized: "not made yet"))
        // The technique, when the shot names one, straight after the title, as the row shows it.
        let title = shot.techniqueLine.map { "\(shot.title), \($0)" } ?? shot.title
        return String(localized: "Shot \(TrickShots.listNumber(of: shot)), \(title), \(shot.difficulty.label), \(state). \(shot.hook)")
    }
}

// MARK: The card

struct TrickShotCard: View {
    let model: ShowpieceModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// On a phone held upright while a guided Lens replay plays (set by ShowpieceView, App/LayoutFlags.swift): the slim
    /// card, heading and main button only, so the table keeps its height. The kit's ModeCard reads the same flag and
    /// slims itself to its name and primary; this card picks what that primary is for each phase.
    @Environment(\.lensReplayCompact) private var compact

    private var mode: TrickShotMode { model.trickMode }

    var body: some View {
        // While the Lens tips are showing over a held beat (model.holdForTips, set by the tips themselves), they are the
        // one card: this card steps back and returns when they are done, so the idea is never stacked under the tips.
        // While a what-if is open on the try (0.7.5, WhatIfFork.isShowing) its card is the one result card: this one
        // steps aside and comes back, unchanged, when the what-if closes.
        // 0.7.10 daily: the shot of the day has its own card (the answer stays hidden until the day is finished).
        if DailyMode.showing(model) {
            DailyCard(model: model)
        } else if let shot = mode.current, mode.isActive, !model.holdForTips, !model.otherFutureShowing {
            Group {
                if compact { slim(shot) } else { content(shot) }
            }
            .animation(reduceMotion ? nil : Theme.Motion.standard, value: mode.phase)
            // The make's success haptic is TrickTableLayer's (with the glow and the sound), so it fires in every layout.
            .transition(.opacity)
        }
    }

    /// Every phase in the kit's mode card (or, once judged, the result card): the shot's name and five dots, one
    /// sentence, "How forgiving" while the shot is being set up, and the button row with the way on at the bottom
    /// right.
    @ViewBuilder
    private func content(_ shot: TrickShot) -> some View {
        let dots = ModeDifficulty.dots(shot.difficulty)
        switch mode.phase {
        case .ready:
            // Watching first is the shot's path, but nothing is gated: Your turn is the way on, Watch it beside it.
            if Self.showsForgiving(shot) {
                ModeCard(name: shot.title, difficulty: dots, goal: shot.hook,
                         primary: turnAction, secondary: watchAction(again: false), more: [listAction]) {
                    ForgivingTiles(window: shot.window, isBreak: shot.isBreak)
                }
                .modeShortcut(turnAction, .defaultAction)
            } else {
                ModeCard(name: shot.title, difficulty: dots, goal: shot.hook,
                         primary: turnAction, secondary: watchAction(again: false), more: [listAction])
                    .modeShortcut(turnAction, .defaultAction)
            }
        case .watching:
            ModeCard(name: shot.title, difficulty: dots, goal: String(localized: "Watch the answer. \(shot.goalLine)"),
                     primary: turnAction)
        case .explaining:
            // The one idea while the answer replays in the Lens; the worked equation under "The maths" when asked for.
            if mode.showMaths, let maths = shot.maths {
                ModeCard(name: shot.title, difficulty: dots, goal: shot.idea,
                         tilesTitle: String(localized: "The maths"),
                         primary: turnAction, secondary: watchAction(again: true), more: mathsActions(shot)) {
                    ModeMaths(maths: maths, spoken: shot.mathsSpoken)
                }
            } else {
                ModeCard(name: shot.title, difficulty: dots, goal: shot.idea,
                         primary: turnAction, secondary: watchAction(again: true), more: mathsActions(shot))
            }
        case .aiming:
            // Lining up: the aiming panel's Shoot is the screen's one primary, so this card has none.
            if Self.showsForgiving(shot) {
                ModeCard(name: shot.title, difficulty: dots, goal: aimingLine(shot),
                         primary: nil, secondary: watchAction(again: false),
                         more: [answerPathAction, listAction].compactMap { $0 }) {
                    ForgivingTiles(window: shot.window, isBreak: shot.isBreak)
                }
            } else {
                ModeCard(name: shot.title, difficulty: dots, goal: aimingLine(shot),
                         primary: nil, secondary: watchAction(again: false),
                         more: [answerPathAction, listAction].compactMap { $0 })
            }
        case .judged(let verdict):
            judged(shot, verdict)
        case .offScript:
            ModeCard(name: shot.title, difficulty: dots,
                     goal: String(localized: "That shot started from where the balls stopped. Try again puts them back for the trick."),
                     primary: tryAgainAction, more: [listAction])
                .modeShortcut(tryAgainAction, .defaultAction)
        case .off:
            EmptyView()
        }
    }

    /// Made it or Missed, in the result card: the judge's one line on what to change, the retry's one difference
    /// (RetryWords; the general comparison card steps aside while this card is up), then after a make Next shot with
    /// Try again beside it, after a miss Try again with Watch it beside it; See the contact, Watch yours in the Lens and
    /// the answer's path under More.
    @ViewBuilder
    private func judged(_ shot: TrickShot, _ verdict: TrickVerdict) -> some View {
        let lines = [verdict.line] + (model.retryComparison.map { [RetryWords.sentence($0)] } ?? [])
        let contact = ContactButton.kitAction(model: model, reduceMotion: reduceMotion)
        if verdict.made {
            // The player's own make, slowly in the Lens, holding the moments the shot is about (0.7.4).
            let watchYours = KitAction(String(localized: "Watch yours in the Physics Lens"), systemImage: "eye") {
                mode.watchYours()
            }
            let made = String(localized: "Made it!")
            ModeResultCard(verdict: made, tone: .passed, corner: shot.title, lines: lines,
                           tryAgain: tryAgainAction, next: nextAction,
                           share: share(shot, verdict: made, tone: .passed),
                           more: [watchYours, contact, answerPathAction].compactMap { $0 })
                .modeShortcut(nextAction, .defaultAction)
        } else {
            let missed = String(localized: "Missed")
            ModeResultCard(verdict: missed, tone: .foul, corner: shot.title, lines: lines,
                           tryAgain: watchAction(again: false), next: tryAgainAction,
                           share: share(shot, verdict: missed, tone: .foul),
                           more: [contact, answerPathAction].compactMap { $0 })
                .modeShortcut(tryAgainAction, .defaultAction)
        }
    }

    /// The slim card (0.7.5, lensReplayCompact): the shot's name and the one action that moves the shot on, so a
    /// guided Lens replay on a phone held upright keeps the table its height. Your turn while the answer is set up,
    /// played or explained; after a try, Next shot for a make and Try again for a miss; the name alone while aiming.
    /// While the answer is explained (0.7.6, #64) the shot's one idea stays above Your turn, so the card carries what
    /// the replay is for: the card's own slimming is turned off there and only the idea and Your turn are passed.
    @ViewBuilder
    private func slim(_ shot: TrickShot) -> some View {
        let dots = ModeDifficulty.dots(shot.difficulty)
        switch mode.phase {
        case .explaining:
            ModeCard(name: shot.title, difficulty: dots, goal: shot.idea, primary: turnAction)
                .environment(\.lensReplayCompact, false)
        case .ready, .watching:
            ModeCard(name: shot.title, difficulty: dots, goal: shot.hook, primary: turnAction)
        case .judged(let verdict):
            ModeCard(name: shot.title, difficulty: dots, goal: verdict.line,
                     primary: verdict.made ? nextAction : tryAgainAction)
        case .offScript:
            ModeCard(name: shot.title, difficulty: dots, goal: shot.goalLine, primary: tryAgainAction)
        case .aiming:
            ModeCard(name: shot.title, difficulty: dots, goal: shot.goalLine, primary: nil)
        case .off:
            EmptyView()
        }
    }

    // MARK: Pieces

    /// What to do while lining up, with the bridge's reason when the ball is out of reach.
    private func aimingLine(_ shot: TrickShot) -> String {
        shot.usesBridge ? String(localized: "\(shot.goalLine) The ball is out of reach, so the bridge holds the cue.")
                        : shot.goalLine
    }

    /// True when a shot's "How forgiving" tiles can be shown: its window is measured (0.7.7: a saved shot's window is
    /// not measured yet, so it shows none rather than made-up numbers).
    static func showsForgiving(_ shot: TrickShot) -> Bool { !OwnShotShelf.shared.isUnmeasured(shot) }

    /// True while the card itself shows the forgiving tiles (the shot being set up or lined up), so the notebook's
    /// dossier does not show them a second time beside it.
    static func cardShowsForgiving(_ mode: TrickShotMode) -> Bool {
        switch mode.phase {
        case .ready, .aiming: return true
        default: return false
        }
    }

    private var turnAction: KitAction {
        KitAction(String(localized: "Your turn"), systemImage: "target") { mode.yourTurn() }
    }

    /// The one share picture's quiet Share (package 10): the try over its own table, the trick's title as the corner
    /// word. Nil while no shot is on the table, so the button hides itself.
    private func share(_ shot: TrickShot, verdict: String, tone: ResultTone) -> KitAction? {
        ResultShare.action(model: model, mode: String(localized: "Trick shots"), corner: shot.title, verdict: verdict,
                           tone: tone)
    }

    private func watchAction(again: Bool) -> KitAction {
        KitAction(again ? String(localized: "Watch again") : String(localized: "Watch it"),
                  systemImage: again ? "arrow.counterclockwise" : "play") { mode.watch() }
    }

    private var tryAgainAction: KitAction {
        KitAction(String(localized: "Try again"), systemImage: "arrow.uturn.backward") { mode.tryAgain() }
    }

    private var nextAction: KitAction {
        KitAction(String(localized: "Next shot"), systemImage: "arrow.forward") { mode.next() }
    }

    private var listAction: KitAction {
        KitAction(String(localized: "All trick shots"), systemImage: "list.bullet") { mode.listOpen = true }
    }

    /// Show / Hide the maths, when the shot has an equation.
    private func mathsActions(_ shot: TrickShot) -> [KitAction] {
        guard shot.maths != nil else { return [] }
        return [KitAction(mode.showMaths ? String(localized: "Hide the maths") : String(localized: "Show the maths"),
                          systemImage: "function") { mode.showMaths.toggle() }]
    }

    /// Show / Hide the answer's path, offered once the answer has been watched, while the player lines up or reads the
    /// verdict (TrickShotMode.offersAnswerPath). The path itself is drawn by TrickTableLayer.
    private var answerPathAction: KitAction? {
        guard mode.offersAnswerPath else { return nil }
        let shown = mode.showAnswerPath
        return KitAction(shown ? String(localized: "Hide the answer's path") : String(localized: "Show the answer's path"),
                         systemImage: "point.topleft.down.to.point.bottomright.curvepath") {
            mode.showAnswerPath.toggle()
        }
    }
}

// MARK: The phone held upright

/// The trick card's words as blurbs, docked at the top of the table area on the phone held upright (ShowpieceView's
/// dock; phone UI plan, Part 3 and Part 4 step 5). One blurb at a time, chosen by the phase, plus the idea whenever the
/// title has opened it. Shows nothing outside a trick shot, while the Lens tips hold a beat (they are the one text then,
/// as the card stepped back for them) and while a what-if is open (its result is the one result then).
struct TrickPhoneBlurbs: View {
    let model: ShowpieceModel
    /// The idea is open: the title row's tap and a tap on the idea blurb both toggle it (ShowpieceView owns it).
    @Binding var ideaOpen: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var mode: TrickShotMode { model.trickMode }

    var body: some View {
        // 0.7.10 daily: the shot of the day's own blurbs.
        if DailyMode.showing(model) {
            DailyPhoneBlurbs(model: model)
        } else if let shot = mode.current, mode.isActive, !model.holdForTips, !model.otherFutureShowing {
            // The idea while the answer replays in the Lens (folded to one line, its dot saying there is more), or
            // whenever the title opened it (then shown open; folding it puts it away).
            if mode.phase == .explaining || ideaOpen { idea(shot) }
            phaseBlurb(shot)
        }
    }

    /// Blurb's fold switch is true when folded; ideaOpen is true when open. One binding turns one into the other.
    private var ideaFolded: Binding<Bool> {
        Binding(get: { !ideaOpen }, set: { ideaOpen = !$0 })
    }

    /// "The idea", the shot's one idea, and the worked maths while Show the maths is on (the title row's More menu
    /// sets mode.showMaths with the stored option).
    private func idea(_ shot: TrickShot) -> some View {
        Blurb(title: String(localized: "The idea"), sentence: shot.idea,
              equation: mode.showMaths ? shot.maths : nil,
              folded: ideaFolded, foldedLines: 1)
    }

    /// The phase's own words. Explaining has none beyond the idea; Your turn, Try again and Next shot are the strip's
    /// primary action (PhonePrimaryAction.trick), and Watch it is the ready blurb's small button.
    @ViewBuilder
    private func phaseBlurb(_ shot: TrickShot) -> some View {
        switch mode.phase {
        case .ready:
            // The hook, and Watch it for a player who wants to see the answer first (Your turn is the primary action,
            // the card's way on).
            Blurb(sentence: shot.hook, buttons: [
                BlurbButton(String(localized: "Watch it"),
                            hint: String(localized: "Plays the answer, then explains it in the Physics Lens")) { mode.watch() }
            ])
        case .watching:
            Blurb(sentence: String(localized: "Watch the answer. \(shot.goalLine)"))
        case .aiming:
            Blurb(sentence: shot.usesBridge
                  ? String(localized: "\(shot.goalLine) The ball is out of reach, so the bridge holds the cue.")
                  : shot.goalLine)
        case .judged(let verdict):
            judged(verdict)
        case .offScript:
            Blurb(sentence: String(localized: "That shot started from where the balls stopped. Try again puts them back for the trick."))
        case .explaining, .off:
            EmptyView()
        }
    }

    /// Made it or Missed, the judge's one line and, after a retry, the one difference between the two tries
    /// (RetryWords), folded to three lines with the dot when longer. Two small buttons at most: See the contact (when
    /// the cue ball touched a ball) and, after a make, Watch yours in the Lens.
    private func judged(_ verdict: TrickVerdict) -> some View {
        var sentence = verdict.line
        if let c = model.retryComparison { sentence += " " + RetryWords.sentence(c) }
        var buttons: [BlurbButton] = []
        if let contact = ContactButton.blurbButton(model: model, reduceMotion: reduceMotion) { buttons.append(contact) }
        if verdict.made {
            buttons.append(BlurbButton(String(localized: "Watch yours in the Physics Lens"),
                                       hint: String(localized: "Replays your stroke slowly in the Physics Lens, stopping on the moments that made it")) {
                mode.watchYours()
            })
        }
        return Blurb(title: verdict.made ? String(localized: "Made it!") : String(localized: "Missed"),
                     sentence: sentence, buttons: buttons)
    }
}

extension PhonePrimaryAction {
    /// The trick shot's way on, the card's primary button (phone UI plan, Part 3 "The control strip"): "Your turn"
    /// before the answer is watched (wave 3 note 5: the card's way on; Watch it is the blurb's small button) and while
    /// the answer plays and replays in the Lens (one word for the whole replay, so it never changes under the thumb); "Next shot" after a make; "Try again" after a miss or an
    /// off-script shot. Nil while lining up (the aiming panel is the way on), outside a trick shot, and while a
    /// what-if is open (the trick card stepped aside for it too).
    static func trick(_ model: ShowpieceModel) -> PhonePrimaryAction? {
        // 0.7.10 daily: the shot of the day's own main button.
        if DailyMode.showing(model) { return daily(model) }
        let mode = model.trickMode
        guard mode.isActive, !model.otherFutureShowing else { return nil }
        switch mode.phase {
        case .ready, .watching, .explaining:
            return PhonePrimaryAction(title: String(localized: "Your turn"),
                                      hint: String(localized: "Puts the balls back and opens the aiming controls")) {
                mode.yourTurn()
            }
        case .judged(let verdict) where verdict.made:
            return PhonePrimaryAction(title: String(localized: "Next shot")) { mode.next() }
        case .judged, .offScript:
            return PhonePrimaryAction(title: String(localized: "Try again"),
                                      hint: String(localized: "Puts the balls back where the shot started, with your last aim, power and spin")) {
                mode.tryAgain()
            }
        case .aiming, .off:
            return nil
        }
    }
}

// MARK: Over the table

struct TrickTableLayer: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    @Binding var shotPanelOpen: Bool
    @Environment(\.inlinePages) private var inlinePages
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var cameraBox = AimProjector.CameraBox()
    @State private var glow = 0.0

    private var mode: TrickShotMode { model.trickMode }
    @MainActor private static var launchHandled = false

    var body: some View {
        @Bindable var mode = mode
        ZStack {
            if mode.markers != nil || mode.answerPathOnCloth != nil {
                TimelineView(.animation) { _ in
                    Canvas { ctx, size in draw(&ctx, size: size) }
                }
            }
            // The make: a short glow around the edge of the screen. It only fades, so it is the same with Reduce Motion.
            // The screen's own corners (ContainerRelativeShape), not a card's: no corner number of its own.
            ContainerRelativeShape()
                .strokeBorder(palette.accent, lineWidth: 6)
                .blur(radius: 10)
                .opacity(glow)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .accessibilityHidden(true)
        // On a folding phone the list is a page of the side panel (inlinePages), so the table is never covered. The setter
        // ignores the dismissal SwiftUI sends when the screen turns into that layout just after launch; it would close the list.
        .sheet(isPresented: Binding(get: { mode.listOpen && !inlinePages }, set: { if !inlinePages { mode.listOpen = $0 } })) { TrickShotList(mode: mode) }
        .onAppear(perform: handleLaunchFlags)
        // The mode learns that a shot finished from these two; it ignores anything that is not its business.
        .onChange(of: model.aimReady) { _, _ in mode.update() }
        .onChange(of: model.timelineVersion) { _, _ in mode.update() }
        .onChange(of: mode.aimingRequests) { _, _ in shotPanelOpen = mode.wantsAiming }
        .onChange(of: mode.celebrations) { _, _ in
            glow = 1
            withAnimation(.easeOut(duration: reduceMotion ? 0.8 : 1.4)) { glow = 0 }
            // The made-it sound starts with the glow's flash. SoundBoard honours the Sound option.
            SoundBoard.play(.madeIt)
        }
        // One success haptic per make, with the glow and the sound. Here rather than on the card (phone UI plan): this
        // layer is on screen in every layout and already mounted when the make lands, while the upright phone has no
        // card and its result blurb appears in the same update as the make. The Vibration option is read as it fires.
        .sensoryFeedback(trigger: mode.celebrations) { _, _ in GameSettings.hapticsOn ? .success : nil }
    }

    /// -trickList opens the list over the menu; -trick <id> sets a shot up; -trickPlay <id> also plays the answer;
    /// -trickAim <id> lines the answer up with aiming open and plays nothing (for store screenshots).
    private func handleLaunchFlags() {
        // Once per launch: the layer is rebuilt when the screen switches between its narrow and wide layouts.
        guard !Self.launchHandled else { return }
        Self.launchHandled = true
        let args = ProcessInfo.processInfo.arguments
        func value(after flag: String) -> String? {
            guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
            return args[i + 1]
        }
        if let id = value(after: "-trick") { mode.begin(id: id) }
        if let id = value(after: "-trickPlay") { mode.begin(id: id); mode.watch() }
        if let id = value(after: "-trickAim") { mode.begin(id: id); mode.lineUpAnswer() }
        // Last, so -trick <id> -trickList shows the list over that shot's table (begin closes the list).
        // A moment late: on a folding phone the screen first lays out as an ordinary one and turns into the fold layout a
        // beat later, and a list opened in the first beat is closed again by that change.
        if args.contains("-trickList") {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.2))
                mode.listOpen = true
            }
        }
    }

    /// Everything this layer draws on the cloth, through the live camera: the answer's path under the rings.
    private func draw(_ ctx: inout GraphicsContext, size: CGSize) {
        guard let root = bridge.table?.root,
              let proj = AimProjector(camera: cameraBox.find(in: root), size: size, frame: TableFrame(model.timeline.table))
        else { return }
        if let answer = mode.answerPathOnCloth { drawAnswerPath(answer, &ctx, size: size, proj) }
        drawMarkers(&ctx, proj)
        // 0.7.10 daily: the shot of the day's mark, and after a make the line to it.
        DailyMarks.draw(model, accent: palette.accent, paper: palette.paper, in: &ctx, size: size, proj)
    }

    /// The answer's cue-ball path, faint beside the player's own (0.7.4): neutral white, long dashes, about half
    /// opacity, with a hollow ring and an "Answer" label where it stopped. Kept apart from the last-try ghost (shorter
    /// dashes on a dark underlay, "Last try") by its dash and its label, never by colour alone. Drawn while the balls
    /// run too, so the live shot can be watched against it.
    private func drawAnswerPath(_ answer: TrickShotMode.AnswerPath, _ ctx: inout GraphicsContext, size: CGSize,
                                _ proj: AimProjector) {
        let colour = palette.paper.opacity(0.5)
        TablePathStroke(points: answer.cue, colour: colour, lineWidth: 2, dash: [12, 7]).draw(in: &ctx, proj)
        guard let rest = answer.rest,
              let ring = TablePathStroke.ring(at: rest, radius: model.timeline.table.ballRadius, proj) else { return }
        ctx.stroke(ring, with: .color(colour), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
        TablePathStroke.label(Text("Answer"), at: rest, colour: palette.paper.opacity(0.8), in: &ctx, size: size, proj)
    }

    /// Rings on the balls the shot names (where they rest now), on the pockets they must drop in, and Stop Dead's
    /// finish circle (0.7.5), drawn by GoalMarks exactly as the lesson layer draws its own.
    private func drawMarkers(_ ctx: inout GraphicsContext, _ proj: AimProjector) {
        guard let marks = mode.markers, model.aimReady, model.layout.count == 16 else { return }
        GoalMarks.draw(balls: marks.balls, pockets: marks.pockets, zone: marks.zone, layout: model.layout,
                       table: model.timeline.table, accent: palette.accent, in: &ctx, proj)
    }
}

// MARK: Goal marks (shared with LessonTableLayer)

/// The marks a trick shot or a lesson lays on the cloth, drawn one way for both (0.7.5; each layer had its own copy,
/// and the trick layer had no finish circle, so Stop Dead's target never showed): the circle the cue ball must finish
/// in (a faint accent fill under a dashed accent line), a double ring on each pocket a ball must drop in, and a dashed
/// ring round each named ball where it rests. The ring path is the ghost overlay's (TablePathStroke.ring), so every
/// circle on the cloth is traced the same way through the live camera. On the main actor, as TablePathStroke is and
/// as both layers' Canvas drawing runs.
@MainActor
enum GoalMarks {
    /// Draw the marks. `balls` empty draws no ball rings (the lesson's paused key moment, where the balls are
    /// mid-shot). The zone goes first, under the pocket and ball rings.
    static func draw(balls: [Int], pockets: [Int], zone: TrickZone?, layout: [Vec2], table: TableSpec, accent: Color,
                     in ctx: inout GraphicsContext, _ proj: AimProjector) {
        if let zone, let p = TablePathStroke.ring(at: zone.centre, radius: zone.radius, proj) {
            ctx.fill(p, with: .color(accent.opacity(0.10)))
            ctx.stroke(p, with: .color(accent.opacity(0.8)), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        }
        // 0.7.7 make-it-again: a bed hole (pocket 6 and up on bumper pool and bar billiards) is ringed too, for a saved
        // shot on those tables. holeCenter is nil for a hole this table lacks; it comes first, as it is what keeps
        // bedHoles[j] in range. On the pool table it gives pockets[k] for 0 to 5, so every other ring is as before.
        for k in pockets {
            guard let centre = table.holeCenter(pocket: k) else { continue }
            let j = k - TableSpec.edgePocketCount
            let radius: Double
            if j >= 0 {
                radius = table.bedHoles[j].captureRadius
            } else {
                guard k < table.pocketCaptureRadius.count else { continue }
                radius = table.pocketCaptureRadius[k]
            }
            if let p = TablePathStroke.ring(at: centre, radius: radius + 0.012, proj) {
                ctx.stroke(p, with: .color(accent.opacity(0.35)), style: StrokeStyle(lineWidth: 7))
                ctx.stroke(p, with: .color(accent), style: StrokeStyle(lineWidth: 2))
            }
        }
        for b in balls where layout.indices.contains(b) && NextShot.isOnTable(layout[b]) {
            if let p = TablePathStroke.ring(at: layout[b], radius: table.ballRadius * 1.45, proj) {
                ctx.stroke(p, with: .color(accent.opacity(0.9)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            }
        }
    }
}
