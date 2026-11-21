// Author: Claude Opus 5.5 High
// Date: 20-November-2026
// Edited: Claude Haiku 5.5 High, 20-November-2026 (strings that are built in code, such as the card lines, the spoken row
//          label and the "Coming next" line, are String(localized:); literal labels and buttons are already keys)
// Edited: Claude Opus 5.5 High, 21-November-2026 (the -trickAim store-screenshot flag.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (the list shows each shot's place in the easiest-first order,
//          TrickShots.listNumber, instead of its authored number)
// PURPOSE: Everything the player sees of trick-shot mode, kept small so the table stays big:
//          TrickShotList - the list of the ten trick shots, in a sheet from the menu: number (or a tick once made),
//            title, hook and difficulty; the two that wait on new physics show as "Coming next" and cannot be opened.
//          TrickShotCard - one compact glass card at the bottom edge, above the controls (or at the top of the side
//            column on iPad, Mac and landscape): the hook and Watch it / Your turn; the one idea while the answer
//            replays in the Lens, with the maths behind a button; Made it or Missed with one line on what to change,
//            Try again and Next shot. One or two lines of text and one row of buttons.
//          TrickTableLayer - laid over the 3D table, never taking touches: rings on the balls the shot names and on the
//            pockets they must drop in, and a short glow around the screen when a shot is made. It also hosts the list
//            sheet, handles the launch flags (-trickList, -trick <id>, -trickPlay <id>), forwards the model's playback
//            changes to TrickShotMode.update(), and opens or closes the shot panel when the mode asks.
//          Standard controls throughout (Liquid Glass buttons, a List, SF Symbols), Dynamic Type (button rows fall back
//          to two rows and the text wraps), VoiceOver labels, and Reduce Motion (the glow fades without movement; the
//          card changes without animation).
// SRP/DRY check: Pass - views only. Flow is TrickShotMode, data TrickShots; projection to the screen is AimProjector
//          (as in GhostOverlay and AimOverlay); card styling is the shared glassCard.
import BreakdownLensModel
import BreakdownPhysics
import SwiftUI

// MARK: The list

struct TrickShotList: View {
    let mode: TrickShotMode
    @Environment(\.palette) private var palette

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(TrickShots.all) { shot in
                        Button { mode.begin(shot) } label: { row(shot) }
                            .disabled(shot.pending)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(spoken(shot))
                            .accessibilityHint(shot.pending ? "" : "Sets up the shot on the table")
                    }
                } footer: {
                    Text("Watch each shot, see the physics behind it in the Lens, then make it yourself.")
                }
            }
            .navigationTitle("Trick shots")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { mode.listOpen = false } }
            }
        }
        .tint(palette.accent)
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 560)
        #endif
    }

    private func row(_ shot: TrickShot) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            ZStack {
                if mode.isDone(shot) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(palette.accent)
                } else if shot.pending {
                    Image(systemName: "lock.fill").foregroundStyle(.secondary)
                } else {
                    Text("\(TrickShots.listNumber(of: shot))").font(Theme.equation).foregroundStyle(palette.accent)
                }
            }
            .font(.title3)
            .frame(minWidth: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(shot.title).font(Theme.heading).foregroundStyle(shot.pending ? .secondary : .primary)
                Text(shot.pending ? String(localized: "Coming next. \(shot.hook)") : shot.hook)
                    .font(Theme.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(shot.difficulty.label)
                    .font(Theme.label)
                    .foregroundStyle(palette.slide)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private func spoken(_ shot: TrickShot) -> String {
        let state = shot.pending ? String(localized: "coming next")
            : (mode.isDone(shot) ? String(localized: "made") : String(localized: "not made yet"))
        return String(localized: "Shot \(TrickShots.listNumber(of: shot)), \(shot.title), \(shot.difficulty.label), \(state). \(shot.hook)")
    }
}

// MARK: The card

struct TrickShotCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    private var mode: TrickShotMode { model.trickMode }

    var body: some View {
        if let shot = mode.current, mode.isActive {
            VStack(alignment: .leading, spacing: 8) {
                content(shot)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(cornerRadius: 22, padding: 12)
            .tint(palette.accent)
            .animation(reduceMotion ? nil : .snappy, value: mode.phase)
            // One success haptic per make; the Vibration option is read at the moment it fires.
            .sensoryFeedback(trigger: mode.celebrations) { _, _ in GameSettings.hapticsOn ? .success : nil }
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private func content(_ shot: TrickShot) -> some View {
        switch mode.phase {
        case .ready:
            header(shot)
            line(shot.hook)
            buttons {
                watchButton(prominent: false)
                turnButton(prominent: true)
                listButton
            }
        case .watching:
            header(shot)
            line(String(localized: "Watch the answer. \(shot.goalLine)"))
            buttons { turnButton(prominent: false) }
        case .explaining:
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill").foregroundStyle(palette.slide).accessibilityHidden(true)
                Text("The idea").font(Theme.label).foregroundStyle(palette.slide)
            }
            line(shot.idea)
            if mode.showMaths, let maths = shot.maths {
                Text(maths)
                    .font(Theme.equation)
                    .foregroundStyle(palette.paper)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("The maths: \(shot.mathsSpoken ?? maths)")
            }
            buttons {
                if shot.maths != nil {
                    Button { mode.showMaths.toggle() } label: {
                        Label(mode.showMaths ? "Hide the maths" : "Show the maths", systemImage: "function")
                            .labelStyle(.iconOnly).frame(minWidth: 30, minHeight: Self.buttonHeight)
                    }
                    .buttonStyle(.glass).buttonBorderShape(.circle)
                    .accessibilityLabel(mode.showMaths ? "Hide the maths" : "Show the maths")
                }
                watchButton(prominent: false, again: true)
                turnButton(prominent: true)
            }
        case .aiming:
            header(shot)
            line(shot.usesBridge ? String(localized: "\(shot.goalLine) The ball is out of reach, so the bridge holds the cue.")
                                 : shot.goalLine)
            buttons {
                watchButton(prominent: false)
                listButton
            }
        case .judged(let verdict):
            HStack(spacing: 8) {
                Image(systemName: verdict.made ? "checkmark.seal.fill" : "arrow.uturn.backward.circle")
                    .foregroundStyle(verdict.made ? palette.accent : palette.slide)
                    .accessibilityHidden(true)
                Text(verdict.made ? "Made it!" : "Missed").font(Theme.heading)
            }
            .accessibilityElement(children: .combine)
            line(verdict.line)
            buttons {
                if verdict.made {
                    tryAgainButton(prominent: false)
                    Button { mode.next() } label: {
                        Label("Next shot", systemImage: "arrow.right").font(.headline).lineLimit(1)
                            .frame(minHeight: Self.buttonHeight)
                    }
                    .buttonStyle(.glassProminent).foregroundStyle(palette.ground)
                    .keyboardShortcut(.defaultAction)
                } else {
                    watchButton(prominent: false)
                    tryAgainButton(prominent: true)
                }
            }
        case .offScript:
            header(shot)
            line(String(localized: "That shot started from where the balls stopped. Try again puts them back for the trick."))
            buttons { tryAgainButton(prominent: true); listButton }
        case .off:
            EmptyView()
        }
    }

    // MARK: Pieces

    private func header(_ shot: TrickShot) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(shot.title).font(Theme.heading).lineLimit(2)
            Spacer(minLength: 0)
            Text(shot.difficulty.label).font(Theme.label).foregroundStyle(palette.slide)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func line(_ text: String) -> some View {
        Text(text)
            .font(Theme.body)
            .foregroundStyle(palette.paper.opacity(0.9))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// One row of buttons, right-aligned; two rows when the text is too large for one.
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

    private func watchButton(prominent: Bool, again: Bool = false) -> some View {
        styled(Button { mode.watch() } label: {
            Label(again ? "Watch again" : "Watch it", systemImage: again ? "arrow.counterclockwise" : "play.fill")
                .font(.headline).lineLimit(1).frame(minHeight: Self.buttonHeight)
        }, prominent: prominent)
        .accessibilityHint("Plays the answer, then explains it in the Physics Lens")
    }

    private func turnButton(prominent: Bool) -> some View {
        styled(Button { mode.yourTurn() } label: {
            Label("Your turn", systemImage: "target").font(.headline).lineLimit(1).frame(minHeight: Self.buttonHeight)
        }, prominent: prominent)
        .accessibilityHint("Puts the balls back and opens the aiming controls")
    }

    private func tryAgainButton(prominent: Bool) -> some View {
        styled(Button { mode.tryAgain() } label: {
            Label("Try again", systemImage: "arrow.uturn.backward").font(.headline).lineLimit(1)
                .frame(minHeight: Self.buttonHeight)
        }, prominent: prominent)
        .accessibilityHint("Puts the balls back where the shot started, with your last aim, power and spin")
    }

    private var listButton: some View {
        Button { mode.listOpen = true } label: {
            Label("All trick shots", systemImage: "list.bullet").labelStyle(.iconOnly)
                .frame(minWidth: 30, minHeight: Self.buttonHeight)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel("All trick shots")
    }

    @ViewBuilder
    private func styled(_ button: some View, prominent: Bool) -> some View {
        if prominent {
            // Dark text on the bright accent: white on cyan is too faint (as the Shoot button).
            button.buttonStyle(.glassProminent).foregroundStyle(palette.ground)
        } else {
            button.buttonStyle(.glass)
        }
    }

    /// The glass button adds its own padding; this lands the buttons on 44 points or more on a touch screen.
    #if os(iOS)
    private static let buttonHeight: CGFloat = 30
    #else
    private static let buttonHeight: CGFloat = 0
    #endif
}

// MARK: Over the table

struct TrickTableLayer: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    @Binding var shotPanelOpen: Bool
    @Environment(\.inlinePages) private var inlinePages
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var cameraBox = AimProjector.CameraBox()
    @State private var glow = 0.0

    private var mode: TrickShotMode { model.trickMode }
    @MainActor private static var launchHandled = false

    var body: some View {
        @Bindable var mode = mode
        ZStack {
            if mode.markers != nil {
                TimelineView(.animation) { _ in
                    Canvas { ctx, size in drawMarkers(&ctx, size: size) }
                }
            }
            // The make: a short glow around the edge of the screen. It only fades, so it is the same with Reduce Motion.
            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .strokeBorder(palette.accent, lineWidth: 6)
                .blur(radius: 10)
                .opacity(glow)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .accessibilityHidden(true)
        // On a folding phone the list is a page of the side panel (inlinePages), so the table is never covered. The setter
        // ignores the dismissal SwiftUI sends when the screen turns into that layout just after launch; it would close the list.
        .sheet(isPresented: Binding(get: { mode.listOpen && !inlinePages }, set: { if !inlinePages { mode.listOpen = $0 } })) { TrickShotList(mode: mode) }
        .onAppear(perform: handleLaunchFlags)
        // The mode learns that a shot finished from these two; it ignores anything that is not its business.
        .onChange(of: model.aimReady) { _, _ in mode.update() }
        .onChange(of: model.timelineVersion) { _, _ in mode.update() }
        .onChange(of: mode.aimingRequests) { _, _ in shotPanelOpen = mode.wantsAiming }
        .onChange(of: mode.celebrations) { _, _ in
            glow = 1
            withAnimation(.easeOut(duration: reduceMotion ? 0.8 : 1.4)) { glow = 0 }
        }
    }

    /// -trickList opens the list over the menu; -trick <id> sets a shot up; -trickPlay <id> also plays the answer;
    /// -trickAim <id> lines the answer up with aiming open and plays nothing (for store screenshots).
    private func handleLaunchFlags() {
        // Once per launch: the layer is rebuilt when the screen switches between its narrow and wide layouts.
        guard !Self.launchHandled else { return }
        Self.launchHandled = true
        let args = ProcessInfo.processInfo.arguments
        func value(after flag: String) -> String? {
            guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
            return args[i + 1]
        }
        if let id = value(after: "-trick") { mode.begin(id: id) }
        if let id = value(after: "-trickPlay") { mode.begin(id: id); mode.watch() }
        if let id = value(after: "-trickAim") { mode.begin(id: id); mode.lineUpAnswer() }
        // Last, so -trick <id> -trickList shows the list over that shot's table (begin closes the list).
        // A moment late: on a folding phone the screen first lays out as an ordinary one and turns into the fold layout a
        // beat later, and a list opened in the first beat is closed again by that change.
        if args.contains("-trickList") {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.2))
                mode.listOpen = true
            }
        }
    }

    /// Rings on the balls the shot names (where they rest now) and on the pockets they must drop in.
    private func drawMarkers(_ ctx: inout GraphicsContext, size: CGSize) {
        guard let marks = mode.markers, model.aimReady, model.layout.count == 16, let root = bridge.table?.root,
              let proj = AimProjector(camera: cameraBox.find(in: root), size: size, frame: TableFrame(model.timeline.table))
        else { return }
        let table = model.timeline.table
        func ring(_ centre: Vec2, _ radius: Double) -> Path? {
            var path = Path()
            for i in 0..<40 {
                let a = Double(i) / 40 * 2 * Double.pi
                guard let s = proj.screen(centre + Vec2(cos(a), sin(a)) * radius, height: 0.001) else { return nil }
                if i == 0 { path.move(to: s) } else { path.addLine(to: s) }
            }
            path.closeSubpath()
            return path
        }
        for k in marks.pockets where k < table.pockets.count {
            if let p = ring(table.pockets[k], table.pocketCaptureRadius[k] + 0.012) {
                ctx.stroke(p, with: .color(palette.accent.opacity(0.35)), style: StrokeStyle(lineWidth: 7))
                ctx.stroke(p, with: .color(palette.accent), style: StrokeStyle(lineWidth: 2))
            }
        }
        for b in marks.balls where NextShot.isOnTable(model.layout[b]) {
            if let p = ring(model.layout[b], table.ballRadius * 1.45) {
                ctx.stroke(p, with: .color(palette.accent.opacity(0.9)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            }
        }
    }
}
