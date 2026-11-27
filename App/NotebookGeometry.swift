// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 8, the upright iPad's table share settled: the band
//          under the table stays belowPanel, sized from what the table needs, not the design language's 58 percent
//          (Theme.Size.uprightTableShare, read by nothing). The table lies across the iPad's width, so its height on
//          screen is fixed by that width: about 383 points of a 1133-point iPad mini, 418 of an 1180-point 11-inch
//          iPad, 518 of a 1376-point 13-inch one, a third of the height (34 to 38 percent) with its rails a few points
//          from the half's edges. A 58 percent half would be 650 to 800 points tall round that same table, about 270
//          points of empty dark ground above and below it, the dead bands 0.7.10 removed, and the notebook would lose
//          that room. "Framed tight to the rails", the other half of the same rule, wins. No change to the maths.
//          The hinge keeps its own column rule; its panel's margins are Theme.Space.pageMargin(.foldPanel), set in
//          NotebookPanel.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 4, the shot console: the panel beside the table is
//          the design language's side column, about 400 points (380 to 440, following the window: a third of its
//          width, held between the two), so the table gets the rest; and without a hinge the panel is always one
//          column, the step list a tab of the same column, so the upright iPad's band has no empty second column.
//          The names the framing check reads (besideShare, besideMinimum, twoColumnWidth, belowPanel) are kept.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 front door, plans/25-Nov-2026-front-door-and-table-view-plan.md
//          Stage 2: the band under the table on an upright iPad is sized from what the table needs, not a fixed share.
//          At 40 percent of the height, capped at 520 points, the table half of an upright iPad was far taller than a
//          table lying across it can fill at any camera angle, so the table covered only 55 to 61 percent of its
//          half's height with dark bands above and below. The band now takes everything the table does not need
//          (belowPanel), so the table reaches within a few points of all four edges of its half on every upright iPad,
//          and the notebook gets the room. The table is the same size on screen as before (it was already as wide as
//          its half); the half now ends where the table does.)
// PURPOSE: The one rule for when a window is big enough for the notebook layout (the table on one side, the full
//          notebook panel of cards, step-by-step story, numbers and controls on the other) and where the split goes.
//          It reads only the window's size in points, never the device's name, so an iPad in split view or Stage
//          Manager, a resized Mac window and an iPad turned round all get the layout their space deserves:
//            - too small (any phone, an iPad at a third of the screen, a small Mac window): no notebook, and the screen
//              keeps its existing phone layouts exactly as they were;
//            - wider than tall: the panel sits beside the table, taking a fixed share of the width within a minimum and
//              a maximum, and on very wide windows it is wide enough for two columns of its own;
//            - taller than wide (an iPad held upright): the panel sits under the table and takes every point of height
//              the table lying across the width does not need (belowPanel, 0.7.10); it lays itself out in two columns.
//          A folding phone's hinge is not decided here: where the system reports a hinge (ScreenLayout.fold) the split
//          follows the hinge instead. Every result is a continuous function of the size within each case, so live
//          resizing slides the split smoothly; the only steps are where the panel moves from the side to the bottom or
//          the screen falls back to the phone layout.
//          Pure CoreGraphics on purpose: the framing harness (Tools/framing-check) compiles this file with
//          CameraFraming.swift to check the table still fits on every standard iPad and Mac window shape.
//          Read by ScreenLayout (Surfaces.swift), which ShowpieceView and NotebookPanel ask.
// SRP/DRY check: Pass - checked ScreenLayout (isWide, isShort and the hinge read stay there and unchanged) and
//          NotebookPanel (it asks panelColumns here instead of keeping its own threshold).
import CoreGraphics

enum NotebookGeometry {
    // MARK: When the notebook applies

    /// Narrowest window that gets the notebook: the width of the smallest iPad held upright (an iPad mini is 744 points
    /// wide in portrait), the plan's starting point. Every iPhone held upright is far narrower (440 at most).
    static let minimumWidth: Double = 744
    /// Shortest window that gets the notebook beside the table. Every iPhone turned sideways is shorter than this (440
    /// at most), so a phone in landscape keeps its own layout (ScreenLayout.isShort uses the same 500).
    static let minimumHeightBeside: Double = 500
    /// Shortest window that gets the notebook under the table: the panel's minimum (below) plus room for a table that
    /// still reads at a glance (about 360 points).
    static let minimumHeightBelow: Double = 700

    // MARK: Panel beside the table (window wider than tall)

    /// Share of the window's width the panel takes (0.42 before UI rethink package 4, which reached two columns on a
    /// 13-inch iPad).
    /// UI rethink package 4: a third of the width, so an 11-inch iPad sideways (1180 points) gets the 400-point side
    /// column of the design language and a 13-inch one or a wide Mac window reaches the 440-point cap. Continuous in
    /// the width (the framing check's sweep allows a step of at most this share per point dragged).
    static let besideShare: Double = 0.34
    /// The narrowest panel beside the table: the design language's narrowest side column (the Mac's 380).
    static let besideMinimum: Double = 380
    /// At the accessibility text sizes the same words need more width, so the panel starts at the widest column.
    static let besideMinimumLargeText: Double = 440
    /// The widest the panel gets (the design language's 440); past this the extra width goes to the table.
    static let besideMaximum: Double = 440

    // MARK: Panel under the table (window taller than wide)

    /// Enough height for the top bar, one card and the playback controls in two columns.
    static let belowMinimum: Double = 340
    /// The table's side never gets shorter than this, whatever the panel would like (the framing check's floor too).
    static let belowTableMinimum: Double = 360
    /// The panel never takes more than this share of the height, so a very tall, narrow window keeps a table worth
    /// looking at. It does not bite on any iPad held upright (the panel there is 62 to 66 percent).
    static let belowMaximumShare: Double = 0.68
    /// The pool table's outline with its rails, short side over long side: (1.27 + 2 x 0.21) / (2.54 + 2 x 0.21) m, the
    /// cloth plus TableCamera's rail reach on each side. The band is sized for this table; the other tables are
    /// squarer or the same shape, and the warm view's angle (CameraFraming.warmElevation) tilts lower for them, so
    /// they fill the same half too (measured with a port of CameraFraming's maths: bumper pool settles near 56
    /// degrees, bar billiards near 62, the pool table and five-pin near 72, each within a few points of every edge).
    static let tableShape: Double = (1.27 + 0.42) / (2.54 + 0.42)
    /// How tall a table lying across the half looks per point of its width, against its real shape: the warm view
    /// looks down at an angle, so the far half of the table is foreshortened. 0.82 puts the pool table's warm view at
    /// about 72 degrees, inside the 48 to 74 the warm angle may take, so the camera can fill the height exactly.
    static let tableForeshortening: Double = 0.82
    /// Points the table's half keeps above and below the table: the iPad's status bar (24) and the framing's own
    /// small gaps (CameraFraming.outerGap and gutter).
    static let tableAllowance: Double = 42
    /// The framing's side gutters together (CameraFraming.gutter on each side), so the width the table really gets.
    static let tableSideGutters: Double = 16

    /// The panel's height under the table in a window `size` taller than wide: everything the table does not need.
    /// UI rethink package 8: deliberately not a fixed share of the height (the design language's 58 percent): the table's
    /// height follows from the width, so any fixed share leaves dark bands round it on some iPad (see the header).
    /// The table lies across the window's full width (CameraFraming.tableYaw: its half is then wider than tall), so its
    /// height on screen follows from that width; the half is made that tall, and the panel takes the rest. Never less
    /// than belowMinimum, and never more than belowMaximumShare of the height or so much that the table's side drops
    /// under belowTableMinimum. Continuous in the size (it moves by at most one point per point the window is dragged),
    /// so live resizing slides the split.
    static func belowPanel(for size: CGSize) -> Double {
        let w = Double(size.width), h = Double(size.height)
        let tableNeeds = (w - tableSideGutters) * tableShape * tableForeshortening + tableAllowance
        let most = max(belowMinimum, min(h - belowTableMinimum, h * belowMaximumShare))
        return min(max(h - tableNeeds, belowMinimum), most)
    }

    // MARK: Columns inside the panel

    /// A panel at least this wide shows two columns: cards and controls on one side, the story and numbers on the other.
    /// Two columns of 280 points each: the narrowest the story's rows read well at.
    static let twoColumnWidth: Double = 560

    enum Side: Equatable {
        /// The panel is a column on the trailing side of the table.
        case beside
        /// The panel is a band under the table.
        case below
    }

    struct Split: Equatable {
        var side: Side
        /// The panel's width (beside) or height (below), in points.
        var panel: Double

        /// The line where the table ends and the panel begins, as a zero-thickness rectangle in the window's own
        /// coordinates: the same shape ScreenLayout.fold returns for a hinge, so the screen splits along either the
        /// same way. Leading to trailing, the table is always first.
        func division(in size: CGSize) -> CGRect {
            switch side {
            case .beside: return CGRect(x: max(0, size.width - panel), y: 0, width: 0, height: size.height)
            case .below: return CGRect(x: 0, y: max(0, size.height - panel), width: size.width, height: 0)
            }
        }
    }

    /// The notebook split for a window of this size, or nil when the window is too small for it (the phone layouts).
    /// - largeText: the reader uses an accessibility text size, so the beside panel's minimum is wider.
    static func split(for size: CGSize, largeText: Bool = false) -> Split? {
        let w = Double(size.width), h = Double(size.height)
        guard w >= minimumWidth else { return nil }
        if w >= h {
            guard h >= minimumHeightBeside else { return nil }
            let low = largeText ? besideMinimumLargeText : besideMinimum
            return Split(side: .beside, panel: min(max(w * besideShare, low), besideMaximum))
        } else {
            guard h >= minimumHeightBelow else { return nil }
            // 0.7.10 front door: sized from the table's need (belowPanel), not a fixed share of the height.
            return Split(side: .below, panel: belowPanel(for: size))
        }
    }

    /// How many columns the panel lays itself out in for its own size.
    /// - onHinge: the panel is the other half of a folding phone. There the folding phone's own rule stands unchanged:
    ///   two columns only when the half is short and wide (propped like a laptop), wider than 560 points and a quarter
    ///   again wider than tall. A tall half keeps one column, as it was designed.
    /// Without a hinge, two columns whenever the panel is wide enough for two readable ones (twoColumnWidth): a very
    /// wide window's side panel, or the short and wide band under the table on an iPad held upright.
    /// UI rethink package 4: without a hinge, always one column (the design language: "the notebook and step list are a
    /// tab of the same column, not a second column"; the upright iPad's band is one full-width column with no gaps).
    static func panelColumns(width: Double, height: Double, onHinge: Bool) -> Int {
        if onHinge { return width > 560 && width > height * 1.25 ? 2 : 1 }
        return 1
    }
}
