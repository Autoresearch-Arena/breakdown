// Author: Claude Opus 5.5 Medium
// Date: 22-November-2026
// PURPOSE: A match on the upright phone (plans/22-Nov-2026-phone-ui-plan.md, Part 3 "Every phone state": "Match: the
//          title shows whose turn and the score; a ruling is a docked blurb with Continue as the primary action; a
//          ruling that is a choice keeps both its buttons in the blurb and hides the primary action"). Everything the
//          match card (MatchViews.swift) shows on the other layouts, as small docked blurbs instead of one glass card:
//            aiming   - one status blurb: the computer thinking or lining up (and its choice prompt), the settled
//                       routine ruling (folded to two lines, a tap opens the standings under it), and the standings
//                       (MatchStandings: the ball to hit first, eight-ball's groups and balls left, the table games'
//                       lines, the score); a person's choice ("take the table or rack again") with its two answers;
//                       the End-this-game confirmation with Keep playing and End match.
//            shooting - the call, while there is one.
//            ruling   - the ruling's title and sentences (the points and scores for five-pin and bar billiards, the
//                       remarkable shot named), with "Watch it in the Lens" and "Why that shot" as its small buttons;
//                       Continue is the strip's primary action. A ruling that is a choice carries its two answers
//                       instead, and the Lens offer then moves to a second one-line blurb of its own.
//            handOver - whose shot it is, and Ready as the primary action.
//            over     - who won and why, the scores, the record; Menu in the blurb, Rematch as the primary action.
//          Also PhoneTitle.match (the title row's words) and PhonePrimaryAction.match (the strip's white capsule). The
//          announcements and the clock's haptic are not here: the blurbs come and go, so MatchFeedback is hosted by
//          PlayTableLayer on the upright phone (FreePlayPhoneBlurbs.swift, PhonePlayFeedback).
//          The call itself (eight-ball after the break) is not here: the plan puts the call row in the aiming panel
//          (PhoneAimPanel, MatchCallControl).
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (numbers are written in the game's own language, AppLocale.numbers
//          in NumberStyle.swift: French and German get "6,7" even on a phone set to another region.)
// SRP/DRY check: Pass - every word comes from MatchWords, TableGameWords, OpponentWords, HighlightWords and the
//          MatchCard statics the card itself uses (rulingTitle, rulingSentences, settledWords, rematchHint,
//          recordLines, personWon); every action is the card's own model call (acknowledgeRuling, answer, rematch,
//          endMatch, watchShotInLens, seeRuling). Blurb and BlurbButton are the foundation's (App/Phone/Blurb.swift).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import SwiftUI

// MARK: Shared rules

/// The one test the blurbs and the primary action both use, so they can never disagree about a choice.
@MainActor
enum MatchPhone {
    /// The person's own pending choice while it is theirs to answer here: during aiming (once the computer is not the
    /// chooser and End match is not being confirmed), or on a ruling card (a routine ruling never carries one). Nil
    /// for the computer's choice, which it makes itself.
    static func personChoice(_ match: MatchMode) -> PendingChoice? {
        guard let c = match.state.pendingChoice, !match.isComputer(c.chooser) else { return nil }
        switch match.phase {
        case .aiming: return match.confirmingEnd ? nil : c
        case .ruling: return match.lastRuling != nil && match.lastRulingShow == .card ? c : nil
        case .shooting, .handOver, .over: return nil
        }
    }

    /// The remarkable shot on offer for a Lens replay, named; nil for the break (the ruling already says it was the
    /// break) and when nothing is offered. As MatchCard.namedHighlight.
    static func namedHighlight(_ model: ShowpieceModel) -> ShotHighlight? {
        guard model.offerLensReplay, let h = model.match?.lensHighlight, h.kind != .breakShot else { return nil }
        return h
    }

    /// "Watch it in the Lens", as the card's button: the break or the remarkable shot replayed slowly in the Lens.
    static func lensButton(_ model: ShowpieceModel) -> BlurbButton {
        BlurbButton(String(localized: "Watch it in the Lens"),
                    hint: namedHighlight(model) == nil
                        ? String(localized: "Replays the break slowly with the physics drawn on the table")
                        : HighlightWords.watchHint) {
            model.watchShotInLens()
        }
    }
}

// MARK: The blurbs

/// The match's docked blurbs on the upright phone, in the dock's order (hosted by PlayPhoneBlurbs). Shows nothing
/// outside a match.
struct MatchPhoneBlurbs: View {
    let model: ShowpieceModel
    /// "Why that shot" is open (on the ruling, or under the settled line).
    @State private var showingWhy = false
    /// The ruling blurb's fold (true is folded): opened by "Why that shot" so its reasons are not folded away.
    @State private var rulingFolded = true
    /// The aiming status blurb's fold: folded shows the settled line, open adds the standings under it.
    @State private var statusFolded = true

    var body: some View {
        if let match = model.match {
            switch match.phase {
            case .aiming: aiming(match)
            case .shooting: shooting(match)
            case .ruling: ruling(match)
            case .handOver: handOver(match)
            case .over: result(match)
            }
        }
    }

    // MARK: Aiming

    @ViewBuilder
    private func aiming(_ match: MatchMode) -> some View {
        if match.confirmingEnd {
            // Asked here (no alert or sheet): ending throws the game away and is not counted in the record.
            Blurb(sentence: String(localized: "End this game? It won't be saved, and it doesn't count in your record."),
                  startsFolded: false,
                  buttons: [
                    BlurbButton(String(localized: "Keep playing")) { match.confirmingEnd = false },
                    BlurbButton(String(localized: "End match"),
                                hint: String(localized: "Ends this game and goes back to the menu")) {
                        match.confirmingEnd = false
                        model.endMatch()
                        if !model.menuOpen { model.openMenu() }
                    }
                  ])
        } else {
            status(match)
            if let choice = MatchPhone.personChoice(match) { choiceBlurb(choice, match, lead: nil) }
        }
    }

    /// The aiming status: the computer's work, the settled ruling and the standings. With a settled ruling the blurb
    /// folds (the ruling's line first, the standings a tap away), so the table keeps its height; without one the
    /// standings show as they are.
    @ViewBuilder
    private func status(_ match: MatchMode) -> some View {
        let why = settledWhy(match)
        if let settled = match.settledRuling {
            Blurb(folded: $statusFolded, buttons: why == nil ? [] : [whyButton(open: { statusFolded = false })]) { open in
                VStack(alignment: .leading, spacing: 6) {
                    computerLines(match)
                    Text(verbatim: MatchCard.settledWords(settled, match))
                        .font(Theme.body)
                        .lineLimit(open ? nil : 2)
                        .fixedSize(horizontal: false, vertical: true)
                    if open {
                        if showingWhy, let shot = why { reasons(shot) }
                        MatchStandings(match: match)
                    }
                }
            }
        } else {
            Blurb {
                VStack(alignment: .leading, spacing: 6) {
                    computerLines(match)
                    MatchStandings(match: match)
                }
            }
        }
    }

    /// The computer's decision: its choice prompt (if any) and that it is thinking or lining up its shot.
    @ViewBuilder
    private func computerLines(_ match: MatchMode) -> some View {
        if match.computerSeatToAct != nil {
            if let choice = match.state.pendingChoice {
                Text(verbatim: MatchWords.choicePrompt(choice, names: match.playerNames, you: match.you))
                    .font(Theme.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            let lining = model.computerTurnStage == .staging || model.computerTurnStage == .striking
            HStack(spacing: 8) {
                ProgressView().controlSize(.small).accessibilityHidden(true)
                Text(verbatim: lining ? OpponentWords.liningUp : OpponentWords.thinking)
                    .font(Theme.body)
            }
        }
    }

    /// The computer's shot behind the settled ruling, when "Why that shot" applies to it.
    private func settledWhy(_ match: MatchMode) -> OpponentShot? {
        guard let r = match.settledRuling else { return nil }
        return Self.computersShot(r, match)
    }

    // MARK: Shooting

    @ViewBuilder
    private func shooting(_ match: MatchMode) -> some View {
        // The call the shot is held to. "See the ruling" is the strip's primary action while the shot plays.
        if let call = match.currentCall {
            Blurb(sentence: MatchWords.callLine(call))
        }
    }

    // MARK: Ruling

    @ViewBuilder
    private func ruling(_ match: MatchMode) -> some View {
        if let r = match.lastRuling {
            let choice = MatchPhone.personChoice(match)
            let shot = Self.computersShot(r, match)
            // The small buttons, in this order of precedence: a choice's two answers fill both slots (the strip's
            // primary action is hidden then, and the Lens offer gets a blurb of its own below); otherwise the Lens
            // offer, then "Why that shot". A routine ruling in its beat offers the Lens only while it waits for a tap
            // (MatchMode.rulingWaitsForTap), as the card did.
            let buttons: [BlurbButton] = {
                if let choice { return answerButtons(choice, match) }
                var out: [BlurbButton] = []
                let offersLens = match.lastRulingShow == .card || match.rulingWaitsForTap
                if offersLens && model.offerLensReplay { out.append(MatchPhone.lensButton(model)) }
                if shot != nil { out.append(whyButton(open: { rulingFolded = false })) }
                return out
            }()
            Blurb(title: MatchCard.rulingTitle(r, match),
                  sentence: rulingText(r, match, shot: shot, choice: choice),
                  folded: $rulingFolded,
                  buttons: buttons)
                // Each ruling starts folded with its reasons closed.
                .onAppear { showingWhy = false; rulingFolded = true }
            if choice != nil && model.offerLensReplay { lensOfferBlurb() }
        }
        // A ruling phase with nothing to show cannot be read: Continue (the primary action) moves on.
    }

    /// Everything the ruling says, in reading order: its sentences, how the points came and the scores (five-pin, bar
    /// billiards), the computer's reasons once opened, the remarkable shot on offer, and a choice's prompt.
    private func rulingText(_ r: Ruling, _ match: MatchMode, shot: OpponentShot?, choice: PendingChoice?) -> String {
        var parts = MatchCard.rulingSentences(r, match)
        if !match.lastPoints.isEmpty {
            parts += TableGameWords.lines(match.lastPoints, kind: match.state.kind, names: match.playerNames,
                                          you: match.you)
            if match.rules.keepsRunningScore {
                parts.append(TableGameWords.scores(match.state.scores, names: match.playerNames, you: match.you))
            }
        }
        if showingWhy, let shot { parts += OpponentWords.why(shot) }
        if let h = MatchPhone.namedHighlight(model) {
            parts.append(HighlightWords.title(h.kind) + ". " + HighlightWords.line(h.kind))
        }
        if let choice { parts.append(MatchWords.choicePrompt(choice, names: match.playerNames, you: match.you)) }
        return parts.joined(separator: " ")
    }

    /// The Lens offer beside a choice (whose answers fill the ruling's two buttons): the shot named, one button.
    private func lensOfferBlurb() -> some View {
        let title = MatchPhone.namedHighlight(model).map { HighlightWords.title($0.kind) }
            ?? String(localized: "Watch it in the Lens")
        return Blurb(title: title, buttons: [MatchPhone.lensButton(model)])
    }

    // MARK: Hand-over

    private func handOver(_ match: MatchMode) -> some View {
        let next = MatchWords.name(match.state.turn, in: match.playerNames)
        var lines: [String] = []
        if let hand = MatchWords.ballInHand(match.state.ballInHand, for: next) { lines.append(hand) }
        if let g = match.state.group(of: match.state.turn) {
            lines.append(MatchWords.groupLine(g, left: match.state.ballsRemaining(for: match.state.turn).count,
                                              tableOpen: false))
        }
        // Ready is the strip's primary action.
        return Blurb(title: MatchWords.handOver(to: next), sentence: lines.isEmpty ? nil : lines.joined(separator: " "))
    }

    // MARK: Result

    @ViewBuilder
    private func result(_ match: MatchMode) -> some View {
        let menu = BlurbButton(String(localized: "Menu")) {
            model.endMatch()
            if !model.menuOpen { model.openMenu() }
        }
        if let r = match.state.result {
            let lines = resultLines(r, match)
            // Rematch is the strip's primary action.
            Blurb(title: MatchWords.resultTitle(r, names: match.playerNames, you: match.you),
                  sentence: lines.isEmpty ? nil : lines.joined(separator: " "),
                  buttons: [menu])
        } else {
            Blurb(title: String(localized: "Game over"), buttons: [menu])
        }
    }

    /// The result's lines: why (when the ruling that ended it did not already say), the scores, the best score alone,
    /// and against the computer the record at this level and this sitting's tally (as the card's result).
    private func resultLines(_ r: MatchResult, _ match: MatchMode) -> [String] {
        var lines: [String] = []
        if match.lastRuling?.result == nil {
            let why = MatchWords.endReason(r, shooter: match.lastRuling?.shooter, names: match.playerNames,
                                           you: match.you)
            if !why.isEmpty { lines.append(why) }
        }
        if match.rules.keepsRunningScore {
            lines.append(TableGameWords.scores(match.state.scores, names: match.playerNames, you: match.you))
        }
        if let best = match.bestOutcome { lines.append(TableGameWords.bestOutcome(best)) }
        return lines + MatchCard.recordLines(match)
    }

    // MARK: Pieces

    /// A choice: its prompt (with an optional lead line) and its answers as the blurb's two buttons.
    private func choiceBlurb(_ c: PendingChoice, _ match: MatchMode, lead: String?) -> some View {
        let prompt = MatchWords.choicePrompt(c, names: match.playerNames, you: match.you)
        return Blurb(sentence: [lead, prompt].compactMap { $0 }.joined(separator: " "),
                     startsFolded: false,
                     buttons: answerButtons(c, match))
    }

    /// A choice's answers (the first is the usual one: take the table, spot the 8). At most two are drawn.
    private func answerButtons(_ c: PendingChoice, _ match: MatchMode) -> [BlurbButton] {
        c.choice.answers.map { a in BlurbButton(MatchWords.answer(a)) { match.answer(a) } }
    }

    /// "Why that shot": opens the computer's reasons inside the blurb (and opens the blurb so they are not folded).
    private func whyButton(open: @escaping @MainActor () -> Void) -> BlurbButton {
        BlurbButton(OpponentWords.whyThatShot,
                    hint: showingWhy ? String(localized: "Open") : String(localized: "Closed")) {
            showingWhy.toggle()
            if showingWhy { open() }
        }
    }

    /// The computer's reasons, one line each.
    private func reasons(_ shot: OpponentShot) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(OpponentWords.why(shot).enumerated()), id: \.offset) { _, s in
                Text(verbatim: s).font(Theme.body).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// The computer's own stroke behind a ruling (not an answered choice), as MatchCard.whyIfComputers.
    private static func computersShot(_ r: Ruling, _ match: MatchMode) -> OpponentShot? {
        guard let shot = match.opponent?.lastShot, shot.seat == r.shooter, match.isComputer(r.shooter),
              !r.reasons.contains(.choiceAnswered) else { return nil }
        return shot
    }
}

// MARK: The title

extension PhoneTitle {
    /// The match's title on the upright phone, one line: whose turn and where the game stands. The result once the
    /// game is over. Otherwise whose turn ("Your turn", "Your break", "Computer (Hard) to shoot") and, after a
    /// middle dot, the score (five-pin and bar billiards; the person's first), the person's group (eight-ball) or
    /// the ball to hit first (nine-ball). The person's turn says "Your turn", not "Your shot": "Your shot" is the
    /// strip's button that brings the aiming panel back, and the two would read as one.
    static func match(_ model: ShowpieceModel) -> String? {
        guard let match = model.match else { return nil }
        let state = match.state
        if match.phase == .over, let r = state.result {
            return MatchWords.resultTitle(r, names: match.playerNames, you: match.you)
        }
        let isBreak = state.isBreak && !state.kind.isTableGame
        let who: String
        if state.turn == match.you {
            who = isBreak ? String(localized: "Your break")
                          : String(localized: "Title: Your turn", defaultValue: "Your turn",
                                   comment: "Phone title row during a match, on the person's turn; short")
        } else {
            who = MatchWords.toShoot(MatchWords.name(state.turn, in: match.playerNames), isBreak: isBreak)
        }
        guard let detail = standing(match) else { return who }
        return who + " · " + detail
    }

    /// The short standing after the turn: the score, the group or the ball to hit first; nil when there is none.
    private static func standing(_ match: MatchMode) -> String? {
        let state = match.state
        if match.rules.keepsRunningScore {
            let scores = state.players.map { p in
                state.scores.indices.contains(p.id.index) ? state.scores[p.id.index] : 0
            }
            guard !scores.isEmpty else { return nil }
            // Alone (bar billiards against the clock): the one score. Two seats: the person's first, so "12–8" on the
            // person's line reads as theirs.
            if scores.count == 1 { return scores[0].formatted(.number.locale(AppLocale.numbers)) }
            var ordered = state.players.map(\.id)
            if let you = match.you, let i = ordered.firstIndex(of: you) { ordered.insert(ordered.remove(at: i), at: 0) }
            return ordered.map { id in
                (state.scores.indices.contains(id.index) ? state.scores[id.index] : 0).formatted(.number.locale(AppLocale.numbers))
            }.joined(separator: "–")
        }
        if state.kind == .eightBall, let you = match.you {
            let words = MatchWords.groupLine(state.group(of: you), left: state.ballsRemaining(for: you).count,
                                             tableOpen: state.tableOpen)
            return words.isEmpty ? nil : words
        }
        if state.kind == .nineBall, let low = state.ballsLeft.min() { return MatchWords.hitFirst(low) }
        return nil
    }
}

// MARK: The primary action

extension PhonePrimaryAction {
    /// The match's primary action: Continue for a ruling that waits for a tap (a ruling card, a routine ruling held
    /// with its Lens offer, or a ruling with nothing to read), Ready at a hand-over, Rematch at the end, and "See the
    /// ruling" while a match shot plays (hidden anyway while the person's own shot rolls). Nil while the person has a
    /// choice to answer (its two answers are in the blurb; see matchHoldsPrimary) and while aiming.
    static func match(_ model: ShowpieceModel) -> PhonePrimaryAction? {
        guard let match = model.match, MatchPhone.personChoice(match) == nil else { return nil }
        switch match.phase {
        case .ruling:
            guard match.lastRuling == nil || match.lastRulingShow == .card || match.rulingWaitsForTap else { return nil }
            return PhonePrimaryAction(title: String(localized: "Continue")) { match.acknowledgeRuling() }
        case .handOver:
            return PhonePrimaryAction(title: String(localized: "Ready"),
                                      hint: String(localized: "Shows the table for the next player's shot")) {
                match.acknowledgeRuling()
            }
        case .over:
            return PhonePrimaryAction(title: String(localized: "Rematch"), hint: MatchCard.rematchHint(match)) {
                match.rematch()
            }
        case .shooting:
            guard model.matchShotPlaying else { return nil }
            return PhonePrimaryAction(title: String(localized: "See the ruling"),
                                      hint: String(localized: "Skips to the end of the shot so the ruling comes at once")) {
                model.seeRuling()
            }
        case .aiming:
            return nil
        }
    }

    /// True while a match choice is the person's to answer: the plan hides the primary action then (the answers are
    /// the blurb's two buttons), so PhonePrimaryAction.resolve should stop and return nil rather than fall through to
    /// the other providers and "Your shot".
    static func matchHoldsPrimary(_ model: ShowpieceModel) -> Bool {
        guard let match = model.match else { return false }
        return MatchPhone.personChoice(match) != nil
    }
}
