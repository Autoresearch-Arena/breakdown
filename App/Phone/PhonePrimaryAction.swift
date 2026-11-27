// Author: Claude Opus 5.5 Medium
// Date: 22-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 6, the thumb dock: the fallback's word is "Aim"
//          (StrikeWords.aimTab, the tab's one name; wave 2 note 7), the button is the kit's cyan primary at the right
//          of the dock's action row (PhoneStrip), and a second resolver, `secondary`, offers the one secondary beside
//          it: "Skip" while the opening plays (it left the title row: every action lives in the dock). The modes'
//          providers are unchanged and still compile.)
// PURPOSE: The upright phone's one primary action (plans/22-Nov-2026-phone-ui-plan.md, Part 3 "The control strip"):
//          the cyan capsule at the right of the dock's action row (PhoneStrip), its word chosen by the first mode that has
//          something to offer. The modes write their own providers as extensions in their own files, so this file
//          never learns their rules; it only asks them in the plan's order and then offers its own fallback:
//            match  (PhonePrimaryAction.match,     the match views:   "Continue" for a ruling waiting for a tap, ...)
//            eightBall (.eightBall,                Behind the 8-Ball)
//            trick  (.trick,                       the trick shots:   "Watch it", "Your turn", "Try again", "Next shot")
//            lesson (.lesson,                      the lessons)
//            freePlay (.freePlay,                  free play)
//            stroke (.stroke,                      the stroke drill)
//            then "Aim" here: the aiming controls are closed and the person may shoot, so the button brings them back.
//          Nothing is offered while the person's (or the computer's) shot is live, nor behind the menu. A provider that
//          needs Your shot opened asks the model (model.requestShotPanel(.open)), the one door ShowpieceView listens at.
// SRP/DRY check: Pass - checked PlaybackControls' Your shot toggle (shared views keep it; this is the phone's copy of
//          its open action, through the model's request rather than a binding) and the mode cards' main buttons (they
//          stay in the shared cards; the providers above call the same mode methods).
import Foundation

/// One primary action: its word, what VoiceOver says it does, and what it does. MainActor because every action and
/// provider works on the model; extensions written in other files inherit the isolation.
@MainActor
struct PhonePrimaryAction {
    /// The capsule's word, already translated. Never shortened (Part 3: "The primary action never shortens its word").
    let title: String
    /// Already translated; nil for none.
    let hint: String?
    let action: @MainActor () -> Void

    init(title: String, hint: String? = nil, action: @escaping @MainActor () -> Void) {
        self.title = title
        self.hint = hint
        self.action = action
    }

    /// The action to show now, or nil for none.
    /// - shotPanelOpen: Your shot is open (the fallback offers it only while closed).
    /// - shotLive: a shot just struck is still rolling (ShowpieceView's shotRolling for the person's or the computer's
    ///   own shot): nothing is offered until the balls stop.
    static func resolve(_ model: ShowpieceModel, shotPanelOpen: Bool, shotLive: Bool) -> PhonePrimaryAction? {
        // With the aiming panel open its own white Break or Shoot is the one primary action: the strip's button has
        // grown into the panel (they share a glass identity), so nothing else white shows beside it.
        guard !shotLive, !shotPanelOpen, !model.menuOpen else { return nil }
        // A match choice that is the person's to answer carries its own two buttons: no white button beside them.
        if PhonePrimaryAction.matchHoldsPrimary(model) { return nil }
        // The plan's order; each provider returns nil when its mode has nothing to offer.
        if let a = PhonePrimaryAction.match(model) { return a }
        if let a = PhonePrimaryAction.eightBall(model) { return a }
        if let a = PhonePrimaryAction.trick(model) { return a }
        if let a = PhonePrimaryAction.lesson(model) { return a }
        if let a = PhonePrimaryAction.freePlay(model) { return a }
        if let a = PhonePrimaryAction.stroke(model) { return a }
        return yourShot(model, shotPanelOpen: shotPanelOpen)
    }

    /// The fallback: "Aim" brings the aiming controls back once it has been put away (the "Put away" chevron, the
    /// controller's Y button, a finished replay that closed it), whenever the person may shoot. Not in the first
    /// minute (its panel opens by itself), not during the computer's turn, not while the opening's story plays.
    static func yourShot(_ model: ShowpieceModel, shotPanelOpen: Bool) -> PhonePrimaryAction? {
        guard !shotPanelOpen, model.openingStage == .none, model.stage == .explore, model.personControlsLive else {
            return nil
        }
        return PhonePrimaryAction(title: StrikeWords.aimTab,
                                  hint: String(localized: "Opens the aiming controls")) {
            model.requestShotPanel(.open)
        }
    }

    /// The one secondary beside the primary while the aiming controls are closed (design language: at most one
    /// secondary, left of the primary). "Skip" while the opening plays, so the first minute can be skipped from the
    /// dock as well as by a tap on the table. Nil otherwise; with the aiming controls open the dock offers Try again
    /// itself (PhoneStrip). Mode files may add their own secondaries here later.
    static func secondary(_ model: ShowpieceModel, shotPanelOpen: Bool) -> PhonePrimaryAction? {
        guard !shotPanelOpen, !model.menuOpen else { return nil }
        if model.openingStage == .playing {
            return PhonePrimaryAction(title: String(localized: "Skip"),
                                      hint: String(localized: "Goes straight to your own break")) {
                model.skipOpening()
            }
        }
        return nil
    }
}
