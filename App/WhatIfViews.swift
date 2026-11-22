// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: The what-if replay's controls: WhatIfButton (the entry in the playback row) and WhatIfCard (the nudge
//          controls and the plain sentences, in the card slot below the table or in the notebook). 0.7.5 foundation
//          stub: both draw nothing until the whatif stream fills them; ShowpieceView and NotebookPanel already mount
//          them so the layouts stream never has to.
// SRP/DRY check: Pass - checked GhostOverlay.swift (ComparisonCard) and PlaybackControls.swift (ReplayButton); the
//          what-if card and button are new.
import SwiftUI

/// The "What if" entry beside Replay; shown only while model.whatIf.canOpen (stub: draws nothing yet).
struct WhatIfButton: View {
    let model: ShowpieceModel
    var body: some View { EmptyView() }
}

/// The what-if card in the card slot; shown only while model.whatIf.isShowing (stub: draws nothing yet).
struct WhatIfCard: View {
    let model: ShowpieceModel
    var body: some View { EmptyView() }
}
