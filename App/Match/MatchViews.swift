// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink wave 3 note 22: the game-ending ruling and the match
//          result carry the one share picture's quiet Share (ResultShare, App/SharePicture.swift), the game's name as
//          the picture's mode.)
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 9's leftover note: the Lens is named by its one
//          name, "Physics Lens", where a player reads it.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 5, the mode frame: the match is the state card
//          with the kit's scoreboard strip first (MatchScoreboard: "You" and "Computer", the computer's level once as a
//          badge, each seat's score, group or balls left, the cyan dot on whose turn it is, the target or nine-ball's
//          ball to hit first in caption; bar billiards alone sets your score against the best), then whose shot and the
//          game with the kit's worded More menu, the standings without what the strip shows, the settled line, the call
//          and the choices on kit buttons. A ruling of a game still going is the kit's ruling card (Foul, Legal, Loss of
//          turn; the last sentence as what happens next, the rest behind More) with an actions panel under it (how the
//          points came, Why that shot as a quiet button, the remarkable shot's name, Continue with Watch it in the Lens
//          beside it); a ruling that ends the game and the end of the game are the kit-style result card (a win in
//          pocket gold, a loss in warning), Rematch the way on and Menu beside it. End match is a destructive secondary.
//          The slim rules are kept (#32, #34, #35): the card decides what it passes, and switches the kit cards' own
//          slimming off. The ball icons' colours come from ModeBallColour; their number and hairline are the ground.
//          The highlight's name and the settled line's icon are paper and paper2, no longer cyan.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2: one meaning per colour. Fouls, misses and
//          refusals take Palette.warning; headings, try counts, tags and difficulty take paper or paper2; the sliding
//          magenta is left for sliding and friction.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 words, Part A row 1: rulingSentences takes headed; the card
//          and the phone blurb, which show the "Foul" heading, no longer start the sentence with "Foul:" as well. The
//          settled line under the banner has no heading and keeps it.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (phone UI plan, Part 4 step 5: no change on screen. The pieces the
//          upright phone's match blurbs (MatchPhoneBlurbs.swift) share with this card are lifted out so both say the
//          same words: the ruling's title and sentences, the settled line, the Rematch hint and the announcements are
//          MatchCard statics; the phase and clock feedback is the MatchFeedback modifier; the turn banner's standings
//          (nine-ball's ball to hit first, eight-ball's player rows, the table games' lines, the score) are
//          MatchStandings, which the banner shows exactly as before.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream cards, plans/22-Nov-2026-phone-bug-hunt.md #32, #34,
//          #35, #37: a routine ruling that waits for a tap (MatchMode.rulingWaitsForTap, a break's with the Lens offer
//          up) always shows its own row, "Watch it in the Lens" and Continue, slim or not, so a legal break with the Lens
//          on no longer freezes the match behind a bare heading. The slim card (Lens on, upright phone) drops the words
//          only while a guided Lens replay actually plays; at rest a foul, a lost peg or the end of the game says why,
//          with its points, and the Lens offer stays in the button row beside Continue. The aiming banner's slim form
//          keeps the More menu (End match, Your name) and an open names editor. Eight-ball player rows stack the name,
//          the group and the ball icons when one line does not fit, instead of cutting them.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 coordinator: while aiming with the Lens on, on an upright phone,
//          the card shows the turn line only).
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 match-ui, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md B2
//          and B3: the person is "you" on every line (MatchMode.you): "Your shot", "You have the solids.", "You win!",
//          score and player rows labelled "You", and the names editor lists only the person's seat ("Your name"),
//          never the computer's. A ruling that ends the game is headed by the result ("You win!" with a trophy, or the
//          winner's name with a flag in the foul colour) and says why; the result card no longer repeats that reason,
//          and adds the record against this level and, from the second game, this sitting's tally. Nine-ball's banner
//          says who is on two fouls. The table games never say "to break", and on the computer's turn the banner
//          describes its stroke instead of giving orders; fouls there name balls by colour. Bar billiards alone hides
//          "This break: 0", leaves the repeated "Time is up." out of routine rulings, and its Rematch hint says
//          against the clock. The End-this-game confirmation lives on MatchMode.confirmingEnd (so the menu's back
//          button can stand aside for Escape). While a guided Lens replay plays on an upright phone
//          (lensReplayCompact) the ruling shows only its heading and its button. The aiming card's Lens offer, which
//          could never show there, is gone.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 watch-invite, plans/22-Nov-2026-v074-glow-up-plan.md G3: the
//          Lens offer follows the model's offerLensReplay and watchShotInLens (renamed from the break-only
//          offerLensReplayOfBreak and watchBreakInLens): after a break as before, and after any shot by either seat that
//          MatchMode offers as remarkable, whose card names the shot and its physics (HighlightWords) above the button.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.2: comment only - the hand-over card's heading is now whose shot
//          it is, from MatchWords.handOver, no longer an instruction to pass the device.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (opponent stream: on the computer's turn the card shows "Thinking..."
//          instead of the call control and the choice buttons (the person cannot act for it); after the computer's
//          stroke the ruling card offers "Why that shot", which opens its plain-words reasons in the card itself (so it
//          is part of the notebook panel on the open Duo, iPad and Mac, never a sheet). The ruling's tap moved to the
//          match itself: MatchMode plays each ruling's moment through SoundBoard.play, which sounds it and plays its
//          haptic together, so the card no longer adds a second tap of its own.)
// Edited: 21-November-2026 by Claude Opus 5.5 High (tables-screens) - the three table games: the turn banner says
//          which ball to strike and what is left (bumper pool: each side's balls still to sink; five-pin: your ball,
//          the ball to hit first, the scores and the target; bar billiards: the clock, or the bar once time is up,
//          the break in progress, the total and, alone, the best score); after each five-pin and bar-billiards shot a
//          "How the points came" section explains the score line by line (TablePoints, TableGameWords); the result
//          card says what a one-player bar-billiards game did to the best score; VoiceOver hears the points and the
//          scores with each ruling and the moment time runs out. The ruling card names the ball that was really
//          struck (MatchMode.lastShotBall) and the other tables' balls by their names there.
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan items 13, 14, 15, 16, 18, 20, 21 and 43. A routine ruling
//          (MatchMode.lastRulingShow == .banner) shows for a beat without a Continue button, settles by itself, and
//          stays as a line under the turn banner until the next shot, "Why that shot" with it for the computer's
//          shots; a tap or Return on it moves on at once. The card stays for fouls, choices, a hand-over and the end.
//          A shot played on the suggested call says which call it was. While a match shot plays, "See the ruling"
//          jumps to its end; after a break, "Watch it in the Lens" replays it under the Lens. On the computer's turn
//          the card says "Lining up its shot..." while the model stages its stroke. "End match" (from the banner's
//          More menu) ends the game after an in-card confirmation. Bar billiards' banner counts only the whites left
//          to play (the D and the tray, BarBilliardsRules.whitesLeftToPlay), as the game does. The ball icons follow
//          the table's own ball set (TableBallSet; plain whites and a red, white and yellow, spotted marked balls),
//          and bumper pool's and five-pin's banner lines show them. At the largest text sizes the banner's first line
//          wraps freely and stacks above the game's name, and every row of buttons becomes a column (CardButtonRow,
//          shared with the call card).)
// Edited: Claude Opus 5.5 High, 21-November-2026 (access stream hooks, 0.7.0 items 44 and 47: announcements go through the one speaker,
//          ShotNarration.announce, the ruling itself is said once by the shot's narration, and Continue's arrow follows
//          the reading direction.)
// PURPOSE: Everything the player sees of a match (eight-ball and nine-ball against the computer; the other tables'
//          games use the same card, and bar billiards is also played alone): the state card (the kit's scoreboard strip
//          first), with the kit's ruling or result card and an actions panel under it, its content following
//          MatchMode.phase:
//            aiming   - the turn banner: who shoots (or breaks), the game, each player's group with their balls left
//                       as small ball icons (eight-ball), the ball to hit first (nine-ball), running scores and the
//                       clock where the game keeps them; the last routine ruling as a line; editable player names
//                       and End match (the banner's More menu); a pending choice ("take the table or rack again");
//                       and the call control while the rules want a call (eight-ball after the break; never in
//                       nine-ball).
//            shooting - the banner, small, with the call, and "See the ruling".
//            ruling   - a routine ruling: its header and sentences, settling by themselves; otherwise the card: the
//                       ruling in plain words ("Foul: the cue ball hit the 11 first. Ball in hand for Sam."), then the
//                       choice, or Continue. After a break, or a remarkable shot by either seat (MatchMode's
//                       lensHighlight, which makes the ruling a card), "Watch it in the Lens", the remarkable shot named
//                       with its physics above it.
//            handOver - whose shot it is ("Sam to shoot.") and Ready; kept for the engine's seats, never reached
//                       against the computer.
//            over     - who won and why, the running scores, Rematch and Menu.
//          Feedback (rules plan, package 6): the sound and haptic of a foul, a turn change and a win are played by
//          MatchMode through SoundBoard.play (only felt with Vibration on); this card speaks the ruling to VoiceOver as
//          it appears, routine or not.
//          Hosted by PlayCards (FreePlayViews.swift) next to the other mode cards, so it sits above the controls on a
//          phone, at the top of the side column on iPad and Mac, and in the notebook panel on the open Duo; it never
//          opens a sheet (the End match confirmation is inside the card), so on the Duo nothing covers the table.
//          Reads MatchMode (state, phase, rules, currentCall, lastRuling, lastRulingShow, settledRuling, the last
//          shot's facts, playerNames) and calls setCall, acknowledgeRuling, settleNow, answer, rematch,
//          setPlayerName; reads the model's match-shot calls (matchShotPlaying, seeRuling, offerLensReplay,
//          watchShotInLens, computerTurnStage, endMatch) and MatchMode.lensHighlight.
// SRP/DRY check: Pass - words are in MatchWords, OpponentWords and TableGameWords, the call in CallControl, the
//          cue-ball placement in FreePlayViews and PlayTableLayer, each table's ball looks in TableBallSet and their
//          colours in BallTextures (through ModeBallColour); the strip, cards and buttons are the kit's, the result card
//          ModeFrameKit's ModeResultCard, as every mode's.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import SwiftUI

struct MatchCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// True on a phone held upright while a guided Lens replay plays, and whenever the Lens is on in a match there
    /// (ShowpieceView.lensCardsSlim): the card's slim form, so the Lens table keeps its height.
    @Environment(\.lensReplayCompact) private var lensReplayCompact
    private var deviceReader = KitDeviceReader()
    @State private var editingNames = false
    /// "Why that shot" is open (on the ruling card, or under the settled line in the banner).
    @State private var showingWhy = false
    // "End match" asking to confirm is MatchMode.confirmingEnd (0.7.5), not view state, so the menu's back button
    // can read it and give up Escape to the card's "Keep playing".

    init(model: ShowpieceModel) {
        self.model = model
    }

    /// The slim form's narrow case: a guided Lens replay is actually playing (the balls are moving or held on a beat).
    /// Only then does a ruling shrink to its heading and its button. With the Lens merely on and the balls at rest the
    /// slim card still says why a foul or a game-ending shot was ruled, and keeps every button that moves the game on
    /// (0.7.6, #32 and #34). Same test as ShowpieceView.lensReplayCompact; the environment flag already says upright
    /// phone and no opening.
    private var replaying: Bool {
        lensReplayCompact && model.lensOn && model.guided && !model.aimReady
    }

    /// A ruling the slim card still explains with the Lens on: a foul, a lost peg (bar billiards' penalty) or the end
    /// of the game. Its sentences and its points are the reason the player is stopped.
    private static func explainsItself(_ r: Ruling) -> Bool {
        r.fouled || r.result != nil || r.reasons.contains(.whitePegDown) || r.reasons.contains(.blackPegDown)
    }

    var body: some View {
        if let match = model.match {
            // UI rethink package 5: the match is the state card (the scoreboard strip first, then whose shot and the
            // game, the standings and what is asked now), with the kit's ruling card or result card under it and the
            // actions in a panel at the bottom, the way on at its bottom right. The kit's cards slim themselves on
            // lensReplayCompact; this card keeps its own slim rules (#32, #34, #35) by deciding what it passes them.
            VStack(alignment: .leading, spacing: Theme.Space.cardGap(deviceReader.current)) {
                content(match)
            }
            .environment(\.lensReplayCompact, false)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tint(palette.accent)
            .animation(reduceMotion ? nil : Theme.Motion.standard, value: match.phase)
            .modifier(MatchFeedback(match: match) { phase in
                // The reasons belong to one shot: closed when the next shot starts, kept open while a routine ruling
                // settles into the banner (it was opened during that beat).
                if phase == .shooting { showingWhy = false }
            })
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private func content(_ match: MatchMode) -> some View {
        switch match.phase {
        case .aiming:
            // Slim with the Lens on, on an upright phone (0.7.5 coordinator): the turn line, so the Lens table keeps
            // its size; the scoreboard, the standings and the settled ruling come back when the Lens goes off. The More
            // menu (End match, Your name) and an open names editor stay (0.7.6, #35).
            statePanel(match, scoreboard: !lensReplayCompact) {
                TurnBanner(match: match, editingNames: $editingNames, slim: lensReplayCompact, besideScoreboard: true)
                if match.confirmingEnd {
                    endMatchConfirmation(match)
                } else {
                    // (No Lens offer here: the model only offers it while the ruling or the result is up.)
                    if let settled = match.settledRuling, !lensReplayCompact { settledSection(settled, match) }
                    if match.computerSeatToAct != nil {
                        // The computer's decision: its choice prompt (if any) and that it is thinking or lining up;
                        // nothing to tap.
                        if let choice = match.state.pendingChoice {
                            line(MatchWords.choicePrompt(choice, names: match.playerNames, you: match.you))
                        }
                        computerLine
                    } else if let choice = match.state.pendingChoice {
                        choiceSection(choice, match)
                    } else if match.mustCall {
                        MatchCallControl(model: model, match: match)
                    }
                }
            }
        case .shooting:
            statePanel(match, scoreboard: !lensReplayCompact) {
                TurnBanner(match: match, editingNames: .constant(false), compact: true)
                if let call = match.currentCall { line(MatchWords.callLine(call)) }
                if model.matchShotPlaying {
                    // A paused or slowed replay never leaves the player waiting for the ruling (item 14).
                    KitButtonRow(secondary: KitAction(String(localized: "See the ruling"), systemImage: "forward.end") {
                        model.seeRuling()
                    })
                }
            }
        case .ruling:
            if !lensReplayCompact { statePanel(match) { EmptyView() } }
            if let r = match.lastRuling {
                if r.result != nil {
                    endingRuling(r, match)
                } else if match.lastRulingShow == .banner {
                    routineRuling(r, match)
                } else {
                    rulingCard(r, match)
                }
            } else {
                // A ruling phase with nothing to show cannot be read; let the player move on.
                actionsPanel { KitButtonRow(primary: continueAction(match)) }
            }
        case .handOver:
            handOver(match)
        case .over:
            if !lensReplayCompact { statePanel(match) { EmptyView() } }
            result(match)
        }
    }

    // MARK: Surfaces

    /// The state card: the scoreboard strip first (principle 6), then the caller's content, on the kit's panel.
    private func statePanel<Content: View>(_ match: MatchMode, scoreboard: Bool = true,
                                           @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            if scoreboard { MatchScoreboard(match: match) }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .kitPanel()
    }

    /// The panel that carries a ruling's extra words and its buttons, under the kit's ruling card.
    private func actionsPanel<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .kitPanel()
    }

    // MARK: Ruling

    /// The ruling in the kit's card: Foul (warning), Legal (paper) or Loss of turn (paper2); its last sentence as what
    /// happens next ("Ball in hand for the computer."), the sentences before it as the reason behind More. Under it
    /// the actions panel: how the points came, "Why that shot", the remarkable shot's name, then Continue (or the
    /// choice) with "Watch it in the Lens" beside it.
    /// Slim (lensReplayCompact, an upright phone with the Lens on in a match): while a guided Lens replay actually
    /// plays, only the verdict, what happens next and the button (or the choice that must be answered) stay, so the
    /// table keeps its height. With the balls at rest a foul or a lost peg still says why, with its points (#34), and
    /// "Watch it in the Lens" stays beside Continue; a remarkable shot keeps its name.
    @ViewBuilder
    private func rulingCard(_ r: Ruling, _ match: MatchMode) -> some View {
        let explains = !replaying && (!lensReplayCompact || Self.explainsItself(r))
        rulingVerdict(r, match, withReason: explains)
        actionsPanel {
            if !replaying {
                if explains {
                    if !match.lastPoints.isEmpty { pointsSection(match) }
                    whyIfComputers(r, match)
                }
                highlightName(withLine: !lensReplayCompact)
            }
            // A choice the computer makes is made after Continue, on its turn; a person's is answered here.
            if let choice = match.state.pendingChoice, !match.isComputer(choice.chooser) {
                if let lens = lensAction { KitButtonRow(secondary: lens) }
                choiceSection(choice, match)
            } else {
                KitButtonRow(primary: continueAction(match), secondary: lensAction)
                    .modeShortcut(continueAction(match), .defaultAction)
            }
        }
    }

    /// A routine ruling during its beat: the same verdict card with no Continue button. It settles by itself after
    /// MatchMode.settleBeat; a tap on it (or Return) moves on at once. Slim (the verdict and what happens next only)
    /// with the Lens on, on an upright phone.
    /// A routine ruling that waits for a tap (MatchMode.rulingWaitsForTap: a break's, with "Watch it in the Lens" up)
    /// never settles by itself, so it always shows its own row, the offer and Continue, slim or not (0.7.6, #32: the
    /// slim card once showed a bare heading here and the match froze; the heading's tap looked like a label).
    @ViewBuilder
    private func routineRuling(_ r: Ruling, _ match: MatchMode) -> some View {
        let waits = match.rulingWaitsForTap
        if waits {
            // Continue below carries the tap and Return, so the card is plain here.
            rulingVerdict(r, match, withReason: !lensReplayCompact)
        } else {
            Button { match.settleNow() } label: {
                rulingVerdict(r, match, withReason: !lensReplayCompact)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
            .accessibilityHint(String(localized: "Moves on now. It also moves on by itself in a moment."))
        }
        let extras = !lensReplayCompact && (!match.lastPoints.isEmpty || whyAvailable(r, match) || namedHighlight != nil)
        if extras || waits {
            actionsPanel {
                if !lensReplayCompact {
                    if !match.lastPoints.isEmpty { pointsSection(match) }
                    whyIfComputers(r, match)
                    highlightName(withLine: true)
                }
                if waits {
                    KitButtonRow(primary: continueAction(match), secondary: lensAction)
                        .modeShortcut(continueAction(match), .defaultAction)
                }
            }
        }
    }

    /// The kit's ruling card for a ruling of a game still going: the verdict from the rules (RulingVerdict), the last
    /// sentence as the next step, the rest as the reason behind More (left out in the slim form).
    private func rulingVerdict(_ r: Ruling, _ match: MatchMode, withReason: Bool) -> some View {
        let sentences = Self.rulingSentences(r, match)
        let next = sentences.last ?? Self.rulingTitle(r, match)
        let reason = sentences.dropLast().joined(separator: " ")
        return RulingCard(RulingVerdict(r), nextStep: next, reason: withReason && !reason.isEmpty ? reason : nil)
    }

    /// A ruling that ends the game, in the result card: headed by the result ("You win!" in pocket gold, a loss in
    /// warning, a game with no winner in paper), never "Keep shooting"; its sentences and points say why (in the slim
    /// form too, #34, except while a guided replay plays), then Continue with "Watch it in the Physics Lens" beside it
    /// and the one share picture's quiet Share on the left.
    @ViewBuilder
    private func endingRuling(_ r: Ruling, _ match: MatchMode) -> some View {
        let lines = replaying ? [] : Self.rulingSentences(r, match)
        let verdict = Self.rulingTitle(r, match)
        let tone = Self.tone(r.result, match)
        ModeResultCard(verdict: verdict, tone: tone, lines: lines,
                       tryAgain: lensAction, next: continueAction(match),
                       share: share(match, verdict: verdict, tone: tone)) {
            if !replaying {
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    if !match.lastPoints.isEmpty { pointsSection(match) }
                    whyIfComputers(r, match)
                    highlightName(withLine: !lensReplayCompact)
                }
            }
        }
        .modeShortcut(continueAction(match), .defaultAction)
    }

    /// The one share picture's quiet Share (package 10): the game's name ("Eight-ball") as the mode, the result as the
    /// verdict, the last shot over its own table. Nil while no shot is on the table, so the button hides itself.
    private func share(_ match: MatchMode, verdict: String, tone: ResultTone) -> KitAction? {
        ResultShare.action(model: model, mode: MatchWords.title(match.state.kind), verdict: verdict, tone: tone)
    }

    /// A result's colour: the person's win in pocket gold, a game with no winner in paper, a loss in warning.
    private static func tone(_ result: MatchResult?, _ match: MatchMode) -> ResultTone {
        guard let result else { return .plain }
        if personWon(result, match) { return .pocketed }
        return result.winner == nil ? .plain : .foul
    }

    /// The last routine ruling, settled under the turn banner until the next shot: its sentences as one quiet line
    /// (and the points of a bar-billiards or five-pin shot), with "Why that shot" when the computer played it.
    @ViewBuilder
    private func settledSection(_ r: Ruling, _ match: MatchMode) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
            Image(systemName: r.turnPasses ? "arrow.left.arrow.right" : "checkmark.circle")
                .foregroundStyle(palette.paper2)
                .accessibilityHidden(true)
            Text(Self.settledWords(r, match))
                .font(Theme.label)
                .foregroundStyle(palette.paper2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        whyIfComputers(r, match)
    }

    /// The settled line's words: the ruling's sentences, then how the points came (five-pin, bar billiards).
    static func settledWords(_ r: Ruling, _ match: MatchMode) -> String {
        let points = TableGameWords.lines(match.lastPoints, kind: match.state.kind, names: match.playerNames,
                                          you: match.you)
        // 0.7.10 words: no heading above the settled line, so its foul keeps "Foul:".
        return (rulingSentences(r, match, headed: false) + points).joined(separator: " ")
    }

    /// The ruling's heading words: the result for a ruling that ends the game ("You win!"), else "Foul", else "Turn
    /// over" or "Keep shooting". The match card heads a game still going with the kit's verdict word (RulingCard);
    /// the upright phone's ruling blurb still reads these.
    static func rulingTitle(_ r: Ruling, _ match: MatchMode) -> String {
        if let result = r.result { return MatchWords.resultTitle(result, names: match.playerNames, you: match.you) }
        if r.fouled { return String(localized: "Foul") }
        return r.turnPasses ? String(localized: "Turn over") : String(localized: "Keep shooting")
    }

    /// True when the game's winner is the person: their seat (MatchMode.personSeat) when there is one, otherwise any
    /// seat the computer does not play. A game with no named winner is not a win.
    static func personWon(_ result: MatchResult, _ match: MatchMode) -> Bool {
        guard let w = result.winner else { return false }
        if let person = match.personSeat { return w == person }
        return !match.isComputer(w)
    }

    /// The ruling's sentences, from what the recording showed when the shot was ruled (MatchMode keeps the balls that
    /// dropped and the first ball the striking ball touched, so a wrong-ball foul names the ball), then, when the
    /// stroke went through with no call made, the suggested call it was held to. "Time is up." is said on a card
    /// only: a routine ruling after the bar drops would repeat it every shot.
    /// `headed` (0.7.10 words): the words sit under a heading that says "Foul", so a foul line starts with what
    /// happened. The settled line has no heading and passes false.
    static func rulingSentences(_ r: Ruling, _ match: MatchMode, headed: Bool = true) -> [String] {
        // 0.7.10 words: the heading says "Foul" only for a foul that does not end the game (rulingTitle).
        let foulHeaded = headed && r.result == nil && r.fouled
        var out = MatchWords.sentences(for: r, names: match.playerNames, pocketed: match.lastPocketed,
                                       firstBall: match.lastFirstBall, kind: match.state.kind, you: match.you,
                                       target: match.targetBall(for: r.shooter),
                                       mentionTimeUp: match.lastRulingShow == .card && match.settledRuling == nil,
                                       foulHeaded: foulHeaded)
        // Only for the shot itself, not for an answered choice that followed it.
        if match.lastCallWasSuggested, let call = match.lastShotCall, !r.reasons.contains(.choiceAnswered) {
            out.insert(MatchWords.suggestedCallUsed(call), at: 0)
        }
        return out
    }

    /// Five-pin and bar billiards: how the shot's points came, line by line (everyone's score is the scoreboard's).
    @ViewBuilder
    private func pointsSection(_ match: MatchMode) -> some View {
        SectionLabel(String(localized: "How the points came"))
            .accessibilityAddTraits(.isHeader)
        ForEach(Array(TableGameWords.lines(match.lastPoints, kind: match.state.kind, names: match.playerNames,
                                           you: match.you).enumerated()),
                id: \.offset) { _, s in line(s) }
    }

    // MARK: The computer

    /// "Thinking..." with a small spinner while the computer works out its stroke (or its answer), then "Lining up
    /// its shot..." while the model swings its aim and draws its cue back.
    private var computerLine: some View {
        let lining = model.computerTurnStage == .staging || model.computerTurnStage == .striking
        return HStack(spacing: Theme.Space.xs) {
            ProgressView().controlSize(.small).accessibilityHidden(true)
            Text(lining ? OpponentWords.liningUp : OpponentWords.thinking)
                .font(bodyFont).foregroundStyle(palette.paper)
        }
        .accessibilityElement(children: .combine)
    }

    /// True when the ruling is on the computer's own stroke (not on an answered choice), so "Why that shot" shows.
    private func whyAvailable(_ r: Ruling, _ match: MatchMode) -> Bool {
        guard let shot = match.opponent?.lastShot else { return false }
        return shot.seat == r.shooter && match.isComputer(r.shooter) && !r.reasons.contains(.choiceAnswered)
    }

    /// "Why that shot" for a ruling on the computer's own stroke (not on an answered choice).
    @ViewBuilder
    private func whyIfComputers(_ r: Ruling, _ match: MatchMode) -> some View {
        if whyAvailable(r, match), let shot = match.opponent?.lastShot {
            whySection(shot)
        }
    }

    /// "Why that shot": a quiet button that opens the computer's reasons, in plain words, inside the card.
    @ViewBuilder
    private func whySection(_ shot: OpponentShot) -> some View {
        QuietButton(OpponentWords.whyThatShot, systemImage: showingWhy ? "chevron.up" : "questionmark.bubble") {
            showingWhy.toggle()
        }
        .accessibilityValue(showingWhy ? String(localized: "Open") : String(localized: "Closed"))
        if showingWhy {
            ForEach(Array(OpponentWords.why(shot).enumerated()), id: \.offset) { _, s in line(s) }
        }
    }

    /// After a match break, or a remarkable shot by either seat, a replay of it under the Lens for anyone who wants
    /// it (every match shot plays at real speed in the ordinary view; the model says when the offer stands). The offer
    /// is two pieces since 0.7.6: the remarkable shot's name above (highlightName) and this action, the secondary
    /// beside Continue, so the slim card keeps it too. Nil when nothing is offered.
    private var lensAction: KitAction? {
        guard model.offerLensReplay else { return nil }
        return KitAction(String(localized: "Watch it in the Physics Lens"), systemImage: "eye") { model.watchShotInLens() }
    }

    /// The remarkable shot on offer, or nil for the break (the ruling already says it was the break) and when nothing
    /// is offered.
    private var namedHighlight: ShotHighlight? {
        guard model.offerLensReplay, let h = model.match?.lensHighlight, h.kind != .breakShot else { return nil }
        return h
    }

    /// A remarkable shot on offer, named above the button: its title in paper semibold, and (in the full card) the
    /// physics in one line (HighlightWords). The slim card keeps the title only.
    @ViewBuilder
    private func highlightName(withLine: Bool) -> some View {
        if let h = namedHighlight {
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                Text(HighlightWords.title(h.kind))
                    .font(Theme.label.weight(.semibold))
                    .foregroundStyle(palette.paper)
                    .fixedSize(horizontal: false, vertical: true)
                if withLine { line(HighlightWords.line(h.kind)) }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func continueAction(_ match: MatchMode) -> KitAction {
        KitAction(String(localized: "Continue"), systemImage: "arrow.forward") { match.acknowledgeRuling() }
    }

    /// The choice ("take the table or rack again"): the first answer, the usual one, is the primary; the second beside
    /// it; any others under More.
    @ViewBuilder
    private func choiceSection(_ c: PendingChoice, _ match: MatchMode) -> some View {
        line(MatchWords.choicePrompt(c, names: match.playerNames, you: match.you))
        let answers = c.choice.answers.enumerated().map { i, a in
            KitAction(MatchWords.answer(a), id: "answer-\(i)") { match.answer(a) }
        }
        KitButtonRow(primary: answers.first, secondary: answers.dropFirst().first, more: Array(answers.dropFirst(2)))
            .modeShortcut(answers.first, .defaultAction)
    }

    // MARK: End match

    /// Asked inside the card (no alert or sheet, so nothing covers the table): ending throws the game away and, like
    /// any game not finished by the rules, it is not counted in the record (MatchRecord). End match is a destructive
    /// secondary (warning words), Keep playing the quiet way back (Escape).
    /// The flag is MatchMode.confirmingEnd: set by the banner's More menu, cleared here and when the phase moves on.
    @ViewBuilder
    private func endMatchConfirmation(_ match: MatchMode) -> some View {
        let keep = KitAction(String(localized: "Keep playing")) { match.confirmingEnd = false }
        line(String(localized: "End this game? It won't be saved, and it doesn't count in your record."))
        KitButtonRow(secondary: KitAction(String(localized: "End match"), systemImage: "xmark.circle", role: .destructive) {
            match.confirmingEnd = false
            model.endMatch()
            if !model.menuOpen { model.openMenu() }
        }, quiet: keep)
        .modeShortcut(keep, .cancelAction)
    }

    // MARK: Hand-over

    /// Whose shot it is ("Sam to shoot."), ball in hand and their group, and Ready; kept for the engine's seats,
    /// never reached against the computer.
    @ViewBuilder
    private func handOver(_ match: MatchMode) -> some View {
        let next = MatchWords.name(match.state.turn, in: match.playerNames)
        let words: [String] = {
            var w: [String] = []
            if let hand = MatchWords.ballInHand(match.state.ballInHand, for: next) { w.append(hand) }
            if let g = match.state.group(of: match.state.turn) {
                w.append(MatchWords.groupLine(g, left: match.state.ballsRemaining(for: match.state.turn).count,
                                              tableOpen: false))
            }
            return w
        }()
        let ready = KitAction(String(localized: "Ready"), systemImage: "checkmark") { match.acknowledgeRuling() }
        ModeCard(name: MatchWords.handOver(to: next), goal: words.joined(separator: " "), primary: ready)
            .modeShortcut(ready, .defaultAction)
    }

    // MARK: Result

    /// The result card: who won (the person's win in pocket gold, a loss in warning, a game with no winner in paper),
    /// why, unless the ruling card just before it said so, the best score alone, and against the computer the record
    /// at this level and, from the second game of the sitting, the sitting's tally (the scores are the scoreboard's).
    /// Rematch is the way on; Menu beside it.
    @ViewBuilder
    private func result(_ match: MatchMode) -> some View {
        let rematch = KitAction(String(localized: "Rematch"), systemImage: "arrow.counterclockwise") { match.rematch() }
        let menu = KitAction(String(localized: "Menu"), systemImage: "chevron.backward") {
            model.endMatch()
            if !model.menuOpen { model.openMenu() }
        }
        if let r = match.state.result {
            let verdict = MatchWords.resultTitle(r, names: match.playerNames, you: match.you)
            let tone = Self.tone(r, match)
            ModeResultCard(verdict: verdict, tone: tone, lines: resultLines(r, match), tryAgain: menu, next: rematch,
                           share: share(match, verdict: verdict, tone: tone))
                .modeShortcut(rematch, .defaultAction)
        } else {
            actionsPanel { KitButtonRow(primary: rematch, secondary: menu) }
                .modeShortcut(rematch, .defaultAction)
        }
    }

    /// The result's lines: why (when no ruling card said it: an end reached by an answered choice), the best score,
    /// then the record lines.
    private func resultLines(_ r: MatchResult, _ match: MatchMode) -> [String] {
        var out: [String] = []
        // The ruling card that ended the game already said why (its .gameOver line); an end reached without that card
        // (an answered choice) says it here.
        if match.lastRuling?.result == nil {
            let why = MatchWords.endReason(r, shooter: match.lastRuling?.shooter, names: match.playerNames,
                                           you: match.you)
            if !why.isEmpty { out.append(why) }
        }
        if let best = match.bestOutcome { out.append(TableGameWords.bestOutcome(best)) }
        return out + Self.recordLines(match)
    }

    /// What Rematch does, per game: alone against the clock (bar billiards), against the computer, or (old saves
    /// only) between the same players.
    static func rematchHint(_ match: MatchMode) -> String {
        if match.state.players.count == 1 { return String(localized: "Racks for a new game against the clock") }
        if match.hasComputer { return String(localized: "Racks for a new game against the computer") }
        return String(localized: "Racks for a new game between the same players")
    }

    /// Against the computer: the person's record at this level in this game (MatchRecord, already counting the game
    /// just finished: MatchMode notes it before the result shows), then, from the second game of this sitting, the
    /// sitting's tally. Empty for a game with no computer.
    static func recordLines(_ match: MatchMode) -> [String] {
        guard let level = match.state.players.compactMap(\.computer).first else { return [] }
        var out = [OpponentWords.levelRecord(MatchRecord.load().tally(match.state.kind, level), level: level)]
        if match.sittingGames >= 2, let person = match.personSeat,
           let computer = match.state.players.first(where: \.isComputer)?.id {
            let wins = match.sittingWins
            out.append(OpponentWords.sitting(you: wins.indices.contains(person.index) ? wins[person.index] : 0,
                                             computer: wins.indices.contains(computer.index) ? wins[computer.index] : 0))
        }
        return out
    }

    // MARK: Feedback

    /// VoiceOver hears each ruling (a routine one too, as it appears), the hand-over and the result as they arrive,
    /// without hunting for the card.
    static func announce(_ phase: MatchMode.Phase, _ match: MatchMode) {
        let text: String
        switch phase {
        case .ruling:
            // One ruling sentence: the shot's narration says it together with the summary (ShotNarration, access
            // stream hook, 0.7.0 item 47), so the card does not say its own version over it.
            return
        case .handOver:
            text = MatchWords.handOver(to: MatchWords.name(match.state.turn, in: match.playerNames))
        case .over:
            guard let r = match.state.result else { return }
            var parts = [MatchWords.resultTitle(r, names: match.playerNames, you: match.you)]
            if match.rules.keepsRunningScore {
                parts.append(TableGameWords.scores(match.state.scores, names: match.playerNames, you: match.you))
            }
            if let best = match.bestOutcome { parts.append(TableGameWords.bestOutcome(best)) }
            parts += Self.recordLines(match)
            text = parts.joined(separator: " ")
        case .aiming, .shooting:
            return
        }
        ShotNarration.announce(text)
    }

    // MARK: Pieces

    private var bodyFont: Font { deviceReader.current == .phone ? Theme.bodyCompact : Theme.body }

    private func line(_ text: String) -> some View {
        Text(text)
            .font(bodyFont)
            .foregroundStyle(palette.paper)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: The scoreboard

/// The match's scoreboard strip (the kit's Scoreboard), the first line of the state card: the two seats, "You" and
/// "Computer" (an old game between people keeps its names), each one's standing (a running score in five-pin and bar
/// billiards, eight-ball's group and balls left, bumper pool's balls left, nothing in nine-ball), the cyan dot on
/// whose turn it is, the computer's level once as a badge, and in caption the target (five-pin's "First to N") or
/// nine-ball's ball to hit first. Bar billiards alone sets the player's score against the best kept on this device.
struct MatchScoreboard: View {
    let match: MatchMode

    private var state: MatchState { match.state }

    var body: some View {
        let players = state.players
        if let first = players.first {
            let right = players.count > 1 ? side(players[1]) : bestSide
            Scoreboard(left: side(first), right: right, turn: turn, target: target,
                       computerLevel: players.compactMap(\.computer).first?.title)
        }
    }

    /// Whose turn, as the strip's side (0 or 1); none once the game is over.
    private var turn: Int? {
        guard match.phase != .over else { return nil }
        return state.players.firstIndex { $0.id == state.turn }
    }

    /// One seat's side: its name ("You", "Computer", or an old game's name) and its standing.
    private func side(_ p: Player) -> Scoreboard.Side {
        let name = p.isComputer ? Scoreboard.computer
            : (p.id == match.you ? Scoreboard.you : MatchWords.displayName(p.id, in: match.playerNames, you: match.you))
        return Scoreboard.Side(name: name, standing: standing(p), isComputer: p.isComputer)
    }

    private func standing(_ p: Player) -> Scoreboard.Side.Standing {
        if match.rules.keepsRunningScore {
            return .score(state.scores.indices.contains(p.id.index) ? state.scores[p.id.index] : 0)
        }
        if state.kind == .eightBall {
            let words = MatchWords.groupLine(state.group(of: p.id), left: state.ballsRemaining(for: p.id).count,
                                             tableOpen: state.tableOpen)
            return words.isEmpty ? .none : .group(words)
        }
        if let bumper = match.rules as? BumperPoolRules {
            return .group(TableGameWords.ballsToSink(bumper.ballsLeft(for: p.id, in: state).count))
        }
        return .none
    }

    /// Bar billiards alone: the best score kept on this device, as the strip's other side.
    private var bestSide: Scoreboard.Side {
        // Spelled out rather than `map ?? .none`, so the case named none is never read as Optional's none.
        let standing: Scoreboard.Side.Standing
        if let best = BarBilliardsBest.best() { standing = .score(best) } else { standing = .none }
        return Scoreboard.Side(name: String(localized: "Best", comment: "Scoreboard: the best score kept on this device, beside your score in bar billiards played alone."),
                               standing: standing)
    }

    /// The caption under the strip: five-pin's target, or nine-ball's ball to hit first.
    private var target: String? {
        if let five = match.rules as? FivePinRules { return TableGameWords.target(five.targetScore) }
        if state.kind == .nineBall, let low = state.ballsLeft.min() { return MatchWords.hitFirst(low) }
        return nil
    }
}

// MARK: Feedback, shared

/// What a match says and plays as it moves on, whichever view shows it: each phase change is announced to VoiceOver
/// (MatchCard.announce) and closes the End-this-game confirmation once the game moves past aiming; bar billiards' clock
/// running out is said aloud and felt. Hosted by MatchCard (every layout but the upright phone) and, on the upright
/// phone, by PlayTableLayer's always-present background (the phone's blurbs come and go, so they cannot hold it).
/// `onPhase` runs first, for the host's own view state.
struct MatchFeedback: ViewModifier {
    let match: MatchMode
    var onPhase: (MatchMode.Phase) -> Void = { _ in }

    func body(content: Content) -> some View {
        content
            .onChange(of: match.phase) { _, phase in
                onPhase(phase)
                if phase != .aiming { match.confirmingEnd = false }
                MatchCard.announce(phase, match)
            }
            // Bar billiards: the moment the clock runs out, said aloud and felt (the banner shows the bar from then).
            .onChange(of: match.timeIsUp) { _, up in
                if up { ShotNarration.announce(TableGameWords.timeUpNow) }
            }
            .sensoryFeedback(trigger: match.timeIsUp) { _, up in up && GameSettings.hapticsOn ? .warning : nil }
    }
}

// MARK: One row of buttons

/// One row of buttons, right-aligned; wrapped onto more rows when they do not fit; a column at the accessibility text
/// sizes, where even a wrapped row would cut its labels off. The match card moved onto the kit's KitButtonRow (UI
/// rethink package 5); this stays for the cards outside the mode frame that still use it (ClipViews, WhatIfViews,
/// FreePlayViews, EveryWorldViews), until their own packages move them.
struct CardButtonRow<Content: View>: View {
    @ViewBuilder let content: Content
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .trailing, spacing: Theme.Space.xs) { content }
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Theme.Space.xs) { Spacer(minLength: 0); content }
                    WrappingRow { content }.frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .controlSize(.regular)
    }
}

// MARK: The turn banner

/// Who shoots, the game, and where each player stands, under the scoreboard.
struct TurnBanner: View {
    let match: MatchMode
    @Binding var editingNames: Bool
    // The More menu's End match sets match.confirmingEnd; the card then asks to confirm.
    /// While a shot plays: only the first line, no More menu.
    var compact = false
    /// Aiming with the Lens on, on an upright phone (0.7.6, #35): the first line with its More menu, and the names
    /// editor while it is open; the player rows, the table games' lines and the score wait until the Lens goes off.
    var slim = false
    /// The scoreboard strip is above (the match card): the standings leave out what it already shows.
    var besideScoreboard = false
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize

    private var state: MatchState { match.state }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            header
            if !compact {
                if editingNames { PlayerNamesEditor(match: match) }
            }
            if !compact && !slim { MatchStandings(match: match, besideScoreboard: besideScoreboard) }
        }
    }

    /// Who shoots (heading, paper) and the game's name (label, paper2), with the More menu on the right: side by side,
    /// or stacked at the accessibility text sizes. The who-shoots line wraps as far as it needs (item 43); it is never
    /// cut to two lines. Only a pool rack is a break: the other tables' first shot is plain "to shoot". The person's
    /// turn reads "Your shot" / "Your break".
    @ViewBuilder
    private var header: some View {
        let who = Text(MatchWords.toShoot(MatchWords.name(state.turn, in: match.playerNames),
                                          isBreak: state.isBreak && !state.kind.isTableGame,
                                          isYou: state.turn == match.you))
            .font(Theme.heading)
            .foregroundStyle(palette.paper)
            .fixedSize(horizontal: false, vertical: true)
        let game = Text(MatchWords.title(state.kind)).font(Theme.label).foregroundStyle(palette.paper2)
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
                    who
                    Spacer(minLength: 0)
                    if !compact { moreMenu }
                }
                game
            }
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isHeader)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xs) {
                who
                Spacer(minLength: 0)
                game
                if !compact { moreMenu }
            }
            .accessibilityAddTraits(.isHeader)
        }
    }

    /// The seats the names editor offers: the people's, never the computer's.
    private var peopleCount: Int { state.players.filter { !$0.isComputer }.count }

    /// Your name (or, in an old game between people, Player names) and End match, in the kit's worded More menu so
    /// the banner stays one line on a phone. With nobody to name the menu holds End match alone.
    private var moreMenu: some View {
        var items: [KitAction] = []
        if peopleCount > 0 {
            items.append(KitAction(namesItemTitle, systemImage: editingNames ? "checkmark" : "pencil") {
                editingNames.toggle()
            })
        }
        items.append(KitAction(String(localized: "End match"), systemImage: "xmark.circle", role: .destructive) {
            match.confirmingEnd = true
        })
        return MoreMenuButton(items)
            .accessibilityLabel(String(localized: "Match options"))
            .accessibilityHint(moreMenuHint)
    }

    /// The names item: "Your name" for the one person (against the computer, or bar billiards alone), "Player
    /// names" in an old game between people; "Done" or "Done editing names" while the field is open.
    private var namesItemTitle: String {
        if peopleCount == 1 { return editingNames ? String(localized: "Done") : String(localized: "Your name") }
        return editingNames ? String(localized: "Done editing names") : String(localized: "Player names")
    }

    private var moreMenuHint: String {
        switch peopleCount {
        case 0: return String(localized: "End the match")
        case 1: return String(localized: "Your name, or end the match")
        default: return String(localized: "Player names, or end the match")
        }
    }
}

/// Where each player stands, under the turn banner's first line, and on the upright phone in the match's status blurb
/// (MatchPhoneBlurbs.swift): nine-ball's ball to hit first and who is on two fouls, eight-ball's player rows (name,
/// group, balls left as icons), the table games' lines (TableGameLines) and the running score. Beside the match card's
/// scoreboard (besideScoreboard) it leaves out what the strip already shows: the ball to hit first, the groups and the
/// running score; the balls left stay, as icons.
struct MatchStandings: View {
    let match: MatchMode
    var besideScoreboard = false
    @Environment(\.palette) private var palette

    private var state: MatchState { match.state }
    /// The balls of the table this game is played on, for the icons.
    private var ballSet: TableBallSet { TableBallSet.for(table: match.table) }

    var body: some View {
        // Nine-ball, and any game without calls that is played in order: the lowest ball is hit first.
        if state.kind == .nineBall, let low = state.ballsLeft.min() {
            if !besideScoreboard {
                HStack(spacing: Theme.Space.xs) {
                    BallIcon(ball: low, set: ballSet)
                    Text(MatchWords.hitFirst(low)).font(Theme.body).foregroundStyle(palette.paper)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
            // Whoever is one foul from losing the game, as a quiet line under it.
            ForEach(onTwoFouls, id: \.self) { seat in
                Text(MatchWords.onTwoFouls(MatchWords.name(seat, in: match.playerNames), isYou: seat == match.you))
                    .font(Theme.label)
                    .foregroundStyle(palette.paper2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        if state.kind == .eightBall {
            ForEach(state.players, id: \.id) { p in playerRow(p) }
        }
        // The other tables: which ball to strike and what is left (TableGameLines below).
        if state.kind.isTableGame { TableGameLines(match: match, besideScoreboard: besideScoreboard) }
        if match.rules.keepsRunningScore && !besideScoreboard { ScoreRow(match: match) }
    }

    /// Nine-ball: the seats one foul from losing (NineBallRules.foulsToLose), in seat order.
    private var onTwoFouls: [PlayerID] {
        state.players.map(\.id).filter { p in
            state.consecutiveFouls.indices.contains(p.index)
                && state.consecutiveFouls[p.index] >= NineBallRules.foulsToLose - 1
        }
    }

    /// One player's line in eight-ball: a dot on whoever is shooting, the name ("You" for the person), the group and
    /// the balls left. On one line when the whole of it fits; otherwise (a long name or group in a longer language, a
    /// larger text size) stacked: the name, the group under it, both wrapping, and the ball icons on a line of their
    /// own, so nothing is ever cut to a few letters (0.7.6, #37). Beside the scoreboard the dot and the group are the
    /// strip's, so the line is the name and the ball icons.
    private func playerRow(_ p: Player) -> some View {
        let group = state.group(of: p.id)
        let left = state.ballsRemaining(for: p.id)
        let groupText = besideScoreboard ? ""
            : MatchWords.groupLine(group, left: left.count, tableOpen: state.tableOpen)
        let name = MatchWords.displayName(p.id, in: match.playerNames, you: match.you)
        // Spoken as one line: the name, the group and the balls left by number (the icons are pictures only).
        let spoken = [name, groupText, left.isEmpty ? "" : MatchWords.balls(left)]
            .filter { !$0.isEmpty }.joined(separator: ". ")
        let dot = Circle().fill(p.id == state.turn && !besideScoreboard ? palette.accent : Color.clear)
            .frame(width: Theme.Space.xs, height: Theme.Space.xs)
            .accessibilityHidden(true)
        let icons = HStack(spacing: Theme.Space.xxs) {
            ForEach(left, id: \.self) { BallIcon(ball: $0, set: ballSet) }
        }
        .accessibilityHidden(true)
        return ViewThatFits(in: .horizontal) {
            // The texts at their full width (fixedSize), so ViewThatFits sees when the line is too long instead of
            // the texts quietly truncating.
            HStack(spacing: Theme.Space.xs) {
                dot
                Text(name).font(Theme.label).foregroundStyle(palette.paper).lineLimit(1).fixedSize()
                if !groupText.isEmpty {
                    Text(groupText).font(Theme.label).foregroundStyle(palette.paper2).lineLimit(1).fixedSize()
                }
                Spacer(minLength: 0)
                icons
            }
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                HStack(spacing: Theme.Space.xs) {
                    dot
                    Text(name).font(Theme.label).foregroundStyle(palette.paper)
                        .fixedSize(horizontal: false, vertical: true)
                }
                // Indented past the dot, under the name.
                if !groupText.isEmpty {
                    Text(groupText).font(Theme.label).foregroundStyle(palette.paper2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, Theme.Space.md)
                }
                if !left.isEmpty { icons.padding(.leading, Theme.Space.md) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }
}

/// The turn banner's lines for the three table games, under the shooter's name.
private struct TableGameLines: View {
    let match: MatchMode
    /// The scoreboard above shows five-pin's target and each bumper-pool side's balls left in words.
    var besideScoreboard = false
    @Environment(\.palette) private var palette

    private var state: MatchState { match.state }
    private var ballSet: TableBallSet { TableBallSet.for(table: match.table) }

    var body: some View {
        if let bumper = match.rules as? BumperPoolRules {
            let seat = state.turn.index
            let ball = match.cueBallIndex
            let marked = BumperPoolRules.sides.indices.contains(seat) && BumperPoolRules.sides[seat].first == ball
            HStack(spacing: Theme.Space.xs) {
                BallIcon(ball: ball, set: ballSet)
                // On the computer's turn the line says what it strikes; on the person's it says what to strike.
                line(TableGameWords.bumperStrike(ball, marked: marked, computer: computerName))
            }
            .accessibilityElement(children: .combine)
            // Each side's balls still to sink, as that side's own balls (white or red, the marked one spotted), a dot
            // on the side shooting (the scoreboard's dot, when it is above).
            ForEach(state.players, id: \.id) { p in
                let name = MatchWords.displayName(p.id, in: match.playerNames, you: match.you)
                let balls = bumper.ballsLeft(for: p.id, in: state)
                let left = TableGameWords.ballsToSink(balls.count)
                HStack(spacing: Theme.Space.xs) {
                    Circle().fill(p.id == state.turn && !besideScoreboard ? palette.accent : Color.clear)
                        .frame(width: Theme.Space.xs, height: Theme.Space.xs)
                        .accessibilityHidden(true)
                    Text(name).font(Theme.label).foregroundStyle(palette.paper).lineLimit(1)
                    Spacer(minLength: 0)
                    HStack(spacing: Theme.Space.xxs) {
                        ForEach(balls, id: \.self) { BallIcon(ball: $0, set: ballSet) }
                    }
                    .accessibilityHidden(true)
                    if !besideScoreboard {
                        Text(left).font(Theme.label).foregroundStyle(palette.paper2).lineLimit(1)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel([name, left].joined(separator: ". "))
            }
        } else if let five = match.rules as? FivePinRules {
            let seat = state.turn.index
            HStack(spacing: Theme.Space.xs) {
                // The ball struck, then the ball to hit first (the other player's), as they look on the table.
                if FivePinRules.playerBalls.indices.contains(seat) {
                    BallIcon(ball: FivePinRules.playerBalls[seat], set: ballSet)
                    Image(systemName: "arrow.right").font(Theme.caption).foregroundStyle(palette.paper2)
                        .accessibilityHidden(true)
                    BallIcon(ball: five.targetBall(for: state.turn), set: ballSet)
                }
                line(TableGameWords.fivePinStrike(seat: seat, computer: computerName))
            }
            .accessibilityElement(children: .combine)
            if !besideScoreboard { line(TableGameWords.target(five.targetScore)) }
        } else if let bar = match.rules as? BarBilliardsRules {
            if let clock = state.clockRemaining {
                if clock > 0 {
                    Text(TableGameWords.timeLeft(seconds: MatchClock.shownSeconds(clock)))
                        .font(Theme.inlineFigure)
                        .foregroundStyle(palette.paper)
                        .accessibilityAddTraits(.updatesFrequently)
                } else {
                    // Only the whites the game will still play: the one on the D and those in the tray. Whites resting
                    // on the bed are not played again once the bar is down (item 20).
                    let whites = bar.whitesLeftToPlay(in: state, layout: match.model.layout)
                    Text(TableGameWords.barDown(whitesLeft: whites))
                        .font(Theme.label)
                        .foregroundStyle(palette.paper2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            // The break in progress only once it has points: "This break: 0" before every first shot says nothing.
            if let points = state.breakPoints, points > 0 { line(TableGameWords.breakSoFar(points)) }
            // Alone, the best score is the scoreboard's other side when it is above.
            if state.players.count == 1 && !besideScoreboard { line(TableGameWords.best(BarBilliardsBest.best())) }
        }
    }

    /// The computer's name while it is the computer's turn (the banner then describes its stroke), nil on the
    /// person's turn.
    private var computerName: String? {
        match.isComputer(state.turn) ? MatchWords.name(state.turn, in: match.playerNames) : nil
    }

    private func line(_ text: String) -> some View {
        Text(text)
            .font(Theme.body)
            .foregroundStyle(palette.paper)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The running score, one name and number per player (games that keep a score: five-pin, bar billiards), on the
/// upright phone's status blurb; the match card shows the scoreboard strip instead. The figure is the control figure in
/// paper; whose turn it is is the cyan dot before the name.
private struct ScoreRow: View {
    let match: MatchMode
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: Theme.Space.md) {
            ForEach(match.state.players, id: \.id) { p in
                let score = match.state.scores.indices.contains(p.id.index) ? match.state.scores[p.id.index] : 0
                let name = MatchWords.displayName(p.id, in: match.playerNames, you: match.you)
                VStack(alignment: .leading, spacing: Theme.Space.figureToLabel) {
                    KitFigure(number: score.formatted(.number.locale(AppLocale.numbers)), unit: "", size: .control)
                    HStack(spacing: Theme.Space.xxs) {
                        Circle().fill(p.id == match.state.turn ? palette.accent : Color.clear)
                            .frame(width: Theme.Space.xs, height: Theme.Space.xs)
                        Text(name).font(Theme.caption).foregroundStyle(palette.paper2).lineLimit(1)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(localized: "\(name): \(score)"))
            }
            Spacer(minLength: 0)
        }
    }
}

/// Editable names, in the card itself (no sheet, so it works as part of the notebook panel on the open Duo). Only
/// the people's seats are listed: the computer's name says its level and is never changed. A seat still on its
/// default name shows an empty field with the placeholder ("Your name" for the one person), and an emptied field
/// returns the seat to its default, so the words call the person "you" again.
private struct PlayerNamesEditor: View {
    let match: MatchMode

    private var people: [Player] { match.state.players.filter { !$0.isComputer } }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            ForEach(people, id: \.id) { p in
                let fallback = MatchWords.defaultName(p.id)
                let label = people.count == 1 ? String(localized: "Your name") : String(localized: "Name for \(fallback)")
                TextField(people.count == 1 ? String(localized: "Your name") : fallback, text: Binding(
                    get: {
                        guard match.playerNames.indices.contains(p.id.index) else { return "" }
                        let stored = match.playerNames[p.id.index]
                        return MatchWords.isDefaultName(stored, seat: p.id) ? "" : stored
                    },
                    set: { match.setPlayerName($0, for: p.id) }))
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .accessibilityLabel(label)
            }
        }
    }
}

// MARK: Ball icons

/// A small flat picture of a ball as the table draws it (TableBallSet): a pool ball (a solid disc, or an ivory disc
/// with a coloured band for a stripe, with the number on a light spot; the cue ball plain ivory), a plain coloured
/// ball, or a coloured ball with a spot of another colour (bumper pool's marked balls). The colours come from
/// BallTextures through ModeBallColour, the same palette the 3D balls use; the ivory is the cue ball's own, the number
/// and the hairline the ground colour. Decorative: the rows that show these always say the balls in words for
/// VoiceOver.
struct BallIcon: View {
    let look: BallLook
    @Environment(\.palette) private var palette
    @ScaledMetric(relativeTo: .caption) private var size: CGFloat = 16

    /// A pool ball by number (eight-ball and nine-ball).
    init(number: Int) { look = .pool(number: number) }
    /// The ball in slot `ball` as the given table's set draws it.
    init(ball: Int, set: TableBallSet) { look = set.look(of: ball) }
    init(look: BallLook) { self.look = look }

    /// The cue ball's ivory, for a stripe's body and the number's spot.
    private var ivory: Color { ModeBallColour.colour(.pool(number: 0)) }

    var body: some View {
        ZStack {
            switch look {
            case .pool(let number):
                let colour = ModeBallColour.colour(look)
                Circle().fill(number > 8 ? ivory : colour)
                if number > 8 {
                    // The band: the middle half of the ball's height, as on the real ball.
                    Rectangle().fill(colour).frame(height: size * 0.5)
                }
                if number > 0 {
                    Circle().fill(ivory).frame(width: size * 0.58, height: size * 0.58)
                    // The number scales with the icon (itself scaled with the caption), so it is drawn at a share of
                    // the icon's size rather than a text style.
                    Text("\(number)")
                        .font(.system(size: size * 0.42, weight: .bold).monospacedDigit()) // design-lint: allow sized to the ball icon, which scales with the caption
                        .foregroundStyle(palette.ground)
                        .minimumScaleFactor(0.5)
                }
            case .plain:
                Circle().fill(ModeBallColour.colour(look))
                // A hairline so a white ball still reads on the panel.
                Circle().strokeBorder(palette.ground.opacity(0.25), lineWidth: Theme.Size.hairline)
            case .spotted(_, let spot):
                Circle().fill(ModeBallColour.colour(look))
                Circle().fill(ModeBallColour.colour(.plain(spot))).frame(width: size * 0.42, height: size * 0.42)
                Circle().strokeBorder(palette.ground.opacity(0.25), lineWidth: Theme.Size.hairline)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}
