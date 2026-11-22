// Author: Claude Opus 5.5 Medium
// Date: 22-November-2026
// PURPOSE: Where a blurb goes on the upright phone (plans/22-Nov-2026-phone-ui-plan.md, Part 3 "Placement"), as pure
//          maths with no SwiftUI so it can be unit-tested (BreakdownTests/BlurbPlacementTests.swift).
//          ANCHORED blurbs (an explanation tied to a moment on the table) go above or below their anchor, never beside
//          it (with the moment framed in the middle there are only about 185 points either side), centred on the
//          anchor's x, kept inside a 16-point margin of the table area, never over the keep-clear rectangle (the moment
//          and its ring), never above the table area's top (the title row or the lowest docked blurb) nor below its
//          bottom (the control strip). The caller passes the side it used last as `preferred`, so a blurb keeps its
//          side while it still fits and never jumps during a beat; nil means "no room either side" and the caller
//          docks the blurb instead. DOCKED blurbs stack top down from the top of their area, 6 apart, in the order
//          given; dockedFrames says where each lands and dockedBottom where the table framing may begin.
//          All rectangles share one space (StageSpace on the stage: points, y down).
// SRP/DRY check: Pass - checked CameraFraming.swift (frames the 3D table, not overlays), CaptionViews.swift (the old
//          chip beside the ring clamps itself to the stage; it is dropped on the upright phone) and LensCallouts.swift
//          (places its tips against the playback row, not against a moment). No other overlay placement exists.
import CoreGraphics

enum BlurbPlacement {
    /// Least distance from a blurb to the table area's left and right edges.
    static let margin: CGFloat = 16
    /// Distance between the anchor (or the keep-clear rectangle) and the blurb's near edge: room for the leader.
    static let gap: CGFloat = 14
    /// Space between docked blurbs.
    static let dockSpacing: CGFloat = 6
    /// How far the leader's end may come to the blurb's corner, so it meets a straight edge.
    static let leaderInset: CGFloat = 12

    enum Side: Equatable, Sendable { case above, below }

    /// An anchored blurb's place: its frame, the side it took, and the two ends of its leader (from the anchor to the
    /// middle of the blurb's near edge, nudged toward the anchor's x).
    struct Anchored: Equatable, Sendable {
        let frame: CGRect
        let side: Side
        let leaderFrom: CGPoint
        let leaderTo: CGPoint
    }

    /// The frame for a blurb of `size` tied to `anchor`.
    /// - tableArea: the room between the title row (or the lowest docked blurb) and the control strip.
    /// - keepClear: what the blurb must never cover (the moment and its ring); nil or empty for nothing.
    /// - preferred: the side to try first; pass the side the blurb had for this beat to keep it steady. Below by default:
    ///   while an anchored blurb shows, the moment is framed at about 35 per cent of the table area's height.
    /// Returns nil when neither side has room (the caller then docks the blurb at the top of the table area).
    static func anchored(anchor: CGPoint, size: CGSize, tableArea: CGRect, keepClear: CGRect? = nil,
                         preferred: Side = .below) -> Anchored? {
        guard size.width > 0, size.height > 0, !tableArea.isEmpty else { return nil }
        let clear = keepClear.flatMap { $0.isEmpty ? nil : $0 }
        let x = horizontalOrigin(anchorX: anchor.x, width: size.width, tableArea: tableArea)
        for side in [preferred, preferred == .below ? Side.above : Side.below] {
            if let frame = frame(side: side, x: x, anchor: anchor, size: size, tableArea: tableArea, keepClear: clear) {
                return Anchored(frame: frame, side: side, leaderFrom: anchor, leaderTo: leaderEnd(frame: frame, side: side, anchorX: anchor.x))
            }
        }
        return nil
    }

    /// Centred on the anchor's x, then pushed back inside the margins. A blurb wider than the area less its margins
    /// starts at the left margin (the caller caps blurb widths, so this only happens on a tiny window).
    static func horizontalOrigin(anchorX: CGFloat, width: CGFloat, tableArea: CGRect) -> CGFloat {
        let lo = tableArea.minX + margin
        let hi = tableArea.maxX - margin - width
        guard hi >= lo else { return lo }
        return min(max(anchorX - width / 2, lo), hi)
    }

    /// The frame on one side, or nil when it would leave the table area or cover the keep-clear rectangle.
    private static func frame(side: Side, x: CGFloat, anchor: CGPoint, size: CGSize, tableArea: CGRect,
                              keepClear: CGRect?) -> CGRect? {
        // The keep-clear rectangle only pushes the blurb if the two share some width; otherwise the anchor alone does.
        // Pushing past it (not just past the anchor) is what keeps the moment and its ring uncovered.
        let blocker = keepClear.flatMap { $0.maxX > x && $0.minX < x + size.width ? $0 : nil }
        let frame: CGRect
        switch side {
        case .below:
            let top = max(anchor.y, blocker?.maxY ?? anchor.y) + gap
            frame = CGRect(x: x, y: top, width: size.width, height: size.height)
        case .above:
            let bottom = min(anchor.y, blocker?.minY ?? anchor.y) - gap
            frame = CGRect(x: x, y: bottom - size.height, width: size.width, height: size.height)
        }
        // Never under the title row or the docked blurbs (the area's top), never under the strip (its bottom).
        guard frame.minY >= tableArea.minY, frame.maxY <= tableArea.maxY else { return nil }
        if let keepClear, frame.intersects(keepClear) { return nil }
        return frame
    }

    /// The leader meets the blurb's near edge at the anchor's x, kept off the rounded corners.
    private static func leaderEnd(frame: CGRect, side: Side, anchorX: CGFloat) -> CGPoint {
        let inset = min(leaderInset, frame.width / 2)
        let x = min(max(anchorX, frame.minX + inset), frame.maxX - inset)
        return CGPoint(x: x, y: side == .below ? frame.minY : frame.maxY)
    }

    // MARK: Docked

    /// Docked blurbs, top down from `top` in the order given, 6 apart, each at the left margin of `area`.
    static func dockedFrames(sizes: [CGSize], top: CGFloat, area: CGRect) -> [CGRect] {
        var y = top
        var frames: [CGRect] = []
        for size in sizes {
            frames.append(CGRect(x: area.minX + margin, y: y, width: size.width, height: size.height))
            y += size.height + dockSpacing
        }
        return frames
    }

    /// Where the docked stack ends (the table framing starts here): `top` when nothing is docked.
    static func dockedBottom(sizes: [CGSize], top: CGFloat) -> CGFloat {
        guard !sizes.isEmpty else { return top }
        return top + sizes.reduce(0) { $0 + $1.height } + dockSpacing * CGFloat(sizes.count - 1)
    }
}
