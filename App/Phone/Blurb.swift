// Author: Claude Opus 5.5 Medium
// Date: 22-November-2026
// Edited: Claude Opus 5.5 Medium, 25-November-2026 (0.7.9: an optional picture slot under the chips, for the jump's
//          side view inside its explanation.)
// PURPOSE: The Blurb, the one text component of the upright phone (plans/22-Nov-2026-phone-ui-plan.md, Part 3 "The
//          Blurb"). Words on the upright phone are no longer full-width glass cards: each piece of text is a small
//          blurb sized to its words, on thin material (regular once opened), corner 12, padding 10, at most 260 wide
//          (85 per cent of the offered width at the accessibility text sizes), as tall as its content and no taller.
//          Slots, in order, each optional: a title with its lead figure after it ("Throw · 2.1°"), up to three figure
//          chips (Caption.figures), one sentence (three lines while folded), the worked equation, and up to two small
//          glass buttons. A tap opens a folded blurb in place (up to 370 wide, scrolling past openMaxHeight) and a second
//          tap folds it again; a "more" dot shows while words are folded away. VoiceOver always reads the whole text,
//          folded or not. Also BlurbLeader, the 2-point line over a 4-point shadow (the Lens tips' line) that joins an
//          anchored blurb to its moment, and BlurbButton, the value a caller hands in for each small button.
//          Used by the phone-only views (PhoneTitleRow's neighbours: the docked and anchored blurbs other files build,
//          and ShowpieceView's Ride map). Placement is not decided here: docked blurbs sit in ShowpieceView's stack, and
//          anchored ones are placed by BlurbPlacement. Reads Theme (fonts) and the palette (figure colours) only.
// SRP/DRY check: Pass - checked CaptionViews.swift (FigureTile is the old card's tile, private there; the chip here is
//          the plan's smaller caption-size chip), Surfaces.swift (glassCard is glass, and blurbs are content, never
//          glass) and LensCallouts.swift (its pointer line is the look BlurbLeader repeats, drawn the same two strokes).
//          FittingScroll (Surfaces.swift) is reused for the opened blurb's scrolling.
import SwiftUI

/// One small glass button inside a blurb (at most two per blurb), for a choice that is not the screen's primary action
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
    /// The width a folded blurb never passes (Part 3: "width follows the text up to 260").
    static let width: CGFloat = 260
    /// The width an opened blurb may grow to.
    static let openWidth: CGFloat = 370
    /// The share of the offered width at the accessibility text sizes, where 260 would leave a word a line.
    static let accessibilityShare: CGFloat = 0.85
    /// Corner, padding.
    static let corner: CGFloat = 12
    static let padding: CGFloat = 10
    /// How a blurb comes and goes: a fade with a slight scale (Part 3). The parent animates the change.
    static var transition: AnyTransition { .opacity.combined(with: .scale(scale: 0.96)) }

    // MARK: What it shows

    private let title: String?
    private let figure: CaptionFigure?
    private let chips: [CaptionFigure]
    private let sentence: String?
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
    /// The content form with a fold: always offers the tap and the dot (the content decides what it hides).
    private let contentFolds: Bool

    // MARK: Fold state

    /// The caller's fold switch, when it owns one (a held replay that must stay held while open, the title row's idea).
    private let external: Binding<Bool>?
    /// The blurb's own fold switch otherwise.
    @State private var ownFolded: Bool
    /// The sentence's height as shown and at full length, measured, so the dot shows only when words are hidden.
    @State private var shownHeight: CGFloat = 0
    @State private var fullHeight: CGFloat = 0

    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The slots form. Every argument is optional; pass only what this blurb says. Strings are already translated.
    /// - folded: the caller's fold switch (true is folded); nil lets the blurb keep its own, starting at startsFolded.
    /// - foldedLines: how many lines of the sentence show while folded.
    /// - buttons: at most two are drawn; any more are ignored.
    init(title: String? = nil, figure: CaptionFigure? = nil, chips: [CaptionFigure] = [], sentence: String? = nil,
         equation: String? = nil, picture: AnyView? = nil, folded: Binding<Bool>? = nil, startsFolded: Bool = true,
         foldedLines: Int = 3, openMaxHeight: CGFloat = 420, buttons: [BlurbButton] = []) {
        self.title = title
        self.figure = figure
        self.chips = Array(chips.prefix(3))
        self.sentence = sentence
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

    /// Any content on the blurb's material, without a fold (the Lens key, Ride's map, a one-line notice).
    /// - accessibilityText: the whole text VoiceOver reads; nil reads the content's own elements, combined.
    init<Content: View>(accessibilityText: String? = nil, buttons: [BlurbButton] = [],
                        @ViewBuilder content: () -> Content) {
        let built = AnyView(content())
        self.title = nil; self.figure = nil; self.chips = []; self.sentence = nil; self.equation = nil; self.picture = nil
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
    /// and opened forms; the blurb adds the tap, the dot while folded, the wider opened width and the scrolling.
    init<Content: View>(folded: Binding<Bool>, accessibilityText: String? = nil, openMaxHeight: CGFloat = 420,
                        buttons: [BlurbButton] = [], @ViewBuilder content: @escaping (_ open: Bool) -> Content) {
        self.title = nil; self.figure = nil; self.chips = []; self.sentence = nil; self.equation = nil; self.picture = nil
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
    private var wordsHidden: Bool { sentence != nil && fullHeight > shownHeight + 0.5 }

    /// A tap does something: it opens hidden words, or folds an opened blurb back.
    private var canToggle: Bool {
        if contentFolds { return true }
        return isFolded ? wordsHidden : true
    }

    private func toggle() {
        guard canToggle else { return }
        withAnimation(reduceMotion ? nil : .smooth) {
            if let external { external.wrappedValue.toggle() } else { ownFolded.toggle() }
        }
    }

    // MARK: Body

    var body: some View {
        let open = !isFolded && canToggle
        BlurbWidth(cap: open ? Self.openWidth : Self.width,
                   share: typeSize.isAccessibilitySize ? Self.accessibilityShare : nil) {
            VStack(alignment: .leading, spacing: 6) {
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
            // Content, never glass (Part 3): thin material folded, regular once opened (longer text needs the calm).
            .background(open ? Material.regular : Material.thin,
                        in: .rect(cornerRadius: Self.corner, style: .continuous))
        }
        .transition(Self.transition)
    }

    /// The text slots, or the custom content.
    @ViewBuilder
    private func words(open: Bool) -> some View {
        if let custom {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                custom(open)
                if contentFolds && isFolded { moreDot }
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                if title != nil || figure != nil { titleLine }
                if !chips.isEmpty { chipRow }
                if let picture { picture }
                if let sentence { sentenceLine(sentence, open: open) }
                if let equation {
                    Text(verbatim: equation)
                        .font(Theme.blurbEquation)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// "Throw · 2.1°": the title, then the lead figure in bold monospaced white.
    private var titleLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if let title {
                Text(verbatim: title).font(Theme.blurbTitle).lineLimit(2)
            }
            if title != nil, figure != nil {
                Text(verbatim: "·").font(Theme.blurbTitle).foregroundStyle(.secondary)
            }
            if let figure {
                Text(verbatim: figure.text).font(Theme.blurbFigure).foregroundStyle(.white).lineLimit(1).fixedSize()
            }
        }
    }

    /// Up to three figure chips: the number in its Lens mark's colour (magenta sliding, cyan rolling, the event
    /// colours otherwise), the few words after it in the secondary colour. A column when one row does not fit.
    private var chipRow: some View {
        let row = ForEach(Array(chips.enumerated()), id: \.offset) { _, f in chip(f) }
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) { row }
            VStack(alignment: .leading, spacing: 4) { row }
        }
    }

    private func chip(_ f: CaptionFigure) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(verbatim: f.text).font(Theme.blurbChip).foregroundStyle(palette.color(for: f.mark))
            Text(verbatim: f.label).font(Theme.blurbChipLabel).foregroundStyle(.secondary)
        }
        .lineLimit(1)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(.white.opacity(0.08), in: .capsule)
    }

    /// The sentence: foldedLines lines while folded, all of it once open. A hidden full copy behind it is measured, so
    /// the dot shows only when the fold really hides words.
    private func sentenceLine(_ text: String, open: Bool) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 6) {
            Text(verbatim: text)
                .font(Theme.body)
                .lineLimit(open ? nil : foldedLines)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { shownHeight = $0 }
                .background(alignment: .topLeading) {
                    // Same width, natural height: the sentence's full length, never drawn.
                    Text(verbatim: text)
                        .font(Theme.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fullHeight = $0 }
                        .accessibilityHidden(true)
                }
            if isFolded && wordsHidden { moreDot }
        }
    }

    /// The "more" dot: words are folded away, tap to read them.
    private var moreDot: some View {
        Image(systemName: "circle.fill")
            .font(.system(size: 7))
            .foregroundStyle(.white.opacity(0.8))
            .padding(.bottom, 2)
            .accessibilityHidden(true)
    }

    /// The small glass buttons: 32 drawn, 44 to touch.
    private var buttonRow: some View {
        HStack(spacing: 8) {
            ForEach(buttons) { b in
                Button(action: b.action) {
                    Text(verbatim: b.title)
                        .font(Theme.blurbButton)
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 32)
                        .glassEffect(.regular.interactive(), in: .capsule)
                        // Inside the label, so the button itself is 44 high to touch (a frame outside a Button does
                        // not widen what it takes).
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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
        if let sentence { parts.append(sentence) }
        if let equation { parts.append(equation) }
        return parts.joined(separator: ". ")
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
/// the blurb's frame were measured in (StageSpace on the stage). Never takes touches; VoiceOver skips it.
struct BlurbLeader: View {
    let from: CGPoint
    let to: CGPoint
    var colour: Color = .white

    var body: some View {
        Canvas { ctx, _ in
            var line = Path()
            line.move(to: from)
            line.addLine(to: to)
            ctx.stroke(line, with: .color(.black.opacity(0.45)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            ctx.stroke(line, with: .color(colour), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
