// Author: Claude Sonnet 5.5 Medium
// Date: 21-November-2026
// PURPOSE: The iPhone Duo's live commentary: every explained moment of the shot on screen, in clock order, as a list
//          that fills the side panel. Each row is a caption (title, the whole sentence, and the equation when Show the
//          maths is on) with the time it happens; the one for the moment on the table is lit and kept in view, the
//          rest are dimmed, and tapping a row jumps the replay to that moment. The lit row also gives the thin leader
//          line to the ball it describes its starting rectangle (the same job CaptionArea does in the other layouts),
//          so the line crosses the fold from the words to the table. Captions are the ones the Physics Lens already
//          uses (CaptionEngine), read from the model; nothing here is worked out again, so every number on the panel is
//          a number the solver produced.
//          Follows the Explanations option: with it off the list is not drawn.
// SRP/DRY check: Pass - display only. Wording is Captions.swift, the clock and the jump are ShowpieceModel; the lit row
//          is found by a probe view so the list itself redraws only when the lit caption changes, not every frame.
import BreakdownLensModel
import SwiftUI

struct DuoStory: View {
    let model: ShowpieceModel
    let leader: LeaderState
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(GameSettings.mathsKey) private var maths = false
    @AppStorage(GameSettings.explanationsKey) private var explanations = true
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
                    // Before any shot: what is coming, and the surface and table it will be played on.
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Once the balls move, every hit is explained here.")
                                .font(Theme.body)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            DuoSurfaceCard(model: model, detailed: true)
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

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("Step by step")
                .font(Theme.label)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            if model.lensOn { LensLegendChip().transition(.opacity) }
        }
        .animation(.easeOut(duration: 0.25), value: model.lensOn)
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
                        .font(Theme.body)
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
                                    numberFormatStyle: .number.precision(.fractionLength(2))))
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
