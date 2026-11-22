// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 item 42: controller play no longer stops after the first shot.
//          A presses the main button of whatever card is up (Continue, Ready, the first answer of a choice, Rematch,
//          See the ruling, Place it, Pick up the cue ball, Rack again, Watch it, Your turn, Next step, Try again, Next,
//          Make your call, Skip, Again, Learn the shots), and with no card up it shoots while Your shot is open or opens
//          Your shot when it is closed; Y opens and closes Your shot through the model's request (requestShotPanel);
//          the d-pad moves ball in hand a ball radius per press the way it points on screen, steps the eight-ball call
//          (balls left and right, pockets up and down), and otherwise turns the aim finely and steps the cue angle; the
//          menu button opens the menu. Every route records itself as the input in use (model.inputInUse), and the
//          mapping is published as `mapping` for How to play's Controls page.)
// PURPOSE: Play with a game controller (accessibility plan, package 5): any controller the system's GameController
//          framework knows as an extended gamepad, including the adaptive controllers many players with limited
//          movement use. The mapping (also `GameControllerInput.mapping`, in words, for How to play):
//            left stick, left and right ... turns the aim (faster the further it is pushed)
//            right trigger / left trigger . more / less power (by how hard each is squeezed; power is the swing)
//            right stick ................... moves the cue tip on the cue ball (follow, draw, side); it stays put when
//                                            the stick is let go, like the tip picker
//            A ............................ the main button of the card on screen; with no card up, shoot while Your
//                                            shot is open, open Your shot when it is closed, or play or pause a replay
//            B ............................ skip to where the balls came to rest (ready to aim)
//            X ............................ Physics Lens on or off
//            Y ............................ open or close Your shot
//            d-pad ......................... ball in hand: move it one ball radius the way the arrow points on screen;
//                                            an eight-ball call: left and right step the ball, up and down the pocket;
//                                            otherwise left and right turn the aim a quarter degree, up and down step
//                                            the cue angle through the angles the cue-angle menu offers
//            right / left shoulder ......... step the replay to the next / previous explained moment (read aloud)
//            menu button ................... open the menu
//          Nothing needs a button held for a time: every press is one action, and the sticks and triggers only move
//          values the player can also set with a touch, the keyboard or VoiceOver.
//          "The card on screen" is read from the model and the modes, not from the views: each card's main button
//          calls one model or mode method, and A calls that same method in the same situation, so the controller and
//          the card can never disagree about what the button does. The order below is the order the cards stack in.
//          GameControllerInput.shared is started by TableStage, which also calls step(_:model:) once a frame from the
//          scene's update (the sticks and triggers are read there, so a held stick turns the aim smoothly). Buttons
//          are edge-triggered through the framework's pressed handlers. AimOverlay registers what A does while the
//          shot panel is open (fire, and close the panel on a break) and the screen direction of a turn. The table's
//          accessibility layer (TableAccessLayer) hands over the scene bridge, so the d-pad can find "up on screen" for
//          ball in hand from the live camera (AimProjector), the same way the arrow keys do.
//          Declared in Breakdown-Info.plist (GCSupportsControllerUserInteraction, GCSupportedGameControllers).
// SRP/DRY check: Pass - checked AimOverlay.handleKey and placementKey (the keyboard route) and AimGauges (tip and
//          power); this file writes the same model values through the same methods (nudgeAim, powerFraction,
//          activeTipUp/Side, activeElevation, moveCueBallCandidate, fireStroke through the panel's hook, scrub,
//          setLens), and presses cards through the very methods their buttons call (MatchMode.acknowledgeRuling and
//          answer, LessonMode, TrickShotMode, EightBallMode, StrokeDrill, rackAgain), so every input route agrees.
//          Replay stepping reuses ShotNarration.step; the call's best pocket is TableLines.bestPot.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import CoreGraphics
import Foundation
import GameController
// The scene's camera (AimProjector reads RealityKit's PerspectiveCamera from the table's root entity).
import RealityKit

@MainActor
final class GameControllerInput {
    static let shared = GameControllerInput()

    // MARK: Tunables (each a feel choice, stated with its reason)

    /// Aim turn speed at full stick, in the model's quarter-degree steps per second: 60 steps is 15 degrees a
    /// second, a half turn of the table in twelve seconds at full tilt, and fine work at a light touch.
    static let aimStepsPerSecond = 60.0
    /// Power change per second with a trigger fully squeezed: the whole range in a second and a half, quick enough
    /// to set, slow enough to stop where intended.
    static let powerPerSecond = 0.66
    /// Tip travel per second at full stick, as a share of the tip's reach: centre to edge in about two thirds of a
    /// second.
    static let tipPerSecond = 1.5
    /// Stick and trigger readings below this are rest noise (worn sticks rarely centre to exactly zero).
    static let deadZone: Float = 0.15
    /// One d-pad press on ball in hand moves the lifted ball this many points on screen before it is turned into a
    /// table direction and scaled to one ball radius: the same probe the arrow keys use (AimOverlay.placementKey).
    static let placementProbe: CGFloat = 20

    // MARK: The mapping, in words

    /// One row of the mapping: the control's name and what it does, both localized. For How to play's Controls page.
    struct Mapping: Identifiable, Equatable, Sendable {
        let control: String
        let action: String
        var id: String { control }
    }

    /// The whole controller mapping in the order a player meets it. The menu's How to play shows it as a list; the
    /// file header above keeps the same mapping next to the code.
    nonisolated static var mapping: [Mapping] {
        [
            Mapping(control: String(localized: "Left stick"),
                    action: String(localized: "Turns the aim. Push further to turn faster.")),
            Mapping(control: String(localized: "Triggers"),
                    action: String(localized: "Right trigger swings harder, left trigger softer.")),
            Mapping(control: String(localized: "Right stick"),
                    action: String(localized: "Moves the tip on the cue ball: follow, draw and side.")),
            Mapping(control: String(localized: "A button"),
                    action: String(localized: "Presses the main button of the card on screen. With no card up, it shoots while Your shot is open and opens it when it is closed.")),
            Mapping(control: String(localized: "B button"),
                    action: String(localized: "Skips to where the balls stop.")),
            Mapping(control: String(localized: "X button"),
                    action: String(localized: "Turns the Physics Lens on or off.")),
            Mapping(control: String(localized: "Y button"),
                    action: String(localized: "Opens or closes Your shot.")),
            Mapping(control: String(localized: "D-pad"),
                    action: String(localized: "Moves ball in hand. In eight-ball, left and right pick the ball to call and up and down the pocket. Otherwise left and right turn the aim finely, and up and down raise or lower the cue.")),
            Mapping(control: String(localized: "Shoulder buttons"),
                    action: String(localized: "Step through the explained moments of the shot, forwards or back.")),
            Mapping(control: String(localized: "Menu button"),
                    action: String(localized: "Opens the menu.")),
        ]
    }

    // MARK: Hooks the aiming layer sets while the shot panel is open

    /// What A does while aiming; nil when the shot panel is closed.
    var shoot: (() -> Void)?
    /// +1 or -1: which way on the table plan "stick right" turns the line so it turns right as the player sees it
    /// (AimOverlay works it out from the camera, as for the arrow keys). +1 when no aiming layer is up.
    var turnSign: () -> Double = { 1 }

    private weak var model: ShowpieceModel?
    /// The table's scene bridge, for the live camera (ball in hand on the d-pad). Handed over by TableAccessLayer.
    private weak var bridge: SceneBridge?
    private var observers: [NSObjectProtocol] = []
    /// Behind the 8-Ball's call: the pocket the d-pad has stepped to for the picked ball (A makes the call with it).
    /// Nil until the d-pad steps a pocket; then A uses the best pocket for the ball.
    private var eightBallPocket: EightBallPocket?

    private init() {}

    /// Start listening for controllers (idempotent). Configures every controller already connected and each one that
    /// connects later.
    func start(model: ShowpieceModel) {
        self.model = model
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { _ in
            // Delivered on the main queue. Rather than carry the notification's controller across into the main
            // actor, configure every connected controller again: setting a handler twice simply replaces it.
            MainActor.assumeIsolated { GameControllerInput.shared.configureAll() }
        })
        configureAll()
    }

    /// The table's scene bridge (TableAccessLayer passes it when the table appears); kept weakly.
    func attach(bridge: SceneBridge) { self.bridge = bridge }

    private func configureAll() {
        for controller in GCController.controllers() { configure(controller) }
    }

    /// Which button was pressed: a plain value, so the framework's handler can hand it to the main actor.
    private enum Button: Sendable {
        case a, b, x, y, menu, rightShoulder, leftShoulder, left, right, up, down
    }

    /// Buttons: one action per press (pressed changes from false to true), never a hold.
    private func configure(_ controller: GCController) {
        guard let pad = controller.extendedGamepad else { return }
        let buttons: [(GCControllerButtonInput, Button)] = [
            (pad.buttonA, .a), (pad.buttonB, .b), (pad.buttonX, .x), (pad.buttonY, .y), (pad.buttonMenu, .menu),
            (pad.rightShoulder, .rightShoulder), (pad.leftShoulder, .leftShoulder),
            (pad.dpad.left, .left), (pad.dpad.right, .right), (pad.dpad.up, .up), (pad.dpad.down, .down),
        ]
        for (input, button) in buttons {
            input.pressedChangedHandler = { _, _, pressed in
                guard pressed else { return }
                MainActor.assumeIsolated { GameControllerInput.shared.press(button) }
            }
        }
    }

    private func press(_ button: Button) {
        guard let model else { return }
        noteUse(model)
        switch button {
        case .a: pressA(model)
        case .b: model.skipToResult()
        case .x: model.setLens(!model.lensOn)
        case .y:
            guard !model.menuOpen else { return }
            model.requestShotPanel(.toggle)
        case .menu:
            if !model.menuOpen { model.openMenu() }
        case .rightShoulder: ShotNarration.step(model, forward: true)
        case .leftShoulder: ShotNarration.step(model, forward: false)
        case .left: pressDpad(model, x: -1, y: 0)
        case .right: pressDpad(model, x: 1, y: 0)
        case .up: pressDpad(model, x: 0, y: 1)
        case .down: pressDpad(model, x: 0, y: -1)
        }
    }

    /// The first press or stick movement tells the model a controller is in use, so the instruction lines (the
    /// hand-over, the panel hint, the spoken first line) speak to it.
    private func noteUse(_ model: ShowpieceModel) {
        if model.inputInUse != .controller { model.inputInUse = .controller }
    }

    // MARK: A

    /// A: the card's main button when a card is up; otherwise the shot.
    private func pressA(_ model: ShowpieceModel) {
        // The menu's own rows are moved through by the system's controller focus; A does nothing to the table.
        guard !model.menuOpen else { return }
        if pressCardButton(model) { return }
        if let shoot {
            // Your shot is open: shoot when the balls are ready, otherwise play or pause the shot on screen.
            if model.aimReady { shoot() } else { model.togglePlay() }
            return
        }
        if model.aimReady, model.personControlsLive {
            model.requestShotPanel(.open)
        } else if !model.aimReady {
            model.togglePlay()
        }
    }

    /// Presses the main (prominent) button of the card on screen, by calling what that button calls. Returns false
    /// when no card with a main button is up. Checked in the order the cards take precedence on screen.
    private func pressCardButton(_ model: ShowpieceModel) -> Bool {
        // The first break's short card: "Learn the shots" is its prominent button.
        if model.openingStage == .firstBreakCard {
            model.learnAfterFirstBreak()
            return true
        }
        if let match = model.match, pressMatchCard(match, model: model) { return true }
        // Ball in hand lifted: Place it (an illegal spot keeps it lifted, and the card says why).
        if model.placingCueBall {
            model.confirmCueBallPlacement()
            return true
        }
        // Free play's ball in hand not yet picked up: Pick up the cue ball.
        if model.match == nil, model.ballInHand != .none, model.canPlaceCueBall, model.aimReady {
            model.beginPlacingCueBall()
            return true
        }
        if pressLessonCard(model.lessonMode) { return true }
        if pressTrickCard(model.trickMode) { return true }
        if pressEightBallCard(model.eightBallMode, model: model) { return true }
        // The stroke drill's Again, shown once a drill stroke has played out.
        let drill = model.strokeDrill
        if drill.isActive, model.aimReady, drill.last != nil, NotebookStory.hasShot(model) {
            drill.again()
            return true
        }
        // Free play, every ball potted: Rack again.
        if model.match == nil, model.tableCleared, model.aimReady {
            model.rackAgain()
            return true
        }
        return false
    }

    /// The match card: Continue on a ruling (or the first answer of a choice it carries), Ready on a hand-over,
    /// Rematch on the result, the first answer of a pending choice while aiming, and See the ruling while a match
    /// shot is still playing. Only a person's decision is pressed: the computer answers its own.
    private func pressMatchCard(_ match: MatchMode, model: ShowpieceModel) -> Bool {
        let personChoice: MatchChoiceAnswer? = match.state.pendingChoice.flatMap { pending in
            match.isComputer(pending.chooser) ? nil : pending.choice.answers.first
        }
        // Compared one phase at a time rather than switched over, so a phase the match adds later simply has no main
        // button here until it is given one.
        let phase = match.phase
        if phase == .ruling {
            if let answer = personChoice { match.answer(answer) } else { match.acknowledgeRuling() }
            return true
        }
        if phase == .handOver {
            match.acknowledgeRuling()
            return true
        }
        if phase == .over {
            match.rematch()
            return true
        }
        if phase == .aiming, let answer = personChoice {
            match.answer(answer)
            return true
        }
        if phase == .shooting, model.matchShotPlaying {
            model.seeRuling()
            return true
        }
        return false
    }

    /// The lesson card's prominent button in each phase (LessonViews): Watch it, Your turn, Next step or Try again
    /// after a guided try, Next lesson once passed, Try again after a missed pass shot or an off-script shot, and the
    /// list after a made exercise (that card has no prominent button; the list is the way on).
    private func pressLessonCard(_ lesson: LessonMode) -> Bool {
        guard lesson.isActive else { return false }
        switch lesson.phase {
        case .ready:
            lesson.watch()
        case .watching, .replaying, .keyMoment:
            lesson.yourTurn()
        case .judged(let step, let verdict):
            if step == .pass {
                if verdict.made { lesson.nextLesson() } else { lesson.tryAgain() }
            } else if step == .exercise {
                if verdict.made { lesson.listOpen = true } else { lesson.tryAgain() }
            } else {
                if verdict.made { lesson.nextStep() } else { lesson.tryAgain() }
            }
        case .offScript:
            lesson.tryAgain()
        case .aiming, .off:
            return false
        }
        return true
    }

    /// The trick-shot card's prominent button (TrickShotViews): Your turn before the attempt, Next shot after a make,
    /// Try again after a miss or an off-script shot.
    private func pressTrickCard(_ trick: TrickShotMode) -> Bool {
        guard trick.isActive else { return false }
        switch trick.phase {
        case .ready, .watching, .explaining:
            trick.yourTurn()
        case .judged(let verdict):
            if verdict.made { trick.next() } else { trick.tryAgain() }
        case .offScript:
            trick.tryAgain()
        case .aiming, .off:
            return false
        }
        return true
    }

    /// Behind the 8-Ball's card (EightBallViews): Make your call, then the call itself (the ball the d-pad picked, or
    /// the first callable ball, then its pocket), Skip while a hint plays, Next after a made escape, Try again after
    /// a miss.
    private func pressEightBallCard(_ eight: EightBallMode, model: ShowpieceModel) -> Bool {
        guard eight.isActive else { return false }
        switch eight.phase {
        case .looking:
            eight.startCalling()
        case .calling:
            if let ball = eight.pendingBall {
                guard let pocket = eightBallPocket ?? bestPocket(for: ball, model: model) else { return false }
                eight.pick(pocket: pocket)
                eightBallPocket = nil
            } else {
                guard let first = eight.callableBalls.first else { return false }
                eight.pick(ball: first)
            }
        case .watching:
            eight.skipHint()
        case .scored(let verdict):
            if verdict.madeAsCalled { eight.next() } else { eight.tryAgain() }
        default:
            return false
        }
        return true
    }

    /// The pocket the ghost-ball rule finds easiest for a ball from where the striking ball sits (clear lines first,
    /// then the smallest cut).
    private func bestPocket(for ball: Int, model: ShowpieceModel) -> EightBallPocket? {
        TableLines.bestPot(ball: ball, cueBall: model.strikeBall, in: model.layout, table: model.timeline.table)
            .flatMap { EightBallPocket(rawValue: $0.pocket) }
    }

    // MARK: D-pad

    /// One d-pad press. `x` is +1 for right, `y` +1 for up.
    private func pressDpad(_ model: ShowpieceModel, x: Int, y: Int) {
        guard !model.menuOpen, model.personControlsLive else { return }
        if model.placingCueBall {
            moveLifted(model, screenStep: CGPoint(x: CGFloat(x) * Self.placementProbe, y: CGFloat(-y) * Self.placementProbe))
            return
        }
        if stepMatchCall(model, x: x, y: y) || stepEightBallCall(model.eightBallMode, model: model, x: x, y: y) { return }
        guard model.aimReady else { return }
        // Right turns the line clockwise as seen, like the stick (one quarter-degree step per press).
        if x != 0 { model.nudgeAim(-turnSign() * Double(x)) }
        if y != 0 { stepCueAngle(model, up: y > 0) }
    }

    /// Ball in hand: move the lifted ball one ball radius the way the d-pad points on screen. The screen step is
    /// projected back onto the table through the live camera, so up is up from any camera angle (AimOverlay's
    /// arrow-key rule). Without a camera yet (the very first frame), nothing moves.
    private func moveLifted(_ model: ShowpieceModel, screenStep step: CGPoint) {
        guard let bridge, let root = bridge.table?.root,
              let proj = AimProjector(camera: AimProjector.CameraBox().find(in: root), size: bridge.viewSize,
                                      frame: TableFrame(model.timeline.table)) else { return }
        let at = CueBallPlacement.spot(model)
        guard let s = proj.screen(at), let there = proj.table(at: CGPoint(x: s.x + step.x, y: s.y + step.y)) else { return }
        let d = there - at
        guard d.lengthSquared > 1e-12 else { return }
        model.moveCueBallCandidate(to: at + d.normalized * model.timeline.table.ballRadius)
    }

    /// The match's eight-ball call: left and right step through the balls the rules let the shooter call (with the
    /// easiest pocket for each), up and down through the six pockets for the ball called. Each step is the call the
    /// shot will be played on (MatchMode.setCall), shown by the call card and spoken for VoiceOver.
    private func stepMatchCall(_ model: ShowpieceModel, x: Int, y: Int) -> Bool {
        guard let match = model.match, match.mustCall, match.phase == .aiming, match.personMayAct,
              match.state.pendingChoice == nil else { return false }
        let callable = match.state.ballsLeft.filter { match.rules.mayCall($0, in: match.state) }.sorted()
        guard !callable.isEmpty else { return false }
        let current = match.currentCall?.ball ?? match.suggestedCall?.ball
        let ball: Int
        let pocket: EightBallPocket
        if x != 0 {
            let i = current.flatMap { callable.firstIndex(of: $0) }
            ball = i.map { callable[($0 + x + callable.count) % callable.count] } ?? callable[0]
            guard let best = bestPocket(for: ball, model: model) ?? EightBallPocket.allCases.first else { return true }
            pocket = best
        } else {
            ball = current ?? callable[0]
            let now = match.currentCall?.pocket ?? match.suggestedCall?.pocket ?? bestPocket(for: ball, model: model)
            let all = EightBallPocket.allCases
            let i = now.flatMap { all.firstIndex(of: $0) } ?? 0
            pocket = all[(i + y + all.count) % all.count]
        }
        let call = EightBallCall.ball(ball, pocket: pocket)
        match.setCall(call)
        ShotNarration.answer(MatchWords.callLine(call))
        return true
    }

    /// Behind the 8-Ball while calling: left and right step the picked ball through the callable ones, up and down
    /// step the pocket A will call it into.
    private func stepEightBallCall(_ eight: EightBallMode, model: ShowpieceModel, x: Int, y: Int) -> Bool {
        guard eight.isActive, eight.phase == .calling else { return false }
        let callable = eight.callableBalls
        guard !callable.isEmpty else { return true }
        if x != 0 {
            let i = eight.pendingBall.flatMap { callable.firstIndex(of: $0) }
            let ball = i.map { callable[($0 + x + callable.count) % callable.count] } ?? callable[0]
            eight.pick(ball: ball)
            eightBallPocket = nil
            ShotNarration.answer(TableWords.capitalized(TableWords.ballName(ball)))
        } else if let ball = eight.pendingBall {
            let all = EightBallPocket.allCases
            let now = eightBallPocket ?? bestPocket(for: ball, model: model)
            let i = now.flatMap { all.firstIndex(of: $0) } ?? 0
            let next = all[(i + y + all.count) % all.count]
            eightBallPocket = next
            ShotNarration.answer(next.title)
        }
        return true
    }

    /// Up and down: the cue angle one step through the angles the cue-angle menu offers, through the model's locked
    /// setter (a lesson that has fixed the angle refuses it there, as it refuses the menu).
    private func stepCueAngle(_ model: ShowpieceModel, up: Bool) {
        guard model.elevationAllowed else { return }
        let angles = CueAngleMenu.angles
        let now = CueAngleMenu.nearestAngle(toSine: model.activeElevation)
        guard let i = angles.firstIndex(of: now) else { return }
        let j = min(max(i + (up ? 1 : -1), 0), angles.count - 1)
        model.activeElevation = CueAngleMenu.sine(forAngle: angles[j])
    }

    // MARK: Sticks and triggers

    /// Read the sticks and triggers once a frame (called from the scene's update with the frame's time step).
    /// Only acts while the balls are ready for the next shot, the menu is closed and the person may act (not on the
    /// computer's turn), the same rule as the aim drag.
    func step(_ dt: Double, model: ShowpieceModel) {
        guard let pad = GCController.current?.extendedGamepad ?? GCController.controllers().first?.extendedGamepad,
              model.aimReady, !model.menuOpen, model.personControlsLive else { return }
        let dt = min(dt, 1.0 / 20.0)
        func live(_ v: Float) -> Double { abs(v) < Self.deadZone ? 0 : Double(v) }

        // Aim: stick right turns the line clockwise as seen, i.e. the negative way on the plan when turnSign is +1.
        let turn = live(pad.leftThumbstick.xAxis.value)
        // Power: the right trigger raises it, the left lowers it.
        let power = live(pad.rightTrigger.value) - live(pad.leftTrigger.value)
        // Tip: the right stick pushes the dot.
        let side = live(pad.rightThumbstick.xAxis.value), up = live(pad.rightThumbstick.yAxis.value)
        guard turn != 0 || power != 0 || side != 0 || up != 0 else { return }
        noteUse(model)

        if turn != 0 { model.nudgeAim(-turnSign() * turn * Self.aimStepsPerSecond * dt) }
        if power != 0 { model.powerFraction += power * Self.powerPerSecond * dt }
        if side != 0 || up != 0 {
            // Kept inside the reachable disc, as TipPicker keeps it.
            let limit = model.tipLimit
            var x = model.activeTipSide / limit + side * Self.tipPerSecond * dt
            var y = model.activeTipUp / limit + up * Self.tipPerSecond * dt
            let len = (x * x + y * y).squareRoot()
            if len > 1 { x /= len; y /= len }
            model.activeTipSide = x * limit
            model.activeTipUp = y * limit
        }
    }
}
