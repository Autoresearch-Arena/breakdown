// Author: Claude Opus 5.5 Medium
// Date: 22-November-2026
// PURPOSE: The upright phone's title row (plans/22-Nov-2026-phone-ui-plan.md, Part 3 "The title row"), in place of
//          ScreenHeader on that layout only. Left: Back, the standard back chevron in a 44-point clear glass circle
//          (it pauses and opens the main menu, as MenuBackButton). Then the title (PhoneTitle: a trick or lesson name
//          with its difficulty, "Break", the match's turn and score, Ride's status words), one line of plain headline
//          that shrinks to 0.8 before it truncates; the title is a button that opens and closes the idea blurb (the
//          ideaOpen binding the trick, lesson and 8-ball blurbs read). Right: "Skip" while the opening plays, then More,
//          the system ellipsis in a 44-point clear glass circle, a menu with Surface (a submenu), What if, Show the
//          maths, All trick shots or All lessons, Watch again, Show the answer's path, and whatever the strip moved
//          into it because its row was too wide (Ride, Lens, the speed). The two circles and Skip are clear glass over a
//          35 per cent black dimming while the Lens is off (the warm table is bright and busy) and plain clear glass
//          while it is on (the Lens view is dark).
//          Every action is the call the existing UI already makes: openMenu (MenuBackButton), skipOpening (ScreenHeader's
//          Tap to skip), setSurface (SurfaceMenuItems), whatIf.open (WhatIfButton), the maths option (GameSettings and
//          TrickShotMode.showMaths, as the trick card's button), showList (the cards' list buttons), watch (the cards'
//          Watch again), showAnswerPath (the trick card), setLens, setRide, setRate and setAutoRate (PlaybackControls).
// SRP/DRY check: Pass - checked ShowpieceView's ScreenHeader, MenuBackButton and SurfaceMenuButton (shared with the
//          notebook's top bar, unchanged; the surface rows are SurfaceMenuItems, used by both menus), and the trick and
//          lesson cards' buttons (same mode calls, no new rules).
import SwiftUI

struct PhoneTitleRow: View {
    let model: ShowpieceModel
    /// The idea blurb is open (a tap on the title opens and closes it).
    @Binding var ideaOpen: Bool
    /// What the strip moved into the menu (PhoneStrip writes it, ShowpieceView owns it).
    var overflow = PhoneStripOverflow()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(GameSettings.mathsKey) private var maths = false

    /// Clear glass needs a dimming layer over the bright warm table; the Lens view is already dark.
    private var dimmed: Bool { !model.lensOn }

    var body: some View {
        HStack(spacing: 8) {
            backButton
            title
            Spacer(minLength: 0)
            // First minute only: the opening can be skipped from here as well as by a tap on the table.
            if model.openingStage == .playing {
                skipButton.transition(.opacity)
            }
            moreMenu
        }
        .frame(minHeight: 44)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: model.openingStage)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.25), value: model.lensOn)
    }

    // MARK: Back

    /// The back button claims Escape only when nothing else on screen is using it (as MenuBackButton).
    private var escapeIsMine: Bool { !model.menuOpen && model.match?.confirmingEnd != true }

    private var backButton: some View {
        Button { model.openMenu() } label: {
            Image(systemName: "chevron.backward")
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .modifier(TitleGlass(shape: Circle(), dimmed: dimmed))
        .keyboardShortcut(escapeIsMine ? KeyboardShortcut.cancelAction : nil)
        .hoverHighlight()
        .accessibilityLabel(String(localized: "Back"))
        .accessibilityHint(String(localized: "Pauses the game and opens the main menu"))
    }

    // MARK: Title

    @ViewBuilder
    private var title: some View {
        if let line = PhoneTitle.line(for: model) {
            let text = titleText(line)
            if line.isStatus {
                // Status words (Ride, the opening) are read as a status, not offered as a button.
                text.accessibilityLabel(Text(verbatim: String(localized: "Status: \(line.title)")))
            } else {
                Button { ideaOpen.toggle() } label: { text.contentShape(Rectangle()) }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(verbatim: line.spoken))
                    .accessibilityHint(String(localized: "Shows the idea"))
                    .accessibilityValue(ideaOpen ? String(localized: "Open") : "")
            }
        }
    }

    /// "The Called Break · Hard": the title, then the detail in the secondary colour; one line, at most 258 wide,
    /// shrinking to 0.8 before it truncates. White over the dark gradient behind the row.
    private func titleText(_ line: PhoneTitle.Line) -> some View {
        let main = Text(verbatim: line.title)
        let full = line.detail.map { main + Text(verbatim: " · \($0)").foregroundStyle(.secondary) } ?? main
        return full
            .font(Theme.phoneTitle)
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: 258, alignment: .leading)
            .shadow(color: .black.opacity(0.5), radius: 3)
    }

    // MARK: Skip

    private var skipButton: some View {
        Button { model.skipOpening() } label: {
            Text(String(localized: "Skip"))
                .font(Theme.phoneControl)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .modifier(TitleGlass(shape: Capsule(), dimmed: dimmed))
        .accessibilityHint(String(localized: "Goes straight to your own break"))
    }

    // MARK: More

    private var moreMenu: some View {
        Menu {
            menuItems
        } label: {
            Image(systemName: "ellipsis")
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .modifier(TitleGlass(shape: Circle(), dimmed: dimmed))
        }
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
        .hoverHighlight()
        .accessibilityLabel(String(localized: "More"))
    }

    @ViewBuilder
    private var menuItems: some View {
        // Surface: every playing surface, each with its one-line note (shared with the round Surface button).
        Menu {
            SurfaceMenuItems(model: model)
        } label: {
            Label(String(localized: "Surface"), systemImage: model.surface.symbol)
        }
        // What if: only after the player's own shot has come to rest (WhatIfButton's rule).
        if model.whatIf.canOpen && !model.whatIf.isShowing {
            Button { model.whatIf.open() } label: {
                Label(WhatIfWords.title, systemImage: "arrow.triangle.branch")
            }
        }
        Toggle(isOn: mathsBinding) {
            Label(String(localized: "Show the maths"), systemImage: "function")
        }
        modeItems
        // A match's End match (it was in the match card's own More menu): the match blurb then asks to confirm.
        if let match = model.match, match.phase != .over {
            Button(role: .destructive) { match.confirmingEnd = true } label: {
                Label(String(localized: "End match"), systemImage: "xmark")
            }
        }
        overflowItems
    }

    /// The maths option: the stored setting (explanations read it) and the trick shot's own switch (its idea reads it),
    /// set together so the two never disagree.
    private var mathsBinding: Binding<Bool> {
        Binding(get: { maths }, set: { on in
            maths = on
            if model.trickMode.isActive { model.trickMode.showMaths = on }
        })
    }

    /// The trick shot's and the lesson's own entries (they were buttons on their cards).
    @ViewBuilder
    private var modeItems: some View {
        let trick = model.trickMode
        let lessons = model.lessonMode
        if trick.isActive {
            Button { model.showList(.tricks) } label: {
                Label(String(localized: "All trick shots"), systemImage: "list.bullet")
            }
            if Self.watchedBefore(trick.phase) {
                Button { trick.watch() } label: {
                    Label(String(localized: "Watch again"), systemImage: "arrow.counterclockwise")
                }
            }
            if trick.offersAnswerPath {
                Toggle(isOn: Binding(get: { trick.showAnswerPath }, set: { trick.showAnswerPath = $0 })) {
                    Label(String(localized: "Show the answer's path"),
                          systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                }
            }
        }
        if lessons.isActive {
            Button { model.showList(.lessons) } label: {
                Label(String(localized: "All lessons"), systemImage: "list.bullet")
            }
            if Self.watchedBefore(lessons.phase) {
                Button { lessons.watch() } label: {
                    Label(String(localized: "Watch again"), systemImage: "arrow.counterclockwise")
                }
            }
        }
    }

    /// The trick shot's answer has been watched and is not playing now: Watch again replays it. Before the first watch
    /// the primary action offers "Watch it" instead.
    static func watchedBefore(_ phase: TrickShotMode.Phase) -> Bool {
        switch phase {
        case .explaining, .aiming, .judged, .offScript: return true
        case .off, .ready, .watching: return false
        }
    }

    /// The lesson's demonstration has been watched and is not playing now.
    static func watchedBefore(_ phase: LessonMode.Phase) -> Bool {
        switch phase {
        // The held moment and the slow replay count: the lesson card offered Watch again there too.
        case .aiming, .judged, .offScript, .replaying, .keyMoment: return true
        case .off, .ready, .watching: return false
        }
    }

    /// The strip's pieces that did not fit its row (Ride first, then Lens, then the speed), here instead.
    @ViewBuilder
    private var overflowItems: some View {
        if overflow.lens && PhoneStrip.showsLens(model) {
            Toggle(isOn: Binding(get: { model.lensOn }, set: { model.setLens($0) })) {
                Text(String(localized: "Physics Lens"))
            }
        }
        if overflow.ride && PhoneStrip.showsRide(model) {
            Toggle(isOn: Binding(get: { model.rideOn }, set: { model.setRide($0) })) {
                Text(String(localized: "Ride"))
            }
        }
        if overflow.speed {
            Picker(String(localized: "Speed"), selection: PhoneStrip.speedSelection(model)) {
                Text(String(localized: "Auto")).tag(Double?.none)
                ForEach(PlaybackSpeed.rates.reversed(), id: \.self) { r in
                    Text(verbatim: PhoneStrip.speedLabel(r)).tag(Optional(r))
                }
            }
            .pickerStyle(.menu)
        }
    }
}

/// The title row's glass: clear and interactive, over a 35 per cent black dimming while the table behind is bright
/// (HIG Materials: clear glass over bright content wants a dark dimming layer). The dimming is drawn under the glass.
private struct TitleGlass<S: Shape>: ViewModifier {
    let shape: S
    let dimmed: Bool

    func body(content: Content) -> some View {
        content
            .glassEffect(.clear.interactive(), in: shape)
            .background { shape.fill(.black.opacity(dimmed ? 0.35 : 0)) }
    }
}
