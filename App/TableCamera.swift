// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: The camera. Owns the rig and the perspective camera, frames the WHOLE table (rails included) inside the
//          part of the screen that is free of the status bar, the title row and the control strip, and swings from a
//          low three-quarter view to straight down as the Lens melts in. With Reduce Motion on it never swings: the
//          view holds one near-overhead angle and the existing opacity cross-fade carries the melt.
//          Also owns a small "HUD anchor" parented to the camera, scaled so one unit is one screen point, where the
//          Lens layer hangs its colour legend so it stays put on screen while the camera moves.
//          The framing maths lives in CameraFraming.swift (pure, tested by a harness); this file reads the window
//          (size and safe-area insets) and the accessibility setting and applies the answer to the entities.
//          Anything about where the camera is, how it moves, field of view or framing margins belongs here and only
//          here. Does NOT belong here: table or Lens drawing, ball placement.
//          History: split out of TableScene.swift in package 0; framing rewritten in package 2 of the glow-up plan
//          (the old formula ignored the status bar and title, so the table ran off the top and sides in portrait).
// SRP/DRY check: Pass - camera placement only; framing maths is in CameraFraming, table size arrives as a TableFrame.
import CoreGraphics
import Foundation
import RealityKit
import simd
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

@MainActor
final class TableCamera {
    let rig = Entity()
    /// Child of the camera; one local unit equals one screen point. The Lens legend is parented here.
    let hud = Entity()
    private let camera = PerspectiveCamera()
    private static let fov: Float = 45
    /// How far in front of the camera the HUD plane floats. Anything nearer than the table is fine; nearer than 0.05 is clipped.
    private static let hudDistance: Float = 1.5
    /// Metres the rails and corner blocks reach past the playing surface (cushion 0.04 plus rail 0.16, with a hair spare).
    private static let railReach: Float = 0.21
    /// Rail top height above the cloth, so the near rail's top edge is framed too.
    private static let railHeight: Float = 0.075
    /// The one overhead-ish angle Reduce Motion holds, in degrees. Near the Lens angle so the cross-fade lines up.
    private static let reducedMotionElevation: Float = 80

    init() {
        camera.camera.fieldOfViewInDegrees = Self.fov
        camera.camera.near = 0.05
        camera.camera.far = 40
        rig.addChild(camera)
        camera.addChild(hud)
    }

    /// True when the person asked the system for less motion (or a test launch forced it with -forceReduceMotion).
    static var reduceMotion: Bool {
        if ProcessInfo.processInfo.arguments.contains("-forceReduceMotion") { return true }
        #if canImport(UIKit)
        return UIAccessibility.isReduceMotionEnabled
        #else
        return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        #endif
    }

    /// The real size of the window and its safe-area insets, in points. The screen hands the scene only the inside of
    /// the safe area, but the 3D view fills the whole window, so the camera has to ask the window itself.
    /// Returns nil before a window exists (first frames, previews); the caller then trusts the size it was given.
    private static func windowMetrics() -> (size: CGSize, safe: FramingInsets)? {
        #if canImport(UIKit)
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first,
              let window = scene.keyWindow ?? scene.windows.first, window.bounds.width > 1 else { return nil }
        let i = window.safeAreaInsets
        return (window.bounds.size, FramingInsets(top: i.top, left: i.left, bottom: i.bottom, right: i.right))
        #else
        guard let window = NSApp.keyWindow ?? NSApp.windows.first, let view = window.contentView, view.bounds.width > 1 else { return nil }
        // With a full-size content view the title bar shows up as a top safe inset; otherwise the inset is zero.
        let i = view.safeAreaInsets
        return (view.bounds.size, FramingInsets(top: i.top, left: i.left, bottom: i.bottom, right: i.right))
        #endif
    }

    /// Frames the whole table and swings from a low three-quarter view to straight down as the Lens melts in.
    /// - viewSize: the size the screen's overlay was laid out in (inside the safe area); used only if no window is found.
    /// - bottomInset: the control strip's share of that height, as the screen computes it.
    /// - topInset: extra points of the top the screen wants kept clear (a caption column, say). Zero today.
    func update(melt: Double, viewSize: CGSize, bottomInset: Double, topInset: Double = 0, frame: TableFrame) {
        let metrics = Self.windowMetrics()
        let size = metrics?.size ?? viewSize
        let safe = metrics?.safe ?? FramingInsets()
        let controls = bottomInset * Double(max(1, viewSize.height))
        let layout = CameraFraming.layout(size: size, safe: safe, controlsHeight: controls,
                                          extra: FramingInsets(top: topInset))

        // Portrait puts the long side up the screen: the camera moves round to the short edge.
        let portrait = size.width < size.height
        let yaw: Float = portrait ? .pi / 2 : 0
        let m = Float(melt)
        let ease = m * m * (3 - 2 * m)
        let elevDeg: Float = Self.reduceMotion ? Self.reducedMotionElevation : 48 + 41 * ease
        let pose = CameraFraming.pose(size: size, rect: layout.tableRect, yaw: yaw, elevation: elevDeg * .pi / 180,
                                      halfX: frame.length * 0.5 + Self.railReach, halfZ: frame.width * 0.5 + Self.railReach,
                                      rimHeight: Self.railHeight, fovDegrees: Self.fov)
        camera.look(at: pose.target, from: pose.position, upVector: SIMD3(0, 1, 0), relativeTo: nil)

        // HUD anchor: at the legend's spot, scaled so a local unit is one point on screen.
        let kY = tan(Self.fov * .pi / 360), d = Self.hudDistance
        let h = Float(max(1, size.height)), w = Float(max(1, size.width))
        let perPoint = 2 * kY * d / h
        let nx = Float(layout.legendCenter.x) / w * 2 - 1, ny = 1 - Float(layout.legendCenter.y) / h * 2
        hud.position = SIMD3(nx * kY * (w / h) * d, ny * kY * d, -d)
        hud.scale = SIMD3(repeating: perPoint)
    }
}
