// Author: Claude Sonnet 5.5 Medium
// Date: 13-November-2026
// PURPOSE: The camera. Owns the rig and the perspective camera, frames the whole table for the current window shape
//          and control-bar height, and swings from a low three-quarter view to straight down as the Lens melts in.
//          Anything about where the camera is, how it moves, field of view or framing margins belongs here and only
//          here. Does NOT belong here: table or Lens drawing, ball placement.
//          Split out of TableScene.swift in package 0 of the glow-up plan with no behaviour change.
// SRP/DRY check: Pass - camera maths only; table dimensions arrive as a TableFrame, nothing else is read.
import CoreGraphics
import RealityKit
import simd

@MainActor
final class TableCamera {
    let rig = Entity()
    private let camera = PerspectiveCamera()

    init() {
        camera.camera.fieldOfViewInDegrees = 45
        camera.camera.near = 0.05
        camera.camera.far = 40
        rig.addChild(camera)
    }

    /// Frames the whole table and swings from a low three-quarter view to straight down as the Lens melts in.
    func update(melt: Double, viewSize: CGSize, bottomInset: Double, frame: TableFrame) {
        let aspect = Float(max(0.3, viewSize.width / max(1, viewSize.height)))
        let portrait = aspect < 1
        let L = frame.length, W = frame.width
        // Portrait puts the long side up the screen: the camera moves round to the short edge.
        let phi: Float = portrait ? .pi / 2 : 0
        let halfH = tan(Float(45) * .pi / 360)
        let usable = Float(max(0.5, 1 - bottomInset))
        let horizHalf = (portrait ? W : L) * 0.5 + 0.26
        let vertHalf = (portrait ? L : W) * 0.5 + 0.22
        let dTop = max(horizHalf / (aspect * halfH), vertHalf / (usable * halfH))
        let m = Float(melt)
        let ease = m * m * (3 - 2 * m)
        let elevDeg: Float = 48 + 41 * ease
        let elev = elevDeg * .pi / 180
        let dist = dTop * (1.08 - 0.06 * ease)
        let horizontal = SIMD3<Float>(sin(phi), 0, cos(phi))
        // Push the table up the screen so it clears the control bar: a fraction of the view height, converted
        // to ground distance (foreshortened by the viewing angle).
        let shift = Float(bottomInset) * 0.5 * 2 * halfH * dist / max(0.3, sin(elev))
        let target = horizontal * shift
        let pos = target + (horizontal * cos(elev) + SIMD3(0, sin(elev), 0)) * dist
        camera.look(at: target, from: pos, upVector: SIMD3(0, 1, 0), relativeTo: nil)
    }
}
