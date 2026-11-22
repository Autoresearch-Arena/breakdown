// Author: Claude Opus 5.5 High
// Date: 21-November-2026
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
// PURPOSE: Everything the player sees of a match (eight-ball and nine-ball for two on one device or against the
//          computer; the other tables' games use the same card), as ONE glass card whose content follows
//          MatchMode.phase:
// Edited: Claude Opus 5.5 High, 21-November-2026 (access stream hooks, 0.7.0 items 44 and 47: announcements go through the one speaker,
//          ShotNarration.announce, the ruling itself is said once by the shot's narration, and Continue's arrow follows
//          the reading direction.)
// PURPOSE: Everything the player sees of a match (eight-ball and nine-ball for two on one device; the other tables'
//          games use the same card), as ONE glass card whose content follows MatchMode.phase:
//            aiming   - the turn banner: who shoots (or breaks), the game, each player's group with their balls left
//                       as small ball icons (eight-ball), the ball to hit first (nine-ball), running scores and the
//                       clock where the game keeps them; the last routine ruling as a line; editable player names
//                       and End match (the banner's More menu); a pending choice ("take the table or rack again");
//                       and the call control while the rules want a call (eight-ball after the break; never in
//                       nine-ball).
//            shooting - the banner, small, with the call, and "See the ruling".
//            ruling   - a routine ruling: its header and sentences, settling by themselves; otherwise the card: the
//                       ruling in plain words ("Foul: the cue ball hit the 11 first. Ball in hand for Sam."), then the
//                       choice, or Continue.
//            handOver - whose shot it is ("Sam to shoot.") and Ready, between two people on one device.
//            over     - who won and why, the running scores, Rematch and Menu.
//          Feedback (rules plan, package 6): the sound and haptic of a foul, a turn change and a win are played by
//          MatchMode through SoundBoard.play (only felt with Vibration on); this card speaks the ruling to VoiceOver as
//          it appears, routine or not.
//          Hosted by PlayCards (FreePlayViews.swift) next to the other mode cards, so it sits above the controls on a
//          phone, at the top of the side column on iPad and Mac, and in the notebook panel on the open Duo; it never
//          opens a sheet (the End match confirmation is inside the card), so on the Duo nothing covers the table.
//          Reads MatchMode (state, phase, rules, currentCall, lastRuling, lastRulingShow, settledRuling, the last
//          shot's facts, playerNames) and calls setCall, acknowledgeRuling, settleNow, answer, rematch,
//          setPlayerName; reads the model's match-shot calls (matchShotPlaying, seeRuling, offerLensReplayOfBreak,
//          watchBreakInLens, computerTurnStage, endMatch).
// SRP/DRY check: Pass - words are in MatchWords, OpponentWords and TableGameWords, the call in CallControl, the
//          cue-ball placement in FreePlayViews and PlayTableLayer, each table's ball looks in TableBallSet and their
//          colours in BallTextures; card styling is the shared glassCard and the button rows follow TrickShotCard's.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import SwiftUI

struct MatchCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var editingNames = false
    /// "Why that shot" is open (on the ruling card, or under the settled line in the banner).
    @State private var showingWhy = false
    /// "End match" was chosen and the card is asking to confirm.
    @State private var confirmingEnd = false

    var body: some View {
        if let match = model.match {
            VStack(alignment: .leading, spacing: 8) {
                content(match)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 22, padding: 12)
            .tint(palette.accent)
            .animation(reduceMotion ? nil : .snappy, value: match.phase)
            .onChange(of: match.phase) { _, phase in
                // The reasons belong to one shot: closed when the next shot starts, kept open while a routine ruling
                // settles into the banner (it was opened during that beat).
                if phase == .shooting { showingWhy = false }
                if phase != .aiming { confirmingEnd = false }
                announce(phase, match)
            }
            // Bar billiards: the moment the clock runs out, said aloud and felt (the banner shows the bar from then).
            .onChange(of: match.timeIsUp) { _, up in
                if up { ShotNarration.announce(TableGameWords.timeUpNow) }
            }
            .sensoryFeedback(trigger: match.timeIsUp) { _, up in up && GameSettings.hapticsOn ? .warning : nil }
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private func content(_ match: MatchMode) -> some View {
        switch match.phase {
        case .aiming:
            TurnBanner(match: match, editingNames: $editingNames, confirmingEnd: $confirmingEnd)
            if confirmingEnd {
                endMatchConfirmation
            } else {
                if let settled = match.settledRuling { settledSection(settled, match) }
                lensOffer
                if match.computerSeatToAct != nil {
                    // The computer's decision: its choice prompt (if any) and that it is thinking or lining up;
                    // nothing to tap.
                    if let choice = match.state.pendingChoice {
                        line(MatchWords.choicePrompt(choice, names: match.playerNames))
                    }
                    computerLine
                } else if let choice = match.state.pendingChoice {
                    choiceSection(choice, match)
                } else if match.mustCall {
                    MatchCallControl(model: model, match: match)
                }
            }
        case .shooting:
            TurnBanner(match: match, editingNames: .constant(false), confirmingEnd: .constant(false), compact: true)
            if let call = match.currentCall { line(MatchWords.callLine(call)) }
            if model.matchShotPlaying {
                // A paused or slowed replay never leaves the player waiting for the ruling (item 14).
                CardButtonRow {
                    Button { model.seeRuling() } label: {
                        Label(String(localized: "See the ruling"), systemImage: "forward.end.fill")
                            .font(.headline).lineLimit(1)
                            .frame(minHeight: CallMetrics.buttonHeight)
                    }
                    .buttonStyle(.glass)
                    .accessibilityHint(String(localized: "Skips to the end of the shot so the ruling comes at once"))
                }
            }
        case .ruling:
            if let r = match.lastRuling {
                if match.lastRulingShow == .banner {
                    routineRuling(r, match)
                } else {
                    rulingCard(r, match)
                }
            } else {
                // A ruling phase with nothing to show cannot be read; let the player move on.
                CardButtonRow { continueButton(match) }
            }
        case .handOver:
            handOver(match)
        case .over:
            result(match)
        }
    }

    // MARK: Ruling

    /// The full ruling card: it waits for Continue (or the choice).
    @ViewBuilder
    private func rulingCard(_ r: Ruling, _ match: MatchMode) -> some View {
        rulingHeader(r)
        ForEach(Array(rulingSentences(r, match).enumerated()), id: \.offset) { _, s in line(s) }
        if !match.lastPoints.isEmpty { pointsSection(match) }
        whyIfComputers(r, match)
        lensOffer
        // A choice the computer makes is made after Continue, on its turn; a person's is answered here.
        if let choice = match.state.pendingChoice, !match.isComputer(choice.chooser) {
            choiceSection(choice, match)
        } else {
            CardButtonRow { continueButton(match) }
        }
    }

    /// A routine ruling during its beat: the same words with no Continue button. It settles by itself after
    /// MatchMode.settleBeat; a tap on it (or Return) moves on at once.
    @ViewBuilder
    private func routineRuling(_ r: Ruling, _ match: MatchMode) -> some View {
        Button { match.settleNow() } label: {
            VStack(alignment: .leading, spacing: 6) {
                rulingHeader(r)
                ForEach(Array(rulingSentences(r, match).enumerated()), id: \.offset) { _, s in line(s) }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.defaultAction)
        .accessibilityHint(String(localized: "Moves on now. It also moves on by itself in a moment."))
        if !match.lastPoints.isEmpty { pointsSection(match) }
        whyIfComputers(r, match)
        lensOffer
    }

    /// The last routine ruling, settled under the turn banner until the next shot: its sentences as one quiet line
    /// (and the points of a bar-billiards or five-pin shot), with "Why that shot" when the computer played it.
    @ViewBuilder
    private func settledSection(_ r: Ruling, _ match: MatchMode) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: r.turnPasses ? "arrow.left.arrow.right" : "checkmark.circle")
                .foregroundStyle(palette.accent)
                .accessibilityHidden(true)
            Text(settledWords(r, match))
                .font(Theme.label)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        whyIfComputers(r, match)
    }

    /// The settled line's words: the ruling's sentences, then how the points came (five-pin, bar billiards).
    private func settledWords(_ r: Ruling, _ match: MatchMode) -> String {
        let points = TableGameWords.lines(match.lastPoints, kind: match.state.kind, names: match.playerNames)
        return (rulingSentences(r, match) + points).joined(separator: " ")
    }

    private func rulingHeader(_ r: Ruling) -> some View {
        HStack(spacing: 8) {
            Image(systemName: r.fouled ? "exclamationmark.triangle.fill"
                  : (r.turnPasses ? "arrow.left.arrow.right" : "checkmark.circle.fill"))
                .foregroundStyle(r.fouled ? palette.slide : palette.accent)
                .accessibilityHidden(true)
            Text(r.fouled ? String(localized: "Foul") : (r.turnPasses ? String(localized: "Turn over")
                                                                     : String(localized: "Keep shooting")))
                .font(Theme.heading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    /// The ruling's sentences, from what the recording showed when the shot was ruled (MatchMode keeps the balls that
    /// dropped and the first ball the striking ball touched, so a wrong-ball foul names the ball), then, when the
    /// stroke went through with no call made, the suggested call it was held to.
    private func rulingSentences(_ r: Ruling, _ match: MatchMode) -> [String] {
        var out = MatchWords.sentences(for: r, names: match.playerNames, pocketed: match.lastPocketed,
                                       firstBall: match.lastFirstBall, kind: match.state.kind)
        // Only for the shot itself, not for an answered choice that followed it.
        if match.lastCallWasSuggested, let call = match.lastShotCall, !r.reasons.contains(.choiceAnswered) {
            out.insert(MatchWords.suggestedCallUsed(call), at: 0)
        }
        return out
    }

    /// Five-pin and bar billiards: how the shot's points came, line by line, then everyone's score.
    @ViewBuilder
    private func pointsSection(_ match: MatchMode) -> some View {
        Text(String(localized: "How the points came"))
            .font(Theme.label)
            .foregroundStyle(palette.slide)
            .accessibilityAddTraits(.isHeader)
        ForEach(Array(TableGameWords.lines(match.lastPoints, kind: match.state.kind, names: match.playerNames).enumerated()),
                id: \.offset) { _, s in line(s) }
        if match.rules.keepsRunningScore { ScoreRow(match: match) }
    }

    /// Everything a ruling says aloud: its sentences, then (five-pin, bar billiards) how the points came and the
    /// scores, so a player who cannot see the card hears the same as one who can.
    private func spokenRuling(_ r: Ruling, _ match: MatchMode) -> String {
        var parts = rulingSentences(r, match)
        parts += TableGameWords.lines(match.lastPoints, kind: match.state.kind, names: match.playerNames)
        if match.rules.keepsRunningScore { parts.append(TableGameWords.scores(match.state.scores, names: match.playerNames)) }
        return parts.joined(separator: " ")
    }

    // MARK: The computer

    /// "Thinking..." with a small spinner while the computer works out its stroke (or its answer), then "Lining up
    /// its shot..." while the model swings its aim and draws its cue back.
    private var computerLine: some View {
        let lining = model.computerTurnStage == .staging || model.computerTurnStage == .striking
        return HStack(spacing: 8) {
            ProgressView().controlSize(.small).accessibilityHidden(true)
            Text(lining ? OpponentWords.liningUp : OpponentWords.thinking)
                .font(Theme.body).foregroundStyle(palette.paper.opacity(0.9))
        }
        .accessibilityElement(children: .combine)
    }

    /// "Why that shot" for a ruling on the computer's own stroke (not on an answered choice).
    @ViewBuilder
    private func whyIfComputers(_ r: Ruling, _ match: MatchMode) -> some View {
        if let shot = match.opponent?.lastShot, shot.seat == r.shooter, match.isComputer(r.shooter),
           !r.reasons.contains(.choiceAnswered) {
            whySection(shot)
        }
    }

    /// "Why that shot": a button that opens the computer's reasons, in plain words, inside the card.
    @ViewBuilder
    private func whySection(_ shot: OpponentShot) -> some View {
        Button {
            showingWhy.toggle()
        } label: {
            Label(OpponentWords.whyThatShot, systemImage: showingWhy ? "chevron.up" : "questionmark.bubble")
                .font(.headline).lineLimit(1)
                .frame(minHeight: CallMetrics.buttonHeight)
        }
        .buttonStyle(.glass)
        .accessibilityValue(showingWhy ? String(localized: "Open") : String(localized: "Closed"))
        if showingWhy {
            ForEach(Array(OpponentWords.why(shot).enumerated()), id: \.offset) { _, s in line(s) }
        }
    }

    /// After a match break, a replay of it under the Lens for anyone who wants it (the break itself played at real
    /// speed in the ordinary view; the model says when the offer stands).
    @ViewBuilder
    private var lensOffer: some View {
        if model.offerLensReplayOfBreak {
            CardButtonRow {
                Button { model.watchBreakInLens() } label: {
                    Label(String(localized: "Watch it in the Lens"), systemImage: "eye")
                        .font(.headline).lineLimit(1)
                        .frame(minHeight: CallMetrics.buttonHeight)
                }
                .buttonStyle(.glass)
                .accessibilityHint(String(localized: "Replays the break slowly with the physics drawn on the table"))
            }
        }
    }

    private func continueButton(_ match: MatchMode) -> some View {
        Button { match.acknowledgeRuling() } label: {
            Label("Continue", systemImage: "arrow.forward").font(.headline).lineLimit(1)
                .frame(minHeight: CallMetrics.buttonHeight)
        }
        .buttonStyle(.glassProminent)
        .foregroundStyle(palette.ground)
        .keyboardShortcut(.defaultAction)
    }

    @ViewBuilder
    private func choiceSection(_ c: PendingChoice, _ match: MatchMode) -> some View {
        line(MatchWords.choicePrompt(c, names: match.playerNames))
        CardButtonRow {
            ForEach(Array(c.choice.answers.enumerated()), id: \.offset) { i, a in
                let b = Button { match.answer(a) } label: {
                    Text(MatchWords.answer(a)).font(.headline).lineLimit(1).frame(minHeight: CallMetrics.buttonHeight)
                }
                // The first answer is the usual one (take the table, spot the 8), so it is the prominent button.
                if i == 0 { b.buttonStyle(.glassProminent).foregroundStyle(palette.ground) } else { b.buttonStyle(.glass) }
            }
        }
    }

    // MARK: End match

    /// Asked inside the card (no alert or sheet, so nothing covers the table): ending throws the game away and, like
    /// any game not finished by the rules, it is not counted in the record (MatchRecord).
    @ViewBuilder
    private var endMatchConfirmation: some View {
        line(String(localized: "End this game? It won't be saved, and it doesn't count in your record."))
        CardButtonRow {
            Button { confirmingEnd = false } label: {
                Text(String(localized: "Keep playing")).font(.headline).lineLimit(1)
                    .frame(minHeight: CallMetrics.buttonHeight)
            }
            .buttonStyle(.glass)
            .keyboardShortcut(.cancelAction)
            Button(role: .destructive) {
                confirmingEnd = false
                model.endMatch()
                if !model.menuOpen { model.openMenu() }
            } label: {
                Label(String(localized: "End match"), systemImage: "xmark.circle").font(.headline).lineLimit(1)
                    .frame(minHeight: CallMetrics.buttonHeight)
            }
            .buttonStyle(.glassProminent)
            .accessibilityHint(String(localized: "Ends this game and goes back to the menu"))
        }
    }

    // MARK: Hand-over

    @ViewBuilder
    private func handOver(_ match: MatchMode) -> some View {
        let next = MatchWords.name(match.state.turn, in: match.playerNames)
        HStack(spacing: 8) {
            Image(systemName: "hand.point.right.fill").foregroundStyle(palette.accent).accessibilityHidden(true)
            Text(MatchWords.handOver(to: next)).font(Theme.heading).fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        if let hand = MatchWords.ballInHand(match.state.ballInHand, for: next) { line(hand) }
        if let g = match.state.group(of: match.state.turn) {
            line(MatchWords.groupLine(g, left: match.state.ballsRemaining(for: match.state.turn).count, tableOpen: false))
        }
        CardButtonRow {
            Button { match.acknowledgeRuling() } label: {
                Label(String(localized: "Ready"), systemImage: "checkmark").font(.headline).lineLimit(1)
                    .frame(minHeight: CallMetrics.buttonHeight)
            }
            .buttonStyle(.glassProminent)
            .foregroundStyle(palette.ground)
            .keyboardShortcut(.defaultAction)
            .accessibilityHint(String(localized: "Shows the table for the next player's shot"))
        }
    }

    // MARK: Result

    @ViewBuilder
    private func result(_ match: MatchMode) -> some View {
        if let r = match.state.result {
            HStack(spacing: 8) {
                Image(systemName: r.winner == nil ? "flag.checkered" : "trophy.fill")
                    .foregroundStyle(palette.pocket).accessibilityHidden(true)
                Text(MatchWords.resultTitle(r, names: match.playerNames)).font(Theme.heading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            let why = MatchWords.endReason(r, shooter: match.lastRuling?.shooter, names: match.playerNames)
            if !why.isEmpty { line(why) }
            if match.rules.keepsRunningScore { ScoreRow(match: match) }
            if let best = match.bestOutcome { line(TableGameWords.bestOutcome(best)) }
        }
        CardButtonRow {
            Button {
                model.endMatch()
                if !model.menuOpen { model.openMenu() }
            } label: {
                Label("Menu", systemImage: "chevron.backward").font(.headline).lineLimit(1)
                    .frame(minHeight: CallMetrics.buttonHeight)
            }
            .buttonStyle(.glass)
            Button { match.rematch() } label: {
                Label(String(localized: "Rematch"), systemImage: "arrow.counterclockwise").font(.headline).lineLimit(1)
                    .frame(minHeight: CallMetrics.buttonHeight)
            }
            .buttonStyle(.glassProminent)
            .foregroundStyle(palette.ground)
            .keyboardShortcut(.defaultAction)
            .accessibilityHint(String(localized: "Racks for a new game between the same players"))
        }
    }

    // MARK: Feedback

    /// VoiceOver hears each ruling (a routine one too, as it appears), the hand-over and the result as they arrive,
    /// without hunting for the card.
    private func announce(_ phase: MatchMode.Phase, _ match: MatchMode) {
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
            var parts = [MatchWords.resultTitle(r, names: match.playerNames)]
            if match.rules.keepsRunningScore {
                parts.append(TableGameWords.scores(match.state.scores, names: match.playerNames))
            }
            if let best = match.bestOutcome { parts.append(TableGameWords.bestOutcome(best)) }
            text = parts.joined(separator: " ")
        case .aiming, .shooting:
            return
        }
        ShotNarration.announce(text)
    }

    // MARK: Pieces (as TrickShotCard's)

    private func line(_ text: String) -> some View {
        Text(text)
            .font(Theme.body)
            .foregroundStyle(palette.paper.opacity(0.9))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: One row of buttons

/// One row of buttons, right-aligned; wrapped onto more rows when they do not fit; a column at the accessibility text
/// sizes, where even a wrapped row would cut its labels off. Shared by the match card and its call control (item 43).
struct CardButtonRow<Content: View>: View {
    @ViewBuilder let content: Content
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .trailing, spacing: 8) { content }.frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { Spacer(minLength: 0); content }
                    WrappingRow { content }.frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .controlSize(.regular)
    }
}

// MARK: The turn banner

/// Who shoots, the game, and where each player stands.
struct TurnBanner: View {
    let match: MatchMode
    @Binding var editingNames: Bool
    /// Set by the More menu's End match: the card then asks to confirm.
    @Binding var confirmingEnd: Bool
    /// While a shot plays: only the first line.
    var compact = false
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize

    private var state: MatchState { match.state }
    /// The balls of the table this game is played on, for the icons.
    private var ballSet: TableBallSet { TableBallSet.for(table: match.table) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            if !compact {
                if editingNames { PlayerNamesEditor(match: match) }
                // Nine-ball, and any game without calls that is played in order: the lowest ball is hit first.
                if state.kind == .nineBall, let low = state.ballsLeft.min() {
                    HStack(spacing: 6) {
                        BallIcon(ball: low, set: ballSet)
                        Text(MatchWords.hitFirst(low)).font(Theme.body).foregroundStyle(palette.paper.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                }
                if state.kind == .eightBall {
                    ForEach(state.players, id: \.id) { p in playerRow(p) }
                }
                // The other tables: which ball to strike and what is left (TableGameLines below).
                if state.kind.isTableGame { TableGameLines(match: match) }
                if match.rules.keepsRunningScore { ScoreRow(match: match) }
            }
        }
    }

    /// Who shoots and the game's name: side by side, or stacked at the accessibility text sizes. The who-shoots line
    /// wraps as far as it needs (item 43); it is never cut to two lines.
    @ViewBuilder
    private var header: some View {
        let who = Text(MatchWords.toShoot(MatchWords.name(state.turn, in: match.playerNames), isBreak: state.isBreak))
            .font(Theme.heading)
            .fixedSize(horizontal: false, vertical: true)
        let game = Text(MatchWords.title(state.kind)).font(Theme.label).foregroundStyle(palette.slide)
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    who
                    Spacer(minLength: 0)
                    if !compact { moreMenu }
                }
                game
            }
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isHeader)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                who
                Spacer(minLength: 0)
                game
                if !compact { moreMenu }
            }
            .accessibilityAddTraits(.isHeader)
        }
    }

    /// Player names and End match, in one small menu so the banner stays one line on a phone.
    private var moreMenu: some View {
        Menu {
            Button {
                editingNames.toggle()
            } label: {
                Label(editingNames ? String(localized: "Done editing names") : String(localized: "Player names"),
                      systemImage: editingNames ? "checkmark" : "pencil")
            }
            Button(role: .destructive) {
                confirmingEnd = true
            } label: {
                Label(String(localized: "End match"), systemImage: "xmark.circle")
            }
        } label: {
            Label(String(localized: "More"), systemImage: "ellipsis")
                .labelStyle(.iconOnly)
                .frame(minWidth: 30, minHeight: CallMetrics.buttonHeight)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(String(localized: "Match options"))
        .accessibilityHint(String(localized: "Player names, or end the match"))
    }

    /// One player's line in eight-ball: a dot on whoever is shooting, the name, the group and the balls left.
    private func playerRow(_ p: Player) -> some View {
        let group = state.group(of: p.id)
        let left = state.ballsRemaining(for: p.id)
        let groupText = MatchWords.groupLine(group, left: left.count, tableOpen: state.tableOpen)
        let name = MatchWords.name(p.id, in: match.playerNames)
        // Spoken as one line: the name, the group and the balls left by number (the icons are pictures only).
        let spoken = [name, groupText, left.isEmpty ? "" : MatchWords.balls(left)]
            .filter { !$0.isEmpty }.joined(separator: ". ")
        return HStack(spacing: 6) {
            Circle().fill(p.id == state.turn ? palette.accent : Color.clear)
                .frame(width: 6, height: 6)
                .accessibilityHidden(true)
            Text(name).font(Theme.label).lineLimit(1)
            if !groupText.isEmpty {
                Text(groupText).font(Theme.label).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 0)
            HStack(spacing: 2) {
                ForEach(left, id: \.self) { BallIcon(ball: $0, set: ballSet) }
            }
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }
}

/// The turn banner's lines for the three table games, under the shooter's name.
private struct TableGameLines: View {
    let match: MatchMode
    @Environment(\.palette) private var palette

    private var state: MatchState { match.state }
    private var ballSet: TableBallSet { TableBallSet.for(table: match.table) }

    var body: some View {
        if let bumper = match.rules as? BumperPoolRules {
            let seat = state.turn.index
            let ball = match.cueBallIndex
            let marked = BumperPoolRules.sides.indices.contains(seat) && BumperPoolRules.sides[seat].first == ball
            HStack(spacing: 6) {
                BallIcon(ball: ball, set: ballSet)
                line(TableGameWords.bumperStrike(ball, marked: marked))
            }
            .accessibilityElement(children: .combine)
            // Each side's balls still to sink, as that side's own balls (white or red, the marked one spotted), a dot
            // on the side shooting.
            ForEach(state.players, id: \.id) { p in
                let name = MatchWords.name(p.id, in: match.playerNames)
                let balls = bumper.ballsLeft(for: p.id, in: state)
                let left = TableGameWords.ballsToSink(balls.count)
                HStack(spacing: 6) {
                    Circle().fill(p.id == state.turn ? palette.accent : Color.clear)
                        .frame(width: 6, height: 6)
                        .accessibilityHidden(true)
                    Text(name).font(Theme.label).lineLimit(1)
                    Spacer(minLength: 0)
                    HStack(spacing: 2) {
                        ForEach(balls, id: \.self) { BallIcon(ball: $0, set: ballSet) }
                    }
                    .accessibilityHidden(true)
                    Text(left).font(Theme.label).foregroundStyle(.secondary).lineLimit(1)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel([name, left].joined(separator: ". "))
            }
        } else if let five = match.rules as? FivePinRules {
            let seat = state.turn.index
            HStack(spacing: 6) {
                // The ball struck, then the ball to hit first (the other player's), as they look on the table.
                if FivePinRules.playerBalls.indices.contains(seat) {
                    BallIcon(ball: FivePinRules.playerBalls[seat], set: ballSet)
                    Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    BallIcon(ball: five.targetBall(for: state.turn), set: ballSet)
                }
                line(TableGameWords.fivePinStrike(seat: seat))
            }
            .accessibilityElement(children: .combine)
            line(TableGameWords.target(five.targetScore))
        } else if let bar = match.rules as? BarBilliardsRules {
            if let clock = state.clockRemaining {
                if clock > 0 {
                    Text(TableGameWords.timeLeft(seconds: MatchClock.shownSeconds(clock)))
                        .font(Theme.number)
                        .foregroundStyle(palette.paper.opacity(0.9))
                        .accessibilityAddTraits(.updatesFrequently)
                } else {
                    // Only the whites the game will still play: the one on the D and those in the tray. Whites resting
                    // on the bed are not played again once the bar is down (item 20).
                    let whites = bar.whitesLeftToPlay(in: state, layout: match.model.layout)
                    Text(TableGameWords.barDown(whitesLeft: whites))
                        .font(Theme.label)
                        .foregroundStyle(palette.slide)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if let points = state.breakPoints { line(TableGameWords.breakSoFar(points)) }
            if state.players.count == 1 { line(TableGameWords.best(BarBilliardsBest.best())) }
        }
    }

    private func line(_ text: String) -> some View {
        Text(text)
            .font(Theme.body)
            .foregroundStyle(palette.paper.opacity(0.9))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The running score, one name and number per player (games that keep a score: five-pin, bar billiards).
private struct ScoreRow: View {
    let match: MatchMode
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 14) {
            ForEach(match.state.players, id: \.id) { p in
                let score = match.state.scores.indices.contains(p.id.index) ? match.state.scores[p.id.index] : 0
                VStack(spacing: 0) {
                    Text("\(score)").font(.title3.monospacedDigit().weight(.bold))
                        .foregroundStyle(p.id == match.state.turn ? palette.accent : palette.paper)
                    Text(MatchWords.name(p.id, in: match.playerNames)).font(.caption2).foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(localized: "\(MatchWords.name(p.id, in: match.playerNames)): \(score)"))
            }
            Spacer(minLength: 0)
        }
    }
}

/// Editable names, in the card itself (no sheet, so it works as part of the notebook panel on the open Duo). An
/// emptied field shows the default name again ("Player 1"), so nobody is ever nameless.
private struct PlayerNamesEditor: View {
    let match: MatchMode

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(match.state.players, id: \.id) { p in
                let fallback = MatchWords.defaultName(p.id)
                TextField(fallback, text: Binding(
                    get: { match.playerNames.indices.contains(p.id.index) ? match.playerNames[p.id.index] : "" },
                    set: { match.setPlayerName($0, for: p.id) }))
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .accessibilityLabel(String(localized: "Name for \(fallback)"))
            }
        }
    }
}

// MARK: Ball icons

/// A small flat picture of a ball as the table draws it (TableBallSet): a pool ball (a solid disc, or an ivory disc
/// with a coloured band for a stripe, with the number on a light spot; the cue ball plain ivory), a plain coloured
/// ball, or a coloured ball with a spot of another colour (bumper pool's marked balls). The colours come from
/// BallTextures, the same palette the 3D balls use. Decorative: the rows that show these always say the balls in
/// words for VoiceOver.
struct BallIcon: View {
    let look: BallLook
    @ScaledMetric(relativeTo: .caption) private var size: CGFloat = 16

    /// A pool ball by number (eight-ball and nine-ball).
    init(number: Int) { look = .pool(number: number) }
    /// The ball in slot `ball` as the given table's set draws it.
    init(ball: Int, set: TableBallSet) { look = set.look(of: ball) }
    init(look: BallLook) { self.look = look }

    private static let ivory = Color(red: 0.96, green: 0.94, blue: 0.88)

    private static func colour(_ look: BallLook) -> Color {
        let c = BallTextures.swatch(look)
        return Color(red: c.0, green: c.1, blue: c.2)
    }

    var body: some View {
        ZStack {
            switch look {
            case .pool(let number):
                let colour = Self.colour(look)
                Circle().fill(number > 8 ? Self.ivory : colour)
                if number > 8 {
                    // The band: the middle half of the ball's height, as on the real ball.
                    Rectangle().fill(colour).frame(height: size * 0.5)
                }
                if number > 0 {
                    Circle().fill(Self.ivory).frame(width: size * 0.58, height: size * 0.58)
                    Text("\(number)")
                        .font(.system(size: size * 0.42, weight: .bold).monospacedDigit())
                        .foregroundStyle(Color.black)
                        .minimumScaleFactor(0.5)
                }
            case .plain:
                Circle().fill(Self.colour(look))
                // A hairline so a white ball still reads on the light glass of the card.
                Circle().strokeBorder(Color.black.opacity(0.25), lineWidth: 0.5)
            case .spotted(_, let spot):
                Circle().fill(Self.colour(look))
                Circle().fill(Self.colour(.plain(spot))).frame(width: size * 0.42, height: size * 0.42)
                Circle().strokeBorder(Color.black.opacity(0.25), lineWidth: 0.5)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}
