<!--
Author: Claude Opus 5.5 High
Date: 22-November-2026
PURPOSE: Apple's Liquid Glass guidance and SwiftUI APIs (iOS 26), gathered from Apple's design guidelines and developer documentation for the phone UI redesign; includes the do's and don'ts and icon guidance. Developer reference.
SRP/DRY check: Pass - reference material for plans/22-Nov-2026-phone-ui-plan.md; not repeated there.
-->
# Liquid Glass brief

A note for the parent first: the Boss's own rules ban code and numbers in what he reads. The signatures and versions below are for whoever builds this. Anything passed on to him should be in plain words.

## Liquid Glass brief for Breakdown's phone screen

I checked everything below against Apple's documentation data on 22 Nov 2026. Unless marked otherwise, every API is iOS 26.0 and later.

### (1) Principles

- **Two layers.** Glass is "a distinct functional layer for controls and navigation elements … that floats above the content layer" (HIG Materials). The table and everything that explains it, including the explanation words, are content. Glass is only for controls and navigation.
- **Use it sparingly.** "Limit these effects to the most important functional elements in your app" (HIG Materials; Adopting Liquid Glass). Never layer glass on glass: "avoid overcrowding or layering Liquid Glass elements on top of each other" (Adopting).
- **Regular or clear.**
  - Regular blurs the background and adjusts its brightness. Apple says to use it for components with "a significant amount of text".
  - Clear is "highly translucent". Apple says to use it "for components that float above media backgrounds".
  - With clear glass over bright content, "consider adding a dark dimming layer of 35% opacity". Over dark enough content, no dimming layer is needed (HIG Materials).
- **Colour.** Glass has no colour of its own and takes it from what is behind. Labels on small bars are monochrome and flip light or dark to match the content underneath. Tint only the background of the one primary action: "Refrain from adding color to the background of multiple controls" (HIG Color).
- **People can change how glass looks.** They can pick a preferred glass look, turn on Reduce Transparency or Increase Contrast, and, in iOS 27, set the glass opacity with a slider. That last point comes from press reports, not Apple's pages. So legibility must never depend on how transparent the glass is.
- **Concentric corners.** Corner shapes should follow the device's corners and their containers' corners (Adopting; ConcentricRectangle).
- **Sizes.**
  - Hit region of at least 44 by 44 points (HIG Buttons). Frequent game controls at least 44 by 44, secondary ones such as menus at least 28 by 28 (HIG Game Controls).
  - No more than three glyph buttons, or two text buttons, side by side (HIG Layout).
  - "Use style — not size — to visually distinguish the preferred choice" (HIG Buttons).
  - The new extra-large size named in Adopting is not reachable on iPhone: the extra-large control size "Resolves to large on platforms other than visionOS".
- **Motion.** Glass shapes inside one container blend when close together and morph into each other on show and hide. Prefer the matched-geometry and materialize transitions (Applying Liquid Glass to custom views).

### (2) APIs (SwiftUI)

- `func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View`. The default shape resolves to a capsule. Put it after the other appearance modifiers. Example: `Text(t).padding().glassEffect(.regular.tint(.orange).interactive())`
- `struct Glass`:
  - `.regular` and `.clear`.
  - `.identity` leaves the view as if no glass were applied.
  - `func tint(_ color: Color?) -> Glass`
  - `func interactive(_ isEnabled: Bool = true) -> Glass`
  - Example: `.glassEffect(.clear).background(.black.opacity(0.3))`
- `GlassEffectContainer(spacing: CGFloat? = nil, @ContentBuilder content:)`. Gives better rendering and lets shapes morph. Example: `GlassEffectContainer(spacing: 8) { HStack(spacing: 8) { … } }`
- `func glassEffectID(_ id: (some Hashable & Sendable)?, in namespace: Namespace.ID) -> some View`. Example: `.glassEffectID("lens", in: ns)`
- `func glassEffectUnion(id: (some Hashable & Sendable)?, namespace: Namespace.ID) -> some View`. Merges shapes with the same shape and variant into one. Example: `.glassEffectUnion(id: "transport", namespace: ns)`
- `func glassEffectTransition(_ transition: GlassEffectTransition) -> some View`, with `.matchedGeometry` (the default when within the container's spacing) or `.materialize`.
- Button styles: `.buttonStyle(.glass)`, `.buttonStyle(.glassProminent)` and `.buttonStyle(.glass(.clear))`.
- `func safeAreaBar(edge: VerticalEdge, alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ContentBuilder content:) -> some View`. A custom bar that insets the safe area and extends the scroll edge effect. There is also a `HorizontalEdge` overload for side bars. Example: `.safeAreaBar(edge: .bottom) { ControlStrip() }`
- Scroll edge effects:
  - `scrollEdgeEffectStyle(_ style: ScrollEdgeEffectStyle?, for edges: Edge.Set)`, for example `.hard`.
  - `scrollEdgeEffectHidden(_ hidden: Bool = true, for edges: Edge.Set = .all)`
- Concentric shapes:
  - `ConcentricRectangle()`, or per corner, for example `ConcentricRectangle(topLeadingCorner: .concentric(minimum: 12), …)`.
  - `.rect(corners: .concentric, isUniform: true)`
  - The container is declared with `containerShape(_:)`.
- `backgroundExtensionEffect()` mirrors and blurs content under side bars.
- Toolbars:
  - `ToolbarItemPlacement.bottomBar` (iOS 14).
  - `ToolbarSpacer(.fixed)` splits shared glass groups.
  - `.sharedBackgroundVisibility(.hidden)` gives an item its own glass.
  - `.hidden(_:)` hides a whole item rather than its view.
- iOS 27 toolbar additions (from the local swiftui-whats-new-27 notes on toolbars):
  - `visibilityPriority(.high/.low)`
  - `ToolbarOverflowMenu { … }`
  - `.topBarPinnedTrailing`
  - `toolbarMinimizeBehavior(_:for:)` with `.onScrollDown` and similar
  - `ToolbarPlacement.statusBar`
  - All need `if #available(iOS 27, *)` gating if the deployment target is iOS 26.

### (3) Do's and don'ts Apple states

- "Don't use Liquid Glass in the content layer." (HIG Materials)
- "Use Liquid Glass effects sparingly." (HIG Materials)
- "Only use clear Liquid Glass for components that appear over visually rich backgrounds." (HIG Materials)
- "Reduce your use of custom backgrounds in controls and navigation elements." (Adopting)
- "avoid overcrowding or layering Liquid Glass elements on top of each other" (Adopting)
- "Combine custom Liquid Glass effects to improve rendering performance." (Adopting, about GlassEffectContainer)
- "Instead of applying a solid or semi-opaque background color beneath controls, use a scroll edge effect" (HIG Layout)
- "For full-screen background content, be sure to extend it underneath sidebars, toolbars, and tab bars" (HIG Layout)
- "Avoid applying a similar color to button labels and content layer backgrounds." (HIG Buttons)
- "If your app features colorful backgrounds or visually rich content, prefer a monochromatic appearance for toolbars" (HIG Color). A green table counts.
- "Make sure the meaning of each control is clear. Don't make people guess" (HIG Toolbars)
- "Use the `.prominent` style for key actions… Only specify one primary action" (HIG Toolbars)
- "Minimize the number of groups… aim for a maximum of three." (HIG Toolbars)
- "Show and hide virtual controls to reflect gameplay." (HIG Game Controls)
- Text on iOS: default 17 points, minimum 11 points (HIG Designing for Games).

### (4) Icons in controls

- **Familiar actions get familiar symbols.** Use standard SF Symbols for standard actions: play, pause, replay, speed, back, menu.
- **Use text when it is clearer.** "Consider using text when a short label communicates more clearly than an icon" (HIG Buttons). Toolbars should use text "for actions… that aren't well-represented by symbols". Lens, Ride and Your shot are app concepts with no standard symbol. Today's meaningless icons are exactly the "make people guess" failure. Give them short text labels, or text plus a symbol in a capsule.
- **Don't mix inside one glass group.** "don't mix text and icons across items that share a background" (Adopting). Split symbol-only and text groups with a fixed spacer.
- **Outline versus fill.** Outline suits toolbars and places next to text. Fill is for selection and tab bars (HIG SF Symbols). So the Lens toggle shows outline when off and fill when on, not a different glyph.
- **No circled symbols.** "Prefer system-provided symbols without borders"; the glass is already the container (HIG Toolbars).
- **Sizing.** Size symbols with text styles and `imageScale`, not fixed frames, so they match the font weight and grow with Dynamic Type.
- **Accessibility labels.** Every icon needs one, always (Adopting).

### (5) What this means for Breakdown on an upright phone

**The finding that matters most: the plan's Blurb, as drawn, contradicts Apple.** Part 3 calls for a translucent plate with an accent edge for every piece of text over the table. That text is content, not controls. Making it glass breaks "Don't use Liquid Glass in the content layer", "sparingly" and "no layering", and it would put glass blurbs next to a glass strip. Making it look glass-like on purpose is the same mistake. Apple's split is:

- Glass is used for exactly two things: the title row and the control strip.
- Blurbs use a standard material (ultra-thin or thin) with vibrant label colours (primary and secondary label). Thicker material for longer text, because "thicker materials… provide better contrast for text".
- The blurbs have no accent edge. Colour goes only on the highlighted figures, sparingly.

This matches the Boss's "not cards, tiny modular text" and keeps glass special.

**Bottom controls.** The current design has two rows of huge capsules. Replace them with one compact strip in a single glass container, placed with a bottom safe-area bar so the table runs full-bleed underneath:

- On the left, a transport group of symbol-only buttons: play/pause (which becomes Continue while a moment is held), replay and speed. Each is 44 points, using the glass style.
- In the middle, the scrub bar. Its knob turns to glass on its own while dragged, which is the one sanctioned content-layer glass.
- On the right, a text group: Lens and Ride as small glass capsules.
- The context action (Your shot, Your turn, or Continue for a waiting ruling) is the single prominent-glass button, tinted with the accent colour.
- The fix is fewer and smaller controls with one prominent action, not shrinking buttons below 44 points.
- What-if and less-used items go in a menu (minimum 28 points).
- Controls that don't apply right now are hidden: "Show and hide… to reflect gameplay".
- The aiming panel replaces the strip by morphing out of the same container (matched IDs), so it doesn't stack on top. It uses regular glass because it holds labels, sized to its content.

**Title row.**

- Back button with the standard chevron, no text. The menu button uses the standard ellipsis symbol. Each is its own small glass circle.
- The status title is a short line in the safe area, under 15 characters, plain text with no plate.
- The Lens key chip is content, not a control: a small material blurb that appears only while the Lens is on.
- Over a bright table, give the glass a dark dimming layer, or use regular glass.

**Variant choice.** Clear glass, with a dark dimming layer under it when the table behind is bright, for the symbol-only buttons floating over the lit table. Regular glass for anything carrying words: the text capsules, the aiming panel, an opened blurb at full height. Label colours stay monochrome on a green table.

**Explanation over the 3D scene.**

- An anchored material blurb, sized to its text, at 11 points or larger. Body text near the 15–17 point range.
- Readable with Reduce Transparency on, where the material turns opaque.
- When it appears or goes, use a materialize-style fade or morph, not a jump.
- Corners: concentric only where a blurb docks near a screen corner, otherwise a fixed small radius.

Sources (developer.apple.com):

- Technology Overviews: Adopting Liquid Glass
- Human Interface Guidelines: Materials, Color, Buttons, Toolbars, Layout, SF Symbols, Game Controls, Designing for Games
- SwiftUI: Applying Liquid Glass to custom views, glassEffect(_:in:), Glass, GlassEffectContainer, glassEffectID, glassEffectUnion, glassEffectTransition, safeAreaBar, scrollEdgeEffectStyle, ConcentricRectangle, ControlSize.extraLarge, ToolbarSpacer, sharedBackgroundVisibility
- Local notes: /Users/macmini/.claude/skills/swiftui-whats-new-27/references/toolbar.md

The iOS 27 opacity slider is from press reports only:

- [AppleInsider](https://appleinsider.com/articles/26/06/08/ios-27-gets-better-liquid-glass-and-more-responsiveness)
- [Neowin](https://www.neowin.net/news/apple-finally-brings-the-slider-for-liquid-glass-and-many-other-changes/)