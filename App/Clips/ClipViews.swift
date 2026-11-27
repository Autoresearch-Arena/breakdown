// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 3, the closing sweep: Theme.blurbTitle is now
//         Theme.label.)
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 10, "Achievements and sharing": the share
//          button is the top bar's worded glass control, as Back, Zoom and Menu are (TopBarControlLabel on the menu
//          glass: "Share" with its icon on big screens, the icon alone on a phone); the clip card is the panel surface
//          with the kit's button row (Share or Try again the cyan primary on the right, Cancel or Close the secondary
//          beside it) instead of glass and system button styles. The Mac's Playback menu items keep the menu bar's
//          title case.)
// PURPOSE: Every on-screen piece of Lens clips (0.7.7, plans/23-Nov-2026-clips-plan.md, Step 9):
//            ClipShareButton  - the glass "Share" control in the top bar, before the Surface/Menu control (ScreenHeader
//                               on a phone held sideways, iPad and Mac; the notebook's top bar on the open Duo, iPad and
//                               Mac). A tap makes the standard shape; a long press (on the Mac a held click) offers both.
//            ClipMenuItems    - the upright phone's More menu rows: "Share clip" and the other shape ("Share the other
//                               future" and its twin in a what-if). No new glass on the upright phone.
//            ClipCard         - the slim panel card in PlayCards (so on the open Duo and iPad it lives in the words half,
//                               never over the table): "Making your clip" with a progress bar and Cancel; "Your clip is
//                               ready" with Share and Close; or a one-line reason with Try again and Close. Slim during
//                               a guided Lens replay where the cards go slim (lensReplayCompact): title row and bar only.
//            ClipPhoneBlurb   - the same three states as a docked blurb on the upright phone (at most two buttons).
//            ClipCommandItems - the Mac's Playback menu: "Share Clip…" (Shift-Command-E) and the other shape, enabled
//                               exactly when the share button shows.
//            ClipController   - what the controller's A does for a clip card: Share when ready, Close after a failure.
//                               A never starts a clip (it would take A away from shooting after every watched shot).
//            PhonePrimaryAction.clip - the upright phone strip's "Share clip" after a remarkable shot's Watch it was
//                               used or its card closed, while the controls are still as the shot left them.
//          Nothing pops up by itself and nothing is offered in the first minute (ClipOffer decides). Every control is an
//          ordinary button with a label and hint; the progress bar carries its value for VoiceOver.
// SRP/DRY check: Pass - checked SurfaceMenuButton and TableZoomMenuButton (the top bar's worded glass controls; this
//          one wears the same TopBarControlLabel and menu glass), the kit's panel and KitButtonRow (the card's surface and
//          buttons), Blurb (the phone blurb's two forms) and MacChrome's menu titles. Every rule lives in ClipOffer,
//          every action in ClipMaker.
import SwiftUI

/// The words the clip's starts share.
@MainActor
enum ClipWords {
    static var shareClip: String { String(localized: "Share clip") }
    /// The top bar control's word (the game's existing "Share").
    static var share: String { String(localized: "Share") }
    static var hint: String { String(localized: "Makes a short video of this shot, ready to share") }

    /// A start's words for a shape: the standard shape is plain "Share clip"; the other one says which it is. In a
    /// what-if it is the other future that is shared.
    static func title(_ shape: ClipShape, whatIf: Bool) -> String {
        let standard = shape == ClipShape.standard
        if whatIf {
            if standard { return String(localized: "Share the other future") }
            return shape == .wide ? String(localized: "Share the other future, wide")
                                  : String(localized: "Share the other future, upright")
        }
        if standard { return shareClip }
        return shape == .wide ? String(localized: "Share wide clip") : String(localized: "Share upright clip")
    }
}

// MARK: The top bar's share control

/// The glass "Share" control. Shown only while a clip is offered (ClipOffer.available).
struct ClipShareButton: View {
    let model: ShowpieceModel

    var body: some View {
        if ClipOffer.available(model) {
            let whatIf = ClipOffer.isWhatIf(model)
            let standard = ClipShape.standard
            Menu {
                Button(ClipWords.title(standard, whatIf: whatIf)) { ClipOffer.start(model, shape: standard) }
                Button(ClipWords.title(standard.other, whatIf: whatIf)) { ClipOffer.start(model, shape: standard.other) }
            } label: {
                // The word on big screens and the folding phone's panel, the icon alone on a phone, like Back, Zoom
                // and Menu beside it.
                TopBarControlLabel(ClipWords.share, systemImage: "square.and.arrow.up")
                    .topBarMenuGlass()
            } primaryAction: {
                ClipOffer.start(model, shape: standard)
            }
            .menuIndicator(.hidden)
            // The label carries the glass itself (a Menu does not reliably take a custom button style); plain keeps the
            // system's accent off it.
            .menuStyle(.button)
            .buttonStyle(.plain)
            .hoverHighlight()
            .accessibilityLabel(ClipWords.shareClip)
            .accessibilityHint(ClipWords.hint)
        }
    }
}

// MARK: The upright phone's More menu

/// The More menu's clip rows: the standard shape and the other one.
struct ClipMenuItems: View {
    let model: ShowpieceModel

    var body: some View {
        if ClipOffer.available(model) {
            let whatIf = ClipOffer.isWhatIf(model)
            let standard = ClipShape.standard
            Button { ClipOffer.start(model, shape: standard) } label: {
                Label(ClipWords.title(standard, whatIf: whatIf), systemImage: "square.and.arrow.up")
            }
            .accessibilityHint(ClipWords.hint)
            Button { ClipOffer.start(model, shape: standard.other) } label: {
                Label(ClipWords.title(standard.other, whatIf: whatIf),
                      systemImage: standard.other == .wide ? "rectangle" : "rectangle.portrait")
            }
            .accessibilityHint(ClipWords.hint)
        }
    }
}

// MARK: The card (sideways phone, iPad, Mac, the open Duo)

struct ClipCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    /// A phone held upright while a guided Lens replay plays (ShowpieceView sets it): the title row and bar only.
    @Environment(\.lensReplayCompact) private var compact

    private var maker: ClipMaker { ClipMaker.shared }

    var body: some View {
        // The self-test hook needs a view that really appears: an empty Group never does, so its task never ran
        // (0.7.7 merge check). Only a launch with -clipSelfTest gets the one-point stand-in; normal play is unchanged.
        Group {
            if ClipSelfTest.requested { ClipSelfTestAnchor(model: model) }
            if !maker.isIdle { card }
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            HStack(spacing: Theme.Space.xs) {
                Image(systemName: "square.and.arrow.up")
                    .fontWeight(.medium)
                    .foregroundStyle(palette.paper2)
                    .accessibilityHidden(true)
                Text(ClipCardText.heading(maker.phase))
                    .font(Theme.heading)
                    .foregroundStyle(palette.paper)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityAddTraits(.isHeader)
            if case .making(let progress) = maker.phase {
                ProgressView(value: progress)
                    .tint(palette.accent)
                    .accessibilityLabel(String(localized: "Making your clip"))
            }
            if !compact { buttons }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // A card in the words half beside the table: the panel surface, never glass (the design's surfaces rule).
        .kitPanel()
        .transition(.opacity)
    }

    /// The kit's button row: the one primary on the right (Share, or Try again after a failure), the secondary beside
    /// it (Cancel while making, Close otherwise).
    @ViewBuilder private var buttons: some View {
        switch maker.phase {
        case .idle:
            EmptyView()
        case .making:
            KitButtonRow(secondary: KitAction(String(localized: "Cancel"), systemImage: "xmark") { maker.cancel() })
        case .ready:
            KitButtonRow(primary: KitAction(ClipWords.share, systemImage: "square.and.arrow.up") { maker.share() },
                         secondary: KitAction(String(localized: "Close"), systemImage: "xmark") { maker.close() })
        case .failed:
            KitButtonRow(primary: KitAction(String(localized: "Try again"), systemImage: "arrow.counterclockwise") {
                             maker.retry()
                         },
                         secondary: KitAction(String(localized: "Close"), systemImage: "xmark") { maker.close() })
        }
    }
}

/// The card's and blurb's heading for each phase.
@MainActor
enum ClipCardText {
    static func heading(_ phase: ClipMaker.Phase) -> String {
        switch phase {
        case .idle, .making: return String(localized: "Making your clip")
        case .ready: return String(localized: "Your clip is ready")
        case .failed(let why): return why.sentence
        }
    }
}

// MARK: The upright phone's blurb

struct ClipPhoneBlurb: View {
    let model: ShowpieceModel

    private var maker: ClipMaker { ClipMaker.shared }

    var body: some View {
        Group {
            if ClipSelfTest.requested { ClipSelfTestAnchor(model: model) }  // see ClipCard
            if !maker.isIdle { blurb }
        }
    }

    @ViewBuilder private var blurb: some View {
        switch maker.phase {
        case .idle:
            EmptyView()
        case .making(let progress):
            Blurb(accessibilityText: String(localized: "Making your clip"),
                  buttons: [BlurbButton(String(localized: "Cancel")) { maker.cancel() }]) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(String(localized: "Making your clip")).font(Theme.label)
                    ProgressView(value: progress).frame(maxWidth: 200)
                }
            }
        case .ready:
            Blurb(title: String(localized: "Your clip is ready"),
                  buttons: [BlurbButton(String(localized: "Share"), hint: ClipWords.hint) { maker.share() },
                            BlurbButton(String(localized: "Close")) { maker.close() }])
        case .failed(let why):
            Blurb(sentence: why.sentence, startsFolded: false,
                  buttons: [BlurbButton(String(localized: "Try again")) { maker.retry() },
                            BlurbButton(String(localized: "Close")) { maker.close() }])
        }
    }
}

// MARK: The Mac's Playback menu

/// "Share Clip…" and the other shape, enabled exactly when the share button shows. The model is the Playback menu's
/// optional focused value, so every use is written through it.
struct ClipCommandItems: View {
    let model: ShowpieceModel?

    var body: some View {
        let available = model.map { ClipOffer.available($0) } ?? false
        Divider()
        Button("Share Clip…") {
            if let model { ClipOffer.start(model, shape: ClipShape.standard) }
        }
        .keyboardShortcut("e", modifiers: [.command, .shift])
        .disabled(!available)
        if ClipShape.standard == .wide {
            Button("Share Upright Clip…") {
                if let model { ClipOffer.start(model, shape: .upright) }
            }
            .disabled(!available)
        } else {
            Button("Share Wide Clip…") {
                if let model { ClipOffer.start(model, shape: .wide) }
            }
            .disabled(!available)
        }
    }
}

// MARK: The controller

@MainActor
enum ClipController {
    /// A on a clip card: Share when the clip is ready, Close after a failure; true when it was used. Never starts a
    /// clip and never acts while one is being made (Cancel is a deliberate touch).
    static func pressA(_ model: ShowpieceModel) -> Bool {
        let maker = ClipMaker.shared
        switch maker.phase {
        case .ready:
            maker.share()
            return true
        case .failed:
            maker.close()
            return true
        case .idle, .making:
            return false
        }
    }
}

// MARK: The upright phone's primary action

extension PhonePrimaryAction {
    /// "Share clip" after a remarkable shot once its Watch it was used or its card closed, the controls untouched.
    static func clip(_ model: ShowpieceModel) -> PhonePrimaryAction? {
        guard ClipOffer.afterWatch(model) else { return nil }
        return PhonePrimaryAction(title: ClipWords.shareClip, hint: ClipWords.hint) { ClipOffer.start(model) }
    }
}
