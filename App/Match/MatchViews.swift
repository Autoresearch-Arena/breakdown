// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: 21-November-2026 by Claude Opus 5.5 High (tables-screens) - the three table games: the turn banner says
//          which ball to strike and what is left (bumper pool: each side's balls still to sink; five-pin: your ball,
//          the ball to hit first, the scores and the target; bar billiards: the clock, or the bar once time is up,
//          the break in progress, the total and, alone, the best score); after each five-pin and bar-billiards shot a
//          "How the points came" section explains the score line by line (TablePoints, TableGameWords); the result
//          card says what a one-player bar-billiards game did to the best score; VoiceOver hears the points and the
//          scores with each ruling and the moment time runs out. The ruling card names the ball that was really
//          struck (MatchMode.lastShotBall) and the other tables' balls by their names there.
// PURPOSE: Everything the player sees of a match (eight-ball and nine-ball for two on one device; the other tables'
//          games use the same card), as ONE glass card whose content follows MatchMode.phase:
//            aiming   - the turn banner: who shoots (or breaks), the game, each player's group with their balls left
//                       as small ball icons (eight-ball), the ball to hit first (nine-ball), running scores and the
//                       clock where the game keeps them; editable player names; a pending choice ("take the table or
//                       rack again"); and the call control while the rules want a call (eight-ball after the break;
//                       never in nine-ball).
//            shooting - the banner, small, with the call.
//            ruling   - the ruling in plain words ("Foul: the cue ball hit the 11 first. Ball in hand for Sam."),
//                       then the choice, or Continue.
//            handOver - "Pass the device to Sam." and Ready.
//            over     - who won and why, the running scores, Rematch and Menu.
//          Feedback hooks (rules plan, package 6): a warning tap for a foul, a light tick when the turn passes, a
//          success tap for a win (only with Vibration on), and the ruling spoken to VoiceOver as it appears. Sounds are
//          the sound stream's (FeelMapping, SoundBoard); this file only adds the view-side hooks.
//          Hosted by PlayCards (FreePlayViews.swift) next to the other mode cards, so it sits above the controls on a
//          phone, at the top of the side column on iPad and Mac, and in the notebook panel on the open Duo; it never
//          opens a sheet, so on the Duo nothing covers the table.
//          Reads MatchMode (App/Match/MatchMode.swift, the model stream's): state, phase, rules, currentCall,
//          lastRuling, playerNames, and calls setCall, acknowledgeRuling, answer, rematch, setPlayerName. Reads the
//          shot on screen (ShowpieceModel.timeline) only to name the balls that dropped and the first ball hit.
// SRP/DRY check: Pass - words are in MatchWords, the call in CallControl, the cue-ball placement in FreePlayViews and
//          PlayTableLayer; card styling is the shared glassCard and the button rows follow TrickShotCard's.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import SwiftUI

struct MatchCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var editingNames = false

    var body: some View {
        if let match = model.match {
            VStack(alignment: .leading, spacing: 8) {
                content(match)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 22, padding: 12)
            .tint(palette.accent)
            .animation(reduceMotion ? nil : .snappy, value: match.phase)
            // One tap per ruling, read at the moment it fires so the Vibration option is always current.
            .sensoryFeedback(trigger: match.lastRuling) { _, ruling in Self.feedback(for: ruling) }
            .onChange(of: match.phase) { _, phase in announce(phase, match) }
            // Bar billiards: the moment the clock runs out, said aloud and felt (the banner shows the bar from then).
            .onChange(of: match.timeIsUp) { _, up in
                if up { AccessibilityNotification.Announcement(TableGameWords.timeUpNow).post() }
            }
            .sensoryFeedback(trigger: match.timeIsUp) { _, up in up && GameSettings.hapticsOn ? .warning : nil }
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private func content(_ match: MatchMode) -> some View {
        switch match.phase {
        case .aiming:
            TurnBanner(match: match, editingNames: $editingNames)
            if let choice = match.state.pendingChoice {
                choiceSection(choice, match)
            } else if match.mustCall {
                MatchCallControl(model: model, match: match)
            }
        case .shooting:
            TurnBanner(match: match, editingNames: .constant(false), compact: true)
            if let call = match.currentCall { line(MatchWords.callLine(call)) }
        case .ruling:
            if let r = match.lastRuling {
                rulingHeader(r)
                ForEach(Array(rulingSentences(r, match).enumerated()), id: \.offset) { _, s in line(s) }
                if !match.lastPoints.isEmpty { pointsSection(match) }
                if let choice = match.state.pendingChoice {
                    choiceSection(choice, match)
                } else {
                    buttons { continueButton(match) }
                }
            } else {
                // A ruling phase with nothing to show cannot be read; let the player move on.
                buttons { continueButton(match) }
            }
        case .handOver:
            handOver(match)
        case .over:
            result(match)
        }
    }

    // MARK: Ruling

    private func rulingHeader(_ r: Ruling) -> some View {
        HStack(spacing: 8) {
            Image(systemName: r.fouled ? "exclamationmark.triangle.fill"
                  : (r.turnPasses ? "arrow.left.arrow.right" : "checkmark.circle.fill"))
                .foregroundStyle(r.fouled ? palette.slide : palette.accent)
                .accessibilityHidden(true)
            Text(r.fouled ? String(localized: "Foul") : (r.turnPasses ? String(localized: "Turn over")
                                                                     : String(localized: "Keep shooting")))
                .font(Theme.heading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    /// The ruling's sentences, with what the recording showed: the object balls that dropped and the first ball the
    /// shooter's cue ball touched (so a wrong-ball foul names the ball).
    private func rulingSentences(_ r: Ruling, _ match: MatchMode) -> [String] {
        // The ball that was struck: after the ruling the state may name another (bumper pool's next ball once the
        // marked one is down, bar billiards' next white).
        let cueBall = match.lastShotBall ?? match.rules.cueBall(for: r.shooter, in: match.state)
        let tl = model.timeline
        // Only balls that started this shot on the table: a ball pocketed on an earlier shot sits at the parking spot
        // from the start of the recording and must not be named again.
        let pocketed = (0..<tl.ballCount).filter {
            $0 != cueBall && tl.pocketTime[$0] != nil && NextShot.isOnTable(tl.state(ball: $0, at: 0).position)
        }
        return MatchWords.sentences(for: r, names: match.playerNames, pocketed: pocketed,
                                    firstBall: Self.firstBall(hitBy: cueBall, in: tl), kind: match.state.kind)
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

    /// The first ball a given cue ball touched in a recording, or nil when it touched none.
    static func firstBall(hitBy cueBall: Int, in tl: Timeline) -> Int? {
        for e in tl.events where e.kind == .ballBall {
            let ids = e.balls.map(\.ball)
            if ids.contains(cueBall) { return ids.first { $0 != cueBall } }
        }
        return nil
    }

    private func continueButton(_ match: MatchMode) -> some View {
        Button { match.acknowledgeRuling() } label: {
            Label("Continue", systemImage: "arrow.right").font(.headline).lineLimit(1)
                .frame(minHeight: CallMetrics.buttonHeight)
        }
        .buttonStyle(.glassProminent)
        .foregroundStyle(palette.ground)
        .keyboardShortcut(.defaultAction)
    }

    @ViewBuilder
    private func choiceSection(_ c: PendingChoice, _ match: MatchMode) -> some View {
        line(MatchWords.choicePrompt(c, names: match.playerNames))
        buttons {
            ForEach(Array(c.choice.answers.enumerated()), id: \.offset) { i, a in
                let b = Button { match.answer(a) } label: {
                    Text(MatchWords.answer(a)).font(.headline).lineLimit(1).frame(minHeight: CallMetrics.buttonHeight)
                }
                // The first answer is the usual one (take the table, spot the 8), so it is the prominent button.
                if i == 0 { b.buttonStyle(.glassProminent).foregroundStyle(palette.ground) } else { b.buttonStyle(.glass) }
            }
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
        buttons {
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
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            let why = MatchWords.endReason(r, shooter: match.lastRuling?.shooter, names: match.playerNames)
            if !why.isEmpty { line(why) }
            if match.rules.keepsRunningScore { ScoreRow(match: match) }
            if let best = match.bestOutcome { line(TableGameWords.bestOutcome(best)) }
        }
        buttons {
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

    /// The tap a ruling earns: success for the end of the game, a warning for a foul, a light tick when the turn
    /// passes; nothing when the shooter simply carries on. Nil whenever Vibration is off in Options.
    static func feedback(for r: Ruling?) -> SensoryFeedback? {
        guard GameSettings.hapticsOn, let r else { return nil }
        if r.result != nil { return .success }
        if r.fouled { return .warning }
        if r.turnPasses { return .selection }
        return nil
    }

    /// VoiceOver hears each ruling, the hand-over and the result as they arrive, without hunting for the card.
    private func announce(_ phase: MatchMode.Phase, _ match: MatchMode) {
        let text: String
        switch phase {
        case .ruling:
            guard let r = match.lastRuling else { return }
            text = spokenRuling(r, match)
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
        AccessibilityNotification.Announcement(text).post()
    }

    // MARK: Pieces (as TrickShotCard's)

    private func line(_ text: String) -> some View {
        Text(text)
            .font(Theme.body)
            .foregroundStyle(palette.paper.opacity(0.9))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// One row of buttons, right-aligned; a column when the text is too large for one row.
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
}

// MARK: The turn banner

/// Who shoots, the game, and where each player stands.
struct TurnBanner: View {
    let match: MatchMode
    @Binding var editingNames: Bool
    /// While a shot plays: only the first line.
    var compact = false
    @Environment(\.palette) private var palette

    private var state: MatchState { match.state }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(MatchWords.toShoot(MatchWords.name(state.turn, in: match.playerNames), isBreak: state.isBreak))
                    .font(Theme.heading)
                    .lineLimit(2)
                Spacer(minLength: 0)
                Text(MatchWords.title(state.kind)).font(Theme.label).foregroundStyle(palette.slide)
                if !compact {
                    Button { editingNames.toggle() } label: {
                        Label(String(localized: "Player names"), systemImage: editingNames ? "checkmark" : "pencil")
                            .labelStyle(.iconOnly)
                            .frame(minWidth: 30, minHeight: CallMetrics.buttonHeight)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel(editingNames ? String(localized: "Done editing names") : String(localized: "Player names"))
                }
            }
            .accessibilityAddTraits(.isHeader)
            if !compact {
                if editingNames { PlayerNamesEditor(match: match) }
                // Nine-ball, and any game without calls that is played in order: the lowest ball is hit first.
                if state.kind == .nineBall, let low = state.ballsLeft.min() {
                    HStack(spacing: 6) {
                        BallIcon(number: low)
                        Text(MatchWords.hitFirst(low)).font(Theme.body).foregroundStyle(palette.paper.opacity(0.9))
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
                ForEach(left, id: \.self) { BallIcon(number: $0) }
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

    var body: some View {
        if let bumper = match.rules as? BumperPoolRules {
            let seat = state.turn.index
            let ball = match.cueBallIndex
            let marked = BumperPoolRules.sides.indices.contains(seat) && BumperPoolRules.sides[seat].first == ball
            line(TableGameWords.bumperStrike(ball, marked: marked))
            // Each side's balls still to sink, a dot on the side shooting.
            ForEach(state.players, id: \.id) { p in
                let name = MatchWords.name(p.id, in: match.playerNames)
                let left = TableGameWords.ballsToSink(bumper.ballsLeft(for: p.id, in: state).count)
                HStack(spacing: 6) {
                    Circle().fill(p.id == state.turn ? palette.accent : Color.clear)
                        .frame(width: 6, height: 6)
                        .accessibilityHidden(true)
                    Text(name).font(Theme.label).lineLimit(1)
                    Spacer(minLength: 0)
                    Text(left).font(Theme.label).foregroundStyle(.secondary).lineLimit(1)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel([name, left].joined(separator: ". "))
            }
        } else if let five = match.rules as? FivePinRules {
            line(TableGameWords.fivePinStrike(seat: state.turn.index))
            line(TableGameWords.target(five.targetScore))
        } else if match.rules is BarBilliardsRules {
            if let clock = state.clockRemaining {
                if clock > 0 {
                    Text(TableGameWords.timeLeft(seconds: MatchClock.shownSeconds(clock)))
                        .font(Theme.number)
                        .foregroundStyle(palette.paper.opacity(0.9))
                        .accessibilityAddTraits(.updatesFrequently)
                } else {
                    let whites = BarBilliardsRules.whiteBalls.filter { state.ballsLeft.contains($0) }.count
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

/// A small flat picture of a ball: a solid disc, or an ivory disc with a coloured band for a stripe, with the number
/// on a light spot. The colours come from BallTextures, the same palette the 3D balls use. Decorative: the rows that
/// show these always say the numbers in words for VoiceOver.
struct BallIcon: View {
    let number: Int
    @ScaledMetric(relativeTo: .caption) private var size: CGFloat = 16

    var body: some View {
        let c = BallTextures.swatch(number: number)
        let colour = Color(red: c.0, green: c.1, blue: c.2)
        let ivory = Color(red: 0.96, green: 0.94, blue: 0.88)
        ZStack {
            Circle().fill(number > 8 ? ivory : colour)
            if number > 8 {
                // The band: the middle half of the ball's height, as on the real ball.
                Rectangle().fill(colour).frame(height: size * 0.5)
            }
            Circle().fill(ivory).frame(width: size * 0.58, height: size * 0.58)
            Text("\(number)")
                .font(.system(size: size * 0.42, weight: .bold).monospacedDigit())
                .foregroundStyle(Color.black)
                .minimumScaleFactor(0.5)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}
