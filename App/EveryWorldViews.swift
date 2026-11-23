// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: The controls and words of "Same shot, every surface" (0.7.7, plans/23-Nov-2026-every-world-plan.md Build
//          step 7). Nothing here opens by itself, suggests itself, plays a sound or carries a badge.
//            - EveryWorldMenuItem: the entry ("Every surface", square.3.layers.3d), shown only while the fan can open
//              and is not already showing; in the upright phone's More menu under What if, and first in the Surface menu
//              (SurfaceMenuItems, with a divider under it that shows only with the item).
//            - EveryWorldChipRow: a horizontal row of ten chips (a colour dot, the symbol, the surface's name; home
//              marked "Played here" with a white underline, the picked chip with an underline in its colour). Tapping a
//              chip picks it, tapping it again (or home) shows all. Shared by the phone panel and the compact card.
//            - EveryWorldPhonePanel: the upright phone's bottom bar, in the aiming panel's place (the what-if's slot; the
//              two never show together): the title, "Play on" (the white capsule, only while the fan can switch) and
//              Close, then the chip row. Regular glass sized to its content, the same height whatever is picked, so
//              the table never reframes.
//            - EveryWorldPhoneBlurb: the sentence as an anchored blurb (never a card), at the end of the shown surface's
//              struck-ball path, above or below by BlurbPlacement.anchored, with a leader in that surface's colour
//              that follows the camera; with no room either side it docks at the top of the table area. Folded to two
//              lines; a tap opens it to the surface's own one-line explanation. Its two small buttons: Watch them roll,
//              and Show this one (or Show all once something is picked).
//            - EveryWorldCard: the card in the side column, the narrow bottom stack and the notebook (iPad, Mac, the
//              open Duo, where the table half shows only lines and tags). Full form: title and Close, the fixed line,
//              the sentence with its explanation, ten rows (one per surface with its own sentence; a checkmark on the
//              picked one, "Played here" on home), Watch them roll, and Play on when the fan can switch. Compact form
//              (a guided Lens replay, or the narrow tall size classes outside the notebook, WhatIfCard's own rule):
//              title and Close, the sentence folded to two lines, the chip row (left out under a guided replay) and
//              one button row. It never wraps itself in a scroll view: every container it sits in already scrolls.
//          A selection haptic on each pick when Vibration is on. Animations are off under Reduce Motion. VoiceOver: the
//          panel is one container labelled "Every surface"; each chip or row is a button named by its surface, whose
//          value is that surface's sentence, selected when picked. ShowpieceView, NotebookPanel, PhoneTitleRow and
//          SurfaceMenuItems mount these.
// SRP/DRY check: Pass - follows WhatIfViews (the card's glass, the compact rule, the phone panel's glass and
//          PhonePanelControl, the anchored blurb's placement through BlurbPlacement, Blurb and BlurbLeader) without
//          copying its what-if controls; the words are EveryWorldWords, the state EveryWorldFan, the colours
//          EveryWorldLook. Nothing else draws these controls.
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

// MARK: The entry

/// "Every surface" as a menu item: present only while the fan can open and is not already showing. With `divider`
/// (the Surface menu) a divider follows it inside the same condition, so the menu never shows a stray divider.
struct EveryWorldMenuItem: View {
    let model: ShowpieceModel
    var divider = false

    var body: some View {
        if model.everyWorld.canOpen && !model.everyWorld.isShowing {
            Button { model.everyWorld.open() } label: {
                Label(EveryWorldWords.title, systemImage: EveryWorldWords.symbol)
            }
            .accessibilityHint(EveryWorldWords.menuHint)
            if divider { Divider() }
        }
    }
}

// MARK: Shared pieces

/// How strongly a surface's chip or row is drawn: half while it is still solving, faint when it ran too long.
@MainActor
private func surfaceOpacity(_ s: PlaySurface, _ fan: EveryWorldFan) -> Double {
    guard s != fan.home, let slot = fan.slots[s] else { return s == fan.home ? 1 : 0.5 }
    switch slot {
    case .solving: return 0.5
    case .tooLong: return 0.35
    case .solved: return 1
    }
}

/// A tap on a surface: home, or the picked one again, shows all; any other surface is picked (a surface not yet
/// solved, or too long, is ignored by the fan).
@MainActor
private func tapSurface(_ s: PlaySurface, _ fan: EveryWorldFan) {
    if s == fan.home || s == fan.picked { fan.pick(nil) } else { fan.pick(s) }
}

/// The ten chips in one horizontal row, 44 high. Shared by the upright phone's panel and the compact card.
struct EveryWorldChipRow: View {
    let model: ShowpieceModel
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var fan: EveryWorldFan { model.everyWorld }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PlaySurface.allCases) { s in chip(s).id(s) }
                }
                .padding(.vertical, 2)
            }
            .scrollBounceBehavior(.basedOnSize)
            // The picked chip is scrolled into view (the controller's d-pad can pick one off screen).
            .onChange(of: fan.picked) { _, p in
                guard let p else { return }
                withAnimation(reduceMotion ? nil : .smooth) { proxy.scrollTo(p, anchor: .center) }
            }
        }
    }

    private func chip(_ s: PlaySurface) -> some View {
        let colour = s.fanColour(contrast)
        let isHome = s == fan.home
        let isPicked = s == fan.picked
        return Button { tapSurface(s, fan) } label: {
            HStack(spacing: 6) {
                Circle().fill(colour).frame(width: 8, height: 8)
                Image(systemName: s.symbol).foregroundStyle(colour)
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: s.title).font(Theme.phoneControl).lineLimit(1)
                    if isHome {
                        Text(EveryWorldWords.playedHere).font(.caption2).foregroundStyle(.white.opacity(0.75)).lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            // Home: a 2-point white underline; the picked chip: a 3-point one in its colour.
            .overlay(alignment: .bottom) {
                if isPicked {
                    Capsule().fill(colour).frame(height: 3).padding(.horizontal, 12).padding(.bottom, 3)
                } else if isHome {
                    Capsule().fill(.white).frame(height: 2).padding(.horizontal, 12).padding(.bottom, 3)
                }
            }
            .modifier(PhonePanelControl(shape: .capsule))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .fixedSize()
        .opacity(surfaceOpacity(s, fan))
        .accessibilityLabel(Text(verbatim: s.title))
        .accessibilityValue(Text(verbatim: EveryWorldWords.spoken(s, fan: fan)))
        .accessibilityHint(Text(verbatim: EveryWorldWords.chipHint))
        .accessibilityAddTraits(isPicked ? .isSelected : [])
    }
}

/// The sentence shown now with its explanation after it: the blurb's and the compact card's full text.
@MainActor
private func fullSentence(_ fan: EveryWorldFan) -> String {
    [fan.shownSentence, fan.shownSummary].compactMap { $0 }.joined(separator: " ")
}

// MARK: The card (side column, bottom stack, notebook)

/// The fan's card; shown only while model.everyWorld.isShowing.
struct EveryWorldCard: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette
    @Environment(\.colorSchemeContrast) private var contrast
    /// A guided Lens replay on a phone held upright: the card folds to its header, sentence and buttons.
    @Environment(\.lensReplayCompact) private var lensReplayCompact
    /// In the notebook the card keeps its full form beside the table.
    @Environment(\.inlinePages) private var inlinePages
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif
    /// The compact form's sentence opened to its explanation (a tap); closed again whenever the fan closes.
    @State private var sentenceOpen = false

    private var fan: EveryWorldFan { model.everyWorld }

    /// WhatIfCard.compact's rule exactly: a guided Lens replay that slims the cards, or the narrow, tall size classes
    /// outside the notebook (the narrow bottom stack: a closed Duo, a narrow iPad window), where ten 44-point rows would
    /// take the table's height.
    private var compact: Bool {
        if lensReplayCompact { return true }
        #if os(iOS)
        return !inlinePages && horizontalSizeClass == .compact && verticalSizeClass == .regular
        #else
        return false
        #endif
    }

    var body: some View {
        // The haptic sits on the always-present Group, so each pick fires it once.
        Group {
            if fan.isShowing, fan.real != nil {
                if compact { compactCard(slim: lensReplayCompact) } else { card }
            }
        }
        .sensoryFeedback(trigger: fan.picks) { _, _ in GameSettings.hapticsOn ? .selection : nil }
        .onChange(of: fan.isShowing) { _, showing in if !showing { sentenceOpen = false } }
    }

    // MARK: Full form

    private var card: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            Text(EveryWorldWords.fixedLine)
                .font(Theme.body)
                .foregroundStyle(palette.paper.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 4) {
                Text(fan.shownSentence)
                    .font(Theme.body)
                    .foregroundStyle(palette.paper)
                    .fixedSize(horizontal: false, vertical: true)
                if let summary = fan.shownSummary {
                    Text(summary)
                        .font(.caption)
                        .foregroundStyle(palette.paper.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            VStack(spacing: 2) {
                ForEach(PlaySurface.allCases) { s in row(s) }
            }
            buttons
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22, padding: 12)
        .tint(palette.accent)
        .accessibilityElement(children: .contain)
        .transition(.opacity)
    }

    /// One surface: its colour dot, symbol and name, its own sentence under it, a checkmark when picked.
    private func row(_ s: PlaySurface) -> some View {
        let colour = s.fanColour(contrast)
        let isHome = s == fan.home
        let isPicked = s == fan.picked
        return Button { tapSurface(s, fan) } label: {
            HStack(alignment: .top, spacing: 8) {
                Circle().fill(colour).frame(width: 8, height: 8).padding(.top, 6)
                Image(systemName: s.symbol).foregroundStyle(colour).frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: s.title).font(Theme.label.weight(.semibold)).foregroundStyle(palette.paper)
                    Text(verbatim: isHome ? EveryWorldWords.playedHere : fan.sentence(for: s))
                        .font(.caption)
                        .foregroundStyle(palette.paper.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if isPicked {
                    Image(systemName: "checkmark").font(.caption.weight(.bold)).foregroundStyle(colour)
                }
            }
            .padding(.vertical, 4)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(surfaceOpacity(s, fan))
        .accessibilityLabel(Text(verbatim: s.title))
        .accessibilityValue(Text(verbatim: EveryWorldWords.spoken(s, fan: fan)))
        .accessibilityHint(Text(verbatim: EveryWorldWords.chipHint))
        .accessibilityAddTraits(isPicked ? .isSelected : [])
    }

    private var buttons: some View {
        CardButtonRow {
            Button { fan.playAll() } label: {
                Label(EveryWorldWords.watchRoll, systemImage: "play.fill").font(.headline).lineLimit(1)
                    .frame(minHeight: CallMetrics.buttonHeight)
            }
            .buttonStyle(.glass)
            .disabled(!anySolved)
            .accessibilityHint(EveryWorldWords.watchRollHint)
            // Present only when the switch would play what was drawn (free play): absent, not disabled, otherwise.
            if fan.canSwitch, let p = fan.picked {
                Button { fan.switchToPicked() } label: {
                    Label(EveryWorldWords.playOn(p), systemImage: p.symbol).font(.headline).lineLimit(1)
                        .frame(minHeight: CallMetrics.buttonHeight)
                }
                .buttonStyle(.glassProminent)
                .foregroundStyle(palette.ground)
                .accessibilityHint(EveryWorldWords.playOnHint(p))
            }
        }
    }

    // MARK: Compact form

    private func compactCard(slim: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            compactSentence
            if !slim { EveryWorldChipRow(model: model) }
            compactButtons
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 22, padding: 12)
        .tint(palette.accent)
        .accessibilityElement(children: .contain)
        .transition(.opacity)
    }

    /// The sentence folded to two lines; a tap opens it to the surface's explanation. VoiceOver always reads it all.
    private var compactSentence: some View {
        let full = fullSentence(fan)
        return Group {
            if sentenceOpen {
                Text(full).fixedSize(horizontal: false, vertical: true)
            } else {
                Text(fan.shownSentence).lineLimit(2, reservesSpace: true).truncationMode(.tail)
            }
        }
        .font(Theme.body)
        .foregroundStyle(palette.paper)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { sentenceOpen.toggle() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: full))
    }

    private var compactButtons: some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)
            Button { fan.playAll() } label: {
                Label(EveryWorldWords.watchRoll, systemImage: "play.fill").font(.headline).lineLimit(1)
                    .frame(minHeight: CallMetrics.buttonHeight)
            }
            .buttonStyle(.glass)
            .disabled(!anySolved)
            .accessibilityHint(EveryWorldWords.watchRollHint)
            if fan.canSwitch, let p = fan.picked {
                Button { fan.switchToPicked() } label: {
                    Label(EveryWorldWords.playOn(p), systemImage: p.symbol).font(.headline).lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(minHeight: CallMetrics.buttonHeight)
                }
                .buttonStyle(.glassProminent)
                .foregroundStyle(palette.ground)
                .accessibilityHint(EveryWorldWords.playOnHint(p))
            }
        }
    }

    // MARK: Shared

    private var anySolved: Bool { fan.others.contains { fan.world($0) != nil } }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: EveryWorldWords.symbol).foregroundStyle(palette.accent).accessibilityHidden(true)
            Text(EveryWorldWords.title).font(Theme.heading).lineLimit(1).accessibilityAddTraits(.isHeader)
            if fan.showSpinner {
                ProgressView().controlSize(.small).accessibilityLabel(EveryWorldWords.working)
            }
            Spacer(minLength: 0)
            Button { fan.close() } label: {
                Image(systemName: "xmark").frame(width: 30, height: 30)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel(String(localized: "Close"))
        }
    }
}

// MARK: The upright phone

/// The fan's controls on the upright phone, in the aiming panel's place in the bottom bar while the fan shows. One
/// regular glass shape with the controls drawn on it as content (no glass on glass): the title, Play on and Close,
/// then the chip row. The same height whatever is picked: Play on is a 44-point capsule in the 44-point Close row.
struct EveryWorldPhonePanel: View {
    let model: ShowpieceModel
    @Environment(\.palette) private var palette

    private var fan: EveryWorldFan { model.everyWorld }

    var body: some View {
        Group {
            if fan.isShowing {
                VStack(alignment: .leading, spacing: 10) {
                    header
                    EveryWorldChipRow(model: model)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.regular, in: .rect(cornerRadius: PhoneAimPanel.corner, style: .continuous))
                .accessibilityElement(children: .contain)
                .accessibilityLabel(EveryWorldWords.title)
            }
        }
        .sensoryFeedback(trigger: fan.picks) { _, _ in GameSettings.hapticsOn ? .selection : nil }
    }

    /// The title, then Play on and Close at the right. When the row does not fit (a long language, large text) the
    /// title steps out first (VoiceOver still hears it on the panel), then Play on's words may shrink.
    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { title; Spacer(minLength: 0); buttons(fixed: true) }
            HStack(spacing: 8) { Spacer(minLength: 0); buttons(fixed: true) }
            HStack(spacing: 8) { Spacer(minLength: 0); buttons(fixed: false) }
        }
    }

    private var title: some View {
        HStack(spacing: 6) {
            Image(systemName: EveryWorldWords.symbol).foregroundStyle(palette.accent).accessibilityHidden(true)
            Text(EveryWorldWords.title).font(Theme.phoneTitle).lineLimit(1).accessibilityAddTraits(.isHeader)
            if fan.showSpinner {
                ProgressView().controlSize(.small).accessibilityLabel(EveryWorldWords.working)
            }
        }
        .fixedSize()
    }

    @ViewBuilder private func buttons(fixed: Bool) -> some View {
        // Present only when the switch would play what was drawn (free play): absent, not disabled, otherwise.
        if fan.canSwitch, let p = fan.picked {
            Button { fan.switchToPicked() } label: {
                Text(EveryWorldWords.playOn(p))
                    .font(Theme.phoneControl).lineLimit(1)
                    .minimumScaleFactor(fixed ? 1 : 0.7)
                    .padding(.horizontal, 16).frame(minHeight: 44)
                    .foregroundStyle(palette.ground)
                    .background(.white, in: .capsule)
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .fixedSize(horizontal: fixed, vertical: false)
            .accessibilityHint(EveryWorldWords.playOnHint(p))
        }
        Button { fan.close() } label: {
            Image(systemName: "xmark")
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .modifier(PhonePanelControl(shape: .circle))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Close"))
    }
}

/// The fan's sentence on the upright phone (phone UI plan Part 3: words are blurbs sized to their text, never cards),
/// anchored to the end of the shown surface's struck-ball path (where it stopped, or where a pocket took it), above or
/// below it by BlurbPlacement.anchored, with a leader in that surface's colour that follows the camera every frame;
/// with no anchor or no room either side it sits at the top of the table area with no leader. The blurb itself keeps
/// its place for the whole result and moves only when the shown surface changes or the table area does. While the
/// fan is still filling it says nothing, except the working line once the spinner would show. A full-stage layer that
/// takes touches only on the blurb.
struct EveryWorldPhoneBlurb: View {
    let model: ShowpieceModel
    let bridge: SceneBridge
    /// Where blurbs may go, in StageSpace: under the title row (or the lowest docked blurb), above the control bar.
    let tableArea: CGRect

    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// What the blurb is placed for: the surface it is about, and whether the words are the result (not the working
    /// line). A change of either places it afresh.
    private struct Key: Equatable {
        let shown: PlaySurface?
        let ready: Bool
    }

    /// Where the blurb was put: its frame in StageSpace, the side of the anchor it took (nil: docked, no leader) and the
    /// leader's end on its near edge.
    private struct Placed: Equatable {
        let key: Key
        let frame: CGRect
        let side: BlurbPlacement.Side?
        let leaderTo: CGPoint
    }

    @State private var placed: Placed? = nil
    @State private var size: CGSize = .zero
    @State private var origin: CGPoint = .zero
    @State private var layerSize: CGSize = .zero
    @State private var cameraBox = AimProjector.CameraBox()

    /// Marks on the cloth sit just above it, as the overlay draws them, so the leader meets the symbol tag.
    private static let onCloth: Float = 0.001
    /// What the blurb keeps clear of around its anchor: the symbol tag is 18 points across, plus a little air.
    private static let clearSide: CGFloat = 30

    private var fan: EveryWorldFan { model.everyWorld }

    private var key: Key {
        Key(shown: fan.shownSurface, ready: fan.picked != nil || fan.fanSentence != nil)
    }

    /// There is something to say: a result, or the working line once nothing has landed for a moment.
    private var hasWords: Bool { key.ready || fan.showSpinner }

    var body: some View {
        let now = key
        let shown = placed?.key == now ? placed : nil
        ZStack(alignment: .topLeading) {
            // Fills the stage so the offsets below are from its corner; never takes a touch (aiming passes through).
            Color.clear.allowsHitTesting(false)
            if fan.isShowing, hasWords {
                if let shown, shown.side != nil, let s = now.shown {
                    // Re-projected every frame so the leader follows the camera while the blurb stays put.
                    TimelineView(.animation) { _ in
                        if let anchor = anchorPoint() {
                            BlurbLeader(from: local(anchor), to: local(shown.leaderTo), colour: s.fanColour(contrast))
                        }
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
                Blurb(sentence: now.ready ? fullSentence(fan) : EveryWorldWords.working, foldedLines: 2,
                      buttons: buttons)
                    // The words keep the reader's direction; only the placement is in screen points.
                    .environment(\.layoutDirection, layoutDirection)
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { new in
                        size = new
                        place(keepSide: true)
                    }
                    .frame(width: max(0, tableArea.width - 2 * BlurbPlacement.margin), alignment: .topLeading)
                    .offset(x: (shown?.frame.minX ?? 0) - origin.x, y: (shown?.frame.minY ?? 0) - origin.y)
                    // Unseen and silent until it has a place, so it never flashes at the corner.
                    .opacity(shown == nil ? 0 : 1)
                    .accessibilityHidden(shown == nil)
                    .transition(Blurb.transition)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // Placed in screen points from the 3D projection, which does not mirror for right-to-left languages.
        .environment(\.layoutDirection, .leftToRight)
        // The same screen EveryWorldOverlay projects onto (it ignores the safe area too), so the anchor is the tag.
        .ignoresSafeArea()
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(StageSpace.name)) } action: { frame in
            origin = frame.origin
            layerSize = frame.size
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: fan.isShowing)
        .animation(reduceMotion ? nil : .smooth(duration: 0.3), value: placed)
        // A new surface shown (a pick, or the headline arriving): placed afresh, below its anchor first.
        .onChange(of: key) { _, _ in place(keepSide: false) }
        // The table area moved (a docked blurb came or went, the bar grew): placed again, same side first.
        .onChange(of: tableArea) { _, _ in place(keepSide: true) }
        // Closed: forget the place, so the next fan never opens at a stale spot.
        .onChange(of: fan.isShowing) { _, showing in if !showing { placed = nil } }
    }

    private var buttons: [BlurbButton] {
        guard key.ready else { return [] }
        var list: [BlurbButton] = []
        if fan.others.contains(where: { fan.world($0) != nil }) {
            list.append(BlurbButton(EveryWorldWords.watchRoll, hint: EveryWorldWords.watchRollHint) { fan.playAll() })
        }
        if fan.picked != nil {
            list.append(BlurbButton(EveryWorldWords.showAll) { fan.pick(nil) })
        } else if let lead = fan.headline, lead.contrast != .world(.alike), fan.world(lead.surface) != nil {
            list.append(BlurbButton(EveryWorldWords.showThis) { fan.pick(lead.surface) })
        }
        return list
    }

    // MARK: Placement (all in StageSpace)

    /// The anchor on screen, in StageSpace: the end of the shown surface's struck-ball path; nil without one, or when
    /// the table is not up or the point is behind the camera. Projected exactly as EveryWorldOverlay draws the tag.
    private func anchorPoint() -> CGPoint? {
        guard let s = key.shown, let end = fan.world(s)?.cuePath.last, layerSize.width > 0, layerSize.height > 0,
              let root = bridge.table?.root,
              let proj = AimProjector(camera: cameraBox.find(in: root), size: layerSize,
                                      frame: TableFrame(model.timeline.table)),
              let screen = proj.screen(end, height: Self.onCloth)
        else { return nil }
        return CGPoint(x: screen.x + origin.x, y: screen.y + origin.y)
    }

    /// Works out the blurb's place for what is shown. keepSide: try the side it already has first (an opened blurb
    /// stays on its side of the anchor); otherwise below first.
    private func place(keepSide: Bool) {
        guard fan.isShowing, size.width > 0, size.height > 0, tableArea.height > 0 else { return }
        let now = key
        let current = placed?.key == now ? placed : nil
        let preferred: BlurbPlacement.Side = keepSide ? (current?.side ?? .below) : .below
        let next: Placed
        if now.ready, let anchor = anchorPoint(),
           let anchored = BlurbPlacement.anchored(
               anchor: anchor, size: size, tableArea: tableArea,
               keepClear: CGRect(x: anchor.x - Self.clearSide / 2, y: anchor.y - Self.clearSide / 2,
                                 width: Self.clearSide, height: Self.clearSide),
               preferred: preferred) {
            next = Placed(key: now, frame: anchored.frame, side: anchored.side, leaderTo: anchored.leaderTo)
        } else {
            // No anchor, or no room either side: at the top of the table area, at the left margin, with no leader.
            let frame = BlurbPlacement.dockedFrames(sizes: [size], top: tableArea.minY + BlurbPlacement.dockSpacing,
                                                    area: tableArea)[0]
            next = Placed(key: now, frame: frame, side: nil, leaderTo: .zero)
        }
        if placed != next { placed = next }
    }

    /// A StageSpace point in this layer's own space.
    private func local(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x - origin.x, y: p.y - origin.y) }
}
