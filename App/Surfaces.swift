// Author: Claude Sonnet 5.5 High
// Date: 13-November-2026
// PURPOSE: Small shared pieces of screen furniture used by more than one view: the Liquid Glass card that every
//          floating panel sits on, a container that only scrolls when its content is taller than the room it is
//          given (so nothing is lost at the largest text size), and the one rule for when the screen switches from the
//          phone-portrait layout to the wide layout with a side column.
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
    /// Wide layout (a side column for captions and the shot panel) on the Mac, on iPad, and on any screen that is
    /// wider than it is tall. Phone portrait keeps the caption under the title.
    static func isWide(_ size: CGSize) -> Bool {
        size.width >= 700 || size.width > size.height
    }

    /// A phone turned sideways: too short to stack the controls under the table, so they move into the column.
    static func isShort(_ size: CGSize) -> Bool {
        size.width > size.height && size.height < 500
    }
}
