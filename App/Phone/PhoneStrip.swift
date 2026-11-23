// Author: Claude Opus 5.5 Medium
// Date: 22-November-2026
// PURPOSE: The upright phone's control strip (plans/22-Nov-2026-phone-ui-plan.md, Part 3 "The control strip"), in
//          place of PlaybackControls' big capsule rows on that layout only. Two rows of small, clear controls:
//            1. the scrub rail (ScrubBar in its phone style) and the speed capsule ("Auto", "1×", "½×", "¼×", "⅒×",
//               a regular glass capsule drawn 32 high with a 44-point tap area, no symbol);
//            2. the transport (play or pause, and Replay: two 44 circles joined as one glass shape; while a guided
//               moment is held the play button is the way on, spoken "Continue"), the views ("Lens" and "Ride", text
//               capsules joined as one shape, a 3-point half-magenta half-cyan underline while on), and the primary
//               action (PhonePrimaryAction, a white glass capsule with dark text, right-aligned).
//          Each piece is regular, interactive glass on a plain button; the strip lives inside the bottom bar's one
//          GlassEffectContainer (ShowpieceView), so it makes none of its own. The primary action carries the shared
//          glass identity (PhoneGlassID.primaryAction in the environment's phoneGlassNamespace) so the aiming panel can
//          grow out of it. When the row is too wide (a long language, the accessibility text sizes) Ride, then Lens,
//          then speed (only once the rail would be under 160 points) move into the title row's menu: the strip measures
//          hidden copies of its pieces and writes the result to `overflow`, which PhoneTitleRow reads.
//          Also writes model.playbackRowTop (the third Lens tip anchors on it), as PlaybackControls does elsewhere.
//          Writes to the model only through togglePlay, nextBeat, replay(withLens:), setRate, setAutoRate, setLens,
//          setRide and the primary action's own closure.
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (the button row's gaps match the fitting sum: at the largest
//          text sizes Lens was squeezed to "Le..." instead of moving into the menu.)
// Edited: Claude Opus 5.5 Medium, 22-November-2026 (the strip's glass pieces other than the primary action come and go
//          with the materialize transition, plan Part 3 Morph: the speed capsule, the transport and Lens and Ride carry
//          it, their conditional containers fade in and out, and Lens and Ride appearing after the first shot animate.)
// SRP/DRY check: Pass - reuses ScrubBar (phone style added there), PlaybackSpeed.rates, SpeedPicker.autoShort and the
//          same model calls PlayPauseButton, ReplayButton, SpeedPicker and PlaybackControls' Lens and Ride toggles use.
//          The shared PlaybackControls stays for the notebook, the sideways column and the big-window layout.
import SwiftUI

/// What the strip moved into the title row's menu because its row was too wide. Written by PhoneStrip, read by
/// PhoneTitleRow; ShowpieceView owns the value.
struct PhoneStripOverflow: Equatable {
    var ride = false
    var lens = false
    var speed = false
}

struct PhoneStrip: View {
    let model: ShowpieceModel
    @Binding var shotPanelOpen: Bool
    /// A just-struck shot is still rolling: the primary action waits (PhonePrimaryAction.resolve).
    var shotLive = false
    @Binding var overflow: PhoneStripOverflow

    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.phoneGlassNamespace) private var sharedGlass
    @Namespace private var localGlass
    /// The transport circles grow with the text size and never drop under 44.
    @ScaledMetric(relativeTo: .body) private var circle: CGFloat = 44

    /// Measured natural widths of the pieces (hidden copies, always present, so the choice never depends on itself).
    @State private var rowWidth: CGFloat = 0
    @State private var lensWidth: CGFloat = 0
    @State private var rideWidth: CGFloat = 0
    @State private var primaryWidth: CGFloat = 0
    @State private var speedWidth: CGFloat = 0

    /// Space between the strip's groups.
    private static let spacing: CGFloat = 8
    /// The rail is never squeezed under this; below it the speed capsule moves to the menu.
    private static let shortestRail: CGFloat = 160

    // MARK: When things show

    /// The Lens button: from the end of the first minute on (never before the first shot ends), or while it is on.
    static func showsLens(_ model: ShowpieceModel) -> Bool {
        model.openingStage == .none || model.lensOn
    }

    /// The Ride button: for a finished-or-playing shot worth riding whose struck ball reaches another ball, during a
    /// trick's or lesson's own replay as before, and always while Ride is on (so it can be switched off). Never in the
    /// first minute.
    static func showsRide(_ model: ShowpieceModel) -> Bool {
        if model.rideOn { return true }
        guard model.openingStage == .none, model.ridePlan.rideable else { return false }
        return model.ridePlan.contactTime != nil || model.trickMode.isActive || model.lessonMode.isActive
    }

    /// The scrub row and transport: whenever Your shot is closed, and under the open panel while one of the shots
    /// struck at this table is on screen (so the player can replay and scrub their own shot, as PlaybackControls).
    private var showsPlayback: Bool { !shotPanelOpen || model.playerShotOnScreen }

    private var resolvedPrimary: PhonePrimaryAction? {
        PhonePrimaryAction.resolve(model, shotPanelOpen: shotPanelOpen, shotLive: shotLive)
    }

    // MARK: Body

    var body: some View {
        let primary = resolvedPrimary
        let lens = Self.showsLens(model) && !overflow.lens
        let ride = Self.showsRide(model) && !overflow.ride
        VStack(spacing: Self.spacing) {
            // Each conditional piece fades as a whole so its glass's materialize transition shows (plan Part 3 Morph).
            if showsPlayback { scrubRow.transition(.opacity) }
            if showsPlayback || primary != nil {
                HStack(spacing: Self.spacing) {
                    // The left group fills the room instead of a Spacer: a Spacer is a child of the row too, so it
                    // added a gap that wanted() never counted, and at the largest text sizes Lens looked like it fit
                    // by two points and was squeezed to "Le..." (22-Nov-2026). Now the gaps drawn are the gaps counted.
                    HStack(spacing: Self.spacing) {
                        if showsPlayback { transport.transition(.opacity) }
                        if lens || ride { views(lens: lens, ride: ride).transition(.opacity) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if let primary { primaryButton(primary) }
                }
                .frame(maxWidth: .infinity)
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { rowWidth = $0 }
            }
        }
        .background(alignment: .topLeading) { measurers(primary: primary) }
        .onChange(of: wanted(primary: primary), initial: true) { _, new in
            if overflow != new { overflow = new }
        }
        // The third Lens tip's bubble sits on the strip's top (0.7.6 coordinator, stream pacing hand-off).
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(StageSpace.name)) } action: { frame in
            let top = frame.height > 0.5 ? Double(frame.minY) : nil
            if model.playbackRowTop != top { model.playbackRowTop = top }
        }
        .onDisappear { model.playbackRowTop = nil }
        .animation(reduceMotion ? nil : .smooth, value: showsPlayback)
        .animation(reduceMotion ? nil : .smooth, value: primary?.title)
        .animation(reduceMotion ? nil : .smooth, value: overflow)
        // Lens and Ride first appear after the first shot, not on any of the values above, so they animate in too.
        .animation(reduceMotion ? nil : .smooth, value: Self.showsLens(model))
        .animation(reduceMotion ? nil : .smooth, value: Self.showsRide(model))
    }

    // MARK: Overflow

    /// What has to move into the menu for the row to fit, in the plan's order: Ride, then Lens; the speed only once the
    /// rail would be under 160 points. Before anything is measured, nothing moves.
    private func wanted(primary: PhonePrimaryAction?) -> PhoneStripOverflow {
        guard rowWidth > 0 else { return PhoneStripOverflow() }
        // The transport counts only when it shows (with the panel open and no shot of the player's on screen it is
        // gone, and counting it pushed Ride and Lens into the menu for nothing in long languages).
        var fixed: CGFloat = showsPlayback ? circle * 2 : 0
        if primary != nil { fixed += (fixed > 0 ? Self.spacing : 0) + primaryWidth }
        let lens = Self.showsLens(model) ? lensWidth : 0
        let ride = Self.showsRide(model) ? rideWidth : 0
        var result = PhoneStripOverflow()
        // The views group plus the gap before it; the Spacer keeps at least nothing, so the sum must fit the row.
        func fits(_ views: CGFloat) -> Bool { fixed + (views > 0 ? Self.spacing + views : 0) <= rowWidth }
        if !fits(lens + ride) {
            result.ride = ride > 0
            if !fits(lens) { result.lens = lens > 0 }
        }
        result.speed = rowWidth - speedWidth - Self.spacing < Self.shortestRail
        return result
    }

    /// Hidden copies of the worded pieces at their natural widths. Never drawn, never read aloud, never touched.
    private func measurers(primary: PhonePrimaryAction?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            capsuleLabel(lensTitle).fixedSize()
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { lensWidth = $0 }
            capsuleLabel(rideTitle).fixedSize()
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { rideWidth = $0 }
            primaryLabel(primary?.title ?? "").fixedSize()
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { primaryWidth = primary == nil ? 0 : $0 }
            speedLabel.fixedSize()
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { speedWidth = $0 }
        }
        .hidden()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: Row 1: rail and speed

    private var scrubRow: some View {
        HStack(spacing: Self.spacing) {
            ScrubBar(model: model, phoneStyle: true)
            if !overflow.speed { speedMenu.transition(.opacity) }
        }
    }

    /// Auto (the calm guided pace), 1×, ½×, ¼×, ⅒×: the fastest first, as the plan lists them.
    private var speedMenu: some View {
        Menu {
            Picker(String(localized: "Speed"), selection: Self.speedSelection(model)) {
                Text(String(localized: "Auto")).tag(Double?.none)
                ForEach(PlaybackSpeed.rates.reversed(), id: \.self) { r in
                    Text(verbatim: Self.speedLabel(r)).tag(Optional(r))
                }
            }
            .pickerStyle(.inline)
        } label: {
            speedLabel
                .glassEffect(.regular.interactive(), in: .capsule)
                // Materializes in and out; only the primary action is left out, since it morphs into the aiming panel
                // by its shared glass identity instead.
                .glassEffectTransition(.materialize)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
        .fixedSize()
        .accessibilityLabel(String(localized: "Playback speed"))
        .accessibilityValue(model.chosenRate.map(PlaybackSpeed.label) ?? String(localized: "Automatic"))
    }

    /// The capsule's words: "Auto" while the replay paces itself (never a rate that changes every frame), else the
    /// fixed speed. Drawn 32 high.
    private var speedLabel: some View {
        Text(verbatim: model.chosenRate.map(Self.speedLabel) ?? SpeedPicker.autoShort)
            .font(Theme.phoneSpeed)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(minWidth: 44, minHeight: 32)
    }

    /// Auto is nil: no fixed speed, the replay paces itself; a fixed speed hands the pace to the player (SpeedPicker).
    static func speedSelection(_ model: ShowpieceModel) -> Binding<Double?> {
        Binding(get: { model.chosenRate }, set: { if let r = $0 { model.setRate(r) } else { model.setAutoRate() } })
    }

    /// The speeds written as the plan writes them, with fraction signs; anything else as PlaybackSpeed writes it.
    static func speedLabel(_ r: Double) -> String {
        switch r {
        case 1: return "1×"
        case 0.5: return "½×"
        case 0.25: return "¼×"
        case 0.1: return "⅒×"
        default: return PlaybackSpeed.label(r)
        }
    }

    // MARK: Row 2: transport, views, primary

    private var isPlaying: Bool { model.playing && model.time < model.duration }

    /// Play or pause, and Replay, as one glass shape. While a guided moment is held, play continues it.
    private var transport: some View {
        let held = model.holding
        let symbol = held ? "play.fill" : (isPlaying ? "pause.fill" : "play.fill")
        let spoken = held ? String(localized: "Continue") : (isPlaying ? String(localized: "Pause") : String(localized: "Play"))
        return HStack(spacing: 0) {
            Button {
                if held { model.nextBeat() } else { model.togglePlay() }
            } label: {
                Image(systemName: symbol)
                    .contentTransition(.symbolEffect(.replace))
                    .font(.body.weight(.semibold))
                    .frame(width: circle, height: circle)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(spoken)
            .accessibilityHint(held ? String(localized: "Goes on from this moment") : String(localized: "Plays or pauses the replay"))

            Button { model.replay(withLens: true) } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.body.weight(.semibold))
                    .frame(width: circle, height: circle)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "Replay"))
            // With Ride on the replay rides behind the cue ball at the chosen pace, so slow motion is not promised then.
            .accessibilityHint(model.rideOn ? String(localized: "Starts the shot again with the Lens on")
                                            : String(localized: "Starts the shot again in slow motion with the Lens on"))
        }
        // One capsule of glass behind both: two joined circles drew a single circle off-centre between the symbols on
        // the iPhone 17 (22-Nov-2026), so the pair shares one shape instead.
        .glassEffect(.regular.interactive(), in: .capsule)
        // Materializes in and out; the primary action alone skips this, as it morphs into the aiming panel by its
        // shared glass identity instead.
        .glassEffectTransition(.materialize)
        .animation(reduceMotion ? nil : .default, value: symbol)
    }

    private var lensTitle: String { String(localized: "Lens") }
    private var rideTitle: String { String(localized: "Ride") }

    /// Lens and Ride as one glass shape of two text capsules.
    private func views(lens: Bool, ride: Bool) -> some View {
        HStack(spacing: 2) {
            if lens {
                viewButton(lensTitle, spoken: String(localized: "Physics Lens"), isOn: model.lensOn) {
                    model.setLens(!model.lensOn)
                }
            }
            if ride {
                viewButton(rideTitle, spoken: String(localized: "Ride camera"), isOn: model.rideOn) {
                    model.setRide(!model.rideOn)
                }
            }
        }
    }

    private func viewButton(_ title: String, spoken: String, isOn: Bool,
                            action: @escaping @MainActor () -> Void) -> some View {
        Button(action: action) {
            capsuleLabel(title)
                // On is the Lens key in miniature under the word; the weight never changes, so the joined glass holds
                // still. Always laid out (opacity only), so turning it on moves nothing.
                .overlay(alignment: .bottom) {
                    HStack(spacing: 0) {
                        Rectangle().fill(palette.slide)
                        Rectangle().fill(palette.accent)
                    }
                    .frame(height: 3)
                    .clipShape(Capsule())
                    .padding(.horizontal, 14)
                    .padding(.bottom, 7)
                    .opacity(isOn ? 1 : 0)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .capsule)
        .glassEffectUnion(id: "views", namespace: localGlass)
        // Materializes in and out; not the primary action's way, which morphs into the aiming panel by its shared glass
        // identity instead.
        .glassEffectTransition(.materialize)
        .accessibilityLabel(spoken)
        .accessibilityValue(isOn ? String(localized: "On") : String(localized: "Off"))
        .accessibilityAddTraits(isOn ? [.isToggle, .isSelected] : .isToggle)
    }

    /// A worded capsule's label: 44 high, the word plus 14 a side.
    private func capsuleLabel(_ title: String) -> some View {
        Text(verbatim: title)
            .font(Theme.phoneControl)
            .lineLimit(1)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
    }

    /// The primary action's label: 44 high, its word plus 16 a side, dark on white.
    private func primaryLabel(_ title: String) -> some View {
        Text(verbatim: title)
            .font(Theme.phoneControl)
            .lineLimit(1)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
    }

    private func primaryButton(_ a: PhonePrimaryAction) -> some View {
        Button { a.action() } label: {
            primaryLabel(a.title)
                .fixedSize()
                .foregroundStyle(palette.ground)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        // The only tinted control on screen: white, because the accent is cyan and cyan means rolling (Part 3).
        .glassEffect(.regular.tint(.white).interactive(), in: .capsule)
        .glassEffectID(PhoneGlassID.primaryAction, in: sharedGlass ?? localGlass)
        .accessibilityHint(Text(verbatim: a.hint ?? ""))
    }
}
