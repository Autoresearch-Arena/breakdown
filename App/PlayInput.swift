// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Which way the player is playing right now (plans/21-Nov-2026-bugs-after-0-6-6-plan.md items 1 and 51;
//          contract docs/v07-contracts.md section 1.4). The first instruction was written for one input only ("Drag to
//          aim, pull back, let go"), which is wrong on touch, where only a push through the cue ball plays. 0.7.0 gives
//          each input its own instruction, and the hand-over card, the shot panel's hint, How to play and the spoken
//          announcement pick it by the input in use. Each input route records itself on the model
//          (ShowpieceModel.inputInUse) when it is used; the words are the menu stream's (OpeningHandover).
//          A code only: no words, no state, no isolation.
// SRP/DRY check: Pass - checked StrokeGesture (finger and Pencil), PointerAim (pointer and hover), ControllerInput and
//          MacChrome (keys); none of them recorded which input was in use, and nothing else in the app does.
import Foundation

enum PlayInput: String, CaseIterable, Sendable {
    /// A finger, or the Pencil touching the glass: aim by dragging, stroke by pulling back and pushing through.
    case touch
    /// A mouse, trackpad or the iPad pointer: aim by clicking or dragging on the cloth, pull back and let go.
    case pointer
    /// The keyboard alone (arrow keys and Return).
    case keyboard
    /// A game controller.
    case controller
}
