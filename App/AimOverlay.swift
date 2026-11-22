// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// Edited: Claude Haiku 5.5 High, 20-November-2026 (player-facing words wrapped for translation: String(localized:) so they reach the string catalog, and numbers formatted for the player's language).
// Edited: Claude Opus 5.5 High, 20-November-2026 (test script "retry", also started by -retryDemo: a shot, Try again,
//          a change of spin, the same shot again, ending on the comparison).
// Edited: Claude Opus 5.5 High, 20-November-2026 (the Aim guide option: with it off only a short aim line is drawn,
//          with no ghost ball, no ringed target and no follow-on lines, so the player judges the angle).
// Edited: Claude Opus 5.5 High, 20-November-2026 (the mechanical bridge: for a trick shot that needs it, the bridge's
//          head is drawn on the cloth under the cue a little behind the ball, its notch carrying the cue, with its long
//          handle running back beside the cue and a small "Bridge" label, so the player sees why the shot is reachable).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the cue stick and the bridge are real 3D models on the table now
//          (CueRig); this layer no longer strokes a flat cue or draws a flat bridge, and keeps only the small "Bridge"
//          label beside the bridge head).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the bridge label follows model.showsBridge, so Behind the 8-Ball
//          situations that need the bridge get it too).
// Edited: Claude Opus 5.5 High, 21-November-2026 (one line: the guide is drawn along AimGeometry.launchDirection, so it
//          bends with side spin on the new physics generation; the solver stream's hook, everything else unchanged).
// Edited: Claude Opus 5.5 High, 21-November-2026 (ball in hand, play-views stream: while the model has the cue ball
//          lifted (placingCueBall) a drag anywhere on the table carries it to the finger (moveCueBallCandidate) and
//          letting go puts it down (confirmCueBallPlacement; an illegal spot keeps it lifted, tinted red by
//          PlayTableLayer); the arrow keys move it a ball radius in the direction they point on screen and Return
//          puts it down; the aim drawing steps aside meanwhile. The retry test log reads the model's RetryComparison.
//          The spoken route for placement is the ball-in-hand card (FreePlayViews), not this layer's Aim element.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (look plan, small hooks: the aim line fades out as it reaches the first
//          ball it will hit instead of running on (with the guide off, too, it now stops at that ball); the target-ball
//          badge (TargetBallBadge) sits in this layer; the table's pinch, two-finger pan and double tap
//          (TableZoomGestures) work through it, and a one-finger aim drag is ignored while a pinch or pan is on.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (accessibility plan, packages 2 and 5: the aim is spoken as a target,
//          not degrees ("Hits the 3 ball with a half-ball hit, cutting it to the left. It goes into the foot-left
//          corner pocket.", TableWords.aim); the Aim element gains the actions Aim at next ball, Aim to pot in nearest
//          pocket, Finer and Coarser; the layer is now a container that also holds an element over every ball and
//          pocket (TableAccessLayer): double-tap a ball to aim straight at it, a pocket to aim the pot. A plain tap
//          does the same for one-finger play: tap a ball and the line snaps to its centre, tap a pocket and it aims
//          the ball in line (or the easiest ball) into that pocket. A game controller's A button fires while this
//          layer is up, and the controller turns the aim the way the arrow keys do on this camera.)
// Edited: 21-November-2026 by Claude Opus 5.5 High (tables-screens, one hook in the drawing: the guide stops at the
//          first bumper, standing pin or hole on a small table, AimGeometry.obstacleDistance, as it does at a ball.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (lessons: the layer takes the open controls and the lesson's target
//          bands. While a lesson has locked the aim, a drag on the table no longer swings the line and the Aim element
//          tells VoiceOver "Locked for this step" (the model refuses the change from every route anyway); a locked power
//          ignores the pull-back. A lesson's aim band is drawn as a faint fan from the cue ball, so the cut lesson's
//          try 2 shows where the line has to go.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (stroke stream hooks: the pull on the cue ball is now the measured
//          stroke (StrokeGestures, App/Stroke/StrokeGesture.swift), added to this layer as one modifier; while it tracks
//          a stroke this file's own pull defers to it (power is set in one place), the rest of a touch that has played
//          its shot by a push through the ball is ignored (so it does not jump the new shot to its end), and the
//          groove and the finger's trace are drawn from this Canvas with one call. Scripted drags are unchanged.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (reach: the bridge mark. While aiming and stroking, a soft chalk ring
//          lies on the cloth where the bridge rests (model.strokeBridgeLength behind the cue ball along the cue: the
//          finger's, the automatic one, or the rest's head), with a faint dotted line from it to the cue ball. Paper
//          for a square stance, magenta when the stance is not (App/Stroke/Reach.swift); with Differentiate
//          Without Colour that also gets an inner ring, so it never rests on colour alone. It never moves by itself,
//          so Reduce Motion has nothing to stop. Its length is read in the fine controls and the stance by the
//          equipment card, both spoken; the drawing itself stays hidden from VoiceOver like the rest of this Canvas.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 touch stream, plans/21-Nov-2026-bugs-after-0-6-6-plan.md items
//          5, 7, 9, 11, 13 and 23: this layer no longer decides for itself what a touch is. Its old one-finger drag,
//          which acted the moment a finger landed (so the first finger of a pinch swung the aim and a touch during the
//          replay skipped it), is gone; the touch arbiter in App/Stroke/StrokeGesture.swift decides (undecided, zoom,
//          bridge and stroke, placement, aim, tap) and calls this layer's aim, pointer pull, carry, release and tap
//          handlers. A drag that starts on a ball free play lets the player lift picks that ball up and carries it,
//          letting go puts it down, as for ball in hand. The pull handle ring is drawn at the grab circle's own size
//          (TableTouch.grabRadius, from the ball on screen with a 22-point floor). A pointer's pull follows the curved
//          pull (StrokeTracker.powerFraction) and leaves the power alone in lesson steps not about power. Return and
//          the controller's shoot go through model.fireStroke(), so a refusal is recorded and shown. The bridge mark
//          is drawn beside the groove, at the bridge's own distance from the cue ball, instead of on the cue line where
//          the stroke finger travels, and is left out when the mechanical rest is drawn; the "Bridge" label follows
//          model.restInUse. The test script drives the same handlers directly.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (access stream hooks, 0.7.0 items 47 and 50: the Aim element's words
//          come from TableWords.spokenAim (the guide's launch line and contact, side spin included, with a lesson's
//          aim band and the stance), the ball in line is the guide's, and aiming at a ball or a pot goes through
//          AimAccess so the launch line, not the bare cue line, runs through the chosen point. Replies to the Aim
//          element's actions are spoken at once through ShotNarration.answer, not queued behind other speech.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 gaps, plan items 1, 24 and 50: before the first stroke, while
//          the aiming tips have not been seen or the cue is being handed over, the stroke's groove is drawn faintly from
//          the cue ball back along the cue for a finger or a pointer, so a newcomer sees where to pull. The line's stop
//          and contact now come from AimGeometry.guideLine, the one rule the badge and the spoken aim use; with the Aim
//          guide off the line is the cue's own straight line (the side-spin-bent line showed even then); with it on, side
//          spin that turns the ball half a degree or more draws the fork, the cue's line beside the ball's, labelled
//          "Cue aims here" and "Ball goes here" with the turn; and the object ball's line follows the solver's own impact,
//          so it includes throw. Aiming at a ball or a pot, by tap or by the VoiceOver actions, turns the cue back by
//          side spin's push through AimGeometry.cueAim(forLaunch:for:), so the ball itself leaves for the chosen spot.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.2: the ringed target, its departure line and an awkward stance's bridge mark are
//          magenta (Palette.slide), no longer amber; the local name and comments follow.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 learn-modes stream, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          item 7: in Squirt and Side Off the Rail a tap or an aim action points the cue's own line at the spot, not a
//          launch corrected for the side's push, so the player allows for the squirt as the shot asks, and the spoken
//          answer says the side will push the ball off that line; the pull's ticks honour the Vibration option.)
// PURPOSE: Aim by touching the table. A transparent layer laid over the 3D table while "Your shot" is open. It does
//          two jobs. (1) Gestures: which gesture a touch is gets decided by the touch arbiter (StrokeGestures,
//          App/Stroke/StrokeGesture.swift), which then calls this layer's handlers: a drag to aim swings the aim line to
//          follow the finger (the finger's spot on the table is found with AimProjector, so it works from any camera
//          angle); a finger on the cue ball is the measured stroke (that file); a mouse or trackpad pressed on the cue
//          ball pulls back, and how far behind the aim line sets the power on the curved pull, shown live in the power
//          gauge and as a percentage by the ball; a lifted ball is carried and put down; a tap aims at a ball or a
//          pocket. The arrow keys fine-tune: left and right turn the aim a quarter degree (shift: a degree), up and
//          down change the power, Return takes the shot. (2) Drawing: a glowing aim line to the first ball it will hit, the "ghost ball" where the cue ball will be at that
//          moment, the ball it hits ringed, where that ball and the cue ball will head afterwards, or the line to the
//          cushion when it misses everything. All of it is drawn in screen space from the live camera, so it also
//          follows the camera's swing into the Physics Lens. The cue itself (drawn back as far as the power) and the
//          mechanical bridge are 3D models placed by CueRig; while the rest is in use this layer only labels it, and
//          otherwise draws the chalk ring of the bridge hand beside the groove.
//          TEST HOOK: launching with -aimScript <break|shots|scratch> makes the layer drive itself through the same
//          handlers the touch arbiter calls (aim drag, pull-back, release, Break or Shoot, second shot, or a shot straight at a
//          pocket) and log what it did with the prefix AIMSCRIPT, so the flow can be checked and photographed without
//          anyone at the screen. It does not go through UIKit touch delivery; real touches were checked separately.
//          Reads and writes the model only through its aim, power and fire methods; the layer is only in the view
//          tree while the panel is open, so it costs nothing otherwise. For VoiceOver the layer is a container: one
//          adjustable "Aim" element spoken as a target, plus an element over each ball and pocket; the sliders in the
//          fine-controls sheet remain the complete slider route.
// SRP/DRY check: Pass - checked CaptionViews (a Canvas overlay that projects model points; same pattern, but one-way
//          and for the caption ring) and ShotPanel (the sliders, kept as the fallback). Ray casting and camera maths
//          live in AimGeometry; the gauges in AimGauges; who owns a touch in StrokeGesture; this file is only the
//          gesture handlers, keys and drawing.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import RealityKit
import SwiftUI

struct AimOverlay: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    /// Closed by the break: the cold open takes over the screen.
    @Binding var isOpen: Bool
    /// Which controls are open (a lesson's guided tries close some): aim and power are this layer's.
    var open: ShotControls = .all
    /// The lesson's target bands, if any; this layer draws the aim band.
    var zones: LessonZones? = nil

    @AppStorage("aimHintSeen") private var hintSeen = false
    @AppStorage(GameSettings.aimGuideKey) private var aimGuide = true
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @State private var cameraBox = AimProjector.CameraBox()
    /// True while a mouse or trackpad pulls back from the cue ball (a finger's pull is the stroke's: stroke.pullOn).
    @State private var pulling = false
    /// The stroke being drawn on the cue ball (StrokeGesture), shared with the drawing below.
    @State private var stroke = StrokeSession()
    /// True while a finger (or pointer) is carrying the lifted cue ball; letting go puts it down.
    @State private var placingDrag = false
    @State private var viewSize = CGSize(width: 400, height: 800)
    @FocusState private var focused: Bool
    /// The VoiceOver adjust step for the aim, in the model's nudge units (a quarter degree for a shot, a millimetre
    /// at the lead ball for the break). Finer and Coarser walk through `aimSteps`.
    @State private var aimStep = 4.0
    /// A quarter degree for the last hair, a degree (the old fixed step), five degrees to swing round the table.
    private static let aimSteps: [Double] = [1, 4, 20]

    /// Honour the silent-testing flag for touch feedback too.
    private static let muted = ProcessInfo.processInfo.arguments.contains("-muteSound")

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                // Who owns each touch (aim, the measured stroke with its bridge finger, carrying a lifted ball, a tap,
                // or the zoom), decided in one place; it calls back into this layer's handlers.
                .strokeGestures(model: model, bridge: bridge, session: stroke, isOpen: $isOpen, routes: touchRoutes)
                .modifier(TableZoomGestures(model: model, bridge: bridge))
                .accessibilityHidden(true)
            TimelineView(.animation) { _ in
                Canvas { ctx, size in draw(&ctx, size: size) }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            TargetBallBadge(model: model, bridge: bridge)
            // VoiceOver and Switch Control: the Aim element under everything (touching bare cloth finds it), and
            // an element over every ball and pocket on top (touching a ball finds the ball).
            aimElement
            TableAccessLayer(model: model, bridge: bridge, onBall: { aimAtBall($0) }, onPocket: { aimToPot(pocket: $0) },
                             showsTableElement: false)
        }
        .ignoresSafeArea()
        .onGeometryChange(for: CGSize.self) { $0.size } action: { viewSize = $0 }
        // Keyboard: Mac, and iPad with a keyboard. The layer takes focus when it appears so the arrows work at once.
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .onAppear {
            focused = true
            // A game controller fires and turns the aim through this layer while it is up (GameControllerInput).
            GameControllerInput.shared.shoot = { [model] in
                hintSeen = true
                // Through fireStroke, so a refused shot (no call, ...) is recorded and the card says why.
                if model.fireStroke() == .breakStruck { isOpen = false }
            }
            GameControllerInput.shared.turnSign = { screenSign() }
        }
        .onDisappear {
            GameControllerInput.shared.shoot = nil
            GameControllerInput.shared.turnSign = { 1 }
        }
        .task { await TestScript.run(on: self) }
        .onKeyPress(keys: [.leftArrow, .rightArrow, .upArrow, .downArrow, .return], phases: [.down, .repeat], action: handleKey)
        // The pull's ticks honour the Vibration option (0.7.5), read as each one fires, as every other haptic does.
        .sensoryFeedback(trigger: pullBucket) { _, _ in GameSettings.hapticsOn ? .selection : nil }
        .accessibilityElement(children: .contain)
    }

    // MARK: Accessibility

    /// The adjustable Aim element: spoken as a target (TableWords.aim), turned by swiping up and down in steps the
    /// player can make finer or coarser, with actions that aim at a ball or set up a pot. The fine-controls sheet
    /// remains the complete slider route.
    private var aimElement: some View {
        Rectangle()
            .fill(Color.white.opacity(0.001))
            .allowsHitTesting(false)
            .accessibilityElement()
            .accessibilityLabel("Aim")
            .accessibilityValue(spokenAim)
            .accessibilityHint(open.contains(.aim) ? String(localized: "Swipe up or down to turn the aim. Use the more menu for the sliders.")
                                                   : String(localized: "Locked for this step"))
            .accessibilitySortPriority(20_000)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: model.nudgeAim(aimStep)
                case .decrement: model.nudgeAim(-aimStep)
                @unknown default: break
                }
            }
            .accessibilityActions {
                // Aiming at a ball or a pocket only means something after the break; the break aims at the rack.
                if !model.racked {
                    Button(String(localized: "Aim at next ball")) { aimAtNextBall() }
                    Button(String(localized: "Aim to pot in nearest pocket")) { aimToPotNearest() }
                }
                Button(String(localized: "Finer")) { changeStep(finer: true) }
                Button(String(localized: "Coarser")) { changeStep(finer: false) }
            }
    }

    /// Walk the adjust step one size smaller or larger and say what a step now does.
    private func changeStep(finer: Bool) {
        let steps = Self.aimSteps
        let i = steps.firstIndex(of: aimStep) ?? 1
        aimStep = steps[finer ? max(0, i - 1) : min(steps.count - 1, i + 1)]
        let size: String
        if model.racked {
            size = String(localized: "Each step moves the aim \(TableWords.amount(aimStep)) millimetres.")
        } else {
            // A nudge step is a quarter of a degree (ShowpieceModel.nudgeAim).
            let degrees = (aimStep * 0.25).formatted(.number.precision(.fractionLength(0...2)))
            size = String(localized: "Each step turns the aim \(degrees) degrees.")
        }
        ShotNarration.answer(size)
    }

    /// Object balls the cue ball can hit straight on (its line to the ball's centre meets that ball first). In a
    /// match, the balls the shooter may play when there are any, so "next ball" skips the opponent's.
    private func hittableBalls() -> [Int] {
        let layout = model.layout
        guard layout.count > 1, NextShot.isOnTable(model.aimOrigin) else { return [] }
        let o = model.aimOrigin, r = model.timeline.table.ballRadius
        let all = (1..<layout.count).filter { b in
            guard NextShot.isOnTable(layout[b]) else { return false }
            let d = (layout[b] - o).normalized
            return AimGeometry.firstContact(layout: layout, from: o, direction: d, radius: r)?.ball == b
        }
        if let match = model.match {
            let legal = all.filter { match.rules.mayCall($0, in: match.state) }
            if !legal.isEmpty { return legal }
        }
        return all
    }

    /// The ball the aim line meets first now, if any.
    /// (Access stream hook, item 50: the ball the guide shows, along the launch line, not the bare cue line.)
    private var ballInLine: Int? { AimGeometry.guideContact(for: model)?.ball }

    /// Aim straight through a ball's centre (a full hit), and say the new aim. The ball's launch line, side spin's
    /// push included, is what runs through the centre (aimLaunch).
    private func aimAtBall(_ ball: Int) {
        guard model.layout.indices.contains(ball), NextShot.isOnTable(model.layout[ball]) else { return }
        let cueLine = aimLaunch(toward: model.layout[ball])
        // On a strong-side trick the cue, not the ball, was pointed at it: say so, or the player hears a full hit.
        ShotNarration.answer(cueLine
            ? spokenAim + " " + String(localized: "The cue points at \(TableWords.ballName(ball)); the side will push the ball off it.")
            : spokenAim)
    }

    /// True while a trick shot about side spin's push is up (Squirt, Side Off the Rail: TrickGoal.side, the strong-side
    /// rule): there the tap and the aim actions point the cue's own line, and allowing for the squirt is the player's
    /// job, which is what the shot teaches. Everywhere else the launch is corrected for the push (aimLaunch).
    private var aimsCueLine: Bool {
        model.trickMode.isActive && model.trickMode.current?.goal.side != nil
    }

    /// Aim so the struck ball itself leaves along the line through `point`, side spin's push allowed for (item 50):
    /// the cue is turned back by the push through the guide's own inverse (AimGeometry.cueAim(forLaunch:for:)), so the
    /// line the guide draws, the ball the badge rings and the words VoiceOver speaks all run through the chosen ball or
    /// ghost spot. Every aim at a ball or a pot from this layer goes through here: the VoiceOver actions, the ball and
    /// pocket elements and a sighted tap. The break aims at the rack by its offset instead (ShowpieceModel.aim(toward:)),
    /// so it is passed straight on. On a strong-side trick (aimsCueLine, 0.7.5) the cue's own line is pointed at the
    /// spot instead, uncorrected, so the tap does not do the allowing-for-squirt the shot asks of the player. Returns
    /// true when it pointed the cue's own line that way, so the spoken answer can say so.
    @discardableResult
    private func aimLaunch(toward point: Vec2) -> Bool {
        let origin = model.aimOrigin
        let want = point - origin
        guard !model.racked, want.lengthSquared > 1e-12 else { model.aim(toward: point); return false }
        if aimsCueLine {
            model.aim(toward: point)
            return true
        }
        model.aim(toward: origin + AimGeometry.cueAim(forLaunch: want, for: model))
        return false
    }

    /// Cycle through the balls that can be hit, by number, starting after the one in line now.
    private func aimAtNextBall() {
        let balls = hittableBalls()
        guard let first = balls.first else {
            ShotNarration.answer(String(localized: "No ball can be hit in a straight line."))
            return
        }
        let current = ballInLine ?? 0
        aimAtBall(balls.first { $0 > current } ?? first)
    }

    /// Aim the ghost-ball pot of `ball` into `pocket`, and say the new aim (which names the pocket, or what blocks it).
    private func aimPot(_ pot: TableLines.PotAim) {
        // Corrected for side spin's push, so the ball really leaves for the ghost spot (item 50); on a strong-side
        // trick the cue's own line is pointed there instead, and the answer says so (0.7.5).
        let cueLine = aimLaunch(toward: pot.ghost)
        ShotNarration.answer(cueLine
            ? spokenAim + " " + String(localized: "The cue points at the spot to pot \(TableWords.ballName(pot.ball)); the side will push the ball off it.")
            : spokenAim)
    }

    /// Tap or double-tap on a pocket: pot the ball in line into it; with no ball in line, the ball that is easiest
    /// to pot there (clear lines first, then the smallest cut).
    private func aimToPot(pocket: Int) {
        guard !model.racked else { return }
        let table = model.timeline.table, layout = model.layout
        if let b = ballInLine, let pot = TableLines.potAim(ball: b, pocket: pocket, in: layout, table: table) {
            aimPot(pot); return
        }
        let options = (1..<max(1, layout.count)).compactMap { TableLines.potAim(ball: $0, pocket: pocket, in: layout, table: table) }
        guard let pot = options.filter(\.clear).min(by: { $0.cutSine < $1.cutSine }) ?? options.min(by: { $0.cutSine < $1.cutSine })
        else {
            ShotNarration.answer(String(localized: "No ball can be potted in that pocket from here."))
            return
        }
        aimPot(pot)
    }

    /// "Aim to pot in nearest pocket": the ball in line (or the nearest ball that can be hit) into the nearest pocket
    /// it can reach with both lines clear; when none is clear, the easiest pot there is.
    private func aimToPotNearest() {
        let table = model.timeline.table, layout = model.layout
        let o = model.aimOrigin
        guard let ball = ballInLine ?? hittableBalls().min(by: { (layout[$0] - o).length < (layout[$1] - o).length }) else {
            ShotNarration.answer(String(localized: "No ball can be hit in a straight line."))
            return
        }
        let pots = (0..<min(TableSpec.edgePocketCount, table.pockets.count)).compactMap {
            TableLines.potAim(ball: ball, pocket: $0, in: layout, table: table)
        }
        let nearest = pots.filter(\.clear).min { (table.pockets[$0.pocket] - layout[ball]).length < (table.pockets[$1.pocket] - layout[ball]).length }
        guard let pot = nearest ?? TableLines.bestPot(ball: ball, in: layout, table: table) else {
            ShotNarration.answer(String(localized: "No ball can be potted in that pocket from here."))
            return
        }
        aimPot(pot)
    }

    /// A tap (a touch that did not move) on the table while aiming: on an object ball, aim straight at it; on a
    /// pocket, aim the pot into it. Anything else keeps the plain aim-through-the-spot the drag already made.
    fileprivate func tapped(at point: CGPoint) {
        guard model.aimReady, !model.racked, let proj = projector(size: viewSize) else { return }
        let layout = model.layout, table = model.timeline.table
        // Generous on purpose: a finger covers more than a ball does from the overhead camera.
        let ballReach: CGFloat = 26, pocketReach: CGFloat = 34
        var best: (distance: CGFloat, ball: Int?, pocket: Int?)?
        for b in 1..<max(1, layout.count) where NextShot.isOnTable(layout[b]) {
            guard let s = proj.screen(layout[b]) else { continue }
            let d = hypot(s.x - point.x, s.y - point.y)
            if d <= ballReach, best == nil || d < best!.distance { best = (d, b, nil) }
        }
        if table.pocketsEnabled {
            for (k, hole) in table.pockets.enumerated() where k < TableSpec.edgePocketCount {
                guard let s = proj.screen(hole, height: 0.002) else { continue }
                let d = hypot(s.x - point.x, s.y - point.y)
                if d <= pocketReach, best == nil || d < best!.distance { best = (d, nil, k) }
            }
        }
        // A tap on a ball sends the ball, not the bare cue, at it, as the VoiceOver action does (item 50).
        if let ball = best?.ball { aimLaunch(toward: layout[ball]) }
        else if let pocket = best?.pocket { aimToPot(pocket: pocket) }
    }

    // MARK: Gestures

    /// The handlers the touch arbiter (StrokeGestures) calls once it has decided what a touch or a press is.
    private var touchRoutes: TableTouchRoutes {
        TableTouchRoutes(aim: { aimDrag(to: $0) },
                         pull: { pull(from: $0, to: $1) },
                         carry: { carry(to: $0) },
                         release: { endDrag() },
                         tap: { tapAim(at: $0) })
    }

    fileprivate func projectorForScript() -> AimProjector? { projector(size: viewSize) }

    private func projector(size: CGSize) -> AimProjector? {
        guard let root = bridge.table?.root else { return nil }
        return AimProjector(camera: cameraBox.find(in: root), size: size, frame: TableFrame(model.timeline.table))
    }

    /// Drag to aim: the line swings through the table point under the finger or pointer. A lesson step with the aim
    /// locked keeps the line where the lesson set it (the model refuses too).
    fileprivate func aimDrag(to location: CGPoint) {
        guard open.contains(.aim), model.layout.count == 16, let proj = projector(size: viewSize),
              let spot = proj.table(at: location) else { return }
        model.aim(toward: spot)
    }

    /// A mouse or trackpad pulling back from the cue ball (a finger's pull is the measured stroke): how far behind the
    /// cue ball it is, along the aim line on the table, sets the power through the curved pull. Below the slop it is a
    /// click on the ball and leaves the power as it was. In a lesson step not about power the pull only plays the shot
    /// (PointerAim's release), so the power is left where the lesson put it.
    fileprivate func pull(from start: CGPoint, to location: CGPoint) {
        guard model.layout.count == 16, TableTouch.pullSetsPower(model),
              hypot(location.x - start.x, location.y - start.y) > TableTouch.slop,
              let proj = projector(size: viewSize), let spot = proj.table(at: location) else { return }
        let behind = (model.aimOrigin - spot).dot(model.aimDirection)
        model.powerFraction = StrokeTracker.powerFraction(forDepth: behind)
        pulling = true
    }

    /// Ball in hand or a ball lifted in free play: the lifted ball follows the finger or pointer; nothing is aimed.
    fileprivate func carry(to location: CGPoint) {
        guard model.placingCueBall, let proj = projector(size: viewSize), let spot = proj.table(at: location) else { return }
        model.moveCueBallCandidate(to: spot)
        placingDrag = true
    }

    /// A finger or pointer let go of an aim, a pull or a carried ball.
    fileprivate func endDrag() {
        // A carried ball: letting go puts it down. On an illegal spot the model keeps it lifted (and the table layer
        // tints it red), so the player simply drags again or uses Place it.
        if placingDrag {
            placingDrag = false
            model.confirmCueBallPlacement()
            return
        }
        if pulling { hintSeen = true }
        pulling = false
    }

    /// A tap (a touch that did not move) on the table with the balls at rest: aim through the spot, then, on an object
    /// ball, straight at it, or on a pocket, the pot into it (accessibility plan, package 5).
    fileprivate func tapAim(at point: CGPoint) {
        aimDrag(to: point)
        tapped(at: point)
    }

    /// Changes each tenth of pull so the phone can tick as the power climbs; -1 when not pulling. A finger's pull is
    /// the stroke's (stroke.pullOn, not observed; the body is re-read as the power it sets changes).
    private var pullBucket: Int { (pulling || stroke.pullOn) && !Self.muted ? Int(model.powerFraction * 10) : -1 }

    private func handleKey(_ press: KeyPress) -> KeyPress.Result {
        // The keyboard is the input in use now (the hand-over line and the panel hint pick their words by it).
        if model.inputInUse != .keyboard { model.inputInUse = .keyboard }
        if model.placingCueBall { return placementKey(press) }
        guard model.aimReady else { return .ignored }
        let big = press.modifiers.contains(.shift)
        switch press.key {
        case .leftArrow: model.nudgeAim(screenSign() * (big ? 4 : 1)); return .handled
        case .rightArrow: model.nudgeAim(-screenSign() * (big ? 4 : 1)); return .handled
        case .upArrow: model.powerFraction += big ? 0.1 : 0.02; return .handled
        case .downArrow: model.powerFraction -= big ? 0.1 : 0.02; return .handled
        case .return:
            hintSeen = true
            if model.fireStroke() == .breakStruck { isOpen = false }
            return .handled
        default: return .ignored
        }
    }

    /// Ball in hand from the keyboard: each arrow moves the lifted ball one ball radius the way the arrow points on
    /// the screen (found by projecting a short screen step back onto the table, so it holds from any camera angle);
    /// Return puts it down.
    private func placementKey(_ press: KeyPress) -> KeyPress.Result {
        let step: CGPoint
        switch press.key {
        case .leftArrow: step = CGPoint(x: -20, y: 0)
        case .rightArrow: step = CGPoint(x: 20, y: 0)
        case .upArrow: step = CGPoint(x: 0, y: -20)
        case .downArrow: step = CGPoint(x: 0, y: 20)
        case .return:
            model.confirmCueBallPlacement()
            return .handled
        default: return .ignored
        }
        let at = CueBallPlacement.spot(model)
        guard let proj = projector(size: viewSize), let s = proj.screen(at),
              let there = proj.table(at: CGPoint(x: s.x + step.x, y: s.y + step.y)) else { return .ignored }
        let d = there - at
        guard d.lengthSquared > 1e-12 else { return .ignored }
        model.moveCueBallCandidate(to: at + d.normalized * model.timeline.table.ballRadius)
        return .handled
    }

    /// +1 when turning the aim counter-clockwise on the table plan also turns the line counter-clockwise on the
    /// screen, -1 when the camera views the table the other way round (portrait swings it a quarter turn). Left arrow
    /// always means "turn the line anticlockwise as the player sees it".
    private func screenSign() -> Double {
        guard let proj = projector(size: viewSize) else { return 1 }
        let o = model.aimOrigin, d = model.aimDirection
        let a = 2.0 * Double.pi / 180
        let turned = Vec2(cos(a) * d.x - sin(a) * d.y, sin(a) * d.x + cos(a) * d.y)
        guard let s0 = proj.screen(o), let s1 = proj.screen(o + d * 0.5), let s2 = proj.screen(o + turned * 0.5) else { return 1 }
        // Screen y points down, so a negative cross product is a counter-clockwise turn as seen.
        let cross = (s1.x - s0.x) * (s2.y - s0.y) - (s1.y - s0.y) * (s2.x - s0.x)
        return cross < 0 ? 1 : -1
    }

    /// The aim as VoiceOver says it. The break keeps its offset from the lead ball (the rack is the target); a shot
    /// says what it will hit and where that ball goes (TableWords.aim), with the angle last for anyone who wants it.
    /// The target sentence is spoken even with the Aim guide option off: that option hides drawing for sighted
    /// players who want to judge the angle, and for a player who cannot see the table these words are the only view.
    /// (Access stream hook, 0.7.0 item 50: the words follow the launch line and contact the guide draws, side spin
    /// included, and carry a lesson's aim band and the stance; built in TableWords.spokenAim.)
    private var spokenAim: String { TableWords.spokenAim(for: model) }

    // MARK: Drawing

    private func draw(_ ctx: inout GraphicsContext, size: CGSize) {
        guard model.aimReady, !model.placingCueBall, model.layout.count == 16, NextShot.isOnTable(model.aimOrigin), let proj = projector(size: size) else { return }
        let table = model.timeline.table
        let radius = table.ballRadius
        let origin = model.aimOrigin
        guard model.aimDirection.lengthSquared > 0.5, let cueScreen = proj.screen(origin) else { return }

        // The line and what stops it, from the one stop-and-contact rule the badge and the spoken aim also use
        // (AimGeometry.guideLine): the first cushion, bumper, standing pin or hole ends it, and a ball behind that is not
        // the contact. With the guide on it runs along the launch line, the aim bent by side spin (item 24). With the
        // guide off it is the cue's own straight line: the player judges the angle and the push themselves, so the
        // bent line, which used to show even then, would give away what the option hides.
        let guide: GuideLine
        if aimGuide {
            guard let launched = AimGeometry.guideLine(for: model) else { return }
            guide = launched
        } else {
            guide = AimGeometry.guideLine(layout: model.layout, origin: origin, direction: model.aimDirection, table: table)
        }
        let dir = guide.direction
        // Without the guide: no contact prediction drawn, and the line stops a short way out; it still never runs on
        // through the first ball in its way (it fades out there, look plan package 5).
        let firstHit = guide.contact
        let contact = aimGuide ? firstHit : nil
        let toHit = firstHit.map { ($0.ghost - origin).length }
        let reach = aimGuide ? guide.reach : min(Self.unguidedReach, guide.reach)
        let accent = palette.accent, magenta = palette.slide, paper = palette.paper

        // The cue and the mechanical bridge are 3D models (CueRig); whenever the rest is in use (a shot that needs it,
        // or a stance out of reach), a small label names it beside its head.
        // Along the cue's own line, where CueRig stands the rest's head, not the launch line side spin bends.
        if model.restInUse { drawBridgeLabel(&ctx, proj, origin: origin, dir: model.aimDirection, size: size) }

        // A lesson's aim band: a faint fan from the cue ball between the two edge aims of the window, as far as the
        // first ball the middle of the band meets (or half a metre), so the line can be swung into it.
        if let band = zones?.aim { drawAimBand(&ctx, proj, origin: origin, band: band, radius: radius) }

        // Where the bridge hand rests, beside the groove behind the ball (drawn before the aim line, which stays on
        // top). Not with the mechanical rest: its 3D head is the bridge then.
        if !model.restInUse { drawBridgeMark(&ctx, proj, origin: origin, radius: radius) }

        // The aim line: a soft wide halo under a thin bright core, from the ball's edge to where the cue ball stops.
        // When that is a ball, the last third of the line fades out into the contact, so the line reads as ending
        // there rather than running on; a line that ends at the cushion or a short way out stays solid.
        if let a = proj.screen(origin + dir * radius), let b = proj.screen(origin + dir * reach) {
            var line = Path(); line.move(to: a); line.addLine(to: b)
            let fades = toHit.map { reach >= $0 - 1e-6 } ?? false
            func shade(_ c: Color, _ o: Double) -> GraphicsContext.Shading {
                fades ? .linearGradient(Gradient(stops: [.init(color: c.opacity(o), location: 0), .init(color: c.opacity(o), location: 0.66),
                                                          .init(color: c.opacity(o * 0.12), location: 1)]), startPoint: a, endPoint: b)
                      : .color(c.opacity(o))
            }
            ctx.stroke(line, with: shade(accent, 0.28), style: StrokeStyle(lineWidth: 9, lineCap: .round))
            ctx.stroke(line, with: shade(paper, 0.95), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }

        // Side spin turning the ball half a degree or more off the cue's line (item 24): the cue's own line as well,
        // and a label on each prong, so the player sees that the cue points one way and the ball leaves another.
        // Only with the guide on; with it off the one line drawn is already the cue's.
        if aimGuide, let fork = AimGeometry.fork(for: model) {
            drawFork(&ctx, proj, fork: fork, guide: guide, radius: radius, size: size)
        }

        if let hit = contact {
            // The ghost ball: the cue ball where it will touch.
            if let ghost = circle(proj, hit.ghost, radius) {
                ctx.fill(ghost, with: .color(paper.opacity(0.14)))
                ctx.stroke(ghost, with: .color(paper.opacity(0.95)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            }
            // The ball it will hit, ringed, and the spot where they touch.
            if let ring = circle(proj, hit.target, radius * 1.3) { ctx.stroke(ring, with: .color(magenta), lineWidth: 2.5) }
            if let touch = proj.screen((hit.ghost + hit.target) * 0.5) {
                ctx.fill(Path(ellipseIn: CGRect(x: touch.x - 3, y: touch.y - 3, width: 6, height: 6)), with: .color(paper))
            }
            // Where the two balls go next: the object ball where the solver's own impact sends it (longer for a fuller
            // hit), the cue ball at a right angle (longer for a thinner cut). Short guides, cut off at the cushion.
            // The guide on is this game's full assist (there is no other assist level), so the object ball's line
            // includes throw (item 24): the friction at contact drags a soft cut a few degrees off the line of centres,
            // and a pot aimed on the bare line of centres would miss. The line of centres stands in when the solver
            // gives no answer (a break, a miscue, a trial past its budget).
            let objectDirection = AimGeometry.solvedImpact(for: model, contact: hit)?.objectDirection ?? hit.objectDirection
            let fullness = max(0, 1 - hit.cut * hit.cut).squareRoot()
            let objectLength = min(0.15 + 0.6 * fullness, AimGeometry.cushionDistance(from: hit.target, direction: objectDirection, table: table))
            if let a = proj.screen(hit.target + objectDirection * radius * 1.3), let b = proj.screen(hit.target + objectDirection * (radius + objectLength)) {
                var path = Path(); path.move(to: a); path.addLine(to: b)
                ctx.stroke(path, with: .linearGradient(Gradient(colors: [magenta, magenta.opacity(0.05)]), startPoint: a, endPoint: b),
                           style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
            if let side = hit.cueDirection {
                let cueLength = min(0.12 + 0.4 * hit.cut, AimGeometry.cushionDistance(from: hit.ghost, direction: side, table: table))
                if let a = proj.screen(hit.ghost + side * radius), let b = proj.screen(hit.ghost + side * (radius + cueLength)) {
                    var path = Path(); path.move(to: a); path.addLine(to: b)
                    ctx.stroke(path, with: .linearGradient(Gradient(colors: [paper.opacity(0.7), paper.opacity(0.05)]), startPoint: a, endPoint: b),
                               style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [3, 4]))
                }
            }
        } else if aimGuide, let end = circle(proj, origin + dir * reach, radius) {
            // Nothing in the way: the cue ball finishes at the cushion.
            ctx.stroke(end, with: .color(paper.opacity(0.7)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
        }

        // The stroke's groove on the cloth and the finger's trace, while a stroke is drawn on the cue ball.
        StrokeDrawing.draw(&ctx, session: stroke, paper: paper, accent: accent)
        // Before the first touch (item 1): the same groove, fainter and with no trace, laid from the cue ball back along
        // the cue, so a newcomer sees where to pull. Its direction, length and width are the ones a stroke started now
        // would lay (TableTouch.grooveFrame, as StrokeGestures uses), so the real groove lands where the hint was.
        if showsGrooveHint, let groove = TableTouch.grooveFrame(proj, centre: origin, direction: model.aimDirection) {
            StrokeDrawing.drawHint(&ctx, from: cueScreen, groove: groove, paper: paper)
        }

        // The pull handle around the cue ball, drawn at the grab circle itself (TableTouch.grabRadius), so the ring the
        // player sees is exactly where a touch grabs the ball; and the live power read-out while pulling.
        let ringRadius = TableTouch.grabRadius(proj, centre: origin, ballRadius: radius)
        let pullOn = pulling || stroke.pullOn
        let handle = Path(ellipseIn: CGRect(x: cueScreen.x - ringRadius, y: cueScreen.y - ringRadius, width: ringRadius * 2, height: ringRadius * 2))
        ctx.stroke(handle, with: .color(accent.opacity(pullOn ? 1 : 0.8)), style: StrokeStyle(lineWidth: pullOn ? 2.5 : 1.5, dash: pullOn ? [] : [5, 4]))
        if pullOn {
            let text = ctx.resolve(Text(String(format: "%.0f%%", model.powerFraction * 100)).font(.headline.monospacedDigit()).foregroundStyle(Color.white))
            let measured = text.measure(in: size)
            let badge = CGRect(x: cueScreen.x - measured.width / 2 - 10, y: cueScreen.y - ringRadius - measured.height - 14,
                               width: measured.width + 20, height: measured.height + 8)
            ctx.fill(Path(roundedRect: badge, cornerRadius: badge.height / 2), with: .color(.black.opacity(0.65)))
            ctx.draw(text, at: CGPoint(x: badge.midX, y: badge.midY))
        }
    }

    /// The fan for a lesson's aim band (degrees on the table plan), filled faintly and edged, lying on the cloth.
    private func drawAimBand(_ ctx: inout GraphicsContext, _ proj: AimProjector, origin: Vec2, band: ClosedRange<Double>,
                             radius: Double) {
        func unitAt(_ deg: Double) -> Vec2 { Vec2(cos(deg * Double.pi / 180), sin(deg * Double.pi / 180)) }
        let mid = unitAt((band.lowerBound + band.upperBound) / 2)
        let reach = AimGeometry.firstContact(layout: model.layout, from: origin, direction: mid, radius: radius)
            .map { ($0.ghost - origin).length } ?? 0.5
        let steps = 12
        var fan = Path()
        guard let o = proj.screen(origin + mid * radius, height: 0.001) else { return }
        fan.move(to: o)
        for i in 0...steps {
            let a = band.lowerBound + (band.upperBound - band.lowerBound) * Double(i) / Double(steps)
            guard let p = proj.screen(origin + unitAt(a) * reach, height: 0.001) else { return }
            fan.addLine(to: p)
        }
        fan.closeSubpath()
        let strength = zones?.strength ?? 1
        ctx.fill(fan, with: .color(palette.paper.opacity(0.16 * strength)))
        ctx.stroke(fan, with: .color(palette.paper.opacity(0.7 * strength)), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
    }

    /// The bridge mark's radius on the cloth, metres: about a bridge hand's knuckles across.
    private static let bridgeMarkRadius = 0.03

    /// The bridge mark: a soft chalk ring on the cloth where the bridge hand can rest, at the bridge's length from the
    /// cue ball, and a faint dotted line from it to the cue ball. Swung off the cue line to the shooter's left (the
    /// bridge hand of a right-handed player) just far enough that the ring clears the groove by a ball's radius: on
    /// the line it sat on the groove, where the stroke finger travels, and a finger resting there blocked any pull
    /// past it. The bridge is read from the finger's distance to the cue ball in any direction, so a finger on the
    /// ring sets exactly the length it shows. Lying on the cloth (0.001 m up, as the ghost and the stroke's trace
    /// are), projected through the live camera.
    private func drawBridgeMark(_ ctx: inout GraphicsContext, _ proj: AimProjector, origin: Vec2, radius: Double) {
        let forward = model.aimDirection
        guard forward.lengthSquared > 0.5 else { return }
        let length = max(model.strokeBridgeLength, 1e-3)
        // The sideways share of the swing: the ring's own radius plus a ball's radius of clear cloth, over the length.
        let sideways = min(1, (Self.bridgeMarkRadius + radius) / length)
        let backward = (1 - sideways * sideways).squareRoot()
        let spot = origin - forward * (length * backward) + forward.perp * (length * sideways)
        guard let ring = clothCircle(proj, spot, Self.bridgeMarkRadius) else { return }
        // Paper for a square stance with a clear path; magenta (Palette.slide) when the stance is not.
        let awkward = model.stance.map { !$0.isNormal } ?? false
        let ink = awkward ? palette.slide : palette.paper
        let toBall = (origin - spot).normalized
        if let a = proj.screen(spot + toBall * Self.bridgeMarkRadius, height: 0.001),
           let b = proj.screen(origin - toBall * radius, height: 0.001) {
            var line = Path(); line.move(to: a); line.addLine(to: b)
            ctx.stroke(line, with: .color(ink.opacity(0.35)), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [1, 4]))
        }
        // Chalk: a soft wide halo under a thin ring.
        ctx.stroke(ring, with: .color(ink.opacity(0.16)), style: StrokeStyle(lineWidth: 6))
        ctx.stroke(ring, with: .color(ink.opacity(0.75)), style: StrokeStyle(lineWidth: 1.5))
        // Differentiate Without Colour: an awkward stance is told by a second, inner ring as well as by its colour.
        if awkward, differentiateWithoutColor, let inner = clothCircle(proj, spot, Self.bridgeMarkRadius * 0.5) {
            ctx.stroke(inner, with: .color(ink.opacity(0.75)), style: StrokeStyle(lineWidth: 1.5))
        }
    }

    /// A circle lying on the cloth itself (not at the balls' height), as a closed screen path.
    private func clothCircle(_ proj: AimProjector, _ centre: Vec2, _ radius: Double) -> Path? {
        var path = Path()
        let steps = 32
        for i in 0..<steps {
            let a = Double(i) / Double(steps) * 2 * Double.pi
            guard let p = proj.screen(centre + Vec2(cos(a), sin(a)) * radius, height: 0.001) else { return nil }
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }

    /// A small label so a first-time player knows what the new shape on the cloth is: the mechanical bridge (the
    /// "rest" or "spider"), whose 3D head CueRig stands 0.30 m behind the cue ball. The label sits on the cloth just
    /// past the right-hand end of the head (it is 0.12 m wide), where the old flat bridge put it.
    private func drawBridgeLabel(_ ctx: inout GraphicsContext, _ proj: AimProjector, origin: Vec2, dir: Vec2, size: CGSize) {
        let side = dir.perp
        let head = origin - dir * 0.30
        let halfWidth = 0.06
        guard let at = proj.screen(head + side * (halfWidth + 0.10), height: 0.002) else { return }
        drawPill(&ctx, [Text("Bridge")], at: at, size: size)
    }

    /// A small white label on a dark pill, centred on a screen point: the bridge's name and the fork's prongs. Each
    /// entry is one line, centred under the one before (a resolved Text in a Canvas cannot centre its own lines).
    private func drawPill(_ ctx: inout GraphicsContext, _ lines: [Text], at centre: CGPoint, size: CGSize) {
        let resolved = lines.map { ctx.resolve($0.font(.caption2.weight(.semibold)).foregroundStyle(Color.white)) }
        let sizes = resolved.map { $0.measure(in: size) }
        guard !sizes.isEmpty else { return }
        let width = sizes.map(\.width).max() ?? 0
        let height = sizes.map(\.height).reduce(0, +)
        let box = CGRect(x: centre.x - width / 2 - 6, y: centre.y - height / 2 - 2, width: width + 12, height: height + 4)
        // A one-line pill is fully rounded; a two-line one keeps a soft corner rather than turning into a lozenge.
        ctx.fill(Path(roundedRect: box, cornerRadius: min(box.height / 2, 9)), with: .color(.black.opacity(0.55)))
        var top = box.minY + 2
        for (line, m) in zip(resolved, sizes) {
            ctx.draw(line, at: CGPoint(x: box.midX, y: top + m.height / 2))
            top += m.height
        }
    }

    /// How far out the line runs with the Aim guide off, metres: a short line that shows which way the cue points and
    /// leaves the angle to the player's eye (PointerAim's hover preview keeps the same length).
    private static let unguidedReach = 0.35

    /// The groove hint shows before the first stroke: the aiming tips have not been seen yet (first launch, or "Show
    /// the aiming tips again" in Options) or the cue is being handed over in the first-launch opening, and the player
    /// is on a finger or a pointer (the two that pull back from the ball; keys and a controller have no groove). Never
    /// while a finger strokes or a pointer pulls: the real groove, or the pull's own ring, is drawn then.
    private var showsGrooveHint: Bool {
        guard !stroke.isTracking, !pulling else { return false }
        guard !hintSeen || model.openingStage == .handOver else { return false }
        return model.inputInUse == .touch || model.inputInUse == .pointer
    }

    /// The side-spin fork (item 24): the cue's straight line as a thin dashed prong beside the bright launch line the
    /// guide already drew, "Cue aims here" at its end and "Ball goes here" with the turn ("2.4° left") at the launch
    /// line's end. The cue's prong runs as far as the launch line does (its own first ball or cushion stops it sooner),
    /// so both ends sit the same distance out and the gap between them is the push made visible. Each label is pushed
    /// away from the other prong on screen, so the two never sit on top of each other.
    private func drawFork(_ ctx: inout GraphicsContext, _ proj: AimProjector, fork: AimFork, guide: GuideLine,
                          radius: Double, size: CGSize) {
        let origin = guide.origin, table = model.timeline.table
        let cueStop = AimGeometry.guideLine(layout: model.layout, origin: origin, direction: fork.cueLine, table: table).reach
        let cueReach = min(guide.reach, cueStop)
        guard cueReach > radius, guide.reach > radius,
              let cueStart = proj.screen(origin + fork.cueLine * radius),
              let cueEnd = proj.screen(origin + fork.cueLine * cueReach),
              let ballEnd = proj.screen(origin + guide.direction * guide.reach) else { return }
        var prong = Path(); prong.move(to: cueStart); prong.addLine(to: cueEnd)
        ctx.stroke(prong, with: .color(palette.paper.opacity(0.6)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [6, 4]))
        // Which way is "away from the other prong" on screen: from the cue's end toward the ball's. When the two ends
        // land on almost the same point (a short line seen end-on), square to the cue's prong instead.
        var away = CGVector(dx: ballEnd.x - cueEnd.x, dy: ballEnd.y - cueEnd.y)
        var length = hypot(away.dx, away.dy)
        if length < 1 {
            away = CGVector(dx: -(cueEnd.y - cueStart.y), dy: cueEnd.x - cueStart.x)
            length = hypot(away.dx, away.dy)
        }
        guard length > 1e-3 else { return }
        away = CGVector(dx: away.dx / length, dy: away.dy / length)
        // Clear of the line's end by about a label's half height plus a gap; two lines for the ball's label.
        let gap: CGFloat = 16
        // The words are already localized by AimFork, so they are drawn verbatim (no second catalog lookup).
        drawPill(&ctx, [Text(verbatim: AimFork.cueLabel)],
                 at: CGPoint(x: cueEnd.x - away.dx * gap, y: cueEnd.y - away.dy * gap), size: size)
        drawPill(&ctx, [Text(verbatim: AimFork.ballLabel), Text(verbatim: fork.turnWords)],
                 at: CGPoint(x: ballEnd.x + away.dx * (gap + 8), y: ballEnd.y + away.dy * (gap + 8)), size: size)
    }

    /// A circle lying on the cloth at the ball's height, as a closed screen path (a squashed oval from a low camera).
    private func circle(_ proj: AimProjector, _ centre: Vec2, _ radius: Double) -> Path? {
        var path = Path()
        let steps = 40
        for i in 0..<steps {
            let a = Double(i) / Double(steps) * 2 * Double.pi
            guard let p = proj.screen(centre + Vec2(cos(a), sin(a)) * radius) else { return nil }
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: Test hook

/// Scripted drags for -aimScript. Every drag is a list of screen points fed, one every 30 ms, to the handler the touch
/// arbiter would call for it (AimOverlay.aimDrag for an aim, AimOverlay.pull for a pull-back), followed by the same
/// end-of-drag clean-up a lifted finger causes. The script knows which gesture it is making, so it skips the arbiter.
@MainActor
private enum TestScript {
    static func run(on o: AimOverlay) async {
        let args = ProcessInfo.processInfo.arguments
        let scenario: String
        if args.contains("-retryDemo") { scenario = "retry" }
        else if let i = args.firstIndex(of: "-aimScript"), i + 1 < args.count { scenario = args[i + 1] }
        else { return }
        try? await Task.sleep(for: .seconds(3.5))
        let model = o.model
        switch scenario {
        case "break":
            // Aim a little off the apex ball, pull to about three quarters, break.
            await aim(o, toward: model.layout[1] + Vec2(0.01, 0.035))
            await hold(2)
            await pull(o, fraction: 0.75, hold: 2)
            await hold(1.5)
            _ = model.fire(); o.isOpen = false
        case "scratch":
            // A clear line to a pocket at full power: the cue ball should drop and be put back on the head spot.
            let t = model.timeline.table
            let corners = [Vec2(0, 0), Vec2(t.length, 0), Vec2(0, t.width), Vec2(t.length, t.width)] + t.pockets
            for pocket in corners {
                let d = (pocket - model.aimOrigin).normalized
                if AimGeometry.firstContact(layout: model.layout, from: model.aimOrigin, direction: d, radius: t.ballRadius) == nil {
                    await aim(o, toward: pocket); break
                }
            }
            await pull(o, fraction: 1, hold: 1)
            _ = model.fire()
            await settle(model)
            NSLog("AIMSCRIPT scratch: cue ball now at (%.3f, %.3f), on table = %@", model.aimOrigin.x, model.aimOrigin.y,
                  NextShot.isOnTable(model.aimOrigin) ? "yes" : "NO")
        case "retry":
            // One shot at the farthest visible ball with draw, then Try again, switch to follow, and shoot again.
            let t = model.timeline.table
            var best: (Double, Vec2)?
            for b in 1..<16 where NextShot.isOnTable(model.layout[b]) {
                let delta = model.layout[b] - model.aimOrigin
                let seen = AimGeometry.firstContact(layout: model.layout, from: model.aimOrigin, direction: delta.normalized, radius: t.ballRadius)
                if seen?.ball == b, best == nil || delta.length > best!.0 { best = (delta.length, model.layout[b]) }
            }
            guard let ball = best?.1 else { return }
            await aim(o, toward: ball + (ball - model.aimOrigin).normalized.perp * t.ballRadius * 0.4)
            await pull(o, fraction: 0.6, hold: 1)
            model.activeTipUp = -0.012
            _ = model.fire()
            await settle(model)
            await hold(1)
            // Same settings first: the recordings must match exactly (the model logs both hashes).
            model.tryAgain()
            await hold(1)
            _ = model.fire()
            await settle(model)
            model.tryAgain()
            await hold(1)
            model.activeTipUp = 0.012
            NSLog("AIMSCRIPT retry: ghost on screen, spin changed to follow")
            await hold(4)
            _ = model.fire()
            await settle(model)
            NSLog("AIMSCRIPT retry: compared -> %@", model.retryComparison.map { RetryWords.sentence($0) } ?? "none")
        default: // shots
            for shot in 1...2 {
                let t = model.timeline.table
                // The farthest ball the cue ball can see in a straight line, so the guide has some length to show.
                var best: (Double, Vec2)?
                for b in 1..<16 where NextShot.isOnTable(model.layout[b]) {
                    let delta = model.layout[b] - model.aimOrigin
                    let seen = AimGeometry.firstContact(layout: model.layout, from: model.aimOrigin, direction: delta.normalized, radius: t.ballRadius)
                    if seen?.ball != b { continue }
                    if best == nil || delta.length > best!.0 { best = (delta.length, model.layout[b]) }
                }
                guard let ball = best?.1 else { return }
                // A slightly thin cut so the ghost ball and both outgoing lines show.
                let spot = ball + (ball - model.aimOrigin).normalized.perp * t.ballRadius * 0.8
                await aim(o, toward: spot)
                NSLog("AIMSCRIPT shot %d: aim %.2f deg, hits ball %d", shot, model.aimDegrees,
                      AimGeometry.firstContact(layout: model.layout, from: model.aimOrigin, direction: model.aimDirection, radius: t.ballRadius)?.ball ?? -1)
                await hold(2.5)
                await pull(o, fraction: shot == 1 ? 0.55 : 0.8, hold: 2.5)
                NSLog("AIMSCRIPT shot %d: power %.2f m/s (%.0f%%)", shot, model.activePower, model.powerFraction * 100)
                await hold(1.5)
                _ = model.fire()
                await settle(model)
                await hold(1.5)
            }
        }
    }

    static func hold(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }

    /// Wait until the shot on screen has played out and the aiming layer is ready again (bounded, so a stuck run ends).
    static func settle(_ model: ShowpieceModel) async {
        for _ in 0..<400 { try? await Task.sleep(for: .milliseconds(100)); if model.aimReady, model.playing == false, model.time >= model.duration { break } }
    }

    /// A drag that starts well off the cue ball and ends on the screen point of the wanted table spot.
    static func aim(_ o: AimOverlay, toward spot: Vec2) async {
        guard let proj = o.projectorForScript(), let to = proj.screen(spot, height: nil), let from = proj.screen(o.model.aimOrigin + (spot - o.model.aimOrigin).perp.normalized * 0.4) else { return }
        await move(from, to) { o.aimDrag(to: $0) }
        o.endDrag()
    }

    /// A drag that starts on the cue ball and ends behind it, along the aim line, far enough for `fraction` power on
    /// the curved pull (StrokeTracker.depth(forPowerFraction:), the inverse of the curve the pull reads).
    static func pull(_ o: AimOverlay, fraction: Double, hold seconds: Double) async {
        let m = o.model
        let depth = StrokeTracker.depth(forPowerFraction: fraction)
        guard let proj = o.projectorForScript(), let from = proj.screen(m.aimOrigin),
              let to = proj.screen(m.aimOrigin - m.aimDirection * depth) else { return }
        await move(from, to) { o.pull(from: from, to: $0) }
        await hold(seconds)
        o.endDrag()
    }

    /// Feeds thirteen evenly spaced points from `from` to `to` to a handler, one every 30 ms.
    private static func move(_ from: CGPoint, _ to: CGPoint, step: (CGPoint) -> Void) async {
        for i in 0...12 {
            let k = CGFloat(i) / 12
            step(CGPoint(x: from.x + (to.x - from.x) * k, y: from.y + (to.y - from.y) * k))
            try? await Task.sleep(for: .milliseconds(30))
        }
    }
}
