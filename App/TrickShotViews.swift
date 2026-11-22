// Author: Claude Opus 5.5 High
// Date: 20-November-2026
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
// PURPOSE: Everything the player sees of trick-shot mode, kept small so the table stays big:
//          TrickShotList - the list of the trick shots, in a sheet from the menu: number (or a tick once made), title,
//            hook and difficulty, and beside them a small drawing of the answer's real path (above the text at
//            accessibility text sizes); a shot that waits on new physics shows as "Coming next" and cannot be opened.
//          TrickShotCard - one compact glass card at the bottom edge, above the controls (or at the top of the side
//            column on iPad, Mac and landscape): the hook and Watch it / Your turn; the one idea while the answer
//            replays in the Lens, with the maths behind a button; Made it or Missed with one line on what to change,
//            Try again and Next shot, Watch yours in the Lens after a make, and Show the answer's path once the answer
//            has been watched. One or two lines of text and one row of buttons.
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
//          Standard controls throughout (Liquid Glass buttons, a List, SF Symbols), Dynamic Type (button rows fall back
//          to two rows and the text wraps), VoiceOver labels, and Reduce Motion (the glow fades without movement; the
//          card changes without animation).
// SRP/DRY check: Pass - views only. Flow is TrickShotMode, data TrickShots; projection to the screen is AimProjector
//          (as in GhostOverlay and AimOverlay); card styling is the shared glassCard. The goal marks are drawn once,
//          by GoalMarks here, for this layer and LessonTableLayer, with the ghost overlay's ring path
//          (TablePathStroke.ring) rather than a third copy of it.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import SwiftUI

// MARK: The list

struct TrickShotList: View {
    let mode: TrickShotMode
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    /// True when the list is a page of the notebook (iPad, Mac, the open Duo) rather than a sheet of its own.
    @Environment(\.inlinePages) private var inlinePages
    /// The answers' drawings, solved once per run when this list first appears.
    private var paths: TrickPathCache { TrickPathCache.shared }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(TrickShots.all) { shot in
                        Button { mode.begin(shot) } label: { row(shot) }
                            .disabled(shot.pending)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(spoken(shot))
                            .accessibilityHint(shot.pending ? "" : "Sets up the shot on the table")
                    }
                } footer: {
                    Text("Watch each shot, see the physics behind it in the Lens, then make it yourself.")
                }
            }
            // The drawings are solved when the list is first opened, never at launch (TrickPathCache).
            .onAppear { paths.start() }
            .navigationTitle("Trick shots")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { mode.listOpen = false } }
            }
        }
        .tint(palette.accent)
        #if os(macOS)
        // A sheet's own minimum size; as a page of the Mac notebook it takes the panel's size instead (0.7.5: the
        // minimum pushed the list past the panel's edge). One frame with nil sizes, not an if, so the view keeps its
        // identity when the window changes layout.
        .frame(minWidth: inlinePages ? nil : 460, minHeight: inlinePages ? nil : 560)
        #endif
    }

    /// The row: the text, and the answer's drawing beside it (above it, full width, at accessibility text sizes, where
    /// the text needs the whole width). A shot whose drawing failed shows the text alone, as before 0.7.4.
    @ViewBuilder
    private func row(_ shot: TrickShot) -> some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                thumb(shot, fullWidth: true)
                rowText(shot)
            }
        } else {
            HStack(alignment: .center, spacing: 12) {
                rowText(shot)
                thumb(shot, fullWidth: false)
            }
        }
    }

    /// The answer's drawing (TrickPathThumb), or the room for it while it is being solved, or nothing when it failed.
    @ViewBuilder
    private func thumb(_ shot: TrickShot, fullWidth: Bool) -> some View {
        if let path = paths.paths[shot.id] {
            if fullWidth {
                TrickPathThumb(path: path).frame(maxWidth: .infinity)
            } else {
                TrickPathThumb(path: path).frame(width: 96, height: 48)
            }
        } else if !shot.pending, paths.isPending(shot.id) {
            Color.clear
                .aspectRatio(2, contentMode: .fit)
                .frame(width: fullWidth ? nil : 96, height: fullWidth ? nil : 48)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .accessibilityHidden(true)
        }
    }

    private func rowText(_ shot: TrickShot) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            ZStack {
                if mode.isDone(shot) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(palette.accent)
                } else if shot.pending {
                    Image(systemName: "lock.fill").foregroundStyle(.secondary)
                } else {
                    Text("\(TrickShots.listNumber(of: shot))").font(Theme.equation).foregroundStyle(palette.accent)
                }
            }
            .font(.title3)
            .frame(minWidth: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(shot.title).font(Theme.heading).foregroundStyle(shot.pending ? .secondary : .primary)
                Text(shot.pending ? String(localized: "Coming next. \(shot.hook)") : shot.hook)
                    .font(Theme.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(shot.difficulty.label)
                    .font(Theme.label)
                    .foregroundStyle(palette.slide)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private func spoken(_ shot: TrickShot) -> String {
        let state = shot.pending ? String(localized: "coming next")
            : (mode.isDone(shot) ? String(localized: "made") : String(localized: "not made yet"))
        return String(localized: "Shot \(TrickShots.listNumber(of: shot)), \(shot.title), \(shot.difficulty.label), \(state). \(shot.hook)")
    }
}

// MARK: The card

struct TrickShotCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    /// On a phone held upright while a guided Lens replay plays (set by ShowpieceView, App/LayoutFlags.swift): the slim
    /// card, heading and main button only, so the table keeps its height.
    @Environment(\.lensReplayCompact) private var compact

    private var mode: TrickShotMode { model.trickMode }

    var body: some View {
        // While the Lens tips are showing over a held beat (model.holdForTips, set by the tips themselves), they are the
        // one card: this card steps back and returns when they are done, so the idea is never stacked under the tips.
        // While a what-if is open on the try (0.7.5, WhatIfFork.isShowing) its card is the one result card: this one
        // steps aside and comes back, unchanged, when the what-if closes.
        if let shot = mode.current, mode.isActive, !model.holdForTips, !model.whatIf.isShowing {
            VStack(alignment: .leading, spacing: 8) {
                if compact { slim(shot) } else { content(shot) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 22, padding: 12)
            .tint(palette.accent)
            .animation(reduceMotion ? nil : .snappy, value: mode.phase)
            // The make's success haptic is TrickTableLayer's (with the glow and the sound), so it fires in every layout.
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private func content(_ shot: TrickShot) -> some View {
        switch mode.phase {
        case .ready:
            header(shot)
            line(shot.hook)
            buttons {
                watchButton(prominent: false)
                turnButton(prominent: true)
                listButton
            }
        case .watching:
            header(shot)
            line(String(localized: "Watch the answer. \(shot.goalLine)"))
            buttons { turnButton(prominent: false) }
        case .explaining:
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill").foregroundStyle(palette.slide).accessibilityHidden(true)
                Text("The idea").font(Theme.label).foregroundStyle(palette.slide)
            }
            line(shot.idea)
            if mode.showMaths, let maths = shot.maths {
                Text(maths)
                    .font(Theme.equation)
                    .foregroundStyle(palette.paper)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("The maths: \(shot.mathsSpoken ?? maths)")
            }
            buttons {
                if shot.maths != nil {
                    Button { mode.showMaths.toggle() } label: {
                        Label(mode.showMaths ? "Hide the maths" : "Show the maths", systemImage: "function")
                            .labelStyle(.iconOnly).frame(minWidth: 30, minHeight: Self.buttonHeight)
                    }
                    .buttonStyle(.glass).buttonBorderShape(.circle)
                    .accessibilityLabel(mode.showMaths ? "Hide the maths" : "Show the maths")
                }
                watchButton(prominent: false, again: true)
                turnButton(prominent: true)
            }
        case .aiming:
            header(shot)
            line(shot.usesBridge ? String(localized: "\(shot.goalLine) The ball is out of reach, so the bridge holds the cue.")
                                 : shot.goalLine)
            buttons {
                answerPathButton
                watchButton(prominent: false)
                listButton
            }
        case .judged(let verdict):
            HStack(spacing: 8) {
                Image(systemName: verdict.made ? "checkmark.seal.fill" : "arrow.uturn.backward.circle")
                    .foregroundStyle(verdict.made ? palette.accent : palette.slide)
                    .accessibilityHidden(true)
                Text(verdict.made ? "Made it!" : "Missed").font(Theme.heading)
            }
            .accessibilityElement(children: .combine)
            line(verdict.line)
            // After a retry, the one difference between the two tries, here on the one result card (the general
            // comparison card steps aside while this card is up).
            if let c = model.retryComparison { line(RetryWords.sentence(c)) }
            buttons {
                // Back to the moment of contact, with the last try's trail beside it (shown when a ball was touched).
                ContactButton(model: model)
                // The answer's path beside this try, once the answer has been watched (0.7.4).
                answerPathButton
                if verdict.made {
                    // The player's own make, slowly in the Lens, holding the moments the shot is about (0.7.4).
                    styled(Button { mode.watchYours() } label: {
                        Label("Watch yours in the Lens", systemImage: "eye").font(.headline).lineLimit(1)
                            .frame(minHeight: Self.buttonHeight)
                    }, prominent: false)
                    .accessibilityHint("Replays your stroke slowly in the Lens, stopping on the moments that made it")
                    tryAgainButton(prominent: false)
                    nextShotButton
                } else {
                    watchButton(prominent: false)
                    tryAgainButton(prominent: true)
                }
            }
        case .offScript:
            header(shot)
            line(String(localized: "That shot started from where the balls stopped. Try again puts them back for the trick."))
            buttons { tryAgainButton(prominent: true); listButton }
        case .off:
            EmptyView()
        }
    }

    /// The slim card (0.7.5, lensReplayCompact): the shot's heading and the one button that moves the shot on, so a
    /// guided Lens replay on a phone held upright keeps the table its height. Your turn while the answer is set up,
    /// played or explained; after a try, Next shot for a make and Try again for a miss; nothing more while aiming.
    /// While the answer is explained (0.7.6, #64) the shot's one idea sits beside Your turn, at most two lines, so the
    /// card carries what the replay is for and no empty glass; VoiceOver reads the whole idea.
    @ViewBuilder
    private func slim(_ shot: TrickShot) -> some View {
        header(shot)
        switch mode.phase {
        case .explaining:
            if typeSize.isAccessibilitySize {
                slimIdea(shot)
                buttons { turnButton(prominent: true) }
            } else {
                HStack(alignment: .center, spacing: 10) {
                    slimIdea(shot)
                    turnButton(prominent: true).fixedSize().controlSize(.regular)
                }
            }
        case .ready, .watching:
            buttons { turnButton(prominent: true) }
        case .judged(let verdict):
            buttons { if verdict.made { nextShotButton } else { tryAgainButton(prominent: true) } }
        case .offScript:
            buttons { tryAgainButton(prominent: true) }
        case .aiming, .off:
            EmptyView()
        }
    }

    /// The idea in the slim card: two lines at most, the light bulb before it as in the full card.
    private func slimIdea(_ shot: TrickShot) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: "lightbulb.fill").foregroundStyle(palette.slide).accessibilityHidden(true)
            Text(shot.idea)
                .font(Theme.body)
                .foregroundStyle(palette.paper.opacity(0.9))
                .lineLimit(2)
                .accessibilityLabel(shot.idea)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Pieces

    private var nextShotButton: some View {
        Button { mode.next() } label: {
            Label("Next shot", systemImage: "arrow.forward").font(.headline).lineLimit(1)
                .frame(minHeight: Self.buttonHeight)
        }
        .buttonStyle(.glassProminent).foregroundStyle(palette.ground)
        .keyboardShortcut(.defaultAction)
    }

    private func header(_ shot: TrickShot) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(shot.title).font(Theme.heading).lineLimit(2)
            Spacer(minLength: 0)
            Text(shot.difficulty.label).font(Theme.label).foregroundStyle(palette.slide)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func line(_ text: String) -> some View {
        Text(text)
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

    private func watchButton(prominent: Bool, again: Bool = false) -> some View {
        styled(Button { mode.watch() } label: {
            Label(again ? "Watch again" : "Watch it", systemImage: again ? "arrow.counterclockwise" : "play.fill")
                .font(.headline).lineLimit(1).frame(minHeight: Self.buttonHeight)
        }, prominent: prominent)
        .accessibilityHint("Plays the answer, then explains it in the Physics Lens")
    }

    private func turnButton(prominent: Bool) -> some View {
        styled(Button { mode.yourTurn() } label: {
            Label("Your turn", systemImage: "target").font(.headline).lineLimit(1).frame(minHeight: Self.buttonHeight)
        }, prominent: prominent)
        .accessibilityHint("Puts the balls back and opens the aiming controls")
    }

    private func tryAgainButton(prominent: Bool) -> some View {
        styled(Button { mode.tryAgain() } label: {
            Label("Try again", systemImage: "arrow.uturn.backward").font(.headline).lineLimit(1)
                .frame(minHeight: Self.buttonHeight)
        }, prominent: prominent)
        .accessibilityHint("Puts the balls back where the shot started, with your last aim, power and spin")
    }

    /// Show / Hide the answer's path: an icon button, offered once the answer has been watched, while the player lines
    /// up or reads the verdict (TrickShotMode.offersAnswerPath). The path itself is drawn by TrickTableLayer.
    @ViewBuilder
    private var answerPathButton: some View {
        if mode.offersAnswerPath {
            let shown = mode.showAnswerPath
            Button { mode.showAnswerPath.toggle() } label: {
                Label(shown ? "Hide the answer's path" : "Show the answer's path",
                      systemImage: shown ? "point.topleft.down.to.point.bottomright.curvepath.fill"
                                         : "point.topleft.down.to.point.bottomright.curvepath")
                    .labelStyle(.iconOnly)
                    .frame(minWidth: 30, minHeight: Self.buttonHeight)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel(shown ? "Hide the answer's path" : "Show the answer's path")
            .accessibilityHint("Draws the answer's cue-ball path faintly on the cloth beside your own")
        }
    }

    private var listButton: some View {
        Button { mode.listOpen = true } label: {
            Label("All trick shots", systemImage: "list.bullet").labelStyle(.iconOnly)
                .frame(minWidth: 30, minHeight: Self.buttonHeight)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel("All trick shots")
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
        if let shot = mode.current, mode.isActive, !model.holdForTips, !model.whatIf.isShowing {
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

    /// The phase's own words. Explaining has none beyond the idea; Watch it, Your turn, Try again and Next shot are the
    /// strip's primary action (PhonePrimaryAction.trick).
    @ViewBuilder
    private func phaseBlurb(_ shot: TrickShot) -> some View {
        switch mode.phase {
        case .ready:
            // The hook, and Your turn for a player who wants to skip the answer (Watch it is the primary action).
            Blurb(sentence: shot.hook, buttons: [
                BlurbButton(String(localized: "Your turn"),
                            hint: String(localized: "Puts the balls back and opens the aiming controls")) { mode.yourTurn() }
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
            buttons.append(BlurbButton(String(localized: "Watch yours in the Lens"),
                                       hint: String(localized: "Replays your stroke slowly in the Lens, stopping on the moments that made it")) {
                mode.watchYours()
            })
        }
        return Blurb(title: verdict.made ? String(localized: "Made it!") : String(localized: "Missed"),
                     sentence: sentence, buttons: buttons)
    }
}

extension PhonePrimaryAction {
    /// The trick shot's way on, the old card's prominent button (phone UI plan, Part 3 "The control strip"): "Watch
    /// it" before the answer has been watched; "Your turn" while the answer plays and replays in the Lens (one word for
    /// the whole replay, so it never changes under the thumb); "Next shot" after a make; "Try again" after a miss or an
    /// off-script shot. Nil while lining up (the aiming panel is the way on), outside a trick shot, and while a
    /// what-if is open (the trick card stepped aside for it too).
    static func trick(_ model: ShowpieceModel) -> PhonePrimaryAction? {
        let mode = model.trickMode
        guard mode.isActive, !model.whatIf.isShowing else { return nil }
        switch mode.phase {
        case .ready:
            return PhonePrimaryAction(title: String(localized: "Watch it"),
                                      hint: String(localized: "Plays the answer, then explains it in the Physics Lens")) {
                mode.watch()
            }
        case .watching, .explaining:
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
            RoundedRectangle(cornerRadius: 48, style: .continuous)
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
        for k in pockets where k < table.pockets.count {
            if let p = TablePathStroke.ring(at: table.pockets[k], radius: table.pocketCaptureRadius[k] + 0.012, proj) {
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
