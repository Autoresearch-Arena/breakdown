// Author: Claude Opus 5.5 Medium
// Date: 22-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 6, the thumb dock: the title row is the first of
//          the upright phone's three zones, laid out as mockup-aiming-iphone.png: "Back" on the left and "Menu" on the
//          right as the kit's worded glass controls (design language: every glass control carries its word; Menu is the
//          word, not a symbol), and between them, centred, only what is being played (PhoneTitle), in the heading face
//          and paper. The title opens the idea in the dock's sheet where there is one. "Skip" left the row for the
//          dock's action row (every action lives in the dock). The row sits on the ground band ShowpieceView draws
//          behind it, so the dimming under the glass is gone. The menu's items are unchanged.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 daily: the trick shot's More items stay off for the shot of
//          the day, whose answer waits until the day is finished and whose card holds its own buttons.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 every-world: "Every surface" in the More menu right under What
//          if (EveryWorldMenuItem, shown while the fan can open), and the Surface submenu leaves it out so it is not
//          listed twice.)
// PURPOSE: The upright phone's title row (plans/22-Nov-2026-phone-ui-plan.md, Part 3 "The title row", redrawn by
//          plans/26-Nov-2026-ui-rethink-plan.md package 6), in place of ScreenHeader on that layout only. Left: "Back"
//          (it pauses and opens the main menu, as MenuBackButton). Centre: what is being played (PhoneTitle), one line
//          of heading that shrinks to 0.8 before it truncates; a button that opens the idea (the ideaOpen binding the
//          trick, lesson and 8-ball blurbs read; the dock opens its sheet on it) where there is one. Right: "Menu", a
//          menu with Surface (a submenu), Zoom, What if, Share clip, Every surface, Show the maths, All trick shots or
//          All lessons, Watch again, Show the answer's path, End match, and whatever the dock moved into it because
//          its action row was too wide (Ride, Physics Lens).
//          Every action is the call the existing UI already makes: openMenu (MenuBackButton), setSurface (SurfaceMenuItems), whatIf.open (WhatIfButton), the maths option (GameSettings and
//          TrickShotMode.showMaths, as the trick card's button), showList (the cards' list buttons), watch (the cards'
//          Watch again), showAnswerPath (the trick card), setLens, setRide, setRate and setAutoRate (PlaybackControls).
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 clips, plans/23-Nov-2026-clips-plan.md: the More menu offers
//          "Share clip" and the other shape (ClipMenuItems) right after What if; no new glass on the upright phone.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 everyone, plans/25-Nov-2026-everyone-can-play-plan.md:
//          the More menu gains Zoom (TableZoomMenuItems), so the upright phone zooms without a pinch
//          or a double tap.)
// SRP/DRY check: Pass - checked ShowpieceView's ScreenHeader, MenuBackButton and SurfaceMenuButton (shared with the
//          notebook's top bar, unchanged; the surface rows are SurfaceMenuItems, used by both menus), and the trick and
//          lesson cards' buttons (same mode calls, no new rules).
import SwiftUI

struct PhoneTitleRow: View {
    let model: ShowpieceModel
    /// The idea is open (a tap on the title opens it in the dock's sheet).
    @Binding var ideaOpen: Bool
    /// What the strip moved into the menu (PhoneStrip writes it, ShowpieceView owns it).
    var overflow = PhoneStripOverflow()

    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(GameSettings.mathsKey) private var maths = false

    var body: some View {
        HStack(spacing: Theme.Space.xs) {
            backButton.fixedSize()
            title.frame(maxWidth: .infinity)
            moreMenu.fixedSize()
        }
        .frame(minHeight: Theme.Size.titleRow)
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: PhoneTitle.line(for: model))
    }

    // MARK: Back

    /// The back button claims Escape only when nothing else on screen is using it (as MenuBackButton).
    private var escapeIsMine: Bool { !model.menuOpen && model.match?.confirmingEnd != true }

    private var backButton: some View {
        Button { model.openMenu() } label: {
            KitButtonLabel(String(localized: "Back"), systemImage: "chevron.backward")
        }
        .buttonStyle(.kitGlass)
        .keyboardShortcut(escapeIsMine ? KeyboardShortcut.cancelAction : nil)
        .hoverHighlight()
        .accessibilityHint(String(localized: "Pauses the game and opens the main menu"))
    }

    // MARK: Title

    /// What is being played, centred, one line that shrinks a little before it truncates. A button that opens the idea
    /// where there is one; otherwise a plain heading.
    @ViewBuilder
    private var title: some View {
        if let line = PhoneTitle.line(for: model) {
            let text = Text(verbatim: line.title)
                .font(Theme.heading)
                .foregroundStyle(palette.paper)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
            if PhoneTitle.hasIdea(model) {
                Button { ideaOpen.toggle() } label: {
                    text.frame(minHeight: Theme.Size.minHit).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: line.spoken))
                .accessibilityHint(String(localized: "Shows the idea"))
                .accessibilityAddTraits(.isHeader)
            } else {
                text
                    .accessibilityLabel(Text(verbatim: line.spoken))
                    .accessibilityAddTraits(.isHeader)
            }
        }
    }

    // MARK: More

    /// "Menu": the table's own menu (surface, zoom, what if, share, the maths, the mode's entries), the word on the
    /// kit's glass capsule (package 6: the word, not an ellipsis; the design language's "Menu").
    private var moreMenu: some View {
        Menu {
            menuItems
        } label: {
            // The glass capsule's own padding plus these make it the same 44-point capsule as Back's.
            KitButtonLabel(String(localized: "Menu"))
                .frame(minHeight: Theme.Size.minHit - 2 * Theme.Space.xs)
                .padding(.horizontal, Theme.Space.xxs)
                .kitGlassCapsule()
                .contentShape(Capsule())
        }
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
        .hoverHighlight()
        .accessibilityHint(String(localized: "Surface, zoom and more for this table"))
    }

    @ViewBuilder
    private var menuItems: some View {
        // Surface: every playing surface, each with its one-line note (shared with the round Surface button).
        Menu {
            // 0.7.7 every-world: the item is listed under What if below, not here as well.
            SurfaceMenuItems(model: model, offersEveryWorld: false)
        } label: {
            Label(String(localized: "Surface"), systemImage: model.surface.symbol)
        }
        // 0.7.10 everyone: zoom without a pinch or a double tap (TableZoomMenu).
        Menu {
            TableZoomMenuItems(model: model)
        } label: {
            Label(TableZoomWords.zoom, systemImage: "plus.magnifyingglass")
        }
        // What if: only after the player's own shot has come to rest (WhatIfButton's rule).
        if model.whatIf.canOpen && !model.whatIf.isShowing {
            Button { model.whatIf.open() } label: {
                Label(WhatIfWords.title, systemImage: "arrow.triangle.branch")
            }
        }
        ClipMenuItems(model: model)  // 0.7.7 clips: Share clip, and the other shape
        // 0.7.7 every-world: Every surface, under What if, on the same gate (shown while it can open and is not up).
        EveryWorldMenuItem(model: model)
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
        // 0.7.10 daily: not for the shot of the day (its card holds Watch the answer once the day is finished).
        if trick.isActive, !DailyMode.showing(model) {
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

    /// The dock's toggles that did not fit its action row (Ride first, then Physics Lens), here instead.
    @ViewBuilder
    private var overflowItems: some View {
        if overflow.lens && PhoneStrip.showsLens(model) {
            Toggle(isOn: Binding(get: { model.lensOn }, set: { model.setLens($0) })) {
                Text(String(localized: "Physics Lens"))
            }
        }
        if overflow.ride && PhoneStrip.showsRide(model) {
            Toggle(isOn: Binding(get: { model.rideOn }, set: { model.setRide($0) })) {
                Text(String(localized: "Ride camera"))
            }
        }
        // Package 6: the speed never moves here any more; the dock's shot reel always keeps its speed pill.
    }
}
