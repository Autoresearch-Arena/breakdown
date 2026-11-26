// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: Zoom without a gesture (plans/25-Nov-2026-everyone-can-play-plan.md, Part B items 2 and 3). The table zooms by
//          pinch, two-finger drag and double tap (TableZoomGestures); a player who cannot pinch or double-tap had only
//          the Mac's View menu and VoiceOver's actions. This adds the same zoom as plain menu entries, on every layout:
//          - TableZoomMenuItems: Zoom in on the white ball (the double tap's close-up, centred on the striking ball),
//            Zoom in, Zoom out, Whole table. The same TableZoom calls the gestures and the View menu make (focus,
//            zoomStep, actualSize), so the zoom behaves exactly as it does by hand.
//          - TableZoomMenuButton: a round glass button the size of the back button, in the title row over the table
//            (ShowpieceView's ScreenHeader) and in the notebook's top bar (NotebookPanel), opening those entries.
//            The upright phone lists them under Zoom in its More menu (PhoneTitleRow).
//          - The zoomBridge environment value: the scene bridge (ShowpieceView hands it down once), since the zoom lives
//            on the table scene (SceneBridge.table.zoom), as the View menu finds it through its focused value.
//          The entries are always listed (a step that cannot zoom further does nothing, as the View menu's do), so the
//          menu never has to follow the zoom's state. Nothing here moves while a ball travels except the camera.
// SRP/DRY check: Pass - checked TableZoom (all zoom state and clamping stay there; only its public calls are made),
//          MacChrome (the View menu's Zoom In, Zoom Out and Actual Size, the same three calls), TableAccessLayer
//          (VoiceOver's Zoom in on the cue ball: the same focus on the striking ball; its private positions are not
//          shared, so the white ball's place is read here the same way, from the layout at rest or the recording at
//          the clock) and SurfaceMenuButton (the round glass button's look, matched, not copied).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import SwiftUI

extension EnvironmentValues {
    /// The scene bridge, for the zoom menu (TableZoomMenuItems): its table holds the zoom. Set once by ShowpieceView;
    /// nil elsewhere (a preview, a page shown outside the game), where the zoom entries do nothing.
    @Entry var zoomBridge: SceneBridge? = nil
}

/// The zoom entries for any menu.
struct TableZoomMenuItems: View {
    let model: ShowpieceModel
    @Environment(\.zoomBridge) private var bridge

    var body: some View {
        Button {
            focusWhiteBall()
        } label: {
            Label(TableZoomWords.onWhiteBall, systemImage: "scope")
        }
        Button {
            bridge?.table?.zoom.zoomStep(1)
        } label: {
            Label(TableZoomWords.zoomIn, systemImage: "plus.magnifyingglass")
        }
        Button {
            bridge?.table?.zoom.zoomStep(-1)
        } label: {
            Label(TableZoomWords.zoomOut, systemImage: "minus.magnifyingglass")
        }
        Button {
            bridge?.table?.zoom.actualSize()
        } label: {
            Label(TableZoomWords.wholeTable, systemImage: "rectangle.dashed")
        }
    }

    /// The double tap's close-up on the striking ball (as VoiceOver's Zoom in on the cue ball does).
    private func focusWhiteBall() {
        guard let zoom = bridge?.table?.zoom, let p = Self.strikingBall(model) else { return }
        let w = TableFrame(model.timeline.table).world(p.place)
        zoom.focus(on: SIMD2(w.x, w.z), ball: p.ball)
    }

    /// The striking ball and where it is now: in the next shot's layout once the shot on screen has played out, else in
    /// the recording at the clock. Nil when it is off the table.
    static func strikingBall(_ model: ShowpieceModel) -> (ball: Int, place: Vec2)? {
        let ball = model.strikeBall
        if model.aimReady, model.layout.indices.contains(ball) {
            let p = model.layout[ball]
            return NextShot.isOnTable(p) ? (ball, p) : nil
        }
        let tl = model.timeline
        guard ball < tl.ballCount else { return nil }
        let s = tl.state(ball: ball, at: model.time)
        return s.pocketed ? nil : (ball, s.position)
    }
}

/// The round glass zoom button for the title row and the notebook's top bar.
struct TableZoomMenuButton: View {
    let model: ShowpieceModel

    var body: some View {
        Menu {
            TableZoomMenuItems(model: model)
        } label: {
            Label(TableZoomWords.zoom, systemImage: "plus.magnifyingglass")
                .labelStyle(.iconOnly)
                .font(.body.weight(.semibold))
                .frame(width: 22, height: 22)
        }
        .menuIndicator(.hidden)
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.regular)
        .hoverHighlight()
        .accessibilityLabel(TableZoomWords.zoom)
    }
}

/// The zoom menu's words, through String(localized:). "Zoom" and "Zoom out" are the game's existing lines; the rest are
/// in localization/pending/v0710-everyone.json.
enum TableZoomWords {
    static var zoom: String { String(localized: "Zoom") }
    static var onWhiteBall: String { String(localized: "Zoom in on the white ball") }
    static var zoomIn: String { String(localized: "Zoom in") }
    static var zoomOut: String { String(localized: "Zoom out") }
    static var wholeTable: String { String(localized: "Whole table") }
}
