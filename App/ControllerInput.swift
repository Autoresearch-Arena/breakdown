// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Play with a game controller (accessibility plan, package 5): any controller the system's GameController
//          framework knows as an extended gamepad, including the adaptive controllers many players with limited
//          movement use. The mapping:
//            left stick, left and right ... turns the aim (faster the further it is pushed)
//            right trigger / left trigger . more / less power (by how hard each is squeezed)
//            right stick ................... moves the cue tip on the cue ball (follow, draw, side); it stays put when
//                                            the stick is let go, like the tip picker
//            A ............................ shoot (while the shot panel is open), otherwise play or pause the replay
//            B ............................ skip to where the balls came to rest (ready to aim)
//            X ............................ Physics Lens on or off
//            right / left shoulder ......... step the replay to the next / previous explained moment (read aloud)
//          Nothing needs a button held for a time: every press is one action, and the sticks and triggers only move
//          values the player can also set with a touch, the keyboard or VoiceOver.
//          GameControllerInput.shared is started by TableStage, which also calls step(_:model:) once a frame from the
//          scene's update (the sticks and triggers are read there, so a held stick turns the aim smoothly). Buttons
//          are edge-triggered through the framework's pressed handlers. AimOverlay registers what A does while the
//          shot panel is open (fire, and close the panel on a break) and the screen direction of a turn.
//          Declared in Breakdown-Info.plist (GCSupportsControllerUserInteraction, GCSupportedGameControllers).
// SRP/DRY check: Pass - checked AimOverlay.handleKey (the keyboard route) and AimGauges (tip and power); this file
//          writes the same model values through the same methods (nudgeAim, powerFraction, activeTipUp/Side, fire,
//          scrub, setLens), so every input route agrees. Replay stepping reuses ShotNarration.step.
import Foundation
import GameController

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

    // MARK: Hooks the aiming layer sets while the shot panel is open

    /// What A does while aiming; nil when the shot panel is closed.
    var shoot: (() -> Void)?
    /// +1 or -1: which way on the table plan "stick right" turns the line so it turns right as the player sees it
    /// (AimOverlay works it out from the camera, as for the arrow keys). +1 when no aiming layer is up.
    var turnSign: () -> Double = { 1 }

    private weak var model: ShowpieceModel?
    private var observers: [NSObjectProtocol] = []

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

    private func configureAll() {
        for controller in GCController.controllers() { configure(controller) }
    }

    /// Buttons: one action per press (pressed changes from false to true), never a hold.
    private func configure(_ controller: GCController) {
        guard let pad = controller.extendedGamepad else { return }
        pad.buttonA.pressedChangedHandler = { _, _, pressed in
            guard pressed else { return }
            MainActor.assumeIsolated { GameControllerInput.shared.pressA() }
        }
        pad.buttonB.pressedChangedHandler = { _, _, pressed in
            guard pressed else { return }
            MainActor.assumeIsolated { GameControllerInput.shared.model?.skipToResult() }
        }
        pad.buttonX.pressedChangedHandler = { _, _, pressed in
            guard pressed else { return }
            MainActor.assumeIsolated {
                guard let m = GameControllerInput.shared.model else { return }
                m.setLens(!m.lensOn)
            }
        }
        pad.rightShoulder.pressedChangedHandler = { _, _, pressed in
            guard pressed else { return }
            MainActor.assumeIsolated {
                guard let m = GameControllerInput.shared.model else { return }
                ShotNarration.step(m, forward: true)
            }
        }
        pad.leftShoulder.pressedChangedHandler = { _, _, pressed in
            guard pressed else { return }
            MainActor.assumeIsolated {
                guard let m = GameControllerInput.shared.model else { return }
                ShotNarration.step(m, forward: false)
            }
        }
    }

    private func pressA() {
        guard let model, !model.menuOpen else { return }
        if let shoot, model.aimReady { shoot() } else { model.togglePlay() }
    }

    /// Read the sticks and triggers once a frame (called from the scene's update with the frame's time step).
    /// Only acts while the balls are ready for the next shot and the menu is closed, the same rule as the aim drag.
    func step(_ dt: Double, model: ShowpieceModel) {
        guard let pad = GCController.current?.extendedGamepad ?? GCController.controllers().first?.extendedGamepad,
              model.aimReady, !model.menuOpen else { return }
        let dt = min(dt, 1.0 / 20.0)
        func live(_ v: Float) -> Double { abs(v) < Self.deadZone ? 0 : Double(v) }

        // Aim: stick right turns the line clockwise as seen, i.e. the negative way on the plan when turnSign is +1.
        let turn = live(pad.leftThumbstick.xAxis.value)
        if turn != 0 { model.nudgeAim(-turnSign() * turn * Self.aimStepsPerSecond * dt) }

        // Power: the right trigger raises it, the left lowers it.
        let power = live(pad.rightTrigger.value) - live(pad.leftTrigger.value)
        if power != 0 { model.powerFraction += power * Self.powerPerSecond * dt }

        // Tip: the right stick pushes the dot; it is kept inside the reachable disc, as TipPicker keeps it.
        let side = live(pad.rightThumbstick.xAxis.value), up = live(pad.rightThumbstick.yAxis.value)
        if side != 0 || up != 0 {
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
