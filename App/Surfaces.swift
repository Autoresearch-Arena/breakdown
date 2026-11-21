// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: Small shared pieces of screen furniture used by more than one view: the Liquid Glass card that every
//          floating panel sits on, a container that only scrolls when its content is taller than the room it is
//          given (so nothing is lost at the largest text size), and the one rule for when the screen switches from the
//          phone-portrait layout to the wide layout with a side column.
//          Also where a folding phone's hinge crosses the window (ScreenLayout.fold), so the showpiece screen can
//          split along it.
// Edited: Claude Opus 5.5 Medium, 21-November-2026 (ScreenLayout.fold reads the system's division region on iOS 27.1
//          and later: on a folding phone the hinge, so the table can fill one panel and everything else the other).
// Edited: Claude Sonnet 5.5 Medium, 21-November-2026 (WrappingRow: a right-aligned row that wraps onto a second line, so
//          the trick-shot and 8-ball card buttons use two rows rather than one row each when they do not fit.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (ScreenLayout.notebook: any window big enough for the table plus a
//          readable column (an iPad, a Mac window, an iPad in a large split) gets the notebook layout the folding phone
//          had, chosen from the window's size alone (the maths is NotebookGeometry); ScreenLayout.panelColumns says when
//          the notebook panel splits into two columns. isWide, isShort and fold are unchanged, so phones lay out as before.)
// SRP/DRY check: Pass - checked the old view file, which repeated the panel background three times; they all use
//          glassCard now. No other file builds surfaces.
import SwiftUI

extension View {
    /// The system's Liquid Glass look for something that floats over the scene. The system turns this into a more
    /// opaque surface by itself when Reduce Transparency is on, and raises its edge when Increase Contrast is on.
    func glassCard(cornerRadius: CGFloat = 24, padding: CGFloat = 16) -> some View {
        self.padding(padding)
            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// Shows its content at natural size when that fits within `maxHeight`, and inside a scroll view when it does not.
/// Plain ScrollView would grab all the height it is offered, and wrapping controls in one always would make a drag on
/// the scrub bar fight the scroll gesture, so the scroll view only appears at the largest text sizes. The content is
/// measured at its natural height (fixedSize), which keeps the choice stable: the measurement never depends on which
/// branch is showing, so the two cannot flip back and forth.
struct FittingScroll<Content: View>: View {
    let maxHeight: CGFloat
    @ViewBuilder var content: Content
    @State private var naturalHeight: CGFloat = 0

    private var measured: some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { naturalHeight = $0 }
    }

    var body: some View {
        if naturalHeight > maxHeight {
            ScrollView { measured }
                .frame(height: maxHeight)
        } else {
            measured
        }
    }
}

enum ScreenLayout {
    /// The notebook split for this window (the table on one side, NotebookPanel on the other), or nil when the window is
    /// too small and one of the phone layouts below applies. Read from the window's size only, so split view, Stage
    /// Manager and a resized Mac window all follow it live. A folding phone's hinge, where there is one, wins over this.
    static func notebook(for size: CGSize, largeText: Bool) -> NotebookGeometry.Split? {
        NotebookGeometry.split(for: size, largeText: largeText)
    }

    /// How many columns the notebook panel uses at its own size; `onHinge` keeps the folding phone's original rule.
    static func panelColumns(for size: CGSize, onHinge: Bool) -> Int {
        NotebookGeometry.panelColumns(width: Double(size.width), height: Double(size.height), onHinge: onHinge)
    }

    /// Wide layout (a side column for captions and the shot panel) on the Mac, on iPad, and on any screen that is
    /// wider than it is tall. Phone portrait keeps the caption under the title.
    static func isWide(_ size: CGSize) -> Bool {
        size.width >= 700 || size.width > size.height
    }

    /// A phone turned sideways: too short to stack the controls under the table, so they move into the column.
    static func isShort(_ size: CGSize) -> Bool {
        size.width > size.height && size.height < 500
    }

    /// Where a folding phone's hinge crosses this view, in the view's own coordinates, or nil when there is none
    /// (closed, or a screen without one). The system reports the hinge as a "division" region, about 40 points wide
    /// with its margins, whether the phone is half open or flat.
    /// Only a division that runs right across the view counts, so the screen can be cut into two panels along it;
    /// a small notch-like region is not a fold. A zero-thickness line is fine: the panels then just meet on it.
    static func fold(in geo: GeometryProxy) -> CGRect? {
        #if os(iOS)
        if #available(iOS 27.1, *) {
            let size = geo.size
            // Inactive ones count too: lying flat the system marks the hinge inactive (content may cross it), but the
            // screen still reads best as two panels, table on one and words on the other.
            return geo.reservedRegions(kind: .division, options: .includeInactive)
                .map(\.frame)
                .first { r in
                    let crossesTopToBottom = r.minY <= 1 && r.maxY >= size.height - 1 && r.midX > 1 && r.midX < size.width - 1
                    let crossesSideToSide = r.minX <= 1 && r.maxX >= size.width - 1 && r.midY > 1 && r.midY < size.height - 1
                    return crossesTopToBottom || crossesSideToSide
                }
        }
        #endif
        return nil
    }
}

/// A row of controls aligned to the trailing edge that wraps onto further lines when it does not fit, in reading order
/// (the first controls on the first line). The cards' button rows use it as their fallback, so a narrow column gets two
/// rows instead of every button on a row of its own.
struct WrappingRow: Layout {
    var spacing: CGFloat = 8

    private struct Line { var indices: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func lines(width: CGFloat, subviews: Subviews) -> [Line] {
        var all = [Line()]
        for i in subviews.indices {
            let size = subviews[i].sizeThatFits(.unspecified)
            let last = all.count - 1
            let needed = all[last].indices.isEmpty ? size.width : all[last].width + spacing + size.width
            if needed > width, !all[last].indices.isEmpty { all.append(Line()) }
            let at = all.count - 1
            all[at].width = all[at].indices.isEmpty ? size.width : all[at].width + spacing + size.width
            all[at].height = max(all[at].height, size.height)
            all[at].indices.append(i)
        }
        return all
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let all = lines(width: proposal.width ?? .infinity, subviews: subviews)
        let height = all.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(0, all.count - 1))
        return CGSize(width: all.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for line in lines(width: bounds.width, subviews: subviews) {
            var x = bounds.maxX - line.width
            for i in line.indices {
                let size = subviews[i].sizeThatFits(.unspecified)
                subviews[i].place(at: CGPoint(x: x, y: y + (line.height - size.height) / 2), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += line.height + spacing
        }
    }
}
