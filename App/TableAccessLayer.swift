// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: 21-November-2026 by Claude Opus 5.5 High (tables-screens, one hook: the spoken ruling ends with everyone's
//          score in games that keep one, five-pin and bar billiards.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (stroke stream hook: a finished shot's summary is followed by the
//          stroke's result line when a hard swing's drift mattered, the same words the screen shows (StrokeWords).)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, access stream:
//          - item 47: one speaker. Every announcement goes through ShotNarration.announce, which gathers the lines
//            posted within a quarter of a second into one sentence (no exact repeats) and posts it at low priority,
//            so VoiceOver queues it behind whatever it is saying instead of cutting it off. A finished shot is one
//            utterance: the summary, the stroke's line, the one ruling sentence (the match card no longer says its
//            own version) and the stance for the next strike, folded in instead of announced on every change.
//          - item 46: lessons are followed without sight: the step's voice line when a step starts (what is open, the
//            band's range in words, the goal, where the finish circle is), the idea when the replay pauses on it, the
//            verdict after every try; TipAccessActions gives the tip picture its spoken amount, its band status, fine
//            steps, quick actions that land inside a marked band, and Into the marked band.
//          - item 48: the table element stays while aiming (sorted after Aim), so Step through the shot, Step back and
//            Say what happened are always reachable; item 58: it also carries Zoom in on the cue ball and Zoom out.
//          - item 49: the small tables' balls carry their own names, and every hole, cup, peg, pin and bumper is an
//            element of its own; double-tap one while aiming to aim straight at it.
//          - item 50: AimAccess aims so the ball's launch line, side spin's push included, runs through the chosen
//            point, the line the guide draws and the aim words describe.
//          - item 51: the first-minute line is chosen by the input in use and announced when the hand-over begins.
//          - item 44: the element layer is pinned left to right, as the caption and badge layers are, so in Arabic an
//            element sits over its ball instead of the mirrored spot.
//          - item 42: the layer hands the scene bridge to the game controller, which needs the live camera to move
//            ball in hand the way the d-pad points.)
// PURPOSE: The table as VoiceOver and Switch Control find it (accessibility plan, packages 1 and 3).
//          TableAccessLayer lays one invisible accessibility element over each ball and each pocket of the 3D table,
//          at the place the ball or pocket really is on screen, so touch exploration finds a ball where it sits and
//          swiping goes cue ball first, then the other balls nearest first, then the pockets (on the small tables,
//          their holes, cups, pegs, pins and bumpers). Each ball says its name and where it is (TableWords); each
//          pocket its name and whether a ball can be potted in it cleanly. A first, table-wide element carries the
//          table's name, the view (table or Physics Lens), how many balls are up, and the "Step through the shot",
//          "Say what happened" and zoom actions. Positions come from the live camera through AimProjector, refreshed
//          twice a second (fast enough to follow a replay by touch, and nothing runs at all while no assistive
//          technology is on). The elements take no touches, so aiming drags pass straight through.
//          ShotNarration is the one speaker: the summary when a shot finishes, each explained moment when stepping
//          through, the match ruling, the lesson's steps, idea and verdicts, the first-minute line, and every other
//          view's announcement (the cards call ShotNarration.announce), posted through SwiftUI's
//          AccessibilityNotification at low priority so lines wait their turn.
//          Used by TableStage (the table, with step-through) and AimOverlay (while aiming: double-tap a ball to aim at
//          it, a pocket to aim the pot). Reads the model; writes it only by scrubbing the replay, by the aim actions
//          (AimAccess) and by the tip actions (TipAccessActions, laid on the tip picture by AimGauges).
// SRP/DRY check: Pass - checked CaptionViews.LeaderState (projects one ball per frame through the RealityView's own
//          projector for the caption ring) and AimOverlay (projects through AimProjector); this layer reuses
//          AimProjector rather than adding work to the per-frame scene closure. The words are TableWords; the caption
//          list for stepping is the model's (the same list NotebookStory shows). The zoom actions call TableZoom's
//          own focus and springBack (the double tap's), and the launch line is AimGeometry.launchDirection's.
import Accessibility
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import SwiftUI

// MARK: Speaking

@MainActor
enum ShotNarration {
    /// Lines posted this close together are said as one announcement. A quarter of a second covers the lines one
    /// event produces across a frame or two (a shot's summary and its lesson verdict, a ruling and "Table cleared")
    /// and is too short to be heard as a delay.
    static let gatherWindow: Duration = .milliseconds(250)
    private static var pending: [String] = []
    private static var flushScheduled = false

    /// Speak a sentence (VoiceOver; ignored when no screen reader is running). Lines arriving within the gather
    /// window are joined into one announcement, an exact repeat is said once, and the announcement is queued behind
    /// whatever VoiceOver is saying (low priority) instead of cutting it off.
    static func announce(_ text: String) {
        let line = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { return }
        if !pending.contains(line) { pending.append(line) }
        guard !flushScheduled else { return }
        flushScheduled = true
        Task { @MainActor in
            try? await Task.sleep(for: gatherWindow)
            flush()
        }
    }

    private static func flush() {
        flushScheduled = false
        let lines = pending
        pending = []
        guard !lines.isEmpty else { return }
        var spoken = AttributedString(lines.joined(separator: " "))
        spoken.accessibilitySpeechAnnouncementPriority = .low
        AccessibilityNotification.Announcement(spoken).post()
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

    /// The finished shot in one to three sentences, with the striking player's ball as the cue ball in a match and
    /// the table's own ball names.
    static func summary(of model: ShowpieceModel) -> String {
        // The ball that was struck: once the ruling is in, the turn (and on the other tables the striking ball) has
        // moved on, so the match's record of the shot comes first.
        TableWords.summary(timeline: model.timeline, start: start(of: model),
                           cueBall: model.match.map { $0.lastShotBall ?? $0.cueBallIndex } ?? 0,
                           kind: model.solvedTable)
    }

    /// The first-minute line as VoiceOver gives it, by the input in use: a keyboard or a controller gets its own
    /// instruction (FirstInstruction, the words the hand-over card shows), and a touch screen gets the VoiceOver way
    /// to aim and play, because with VoiceOver running a finger explores rather than drags. On the Mac VoiceOver is
    /// driven from the keyboard, so the keyboard's line is the one that fits.
    static func firstLine(_ model: ShowpieceModel) -> String {
        switch model.inputInUse {
        case .keyboard, .controller:
            return FirstInstruction.line(for: model.inputInUse)
        case .touch, .pointer:
            #if os(iOS)
            return String(localized: "Swipe up or down on Aim to turn the aim, and on Power to set the swing. Then double-tap Break.")
            #else
            return FirstInstruction.line(for: .keyboard)
            #endif
        }
    }

    // Narration state: what has been said, so each thing is said once. Main-actor statics, like the queue.
    private static var lastOpeningStage: OpeningStage = .none
    private static var lastLessonPhase: LessonMode.Phase?
    private static var lastLessonID: String?
    private static var lastAimedStep: LessonMode.Step?

    /// Called once a frame by TableStage's scene update (not from a view body, so reading the clock here redraws
    /// nothing), only while a screen reader runs. Says, each once: the first-minute line when the hand-over begins,
    /// who breaks at the start of a match, a finished shot (summary, stroke line, ruling and next stance as one
    /// utterance; in a match it waits for the ruling so the two are one), and a lesson's steps, idea and verdicts.
    static func frame(model: ShowpieceModel, bridge: SceneBridge) {
        guard bridge.speaks, !model.menuOpen else { return }
        narrateOpening(model)
        narrateMatchStart(model, bridge: bridge)
        narrateShot(model, bridge: bridge)
        narrateLesson(model)
    }

    /// The hand-over of the first launch: the one line that teaches the first shot, for the input in use.
    private static func narrateOpening(_ model: ShowpieceModel) {
        let stage = model.openingStage
        guard stage != lastOpeningStage else { return }
        lastOpeningStage = stage
        if stage == .handOver { announce(firstLine(model)) }
    }

    /// "Ana to break." once per rack.
    private static func narrateMatchStart(_ model: ShowpieceModel, bridge: SceneBridge) {
        guard let match = model.match else { bridge.matchStartSpoken = false; return }
        if !bridge.matchStartSpoken, match.state.isBreak, match.state.shotCount == 0,
           let player = match.state.currentPlayer {
            bridge.matchStartSpoken = true
            announce(String(localized: "\(player.name) to break."))
        } else if match.state.shotCount > 0 {
            // Under way: a rematch (back to no shots) says who breaks again.
            bridge.matchStartSpoken = false
        }
    }

    /// A shot that has played out, once per recording: the summary, the stroke's line, the ruling (one sentence; the
    /// match card leaves it to this) and the stance for the next strike when the next shooter is a person.
    private static func narrateShot(_ model: ShowpieceModel, bridge: SceneBridge) {
        let version = model.timelineVersion
        guard bridge.narratedVersion != version, model.aimReady, NotebookStory.hasShot(model) else { return }
        var text = summary(of: model)
        if let line = StrokeWords.resultLine(model.currentAttempt?.stroke) { text += " " + line }
        var nextIsPerson = true
        if let match = model.match {
            // The ruling is still being made while the shot is out: wait for it, then say both together.
            if match.phase == .shooting { return }
            if let ruling = match.lastRuling {
                text += " " + TableWords.ruling(ruling, names: match.playerNames,
                                                scores: match.rules.keepsRunningScore ? match.state.scores : nil)
            }
            nextIsPerson = !match.isComputer(match.state.turn)
        }
        if nextIsPerson, let stance = TableWords.stanceLine(model) { text += " " + stance + "." }
        bridge.narratedVersion = version
        announce(text)
    }

    /// A lesson, step by step: the lesson when it is set up, what to watch, the idea when the replay pauses on it,
    /// the voice version of each step when it starts (not again after Try again), and the verdict after every try.
    private static func narrateLesson(_ model: ShowpieceModel) {
        let mode = model.lessonMode
        guard let lesson = mode.current, mode.isActive else {
            lastLessonPhase = nil; lastLessonID = nil; lastAimedStep = nil
            return
        }
        if lastLessonID != lesson.id { lastLessonID = lesson.id; lastAimedStep = nil; lastLessonPhase = nil }
        let phase = mode.phase
        guard phase != lastLessonPhase else { return }
        lastLessonPhase = phase
        switch phase {
        case .ready:
            lastAimedStep = nil
            announce(String(localized: "Lesson \(lesson.number): \(lesson.title)") + ". " + lesson.hook)
        case .watching:
            announce(String(localized: "Watch a perfect example. \(lesson.goalLine)"))
        case .replaying:
            announce(String(localized: "Now slowed down in the Physics Lens. It stops on the moment that matters."))
        case .keyMoment:
            announce(String(localized: "The idea") + ". " + lesson.idea)
        case .aiming(let step):
            guard step != lastAimedStep else { return }
            lastAimedStep = step
            announce(TableWords.lessonStepVoice(lesson, step: step, model: model))
        case .judged(let step, let verdict):
            announce(TableWords.lessonVerdict(lesson, step: step, verdict: verdict, model: model))
        case .offScript:
            announce(String(localized: "That shot started from where the balls stopped. Try again puts them back for the lesson."))
        case .off:
            break
        }
    }

    /// True when the recording holds a real strike worth stepping through (not just balls at rest).
    static func canStep(_ model: ShowpieceModel) -> Bool { NotebookStory.hasShot(model) && !model.captions.isEmpty }

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

// MARK: Aiming by words

/// Aim actions for VoiceOver, Switch Control and the controller that must land where the guide says (item 50): the
/// player picks a point (a ball's centre, a pot's ghost-ball spot, a cup), and the cue is turned so the ball's launch
/// line, with side spin's push, runs through it. Without side spin the launch line is the cue's line and this is the
/// plain aim.
@MainActor
enum AimAccess {
    /// Aim so the ball leaves along the line from the striking ball through `point`. The push depends only on the tip
    /// and the table, not on which way the cue points (the solver's launch turns any aim by the same angle), so the
    /// cue is turned back by that angle; a second pass takes out what little is left.
    static func aim(_ model: ShowpieceModel, toward point: Vec2) {
        let origin = model.aimOrigin
        let want = point - origin
        guard !model.racked, want.lengthSquared > 1e-12 else { model.aim(toward: point); return }
        let target = want.normalized
        var parameters = model.physicsTable.parameters
        parameters.modelGeneration = model.activeModelGeneration
        var cue = target
        for _ in 0..<2 {
            let launch = AimGeometry.launchDirection(aim: cue, tipUp: model.activeTipUp, tipSide: model.activeTipSide,
                                                     parameters: parameters)
            // The signed angle from where the ball would go to where it should go, applied to the cue.
            let miss = atan2(launch.x * target.y - launch.y * target.x, launch.dot(target))
            let c = cos(miss), s = sin(miss)
            cue = Vec2(c * cue.x - s * cue.y, s * cue.x + c * cue.y)
        }
        model.aim(toward: origin + cue)
    }
}

// MARK: The tip picture, without sight

/// The cue-tip picture's accessibility (item 46), laid on TipPicker by AimGauges: the tip spoken as an amount with the
/// lesson band's status (TableWords.tipValue), fine steps of a millimetre, quick actions that land inside a marked
/// band when one is marked, Into the marked band, and nothing offered (the picture dimmed) while the lesson has locked
/// both of its values. Every change goes through the model's locked setters and the new value is spoken.
struct TipAccessActions: ViewModifier {
    let model: ShowpieceModel
    var open: ShotControls = .all
    var zones: LessonZones? = nil

    /// One fine step, metres: a millimetre, finer than the narrowest lesson band (about four millimetres wide), so a
    /// band can always be stepped into.
    static let fineStep = 0.001
    /// The quick actions with no band marked go this share of the tip's reach, as they always have.
    static let quickShare = 0.6

    func body(content: Content) -> some View {
        let upOpen = open.contains(.tipUp), sideOpen = open.contains(.tipSide)
        let band = hasOpenBand(upOpen: upOpen, sideOpen: sideOpen)
        content
            .accessibilityValue(TableWords.tipValue(model, zones: zones))
            .accessibilityActions {
                if upOpen {
                    Button(String(localized: "Up a little")) { set(up: model.activeTipUp + Self.fineStep) }
                    Button(String(localized: "Down a little")) { set(up: model.activeTipUp - Self.fineStep) }
                    Button(String(localized: "Follow")) { set(up: quick(zones?.tipUp, sign: 1)) }
                    Button(String(localized: "Draw")) { set(up: quick(zones?.tipUp, sign: -1)) }
                }
                if sideOpen {
                    Button(String(localized: "Left a little")) { set(side: model.activeTipSide - Self.fineStep) }
                    Button(String(localized: "Right a little")) { set(side: model.activeTipSide + Self.fineStep) }
                    Button(String(localized: "Left spin")) { set(side: quick(zones?.tipSide, sign: -1)) }
                    Button(String(localized: "Right spin")) { set(side: quick(zones?.tipSide, sign: 1)) }
                }
                if upOpen || sideOpen {
                    Button(String(localized: "Centre")) { set(up: upOpen ? 0 : nil, side: sideOpen ? 0 : nil) }
                }
                if band {
                    Button(String(localized: "Into the marked band")) {
                        set(up: upOpen ? zones?.tipUp.map { middle($0) } : nil,
                            side: sideOpen ? zones?.tipSide.map { middle($0) } : nil)
                    }
                }
            }
            .disabled(!(upOpen || sideOpen))
    }

    private func hasOpenBand(upOpen: Bool, sideOpen: Bool) -> Bool {
        (upOpen && zones?.tipUp != nil) || (sideOpen && zones?.tipSide != nil)
    }

    private func middle(_ r: ClosedRange<Double>) -> Double { (r.lowerBound + r.upperBound) / 2 }

    /// Where Follow, Draw, Left spin or Right spin go: the middle of the marked band when the band lies on that side
    /// of centre (the stop shot's Draw lands inside its band instead of twice as low), otherwise the usual share of
    /// the reach.
    private func quick(_ band: ClosedRange<Double>?, sign: Double) -> Double {
        if let band, middle(band) * sign > 0 { return middle(band) }
        return sign * Self.quickShare * model.tipLimit
    }

    /// Set one or both values, kept inside the reachable disc (as the drag keeps the dot), then say the new value.
    private func set(up: Double? = nil, side: Double? = nil) {
        let limit = model.tipLimit
        var u = up ?? model.activeTipUp, s = side ?? model.activeTipSide
        let length = (u * u + s * s).squareRoot()
        if length > limit, length > 0 { u *= limit / length; s *= limit / length }
        if up != nil { model.activeTipUp = u }
        if side != nil { model.activeTipSide = s }
        ShotNarration.announce(TableWords.tipValue(model, zones: zones))
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
    /// True for the table's own copy (TableStage), false for the aiming copy (AimOverlay). The table element shows in
    /// both, so stepping through the shot and zooming are reachable while aiming too; in the aiming copy it is sorted
    /// after the Aim element and its hint names the aiming context.
    var showsTableElement = true

    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl
    @AppStorage(GameSettings.explanationsKey) private var explanations = true
    @State private var cameraBox = AimProjector.CameraBox()

    /// The square each element covers, points: the smallest comfortable touch target.
    private let side: CGFloat = 44

    var body: some View {
        ZStack {
            // Takes no space, says nothing: hands the game controller the scene bridge (its d-pad moves ball in hand
            // the way it points on screen, which needs the live camera).
            Color.clear
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .onAppear { GameControllerInput.shared.attach(bridge: bridge) }
            if (voiceOver || switchControl) && !model.menuOpen {
                TimelineView(.periodic(from: .now, by: 0.5)) { _ in
                    GeometryReader { geo in
                        ZStack(alignment: .topLeading) {
                            tableElement
                            ForEach(items(size: geo.size)) { item in element(item) }
                        }
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                    }
                }
                .allowsHitTesting(false)
                .accessibilityElement(children: .contain)
            }
        }
        // The elements are placed at projected screen points, which are left-to-right; in a right-to-left language
        // the layout would mirror them onto the wrong side of the table (the caption and badge layers pin it too).
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: Table element

    private var tableElement: some View {
        Rectangle()
            .fill(Color.white.opacity(0.001))
            .accessibilityElement()
            .accessibilityLabel(Text(model.solvedTable.title))
            .accessibilityValue(Text(tableValue))
            .accessibilityHint(Text(tableHint))
            // Below the Aim element (20 000) while aiming, above every ball and pocket either way.
            .accessibilitySortPriority(showsTableElement ? 10_000 : 15_000)
            .accessibilityActions {
                // With Shot explanations off the player asked for the summary only, so the moment-by-moment
                // stepping is not offered (the plan's package 3, step 4).
                if explanations && ShotNarration.canStep(model) {
                    Button(String(localized: "Step through the shot")) { ShotNarration.step(model, forward: true) }
                    Button(String(localized: "Step back through the shot")) { ShotNarration.step(model, forward: false) }
                }
                if NotebookStory.hasShot(model) {
                    Button(String(localized: "Say what happened")) { ShotNarration.announce(ShotNarration.summary(of: model)) }
                }
                if let zoom = bridge.table?.zoom {
                    if cuePosition != nil {
                        Button(String(localized: "Zoom in on the cue ball")) { zoomIn(zoom) }
                    }
                    if zoom.isZoomed {
                        Button(String(localized: "Zoom out")) {
                            zoom.springBack()
                            ShotNarration.announce(String(localized: "Zoomed out."))
                        }
                    }
                }
            }
    }

    private var tableValue: String {
        let view = model.lensOn ? String(localized: "Physics Lens view") : String(localized: "Table view")
        return view + ". " + TableWords.tableValue(layout: positions, cueBall: cueBall)
    }

    /// During the first launch's hand-over, the one line that teaches the first shot; otherwise what the actions do.
    private var tableHint: String {
        if model.openingStage == .handOver { return ShotNarration.firstLine(model) }
        return String(localized: "Actions: step through the shot, say what happened, zoom in on the cue ball.")
    }

    /// The striking ball's place now, if it is on the table.
    private var cuePosition: Vec2? {
        let p = positions
        guard p.indices.contains(cueBall), NextShot.isOnTable(p[cueBall]) else { return nil }
        return p[cueBall]
    }

    /// Zoom in on the cue ball: the double tap's close-up, centred on it.
    private func zoomIn(_ zoom: TableZoom) {
        guard let p = cuePosition else { return }
        let w = TableFrame(model.timeline.table).world(p)
        zoom.focus(on: SIMD2(w.x, w.z), ball: cueBall)
        ShotNarration.announce(String(localized: "Zoomed in on the cue ball."))
    }

    // MARK: Ball, pocket and feature elements

    private struct Item: Identifiable {
        /// Balls by number, pockets as 100 + index, bed holes 200 + j, pins 300 + k, posts 400 + k.
        let id: Int
        let point: CGPoint
        let label: String
        let value: String
        let priority: Double
        /// For a small table's hole, cup, peg, pin or bumper: where it is, so a double-tap while aiming aims at it.
        var target: Vec2? = nil
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
        let kind = model.solvedTable
        let layout = positions
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
            out.append(Item(id: b, point: p, label: TableWords.ballLabel(b, cueBall: cueBall, table: kind),
                            value: TableWords.ballValue(b, cueBall: cueBall, layout: layout, table: table, kind: kind),
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
        // The small tables' holes, cups, pegs, pins and bumpers, after the balls, each where it is.
        for (rank, feature) in TableWords.features(of: table, kind: kind).enumerated() {
            guard let p = proj.screen(feature.centre, height: 0.002), bounds.contains(p) else { continue }
            let id: Int
            switch feature.kind {
            case .hole(let j): id = 200 + j
            case .pin(let k): id = 300 + k
            case .post(let k): id = 400 + k
            }
            out.append(Item(id: id, point: p, label: feature.label, value: featureValue(feature, table: table, kind: kind),
                            priority: Double(90 - rank), target: feature.centre))
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

    /// A small table's fixed thing: where it is (by the cushions, never by itself), whose cup it is in bumper pool,
    /// and whether a pin or peg is down on the shot on screen.
    private func featureValue(_ f: TableWords.Feature, table: TableSpec, kind: TableKind) -> String {
        var parts: [String] = []
        switch f.kind {
        case .hole(let j):
            // Bumper pool: each side sinks its balls in the cup at the far end from where they started.
            if kind == .bumperPool, let match = model.match, BumperPoolRules.targetHole.indices.contains(match.state.turn.index) {
                parts.append(BumperPoolRules.targetHole[match.state.turn.index] == j
                             ? String(localized: "Your cup: sink your balls here.")
                             : String(localized: "The other side's cup."))
            }
        case .pin(let k):
            if model.timeline.pinIsDown(k, at: model.time) { parts.append(String(localized: "Knocked down.")) }
        case .post:
            break
        }
        parts.append(TableWords.capitalized(TableWords.place(f.centre, table: table, kind: kind, excluding: f.kind)))
        return parts.joined(separator: " ")
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
        if let target = item.target, onBall != nil {
            // While aiming (the aiming copy has onBall): aim the ball straight at this hole, cup, peg, pin or bumper.
            base
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(Text("Aims straight at it"))
                .accessibilityAction {
                    AimAccess.aim(model, toward: target)
                    ShotNarration.announce(TableWords.spokenAim(for: model))
                }
        } else if item.id >= 100, item.id < 200, let onPocket {
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
