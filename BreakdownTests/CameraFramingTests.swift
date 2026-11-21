// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The table-framing maths (App/CameraFraming.swift) swept over screen shapes, safe areas, title rows, control
//          strips, camera angles and table sizes. This is the sweep CameraFraming's header asks for, as a test: for every
//          case it fits the camera with CameraFraming.pose, then projects the table's corners with CameraFraming.project
//          (built from a look-at and a perspective matrix, deliberately not from pose's formulas, so it is an independent
//          check) and asserts THE INVARIANT the header states: the playing-area corners land inside Framing.inner, the
//          rail-outline corners (at cloth level and at rail height) inside Framing.outer, and at least one corner touches
//          its edge, so the table is as large as it can be. Also the push-in curve and the warm view's angle.
// SRP/DRY check: Pass - no framing logic here. The extents mirror the ones TableCamera builds (its rail reach, rail
//          height and playing-area reach are private, so they are restated below with where they come from).
@testable import Breakdown
import CoreGraphics
import simd
import XCTest

final class CameraFramingTests: XCTestCase {
    /// TableCamera's field of view, degrees (TableCamera.fov).
    private let fov: Float = 45
    /// How far a corner may sit outside its rectangle, in points: the projection runs in Float, so a few
    /// hundredths of a point of rounding is expected; half a point is still invisible.
    private let inside = 0.5
    /// How close the nearest corner must come to its edge for the fit to count as "as large as it can be", points.
    /// The pose's bisection leaves far less slack than this.
    private let touching = 1.0

    /// Table extents as TableCamera builds them: rails reach 0.21 m past the cloth (TableCamera.railReach), the rail tops
    /// stand 0.075 m above it (railHeight), the playing area runs 0.08 m past it to take in the pocket holes (playReach).
    private func extents(length: Float, width: Float) -> TableExtents {
        TableExtents(halfX: length * 0.5 + 0.21, halfZ: width * 0.5 + 0.21, rimHeight: 0.075,
                     playX: length * 0.5 + 0.08, playZ: width * 0.5 + 0.08)
    }

    private struct Screen {
        var name: String
        var size: CGSize
        var safe: FramingInsets
        /// Height of the title row below the safe top, and of the control strip above the safe bottom (nil: controls
        /// in a side column, so the table may run to the bottom).
        var header: Double
        var controls: Double?
    }

    private let screens: [Screen] = [
        Screen(name: "phone upright", size: CGSize(width: 402, height: 874),
               safe: FramingInsets(top: 62, left: 0, bottom: 34, right: 0), header: 48, controls: 150),
        Screen(name: "phone upright, panel closed", size: CGSize(width: 402, height: 874),
               safe: FramingInsets(top: 62, left: 0, bottom: 34, right: 0), header: 48, controls: 64),
        Screen(name: "phone sideways", size: CGSize(width: 874, height: 402),
               safe: FramingInsets(top: 0, left: 62, bottom: 21, right: 62), header: 44, controls: nil),
        Screen(name: "small phone upright", size: CGSize(width: 375, height: 667),
               safe: FramingInsets(top: 20, left: 0, bottom: 0, right: 0), header: 44, controls: 140),
        Screen(name: "tablet upright", size: CGSize(width: 1032, height: 1376),
               safe: FramingInsets(top: 24, left: 0, bottom: 20, right: 0), header: 52, controls: 120),
        Screen(name: "tablet sideways", size: CGSize(width: 1376, height: 1032),
               safe: FramingInsets(top: 24, left: 0, bottom: 20, right: 0), header: 52, controls: nil),
        Screen(name: "two-screen phone open", size: CGSize(width: 951, height: 669),
               safe: FramingInsets(top: 24, left: 0, bottom: 20, right: 0), header: 44, controls: 100),
        Screen(name: "Mac window", size: CGSize(width: 1280, height: 800),
               safe: FramingInsets(top: 28, left: 0, bottom: 0, right: 0), header: 44, controls: 90),
        Screen(name: "narrow Mac window", size: CGSize(width: 520, height: 900),
               safe: FramingInsets(top: 28, left: 0, bottom: 0, right: 0), header: 44, controls: 160),
        Screen(name: "very wide window", size: CGSize(width: 2000, height: 600),
               safe: FramingInsets(), header: 40, controls: 80),
        Screen(name: "largest text, chrome nearly meeting", size: CGSize(width: 402, height: 874),
               safe: FramingInsets(top: 62, left: 0, bottom: 34, right: 0), header: 330, controls: 420),
    ]

    private func request(_ s: Screen) -> FramingRequest {
        let h = Double(s.size.height)
        return FramingRequest(size: s.size, safe: s.safe, headerBottom: s.safe.top + s.header,
                              controlsTop: s.controls.map { h - s.safe.bottom - $0 })
    }

    /// How far inside `r` the point is: the smallest distance to any edge, negative when outside.
    private func margin(_ p: CGPoint, _ r: FramingRect) -> Double {
        min(Double(p.x) - r.left, r.right - Double(p.x), Double(p.y) - r.top, r.bottom - Double(p.y))
    }

    func testEveryCornerStaysInItsRectangleAndTheFitIsTight() {
        let tables = [("pool", extents(length: 2.54, width: 1.27)), ("bumper", extents(length: 1.37, width: 0.84)),
                      ("bar", extents(length: 2.0, width: 0.9))]
        let degrees: [Float] = [30, 48, 60, 74, 89, 90]
        for screen in screens {
            let q = request(screen)
            let framing = CameraFraming.framing(q)
            // The outer rectangle must always contain the inner one (the sliver rule must not break that).
            XCTAssertLessThanOrEqual(framing.outer.top, framing.inner.top, screen.name)
            XCTAssertGreaterThanOrEqual(framing.outer.bottom, framing.inner.bottom, screen.name)
            XCTAssertGreaterThan(framing.inner.width, 0, screen.name)
            XCTAssertGreaterThan(framing.inner.height, 0, screen.name)
            // TableCamera turns the camera round to the short edge when the screen is upright.
            let yaw: Float = screen.size.width < screen.size.height ? .pi / 2 : 0
            for (tableName, table) in tables {
                var angles = degrees.map { $0 * .pi / 180 }
                angles.append(CameraFraming.warmElevation(size: screen.size, framing: framing, yaw: yaw, table: table,
                                                          fovDegrees: fov))
                for el in angles {
                    let pose = CameraFraming.pose(size: screen.size, framing: framing, yaw: yaw, elevation: el,
                                                  table: table, fovDegrees: fov)
                    let label = "\(screen.name), \(tableName), \(el * 180 / .pi) degrees"
                    var closest = Double.infinity
                    func check(_ p: SIMD3<Float>, _ box: FramingRect, _ what: String) {
                        let s = CameraFraming.project(p, position: pose.position, target: pose.target,
                                                      size: screen.size, fovDegrees: fov)
                        let m = margin(s, box)
                        XCTAssertGreaterThanOrEqual(m, -inside, "\(label): \(what) corner at \(s) is outside \(box)")
                        closest = min(closest, m)
                    }
                    for sx: Float in [-1, 1] {
                        for sz: Float in [-1, 1] {
                            check(SIMD3(sx * table.halfX, 0, sz * table.halfZ), framing.outer, "rail")
                            check(SIMD3(sx * table.halfX, table.rimHeight, sz * table.halfZ), framing.outer, "rail top")
                            check(SIMD3(sx * table.playX, 0, sz * table.playZ), framing.inner, "playing area")
                        }
                    }
                    XCTAssertLessThanOrEqual(closest, touching, "\(label): no corner touches its edge (slack \(closest))")
                    XCTAssertGreaterThan(pose.distance, 0, label)
                }
            }
        }
    }

    func testPushInIsAPureFunctionOfTheClockThatStartsAndEndsAtZero() {
        for d in [0.4, 1.0, 3.0, 8.0, 20.0] {
            XCTAssertEqual(CameraFraming.push(clock: 0, duration: d), 0, accuracy: 1e-6, "duration \(d)")
            XCTAssertEqual(CameraFraming.push(clock: d, duration: d), 0, accuracy: 1e-6, "duration \(d)")
            var t = 0.0
            while t <= d {
                let p = CameraFraming.push(clock: t, duration: d)
                XCTAssertTrue((0...1).contains(p))
                XCTAssertEqual(p, CameraFraming.push(clock: t, duration: d), "same clock, same push")
                t += d / 97
            }
        }
        // The fitted distance is the exact fit with no motion, and the push only ever brings the camera in.
        XCTAssertEqual(CameraFraming.distanceScale(push: 1, intro: 1, motionAllowed: false), 1)
        XCTAssertEqual(CameraFraming.distanceScale(push: 0, intro: 0, motionAllowed: true), 1)
        XCTAssertEqual(CameraFraming.distanceScale(push: 1, intro: 0, motionAllowed: true),
                       1 - CameraFraming.pushDepth, accuracy: 1e-6)
    }

    func testWarmAngleStaysInItsRangeAndOnlyTiltsForTallScreens() {
        let table = extents(length: 2.54, width: 1.27)
        let low = CameraFraming.warmElevationBase * .pi / 180, high = CameraFraming.warmElevationMax * .pi / 180
        for screen in screens {
            let framing = CameraFraming.framing(request(screen))
            let yaw: Float = screen.size.width < screen.size.height ? .pi / 2 : 0
            let el = CameraFraming.warmElevation(size: screen.size, framing: framing, yaw: yaw, table: table,
                                                 fovDegrees: fov)
            XCTAssertGreaterThanOrEqual(el, low - 1e-6, screen.name)
            XCTAssertLessThanOrEqual(el, high + 1e-6, screen.name)
            // When the height already decides the size at the usual angle, the angle stays the usual one.
            let atBase = CameraFraming.pose(size: screen.size, framing: framing, yaw: yaw, elevation: low, table: table,
                                            fovDegrees: fov)
            if !atBase.widthLimited { XCTAssertEqual(el, low, accuracy: 1e-6, screen.name) }
        }
    }
}
