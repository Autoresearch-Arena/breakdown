// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Checks for the Lens clip's projection (ClipOverlay.project, App/Clips/ClipOverlay.swift, 0.7.7): a point
//          straight ahead lands in the middle of the canvas, a point on the top edge of the 45-degree vertical field
//          of view lands on the top edge, a point behind the eye gives nothing, and a point in view lands exactly where
//          the camera's own projection (CameraFraming.project) puts it, so the ring sits where the game's would.
// SRP/DRY check: Pass - checks only.
@testable import Breakdown
import CoreGraphics
import XCTest
import simd

final class ClipOverlayTests: XCTestCase {
    private let canvas = ClipShape.upright.canvas
    private let eye = SIMD3<Float>(0, 1, 0)
    private let forward = SIMD3<Float>(0, 0, -1)

    func testAPointStraightAheadLandsInTheMiddle() throws {
        let p = try XCTUnwrap(ClipOverlay.project(SIMD3(0, 1, -2), eye: eye, forward: forward, canvas: canvas))
        XCTAssertEqual(p.x, canvas.width / 2, accuracy: 0.01)
        XCTAssertEqual(p.y, canvas.height / 2, accuracy: 0.01)
    }

    func testAPointOnTheTopEdgeOfTheFieldOfViewLandsAtTheTop() throws {
        let half = Float(22.5 * Double.pi / 180)
        let p = try XCTUnwrap(ClipOverlay.project(SIMD3(0, 1 + 2 * tan(half), -2), eye: eye, forward: forward,
                                                  canvas: canvas))
        XCTAssertEqual(p.y, 0, accuracy: 0.5)
        XCTAssertEqual(p.x, canvas.width / 2, accuracy: 0.01)
    }

    func testAPointBehindTheEyeGivesNothing() {
        XCTAssertNil(ClipOverlay.project(SIMD3(0, 1, 2), eye: eye, forward: forward, canvas: canvas))
        XCTAssertNil(ClipOverlay.project(eye, eye: eye, forward: forward, canvas: canvas))
    }

    func testAPointInViewMatchesTheCamerasOwnProjection() throws {
        let world = SIMD3<Float>(0.3, 0.2, -1.5)
        let p = try XCTUnwrap(ClipOverlay.project(world, eye: eye, forward: forward, canvas: canvas))
        let q = CameraFraming.project(world, position: eye, target: eye + forward, size: canvas, fovDegrees: 45)
        XCTAssertEqual(p.x, q.x, accuracy: 1e-6)
        XCTAssertEqual(p.y, q.y, accuracy: 1e-6)
    }
}
