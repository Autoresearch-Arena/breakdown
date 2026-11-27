// Author: Claude Opus 5.5 Medium
// Date: 27-November-2026
// PURPOSE: UI rethink package 6, the upright phone's thumb dock (plans/26-Nov-2026-ui-rethink-plan.md package 6,
//          plans/26-Nov-2026-design-language.md "Upright iPhone", store/review/design/mockup-aiming-iphone.png). The
//          third of the upright phone's three zones (title row, the whole table, the dock): one panel of the house
//          surface at the foot of the screen, 16 points in from the sides, holding from the top:
//            - the scoreboard strip during a match (MatchScoreboard, the kit's Scoreboard: the first line of the state
//              card, so the title row never carries who is up or the score);
//            - the word strip (PhoneWordStrip), words of fixed height: two lines and a worded "More" that opens the
//              pull-up sheet, with a line for the lead words' small buttons when they have any (PhoneWordsSheet: Notes, Step by step, Table). Its words come from the dock's word sources,
//              mounted here invisibly with the blurbRole .strip so every Blurb hands its words up (PhoneWordsKey)
//              instead of drawing over the table: the status words (Ride's acts, a frozen hit, the opening's story),
//              the Lens tips, the explanation of the moment, the what-if's and the every-surface fan's results, every
//              mode's blurbs, the comparison with the last try, the contact line, the stroke drill and the achievement
//              note. With no words the strip shows the first instruction (until it has been seen, and through the
//              hand-over) or the plain sentence of the strike set now;
//            - the aiming controls (PhoneAimPanel) while they are open, or the what-if's or the fan's panel in their
//              place, and the eight-ball call's ball chips and pocket menu while a call is being made; they grow out of
//              the dock, and since the camera frames the table above the dock's measured top (ShowpieceView), the
//              table reframes above them;
//            - the shot reel and the action row (PhoneStrip): secondary left, primary right, 50 high.
//          The dock reports its frame to leader.blurb, so a jump's side view (drawn beside the flight on the table by
//          CaptionLeader) keeps clear of it.
//          The title row's tap on a name (ideaOpen) opens the sheet; closing the sheet folds the idea again. Opening
//          the sheet opens every word source's fold switch (a held beat stays held while it is read), closing folds
//          them. Reads the model; writes nothing itself but its own sheet state, the idea switch and the fold switches
//          the sources handed up.
// SRP/DRY check: Pass - the panel look is the kit's (palette.panel, the rule edge, Theme.Corner.medium, the phone's card
//          padding); the scoreboard is MatchScoreboard (MatchViews.swift); every word source is the existing phone
//          blurb view, mounted here instead of over the table, not rewritten; the strip and sheet are PhoneWords.swift,
//          the rows PhoneStrip.swift and PhoneAimPanel.swift.
import SwiftUI

struct PhoneDock: View {
    let model: ShowpieceModel
    let leader: LeaderState
    let bridge: SceneBridge
    @Binding var shotPanelOpen: Bool
    /// A just-struck shot is still rolling: the primary action waits (PhonePrimaryAction.resolve).
    let shotLive: Bool
    @Binding var overflow: PhoneStripOverflow
    /// The title row's idea switch (the trick, lesson and 8-ball blurbs read it): true opens the sheet.
    @Binding var ideaOpen: Bool
    /// The table's room in StageSpace, handed to the anchored results' views (they still measure against it).
    let tableArea: CGRect

    @State private var sheetOpen = false
    /// The lead words have small buttons: the strip's button line is added under its fixed words.
    @State private var stripButtons = false
    /// The first instruction's seen flag (the same stored key the aiming layer and StrikeHint use).
    @AppStorage("aimHintSeen") private var hintSeen = false
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            if let match = model.match { MatchScoreboard(match: match) }
            wordStrip
            aiming
            PhoneStrip(model: model, shotPanelOpen: $shotPanelOpen, shotLive: shotLive, overflow: $overflow)
        }
        .padding(Theme.Space.cardPadding(.phone))
        .frame(maxWidth: .infinity, alignment: .leading)
        // The house panel: opaque, a hairline rule edge, the card corner. Nothing of the table shows through the words.
        .background(palette.panel, in: Theme.Corner.cardShape)
        .overlay { Theme.Corner.cardShape.strokeBorder(palette.rule, lineWidth: Theme.Size.hairline) }
        .foregroundStyle(palette.paper)
        .tint(palette.accent)
        .kitDevice(.phone)
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: shotPanelOpen)
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: model.whatIf.isShowing)
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: model.everyWorld.isShowing)
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: model.match != nil)
        // The title's tap opens the idea in the sheet.
        .onChange(of: ideaOpen) { _, open in if open && !sheetOpen { sheetOpen = true } }
        // The dock's frame is what a jump's side view (CaptionLeader) keeps clear of: the picture stays on the table,
        // above the dock, never under it.
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(StageSpace.name)) } action: { frame in
            if leader.blurb != frame { leader.blurb = frame }
        }
        .onDisappear { leader.blurb = .zero }
    }

    // MARK: The word strip

    /// The strip's fixed frame, with the word sources behind it (invisible, silent, untouchable) and the strip itself
    /// drawn from what they hand up.
    private var wordStrip: some View {
        // The sources are children of the view the reader hangs on (not a background branch), so their entries are
        // surely in the preference value read below.
        ZStack(alignment: .topLeading) {
            sources
            Color.clear
                .frame(maxWidth: .infinity)
                // The fixed height: the strip never grows or shrinks with its words, so the camera above never moves.
                // The button line's height comes from the entries read below; that is safe because the sources sit in
                // a zero frame and never measure themselves, so a change of this height cannot change what they hand up.
                .modifier(StripHeight(buttons: stripButtons))
        }
        .overlayPreferenceValue(PhoneWordsKey.self, alignment: .topLeading) { entries in
                PhoneWordStripHost(entries: entries, model: model, leader: leader, fallback: fallback,
                                   sheetOpen: $sheetOpen, ideaOpen: $ideaOpen, hasButtons: $stripButtons)
            }
    }

    /// Every view that has words to say on the upright phone, in the dock's order, each a Blurb in the .strip role.
    /// The priorities pick the lead: the status words first, then the Lens tips, then the explanation of the moment and
    /// the results of a what-if or the every-surface fan, then everything else in this order.
    private var sources: some View {
        ZStack(alignment: .topLeading) {
            Group {
                PhoneStatusWords(model: model).environment(\.blurbPriority, 4)
                PhoneLensTipBlurb(model: model).environment(\.blurbPriority, 3)
                PhoneExplanationBlurb(model: model, leader: leader).environment(\.blurbPriority, 2)
                WhatIfPhoneBlurb(model: model, bridge: bridge, tableArea: tableArea).environment(\.blurbPriority, 2)
                EveryWorldPhoneBlurb(model: model, bridge: bridge, tableArea: tableArea).environment(\.blurbPriority, 2)
            }
            Group {
                PlayPhoneBlurbs(model: model)
                EightBallPhoneBlurbs(model: model, ideaOpen: $ideaOpen)
                TrickPhoneBlurbs(model: model, ideaOpen: $ideaOpen)
                LessonPhoneBlurbs(model: model, ideaOpen: $ideaOpen)
            }
            Group {
                ComparisonPhoneBlurb(model: model)
                ContactArrivalPhoneBlurb(model: model)
                StrokePhoneBlurbs(model: model)
                // 0.7.7 achievements: the achievement note.
                AchievementToast(model: model, style: .blurb)
            }
        }
        .environment(\.blurbRole, .strip)
        .frame(width: 0, height: 0)
        .opacity(0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// With no words to show: the first instruction while aiming (through the hand-over and until it has been seen),
    /// else the plain sentence of the strike set now, or of the one just played while it is on screen.
    private var fallback: AnyView? {
        if shotPanelOpen && (!hintSeen || model.openingStage == .handOver) {
            return AnyView(StrikeHint(model: model, plain: true))
        }
        guard model.openingStage == .none, let reading = StrikeReading.current(model) else { return nil }
        let words = reading.comparison.map(StrikeWords.playedSentence) ?? StrikeWords.plainSentence(reading.shown)
        return AnyView(
            Text(verbatim: words)
                .font(Theme.bodyCompact)
                .foregroundStyle(palette.paper)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        )
    }

    // MARK: The aiming section

    /// The aiming controls, or the what-if's or the fan's panel in their place, and the eight-ball call row.
    @ViewBuilder private var aiming: some View {
        if model.whatIf.isShowing {
            WhatIfPhonePanel(model: model)
                .transition(.opacity)
        } else if model.everyWorld.isShowing {
            // 0.7.7 every-world: the fan's chips in the aiming controls' place (never with the what-if's).
            EveryWorldPhonePanel(model: model)
                .transition(.opacity)
        } else if shotPanelOpen {
            PhoneAimPanel(model: model, isOpen: $shotPanelOpen)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
        EightBallPhoneCallRow(model: model)
    }
}

/// The strip's height: its fixed words, scaled with the reader's text (two lines of the compact body), plus the
/// 44-point button line only while the lead words carry small buttons.
private struct StripHeight: ViewModifier {
    let buttons: Bool
    @ScaledMetric(relativeTo: .subheadline) private var text: CGFloat = PhoneWordStrip.textBaseHeight

    func body(content: Content) -> some View {
        content.frame(height: text + (buttons ? Theme.Size.minHit : 0))
    }
}

/// The strip and its sheet, given the entries the sources handed up. Its own view so the sheet's opening and closing
/// can open and fold the entries' fold switches.
private struct PhoneWordStripHost: View {
    let entries: [PhoneWordsEntry]
    let model: ShowpieceModel
    let leader: LeaderState
    let fallback: AnyView?
    @Binding var sheetOpen: Bool
    @Binding var ideaOpen: Bool
    @Binding var hasButtons: Bool

    var body: some View {
        PhoneWordStrip(entries: entries, model: model, fallback: fallback, sheetOpen: $sheetOpen)
            .onChange(of: PhoneWordStrip.hasButtons(entries), initial: true) { _, now in
                if hasButtons != now { hasButtons = now }
            }
            .sheet(isPresented: $sheetOpen, onDismiss: { if ideaOpen { ideaOpen = false } }) {
                PhoneWordsSheet(entries: entries, model: model, leader: leader,
                                title: PhoneTitle.line(for: model)?.title ?? "",
                                onDone: { sheetOpen = false })
            }
            // Opening the sheet opens every entry that has a fold switch (the explanation holds its beat for reading);
            // closing it folds them again.
            .onChange(of: sheetOpen) { _, open in
                for e in entries {
                    if let fold = e.fold, fold.wrappedValue == open { fold.wrappedValue = !open }
                }
            }
    }
}

// MARK: Status words

/// What the screen is doing for a moment, said in the word strip (it left the title row, which names only what is
/// being played): Ride's acts while a ride speaks, a frozen hit's words, the opening's story while the intro tells it.
struct PhoneStatusWords: View {
    let model: ShowpieceModel

    var body: some View {
        if let status = model.rideStatus {
            Blurb(title: status)
        } else if let words = model.bulletTime.statusWords {
            Blurb(title: words)
        } else if model.stage != .explore && model.stage != .lead && !model.stageTitle.isEmpty {
            Blurb(title: model.stageTitle)
        }
    }
}
