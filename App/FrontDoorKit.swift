// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 7, "The front door and the sheets": created.)
// PURPOSE: The few shared pieces the front door's screens need that the component kit (App/Kit) does not hold, so the
//          menu (TitleScreen), the Tables page (TableList), Options (GameSettings) and the Achievements page
//          (AchievementViews) draw them one way (plans/26-Nov-2026-ui-rethink-plan.md package 7,
//          plans/26-Nov-2026-design-language.md "Sheet" and "Units and precision"):
//          - frontDoorWatchIntro, an environment value holding "Watch the intro" (the opening break again under the
//            Physics Lens). The intro left the main menu for How to play; How to play is shown by three hosts
//            (ShowpieceView's page sheet, the menu's own sheet, NotebookPanel's page), so the action travels down the
//            environment from ShowpieceView instead of through every host's call.
//          - frontDoorSheetRoot(), for the kit's SheetPage when it is the root of a NavigationStack: the stack stays
//            (How to play, Tables and Achievements push pages) but its own bar is hidden, since SheetPage draws the
//            serif title and the cyan Done itself.
//          - frontDoorPushedPage(title:onDone:), for a page pushed inside one of those stacks: the ground behind it,
//            paper words (so any hierarchical grey derives from paper, never the system's grey), the cyan tint for the
//            back chevron, the title inline, and Done top right in cyan. frontDoorBackdrop() is the same surface
//            without a title, for a pushed page that names itself (TableGamePage).
//          - TableFigures and TableFiguresLine: a table's real figures in one line, bed in m (two decimals), ball in mm
//            (whole), and its pockets, cups, holes or pins, through NumberStyle, read from the table's own parameters
//            (TableKind.parameters). Shown on the Tables cards, the table pages and the menu's "The table" panel.
//          - TopBarControlLabel: a top-bar control's label (Back, Menu, Zoom): its word, led by its outline icon where it
//            has one, on big screens (iPad, Mac, the open folding phone's panel), the icon alone on a phone, where the
//            row is narrow. A Button caller draws it with the kit's glass control style (GlassControlStyle); a Menu
//            caller puts topBarMenuGlass() on the label, the same capsule, since a Menu does not reliably take a custom
//            button style.
//          Reads TableKind and PoolParameters; writes nothing.
// SRP/DRY check: Pass - checked App/Kit (SheetPage has no pushed-page form and no environment action; KitFigure and
//          NumberStyle are reused for every figure, not copied), NotebookInfo (the notebook's table line names the
//          table in words only, no figures) and TableKind (title, summary and symbol only; the figures come from its
//          parameters, the one place they are written).
import BreakdownPhysics
import SwiftUI

// MARK: Watch the intro, from How to play

extension EnvironmentValues {
    /// "Watch the intro": ends any trick shot or situation and plays the opening break again under the Physics Lens.
    /// Set once by ShowpieceView; nil elsewhere (a preview, the Mac's Settings window), where How to play leaves the row
    /// out.
    @Entry var frontDoorWatchIntro: (@MainActor () -> Void)? = nil
}

// MARK: Sheets inside a navigation stack

extension View {
    /// The root of a sheet's NavigationStack drawn by SheetPage: the stack's own bar is hidden, SheetPage draws the
    /// title and Done.
    func frontDoorSheetRoot() -> some View {
        modifier(FrontDoorSheetRoot())
    }

    /// A page pushed inside a sheet's NavigationStack: ground, paper words, cyan tint, the title inline, Done top right.
    func frontDoorPushedPage(title: String, onDone: (() -> Void)? = nil) -> some View {
        modifier(FrontDoorPushedPage(title: title, onDone: onDone))
    }

    /// The pushed page's surface alone (ground, paper words, cyan tint), for a page that sets its own title.
    func frontDoorBackdrop() -> some View {
        modifier(FrontDoorBackdrop())
    }
}

private struct FrontDoorSheetRoot: ViewModifier {
    @Environment(\.palette) private var palette

    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .tint(palette.accent)
    }
}

private struct FrontDoorBackdrop: ViewModifier {
    @Environment(\.palette) private var palette

    func body(content: Content) -> some View {
        content
            // Paper as the foreground, so a pushed page's hierarchical .secondary reads as paper at its lower
            // opacity, not the system's grey.
            .foregroundStyle(palette.paper)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(palette.ground.ignoresSafeArea())
            #if os(iOS)
            .toolbarBackground(palette.ground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .tint(palette.accent)
    }
}

private struct FrontDoorPushedPage: ViewModifier {
    let title: String
    let onDone: (() -> Void)?
    @Environment(\.palette) private var palette

    func body(content: Content) -> some View {
        content
            .frontDoorBackdrop()
            .navigationTitle(Text(verbatim: title))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                // Done in the same place as on the sheet's first page: it closes the whole sheet (or the notebook's
                // page), not just this pushed page; the back chevron steps back.
                if let onDone {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            onDone()
                        } label: {
                            Text(verbatim: String(localized: "Sheet: Done", defaultValue: "Done",
                                                  comment: "The button at the top right of every sheet that closes it."))
                                .font(Theme.label.weight(.semibold))
                                .foregroundStyle(palette.accent)
                        }
                    }
                }
            }
    }
}

// MARK: A top-bar control's label

/// A glass top-bar control's label: the word on big screens ("Toolbar icons carry their words"), the icon alone on a
/// phone. The accessibility label is the word either way.
struct TopBarControlLabel: View {
    let title: String
    /// The outline icon; nil for a word-only control on big screens ("Menu"), which then shows `phoneIcon` on a phone.
    let systemImage: String?
    /// The icon a phone shows when the big screens show the word alone.
    var phoneIcon: String? = nil
    private var device = KitDeviceReader()

    init(_ title: String, systemImage: String?, phoneIcon: String? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.phoneIcon = phoneIcon
    }

    var body: some View {
        if device.current == .phone, let icon = systemImage ?? phoneIcon {
            Image(systemName: icon)
                .fontWeight(.medium)
                .accessibilityLabel(Text(verbatim: title))
        } else {
            KitButtonLabel(title, systemImage: systemImage)
        }
    }
}

/// The glass surface for a top-bar control drawn by a Menu (Zoom, the surface Menu), matching the kit's glass control
/// (GlassControlStyle) that a plain Button gets: label words in paper, 16 points either side, a 44 point minimum, the
/// thin material capsule (regular under Increase Contrast). A Menu does not reliably take a custom button style, so
/// its label carries the surface itself and the Menu is given the plain style.
private struct TopBarMenuGlass: ViewModifier {
    @Environment(\.palette) private var palette
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
            .font(Theme.label)
            .foregroundStyle(palette.paper)
            .padding(.horizontal, Theme.Space.md)
            .frame(minWidth: Theme.Size.minHit, minHeight: Theme.Size.minHit)
            .background(contrast == .increased ? Material.regularMaterial : Material.thinMaterial, in: Capsule())
            .contentShape(Capsule())
    }
}

extension View {
    /// A Menu's label as a glass top-bar control (see TopBarMenuGlass).
    func topBarMenuGlass() -> some View { modifier(TopBarMenuGlass()) }
}

// MARK: A table's figures

/// A table's real figures: the bed (length by width, in m), the ball (its diameter, in mm, whole) and what it plays
/// into (pockets on the pool table, cups on bumper pool, holes on bar billiards, pins on five-pin), each through the
/// one precision rule per unit (NumberStyle).
enum TableFigures {
    struct Line {
        /// The bed's length and width, each with two decimals ("2.54", "1.27").
        let length: NumberStyle.Reading
        let width: NumberStyle.Reading
        /// The ball's diameter, whole mm.
        let ball: NumberStyle.Reading
        /// How many pockets, cups, holes or pins.
        let count: Int
        /// The word after the count ("pockets").
        let countWord: String
        /// The whole line in words, for VoiceOver.
        let spoken: String
    }

    static func line(_ kind: TableKind) -> Line {
        let p = kind.parameters
        let length = NumberStyle.tableSize(metres: p.tableLength)
        let width = NumberStyle.tableSize(metres: p.tableWidth)
        let ball = NumberStyle.ballSize(metres: p.ballRadius * 2)
        let (count, word) = target(kind, parameters: p)
        let countText = count.formatted(.number.locale(AppLocale.numbers))
        let spoken = String(localized: "Table figures: spoken",
                            defaultValue: "Bed \(length.number) by \(width.number) metres, ball \(ball.number) millimetres, \(countText) \(word)",
                            comment: "VoiceOver for a table's figures. The bed's length and width in metres, the ball's diameter in millimetres, then a count and its word (pockets, cups, holes or pins).")
        return Line(length: length, width: width, ball: ball, count: count, countWord: word, spoken: spoken)
    }

    /// What the balls go into, counted from the table itself.
    private static func target(_ kind: TableKind, parameters p: PoolParameters) -> (Int, String) {
        if p.pocketsEnabled {
            // The pool table's six edge pockets (four corners, two sides).
            return (6, String(localized: "Table figures: pockets", defaultValue: "pockets",
                              comment: "Word after the count of a table's pockets, e.g. 6 pockets."))
        }
        if !p.bedHoles.isEmpty {
            return kind == .bumperPool
                ? (p.bedHoles.count, String(localized: "Table figures: cups", defaultValue: "cups",
                                            comment: "Word after the count of bumper pool's cups, e.g. 2 cups."))
                : (p.bedHoles.count, String(localized: "Table figures: holes", defaultValue: "holes",
                                            comment: "Word after the count of the holes in a bar billiards bed, e.g. 9 holes."))
        }
        return (p.pins.count, String(localized: "Table figures: pins", defaultValue: "pins",
                                     comment: "Word after the count of five-pin billiards' pins, e.g. 5 pins."))
    }
}

/// One line of a table's figures in the inline figure face, the units and words in paper2. Wraps into a short column
/// when the line does not fit (a narrow card, large text). VoiceOver hears the figures as one sentence.
struct TableFiguresLine: View {
    let kind: TableKind
    @Environment(\.palette) private var palette

    var body: some View {
        let line = TableFigures.line(kind)
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.sm) { parts(line) }
            VStack(alignment: .leading, spacing: Theme.Space.xxs) { parts(line) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: line.spoken))
    }

    @ViewBuilder private func parts(_ line: TableFigures.Line) -> some View {
        // The bed: "2.54 × 1.27 m", the unit once.
        KitFigure(number: line.length.number + " × " + line.width.number, unit: line.width.unit, size: .inline)
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xxs) {
            Text(String(localized: "Table figures: ball", defaultValue: "ball",
                        comment: "Word before a table's ball size in its figures line, e.g. ball 57 mm."))
                .font(Theme.caption)
                .foregroundStyle(palette.paper2)
            KitFigure(line.ball, size: .inline)
        }
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xxs) {
            KitFigure(number: line.count.formatted(.number.locale(AppLocale.numbers)), unit: "", size: .inline)
            Text(verbatim: line.countWord)
                .font(Theme.caption)
                .foregroundStyle(palette.paper2)
        }
    }
}
