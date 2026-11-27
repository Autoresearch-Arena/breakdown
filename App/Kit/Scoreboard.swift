// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, the component kit part B: created.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3 review: the two names are nonisolated, so the
//          tests and the spoken line can read them off the main actor.)
// PURPOSE: UI rethink package 3, "The component kit" part B (plans/26-Nov-2026-design-language.md, "Scoreboard strip";
//          principle 6: the scoreboard is always the first line of the state card). Scoreboard is a sunken strip
//          (panelSunken, small corners, 12 points of padding) with the two players side by side: each one's name
//          (label, paper) and under it their score in the control figure (KitFigure) or their group in words
//          (heading, paper: "Solids", "Stripes", "Open"); a cyan dot before the name of whoever is to play (cyan:
//          "you can act here"); the computer's level once, as a small paper2 badge after its name; and the target
//          ("First to 60") in caption under both. The strip never says who is up in words on screen (the dot does);
//          VoiceOver reads the whole strip as one element and does say it ("You 3, Computer, steady, 5. You to play.
//          First to 60.").
//          Read by the later packages' match and table-game state cards (MatchViews, TableGamePage, package 5).
// SRP/DRY check: Pass - checked MatchViews and TableGamePage (each wrote the score into its title line; package 5 moves
//          them here), MatchWords and OpponentWords (their sentences stay; this only lays the strip out), FigureTile
//          (same sunken surface; a scoreboard is two players, not a tile row).
import SwiftUI

/// The two players' standing on a sunken strip: names, scores or groups, whose turn, the target and the level.
struct Scoreboard: View {
    /// One player's side.
    struct Side: Equatable, Sendable {
        /// What a player has to show.
        enum Standing: Equatable, Sendable {
            /// A score, drawn in the control figure.
            case score(Int)
            /// A group in words ("Solids"), already localised.
            case group(String)
            /// Nothing yet (a dash).
            case none
        }
        /// The name, already localised ("You", "Computer"; Scoreboard.you and Scoreboard.computer give those two).
        var name: String
        var standing: Standing
        /// The computer's side: its level badge (when given) goes after this name.
        var isComputer = false
    }

    let left: Side
    let right: Side
    /// Whose turn: 0 the left side, 1 the right, nil neither (between frames, the game over).
    var turn: Int? = nil
    /// The target, already localised ("First to 60"); nil for none.
    var target: String? = nil
    /// The computer's level in a word or two, already localised ("Steady"); drawn once, beside the computer's name.
    var computerLevel: String? = nil

    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .subheadline) private var dotSize: CGFloat = Theme.Space.xs

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            let layout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Space.sm))
                : AnyLayout(HStackLayout(alignment: .top, spacing: Theme.Space.md))
            layout {
                column(left, playing: turn == 0, badge: badgeSide == 0)
                column(right, playing: turn == 1, badge: badgeSide == 1)
            }
            if let target {
                Text(verbatim: target)
                    .font(Theme.caption)
                    .foregroundStyle(palette.paper2)
            }
        }
        .padding(Theme.Space.tilePadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.panelSunken, in: Theme.Corner.tileShape)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: Self.spoken(left: left, right: right, turn: turn, target: target,
                                                       computerLevel: computerLevel)))
    }

    /// Which side carries the level badge: the first computer side, and only one.
    private var badgeSide: Int? {
        guard computerLevel != nil else { return nil }
        if left.isComputer { return 0 }
        if right.isComputer { return 1 }
        return nil
    }

    private func column(_ side: Side, playing: Bool, badge: Bool) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.xxs) {
            HStack(alignment: .center, spacing: Theme.Space.xs) {
                // The turn dot keeps its room when it is not shown, so the names do not shift as the turn changes.
                Circle()
                    .fill(palette.accent)
                    .frame(width: dotSize, height: dotSize)
                    .opacity(playing ? 1 : 0)
                Text(verbatim: side.name)
                    .font(Theme.label)
                    .foregroundStyle(palette.paper)
                    .lineLimit(1)
                if badge, let computerLevel {
                    Text(verbatim: computerLevel)
                        .font(Theme.caption)
                        .foregroundStyle(palette.paper2)
                        .lineLimit(1)
                        .padding(.vertical, Theme.Space.xxs)
                        .padding(.horizontal, Theme.Space.xs)
                        .overlay { Capsule().strokeBorder(palette.rule, lineWidth: Theme.Size.hairline) }
                        .fixedSize()
                }
            }
            Group {
                switch side.standing {
                case .score(let n):
                    KitFigure(number: n.formatted(.number.locale(AppLocale.numbers)), unit: "", size: .control)
                case .group(let words):
                    Text(verbatim: words)
                        .font(Theme.heading)
                        .foregroundStyle(palette.paper)
                case .none:
                    KitFigure(number: "–", unit: "", size: .control, color: palette.paper3)
                }
            }
            // Under the name, past the dot's room.
            .padding(.leading, dotSize + Theme.Space.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Words

    /// "You", the player's own side.
    nonisolated static var you: String {
        String(localized: "Scoreboard: You", defaultValue: "You",
               comment: "The player's own name on the scoreboard strip.")
    }

    /// "Computer", the computer's side.
    nonisolated static var computer: String {
        String(localized: "Scoreboard: Computer", defaultValue: "Computer",
               comment: "The computer opponent's name on the scoreboard strip. Its level is shown once beside it.")
    }

    /// The whole strip as VoiceOver reads it. Pure, so the tests can check it.
    nonisolated static func spoken(left: Side, right: Side, turn: Int?, target: String?, computerLevel: String?)
        -> String {
        func side(_ s: Side, level: Bool) -> String {
            var parts = [s.name]
            if level, let computerLevel { parts.append(computerLevel) }
            switch s.standing {
            case .score(let n): parts.append(n.formatted(.number.locale(AppLocale.numbers)))
            case .group(let words): parts.append(words)
            case .none: break
            }
            return parts.joined(separator: ", ")
        }
        let levelLeft = computerLevel != nil && left.isComputer
        let levelRight = computerLevel != nil && !levelLeft && right.isComputer
        var sentences = [side(left, level: levelLeft), side(right, level: levelRight)]
        if let turn, turn == 0 || turn == 1 {
            let name = turn == 0 ? left.name : right.name
            sentences.append(String(localized: "Scoreboard: to play", defaultValue: "\(name) to play",
                                    comment: "VoiceOver on the scoreboard strip: whose turn it is, e.g. You to play. The argument is the player's name."))
        }
        if let target { sentences.append(target) }
        return sentences.joined(separator: ". ")
    }
}

#Preview("Scoreboards") {
    let palette = Palette(contrast: .standard)
    VStack(spacing: Theme.Space.sm) {
        Scoreboard(left: .init(name: Scoreboard.you, standing: .score(3)),
                   right: .init(name: Scoreboard.computer, standing: .score(5), isComputer: true),
                   turn: 0, target: "First to 60", computerLevel: "Steady")
        Scoreboard(left: .init(name: Scoreboard.you, standing: .group("Solids")),
                   right: .init(name: Scoreboard.computer, standing: .group("Stripes"), isComputer: true),
                   turn: 1, computerLevel: "Sharp")
        Scoreboard(left: .init(name: Scoreboard.you, standing: .none),
                   right: .init(name: Scoreboard.computer, standing: .none, isComputer: true),
                   target: "Open table")
    }
    .padding(Theme.Space.lg)
    .frame(width: 400)
    .background(palette.panel)
    .background(palette.ground)
}
