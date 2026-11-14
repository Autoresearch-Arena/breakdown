// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: What makes the Mac build feel like a Mac app, and what iPad gains with a hardware keyboard: a real window
//          toolbar (play, speed, Lens, replay, Your shot), a Playback menu with keyboard shortcuts (space plays or
//          pauses, Command-R replays, Command-L toggles the Lens, Command-1 to 4 pick the speed, Command-Y opens the
//          shot panel), and the plumbing that lets menu items reach the window's model. The toolbar reuses the play,
//          replay and speed controls from PlaybackControls and uses the system's own toggle buttons for Lens and
//          Your shot, which draw their pressed state natively in a Mac toolbar. Writes to the model only through its
//          public methods.
// SRP/DRY check: Pass - menu and toolbar only; checked PlaybackControls, whose play, replay and speed pieces are reused here.
import SwiftUI

// MARK: Plumbing: menu commands find the front window's model through focused values.

extension FocusedValues {
    @Entry var showpieceModel: ShowpieceModel?
    @Entry var shotPanelOpen: Binding<Bool>?
}

// MARK: Menu commands

struct PlaybackCommands: Commands {
    @FocusedValue(\.showpieceModel) private var model
    @FocusedValue(\.shotPanelOpen) private var shotPanelOpen

    var body: some Commands {
        CommandMenu("Playback") {
            let isPlaying = (model?.playing ?? false) && (model?.time ?? 0) < (model?.duration ?? 0)
            Button(isPlaying ? "Pause" : "Play") { model?.togglePlay() }
                .keyboardShortcut(.space, modifiers: [])
            Button("Replay with Lens") { model?.replay(withLens: true) }
                .keyboardShortcut("r", modifiers: .command)
            Button((model?.lensOn ?? false) ? "Hide Lens" : "Show Lens") { model?.setLens(!(model?.lensOn ?? false)) }
                .keyboardShortcut("l", modifiers: .command)
            Divider()
            Menu("Speed") {
                ForEach(Array(PlaybackSpeed.rates.enumerated()), id: \.offset) { index, rate in
                    Button(PlaybackSpeed.label(rate)) { model?.setRate(rate) }
                        .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                }
            }
            Divider()
            Button("Your Shot") { shotPanelOpen?.wrappedValue.toggle() }
                .keyboardShortcut("y", modifiers: .command)
        }
    }
}

// MARK: Toolbar (Mac window)

#if os(macOS)
struct ShowpieceToolbar: ToolbarContent {
    let model: ShowpieceModel
    @Binding var shotPanelOpen: Bool

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            PlayPauseButton(model: model).labelStyle(.iconOnly).help("Play or pause (space)")
            ReplayButton(model: model).labelStyle(.iconOnly).help("Replay with the Lens (Command-R)")
        }
        ToolbarItem(placement: .principal) {
            SpeedPicker(model: model).frame(minWidth: 220).help("Playback speed (Command-1 to 4)")
        }
        ToolbarItemGroup(placement: .primaryAction) {
            // Real toggles: the system draws the pressed state, so on and off are visible in the toolbar.
            Toggle(isOn: Binding(get: { model.lensOn }, set: { model.setLens($0) })) {
                Label("Lens", systemImage: "viewfinder")
            }
            .toggleStyle(.button)
            .help("Show the Physics Lens (Command-L)")
            Toggle(isOn: $shotPanelOpen) { Label("Your shot", systemImage: "target") }
                .toggleStyle(.button)
                .help("Take your own shot (Command-Y)")
        }
    }
}
#endif
