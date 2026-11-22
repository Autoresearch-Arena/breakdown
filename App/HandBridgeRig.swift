// Author: GPT 6.2 Sol
// Date: 21-November-2026
// PURPOSE: Draw a planted bridge hand while aiming. Uses the cue's actual axis and table dimensions to choose a
//          cloth or rail pose and keep the pull-back in front of the hand. The strike simulation is independent.
// SRP/DRY check: CueRig owns the cue and its orientation. The assets contain the hand and cuff.
import BreakdownTimeline
import Foundation
import RealityKit
import simd

@MainActor
final class HandBridgeRig {
    private enum Pose: String, CaseIterable {
        case open = "OpenHandBridge"
        case closed = "ClosedHandBridge"
        case rail = "RailHandBridge"

        /// Cue-axis height in the Blender asset, measured from its supporting surface.
        var supportHeight: Float {
            switch self {
            case .open: 0.0412
            case .closed: 0.038
            case .rail: 0.00692
            }
        }
    }

    let root = Entity()
    private var hands: [Pose: Entity] = [:]

    init() {
        root.name = "HandBridge"
        root.isEnabled = false
    }

    func loadModels() async {
        for pose in Pose.allCases {
            do {
                let hand = try await Entity(named: pose.rawValue, in: Bundle.main)
                hand.isEnabled = false
                root.addChild(hand)
                hands[pose] = hand
            } catch {
                NSLog("HandBridgeRig: could not load %@: %@", pose.rawValue, String(describing: error))
            }
        }
    }

    func hide() {
        root.isEnabled = false
    }

    /// Returns the distance from the contact point to the hand, along the cue shaft.
    func place(contact: SIMD3<Float>, back: SIMD3<Float>, frame: TableFrame, orientation: simd_quatf,
               firmStroke: Bool, timeline: Timeline, at time: Double) -> Float? {
        let horizontal = SIMD2(back.x, back.z)
        let speed = simd_length(horizontal)
        guard speed > 0.8 else { hide(); return nil }
        let half = SIMD2(frame.length, frame.width) * 0.5
        let outward = horizontal / speed

        // Near a perpendicular rail, use the top of the wood as the support surface. The rail pose only fits
        // when the cue actually reaches that height at the rail and the hand is clear of the corner pocket.
        let railDistance = (TableBuilder.railTop + Pose.rail.supportHeight - contact.y) / back.y
        if (0.115...0.39).contains(railDistance) {
            let point = contact + back * railDistance
            let foot = SIMD2(point.x, point.z)
            for axis in 0..<2 where abs(outward[axis]) > 0.86 {
                let across = 1 - axis
                // The exported hand was posed with its support 36 mm behind the inner edge of the wood.
                let inset = abs(foot[axis]) - half[axis] - TableBuilder.cushionDepth
                guard (0.023...0.052).contains(inset),
                      abs(foot[across]) < half[across] - 0.15 else { continue }
                if axis == 1, abs(foot[across]) < 0.14, timeline.table.pockets.count >= 6 { continue }
                if show(.rail, point: point, floor: TableBuilder.railTop, orientation: orientation) {
                    return railDistance
                }
            }
        }

        let pose: Pose = firmStroke ? .closed : .open
        let fittedDistance = (pose.supportHeight - contact.y) / back.y
        let distance: Float = (0.13...0.28).contains(fittedDistance * speed) ? fittedDistance : 0.215 / speed
        let point = contact + back * distance
        let foot = SIMD2(point.x, point.z)
        // Most of the palm is behind the cue support. Keep both the fingers and palm on the bed.
        let wrist = foot + outward * 0.120
        guard abs(foot.x) + 0.085 < half.x, abs(foot.y) + 0.085 < half.y,
              abs(wrist.x) + 0.060 < half.x, abs(wrist.y) + 0.060 < half.y else {
            hide()
            return nil
        }
        // Avoid showing a hand through a ball. Test the palm footprint in the cue's local frame.
        let right = SIMD2(outward.y, -outward.x)
        for ball in timeline.segments.indices.dropFirst() {
            let state = timeline.state(ball: ball, at: time)
            if state.pocketed { continue }
            let location = frame.world(state.position)
            let delta = SIMD2(location.x, location.z) - foot
            let along = simd_dot(delta, outward)
            let across = simd_dot(delta, right)
            let radius = frame.ballRadius
            if (-0.075 - radius)...(0.120 + radius) ~= along,
               (-0.130 - radius)...(0.025 + radius) ~= across {
                hide()
                return nil
            }
        }
        if show(pose, point: point, floor: 0, orientation: orientation) {
            return distance
        }
        hide()
        return nil
    }

    private func show(_ pose: Pose, point: SIMD3<Float>, floor: Float, orientation: simd_quatf) -> Bool {
        guard let selected = hands[pose] else { return false }
        let heightScale = (point.y - floor) / pose.supportHeight
        guard (0.87...1.15).contains(heightScale) else { return false }

        // Anchor to the table, with the vertical scale matching the cue axis at this fixed support point.
        root.position = SIMD3(point.x, floor, point.z)
        root.orientation = orientation
        root.scale = SIMD3(1, heightScale, 1)
        for hand in hands.values { hand.isEnabled = hand === selected }
        root.isEnabled = true
        return true
    }
}
