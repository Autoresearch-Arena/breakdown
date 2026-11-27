// Author: Claude Opus 5.5 Medium
// Date: 22-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 3, the closing sweep: a leader with no colour of
//         its own is drawn in paper, not bare white.)
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 6, the upright phone's thumb dock: a Blurb has
//          a role (BlurbRole, set by the environment). In the dock's word sources (.strip) it draws nothing and hands
//          its words up instead (PhoneWordsKey, App/Phone/PhoneWords.swift): the dock's fixed-height word strip shows
//          the lead one in two lines with a worded "More", and the pull-up sheet shows them all in full, so no words sit
//          over the table. Anywhere else (.floating) it is the house panel surface (opaque panel, hairline rule edge,
//          the design language's corners) instead of material, the sentence is the upright phone's compact body, the
//          "more" dot is a worded "More", the small buttons are the kit's quiet buttons, and the chips are the kit's
//          neutral chips with a meaning dot. Every initialiser, slot and the transition are unchanged.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 words, plans/25-Nov-2026-fewer-words-and-honest-claims-plan.md
//          Part A row 5 and Part B: an optional fullSentence. With one, the folded blurb shows its short sentence whole
//          (wrapped, never cut with an ellipsis) and a tap opens the full one in its place; VoiceOver reads the full one.)
// Edited: Claude Opus 5.5 Medium, 25-November-2026 (0.7.9: an optional picture slot under the chips, for the jump's
//          side view inside its explanation.)
// PURPOSE: The Blurb, the one text component of the upright phone (plans/22-Nov-2026-phone-ui-plan.md, Part 3 "The
//          Blurb", and plans/26-Nov-2026-ui-rethink-plan.md package 6). Each piece of words a mode, a ruling, an
//          explanation or a tip has to say on the upright phone is built as a Blurb. Slots, in order, each optional: a
//          title with its lead figure after it ("Throw · 2.1°"), up to three figure chips (Caption.figures), one
//          sentence (three lines while folded) with an optional fuller text behind it, the worked equation, a picture,
//          and up to two small buttons; or any content, with or without a fold the caller owns.
//          Where it shows is set by the environment's blurbRole:
//            .strip    - inside the upright phone's dock (ShowpieceView mounts every phone word source there). The
//                        Blurb draws nothing; it hands one PhoneWordsEntry up through PhoneWordsKey with its slots, its
//                        content, its buttons, its fold switch and the environment's blurbPriority. PhoneWordStrip
//                        shows the lead entry and PhoneWordsSheet all of them (App/Phone/PhoneWords.swift).
//            .floating - anywhere else (a caller that still places one itself): a small panel sized to its words, at
//                        most 260 wide (85 per cent of the offered width at the accessibility text sizes), opened in
//                        place by a tap (up to 370 wide, scrolling past openMaxHeight), with a worded "More" while
//                        words are folded away.
//          VoiceOver always reads the whole text, folded or not. Also BlurbLeader, the line that joins an anchored blurb
//          to its moment (still used by the what-if's and the every-surface fan's anchored results), and BlurbButton,
//          the value a caller hands in for each small button. Reads Theme and the palette only.
// SRP/DRY check: Pass - the surface is the kit's panel look (Theme.Corner, palette.panel and palette.rule), the chips are
//          the kit's Chip, the buttons the kit's QuietButtonStyle; FittingScroll (Surfaces.swift) is reused for the
//          opened blurb's scrolling. The strip and sheet live in PhoneWords.swift, not here.
import SwiftUI

// MARK: Where a blurb shows

/// Where a Blurb is drawn (UI rethink package 6). Set through the environment, so the many views that build blurbs
/// never need to know: ShowpieceView sets .strip on the upright phone's word sources.
enum BlurbRole: Sendable {
    /// Its own small panel, wherever its caller puts it.
    case floating
    /// Not drawn: its words go up to the upright phone's dock (PhoneWordsKey), shown in the word strip and the sheet.
    case strip
}

extension EnvironmentValues {
    /// Where the blurbs below are drawn; .floating unless a container says otherwise.
    @Entry var blurbRole: BlurbRole = .floating
    /// How urgently the blurbs below want the word strip's one place: the highest leads, ties keep the dock's order
    /// (the Lens tips over the explanation of the moment, that over a mode's own words).
    @Entry var blurbPriority: Int = 0
}

/// One small button inside a blurb (at most two per blurb), for a choice that is not the screen's primary action
/// ("Not now", "Next", a ruling's two choices). A value, so callers hand an array and never fight a view builder.
struct BlurbButton: Identifiable {
    /// Already translated.
    let title: String
    /// Already translated; nil for none.
    var hint: String?
    let action: @MainActor () -> Void

    var id: String { title }

    init(_ title: String, hint: String? = nil, action: @escaping @MainActor () -> Void) {
        self.title = title
        self.hint = hint
        self.action = action
    }
}

/// The blurb. Two ways to build one:
///   - the slots: `Blurb(title:figure:chips:sentence:equation:folded:startsFolded:foldedLines:buttons:)`;
///   - any content: `Blurb(accessibilityText:buttons:) { ... }`, or with a fold the content draws itself:
///     `Blurb(folded:accessibilityText:buttons:) { open in ... }`.
/// Not generic on purpose: the slot and content forms are one type, so callers never meet "generic parameter could not
/// be inferred".
struct Blurb: View {
    /// The width a folded floating blurb never passes (Part 3: "width follows the text up to 260").
    static let width: CGFloat = 260
    /// The width an opened floating blurb may grow to.
    static let openWidth: CGFloat = 370
    /// The share of the offered width at the accessibility text sizes, where 260 would leave a word a line.
    static let accessibilityShare: CGFloat = 0.85
    /// Corner and padding: a floating blurb is a small card of the house panel (design language, "Corners", "Surfaces").
    static var corner: CGFloat { Theme.Corner.medium }
    static var padding: CGFloat { Theme.Space.sm }
    /// How a blurb comes and goes: a fade with a slight scale (Part 3). The parent animates the change.
    static var transition: AnyTransition { .opacity.combined(with: .scale(scale: 0.96)) }

    // MARK: What it shows

    private let title: String?
    private let figure: CaptionFigure?
    private let chips: [CaptionFigure]
    private let sentence: String?
    /// 0.7.10 words: the whole text behind a short `sentence` (a caption's detail behind its short form). With one, the
    /// folded blurb shows `sentence` whole, wrapped and never cut, and the opened blurb shows this in its place.
    private let fullSentence: String?
    private let equation: String?
    /// A picture under the chips (0.7.9: the jump's side view in its explanation), shown folded or open.
    private let picture: AnyView?
    /// The content form: draws itself given whether the blurb is open.
    private let custom: ((Bool) -> AnyView)?
    /// The whole text for VoiceOver in the content form (nil: the content's own elements are read, combined).
    private let spokenOverride: String?
    private let buttons: [BlurbButton]
    /// Lines of the sentence while folded (3 by default; 1 for the idea folded under a guided replay).
    private let foldedLines: Int
    /// The opened blurb scrolls past this height (about half an upright phone's screen).
    private let openMaxHeight: CGFloat
    /// The content form with a fold: always offers the tap and "More" (the content decides what it hides).
    private let contentFolds: Bool

    // MARK: Fold state

    /// The caller's fold switch, when it owns one (a held replay that must stay held while open, the title row's idea).
    private let external: Binding<Bool>?
    /// The blurb's own fold switch otherwise.
    @State private var ownFolded: Bool
    /// The sentence's height as shown and at full length, measured, so "More" shows only when words are hidden.
    @State private var shownHeight: CGFloat = 0
    @State private var fullHeight: CGFloat = 0
    /// This blurb's identity in the dock's word strip, kept for as long as the blurb is on screen (package 6).
    @State private var stripID = UUID()

    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.blurbRole) private var role
    @Environment(\.blurbPriority) private var priority

    /// The slots form. Every argument is optional; pass only what this blurb says. Strings are already translated.
    /// - folded: the caller's fold switch (true is folded); nil lets the blurb keep its own, starting at startsFolded.
    /// - foldedLines: how many lines of the sentence show while folded.
    /// - buttons: at most two are drawn; any more are ignored.
    init(title: String? = nil, figure: CaptionFigure? = nil, chips: [CaptionFigure] = [], sentence: String? = nil,
         fullSentence: String? = nil,
         equation: String? = nil, picture: AnyView? = nil, folded: Binding<Bool>? = nil, startsFolded: Bool = true,
         foldedLines: Int = 3, openMaxHeight: CGFloat = 420, buttons: [BlurbButton] = []) {
        self.title = title
        self.figure = figure
        self.chips = Array(chips.prefix(3))
        self.sentence = sentence
        // A full text that says no more than the sentence is no full text at all (nothing to open).
        self.fullSentence = fullSentence == sentence ? nil : fullSentence
        self.equation = equation
        self.picture = picture
        self.custom = nil
        self.spokenOverride = nil
        self.buttons = Array(buttons.prefix(2))
        self.foldedLines = max(1, foldedLines)
        self.openMaxHeight = openMaxHeight
        self.contentFolds = false
        self.external = folded
        _ownFolded = State(initialValue: startsFolded)
    }

    /// Any content on the blurb's surface, without a fold (a one-line notice, a status with its picture).
    /// - accessibilityText: the whole text VoiceOver reads; nil reads the content's own elements, combined.
    init<Content: View>(accessibilityText: String? = nil, buttons: [BlurbButton] = [],
                        @ViewBuilder content: () -> Content) {
        let built = AnyView(content())
        self.title = nil; self.figure = nil; self.chips = []; self.sentence = nil; self.equation = nil; self.picture = nil
        self.fullSentence = nil
        self.custom = { _ in built }
        self.spokenOverride = accessibilityText
        self.buttons = Array(buttons.prefix(2))
        self.foldedLines = 3
        self.openMaxHeight = 420
        self.contentFolds = false
        self.external = nil
        _ownFolded = State(initialValue: true)
    }

    /// Any content with a fold the caller owns: the content is handed `open` (false while folded) and draws its folded
    /// and opened forms; the blurb adds the tap, "More" while folded, the wider opened width and the scrolling. In the
    /// dock the folded form is the word strip's line and the opened form is the sheet's.
    init<Content: View>(folded: Binding<Bool>, accessibilityText: String? = nil, openMaxHeight: CGFloat = 420,
                        buttons: [BlurbButton] = [], @ViewBuilder content: @escaping (_ open: Bool) -> Content) {
        self.title = nil; self.figure = nil; self.chips = []; self.sentence = nil; self.equation = nil; self.picture = nil
        self.fullSentence = nil
        self.custom = { AnyView(content($0)) }
        self.spokenOverride = accessibilityText
        self.buttons = Array(buttons.prefix(2))
        self.foldedLines = 3
        self.openMaxHeight = openMaxHeight
        self.contentFolds = true
        self.external = folded
        _ownFolded = State(initialValue: true)
    }

    // MARK: Fold

    private var isFolded: Bool { external?.wrappedValue ?? ownFolded }

    /// Words are hidden by the fold (measured; half a point of slack for rounding).
    private var wordsHidden: Bool {
        // 0.7.10 words: a full text behind the short sentence is always more to read.
        if fullSentence != nil { return true }
        return sentence != nil && fullHeight > shownHeight + 0.5
    }

    /// A tap does something: it opens hidden words, or folds an opened blurb back.
    private var canToggle: Bool {
        if contentFolds { return true }
        return isFolded ? wordsHidden : true
    }

    private func toggle() {
        guard canToggle else { return }
        withAnimation(reduceMotion ? nil : Theme.Motion.standard) {
            if let external { external.wrappedValue.toggle() } else { ownFolded.toggle() }
        }
    }

    // MARK: Body

    var body: some View {
        switch role {
        case .strip:
            // Package 6: nothing drawn here. The words go up to the dock, which shows them in its strip and its sheet.
            Color.clear
                .frame(width: 0, height: 0)
                .preference(key: PhoneWordsKey.self, value: [entry])
        case .floating:
            floating
        }
    }

    /// Everything this blurb says, handed to the dock's word strip and sheet (package 6).
    private var entry: PhoneWordsEntry {
        PhoneWordsEntry(id: stripID, priority: priority, title: title, figure: figure, chips: chips,
                        sentence: sentence, fullSentence: fullSentence, equation: equation, picture: picture,
                        custom: custom, spoken: spokenText, buttons: buttons, fold: external,
                        contentFolds: contentFolds)
    }

    /// The floating look: a small card of the house panel, sized to its words.
    private var floating: some View {
        let open = !isFolded && canToggle
        return BlurbWidth(cap: open ? Self.openWidth : Self.width,
                          share: typeSize.isAccessibilitySize ? Self.accessibilityShare : nil) {
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                // Opened text scrolls past its cap; folded text is short by construction, so it never needs to.
                FittingScroll(maxHeight: open ? openMaxHeight : .greatestFiniteMagnitude) {
                    words(open: open)
                }
                .contentShape(Rectangle())
                .onTapGesture { toggle() }
                // VoiceOver: one element with the whole text, folded or not, that opens and folds like a tap.
                .accessibilityElement(children: spokenText == nil ? .combine : .ignore)
                .modifier(SpokenLabel(text: spokenText))
                .accessibilityAddTraits(canToggle ? .isButton : [])
                .accessibilityHint(canToggle ? Text(isFolded ? String(localized: "Shows more")
                                                             : String(localized: "Shows less"))
                                             : Text(verbatim: ""))
                .accessibilityAction { toggle() }
                if !buttons.isEmpty { buttonRow }
            }
            .padding(Self.padding)
            .foregroundStyle(palette.paper)
            // The house panel: opaque, a hairline rule edge, the design language's card corner (package 6; it was
            // material, which let the busy cloth show through the words).
            .background(palette.panel, in: RoundedRectangle(cornerRadius: Self.corner, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Self.corner, style: .continuous)
                    .strokeBorder(palette.rule, lineWidth: Theme.Size.hairline)
            }
        }
        .transition(Self.transition)
    }

    /// The text slots, or the custom content.
    @ViewBuilder
    private func words(open: Bool) -> some View {
        if let custom {
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                custom(open)
                if contentFolds && isFolded { moreWord }
            }
        } else {
            VStack(alignment: .leading, spacing: Theme.Space.xxs) {
                if title != nil || figure != nil { BlurbTitleLine(title: title, figure: figure) }
                if !chips.isEmpty { BlurbChipRow(chips: chips) }
                if let picture { picture }
                if let sentence { sentenceLine(sentence, open: open) }
                if let equation {
                    Text(verbatim: equation)
                        .font(Theme.equationCompact)
                        .foregroundStyle(palette.paper2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// The sentence: foldedLines lines while folded, all of it once open. A hidden full copy behind it is measured, so
    /// "More" shows only when the fold really hides words.
    private func sentenceLine(_ short: String, open: Bool) -> some View {
        // 0.7.10 words: with a full text, the folded blurb shows the short sentence whole (no line limit, so it wraps
        // and never ends in an ellipsis) and the opened blurb shows the full text in its place.
        let text = open ? (fullSentence ?? short) : short
        return VStack(alignment: .leading, spacing: Theme.Space.xxs) {
            Text(verbatim: text)
                // Package 6 (wave 1 note): the upright phone's body is the compact one.
                .font(Theme.bodyCompact)
                .lineLimit(open || fullSentence != nil ? nil : foldedLines)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { shownHeight = $0 }
                .background(alignment: .topLeading) {
                    // Same width, natural height: the sentence's full length, never drawn.
                    Text(verbatim: text)
                        .font(Theme.bodyCompact)
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fullHeight = $0 }
                        .accessibilityHidden(true)
                }
            if isFolded && wordsHidden { moreWord }
        }
    }

    /// Words are folded away: a worded "More" in the quiet style (design language principle 4: never a bare dot). The
    /// whole blurb is the tap target, so this is a label, not a second button.
    private var moreWord: some View {
        Text(String(localized: "More"))
            .font(Theme.label)
            .foregroundStyle(palette.accent)
            .accessibilityHidden(true)
    }

    /// The small buttons: the kit's quiet buttons, 44 to touch.
    private var buttonRow: some View {
        HStack(spacing: Theme.Space.md) {
            ForEach(buttons) { b in
                Button(action: b.action) { KitButtonLabel(b.title) }
                    .buttonStyle(.kitQuiet)
                    .accessibilityHint(Text(verbatim: b.hint ?? ""))
            }
        }
    }

    /// Everything the blurb says, in reading order, whatever the fold hides (Part 3, accessibility). Nil in the content
    /// form without an accessibilityText, where the content's own elements are read.
    private var spokenText: String? {
        if custom != nil { return spokenOverride }
        var parts: [String] = []
        if let title { parts.append(title) }
        if let figure { parts.append(figure.text) }
        parts += chips.map { "\($0.label) \($0.text)" }
        // The whole text, folded or not (0.7.10 words: the full sentence behind a short one).
        if let full = fullSentence ?? sentence { parts.append(full) }
        if let equation { parts.append(equation) }
        return parts.joined(separator: ". ")
    }
}

// MARK: Pieces shared with the dock's strip and sheet

/// "Throw · 2.1°": the title in the label weight, then the lead figure in the inline figure face, in its Lens mark's
/// colour (the meaning colours are the same on the cloth and in the panel).
struct BlurbTitleLine: View {
    let title: String?
    let figure: CaptionFigure?
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xxs) {
            if let title {
                Text(verbatim: title).font(Theme.heading).foregroundStyle(palette.paper).lineLimit(2)
            }
            if title != nil, figure != nil {
                Text(verbatim: "·").font(Theme.heading).foregroundStyle(palette.paper2)
            }
            if let figure {
                Text(verbatim: figure.text)
                    .font(Theme.inlineFigure)
                    .foregroundStyle(palette.color(for: figure.mark))
                    .lineLimit(1)
                    .fixedSize()
            }
        }
    }
}

/// Up to three figure chips: the kit's neutral chip (sunken capsule) with the figure in paper, a leading dot in the
/// figure's Lens mark colour, and its words. A column when one row does not fit.
struct BlurbChipRow: View {
    let chips: [CaptionFigure]
    @Environment(\.palette) private var palette

    var body: some View {
        let row = ForEach(Array(chips.enumerated()), id: \.offset) { _, f in
            Chip(value: f.text, word: f.label, dot: palette.color(for: f.mark))
        }
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Theme.Space.xs) { row }
            VStack(alignment: .leading, spacing: Theme.Space.xxs) { row }
        }
    }
}

/// Sets the accessibility label only when there is one (an empty label would silence the combined children).
private struct SpokenLabel: ViewModifier {
    let text: String?
    func body(content: Content) -> some View {
        if let text { content.accessibilityLabel(Text(verbatim: text)) } else { content }
    }
}

/// Caps a blurb's width without fixing it: the content is offered min(offered width, cap), or a share of the offered
/// width at the accessibility sizes, and takes only what its words need below that. A Layout rather than a
/// GeometryReader so the blurb stays as small as its text.
private struct BlurbWidth: Layout {
    var cap: CGFloat
    var share: CGFloat?

    private func limit(_ proposal: ProposedViewSize) -> CGFloat {
        guard let w = proposal.width, w.isFinite else { return cap }
        if let share { return max(0, w * share) }
        return min(w, cap)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let child = subviews.first else { return .zero }
        // Height is left to the content: a blurb is as tall as its words, never stretched by its container.
        return child.sizeThatFits(ProposedViewSize(width: limit(proposal), height: nil))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let child = subviews.first else { return }
        let size = child.sizeThatFits(ProposedViewSize(width: limit(proposal), height: nil))
        child.place(at: bounds.origin, proposal: ProposedViewSize(size))
    }
}

/// The line joining an anchored blurb to its moment: 2 points over a 4-point dark shadow, round caps (the Lens tips'
/// pointer line, LensCallouts.swift). Points are in this view's own space, so lay it over the same frame the anchor and
/// the blurb's frame were measured in (StageSpace on the stage). Never takes touches; VoiceOver skips it. Package 6:
/// the upright phone's explanation no longer uses it (its words are in the dock); the what-if's and the every-surface
/// fan's anchored results still do.
struct BlurbLeader: View {
    let from: CGPoint
    let to: CGPoint
    /// The leader's colour; nil draws it in paper.
    var colour: Color? = nil
    @Environment(\.palette) private var palette

    var body: some View {
        Canvas { ctx, _ in
            var line = Path()
            line.move(to: from)
            line.addLine(to: to)
            ctx.stroke(line, with: .color(.black.opacity(0.45)), style: StrokeStyle(lineWidth: 4, lineCap: .round))  // design-lint: allow the leader's legibility shadow on any cloth
            ctx.stroke(line, with: .color(colour ?? palette.paper), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
