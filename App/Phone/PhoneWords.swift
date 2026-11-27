// Author: Claude Opus 5.5 Medium
// Date: 27-November-2026
// PURPOSE: UI rethink package 6, the upright phone's thumb dock: where its words live
//          (plans/26-Nov-2026-ui-rethink-plan.md package 6, plans/26-Nov-2026-design-language.md "Upright iPhone").
//          Words never sit over the table on the upright phone any more. Every view that has something to say there
//          still builds a Blurb (App/Phone/Blurb.swift), but ShowpieceView mounts those views inside the dock with the
//          environment's blurbRole set to .strip, so each Blurb hands its words up as one PhoneWordsEntry through
//          PhoneWordsKey instead of drawing itself. This file shows them:
//            PhoneWordStrip  - the word strip at the top of the dock: words of FIXED height (two lines of the compact
//                              body, scaled with the reader's text size), so the dock and the camera above it never move
//                              as the words change, with a worded "More" at their end that opens the sheet
//                              (mockup-aiming-iphone.png). It shows the lead entry (the highest blurbPriority; ties keep
//                              the dock's order): its title and lead figure, then its short sentence, in two lines; a
//                              content blurb draws its folded form clipped to them. A one-line content blurb that is not
//                              the lead (the eight-ball "On a real table" recipe) takes the second line, as one line that
//                              opens the sheet. When the lead entry has small buttons they follow on a 44-point line of
//                              their own, as the kit's quiet buttons. With no entry the dock hands in a fallback line
//                              (the first instruction, the plain sentence of the strike set now), else the one-line
//                              Physics Lens key while the Lens is on (a tap opens the full key).
//            PhoneWordsSheet - the pull-up sheet (two detents, half and full; the table stays touchable under the half)
//                              with the same pages as the notebook beside the table on iPad, where practical: Notes
//                              (every entry in full, as panel cards, with its chips, its full sentence, its equation,
//                              its picture and its buttons as the kit's secondary buttons; the Physics Lens key while
//                              the Lens is on), Step by step (NotebookStory, once a shot is on the table) and Table
//                              (NotebookSurfaceCard, the cloth and its figures).
//          Opening the sheet opens every entry's fold switch (so a held beat stays held while the explanation is being
//          read, PhoneExplanationBlurb) and closing it folds them again.
// SRP/DRY check: Pass - the entry is exactly the Blurb's slots (no second set of words); the title line and the chips
//          are Blurb.swift's BlurbTitleLine and BlurbChipRow; the buttons, chips, panel and sheet chrome are the kit's
//          (QuietButtonStyle, SecondaryButton, Chip, kitPanel, Theme tokens); the pages are NotebookStory
//          (NotebookStory.swift), NotebookSurfaceCard (NotebookInfo.swift) and LensKeyPage (CaptionViews.swift), used,
//          not copied.
import SwiftUI

// MARK: The entry and its key

/// Everything one Blurb says, handed up from the dock's word sources (Blurb in its .strip role).
struct PhoneWordsEntry: Identifiable {
    let id: UUID
    let priority: Int
    let title: String?
    let figure: CaptionFigure?
    let chips: [CaptionFigure]
    let sentence: String?
    let fullSentence: String?
    let equation: String?
    let picture: AnyView?
    /// The content form: draws its folded (false) or opened (true) form.
    let custom: ((Bool) -> AnyView)?
    /// The whole text for VoiceOver; nil in a content form that reads its own elements.
    let spoken: String?
    let buttons: [BlurbButton]
    /// The caller's fold switch (true is folded), if it owns one.
    let fold: Binding<Bool>?
    /// The content form with a fold: a line that opens to more.
    let contentFolds: Bool

    /// Nothing more than the strip shows: no chips, no fuller text, no equation, no picture, no content to open.
    var isWhole: Bool {
        custom == nil && chips.isEmpty && fullSentence == nil && equation == nil && picture == nil
    }
}

/// The dock's word sources hand their entries up in the dock's order.
struct PhoneWordsKey: PreferenceKey {
    static var defaultValue: [PhoneWordsEntry] { [] }
    static func reduce(value: inout [PhoneWordsEntry], nextValue: () -> [PhoneWordsEntry]) {
        value += nextValue()
    }
}

@MainActor
enum PhoneWords {
    /// The lead entry: the highest priority, the first in the dock's order among equals. Reads the entries only.
    nonisolated static func lead(_ entries: [PhoneWordsEntry]) -> PhoneWordsEntry? {
        var best: PhoneWordsEntry?
        for e in entries {
            if let b = best, e.priority <= b.priority { continue }
            best = e
        }
        return best
    }

    /// A one-line content blurb that is not the lead (the real-table recipe): it takes the strip's second line.
    nonisolated static func secondLine(_ entries: [PhoneWordsEntry], lead: PhoneWordsEntry?) -> PhoneWordsEntry? {
        entries.first { $0.id != lead?.id && $0.contentFolds && $0.buttons.isEmpty }
    }

    /// The sheet has something the strip does not show.
    static func hasMore(_ entries: [PhoneWordsEntry], model: ShowpieceModel) -> Bool {
        entries.count > 1 || entries.contains { !$0.isWhole } || NotebookStory.hasShot(model)
    }
}

// MARK: The strip

struct PhoneWordStrip: View {
    let entries: [PhoneWordsEntry]
    let model: ShowpieceModel
    /// Shown when no entry leads: the first instruction, the aimed strike's sentence. Nil: nothing to say.
    let fallback: AnyView?
    @Binding var sheetOpen: Bool

    @Environment(\.palette) private var palette
    /// Two lines of the compact body (Subheadline): the strip's fixed text height, growing with the reader's text.
    @ScaledMetric(relativeTo: .subheadline) private var textHeight: CGFloat = PhoneWordStrip.textBaseHeight
    /// The Physics Lens key's full page.
    @State private var keyOpen = false

    /// The words' height at the default text size: two lines of the compact body, or a heading line and a body line.
    nonisolated static let textBaseHeight: CGFloat = 44

    /// The lead entry has small buttons: the strip adds its button line under the words (PhoneDock sizes for it).
    static func hasButtons(_ entries: [PhoneWordsEntry]) -> Bool {
        PhoneWords.lead(entries)?.buttons.isEmpty == false
    }

    var body: some View {
        let lead = PhoneWords.lead(entries)
        let second = PhoneWords.secondLine(entries, lead: lead)
        VStack(alignment: .leading, spacing: 0) {
            // The words, two lines, with the worded "More" at the end of them (mockup-aiming-iphone.png).
            HStack(alignment: .bottom, spacing: Theme.Space.xs) {
                Group {
                    if let lead {
                        VStack(alignment: .leading, spacing: 0) {
                            leadWords(lead, lines: second == nil ? 2 : 1)
                            if let second { secondLineButton(second) }
                        }
                    } else if let fallback {
                        fallback
                    } else if model.lensOn {
                        lensKey
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .clipped()
                if PhoneWords.hasMore(entries, model: model) {
                    Button { sheetOpen = true } label: { KitButtonLabel(String(localized: "More")) }
                        .buttonStyle(.kitQuiet)
                        .accessibilityHint(String(localized: "Opens the notes"))
                }
            }
            .frame(height: textHeight)
            // The lead entry's small buttons, as the kit's quiet buttons, on a line of their own.
            if let lead, !lead.buttons.isEmpty {
                HStack(spacing: Theme.Space.md) {
                    ForEach(lead.buttons) { b in
                        Button(action: b.action) { KitButtonLabel(b.title) }
                            .buttonStyle(.kitQuiet)
                            .accessibilityHint(Text(verbatim: b.hint ?? ""))
                    }
                    Spacer(minLength: 0)
                }
                .frame(height: Theme.Size.minHit)
            }
        }
        .sheet(isPresented: $keyOpen) {
            LensKeyPage(onDone: { keyOpen = false })
                .presentationDetents([.medium, .large])
                .presentationBackground(palette.ground)
        }
        // The Lens tips point from the strip at the trail they name (LensCalloutLayer reads this frame, and draws its
        // pointer only while the tips show, so the frame is always reported: a tip that comes up without the strip
        // moving still has its start).
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(StageSpace.name)) } action: { frame in
            let tips = LensTipsShared.shared
            if tips.dockedFrame != frame { tips.dockedFrame = frame }
        }
        .onDisappear { LensTipsShared.shared.dockedFrame = .zero }
    }

    // MARK: The lead words

    /// The lead entry in `lines` lines: its own folded content, or its title and lead figure then its sentence.
    @ViewBuilder
    private func leadWords(_ e: PhoneWordsEntry, lines: Int) -> some View {
        if let custom = e.custom {
            custom(false)
                .frame(maxWidth: .infinity, maxHeight: textHeight * CGFloat(lines) / 2, alignment: .topLeading)
                .clipped()
                .accessibilityElement(children: e.spoken == nil ? .combine : .ignore)
                .modifier(StripSpoken(text: e.spoken))
        } else {
            sentenceText(e)
                .lineLimit(lines)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .modifier(StripSpoken(text: e.spoken))
        }
    }

    /// "The path bends · 11°  While the 12 ball slid, its path bent to the right.": one run of text, so the title, the
    /// figure and the sentence share the two lines. The figure keeps its Lens mark's colour. Built as one attributed
    /// string (each piece with its own face and colour), not by adding Texts together.
    private func sentenceText(_ e: PhoneWordsEntry) -> Text {
        var out = AttributedString()
        var started = false
        if let title = e.title {
            out += Self.piece(title, font: Theme.heading, color: palette.paper)
            started = true
        }
        if let figure = e.figure {
            if started { out += Self.piece(" · ", font: Theme.heading, color: palette.paper2) }
            out += Self.piece(figure.text, font: Theme.inlineFigure, color: palette.color(for: figure.mark))
            started = true
        }
        if let sentence = e.sentence {
            out += Self.piece((started ? "  " : "") + sentence, font: Theme.bodyCompact, color: palette.paper)
        }
        return Text(out)
    }

    /// One piece of the strip's run: its words in a face and a colour.
    private static func piece(_ words: String, font: Font, color: Color) -> AttributedString {
        var a = AttributedString(words)
        a.font = font
        a.foregroundColor = color
        return a
    }

    /// The real-table recipe (any one-line content blurb that is not the lead): one line that opens the sheet.
    private func secondLineButton(_ e: PhoneWordsEntry) -> some View {
        Button { sheetOpen = true } label: {
            HStack(spacing: Theme.Space.xxs) {
                if let custom = e.custom {
                    custom(false)
                        .lineLimit(1)
                        .frame(maxHeight: textHeight / 2, alignment: .topLeading)
                        .clipped()
                }
                Image(systemName: "chevron.up")
                    .font(Theme.caption)
                    .foregroundStyle(palette.paper2)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .modifier(StripSpoken(text: e.spoken))
        .accessibilityHint(String(localized: "Opens the notes"))
    }

    /// The Physics Lens key in one line ("Sliding", "Rolling" with their trails); a tap opens the full key. Wave 2 note
    /// 43: the phone's key now has a route to LensKeyPage, and speaks the "Physics Lens lines" sentence.
    private var lensKey: some View {
        Button { keyOpen = true } label: {
            HStack(spacing: Theme.Space.sm) {
                LensKeyEntry(name: "Sliding", color: palette.slide, dashed: true)
                LensKeyEntry(name: "Rolling", color: palette.accent)
            }
            .foregroundStyle(palette.paper2)
            .frame(minHeight: Theme.Size.minHit)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(String(localized: "Physics Lens lines: dashed magenta lines show a ball sliding, solid cyan lines a ball rolling")))
        .accessibilityHint(String(localized: "Opens the full key"))
        .accessibilityAddTraits(.isButton)
    }
}

/// Sets the accessibility label only when there is one (an empty label would silence the combined children).
private struct StripSpoken: ViewModifier {
    let text: String?
    func body(content: Content) -> some View {
        if let text { content.accessibilityLabel(Text(verbatim: text)) } else { content }
    }
}

// MARK: The sheet

/// The pull-up sheet's pages: the same pages as the notebook beside the table, where practical.
enum PhoneWordsPage: Hashable, CaseIterable {
    case notes, steps, table

    var title: String {
        switch self {
        case .notes: return String(localized: "Notes")
        case .steps: return String(localized: "Step by step")
        case .table: return String(localized: "Table")
        }
    }
}

struct PhoneWordsSheet: View {
    let entries: [PhoneWordsEntry]
    let model: ShowpieceModel
    let leader: LeaderState
    /// What is being played (the title row's words): the sheet's title.
    let title: String
    let onDone: () -> Void

    @Environment(\.palette) private var palette
    @State private var page: PhoneWordsPage = .notes
    /// The Physics Lens key's full page, from the key card's "Full key".
    @State private var keyOpen = false

    /// Step by step only once a shot is on the table (before it, NotebookStory has nothing of its own to list).
    private var pages: [PhoneWordsPage] {
        PhoneWordsPage.allCases.filter { $0 != .steps || NotebookStory.hasShot(model) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            header
            if pages.count > 1 { pagePicker }
            Group {
                switch page {
                case .notes: notes
                case .steps: NotebookStory(model: model, leader: leader)
                case .table:
                    ScrollView { NotebookSurfaceCard(model: model, detailed: true) }
                        .scrollIndicators(.hidden)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, Theme.Space.pageMargin(.phone))
        .padding(.top, Theme.Space.md)
        .background(palette.ground)
        .foregroundStyle(palette.paper)
        .tint(palette.accent)
        .kitDevice(.phone)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        // The table stays touchable under the half sheet: aiming and the reel go on while the notes are open.
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        .presentationBackground(palette.ground)
        .onChange(of: pages) { _, now in if !now.contains(page) { page = .notes } }
        .sheet(isPresented: $keyOpen) {
            LensKeyPage(onDone: { keyOpen = false })
                .presentationDetents([.medium, .large])
                .presentationBackground(palette.ground)
        }
    }

    /// The title on the left in the serif sheet title, "Done" on the right in cyan (the sheet rule).
    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(verbatim: title)
                .font(Theme.title)
                .foregroundStyle(palette.paper)
                .lineLimit(2)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Theme.Space.xs)
            Button(action: onDone) { KitButtonLabel(String(localized: "Done")) }
                .buttonStyle(.kitQuiet)
        }
    }

    /// The pages as the kit's chips, the shown one selected.
    private var pagePicker: some View {
        HStack(spacing: Theme.Space.xs) {
            ForEach(pages, id: \.self) { p in
                Button { page = p } label: { Chip(word: p.title, selected: p == page) }
                    .buttonStyle(.plain)
                    .frame(minHeight: Theme.Size.minHit)
                    .contentShape(Rectangle())
                    .accessibilityAddTraits(p == page ? [.isSelected] : [])
            }
        }
    }

    // MARK: Notes

    private var notes: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.cardGap(.phone)) {
                if model.lensOn {
                    PanelCard(title: String(localized: "Physics Lens"),
                              titleAction: KitAction(String(localized: "Full key")) { keyOpen = true }) {
                        HStack(spacing: Theme.Space.md) {
                            LensKeyEntry(name: "Sliding", color: palette.slide, dashed: true)
                            LensKeyEntry(name: "Rolling", color: palette.accent)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(String(localized: "Physics Lens lines: dashed magenta lines show a ball sliding, solid cyan lines a ball rolling")))
                    }
                }
                ForEach(entries) { e in PhoneWordsCard(entry: e) }
                if entries.isEmpty && !model.lensOn {
                    Text(String(localized: "Nothing to read just now."))
                        .font(Theme.bodyCompact)
                        .foregroundStyle(palette.paper2)
                }
            }
            .padding(.bottom, Theme.Space.lg)
        }
        .scrollIndicators(.hidden)
    }
}

/// One entry in full, on the panel: its content opened, or its title and figure, chips, picture, whole sentence and
/// equation; its buttons as the kit's secondary buttons.
private struct PhoneWordsCard: View {
    let entry: PhoneWordsEntry
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            if let custom = entry.custom {
                custom(true)
                    .accessibilityElement(children: entry.spoken == nil ? .contain : .ignore)
                    .modifier(StripSpoken(text: entry.spoken))
            } else {
                VStack(alignment: .leading, spacing: Theme.Space.xs) {
                    if entry.title != nil || entry.figure != nil {
                        BlurbTitleLine(title: entry.title, figure: entry.figure)
                    }
                    if !entry.chips.isEmpty { BlurbChipRow(chips: entry.chips) }
                    if let picture = entry.picture { picture }
                    if let words = entry.fullSentence ?? entry.sentence {
                        Text(verbatim: words)
                            .font(Theme.bodyCompact)
                            .foregroundStyle(palette.paper)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let equation = entry.equation {
                        Text(verbatim: equation)
                            .font(Theme.equationCompact)
                            .foregroundStyle(palette.paper2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityElement(children: .ignore)
                .modifier(StripSpoken(text: entry.spoken))
            }
            if !entry.buttons.isEmpty {
                HStack(spacing: Theme.Space.xs) {
                    ForEach(entry.buttons) { b in
                        SecondaryButton(b.title, action: b.action)
                            .accessibilityHint(Text(verbatim: b.hint ?? ""))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .kitPanel()
    }
}
