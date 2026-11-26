// Author: Claude Sonnet 5.5 Medium
// Date: 21-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 strike: the placeholder line "Once the balls move..." is
//          removed; the notebook's slot shows the strike panel while aiming (StrikeSlot) and this view while the balls move.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 layouts items 6 and 7, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md:
//          during the opening (and its hand-over) the story shows only its one line, not the surface card's friction
//          constants and rail percentage, so the first screen is a racked table and one instruction; the Lens colour
//          key left this header for its own row under the notebook's top bar (NotebookPanel), shown with the Lens up
//          whether Explanations is on or off.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (renamed NotebookStory, file NotebookStory.swift (it was DuoStory, DuoStory.swift): it is the notebook's
//          commentary on every big screen now, not only across a folding phone's hinge. On a big screen
//          (notebookRoomy) each sentence is set a size larger for reading at arm's length or at a desk; rows brighten
//          under a pointer; and the Mac and an iPad keyboard can step to the next or previous moment from the Playback
//          menu (MacChrome), which moves the lit row here like a tap.)
// PURPOSE: The notebook's live commentary: every explained moment of the shot on screen, in clock order, as a list
//          that fills the side panel. Each row is a caption (title, the whole sentence, and the equation when Show the
//          maths is on) with the time it happens; the one for the moment on the table is lit and kept in view, the
//          rest are dimmed, and tapping a row jumps the replay to that moment. The lit row also gives the thin leader
//          line to the ball it describes its starting rectangle (the same job CaptionArea does in the other layouts),
//          so the line crosses the fold from the words to the table. Captions are the ones the Physics Lens already
//          uses (CaptionEngine), read from the model; nothing here is worked out again, so every number on the panel is
//          a number the solver produced.
//          Follows the Explanations option: with it off the list is not drawn.
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (numbers are written in the game's own language, AppLocale.numbers
//          in NumberStyle.swift: French and German get "6,7" even on a phone set to another region.)
// SRP/DRY check: Pass - display only. Wording is Captions.swift, the clock and the jump are ShowpieceModel; the lit row
//          is found by a probe view so the list itself redraws only when the lit caption changes, not every frame.
import BreakdownLensModel
import SwiftUI

struct NotebookStory: View {
    let model: ShowpieceModel
    let leader: LeaderState
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(GameSettings.mathsKey) private var maths = false
    @AppStorage(GameSettings.explanationsKey) private var explanations = true
    @Environment(\.notebookRoomy) private var roomy
    /// The caption lit now: the one the table is showing, or the one just tapped.
    @State private var activeID: Int?

    /// True once a shot with a real strike is on the timeline. Before the first shot (and on a trick shot that has not been
    /// watched) the recording is only the balls at rest, and its one caption would read "0.0 metres per second".
    static func hasShot(_ model: ShowpieceModel) -> Bool {
        for e in model.timeline.events where e.kind == .cueStrike {
            if let b = e.balls.first, b.velocityAfter.length > 0.05 { return true }
        }
        return false
    }

    private var captions: [Caption] { Self.hasShot(model) ? model.captions : [] }

    var body: some View {
        if explanations {
            VStack(alignment: .leading, spacing: 8) {
                header
                if captions.isEmpty {
                    // Before any shot: what is coming, and the surface and table it will be played on. While the opening
                    // runs (the first minute's break and hand-over) only the one line shows: the numbers wait until the
                    // player is playing, so nothing competes with the hand-over's one instruction.
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            // 0.7.10 strike: the placeholder line is gone. While the player aims the notebook's slot
                            // shows the strike panel here instead (StrikeSlot, App/Strike/StrikePanel.swift); this empty
                            // page is left for the first minute and for "Your shot" closed before any shot.
                            if model.openingStage == .none {
                                NotebookSurfaceCard(model: model, detailed: true)
                            }
                        }
                    }
                    .scrollBounceBehavior(.basedOnSize)
                } else {
                    list
                }
            }
            .frame(minHeight: 120, alignment: .top)
            .background { ActiveProbe(model: model, activeID: $activeID) }
            // With no lit row, or the Lens down, the leader must not keep an old rectangle: CaptionLeader hides the
            // ring of any ball inside it.
            .onChange(of: showsLeader) { _, now in if !now { leader.card = .zero } }
            .onDisappear { leader.card = .zero }
        }
    }

    private var showsLeader: Bool { model.lensOn && activeID != nil }

    /// The list's heading. The Lens colour key is not here: it has its own row under the panel's top bar, so it shows
    /// with Explanations off too (NotebookPanel, 0.7.5).
    private var header: some View {
        Text("Step by step")
            .font(Theme.label)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(captions) { caption in
                        row(caption, lit: caption.id == activeID).id(caption.id)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollBounceBehavior(.basedOnSize)
            // The rows above and below the visible ones fade out, so a row cut by the edge reads as "more", not as a glitch.
            .mask {
                LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.05),
                                       .init(color: .black, location: 0.9), .init(color: .clear, location: 1)],
                               startPoint: .top, endPoint: .bottom)
            }
            .onChange(of: activeID) { _, id in
                guard let id else { return }
                withAnimation(reduceMotion ? nil : .smooth(duration: 0.35)) { proxy.scrollTo(id, anchor: .center) }
            }
        }
    }

    // MARK: A row

    private func row(_ caption: Caption, lit: Bool) -> some View {
        let accent = palette.color(for: caption.accent)
        return Button {
            activeID = caption.id
            model.scrub(to: caption.time)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Capsule().fill(accent.opacity(lit ? 1 : 0.35)).frame(width: 3)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(verbatim: caption.title)
                            .font(Theme.heading)
                            .foregroundStyle(lit ? Color.primary : Color.secondary)
                        Spacer(minLength: 4)
                        Text(verbatim: Self.timeText(caption.time))
                            .font(Theme.number)
                            .foregroundStyle(.secondary)
                    }
                    Text(verbatim: caption.detail)
                        // A size up on a big screen, read from further away than a phone; the folding phone keeps its own.
                        .font(roomy ? Theme.copy : Theme.body)
                        .foregroundStyle(lit ? Color.primary : Color.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if maths {
                        Text(verbatim: caption.equation)
                            .font(Theme.equation)
                            .foregroundStyle(accent.opacity(lit ? 1 : 0.6))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(accent.opacity(lit ? 0.14 : 0), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // A plain row has no shape of its own, so under a pointer it gets a faint fill to show it can be clicked.
        .hoverHighlight(.fill(cornerRadius: 12))
        // The lit row is where the leader line starts, in the stage's own coordinates (the line crosses the fold).
        .background {
            if lit {
                Color.clear.onGeometryChange(for: CGRect.self) { $0.frame(in: .named(StageSpace.name)) } action: { frame in
                    if model.lensOn { leader.card = frame }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption.title). \(caption.detail)")
        .accessibilityValue(maths ? caption.equation : "")
        .accessibilityHint("Jumps the replay to this moment")
        .accessibilityAddTraits(lit ? [.isButton, .isSelected] : .isButton)
    }

    /// "0.42 sec": the moment's time on the shot's clock, in the player's units.
    private static func timeText(_ t: Double) -> String {
        Measurement(value: t, unit: UnitDuration.seconds)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided,
                                    numberFormatStyle: .number.locale(AppLocale.numbers).precision(.fractionLength(2))).locale(AppLocale.numbers))
    }
}

/// Reads the clock for the list: re-evaluated every frame (it reads the model's time) but writes only when the caption
/// on the table changes, so the list and its rows are not redrawn sixty times a second. Before the first caption of a
/// replay nothing is lit; between captions the last one stays lit, as the strip under the table does on a phone.
private struct ActiveProbe: View {
    let model: ShowpieceModel
    @Binding var activeID: Int?

    var body: some View {
        let now = model.activeCaption()?.id
        let beforeFirst = model.captions.first.map { model.time < $0.time } ?? true
        return Color.clear
            .frame(width: 0, height: 0)
            .onChange(of: now, initial: true) { _, id in
                if let id { activeID = id } else if beforeFirst { activeID = nil }
            }
            .onChange(of: model.timelineVersion) { _, _ in activeID = nil }
    }
}
