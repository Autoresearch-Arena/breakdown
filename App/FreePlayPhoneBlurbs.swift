// Author: Claude Opus 5.5 Medium
// Date: 22-November-2026
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 make it again, plans/23-Nov-2026-make-it-again-plan.md F2:
//          HighlightPhoneBlurb's small buttons start with Make it again / Play it now when the shot can be saved.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 coordinator: what steps aside for the what-if now also steps
//          aside for the every-surface fan, through model.otherFutureShowing.)
// PURPOSE: Free play and matches on the upright phone (plans/22-Nov-2026-phone-ui-plan.md, Part 3 "Every phone state"
//          and Part 4 step 5): everything PlayCards (FreePlayViews.swift) shows on the other layouts, as small docked
//          blurbs instead of full-width glass cards, hosted together as PlayPhoneBlurbs in ShowpieceView's dock:
//            PlaceBallsPhoneBlurb   - "No rack: place the balls" with nothing lifted: how to pick a ball up.
//            BallInHandPhoneBlurb   - ball in hand or a lifted ball: what to do, whether the spot is free, and Place it
//                                     / Cancel (or Pick up the cue ball) as the blurb's small buttons; for VoiceOver
//                                     the Move up, down, left and right actions and the spot in words, as the card.
//            TableClearedPhoneBlurb - free play's cleared rack: the shot count, Watch your best shot in the blurb, and
//                                     Rack again as the strip's primary action.
//            HighlightPhoneBlurb    - a remarkable free-play shot: its name and physics, Try the trick shot and Close
//                                     in the blurb, "Watch it" (in the Lens) as the primary action.
//            IntroEndPhoneBlurb     - the end of Watch the intro: its line, Practice and Close in the blurb, Trick
//                                     shots as the primary action.
//            MatchPhoneBlurbs       - the match (App/Match/MatchPhoneBlurbs.swift).
//          Also PhonePrimaryAction.freePlay (the strip's white capsule for these) and PhonePlayFeedback, the
//          always-present observer PlayTableLayer hosts on the upright phone: the match's announcements and clock
//          haptic (MatchFeedback) and the cleared rack's success haptic, which the blurbs cannot hold because they come
//          and go with what they show.
//          Colour: the old cards' cyan accents are white here (Part 3: cyan means rolling only); an illegal spot stays
//          red with its icon, so it never depends on colour alone.
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 clips, plans/23-Nov-2026-clips-plan.md: ClipPhoneBlurb comes first
//          in PlayPhoneBlurbs, the cleared-table blurb offers "Share your best shot" as its second button, and the
//          strip's primary action is "Share clip" after a watched or closed highlight (PhonePrimaryAction.clip).)
// SRP/DRY check: Pass - each blurb shows exactly when its card does (BallInHandCard.isVisible, PlaceBallsCard.isVisible,
//          TableClearedCard.isVisible, model.highlightCard, model.introEndOffered); words and moves are the cards'
//          (CueBallPlacement, TableClearedCard.shotsLine, HighlightWords); actions are the same model calls.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import SwiftUI

/// Every free-play and match blurb, flattened into the dock (a Group, so the dock's spacing applies and an absent
/// blurb takes no room). The upright phone's PlayCards.
struct PlayPhoneBlurbs: View {
    let model: ShowpieceModel

    var body: some View {
        Group {
            ClipPhoneBlurb(model: model)  // 0.7.7 clips: a clip being made is the newest thing on screen
            PlaceBallsPhoneBlurb(model: model)
            BallInHandPhoneBlurb(model: model)
            TableClearedPhoneBlurb(model: model)
            HighlightPhoneBlurb(model: model)
            IntroEndPhoneBlurb(model: model)
            MatchPhoneBlurbs(model: model)
        }
    }

    /// True while a guided Lens replay actually plays (the balls moving or held on a beat): the blurbs keep their
    /// titles and drop their sentences, so the moment has the table (the old cards' slim form).
    static func replaying(_ model: ShowpieceModel) -> Bool {
        model.lensOn && model.guided && !model.aimReady
    }
}

// MARK: Place the balls

struct PlaceBallsPhoneBlurb: View {
    let model: ShowpieceModel

    var body: some View {
        if PlaceBallsCard.isVisible(model) {
            Blurb(title: String(localized: "Place the balls"),
                  sentence: String(localized: "Touch or click any ball to pick it up, then drag it where you want it. Place it puts it down."))
        }
    }
}

// MARK: Ball in hand

struct BallInHandPhoneBlurb: View {
    let model: ShowpieceModel

    var body: some View {
        if BallInHandCard.isVisible(model) {
            let spot = CueBallPlacement.spot(model)
            let problem = model.placingCueBall
                ? CueBallPlacement.problem(CueBallPlacement.legality(of: spot, model)) : nil
            Blurb(buttons: buttons) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: CueBallPlacement.heading(model))
                        .font(Theme.blurbTitle)
                        .accessibilityAddTraits(.isHeader)
                    Text(verbatim: CueBallPlacement.instructions(model))
                        .font(Theme.body)
                        .fixedSize(horizontal: false, vertical: true)
                    if model.placingCueBall {
                        // The spot under the ball: words AND an icon, red only when it is not legal.
                        Label(problem ?? String(localized: "Free spot"),
                              systemImage: problem == nil ? "checkmark.circle" : "xmark.octagon")
                            .font(Theme.label)
                            .foregroundStyle(problem == nil ? Color.white : Color.red)
                            .accessibilityLabel(Text(verbatim: CueBallPlacement.spoken(model, at: spot, problem: problem)))
                    }
                }
                // The complete route for VoiceOver, as the card: the blurb combines its content into one element,
                // which carries the moves while a ball is lifted.
                .modifier(PlacementMoves(model: model))
            }
        }
    }

    /// Place it (and Cancel when lifting was the player's own idea; owed ball in hand must be placed), or Pick up the
    /// cue ball while it is owed and still on the table.
    private var buttons: [BlurbButton] {
        guard model.placingCueBall else {
            return [BlurbButton(String(localized: "Pick up the cue ball")) { model.beginPlacingCueBall() }]
        }
        var out: [BlurbButton] = []
        if model.ballInHand == .none { out.append(BlurbButton(String(localized: "Cancel")) { model.cancelPlacement() }) }
        out.append(BlurbButton(String(localized: "Place it")) { CueBallPlacement.place(model) })
        return out
    }
}

/// VoiceOver's Move up, down, left and right while a ball is lifted, as BallInHandCard: one ball radius a step, in
/// table directions seen from the head end. Nothing while the ball is only owed (there is nothing to move yet).
private struct PlacementMoves: ViewModifier {
    let model: ShowpieceModel

    func body(content: Content) -> some View {
        if model.placingCueBall {
            content
                .accessibilityAction(named: String(localized: "Move up")) { CueBallPlacement.nudge(model, Vec2(1, 0)) }
                .accessibilityAction(named: String(localized: "Move down")) { CueBallPlacement.nudge(model, Vec2(-1, 0)) }
                .accessibilityAction(named: String(localized: "Move left")) { CueBallPlacement.nudge(model, Vec2(0, 1)) }
                .accessibilityAction(named: String(localized: "Move right")) { CueBallPlacement.nudge(model, Vec2(0, -1)) }
        } else {
            content
        }
    }
}

// MARK: Table cleared

struct TableClearedPhoneBlurb: View {
    let model: ShowpieceModel

    var body: some View {
        if TableClearedCard.isVisible(model) {
            // While the best shot replays in the Lens the title alone says what is on screen.
            let replaying = model.replayingBest && PlayPhoneBlurbs.replaying(model)
            Blurb(title: String(localized: "Table cleared"),
                  sentence: replaying ? nil : TableClearedCard.shotsLine(model),
                  buttons: bestShotButtons)
                .onAppear { ShotNarration.announce(String(localized: "Table cleared")) }
        }
    }

    /// Watch your best shot, and (0.7.7 clips) Share your best shot as the second button when on offer.
    private var bestShotButtons: [BlurbButton] {
        guard model.canWatchBestShot else { return [] }
        var out = [BlurbButton(HighlightWords.watchBest, hint: HighlightWords.watchHint) { model.watchBestShot() }]
        if ClipOffer.bestShotAvailable(model) {  // 0.7.7 clips
            out.append(BlurbButton(String(localized: "Share your best shot"), hint: ClipWords.hint) {
                ClipOffer.startBestShot(model)
            })
        }
        return out
    }
}

// MARK: Worth watching

struct HighlightPhoneBlurb: View {
    let model: ShowpieceModel

    var body: some View {
        // Steps aside while a what-if is showing; it comes back on the what-if's close.
        if let offer = model.highlightCard, !model.otherFutureShowing {
            let kind = offer.highlight.kind
            Blurb(title: HighlightWords.title(kind),
                  sentence: PlayPhoneBlurbs.replaying(model) ? nil : HighlightWords.line(kind),
                  buttons: buttons(offer))
                .onAppear { ShotNarration.announce(HighlightWords.title(kind)) }
        }
    }

    /// Try the trick shot when it is allowed, and Close. "Watch it in the Lens" is the strip's primary action.
    private func buttons(_ offer: ShowpieceModel.HighlightCardOffer) -> [BlurbButton] {
        var out: [BlurbButton] = []
        // 0.7.7 make-it-again: Make it again (or Play it now) first when the shot can be saved; the blurb draws the
        // first two, so with Try the trick shot as well, Close is not drawn (the blurb still goes at the first touch).
        if let save = MakeItAgainButton.blurbButton(model) { out.append(save) }
        if offer.canTryTrick {
            out.append(BlurbButton(String(localized: "Try the trick shot")) { model.tryHighlightTrick() })
        }
        out.append(BlurbButton(String(localized: "Close")) { model.dismissHighlight() })
        return out
    }
}

// MARK: The end of the intro

struct IntroEndPhoneBlurb: View {
    let model: ShowpieceModel

    var body: some View {
        if model.introEndOffered, !model.otherFutureShowing {
            Blurb(sentence: HighlightWords.introEnd,
                  startsFolded: false,
                  buttons: [
                    // Practice: a fresh rack on the pool table and Your shot open, as the menu's Practice does.
                    BlurbButton(String(localized: "Practice")) {
                        model.startGame()
                        model.requestShotPanel(.open)
                    },
                    BlurbButton(String(localized: "Close")) { model.dismissIntroEnd() }
                  ])
                .onAppear { ShotNarration.announce(HighlightWords.introEnd) }
        }
    }
}

// MARK: Feedback that outlives the blurbs

/// Hosted by PlayTableLayer on the upright phone only (where MatchCard and TableClearedCard are not on screen, so
/// nothing is said or felt twice): an invisible, untouchable view that is always there, holding the match's
/// MatchFeedback (each phase announced, the End-match confirmation closed as the game moves on, bar billiards' clock)
/// and the cleared rack's success haptic.
struct PhonePlayFeedback: View {
    let model: ShowpieceModel

    var body: some View {
        Color.clear
            .modifier(MatchFeedbackHost(match: model.match))
            .sensoryFeedback(trigger: TableClearedCard.isVisible(model)) { _, now in
                now && GameSettings.hapticsOn ? .success : nil
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// MatchFeedback while a match is on, nothing otherwise (a modifier cannot be applied on a condition directly).
private struct MatchFeedbackHost: ViewModifier {
    let match: MatchMode?

    func body(content: Content) -> some View {
        if let match {
            content.modifier(MatchFeedback(match: match))
        } else {
            content
        }
    }
}

// MARK: The primary action

extension PhonePrimaryAction {
    /// Free play's primary action: Rack again on a cleared table, "Watch it" for a remarkable shot still on offer,
    /// and Trick shots at the end of Watch the intro. Nil otherwise (and always in a match: MatchPhoneBlurbs owns it).
    static func freePlay(_ model: ShowpieceModel) -> PhonePrimaryAction? {
        if TableClearedCard.isVisible(model) {
            return PhonePrimaryAction(title: String(localized: "Rack again")) { model.rackAgain() }
        }
        if let offer = model.highlightCard, !model.otherFutureShowing, offer.canWatch {
            return PhonePrimaryAction(title: String(localized: "Watch it"), hint: HighlightWords.watchHint) {
                model.watchHighlight()
            }
        }
        // 0.7.7 clips: after the highlight's Watch it was used or its card closed, "Share clip".
        if let a = PhonePrimaryAction.clip(model) { return a }
        if model.introEndOffered, !model.otherFutureShowing {
            return PhonePrimaryAction(title: String(localized: "Trick shots")) { model.showList(.tricks) }
        }
        return nil
    }
}
