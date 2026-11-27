// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit part A: first version.)
// PURPOSE: Difficulty as a scale of five dots (design language, "Colour": difficulty is never a colour): filled dots
//          in paper, empty ones in paper3. The dots grow with the reader's text size (scaled with the caption). One
//          VoiceOver element: "Difficulty", value "3 of 5". Used on the mode card's name row and in list rows' meta
//          line (package 3 part B's ListRow can place it).
// SRP/DRY check: Pass - checked TableList, the trick and drill lists and the mode cards: difficulty was shown as
//          coloured words or tags in place; this is the one scale every list and card shares.
import SwiftUI

struct DifficultyDots: View {
    /// How hard, from 0 to `scale` (clamped).
    let level: Int
    /// How many dots the scale has: five everywhere in the game.
    let scale: Int

    @Environment(\.palette) private var palette
    /// Dot size and gap, scaled with the caption so they keep pace with the words beside them.
    @ScaledMetric(relativeTo: .caption) private var dot: CGFloat = 7
    @ScaledMetric(relativeTo: .caption) private var gap: CGFloat = Theme.Space.xxs

    init(level: Int, scale: Int = 5) {
        self.scale = max(1, scale)
        self.level = min(max(0, level), max(1, scale))
    }

    var body: some View {
        HStack(spacing: gap) {
            ForEach(0..<scale, id: \.self) { index in
                Circle()
                    .fill(index < level ? palette.paper : palette.paper3)
                    .frame(width: dot, height: dot)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Difficulty"))
        .accessibilityValue(String(localized: "\(level) of \(scale)"))
    }
}

#Preview("Difficulty, zero to five") {
    KitPreviewStage(device: .big) {
        ForEach(0...5, id: \.self) { level in
            DifficultyDots(level: level)
        }
    }
}
