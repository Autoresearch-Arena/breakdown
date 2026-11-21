// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The table as VoiceOver and Switch Control find it (accessibility plan, packages 1 and 3).
//          TableAccessLayer lays one invisible accessibility element over each ball and each pocket of the 3D table,
//          at the place the ball or pocket really is on screen, so touch exploration finds a ball where it sits and
//          swiping goes cue ball first, then the other balls nearest first, then the pockets. Each ball says its name
//          and where it is (TableWords); each pocket its name and whether a ball can be potted in it cleanly. A first,
//          table-wide element carries the table's name, the view (table or Physics Lens), how many balls are up, and
//          the "Step through the shot" actions. Positions come from the live camera through AimProjector, refreshed
//          twice a second (fast enough to follow a replay by touch, and nothing runs at all while no assistive
//          technology is on). The elements take no touches, so aiming drags pass straight through.
//          ShotNarration speaks: the summary when a shot finishes, each explained moment when stepping through, the
//          match ruling. Announcements are posted with SwiftUI's AccessibilityNotification.
//          Used by TableStage (the table, with step-through) and AimOverlay (while aiming: double-tap a ball to aim at
//          it, a pocket to aim the pot). Reads the model; writes it only by scrubbing the replay.
// SRP/DRY check: Pass - checked CaptionViews.LeaderState (projects one ball per frame through the RealityView's own
//          projector for the caption ring) and AimOverlay (projects through AimProjector); this layer reuses
//          AimProjector rather than adding work to the per-frame scene closure. The words are TableWords; the caption
//          list for stepping is the model's (the same list DuoStory shows).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import SwiftUI

// MARK: Speaking

@MainActor
enum ShotNarration {
    /// Speak a sentence now (VoiceOver; ignored when no screen reader is running).
    static func announce(_ text: String) {
        guard !text.isEmpty else { return }
        AccessibilityNotification.Announcement(text).post()
    }

    /// The layout the shot on screen started from: the player's attempt when there is one, else the recording's own
    /// first frame (the showpiece break has no attempt). Balls gone at the start read as off the table.
    static func start(of model: ShowpieceModel) -> [Vec2] {
        if let attempt = model.currentAttempt { return attempt.start }
        let tl = model.timeline
        return (0..<tl.ballCount).map { b in
            let s = tl.state(ball: b, at: 0)
            return s.pocketed ? NextShot.offTable : s.position
        }
    }

    /// The finished shot in one to three sentences, with the striking player's ball as the cue ball in a match.
    static func summary(of model: ShowpieceModel) -> String {
        TableWords.summary(timeline: model.timeline, start: start(of: model), cueBall: model.match?.cueBallIndex ?? 0)
    }

    /// Called once a frame by TableStage's scene update (not from a view body, so reading the clock here redraws
    /// nothing). When a shot has played out and a screen reader is on, speaks its summary once per recording. In a
    /// match it waits for the ruling and says both together, because a second announcement would cut off the first;
    /// at the start of a match it says who breaks.
    static func frame(model: ShowpieceModel, bridge: SceneBridge) {
        guard bridge.speaks, !model.menuOpen else { return }
        if let match = model.match {
            if !bridge.matchStartSpoken, match.state.isBreak, match.state.shotCount == 0,
               let player = match.state.currentPlayer {
                bridge.matchStartSpoken = true
                announce(String(localized: "\(player.name) to break."))
            } else if match.state.shotCount > 0 {
                // Under way: a rematch (back to no shots) says who breaks again.
                bridge.matchStartSpoken = false
            }
        } else {
            bridge.matchStartSpoken = false
        }
        let version = model.timelineVersion
        guard bridge.narratedVersion != version, model.aimReady, DuoStory.hasShot(model) else { return }
        var text = summary(of: model)
        if let match = model.match {
            // The ruling is still being made while the shot is out: wait for it, then say both together.
            if match.phase == .shooting { return }
            if match.phase != .aiming, let ruling = match.lastRuling {
                text += " " + TableWords.ruling(ruling, names: match.playerNames)
            }
        }
        bridge.narratedVersion = version
        announce(text)
    }

    /// True when the recording holds a real strike worth stepping through (not just balls at rest).
    static func canStep(_ model: ShowpieceModel) -> Bool { DuoStory.hasShot(model) && !model.captions.isEmpty }

    /// Move the replay to the next (or previous) explained moment and read its caption. Past the last one the replay
    /// goes to the end of the shot (where aiming is offered again) and says so.
    static func step(_ model: ShowpieceModel, forward: Bool) {
        guard canStep(model) else { return }
        // Captions closer to the clock than this are the one already on screen.
        let epsilon = 1e-4
        let caps = model.captions
        let next = forward ? caps.first { $0.time > model.time + epsilon } : caps.last { $0.time < model.time - epsilon }
        guard let caption = next else {
            model.scrub(to: forward ? model.duration : 0)
            announce(forward ? String(localized: "End of the shot.") : String(localized: "Start of the shot."))
            return
        }
        model.scrub(to: caption.time)
        announce("\(caption.title). \(caption.detail)")
    }
}

// MARK: Text that may not be capped

extension View {
    /// Natural height while it fits in `maxHeight` points, a scroll view of that height when the text size makes it
    /// taller. For small panels beside the table that used to cap Dynamic Type instead (the shot panel's hint): the
    /// words grow to every size the reader picks and the table keeps its room. Built on FittingScroll (Surfaces.swift).
    func scrollsWhenTaller(than maxHeight: CGFloat) -> some View {
        FittingScroll(maxHeight: maxHeight) { self }
    }
}

// MARK: The elements

struct TableAccessLayer: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    /// Double-tap on a ball. Nil: balls are only described.
    var onBall: ((Int) -> Void)?
    /// Double-tap on a pocket (solver index 0 to 5). Nil: pockets are only described.
    var onPocket: ((Int) -> Void)?
    /// Show the table-wide element (with the step-through actions). Off while aiming: the aim element takes its place.
    var showsTableElement = true

    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl
    @AppStorage(GameSettings.explanationsKey) private var explanations = true
    @State private var cameraBox = AimProjector.CameraBox()

    /// The square each element covers, points: the smallest comfortable touch target.
    private let side: CGFloat = 44

    var body: some View {
        if (voiceOver || switchControl) && !model.menuOpen {
            TimelineView(.periodic(from: .now, by: 0.5)) { _ in
                GeometryReader { geo in
                    ZStack(alignment: .topLeading) {
                        if showsTableElement { tableElement }
                        ForEach(items(size: geo.size)) { item in element(item) }
                    }
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                }
            }
            .allowsHitTesting(false)
            .accessibilityElement(children: .contain)
        }
    }

    // MARK: Table element

    private var tableElement: some View {
        Rectangle()
            .fill(Color.white.opacity(0.001))
            .accessibilityElement()
            .accessibilityLabel(Text(model.solvedTable.title))
            .accessibilityValue(Text(tableValue))
            .accessibilitySortPriority(10_000)
            .accessibilityActions {
                // With Shot explanations off the player asked for the summary only, so the moment-by-moment
                // stepping is not offered (the plan's package 3, step 4).
                if explanations && ShotNarration.canStep(model) {
                    Button(String(localized: "Step through the shot")) { ShotNarration.step(model, forward: true) }
                    Button(String(localized: "Step back through the shot")) { ShotNarration.step(model, forward: false) }
                }
                if DuoStory.hasShot(model) {
                    Button(String(localized: "Say what happened")) { ShotNarration.announce(ShotNarration.summary(of: model)) }
                }
            }
    }

    private var tableValue: String {
        let view = model.lensOn ? String(localized: "Physics Lens view") : String(localized: "Table view")
        return view + ". " + TableWords.tableValue(layout: positions, cueBall: cueBall)
    }

    // MARK: Ball and pocket elements

    private struct Item: Identifiable {
        /// Balls by number, pockets as 100 + index.
        let id: Int
        let point: CGPoint
        let label: String
        let value: String
        let priority: Double
    }

    private var cueBall: Int { model.match?.cueBallIndex ?? 0 }

    /// Where every ball is now: the next shot's layout once the shot on screen has played out, else the recording at
    /// the clock (pocketed balls off the table).
    private var positions: [Vec2] {
        if model.aimReady, !model.layout.isEmpty { return model.layout }
        let tl = model.timeline
        return (0..<tl.ballCount).map { b in
            let s = tl.state(ball: b, at: model.time)
            let gone = s.pocketed || (tl.flewOffTable(b) && model.time >= tl.duration)
            return gone ? NextShot.offTable : s.position
        }
    }

    private func items(size: CGSize) -> [Item] {
        guard let root = bridge.table?.root,
              let proj = AimProjector(camera: cameraBox.find(in: root), size: size, frame: TableFrame(model.timeline.table))
        else { return [] }
        let table = model.timeline.table
        let layout = positions
        let pool = model.solvedTable == .standard
        let bounds = CGRect(origin: .zero, size: size)
        var out: [Item] = []
        // Balls: the cue ball first, then the rest nearest the cue ball first (the order a player scans the table).
        let cue = layout.indices.contains(cueBall) ? layout[cueBall] : nil
        let onTable = layout.indices.filter { NextShot.isOnTable(layout[$0]) }
        let ordered = onTable.sorted { a, b in
            if a == cueBall { return true }
            if b == cueBall { return false }
            guard let c = cue, NextShot.isOnTable(c) else { return a < b }
            return (layout[a] - c).length < (layout[b] - c).length
        }
        for (rank, b) in ordered.enumerated() {
            guard let p = proj.screen(layout[b]), bounds.contains(p) else { continue }
            out.append(Item(id: b, point: p, label: TableWords.ballLabel(b, cueBall: cueBall, pool: pool),
                            value: TableWords.ballValue(b, cueBall: cueBall, layout: layout, table: table),
                            priority: Double(1000 - rank)))
        }
        // Pockets, after the balls, in the eight-ball order. Only the edge pockets have names.
        if table.pocketsEnabled {
            for (k, hole) in table.pockets.enumerated() where k < TableSpec.edgePocketCount {
                guard let label = TableWords.pocketLabel(k), let p = proj.screen(hole, height: 0.002), bounds.contains(p)
                else { continue }
                out.append(Item(id: 100 + k, point: p, label: label, value: pocketValue(k, layout: layout, table: table),
                                priority: Double(100 - k)))
            }
        }
        return out
    }

    /// For a pocket while the table is still: the ball it is easiest to pot there with a clean line, if any.
    private func pocketValue(_ k: Int, layout: [Vec2], table: TableSpec) -> String {
        guard model.aimReady, layout.indices.contains(cueBall), NextShot.isOnTable(layout[cueBall]) else { return "" }
        let candidates = layout.indices.compactMap { b -> TableLines.PotAim? in
            guard b != cueBall else { return nil }
            return TableLines.potAim(ball: b, pocket: k, cueBall: cueBall, in: layout, table: table)
        }.filter(\.clear)
        guard let best = candidates.min(by: { $0.cutSine < $1.cutSine }) else { return String(localized: "No clear pot") }
        return String(localized: "Clear pot for \(TableWords.ballName(best.ball, cueBall: cueBall))")
    }

    @ViewBuilder private func element(_ item: Item) -> some View {
        let base = Rectangle()
            .fill(Color.white.opacity(0.001))
            .frame(width: side, height: side)
            .position(item.point)
            .accessibilityElement()
            .accessibilityLabel(Text(item.label))
            .accessibilityValue(Text(item.value))
            .accessibilitySortPriority(item.priority)
        if item.id >= 100, let onPocket {
            base
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(Text("Aims to pot the ball in line into this pocket"))
                .accessibilityAction { onPocket(item.id - 100) }
        } else if item.id < 100, item.id != cueBall, let onBall {
            base
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(Text("Aims straight at this ball"))
                .accessibilityAction { onBall(item.id) }
        } else {
            base
        }
    }
}
