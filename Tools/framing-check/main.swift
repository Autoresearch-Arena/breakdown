// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The camera framing check, rewritten for today's framing (the two-tier fit: playing area inside the inner
//          rectangle, rails inside the outer one) and extended to the iPad and Mac window shapes of the notebook layout.
//          It replaces the older scratch harness on the build drive (breakdown-build/p4-framing/harness), which was
//          written against an earlier framing interface and no longer compiles. Compiled together with
//          App/CameraFraming.swift and App/NotebookGeometry.swift by run.sh; needs no app, no simulator and no 3D.
//          For every window in CameraFraming.checkedWindows it works out the table's side of the window the way the
//          screen does (NotebookGeometry for the notebook, the phone rules otherwise), then asks CameraFraming.fitProblems
//          whether the table fits at every camera angle. It also checks that no phone shape gets the notebook, that the
//          panel's size changes smoothly while a window is dragged wider or taller, and that the table side never gets
//          too small to read. Prints PASS or FAIL with the broken cases.
//          Not yet run: it was written in a batch where only the coordinator compiles. Run it once after the merge.
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 front door, Stage 2: prints how much of its half each of
//          the four tables covers on every window (CameraFraming.coverage), fails an upright iPad whose table covers
//          less than 80 percent of its half's height (the dark bands the review found), and lets the band under the
//          table move one point per point the window is dragged, since it now takes all the height the table does not
//          need (NotebookGeometry.belowPanel); a jump is still caught. Not yet run: written in a batch where only the
//          coordinator compiles.)
// SRP/DRY check: Pass - test scaffolding only; the invariant itself lives in CameraFraming.fitProblems so a future unit
//          test target calls the same code.
import CoreGraphics
import Foundation

var problems: [String] = []
var cases = 0

// The standard pool table as TableCamera frames it: 2.54 by 1.27 metres of cloth, rails reaching 0.21 m past it, the
// pocket holes 0.08 m, rail tops 0.075 m above the cloth, a 45-degree field of view (TableCamera's constants).
let table = TableExtents(halfX: 1.27 + 0.21, halfZ: 0.635 + 0.21, rimHeight: 0.075, playX: 1.27 + 0.08, playZ: 0.635 + 0.08)
let fov: Float = 45

/// The four tables as TableCamera frames them (cloth length and width in metres, from TableKind's table files: the pool
/// table, bumper pool, five-pin billiards, bar billiards), with the same rail reach and pocket reach as the pool table.
let tables: [(name: String, extents: TableExtents)] = [(2.54, 1.27, "pool"), (1.1557, 0.762, "bumper pool"),
                                                       (2.84, 1.42, "five-pin"), (1.42, 0.80, "bar billiards")].map {
    (name: $0.2, extents: TableExtents(halfX: Float($0.0) / 2 + 0.21, halfZ: Float($0.1) / 2 + 0.21, rimHeight: 0.075,
                                       playX: Float($0.0) / 2 + 0.08, playZ: Float($0.1) / 2 + 0.08))
}

/// The 3D view's size and what floats over it, for a window, the way ShowpieceView lays it out.
func stage(for window: CameraFraming.CheckedWindow) -> (size: CGSize, request: FramingRequest, layout: String) {
    let w = Double(window.size.width), h = Double(window.size.height), safe = window.safe
    if let split = NotebookGeometry.split(for: window.size) {
        // Notebook: the table's side has no title row and no controls over it (they are in the panel), and no safe
        // inset on the side where it meets the panel.
        switch split.side {
        case .beside:
            let size = CGSize(width: w - split.panel, height: h)
            let s = FramingInsets(top: safe.top, left: safe.left, bottom: safe.bottom, right: 0)
            return (size, FramingRequest(size: size, safe: s, headerBottom: safe.top, controlsTop: nil), "notebook beside")
        case .below:
            let size = CGSize(width: w, height: h - split.panel)
            let s = FramingInsets(top: safe.top, left: safe.left, bottom: 0, right: safe.right)
            return (size, FramingRequest(size: size, safe: s, headerBottom: safe.top, controlsTop: nil), "notebook below")
        }
    }
    // Phone layouts (ScreenLayout.isWide / isShort, unchanged): a side column when wide, the controls under the table
    // unless the window is short. The title row is about 50 points; the control strip about 190 (the sizes the
    // package 4 framing work measured on screen).
    let wide = w >= 700 || w > h
    let short = w > h && h < 500
    let column = wide ? min(320, w * 0.45) : 0
    let size = CGSize(width: w - column, height: h)
    let s = FramingInsets(top: safe.top, left: safe.left, bottom: safe.bottom, right: wide ? 0 : safe.right)
    let controls: Double? = short ? nil : h - safe.bottom - 190
    return (size, FramingRequest(size: size, safe: s, headerBottom: safe.top + 50, controlsTop: controls),
            wide ? "phone wide" : "phone upright")
}

// 1. The fit on every standard window.
for window in CameraFraming.checkedWindows {
    let (size, request, layout) = stage(for: window)
    cases += 1
    let framing = CameraFraming.framing(request)
    problems += CameraFraming.fitProblems(name: "\(window.name) (\(layout))", size: size, framing: framing, table: table,
                                          fovDegrees: fov)
    let lies = CameraFraming.tableYaw(for: size) == 0 ? "across" : "upright"
    print("\(window.name) [\(layout)] table side \(Int(size.width)) x \(Int(size.height)), lies \(lies)")
    // 0.7.10 front door: how much of its half each table covers (Stage 2's measure), and the upright iPad held to it.
    for t in tables {
        let c = CameraFraming.coverage(size: size, framing: framing, table: t.extents, fovDegrees: fov)
        print("    \(t.name): covers \(Int((c.width * 100).rounded()))% of the width, \(Int((c.height * 100).rounded()))% of the height")
        if layout == "notebook below" {
            cases += 1
            if c.height < 0.80 { problems.append("\(window.name): \(t.name) covers only \(Int(c.height * 100))% of its half's height") }
            problems += CameraFraming.fitProblems(name: "\(window.name) (\(t.name))", size: size, framing: framing,
                                                  table: t.extents, fovDegrees: fov)
        }
    }
}

// 1b. The open folding phone's table half (the hinge decides it, not NotebookGeometry), both ways round, measured only:
//     its shape is the hardware's. 669 by 951 points is the inner screen (2007 by 2853 pixels at 3x), halved at the hinge.
for (name, size) in [("Open folding phone, propped", CGSize(width: 669, height: 470)),
                     ("Open folding phone, like a book", CGSize(width: 470, height: 669))] {
    let request = FramingRequest(size: size, safe: FramingInsets(), headerBottom: 0, controlsTop: nil)
    let framing = CameraFraming.framing(request)
    print("\(name) table side \(Int(size.width)) x \(Int(size.height))")
    for t in tables {
        let c = CameraFraming.coverage(size: size, framing: framing, table: t.extents, fovDegrees: fov)
        print("    \(t.name): covers \(Int((c.width * 100).rounded()))% of the width, \(Int((c.height * 100).rounded()))% of the height")
    }
}

// 2. No phone ever gets the notebook: every iPhone held either way keeps its own layouts.
for window in CameraFraming.checkedWindows where window.name.contains("iPhone") {
    cases += 1
    if NotebookGeometry.split(for: window.size) != nil { problems.append("\(window.name) got the notebook") }
}

// 3. Dragging a Mac window wider, then taller, one point at a time: within each layout the panel changes by at most
//    the share of the step (no jump), and the table's side never drops below 360 points.
func sweep(_ sizes: [CGSize], label: String) {
    var last: NotebookGeometry.Split?
    for size in sizes {
        cases += 1
        let split = NotebookGeometry.split(for: size)
        if let a = last, let b = split, a.side == b.side {
            // Beside: a share of the width. Below (0.7.10): every point the table does not need, so up to one point of
            // panel per point dragged; anything more is a jump.
            let step = (b.side == .beside ? NotebookGeometry.besideShare : 1.0) + 1e-9
            if abs(a.panel - b.panel) > step { problems.append("\(label): panel jumped \(a.panel) -> \(b.panel) at \(size)") }
        }
        if let b = split {
            let tableSide = b.side == .beside ? Double(size.width) - b.panel : Double(size.height) - b.panel
            if tableSide < 360 { problems.append("\(label): table side only \(tableSide) at \(size)") }
            if b.side == .beside && b.panel < NotebookGeometry.besideMinimum { problems.append("\(label): panel too narrow at \(size)") }
        }
        last = split
    }
}
sweep((480...2560).map { CGSize(width: Double($0), height: 900) }, label: "Mac window dragged wider")
sweep((520...1600).map { CGSize(width: 1000, height: Double($0)) }, label: "Mac window dragged taller")

// 4. Columns: the panel beside the table splits in two only when wide enough for two readable columns, and the band
//    under the table on an iPad held upright always does.
for window in CameraFraming.checkedWindows {
    guard let split = NotebookGeometry.split(for: window.size) else { continue }
    cases += 1
    let panel = split.side == .beside ? CGSize(width: split.panel, height: Double(window.size.height))
                                      : CGSize(width: Double(window.size.width), height: split.panel)
    let columns = NotebookGeometry.panelColumns(width: Double(panel.width), height: Double(panel.height), onHinge: false)
    if split.side == .below && columns != 2 { problems.append("\(window.name): band under the table is one column") }
    if split.side == .beside && columns == 2 && split.panel < NotebookGeometry.twoColumnWidth {
        problems.append("\(window.name): two columns in a \(split.panel)-point panel")
    }
}

for p in problems.prefix(40) { print("FAIL", p) }
print("cases=\(cases) problems=\(problems.count) -> \(problems.isEmpty ? "PASS" : "FAIL")")
exit(problems.isEmpty ? 0 : 1)
