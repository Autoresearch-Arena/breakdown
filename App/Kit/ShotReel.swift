// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 3, part C review: "Last shot" is now the kit's
//          SecondaryButton (label style, the kit's device height) instead of a hand-drawn copy of it.)
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 9's leftover note: the current beat's tick is
//          marked, so the reel, the notebook's lit row and the figure beside the ball all point at one moment. The tick
//          of pacePlan.beats[currentBeatIndex()] grows taller and wider with a paper ring round its cap; on the phone
//          strip's look the tick of the current moment (currentMoment) grows the same way. The speed pill is drawn
//          inside SpeedPicker's menu label, so the whole pill opens the list. The API is unchanged.)
// PURPOSE: UI rethink package 3 (the component kit), part C: the shot reel, the one playback bar on every device
//          (plans/26-Nov-2026-design-language.md, "Playback bar"). In order: play, the track, the time in s, the speed
//          pill, Replay, then an optional accessory the caller places (the scrub row's What if). 52 points high on the
//          big screens and 44 on the phone (Theme.Size.playbackBar), growing with the reader's text. On the big screens
//          it is a panel (panel fill, hairline rule edge, medium corners); on the phone, where it floats over the table,
//          it is glass with the same corners.
//          The track (ShotReelTrack) is the old scrub bar's control with the new marks: the paced beats (the moments
//          the replay stops on, ShowpieceModel.pacePlan) and every pot are tall ticks in their meaning colour, each kind
//          with its own cap so a greyscale picture still tells them apart (contact a dot, cushion a flat bar, pocket a
//          triangle into the hole, friction a ring, the strike a bare line), and the minor events (every other recorded
//          event) are a faint density band, brighter where they bunch. It keeps everything the scrub bar did: a 44
//          point touch area, a drag anywhere, a thumb that grows under the pointer, a light haptic each time a drag
//          crosses a recorded event (silent with Vibration off), the what-if's parting diamond over the playhead, and
//          one adjustable VoiceOver element with Next impact, Previous impact and Where they part.
//          The track also has the upright phone strip's look (.phoneStrip: white rail, white knob, a white tick at
//          each explained moment), which ScrubBar(phoneStyle: true) still asks for until package 6 moves that strip
//          onto the reel.
//          While aiming the reel folds into a secondary "Last shot" capsule (LastShotReelButton; ShotReel's `folded`),
//          which callers can also place on its own.
//          Reads the model's clock, recording, captions and pace plan; writes only through ShowpieceModel.scrub(to:),
//          togglePlay, setRate and setAutoRate, replay(withLens:) and WhatIfFork.jumpToParting (the old pieces' calls).
// SRP/DRY check: Pass - built from the existing pieces in PlaybackControls.swift (PlayPauseButton, SpeedPicker,
//          ReplayButton, kept there because the Mac toolbar and the phone strip use them) and NumberStyle.time for the
//          time; the old ScrubBar and the old scrub row in PlaybackControls are now thin wrappers over this file, so the
//          track is drawn in one place. Colours from Palette (the caption accents), sizes from Theme.
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI

// MARK: The reel

/// Where the reel sits decides its surface: a panel in a side column or under the table, glass over the table.
enum ShotReelSurface: Sendable {
    /// Panel on the big screens and the fold's panel, glass on the phone.
    case automatic
    /// The house surface: panel fill, hairline rule edge, medium corners.
    case panel
    /// Floating over the 3D table: glass, medium corners.
    case glass
    /// No surface of its own (the caller's container draws one).
    case none
}

struct ShotReel<Accessory: View>: View {
    let model: ShowpieceModel
    /// The layout it sits in: the phone gets the 44 point bar, the others 52.
    var device: Theme.Device
    /// Play, the speed pill and Replay. Off on the Mac while its window toolbar carries those three.
    var transport: Bool
    var surface: ShotReelSurface
    /// While aiming: the reel shows only the "Last shot" capsule.
    var folded: Bool
    /// What "Last shot" does; nil replays the last shot with the Lens (the Replay button's call).
    var onLastShot: (() -> Void)?
    /// The slim row under an open shot panel: the height floor drops to the 44 point touch minimum.
    var slim: Bool
    /// Placed after Replay (the scrub row puts What if here).
    let accessory: Accessory

    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(model: ShowpieceModel, device: Theme.Device, transport: Bool = true, surface: ShotReelSurface = .automatic,
         folded: Bool = false, onLastShot: (() -> Void)? = nil, slim: Bool = false,
         @ViewBuilder accessory: () -> Accessory) {
        self.model = model
        self.device = device
        self.transport = transport
        self.surface = surface
        self.folded = folded
        self.onLastShot = onLastShot
        self.slim = slim
        self.accessory = accessory()
    }

    var body: some View {
        Group {
            if folded {
                LastShotReelButton(device: device) { lastShot() }
                    .transition(.opacity)
            } else {
                bar.transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : Theme.Motion.standard, value: folded)
    }

    private func lastShot() {
        if let onLastShot { onLastShot() } else { model.replay(withLens: true) }
    }

    private var bar: some View {
        HStack(spacing: Theme.Space.xs) {
            if transport {
                PlayPauseButton(model: model)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .foregroundStyle(palette.paper)
                    .frame(minWidth: Theme.Size.minHit, minHeight: Theme.Size.minHit)
                    .contentShape(Rectangle())
            }
            ShotReelTrack(model: model, device: device)
            // At the accessibility text sizes the track speaks the time itself and the row needs the room.
            if !typeSize.isAccessibilitySize {
                // The total only where the row is wide (the fold's panel and the phone show the elapsed time alone).
                ShotReelTime(model: model, showsTotal: device == .big)
            }
            if transport {
                speedPill
                ReplayButton(model: model)
                    // A word on the big screens; the phone's and the fold panel's rows have room for the symbol only
                    // (VoiceOver says Replay).
                    .labelStyle(ReelReplayLabelStyle(worded: device == .big && !typeSize.isAccessibilitySize))
                    .buttonStyle(.plain)
                    .foregroundStyle(palette.paper)
                    .frame(minWidth: Theme.Size.minHit, minHeight: Theme.Size.minHit)
                    .contentShape(Rectangle())
            }
            accessory
        }
        .padding(.horizontal, Theme.Space.xs)
        .frame(minHeight: slim ? Theme.Size.minHit : Theme.Size.playbackBar(device))
        .modifier(ReelSurface(surface: resolvedSurface))
    }

    /// The speed: a capsule pill with the inline figure ("Auto", "½×") that opens the list (SpeedPicker's menu form).
    /// The pill is drawn inside the menu's label (SpeedPicker's pill), so the whole capsule and its 44 point hit area
    /// open the list, not only the words.
    private var speedPill: some View {
        SpeedPicker(model: model, asMenu: true, pill: true)
            .buttonStyle(.plain)
            .fixedSize()
    }

    private var resolvedSurface: ShotReelSurface {
        guard surface == .automatic else { return surface }
        return device == .phone ? .glass : .panel
    }
}

extension ShotReel where Accessory == EmptyView {
    init(model: ShowpieceModel, device: Theme.Device, transport: Bool = true, surface: ShotReelSurface = .automatic,
         folded: Bool = false, onLastShot: (() -> Void)? = nil, slim: Bool = false) {
        self.init(model: model, device: device, transport: transport, surface: surface, folded: folded,
                  onLastShot: onLastShot, slim: slim) { EmptyView() }
    }
}

/// The reel's surface.
private struct ReelSurface: ViewModifier {
    let surface: ShotReelSurface
    @Environment(\.palette) private var palette

    func body(content: Content) -> some View {
        switch surface {
        case .panel, .automatic:
            content
                .background(palette.panel, in: Theme.Corner.cardShape)
                .overlay(Theme.Corner.cardShape.strokeBorder(palette.rule, lineWidth: Theme.Size.hairline))
        case .glass:
            content.glassEffect(.regular, in: Theme.Corner.cardShape)
        case .none:
            content
        }
    }
}

/// Replay with its word, or the symbol alone.
private struct ReelReplayLabelStyle: LabelStyle {
    let worded: Bool
    @ViewBuilder func makeBody(configuration: Configuration) -> some View {
        if worded {
            HStack(spacing: Theme.Space.xxs) {
                configuration.icon
                configuration.title.font(Theme.label)
            }
            .lineLimit(1)
            .fixedSize()
        } else {
            configuration.icon
        }
    }
}

// MARK: The time

/// The playhead's time in s, in the inline figure with its grey unit: "1.2 / 4.8 s" on the big screens, "1.2 s" on the
/// phone. One decimal (NumberStyle's scrub-bar precision). Hidden from VoiceOver: the track already speaks it.
struct ShotReelTime: View {
    let model: ShowpieceModel
    var showsTotal = true
    @Environment(\.palette) private var palette

    var body: some View {
        let now = NumberStyle.time(seconds: model.time, place: .scrubBar)
        let total = NumberStyle.time(seconds: model.duration, place: .scrubBar)
        HStack(alignment: .firstTextBaseline, spacing: Theme.Space.xxs) {
            Text(verbatim: showsTotal ? now.number + " / " + total.number : now.number)
                .font(Theme.inlineFigure)
                .foregroundStyle(palette.paper)
            Text(verbatim: now.unit)
                .font(Theme.inlineUnit)
                .foregroundStyle(palette.paper2)
        }
        .lineLimit(1)
        .fixedSize()
        .accessibilityHidden(true)
    }
}

// MARK: Last shot

/// The reel folded while aiming: the kit's secondary button (App/Kit/SecondaryButton.swift: panel fill, hairline rule
/// edge, paper words in the label style, capsule) reading "Last shot", at the secondary height for the device. Callers
/// can place it on their own.
struct LastShotReelButton: View {
    /// Sets the kit's device for the button (its height: 50 on the phone, 56 on the big screens).
    var device: Theme.Device = .big
    let action: () -> Void

    var body: some View {
        SecondaryButton(String(localized: "Last shot", comment: "The folded playback bar while aiming: watch the last shot again"),
                        systemImage: "play.rectangle") { action() }
            .kitDevice(device)
            .accessibilityHint(String(localized: "Plays the last shot again", comment: "Hint on the Last shot button"))
    }
}

// MARK: The track

/// The track's two looks.
enum ShotReelTrackLook: Sendable {
    /// The reel's: a sunken rail, a cyan played stretch, a paper thumb, the beat and pot ticks and the density band.
    case standard
    /// The upright phone strip's (PhoneStrip, until package 6 moves it onto the reel): white rail at 25 percent, white
    /// played stretch, white knob with a dark shadow, and a 2 point white tick at each explained moment.
    case phoneStrip
}

struct ShotReelTrack: View {
    let model: ShowpieceModel
    var device: Theme.Device = .big
    var look: ShotReelTrackLook = .standard
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovering = false
    @State private var dragging = false
    /// Counts recorded events crossed during a drag; the haptic fires whenever it changes.
    @State private var crossings = 0

    // Drawing sizes, points (not gaps): the rail, the thumb and the tick lengths, a little smaller on the phone.
    private var railHeight: CGFloat { device == .phone ? 4 : 6 }
    private var thumb: CGFloat { device == .phone ? 16 : 20 }
    private var tallTick: CGFloat { device == .phone ? 14 : 18 }
    private var bandHeight: CGFloat { railHeight + Theme.Space.xs }

    var body: some View {
        GeometryReader { geo in
            track(width: max(1, geo.size.width))
        }
        .frame(height: Theme.Size.minHit)
        // Vibration off silences the tick (GameSettings.hapticsOn); nil plays nothing.
        .sensoryFeedback(trigger: crossings) { _, _ in GameSettings.hapticsOn ? .impact(weight: .light) : nil }
        // VoiceOver: one adjustable element instead of a canvas it cannot read.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Playback position")
        .accessibilityValue(spokenValue)
        .accessibilityAdjustableAction { direction in
            let step = model.duration / 20
            switch direction {
            case .increment: model.scrub(to: model.time + step)
            case .decrement: model.scrub(to: model.time - step)
            @unknown default: break
            }
        }
        // The named actions in one list, so the what-if's conditional one sits beside the impact jumps.
        .accessibilityActions {
            Button("Next impact") { if let t = impact(after: model.time) { model.scrub(to: t) } }
            Button("Previous impact") { if let t = impact(before: model.time) { model.scrub(to: t) } }
            if partingTime != nil {
                Button(String(localized: "Where they part")) { model.whatIf.jumpToParting() }
            }
        }
    }

    /// Where the what-if's two futures part, while one shows (the fork's marker); nil otherwise.
    private var partingTime: Double? {
        guard model.whatIf.isShowing else { return nil }
        return model.whatIf.result?.fork.marker?.time
    }

    /// The band, the rail, the played stretch, the ticks and the thumb, with the drag on top.
    private func track(width w: CGFloat) -> some View {
        let d = max(model.duration, 0.001)
        let x: CGFloat = w * CGFloat(min(1, max(0, model.time / d)))
        let thumbScale: CGFloat = dragging ? 1.25 : (hovering ? 1.15 : 1)
        let thumbX: CGFloat = min(max(0, x - thumb / 2), w - thumb)
        let phone = look == .phoneStrip
        return ZStack(alignment: .leading) {
            if !phone { densityBand(duration: d) }
            Capsule().fill(phone ? Color.white.opacity(0.25) : palette.track).frame(height: railHeight)
            Capsule().fill(phone ? Color.white : palette.accent).frame(width: max(railHeight, x), height: railHeight)
            // The marks go over the played stretch too, so their small caps are not hidden once the playhead passes.
            if phone { momentTicks(duration: d) } else { beatTicks(duration: d) }
            Circle()
                .fill(phone ? Color.white : palette.paper)
                .frame(width: thumb, height: thumb)
                .shadow(color: Color.black.opacity(0.5), radius: Theme.Space.xxs)
                .scaleEffect(thumbScale)
                .animation(reduceMotion ? nil : .snappy(duration: 0.15), value: thumbScale)
                .offset(x: thumbX)
            // Over the playhead (0.7.6, bug 30): Where they part lands the playhead on the diamond, which must stay seen.
            partingMark(width: w, duration: d)
        }
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        #if os(macOS)
        .pointerStyle(dragging ? .grabActive : .grabIdle)
        #endif
        .gesture(drag(width: w, duration: d))
    }

    /// Dragging anywhere on the track moves the playhead there; each recorded event crossed ticks the haptic.
    private func drag(width w: CGFloat, duration d: Double) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                dragging = true
                let fraction = Double(min(max(0, g.location.x), w) / w)
                let target = fraction * d
                if impactsBetween(model.time, target) { crossings += 1 }
                model.scrub(to: target)
            }
            .onEnded { _ in dragging = false }
    }

    // MARK: Marks

    /// Which timeline events are the paced beats (a caption's id is its event's index), so the band leaves them out.
    private var beatEventIndices: Set<Int> { Set(model.pacePlan.beats.map { $0.caption.id }) }

    /// The minor events as a faint band: a thin paper stroke per event, faint alone and brighter where they bunch
    /// (each stroke adds its opacity), so a busy stretch of the shot reads as a denser smudge on the rail.
    private func densityBand(duration d: Double) -> some View {
        let beats = beatEventIndices
        let events = model.timeline.events
        let band = bandHeight
        let paper = palette.paper
        return Canvas { ctx, size in
            let y = (size.height - band) / 2
            for (i, e) in events.enumerated() {
                if beats.contains(i) || e.kind == .phaseTransition || e.kind == .pocket { continue }
                let x = size.width * CGFloat(min(1, max(0, e.time / d)))
                ctx.fill(Path(CGRect(x: x - 1.5, y: y, width: 3, height: band)), with: .color(paper.opacity(0.10)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The cap on a tall tick, so each kind reads in greyscale too (the everyone plan's Part A4 rule, kept).
    private enum TickCap { case none, dot, flat, intoHole, ring }

    private struct Tick {
        let time: Double; let color: Color; let cap: TickCap; let headline: Bool
        /// The moment the replay is on now (ShowpieceModel.currentBeatIndex): drawn larger, with a paper ring.
        var current = false
    }

    /// The paced beats in their caption's meaning colour and every pot in the pocket gold: tall ticks with their cap.
    /// The current beat (the same one the notebook lights and the chip on the table shows) is marked as current.
    private var ticks: [Tick] {
        var out: [Tick] = []
        var beatTimes: [Double] = []
        let currentIndex = model.currentBeatIndex()
        for (index, beat) in model.pacePlan.beats.enumerated() {
            let cap: TickCap
            switch beat.caption.accent {
            case .strike: cap = .none
            case .impact: cap = .dot
            case .cushion: cap = .flat
            case .pocket: cap = .intoHole
            case .friction: cap = .ring
            }
            out.append(Tick(time: beat.time, color: palette.color(for: beat.caption.accent), cap: cap,
                            headline: beat.headline, current: index == currentIndex))
            beatTimes.append(beat.time)
        }
        // Every pot, unless a beat already marks that very moment.
        for e in model.timeline.events where e.kind == .pocket {
            if beatTimes.contains(where: { abs($0 - e.time) < 0.001 }) { continue }
            out.append(Tick(time: e.time, color: palette.pocket, cap: .intoHole, headline: false))
        }
        return out
    }

    private func beatTicks(duration d: Double) -> some View {
        // Read on the main actor here, not inside the Canvas's drawing closure (the model is main-actor).
        let ticks = self.ticks
        let tall = tallTick
        let edge = palette.ground
        let ring = palette.paper
        return Canvas { ctx, size in
            let midY = size.height / 2
            // The current beat last, so its larger tick and ring sit over any neighbour at nearly the same time.
            for t in ticks.sorted(by: { !$0.current && $1.current }) {
                // The current tick: 6 points taller (3 above, 3 below) and a point wider than its kind's tick.
                let height: CGFloat = t.current ? tall + 6 : tall
                let top = midY - height / 2
                let x = size.width * CGFloat(min(1, max(0, t.time / d)))
                let width: CGFloat = (t.headline ? 3 : 2) + (t.current ? 1 : 0)
                let line = CGRect(x: x - width / 2, y: top, width: width, height: height)
                // A dark edge first, so the tick reads on the cyan played stretch and on glass alike.
                ctx.fill(Path(line.insetBy(dx: -0.5, dy: -0.5)), with: .color(edge.opacity(0.5)))
                ctx.fill(Path(line), with: .color(t.color))
                let shading = GraphicsContext.Shading.color(t.color)
                switch t.cap {
                case .none:
                    break
                case .dot:
                    ctx.fill(Path(ellipseIn: CGRect(x: x - 3, y: top - 3, width: 6, height: 6)), with: shading)
                case .flat:
                    ctx.fill(Path(CGRect(x: x - 4, y: top - 1, width: 8, height: 2)), with: shading)
                case .intoHole:
                    var tri = Path()
                    tri.move(to: CGPoint(x: x - 4, y: top - 6))
                    tri.addLine(to: CGPoint(x: x + 4, y: top - 6))
                    tri.addLine(to: CGPoint(x: x, y: top))
                    tri.closeSubpath()
                    ctx.fill(tri, with: shading)
                case .ring:
                    ctx.stroke(Path(ellipseIn: CGRect(x: x - 3.5, y: top - 4, width: 7, height: 7)), with: shading,
                               lineWidth: 1.25)
                }
                if t.current {
                    // A paper ring round the cap's place, over a dark edge so it reads on glass and on the cyan stretch.
                    let ringRect = CGRect(x: x - 6, y: top - 9, width: 12, height: 12)
                    ctx.stroke(Path(ellipseIn: ringRect), with: .color(edge.opacity(0.6)), lineWidth: 3)
                    ctx.stroke(Path(ellipseIn: ringRect), with: .color(ring), lineWidth: 1.5)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The phone strip's ticks: one 2 point mark at each explained moment (each caption's time), white with a dark
    /// edge so it reads on the played and the unplayed rail alike.
    private func momentTicks(duration d: Double) -> some View {
        let captions = model.captions
        // The moment the replay is on (the notebook's lit row), read here on the main actor: its tick grows.
        let currentID = model.currentMoment()?.id
        return Canvas { ctx, size in
            for c in captions {
                let current = c.id == currentID
                let h: CGFloat = current ? 18 : 12
                let w: CGFloat = current ? 3 : 2
                let x = size.width * CGFloat(min(1, max(0, c.time / d)))
                let rect = CGRect(x: x - w / 2, y: (size.height - h) / 2, width: w, height: h)
                ctx.fill(Path(rect.insetBy(dx: -0.5, dy: -0.5)), with: .color(.black.opacity(0.45)))
                ctx.fill(Path(rect), with: .color(.white))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The what-if's diamond at the parting time, in the what-if violet with a dark edge (0.7.5).
    @ViewBuilder
    private func partingMark(width w: CGFloat, duration d: Double) -> some View {
        if let t = partingTime {
            let size: CGFloat = 10
            let x = w * CGFloat(min(1, max(0, t / d)))
            Rectangle()
                .fill(palette.whatIf)
                .frame(width: size, height: size)
                .overlay(Rectangle().stroke(.black.opacity(0.55), lineWidth: 1))
                .rotationEffect(.degrees(45))
                .offset(x: min(max(0, x - size / 2), w - size))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    // MARK: Event lookups (also used by VoiceOver)

    private var impactTimes: [Double] {
        model.timeline.events.compactMap { $0.kind == .phaseTransition ? nil : $0.time }
    }

    private func impactsBetween(_ a: Double, _ b: Double) -> Bool {
        let lo = min(a, b), hi = max(a, b)
        return impactTimes.contains { $0 > lo && $0 <= hi }
    }

    private func impact(after t: Double) -> Double? { impactTimes.first { $0 > t + 0.001 } }
    private func impact(before t: Double) -> Double? { impactTimes.last { $0 < t - 0.001 } }

    private var spokenValue: String {
        String(localized: "\(String(format: "%.1f", locale: AppLocale.numbers, model.time)) of \(String(format: "%.1f", locale: AppLocale.numbers, model.duration)) seconds")
    }
}

// MARK: Previews

#Preview("Shot reel, big") {
    ShotReel(model: ShowpieceModel(), device: .big)
        .padding(Theme.Space.lg)
        .frame(width: Theme.Size.sideColumn)
        .background(Palette(contrast: .standard).ground)
}

#Preview("Shot reel, phone") {
    ShotReel(model: ShowpieceModel(), device: .phone)
        .padding(Theme.Space.md)
        .frame(width: 375)
        .background(Palette(contrast: .standard).ground)
}

#Preview("Shot reel, no transport (Mac toolbar)") {
    ShotReel(model: ShowpieceModel(), device: .big, transport: false)
        .padding(Theme.Space.lg)
        .frame(width: 520)
        .background(Palette(contrast: .standard).ground)
}

#Preview("Shot reel folded: Last shot") {
    ShotReel(model: ShowpieceModel(), device: .big, folded: true)
        .padding(Theme.Space.lg)
        .background(Palette(contrast: .standard).ground)
}

#Preview("Track, phone strip look") {
    ShotReelTrack(model: ShowpieceModel(), device: .phone, look: .phoneStrip)
        .padding(Theme.Space.md)
        .frame(width: 320)
        .background(Color.black)
}
