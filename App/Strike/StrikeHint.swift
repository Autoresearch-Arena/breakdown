// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: One hint, in one place (plans/25-Nov-2026-strike-panel-and-controls-plan.md, stage 3 item 5). The first
//          instruction for the input in use (FirstInstruction: on touch "Drag on the table to aim. Pull back from the
//          white ball, then push through it.") sits inside the shot panel, below the table, on every layout: in
//          ShotPanel on iPad, Mac, the open folding phone and the sideways phone, and in the upright phone's aiming
//          panel (it used to be a blurb docked over the top of the table there, and a separate card in the notebook
//          during the hand-over). It shows through the hand-over (the first minute's one instruction) and afterwards
//          until dismissed or until the first pull or shot marks it seen (the stored "aimHintSeen", unchanged).
//          A second line for the Pencil, once one has touched the table on this device (StylusPresence): "Hover to aim.
//          Stand the Pencil up as you stroke to raise the cue." That is what the code does (hover previews the aim,
//          PointerAim; standing the Pencil up past a writing grip during a stroke raises the cue, StrokeGesture), and
//          it is shown only where the cue angle is the player's (model.cueAngleIsPlayers): never for a break, a trick
//          shot, a Behind the 8-Ball situation or a lesson step that holds the angle. Dismissed with the same button,
//          remembered on its own key, so it can still appear once for a player who dismissed the first line before
//          ever picking up a Pencil.
// SRP/DRY check: Pass - checked ShotPanel's old hint (replaced by this view), OpeningCard and OpeningPhoneBlurb (their
//          hand-over copies of the instruction are gone; the instruction itself stays FirstInstruction's) and
//          ShotOptionsItems' "Show the hint again" (clears aimHintSeen, which brings this back).
import SwiftUI

struct StrikeHint: View {
    let model: ShowpieceModel
    /// The upright phone's panel: smaller type, no glass of its own (it sits on the panel's glass).
    var phone = false
    @AppStorage("aimHintSeen") private var hintSeen = false
    @AppStorage("pencilHintSeen") private var pencilHintSeen = false
    @Environment(\.palette) private var palette

    /// The Pencil line, as the plan words it.
    static var pencilLine: String {
        String(localized: "Hover to aim. Stand the Pencil up as you stroke to raise the cue.")
    }

    /// The first instruction shows through the hand-over and until it has been seen.
    private var showsInstruction: Bool { !hintSeen || model.openingStage == .handOver }

    /// The Pencil line shows once a Pencil has been used here, where the angle is the player's, until dismissed.
    private var showsPencil: Bool {
        StylusPresence.shared.seen && model.cueAngleIsPlayers && !pencilHintSeen
    }

    var body: some View {
        if showsInstruction || showsPencil {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: showsInstruction ? "hand.draw" : "pencil.tip")
                    .font(phone ? .body : .title3)
                    .foregroundStyle(palette.accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    if showsInstruction {
                        Text(FirstInstruction.line(for: model.inputInUse))
                            .font(phone ? Theme.blurbTitle : Theme.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if showsPencil {
                        Text(verbatim: Self.pencilLine)
                            .font(Theme.body)
                            .foregroundStyle(showsInstruction ? .secondary : .primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                // The first minute's instruction stays until the break is struck; after it, the hint can be put away.
                if model.openingStage != .handOver {
                    Button {
                        hintSeen = true
                        pencilHintSeen = true
                    } label: {
                        Image(systemName: "xmark").frame(width: 30, height: 30)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel("Dismiss hint")
                }
            }
            // The hint follows every text size; past about three lines of the largest size it scrolls inside its own
            // height instead of pushing the table off the screen (as the old panel hint did).
            .scrollsWhenTaller(than: 150)
            .transition(.opacity)
        }
    }
}
