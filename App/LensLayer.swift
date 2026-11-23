// Author: Claude Sonnet 5.5 High
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 bullet time, plans/23-Nov-2026-bullet-time-plan.md: the
//          contact drawing gets a second owner, bullet time's frozen hit (bulletEvent), and moves under its own parent
//          (heldRoot) outside root so it can show with the Lens off; see CONTACT GEOMETRY. The Lens's own picture is
//          unchanged.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream drawings, plans/22-Nov-2026-v076-phone-plan.md and bug
//          list #15, #16, #17, #65: the Lens marks at a readable size. The layer keeps a weak link to the table camera
//          (`camera`, set once by TableScene) and asks it, at each mark's place, how many screen points a metre covers;
//          LensMarkFloor (LensContactGeometry.swift) turns that into the scale each mark needs so no line is drawn under
//          2 points wide and no arrowhead under 8. Velocity arrowheads, impact rings, jam crosses, the throw lines
//          (lengthened so a one-degree throw opens 6 points at the far end, the angle never exaggerated), the contact
//          drawing (posed every frame now, so it keeps its floor while the view glides in on the moment) and both spin
//          marks all follow it. The slip belt also tips toward a camera looking nearly straight down, so from overhead
//          it reads as a turning wheel instead of an edge-on bar. The dot under a flying ball became a ring on its ground
//          spot, always a few points wider than the drawn ball and growing with height (#17). The marks draw with a
//          wider-cored picture (LensTextures.markLine). With no camera (the scrub check, unit tests) every size is the
//          table size it was, so the fingerprint is unchanged; with one, the sizes follow the camera, which itself
//          follows the clock, so scrubbing still shows the same picture for the same time.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 rules-lens review: the castle ring's transparency is built
//          with the material's own opacity value, which the first version spelled as a scalar parameter that does not
//          compile.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 rules-lens, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          item 9 and R-A: the hit diagram no longer vanishes when a held hit ends - it keeps its pose and fades out over
//          the same quarter second it fades in, and a new held hit during that fade carries on from the opacity on
//          screen; it is still cut at once when the Lens leaves, the recording changes or the hold is not a hit (see
//          CONTACT GEOMETRY). The five-pin castle gets a faint paper-coloured ring round its pins so it reads at a glance
//          on a phone (the pin marks were already 2.6 cm across, over the 1.4 cm asked for, so their size is
//          unchanged), and bar billiards' pegs are no longer drawn with a red one: that table has no red peg.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4: the Lens draws bumper-pool posts and five-pin pins, so a held
//          moment off a bumper or into the pins shows what it is about.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 foundation: hooks for signature beats, the held Lens beat, the shared computer level and the highlight offer; plans/22-Nov-2026-v074-glow-up-plan.md)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 lens-drawing, feature G2 "see the hit": while a guided replay
//          holds on a ball-to-ball hit (heldEvent), the Lens draws its contact geometry on the cloth: the line of
//          centres dashed through both balls, the tangent at the contact with a finer dash (dotted with Differentiate
//          Without Colour on), and the momentum triangle (the striking ball's speed in, white; the struck ball's and
//          the striking ball's speeds out, cyan, head to tail), plus a small square mark when the two outgoing paths are
//          square. The geometry comes from ContactGeometry (LensContactGeometry.swift). The parts are built once and
//          reused, posed when the held event changes and faded in over a quarter second of real time; with heldEvent
//          nil they are all off, so every unheld frame and the scrub check (which never sets heldEvent) are unchanged.
//          See CONTACT GEOMETRY below.)
// Date: 13-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (the colour legend left the 3D scene: it is a SwiftUI glass chip in
//          the title row now (LensLegendChip in CaptionViews), which follows Dynamic Type and VoiceOver and costs the
//          table no room).
// Edited: Claude Opus 5.5 High, 21-November-2026 (spin markers: every moving or spinning ball in the Lens now carries
//          a magenta belt showing the part of its spin that is NOT natural rolling (draw, follow, the slip that makes a
//          ball slide), with an arrowhead on top showing which way the top of the ball turns, and a flat blue ring on
//          the cloth with an arrow for side spin (english). Both fade with the amount and are read from the recorded
//          timeline at the clock, so scrubbing shows the same markers either way.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (AimPreview also carries what the 3D cue needs: whether it may show,
//          power, elevation, tip offsets and the bridge; the Lens does not read them).
// PURPOSE: The cold Physics Lens layer. Owns the grid under the Lens, the glowing trails coloured by motion phase,
//          the impact rings, the velocity arrows and the player's aim line, plus their materials
//          and their per-frame logic. Anything about how the Lens LOOKS or when its parts appear belongs here.
//          Does NOT belong here: the warm table and balls (TableBuilder.swift), the camera (TableCamera.swift), the
//          pictures themselves (LensTextures.swift, BallTextures.gridTexture), or moving the balls (TableScene.apply).
//          The coordinator hands this layer the clock, the melt, the timeline, the frame and which balls are visible;
//          the layer never reads or changes the model.
//
//          HOW THE TRAILS WORK (package 2 of the glow-up plan, 13-Nov-2026). Every path is built ONCE per recorded shot
//          into two meshes (one for sliding, one for rolling) as thin ribbons. Each vertex carries the TIME the ball
//          was there as a texture coordinate. The material's picture is a strip along age: bright and white-hot at the
//          head, easing over a couple of seconds to a faint trace, and transparent for any time still in the future.
//          Each frame the only thing that changes is a texture offset equal to a function of the playback clock, so
//          the head of every trail sits exactly at the ball, the fade with age is exact, and scrubbing backwards or
//          forwards shows the identical picture for the identical time. No trail piece is ever switched on or off.
//          Rings use a fixed span of clock time (not of wall time), so they too depend on the clock alone.
//
//          GLOW. RealityKit in Xcode 27 has a bloom component (BloomComponent, BloomOptionsComponent), but it is
//          iOS 27 / macOS 27 only and this app deploys to 26. So the glow is built in the pictures first (a thin bright
//          core inside a wider soft halo, on every device), and the system bloom is added on top only where it exists,
//          with the halo turned down so the two do not stack into mush. Launch with -noBloom to see the fallback.
//          FADE (package 4, 0.4.0): the newest second of a path is full strength, then brightness drops steeply (a power
//          curve under a smoothstep) to a faint floor by four seconds of age, and the line also narrows with age (the picture
//          is thinner for older time), so a late-break frame shows bold fresh lines over dim hairlines instead of a scribble.
//          Both curves are functions of age alone, baked into the one picture, so the clock-only exactness is untouched.
//          Draw order is fixed with sort groups: grid, then trails, then rings, then spin markers, then arrows.
//
//          SPIN MARKERS (21-Nov-2026). Rolling spin is not interesting on its own: it just follows the velocity. What
//          makes draw, follow and swerve happen is the DIFFERENCE between the ball's spin and natural roll, so that is
//          what the magenta belt shows (the sliding colour, because that difference is exactly what makes a ball
//          slide). The vertical part of the spin, english, gets its own flat ring on the cloth in the cushion blue,
//          since cushions are where side spin shows itself. Each ball owns one belt and one ring built once; per frame only their pose and
//          opacity change.
//
//          CONTACT GEOMETRY (0.7.4). The one part of the Lens NOT driven by the clock alone: it appears only while the
//          model holds a guided beat on a ball-to-ball hit (TableScene hands the held event over each frame), and it fades
//          in over real time, because the clock stands still during a hold. Since 0.7.5 it also fades out over the same
//          real time when the hold ends with the Lens still in (it is cut at once when the Lens leaves, the recording is
//          rebuilt, or the hold moves to a moment that is not a hit). It is therefore left out of fingerprint();
//          LensScrubCheck leaves heldEvent nil, so the parts stay hidden there and the check is exactly as before.
//          The triangle is drawn at one scale for all three arrows (0.12 m per m/s, smaller if the longest would pass
//          0.35 m), so it still closes; arrows clamped one by one would not. When the struck ball was already moving
//          only the two lines are drawn, and when the throw lines already show this hit's line of centres (throwFacts)
//          the contact's own line of centres is left out, so it is never drawn twice.
//          Since 0.7.7 the drawing has two owners and its own parent, heldRoot, outside root: the guided hold
//          (heldEvent, Lens in, multiplied by the melt by hand as root's opacity used to) and bullet time (bulletEvent,
//          any melt, lifted to the balls' centres so it hangs between them, the line of centres always drawn since there
//          are no throw lines with the Lens off). heldRoot carries its own bloom; fingerprint() is unchanged.
// Edited: Claude Opus 5.5 High, 21-November-2026 (the Lens grid is built by buildGrid, which TableScene calls again
//          when the table changes; it also marks the holes in another table's bed).
// Edited: Claude Opus 5.5 High, 21-November-2026 (accessibility plan, package 4: with Differentiate Without Colour on,
//          a sliding path is built as dashes and a rolling path stays solid, so the two phases differ in shape, not
//          only in magenta against cyan; the trails are rebuilt when the setting changes. The dashes are cut from the
//          geometry at build time, so the clock-only exactness of the picture is untouched. Package 5: the
//          generation-two events now leave a visible mark like the others: a red double ring where the cue MISCUED (the
//          one place a sound alone would carry it), a pocket-coloured ring where a ball skipped over a hole, and an
//          impact ring where a jam was brought to rest.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (version 0.7.0, plans/21-Nov-2026-bugs-after-0-6-6-plan.md items 22,
//          24 and 28: a ball in the air leaves its own trail, white and dashed, drawn at the ball's own height, with a
//          soft dot on the cloth under it while it flies and a white ring where it lands; its velocity arrow rides at
//          its height instead of on the cloth. A skip over a hole is a BROKEN ring (dashed arcs) so its shape, not
//          only its colour, says "did not drop"; a jam brought to rest gets a cross on each wedged ball that holds
//          still and fades instead of expanding like an impact. Throw: at a ball-to-ball contact where friction sent
//          the struck ball half a degree or more off the line of centres (CaptionEngine.throwFacts, the same rule the
//          caption uses), the line of centres is drawn dashed beside the real departure, from the struck ball, for a
//          short span of clock. Every new mark is a function of the clock alone and is in the fingerprint.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 equipment hook, plan items 57 and 23: AimPreview carries the
//          picked cue and the bridge's length for CueRig; two appended fields with defaults.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.2: sliding trails and the slip belt are magenta
//          (Theme.slideRGB, renamed from amberRGB); the grid's edge pockets are drawn only when the table has them
//          (pocketsEnabled), and BallTextures.gridImage now draws every pocket and bed hole as a real hole.)
// SRP/DRY check: Pass - Lens drawing only; coordinates come from TableFrame, colours from Theme, pictures from LensTextures.
//          The throw rule is CaptionEngine's (one rule for the words and the drawing).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import Metal
import RealityKit
import simd

/// Where the player's break is aimed, drawn as a guide line on the felt.
struct AimPreview {
    var from: Vec2
    var direction: Vec2
    var length: Double
    var always: Bool
    // For the 3D cue (CueRig); the Lens itself ignores these. Appended with defaults so existing callers still compile.
    /// True when the cue may be drawn: the shot on screen has played out and the cue ball is on the table. The aim
    /// line above keeps showing without it.
    var showsCue = false
    /// Power 0 to 1: how far the cue is drawn back.
    var powerFraction = 0.0
    /// Sine of the cue's raise above the table (only the massé and the jump use it).
    var elevation = 0.0
    /// Tip contact offsets on the cue ball, metres: up is follow, right (as the player sees it) is side spin.
    var tipUp = 0.0
    var tipSide = 0.0
    /// The cue rests on the mechanical bridge.
    var usesBridge = false
    /// Which cue CueRig draws: the one the game picked for the shot (model.cueChoice.kind; plan item 57, the
    /// equipment stream's hook, appended with a default like the rest).
    var cue: CueKind = .house
    /// Metres from the cue ball's centre back to the bridge hand (model.strokeBridgeLength): CueRig stops the drawn
    /// pull-back in front of it (plan item 23). Nil: the automatic bridge.
    var bridgeLength: Double? = nil
}

@MainActor
final class LensLayer {
    /// The timeline event of the guided beat being held, set by TableScene each frame; nil when nothing is held;
    /// LensScrubCheck leaves it nil, so the scrub check stays a pure function of the clock (0.7.4 foundation).
    var heldEvent: Int?
    // 0.7.7 bullet-time: the contact drawing's second owner.
    /// The ball-to-ball event bullet time is frozen on (0.7.7), set by TableScene each frame while the freeze's drawing
    /// shows; nil otherwise. Drawn with any melt (the Lens is off during a freeze), lifted to the balls' centres.
    var bulletEvent: Int?
    /// The height the bullet drawing is lifted to, metres above the cloth: the balls' centres (TableScene sets it).
    var bulletLift: Float = 0
    /// True while the contact drawing on screen was posed for bulletEvent (set every frame its owner branch runs, kept
    /// through its fade-out, cleared by cutContact), so it is lifted and not multiplied by the melt.
    private var contactIsBullet = false
    /// The table camera (0.7.6 stream drawings), handed over once by TableScene, read every frame for how many screen
    /// points a metre covers at a mark (see LensMarkFloor). Weak: TableScene owns it. Nil for a layer made on its own
    /// (unit tests), where every mark keeps its table size; the in-app scrub self-test (-lensSelfTest) runs inside one
    /// frame, while the camera stands still, so its fingerprints still compare like with like. TableScene applies the
    /// Lens before it moves the camera each frame, so the figure is the last frame's: a frame late during a glide,
    /// exact during a hold.
    weak var camera: TableCamera?

    /// Screen points per metre at world point `p` from the camera, or nil when there is no camera or the point is
    /// behind it (LensMarkFloor.usable). Cheap: a dot product and a divide in TableCamera.
    private func pointsPerMetre(at p: SIMD3<Float>) -> Float? {
        guard let camera else { return nil }
        return LensMarkFloor.usable(camera.pointsPerMetre(at: p))
    }

    // MARK: Tunables

    /// Seconds of clock the newest part of a path stays at full brightness.
    static let trailHold = 1.0
    /// Age at which a path has faded to its faint trace, and how bright that trace is (0 to 1). Package 4 (0.4.0) made
    /// the hold shorter and the floor lower: by the end of a break the old 0.20 floor on thick lines was still a dense
    /// scribble; now only the last second or so is bright and everything older is a faint hairline (see `trailWidth`).
    static let trailFadeEnd = 4.0
    static let trailFloor = 0.11
    /// How thin the oldest path gets, as a share of its fresh width (the picture narrows the line as it ages).
    static let trailOldWidth = 0.42
    /// Clock seconds an impact ring takes to expand and fade. Fixed in clock time so it depends on the clock alone.
    static let ringSpan = 0.4
    /// Spin marker fades, as speeds in m/s at the ball's surface (spin times radius), so they read the same on any
    /// table size. Below `lo` a marker is hidden; it reaches its base strength by `mid` and full brightness by `full`.
    static let slipFade = (lo: 0.04, mid: 0.25, full: 1.2)
    static let sideFade = (lo: 0.02, mid: 0.12, full: 0.6)
    /// Clock seconds over which a pocketed ball's markers fade out (the ball itself sinks away in about 0.22 s).
    static let spinPocketFade = 0.2
    /// Dashed sliding trails (Differentiate Without Colour): length of each dash and of each gap, metres along the
    /// path. A fresh line is up to about 5 cm wide (two half-widths of `half(speed)` at break speed), so a 6 cm dash
    /// is longer than the line is wide and reads as a dash, and a 4 cm gap is wide enough to see at a slow roll.
    static let dashLength = 0.06
    static let dashGap = 0.04
    /// Ring strength (the impulse scale used for impact rings) for events that record no impulse of their own: a
    /// miscue and a rim skip get a full-size ring because each is a single, decisive moment worth seeing.
    static let markerStrength: Float = 1.0
    /// Miscue ring colour: the warm red that ends the power bar (AimGauges), the app's one "too far" colour.
    static let miscueRGB: (Double, Double, Double) = (1.0, 0.30, 0.25)
    /// An airborne trail rides this far above the ball's lowest point: between the sliding (1.6 mm) and rolling
    /// (4.6 mm) lifts, so where a flight starts and ends on the cloth it joins the cloth trails without fighting them
    /// for depth, and in the air it climbs with the ball.
    static let airborneLift: Float = 0.0031
    /// Airborne dashes: shorter than the sliding ones (6 cm on, 4 cm off) because a jump's whole flight is often only
    /// a few tens of centimetres; 3 cm on and 2 cm off still gives several dashes over the shortest hop.
    static let airDash = 0.03
    static let airGap = 0.02
    /// The jump mark under a flying ball: shown once the ball is a millimetre up (the solver's own minimumHop). Since
    /// 0.7.6 (#17) it is a ring on the ball's ground spot, not a ball-wide dot: from the Lens's straight-down view the
    /// ball covered the dot completely. The ring's inner edge sits outside the drawn ball and it widens as the ball
    /// climbs (jumpRingBase plus jumpRingGrowth times the height in ball diameters, at least LensMarkFloor's points).
    static let dotMinHeight = 0.001
    /// The jump ring's inner edge as a share of its outer radius (the annulus it is drawn with), and its outer radius
    /// in drawn-ball radii on the ground and how much that grows by two radii up, when no camera figure is known.
    static let jumpRingInner: Float = 0.75
    static let jumpRingBase: Float = 1.4
    static let jumpRingGrowth: Float = 0.6
    /// In the Lens the balls are drawn this much larger at full melt (TableScene.apply's lensScale, look plan package 5);
    /// the jump ring clears the ball as drawn, not as recorded.
    static let lensBallGrowth: Float = 0.08
    /// The velocity arrow's head length and shaft width, metres (buildStatic), for their screen floors.
    static let arrowHeadLength: Float = 0.034
    static let arrowShaftWidth: Float = 0.042
    /// The impact ring's inner edge as a share of its radius, and the jam cross's bar half-width as a share of its arm:
    /// the band a ring or cross is drawn with is what LensMarkFloor.line holds above 2 points.
    static let ringInner: Float = 0.62
    static let crossHalfWidth: Float = 0.16
    /// Throw lines' half-width, metres (their meshes are built with it, and the floor reads it).
    static let throwLineHalfWidth: Float = 0.0035
    /// How far the slip belt tips toward a camera looking almost straight down (#65): enough that from overhead its
    /// circle shows as an open ellipse, so the eye reads a wheel turning one way rather than a bar across the ball.
    static let beltTilt: Float = 50 * .pi / 180
    /// The slip belt's and side ring's arc meshes (buildStatic): strip half-widths and arrowhead lengths as shares of
    /// the arc's radius, for their floors.
    static let beltHalfWidth: Float = 0.13
    static let beltHeadLength: Float = 0.46
    static let sideHalfWidth: Float = 0.09
    static let sideHeadLength: Float = 0.40
    /// Clock seconds a jam's cross stays up: it marks balls brought to REST, so it holds still for longer than an
    /// impact ring's flash (two and a half ring spans, an even second) and then fades.
    static let jamMarkSpan = 1.0
    /// Throw marks: how long they stay (clock seconds; a guided hold stops the clock on the hit, so they stay for the
    /// whole hold) and how long they are drawn. Half a metre opens a one-degree throw to about 9 mm at the far end, a
    /// third of a ball's width, which reads at the normal camera distance.
    static let throwMarkSpan = 1.5
    static let throwLineLength: Float = 0.5
    /// Contact geometry (0.7.4): the line of centres and the tangent reach this many ball diameters either side of the
    /// contact (two: through both balls and a ball's width beyond each).
    static let contactLineReach: Float = 2
    /// Momentum triangle scale, metres of arrow per m/s, and the longest any arrow may be drawn (the whole triangle is
    /// scaled down together to keep the longest inside it, so it still closes).
    static let contactArrowScale = 0.12
    static let contactArrowMax = 0.35
    /// Real seconds the contact drawing takes to fade in when a held hit begins, and (0.7.5) to fade out when the hold
    /// ends with the Lens still in.
    static let contactFadeIn = 0.25
    /// The five-pin castle ring (0.7.5): metres outside the outer pin marks, its width in metres, and its strength
    /// (opacity), faint so it marks the castle without competing with the paths.
    static let castleRingGap = 0.012
    static let castleRingWidth: Float = 0.003
    static let castleRingStrength: Float = 0.35
    /// Arrowhead length of the triangle's arrows, metres (shortened on a very short arrow).
    static let contactHeadLength: Float = 0.022
    /// The right-angle mark's side, as a share of the ball radius.
    static let contactMarkSize: Float = 0.7
    /// Half-widths of the contact drawing's parts (buildContact), metres, or for the right-angle mark a share of its
    /// side; the screen floors (0.7.6) read them. The tangent's dashes are the thinnest line.
    static let contactCentresHalf: Float = 0.003
    static let contactTangentHalf: Float = 0.0025
    static let contactShaftHalf: Float = 0.004
    static let contactMarkHalf: Float = 0.09

    /// Smooth 0-to-1 ramp between `a` and `b`.
    private static func smoothstep(_ a: Double, _ b: Double, _ x: Double) -> Double {
        let s = min(1, max(0, (x - a) / (b - a)))
        return s * s * (3 - 2 * s)
    }

    /// Opacity of a spin marker for a surface speed `x`: zero below `lo`, eased in to a base of 0.5 by `mid`, then
    /// growing to full by `full`, so a stronger spin glows brighter and nothing ever pops in or out.
    static func spinOpacity(_ x: Double, _ f: (lo: Double, mid: Double, full: Double)) -> Double {
        smoothstep(f.lo, f.mid, x) * (0.5 + 0.5 * smoothstep(f.mid, f.full, x))
    }

    /// Fraction 0 (fresh) to 1 (fully faded) of the way through the fade at `age` seconds behind the ball, eased at
    /// both ends so there is no visible kink where the hold ends or the trace begins.
    static func trailFade(age: Double) -> Double {
        if age <= trailHold { return 0 }
        if age >= trailFadeEnd { return 1 }
        let s = (age - trailHold) / (trailFadeEnd - trailHold)
        return s * s * (3 - 2 * s)
    }

    /// Brightness of a trail at `age` seconds behind the ball: 1 while fresh, dropping steeply (the power makes the
    /// first part of the fade quick, so path older than about two seconds is already dim), never below `trailFloor`.
    /// The trail picture is baked from this one function, so this is the single definition of the fade.
    static func trailBrightness(age: Double) -> Double {
        let f = trailFade(age: age)
        return trailFloor + (1 - trailFloor) * pow(1 - f, 1.6)
    }

    /// Width of a trail at `age`: 1 while fresh, narrowing to `trailOldWidth`. Baked into the picture's cross-section.
    static func trailWidth(age: Double) -> Double {
        1 - (1 - trailOldWidth) * trailFade(age: age)
    }

    // MARK: Parts

    /// Parent of every Lens entity; fades as a whole with the melt value.
    let root = Entity()
    // 0.7.7 bullet-time: the contact drawing moved out from under root.
    /// The contact drawing's parent (0.7.7), outside root so the drawing can show with the Lens off (bullet time);
    /// TableScene adds it to the scene beside root. With the Lens it is multiplied by the melt by hand
    /// (setContactOpacity), exactly as root's opacity multiplied it before. It carries its own bloom.
    let heldRoot = Entity()
    private let trailRoot = Entity()
    private let ringRoot = Entity()
    private let arrowRoot = Entity()
    private let gridEntity = ModelEntity()
    private let aimLine = ModelEntity()
    private var arrows: [(root: Entity, shaft: Entity, head: Entity, glow: Entity)] = []
    /// One timed mark on the table: an impact ring (grows and fades) or a held mark (a jam's cross, a throw line:
    /// stays its size, holds, then fades). All are driven by the clock alone.
    private struct Flash {
        let entity: ModelEntity
        let time: Double
        let span: Double
        let radius: Float
        let grows: Bool
        /// Peak opacity of a held mark.
        let peak: Float
        /// 0.7.6 screen floor: the narrowest band of this mark at its table size, metres (a ring's band, a cross's bar).
        /// A miscue's two rings both carry the inner ring's band, so they grow by the same factor and stay one inside
        /// the other. Zero: no floor.
        var band: Float = 0
        /// A throw line's throw, degrees (nil for every other mark): its length follows LensMarkFloor.throwLineLength.
        var throwDegrees: Double? = nil
    }
    private var rings: [Flash] = []
    private let ringMesh = LensLayer.annulus(segments: 72, inner: LensLayer.ringInner)
    /// A skip over a hole: the same ring cut into twelve arcs with gaps, so its shape says "did not drop".
    private let brokenRingMesh = LensLayer.annulus(segments: 72, inner: LensLayer.ringInner, arcs: 12)
    /// A jam brought to rest: a flat cross on each wedged ball.
    private let crossMesh = LensLayer.cross(halfWidth: LensLayer.crossHalfWidth)
    /// Throw lines: one solid, one dashed, both a unit long along +x from the origin (scaled to length).
    private let solidLineMesh = LensLayer.strip(dashes: 0, halfWidth: LensLayer.throwLineHalfWidth)
    private let dashedLineMesh = LensLayer.strip(dashes: 9, halfWidth: LensLayer.throwLineHalfWidth)
    private var markMaterial = UnlitMaterial()
    /// The jump mark under each ball, shown while it flies: a ring on its ground spot (0.7.6, #17; a soft dot before).
    private let dotRoot = Entity()
    private var dots: [ModelEntity] = []
    private var dotMaterial = UnlitMaterial()

    /// One entity per trail colour, each holding every ball's path of that colour.
    private var trailEntities: [MotionPhase: ModelEntity] = [:]
    private var trailMaterials: [MotionPhase: UnlitMaterial] = [:]
    private var trailOffsets: [MotionPhase: Float] = [:]
    private var ringMaterials: [LensEventKind: UnlitMaterial] = [:]
    /// The ring for a miscue (a cue strike whose tip slid off), separate from the ordinary strike ring.
    private var miscueMaterial: UnlitMaterial?
    /// The last recording and frame the trails were built from, so a change of the colour setting can rebuild them.
    private var lastBuild: (timeline: Timeline, frame: TableFrame)?
    /// Whether the current trails were built dashed.
    private var builtDashed = false
    private var settingObserver: NSObjectProtocol?
    private var arrowMaterial = UnlitMaterial()
    private var arrowGlowMaterial = UnlitMaterial()
    /// Spin markers: per ball, the slip belt around the ball and the side-spin ring on the cloth.
    private let spinRoot = Entity()
    private var spinMarkers: [(slip: ModelEntity, side: ModelEntity)] = []
    private var slipMaterial = UnlitMaterial()
    private var sideMaterial = UnlitMaterial()
    /// Contact geometry of a held hit (0.7.4, see CONTACT GEOMETRY in the header): its own parent, so it fades as one.
    private let contactRoot = Entity()
    /// The table's solid obstacles drawn into the Lens (0.7.4): bumper-pool posts and five-pin pins. The warm table
    /// (and its props) fades out as the Lens melts in, so without these a replay that holds on "off a bumper" or "the
    /// red pin alone" would show the moment with nothing there. Posts are static; each pin's mark goes when the
    /// recording knocks that pin down (Timeline.pinDownTime), following the clock like everything else here.
    private let obstacleRoot = Entity()
    private var pinMarks: [ModelEntity] = []
    private var centresLine = ModelEntity()
    /// The tangent in two dashes: a finer dash normally, dots with Differentiate Without Colour on (only one shows).
    private var tangentDashed = ModelEntity()
    private var tangentDotted = ModelEntity()
    /// One arrow of the momentum triangle: a flat glowing shaft (a unit strip scaled to length) and a solid head.
    private struct ContactArrow {
        let root: Entity
        let shaft: ModelEntity
        let head: ModelEntity
    }
    /// Incoming (white), the struck ball out (cyan), the striking ball out (cyan), in that order.
    private var contactArrows: [ContactArrow] = []
    private var squareMark = ModelEntity()
    /// The event the contact drawing is posed for and when (system uptime, seconds) it started to fade in (back-dated
    /// when a fade-in carries on from part-way, see applyContact).
    private var contactShown: (event: Int, since: TimeInterval)?
    /// The hit the contact drawing is laid out for (0.7.6): kept so it is posed again every frame it shows, fade-out
    /// included, with sizes from the camera of that frame (the view glides in on a held moment and back out after).
    private var contactSource: (geometry: ContactGeometry, event: LensEvent)?
    /// The opacity the contact drawing was last shown at (0 when off), so a fade either way starts from it.
    private var contactOpacity: Float = 0
    /// Set while the drawing fades out after its hold ended (0.7.5): the opacity it started from and when.
    private var contactFadingOut: (from: Float, since: TimeInterval)?
    private var tangentMaterial = UnlitMaterial()
    private var outgoingMaterial = UnlitMaterial()

    /// True when the system bloom pass is on for the Lens (iOS 27 / macOS 27 and not turned off by -noBloom).
    private(set) var bloomActive = false
    private let sortGroup = ModelSortGroup(depthPass: nil)


    private static func clampSampler() -> MaterialParameters.Texture.Sampler {
        let d = MTLSamplerDescriptor()
        d.sAddressMode = .clampToEdge
        d.tAddressMode = .clampToEdge
        d.minFilter = .linear
        d.magFilter = .linear
        return MaterialParameters.Texture.Sampler(d)
    }

    /// A transparent, unlit, double-sided material whose colour AND opacity come from one picture (its alpha).
    private static func glow(_ tex: TextureResource, tint: PlatformColor = .white) -> UnlitMaterial {
        var m = UnlitMaterial()
        let t = MaterialParameters.Texture(tex, sampler: clampSampler())
        m.color = .init(tint: tint, texture: t)
        // Opacity 1 times the picture's own alpha. (Feeding the picture in as a separate opacity texture was tried
        // first and dimmed colours unevenly on the iOS 27 simulator, so the alpha rides on the colour picture.)
        m.blending = .transparent(opacity: 1.0)
        m.faceCulling = .none
        return m
    }

    init() {
        bloomActive = Self.enableBloom(on: root)
        // 0.7.7 bullet-time: the bloom is hierarchical, so the moved contact drawing needs its own to keep its glow.
        _ = Self.enableBloom(on: heldRoot)
        // With a real bloom pass the halo in the pictures is dialled back; without one it carries the whole glow.
        let haloGain = bloomActive ? 0.55 : 1.0

        let slide = Theme.slideRGB, cyan = Theme.cyanRGB
        // A flight is white (the spec's airborne trail): neither sliding nor rolling, because nothing touches the cloth.
        let phaseColours: [MotionPhase: (Double, Double, Double)] = [.sliding: slide, .rolling: cyan,
                                                                     .airborne: Theme.paperRGB]
        for (phase, c) in phaseColours {
            if let tex = LensTextures.trail(color: c, haloGain: haloGain, brightness: { Self.trailBrightness(age: $0) }, width: { Self.trailWidth(age: $0) }) {
                trailMaterials[phase] = Self.glow(tex)
            }
        }
        // Rings and arrows share one soft line picture, tinted per use.
        if let ringTex = LensTextures.softLine(peak: 0.85, haloGain: haloGain) {
            func ring(_ r: Double, _ g: Double, _ b: Double) -> UnlitMaterial { Self.glow(ringTex, tint: rgba(r, g, b)) }
            ringMaterials = [.ballBall: ring(1.0, 0.97, 0.80), .cushion: ring(0.45, 0.70, 1.0),
                             // White: a landing (the only phase change that leaves a ring), the airborne trail's colour.
                             .pocket: ring(1.0, 0.82, 0.25), .cueStrike: ring(1.0, 0.97, 0.80), .phaseTransition: ring(1, 1, 1),
                             // A skip over a hole wears the pocket colour (on a broken ring); a jam brought to rest the
                             // impact colour (on a cross). Their shapes, not these colours, set them apart.
                             .rimSkip: ring(1.0, 0.82, 0.25), .settledInContact: ring(1.0, 0.97, 0.80)]
            let red = Self.miscueRGB
            miscueMaterial = ring(red.0, red.1, red.2)
        }
        if let lineTex = LensTextures.softLine(peak: 0.5, haloGain: haloGain) {
            arrowGlowMaterial = Self.glow(lineTex, tint: rgba(1.0, 0.93, 0.55))
        }
        // The marks (0.7.6): throw lines, spin marks, the contact drawing and the jump ring draw with the wider-cored
        // mark picture, so at their 2-point floor they still show a solid line (bug list #15).
        if let markTex = LensTextures.markLine(haloGain: haloGain) {
            // Throw lines in the Lens's light paper colour; the departure is solid, the line of centres dashed.
            let p = Theme.paperRGB
            markMaterial = Self.glow(markTex, tint: rgba(p.0, p.1, p.2))
            // The jump ring under a flying ball (#17): the same paper colour as the airborne trail it belongs to. The
            // ring mesh's v runs inner edge to outer edge, so the centred picture puts the bright line mid-band.
            dotMaterial = Self.glow(markTex, tint: rgba(p.0, p.1, p.2))
            // Slip is sliding, so it wears the sliding magenta; side spin wears the cushion-ring blue used above.
            slipMaterial = Self.glow(markTex, tint: rgba(slide.0, slide.1, slide.2))
            sideMaterial = Self.glow(markTex, tint: rgba(0.45, 0.70, 1.0))
            // Contact geometry: the tangent in the cushion blue (it is the line a ball would roll along a cushion
            // there), the outgoing arrows in the rolling cyan; the line of centres and the incoming arrow use the
            // paper colour of markMaterial, as the throw lines do.
            tangentMaterial = Self.glow(markTex, tint: rgba(0.45, 0.70, 1.0))
            outgoingMaterial = Self.glow(markTex, tint: rgba(cyan.0, cyan.1, cyan.2))
        }
        var core = UnlitMaterial(color: rgba(1.0, 0.96, 0.78))
        core.faceCulling = .none
        arrowMaterial = core

        root.addChild(gridEntity)
        root.addChild(obstacleRoot)
        root.addChild(dotRoot)
        root.addChild(trailRoot)
        root.addChild(ringRoot)
        root.addChild(spinRoot)
        // 0.7.7 bullet-time: under heldRoot, not root, so a frozen hit can show it with the Lens off.
        heldRoot.addChild(contactRoot)
        root.addChild(arrowRoot)
        root.addChild(aimLine)
        buildContact()

        // Differentiate Without Colour switched while the app runs: rebuild the trails dashed or solid at once.
        let change = LensTextures.differentiateWithoutColorChanged
        settingObserver = change.center.addObserver(forName: change.name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.rebuildIfSettingChanged() }
        }
    }

    /// Rebuild the current trails when the dashed setting no longer matches how they were built.
    private func rebuildIfSettingChanged() {
        // A held hit's tangent switches between dashes and dots at once too (it is not rebuilt, only swapped).
        pickTangent()
        guard LensTextures.differentiateWithoutColor != builtDashed, let last = lastBuild else { return }
        rebuild(timeline: last.timeline, frame: last.frame)
    }

    /// Switches on the system bloom for everything under `root`, where the system has it. Returns whether it is on.
    private static func enableBloom(on root: Entity) -> Bool {
        if ProcessInfo.processInfo.arguments.contains("-noBloom") { return false }
        if #available(iOS 27.0, macOS 27.0, *) {
            // Hierarchical: only the Lens glows. The warm table and the controls behind are left alone.
            root.components.set(BloomComponent(scope: .hierarchical))
            var options = BloomOptionsComponent()
            options.strength = 1.4
            options.threshold = 0.35
            options.blurRadius = 12
            root.components.set(options)
            return true
        }
        return false
    }

    // MARK: Static parts

    /// The shapes that do not depend on the recorded shot: one velocity arrow per ball, the grid, the aim line.
    func buildStatic(ballCount: Int, frame: TableFrame, table: TableSpec) {
        // Velocity arrow = a glowing ribbon shaft, a bright triangular head and a larger faint head behind it.
        let shaftMesh = MeshResource.generatePlane(width: 1, depth: Self.arrowShaftWidth)
        let headMesh = LensLayer.triangle(length: Self.arrowHeadLength, halfWidth: 0.015)
        for _ in 0..<ballCount {
            let arrow = Entity()
            let shaft = ModelEntity(mesh: shaftMesh, materials: [arrowGlowMaterial])
            shaft.components.set(ModelSortGroupComponent(group: sortGroup, order: 30))
            let shaftHolder = Entity()
            shaft.position = SIMD3(0.5, 0, 0)
            shaftHolder.addChild(shaft)
            let head = ModelEntity(mesh: headMesh, materials: [arrowMaterial])
            head.position = SIMD3(0, 0.0004, 0)
            head.components.set(ModelSortGroupComponent(group: sortGroup, order: 32))
            let glow = ModelEntity(mesh: headMesh, materials: [arrowGlowMaterial])
            glow.scale = SIMD3(2.0, 1, 2.0)
            glow.position = SIMD3(-0.015, 0, 0)
            glow.components.set(ModelSortGroupComponent(group: sortGroup, order: 31))
            let headHolder = Entity()
            headHolder.addChild(glow); headHolder.addChild(head)
            arrow.addChild(shaftHolder); arrow.addChild(headHolder)
            arrowRoot.addChild(arrow)
            arrows.append((arrow, shaftHolder, headHolder, glow))
        }

        // Spin markers, one pair per ball, sharing two meshes. Both are unit-radius arcs scaled per frame.
        let beltMesh = LensLayer.spinArc(flat: false, halfWidth: Self.beltHalfWidth, headLength: Self.beltHeadLength,
                                         headHalfWidth: 0.24)
        let flatMesh = LensLayer.spinArc(flat: true, halfWidth: Self.sideHalfWidth, headLength: Self.sideHeadLength,
                                         headHalfWidth: 0.20)
        for _ in 0..<ballCount {
            let slip = ModelEntity(mesh: beltMesh, materials: [slipMaterial])
            slip.components.set(ModelSortGroupComponent(group: sortGroup, order: 25))
            slip.components.set(OpacityComponent(opacity: 0))
            slip.isEnabled = false
            let side = ModelEntity(mesh: flatMesh, materials: [sideMaterial])
            side.components.set(ModelSortGroupComponent(group: sortGroup, order: 24))
            side.components.set(OpacityComponent(opacity: 0))
            side.isEnabled = false
            spinRoot.addChild(slip); spinRoot.addChild(side)
            spinMarkers.append((slip, side))
        }

        // The jump mark under each ball while it flies (0.7.6, #17): a ring lying just above the grid, sized per frame.
        let dotMesh = LensLayer.annulus(segments: 48, inner: Self.jumpRingInner)
        for _ in 0..<ballCount {
            let dot = ModelEntity(mesh: dotMesh, materials: [dotMaterial])
            dot.scale = SIMD3(frame.ballRadius, 1, frame.ballRadius)
            dot.components.set(ModelSortGroupComponent(group: sortGroup, order: 5))
            dot.components.set(OpacityComponent(opacity: 0))
            dot.isEnabled = false
            dotRoot.addChild(dot)
            dots.append(dot)
        }

        buildGrid(frame: frame, table: table)

        // Aim line for the player's own break.
        aimLine.model = ModelComponent(mesh: .generateBox(width: 1, height: 0.002, depth: 0.004),
                                       materials: [UnlitMaterial(color: rgba(1, 1, 1, 0.8))])
        aimLine.isEnabled = false
    }

    /// Grid under the Lens, with the cushion line, the rail outline and the pockets drawn into it as holes (the edge
    /// pockets the table has, and any holes in its bed), each at its own capture radius. A function of the table alone:
    /// the picture is cached by StartupAssets under the hole list (GridKey), so nothing here depends on the clock and
    /// the Lens fingerprint, which covers only clock-driven parts, needs nothing from it. Called again by TableScene
    /// when the table changes.
    func buildGrid(frame: TableFrame, table: TableSpec) {
        let L = frame.length, W = frame.width
        // Edge pockets only when the table has them (a table without, such as five-pin, records none anyway; the
        // check keeps the grid honest if a list is ever carried over).
        let edge: [(x: Double, y: Double, radius: Double)] = table.pocketsEnabled
            ? zip(table.pockets, table.pocketCaptureRadius).map { (x: $0.0.x, y: $0.0.y, radius: $0.1) } : []
        let pockets = edge + table.bedHoles.map { (x: $0.center.x, y: $0.center.y, radius: $0.captureRadius) }
        buildObstacles(frame: frame, table: table)
        if let tex = BallTextures.gridTexture(length: Double(L), width: Double(W), pockets: pockets) {
            let m = Float(BallTextures.gridMargin)
            gridEntity.model = ModelComponent(mesh: .generatePlane(width: L + 2 * m, depth: W + 2 * m), materials: [Self.glow(tex)])
            gridEntity.position = SIMD3(0, 0.0004, 0)
            gridEntity.components.set(ModelSortGroupComponent(group: sortGroup, order: 0))
        }
    }

    /// Posts as solid paper-coloured discs with a small dark peg (a hole is a dark disc with a thin light rim) and
    /// pins as smaller discs, the red pin red, at their standing spots. Rebuilt with the grid when the table changes.
    private func buildObstacles(frame: TableFrame, table: TableSpec) {
        for child in Array(obstacleRoot.children) { child.removeFromParent() }
        pinMarks = []
        let paper = UnlitMaterial(color: rgba(0.92, 0.96, 1.0, 0.92))
        let red = UnlitMaterial(color: rgba(0.95, 0.25, 0.30, 0.95))
        func disc(_ center: Vec2, radius: Double, _ material: UnlitMaterial) -> ModelEntity {
            let e = ModelEntity(mesh: .generateCylinder(height: 0.003, radius: Float(radius)), materials: [material])
            e.position = frame.world(center, height: 0.002)
            e.components.set(ModelSortGroupComponent(group: sortGroup, order: 1))
            obstacleRoot.addChild(e)
            return e
        }
        // A post is a solid light disc with a small dark peg in the middle: not a ball (no shading), not a hole (mostly
        // dark with a thin rim).
        let core = UnlitMaterial(color: rgba(0.0, 0.006, 0.014, 1.0))
        for post in table.posts {
            _ = disc(post.center, radius: post.radius, paper)
            let inner = disc(post.center, radius: post.radius * 0.28, core)
            inner.position.y += 0.001
        }
        // A five-pin castle (pins and no holes in the bed) has a red pin; bar billiards' pegs (pins beside holes) have
        // none, so there every peg is drawn in paper rather than painting its black peg red (0.7.5).
        let castle = !table.pins.isEmpty && table.bedHoles.isEmpty
        // The red pin is the one in the middle of the castle (FivePinRules.redPin, the pin nearest the table's
        // centre); read here from the geometry so the Lens needs nothing from the rules.
        let centre = Vec2(table.length / 2, table.width / 2)
        let nearest = table.pins.indices.min { (table.pins[$0].center - centre).length < (table.pins[$1].center - centre).length }
        // Each mark is a disc 1.6 times the pin's contact radius, never under 8 mm: 2.6 cm across on five-pin, whose
        // pins touch at 2.4 mm. That already clears the 1.4 cm the 0.7.5 plan (R-A) asks for, so the size is unchanged
        // and the castle ring below is what makes the castle read at a glance on a phone.
        func markRadius(_ pin: Pin) -> Double { max(pin.radius, 0.008) * 1.6 }
        for (k, pin) in table.pins.enumerated() {
            pinMarks.append(disc(pin.center, radius: markRadius(pin), castle && k == nearest ? red : paper))
        }
        // The castle ring (0.7.5, plan item R-A): a thin, faint paper-coloured circle round the whole castle, just
        // outside the outer pins' marks, centred on the red pin. Static like the posts: the castle's place does not
        // change when pins fall, and the ring stays so the eye still finds where the pins stood.
        if castle, let middle = nearest {
            let c = table.pins[middle].center
            let outer = table.pins.map { ($0.center - c).length + markRadius($0) }.max() ?? 0
            let radius = Float(outer + Self.castleRingGap)
            let inner = max(0, 1 - Self.castleRingWidth / radius)
            var faint = UnlitMaterial(color: rgba(Theme.paperRGB.0, Theme.paperRGB.1, Theme.paperRGB.2))
            // The blending opacity is PhysicallyBasedMaterial.Opacity (a struct with a scale), not a scalar parameter.
            faint.blending = .transparent(opacity: .init(scale: Self.castleRingStrength))
            faint.faceCulling = .none
            let ring = ModelEntity(mesh: Self.annulus(segments: 96, inner: inner), materials: [faint])
            ring.scale = SIMD3(radius, 1, radius)
            // Just under the pin marks (0.002 m), over the grid (0.0004 m).
            ring.position = frame.world(c, height: 0.0016)
            ring.components.set(ModelSortGroupComponent(group: sortGroup, order: 1))
            obstacleRoot.addChild(ring)
        }
    }

    // MARK: Timeline-dependent parts

    /// Rebuild the trails and rings for a new recorded shot.
    func rebuild(timeline: Timeline, frame: TableFrame) {
        for child in Array(trailRoot.children) { child.removeFromParent() }
        for child in Array(ringRoot.children) { child.removeFromParent() }
        trailEntities = [:]; trailOffsets = [:]; rings = []
        lastBuild = (timeline, frame)
        // A new recording: any contact drawing belonged to the old one (its event index means nothing here), so it is
        // cut at once, a fade-out in progress included.
        cutContact()
        builtDashed = LensTextures.differentiateWithoutColor

        // Gather every ball's ribbons into one mesh per colour.
        var builders: [MotionPhase: RibbonBuilder] = [.sliding: RibbonBuilder(), .rolling: RibbonBuilder(),
                                                      .airborne: RibbonBuilder()]
        for b in 0..<timeline.ballCount {
            addTrails(for: b, timeline: timeline, frame: frame, dashSliding: builtDashed, into: &builders)
        }
        for (phase, builder) in builders {
            guard let mesh = builder.mesh(), let mat = trailMaterials[phase] else { continue }
            let e = ModelEntity(mesh: mesh, materials: [mat])
            let order: Int32 = phase == .sliding ? 10 : (phase == .rolling ? 11 : 12)
            e.components.set(ModelSortGroupComponent(group: sortGroup, order: order))
            trailRoot.addChild(e)
            trailEntities[phase] = e
        }

        /// One mark lying on the table at `point`, hidden until the clock reaches it.
        func place(_ mesh: MeshResource, _ mat: UnlitMaterial, at point: Vec2, scale: Float, yaw: Float = 0,
                   height: Float = 0.008) -> ModelEntity {
            let mark = ModelEntity(mesh: mesh, materials: [mat])
            mark.scale = SIMD3(scale, 1, scale)
            mark.position = frame.world(point, height: height)
            if yaw != 0 { mark.orientation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0)) }
            mark.isEnabled = false
            mark.components.set(OpacityComponent(opacity: 0))
            mark.components.set(ModelSortGroupComponent(group: sortGroup, order: 20))
            ringRoot.addChild(mark)
            return mark
        }

        for e in timeline.events {
            // Which events leave a ring: every impact and drop as before, plus the generation-two moments (a jam
            // brought to rest, a skip over a hole), a miscue, which a player could otherwise only hear, and a landing
            // from a jump (only that phase change: skid-to-roll and take-off leave no ring).
            let isMiscue = e.kind == .cueStrike && e.miscue == true
            let isLanding = e.kind == .phaseTransition && e.flight == .landing
            let ringed: Set<LensEventKind> = [.ballBall, .cushion, .pocket, .rimSkip, .settledInContact]
            guard ringed.contains(e.kind) || isMiscue || isLanding else { continue }
            let recorded = Float(min(1.5, max(0.1, e.normalImpulse)))
            let strength = (isMiscue || e.kind == .rimSkip) ? Self.markerStrength : recorded
            let radius = 0.022 + 0.034 * strength
            guard let mat = isMiscue ? miscueMaterial : ringMaterials[e.kind] else { continue }
            if e.kind == .settledInContact {
                // A jam brought to rest: a cross on each wedged ball where it came to rest, held still, not an
                // expanding flash, because the event is balls stopping, not a hit.
                for b in e.balls where b.ball < timeline.ballCount {
                    let at = timeline.state(ball: b.ball, at: e.time).position
                    let arm = frame.ballRadius * 1.3
                    let mark = place(crossMesh, mat, at: at, scale: arm, yaw: .pi / 4)
                    rings.append(Flash(entity: mark, time: e.time, span: Self.jamMarkSpan, radius: arm,
                                       grows: false, peak: 0.85, band: 2 * Self.crossHalfWidth * arm))
                }
                continue
            }
            // A miscue is drawn as two rings, one inside the other, so its shape (not only its red) sets it apart
            // from every impact ring; the inner one is 0.6 of the outer, a gap wider than the ring's own band. A skip
            // over a hole is one broken ring, again a shape no impact has.
            let sizes: [Float] = isMiscue ? [radius, radius * 0.6] : [radius]
            let mesh = e.kind == .rimSkip ? brokenRingMesh : ringMesh
            // The screen floor is measured on the thinnest band (the miscue's inner ring), and both rings share it, so
            // a floored miscue keeps its two rings one inside the other (0.7.6).
            let band = (1 - Self.ringInner) * (sizes.min() ?? radius)
            for size in sizes {
                let ring = place(mesh, mat, at: e.point, scale: size)
                rings.append(Flash(entity: ring, time: e.time, span: Self.ringSpan, radius: size, grows: true, peak: 0.85,
                                   band: band))
            }
            // Throw: the line of centres (dashed) beside where the struck ball really went (solid), from that ball.
            if let t = CaptionEngine.throwFacts(e), t.object < timeline.ballCount {
                let from = timeline.state(ball: t.object, at: e.time).position
                for (line, mesh, peak) in [(t.lineOfCentres, dashedLineMesh, Float(0.7)), (t.departure, solidLineMesh, Float(0.9))] {
                    let dir = frame.direction(line)
                    let yaw = -atan2(dir.z, dir.x)
                    let mark = place(mesh, markMaterial, at: from, scale: 1, yaw: yaw, height: 0.009)
                    // Long along the line, a unit wide across (the strip's own half-width is in metres already). The
                    // frame loop lengthens and widens it to its screen floor (0.7.6, #16).
                    mark.scale = SIMD3(Self.throwLineLength, 1, 1)
                    rings.append(Flash(entity: mark, time: e.time, span: Self.throwMarkSpan, radius: 1, grows: false,
                                       peak: peak, throwDegrees: t.degrees))
                }
            }
        }
    }

    /// Ribbon geometry for one colour: positions, the (time, across) picture coordinates and triangles.
    @MainActor private struct RibbonBuilder {
        var positions: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []

        /// Adds one strip along `pts`; `times[i]` is when the ball was at `pts[i]`, `halves[i]` the half-width there.
        mutating func addStrip(_ pts: [SIMD3<Float>], times: [Double], halves: [Float]) {
            guard pts.count >= 2, times.count == pts.count, halves.count == pts.count else { return }
            let base = UInt32(positions.count)
            for (i, p) in pts.enumerated() {
                let a = pts[max(0, i - 1)], b = pts[min(pts.count - 1, i + 1)]
                var d = b - a
                d.y = 0
                let len = simd_length(d)
                let dir = len > 1e-9 ? d / len : SIMD3<Float>(1, 0, 0)
                let side = SIMD3<Float>(-dir.z, 0, dir.x) * halves[i]
                // u carries the time as a fraction of the picture's age window; v runs across the ribbon.
                let u = Float(times[i] / LensTextures.ageWindow)
                positions.append(p + side); uvs.append(SIMD2(u, 0))
                positions.append(p - side); uvs.append(SIMD2(u, 1))
            }
            for i in 0..<(pts.count - 1) {
                let a = base + UInt32(i * 2)
                indices += [a, a + 1, a + 2, a + 1, a + 3, a + 2]
            }
        }

        func mesh() -> MeshResource? {
            guard !positions.isEmpty else { return nil }
            var d = MeshDescriptor(name: "trails")
            d.positions = MeshBuffers.Positions(positions)
            d.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
            d.primitives = .triangles(indices)
            return try? MeshResource.generate(from: [d])
        }
    }

    /// Cuts one strip into dashes `on` metres long separated by `off`-metre gaps, measured along the path, so the
    /// pattern is even whatever the point spacing. Each cut point is placed by straight interpolation between its two
    /// neighbours, with its time and half-width interpolated the same way, so every dash still carries the exact
    /// times the trail picture fades by. The pattern restarts at the start of each strip.
    static func dashes(_ pts: [SIMD3<Float>], times: [Double], halves: [Float], on: Double, off: Double)
        -> [(pts: [SIMD3<Float>], times: [Double], halves: [Float])] {
        guard pts.count >= 2, on > 0, off > 0 else { return [] }
        var out: [(pts: [SIMD3<Float>], times: [Double], halves: [Float])] = []
        var current: (pts: [SIMD3<Float>], times: [Double], halves: [Float]) = ([pts[0]], [times[0]], [halves[0]])
        var drawing = true
        var phase = 0.0                     // distance into the current dash or gap
        for i in 1..<pts.count {
            let a = pts[i - 1], b = pts[i]
            let length = Double(simd_distance(a, b))
            var used = 0.0                  // distance already walked along this piece
            while length - used > 1e-9 {
                let room = (drawing ? on : off) - phase
                let step = min(room, length - used)
                used += step
                phase += step
                let k = Float(used / length)
                let p = a + (b - a) * k
                let t = times[i - 1] + (times[i] - times[i - 1]) * Double(k)
                let h = halves[i - 1] + (halves[i] - halves[i - 1]) * k
                if drawing { current.pts.append(p); current.times.append(t); current.halves.append(h) }
                if phase >= (drawing ? on : off) - 1e-9 {
                    // End of a dash: keep it; end of a gap: start the next dash at this point.
                    if drawing { if current.pts.count >= 2 { out.append(current) } } else { current = ([p], [t], [h]) }
                    drawing.toggle()
                    phase = 0
                }
            }
        }
        if drawing, current.pts.count >= 2 { out.append(current) }
        return out
    }

    private func addTrails(for ball: Int, timeline: Timeline, frame: TableFrame, dashSliding: Bool,
                           into builders: inout [MotionPhase: RibbonBuilder]) {
        let segs = timeline.segments[ball]
        let tLimit = min(timeline.duration, timeline.pocketTime[ball] ?? .infinity)
        // The line is wider where the ball is faster, so a still frame shows speed. Half-width of the whole
        // ribbon (core and halo together) in metres: about 3 points on a phone at the slowest, 6 at a break.
        func half(_ speed: Double) -> Float { 0.013 + 0.0016 * Float(min(speed, 8)) }
        for seg in segs where seg.phase == .sliding || seg.phase == .rolling || seg.phase == .airborne {
            let tEnd = min(seg.t1, tLimit)
            guard tEnd > seg.t0 else { continue }
            var t = seg.t0
            var pts: [SIMD3<Float>] = [], times: [Double] = [], halves: [Float] = []
            // Each colour rides at its own height (rolling 3 mm above sliding) so overlapping paths never fight over depth.
            // A flight climbs with the ball: its lift is added to the ball's own height above the cloth at each point.
            let airborne = seg.phase == .airborne
            let lift: Float = airborne ? Self.airborneLift : (seg.phase == .rolling ? 0.0046 : 0.0016)
            func add(_ time: Double) {
                let k = seg.kinematics(at: time)
                let p = frame.world(k.position, height: lift + (airborne ? Float(k.height) : 0))
                // Points closer than 2 mm add nothing but a noisy ribbon direction; skip them (the last point always stays).
                if let last = pts.last, simd_distance(last, p) < 0.002, time < tEnd { return }
                pts.append(p); times.append(time); halves.append(half(k.velocity.length))
            }
            add(t)
            while t < tEnd {
                let speed = seg.kinematics(at: t).velocity.length
                // About a centimetre and a half between points, whatever the speed, capped at 50 ms for slow rolls.
                let dt = min(0.05, max(0.002, 0.015 / max(speed, 0.01)))
                t = min(tEnd, t + dt)
                add(t)
            }
            if airborne {
                // A flight is always dashed and white (the spec's airborne trail), so it never reads as either
                // phase on the cloth, with or without colour. The dash is measured along the path in three
                // dimensions, so a steep hop still gets even dashes.
                for dash in Self.dashes(pts, times: times, halves: halves, on: Self.airDash, off: Self.airGap) {
                    builders[seg.phase]?.addStrip(dash.pts, times: dash.times, halves: dash.halves)
                }
            } else if dashSliding && seg.phase == .sliding {
                // Differentiate Without Colour: sliding is dashed, rolling solid (the legend chip matches).
                for dash in Self.dashes(pts, times: times, halves: halves, on: Self.dashLength, off: Self.dashGap) {
                    builders[seg.phase]?.addStrip(dash.pts, times: dash.times, halves: dash.halves)
                }
            } else {
                builders[seg.phase]?.addStrip(pts, times: times, halves: halves)
            }
        }
    }

    /// A flat unit-radius ring (annulus) lying on the table; scaled per impact. UV v runs inner (0) to outer (1) edge.
    /// `arcs` above zero cuts it into that many arcs with equal gaps between them (the rim skip's broken ring): the
    /// circle is split into 2 * arcs equal parts and only every other part is filled. `segments` should be a multiple
    /// of 2 * arcs so every arc has the same number of pieces (72 and 12 give three each).
    private static func annulus(segments: Int, inner: Float, arcs: Int = 0) -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        for i in 0...segments {
            let a = Float(i) / Float(segments) * 2 * .pi
            positions.append(SIMD3(cos(a), 0, sin(a))); uvs.append(SIMD2(0.5, 1))
            positions.append(SIMD3(cos(a) * inner, 0, sin(a) * inner)); uvs.append(SIMD2(0.5, 0))
        }
        for i in 0..<segments {
            // Which of the 2 * arcs parts this piece falls in; odd parts are the gaps.
            if arcs > 0, (i * 2 * arcs / segments) % 2 == 1 { continue }
            let k = UInt32(i * 2)
            indices += [k, k + 1, k + 2, k + 1, k + 3, k + 2]
        }
        var d = MeshDescriptor(name: "ring")
        d.positions = MeshBuffers.Positions(positions)
        d.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        d.primitives = .triangles(indices)
        return try! MeshResource.generate(from: [d])
    }

    /// A flat cross lying on the table: two bars from -1 to 1 through the origin, along x and along z, each
    /// `halfWidth` wide either side (unit scale). UV v runs across each bar so the soft line picture puts its bright
    /// core down the middle.
    private static func cross(halfWidth w: Float) -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        for along in [SIMD3<Float>(1, 0, 0), SIMD3<Float>(0, 0, 1)] {
            let across = SIMD3<Float>(-along.z, 0, along.x) * w
            let base = UInt32(positions.count)
            positions += [-along + across, -along - across, along + across, along - across]
            uvs += [SIMD2(0.5, 0), SIMD2(0.5, 1), SIMD2(0.5, 0), SIMD2(0.5, 1)]
            indices += [base, base + 1, base + 2, base + 1, base + 3, base + 2]
        }
        var d = MeshDescriptor(name: "cross")
        d.positions = MeshBuffers.Positions(positions)
        d.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        d.primitives = .triangles(indices)
        return try! MeshResource.generate(from: [d])
    }

    /// A flat line one unit long along +x from the origin, `halfWidth` metres either side, lying on the table.
    /// `dashes` above zero cuts it into that many dashes with equal gaps (2 * dashes - 1 equal parts, every other one
    /// drawn, so it starts and ends with a dash). UV v runs across.
    private static func strip(dashes: Int, halfWidth w: Float) -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        let parts = dashes > 0 ? 2 * dashes - 1 : 1
        for p in stride(from: 0, to: parts, by: dashes > 0 ? 2 : 1) {
            let x0 = Float(p) / Float(parts), x1 = Float(p + 1) / Float(parts)
            let base = UInt32(positions.count)
            positions += [SIMD3(x0, 0, w), SIMD3(x0, 0, -w), SIMD3(x1, 0, w), SIMD3(x1, 0, -w)]
            uvs += [SIMD2(0.5, 0), SIMD2(0.5, 1), SIMD2(0.5, 0), SIMD2(0.5, 1)]
            indices += [base, base + 1, base + 2, base + 1, base + 3, base + 2]
        }
        var d = MeshDescriptor(name: dashes > 0 ? "dashedLine" : "line")
        d.positions = MeshBuffers.Positions(positions)
        d.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        d.primitives = .triangles(indices)
        return try! MeshResource.generate(from: [d])
    }

    /// A flat arrow head lying on the table, tip along +x, base at the origin.
    private static func triangle(length: Float, halfWidth: Float) -> MeshResource {
        var d = MeshDescriptor(name: "head")
        d.positions = MeshBuffers.Positions([SIMD3(length, 0, 0), SIMD3(0, 0, halfWidth), SIMD3(0, 0, -halfWidth)])
        d.textureCoordinates = MeshBuffers.TextureCoordinates([SIMD2(0.5, 0.5), SIMD2(0.5, 0.5), SIMD2(0.5, 0.5)])
        d.primitives = .triangles([0, 1, 2])
        return try! MeshResource.generate(from: [d])
    }

    /// A unit-radius arc with an arrowhead, for the spin markers. The arc runs round the local +y axis through 288
    /// degrees, as p(a) = (cos a, 0, -sin a) for a from -sweep up to 0, so travelling along it (towards the head) is a
    /// right-handed turn about +y: lay local +y along a spin vector and the arrow turns the way the ball turns.
    /// The head sits at local (1, 0, 0) pointing along -z, the arc's direction of travel there.
    /// - flat: true makes a washer-like strip lying in the arc's own plane (the side-spin ring on the cloth); false
    ///   makes a belt whose width runs along the axis (the slip belt round the ball), with the head lying flat on
    ///   the belt, so with local +x pointing up the head lies level on top of the ball where the camera sees it.
    /// UV v runs across the strip (0 to 1) so the soft line picture puts its bright core down the middle.
    private static func spinArc(flat: Bool, halfWidth: Float, headLength: Float, headHalfWidth: Float) -> MeshResource {
        let segments = 56
        let sweep = Float.pi * 1.6
        var positions: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        for i in 0...segments {
            let a = -sweep + sweep * Float(i) / Float(segments)
            let c = SIMD3<Float>(cos(a), 0, -sin(a))
            let across = flat ? c : SIMD3<Float>(0, 1, 0)
            positions.append(c + across * halfWidth); uvs.append(SIMD2(0.5, 0))
            positions.append(c - across * halfWidth); uvs.append(SIMD2(0.5, 1))
        }
        for i in 0..<segments {
            let k = UInt32(i * 2)
            indices += [k, k + 1, k + 2, k + 1, k + 3, k + 2]
        }
        // Arrowhead: base across the strip at the arc's end, tip ahead along the direction of travel. Its picture
        // coordinates sit on the line's bright core, so the head reads as solid.
        let base = UInt32(positions.count)
        let end = SIMD3<Float>(1, 0, 0)
        let across = flat ? end : SIMD3<Float>(0, 1, 0)
        positions += [end + across * headHalfWidth, end - across * headHalfWidth, SIMD3(1, 0, -headLength)]
        uvs += [SIMD2(0.5, 0.5), SIMD2(0.5, 0.5), SIMD2(0.5, 0.5)]
        indices += [base, base + 1, base + 2]
        var d = MeshDescriptor(name: flat ? "sideSpin" : "slipSpin")
        d.positions = MeshBuffers.Positions(positions)
        d.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        d.primitives = .triangles(indices)
        return try! MeshResource.generate(from: [d])
    }

    // MARK: Per frame

    /// Fade the layer with the melt, slide the trail pictures to the clock, expand the rings, steer the arrows and
    /// the aim line. `ballVisible` says which balls are currently shown (the coordinator decides that).
    /// Everything here is a function of (t, melt, timeline) only.
    func apply(time t: Double, melt: Double, aim: AimPreview?,
               timeline: Timeline, frame: TableFrame, ballVisible: [Bool]) {
        let R = frame.ballRadius
        let m = Float(melt)
        root.isEnabled = m > 0.002
        root.components.set(OpacityComponent(opacity: m))

        // A pin's mark stays until the recording knocks that pin down.
        for (k, mark) in pinMarks.enumerated() {
            let down = k < timeline.pinDownTime.count ? timeline.pinDownTime[k] : nil
            mark.isEnabled = down.map { t < $0 } ?? true
        }

        // Velocity arrows
        for b in 0..<arrows.count {
            let s = timeline.state(ball: b, at: t)
            let arrow = arrows[b]
            let speed = s.velocity.length
            let showArrow = ballVisible[b] && !s.pocketed && speed > 0.04 && m > 0.02
            arrow.root.isEnabled = showArrow
            if showArrow {
                let len = Float(min(0.8, 0.02 + 0.05 * speed))
                let dir = frame.direction(s.velocity.normalized)
                let yaw = -atan2(dir.z, dir.x)
                // Above the ball wherever it is: a flying ball's arrow flies with it (height is zero on the cloth).
                arrow.root.position = frame.world(s.position, height: R + 0.012 + Float(s.height))
                arrow.root.orientation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0))
                // Screen floors (0.7.6): the shaft at least 2 points wide, the head at least 8 long (its glow twin
                // grows with it, being in the same holder). The length along the shaft is the speed and never changes.
                let ppm = pointsPerMetre(at: arrow.root.position)
                let wide = LensMarkFloor.scale(natural: Self.arrowShaftWidth, points: LensMarkFloor.line, pointsPerMetre: ppm)
                let head = LensMarkFloor.scale(natural: Self.arrowHeadLength, points: LensMarkFloor.head, pointsPerMetre: ppm)
                arrow.shaft.scale = SIMD3(len, 1, wide)
                arrow.head.position = SIMD3(len + 0.012, 0, 0)
                arrow.head.scale = SIMD3(head, 1, head)
            }
            // Spin markers reuse the state just read, so the Lens still asks the timeline once per ball per frame.
            if b < spinMarkers.count {
                applySpin(ball: b, state: s, time: t, melt: m, timeline: timeline, frame: frame, visible: ballVisible[b])
            }
            // The jump mark (0.7.6, #17): a ring on the cloth under a flying ball, its inner edge always outside the
            // ball as drawn (the Lens draws balls 8% larger), widening as the ball climbs, so from straight above its
            // edge shows round the ball and how far it reaches out says how high the ball is. It dims a little with
            // height, as the old dot did, but never so far that it is lost.
            if b < dots.count {
                let dot = dots[b]
                let flying = ballVisible[b] && !s.pocketed && s.height >= Self.dotMinHeight && m > 0.02
                if flying {
                    let up = Float(min(1, s.height / (2 * Double(R))))
                    let drawn = R * (1 + Self.lensBallGrowth * m)
                    let ground = frame.world(s.position, height: 0.0012)
                    var outer = drawn * (Self.jumpRingBase + Self.jumpRingGrowth * up)
                    if let ppm = pointsPerMetre(at: ground) {
                        // Inner edge a few points (more as it climbs) outside the drawn ball, and the band itself at
                        // least the 2-point line.
                        let clear = (drawn + (LensMarkFloor.jumpGap + LensMarkFloor.jumpGrowth * up) / ppm) / Self.jumpRingInner
                        let band = LensMarkFloor.line / ((1 - Self.jumpRingInner) * ppm)
                        outer = min(outer * LensMarkFloor.maxScale, max(outer, clear, band))
                    }
                    dot.isEnabled = true
                    dot.position = ground
                    dot.scale = SIMD3(outer, 1, outer)
                    dot.components.set(OpacityComponent(opacity: 0.85 * (1 - 0.35 * up)))
                } else if dot.isEnabled {
                    dot.isEnabled = false
                }
            }
        }

        // Trails: slide each colour's picture so its "now" lines up with the clock. Vertex time u = tv / window;
        // the picture's head sits at headX, so sampling at u + (headX - t / window) puts a vertex recorded at time t
        // exactly on the head, older ones further down the fade, and later ones off the transparent end.
        let shift = Float(LensTextures.headX - t / LensTextures.ageWindow)
        for (phase, e) in trailEntities {
            guard var mat = trailMaterials[phase] else { continue }
            mat.textureCoordinateTransform = .init(offset: SIMD2(shift, 0), scale: SIMD2(1, 1), rotation: 0)
            e.model?.materials = [mat]
            trailOffsets[phase] = shift
        }

        // Rings: expand and fade for a fixed span of clock time after each impact. Held marks (a jam's cross, the throw
        // lines) keep their size, stay at their peak for the first three fifths of their span, then fade.
        for r in rings {
            let tau = t - r.time
            if m > 0.002, tau >= 0, tau <= r.span {
                let k = Float(tau / r.span)
                r.entity.isEnabled = true
                // Screen floors (0.7.6): a ring's or cross's band at least 2 points; the throw lines long enough to
                // part visibly and 2 points wide (#16). With no camera each factor is 1, the sizes are exactly the old
                // ones, and so is the fingerprint.
                let ppm = pointsPerMetre(at: r.entity.position)
                let bandScale = LensMarkFloor.scale(natural: r.band, points: LensMarkFloor.line, pointsPerMetre: ppm)
                if r.grows {
                    let grow = r.radius * bandScale * (1 + 1.8 * k)
                    r.entity.scale = SIMD3(grow, 1, grow)
                    r.entity.components.set(OpacityComponent(opacity: r.peak * (1 - k) * (1 - k)))
                } else {
                    if let degrees = r.throwDegrees {
                        let length = LensMarkFloor.throwLineLength(natural: Self.throwLineLength, degrees: degrees,
                                                                   pointsPerMetre: ppm)
                        let wide = LensMarkFloor.scale(natural: 2 * Self.throwLineHalfWidth, points: LensMarkFloor.line,
                                                       pointsPerMetre: ppm)
                        r.entity.scale = SIMD3(length, 1, wide)
                    } else {
                        let size = r.radius * bandScale
                        r.entity.scale = SIMD3(size, 1, size)
                    }
                    let fade: Float = k < 0.6 ? 1 : 1 - (k - 0.6) / 0.4
                    r.entity.components.set(OpacityComponent(opacity: r.peak * fade))
                }
            } else if r.entity.isEnabled {
                r.entity.isEnabled = false
            }
        }

        // The held hit's contact geometry (0.7.4): off unless a guided hold is on a ball-to-ball event.
        applyContact(melt: m, timeline: timeline, frame: frame)

        // Aim line for the player's break.
        if let aim, m < 0.5 || aim.always {
            aimLine.isEnabled = true
            let dir = frame.direction(aim.direction)
            let yaw = -atan2(dir.z, dir.x)
            aimLine.position = frame.world(aim.from, height: R) + dir * Float(aim.length) * 0.5
            aimLine.orientation = simd_quatf(angle: yaw, axis: SIMD3(0, 1, 0))
            aimLine.scale = SIMD3(Float(aim.length), 1, 1)
        } else {
            aimLine.isEnabled = false
        }
    }

    /// Poses and fades one ball's spin markers for clock `t`. A function of the clock and the recorded timeline only.
    private func applySpin(ball b: Int, state: BallState, time t: Double, melt m: Float,
                           timeline: Timeline, frame: TableFrame, visible: Bool) {
        let marker = spinMarkers[b]
        func hide() {
            if marker.slip.isEnabled { marker.slip.isEnabled = false }
            if marker.side.isEnabled { marker.side.isEnabled = false }
        }
        guard visible, m > 0.02 else { hide(); return }

        // A pocketed ball's recorded state freezes with zero velocity at the capture, which would read as pure slip.
        // Instead show the spin it carried into the pocket and fade it out over a short span of clock time, so the
        // marker leaves with the ball rather than popping.
        var s = state
        var fade = 1.0
        if s.pocketed, let tp = timeline.pocketTime[b] {
            fade = max(0, 1 - (t - tp) / Self.spinPocketFade)
            guard fade > 0 else { hide(); return }
            s = timeline.state(ball: b, at: max(0, tp - 1e-6))
        }

        let R = Double(frame.ballRadius)
        let Rf = frame.ballRadius
        let w = s.omega, v = s.velocity
        // Natural roll in the solver's convention (BallSegment, rolling phase): omega = (-vy / R, vx / R). The slip is
        // what is left of the horizontal spin after taking that away; zero for a cleanly rolling ball.
        let slipX = w.x + v.y / R, slipY = w.y - v.x / R
        let slipMag = (slipX * slipX + slipY * slipY).squareRoot()
        let slipOpacity = Self.spinOpacity(R * slipMag, Self.slipFade) * fade
        let lift = Float(s.height)

        if slipOpacity > 0.004 {
            let strength = Float(Self.smoothstep(Self.slipFade.mid, Self.slipFade.full, R * slipMag))
            // Table (x, y, up) maps to scene (x, up, -y) by a proper rotation, so a spin vector maps the same way.
            let axis = simd_normalize(SIMD3<Float>(Float(slipX), 0, -Float(slipY)))
            // Local frame of the belt: +y along the slip axis, +x straight up (so the arrowhead lies on top of the
            // ball, facing the camera), +z completing a right-handed set.
            let up = SIMD3<Float>(0, 1, 0)
            let travel = simd_cross(up, axis)
            let basis = simd_float3x3(columns: (up, axis, travel))
            let natural = Rf * (1.30 + 0.10 * strength)
            let centre = frame.world(s.position, height: Rf + lift)
            // Screen floors (0.7.6, #65): the whole belt grows until its arrowhead is 8 points long; then its width
            // (local y) is held at 2 points or more. Growing it about the ball keeps the head on top of the ball.
            let ppm = pointsPerMetre(at: centre)
            let r = natural * LensMarkFloor.scale(natural: Self.beltHeadLength * natural, points: LensMarkFloor.head,
                                                  pointsPerMetre: ppm)
            // The belt also grows wider (local y) with the amount, so a hard draw shot looks heavier than a trace.
            var across = r * (0.75 + 0.6 * strength)
            across *= LensMarkFloor.scale(natural: 2 * Self.beltHalfWidth * across, points: LensMarkFloor.line,
                                          pointsPerMetre: ppm)
            // Tip the belt toward a camera looking nearly straight down (#65): turned about its own direction of travel
            // (local z, level), the belt's circle opens from an edge-on bar into an ellipse seen from above, while the
            // arrowhead stays on top pointing the way the top of the ball turns. Nothing tips in a low or level view
            // (the warm table, the Ride camera), where the belt is already seen side-on. The camera is clock-driven, so
            // the tip is too.
            var tip: Float = 0
            if let f = camera?.forward {
                tip = Self.beltTilt * Float(Self.smoothstep(0.7, 0.95, Double(-f.y)))
            }
            // (Untipped, the orientation is exactly the table-size one, with no product to round.)
            let standing = simd_quatf(basis)
            // A floored belt is larger than the ball: its centre rises by the extra radius (times how upright it still
            // stands), so its lowest point stays where the table-size belt's was instead of sinking under the cloth.
            let rise = (r - natural) * cos(tip)
            marker.slip.isEnabled = true
            marker.slip.position = centre + SIMD3<Float>(0, rise, 0)
            marker.slip.orientation = tip > 0 ? simd_quatf(angle: tip, axis: travel) * standing : standing
            marker.slip.scale = SIMD3(r, across, r)
            marker.slip.components.set(OpacityComponent(opacity: Float(slipOpacity)))
        } else if marker.slip.isEnabled {
            marker.slip.isEnabled = false
        }

        // Side spin (english): the vertical spin component. Positive is anticlockwise seen from above.
        let wz = w.z
        let sideAmount = R * abs(wz)
        let sideOpacity = Self.spinOpacity(sideAmount, Self.sideFade) * fade
        if sideOpacity > 0.004 {
            let strength = Float(Self.smoothstep(Self.sideFade.mid, Self.sideFade.full, sideAmount))
            let natural = Rf * (1.55 + 0.15 * strength)
            let at = frame.world(s.position, height: 0.006 + lift)
            // Screen floors (0.7.6, #65): the ring grows until its arrowhead is 8 points long and its band 2 points
            // wide, whichever needs more, so clockwise and anticlockwise english can be told apart on a phone.
            let ppm = pointsPerMetre(at: at)
            let r = natural * max(
                LensMarkFloor.scale(natural: Self.sideHeadLength * natural, points: LensMarkFloor.head, pointsPerMetre: ppm),
                LensMarkFloor.scale(natural: 2 * Self.sideHalfWidth * natural, points: LensMarkFloor.line, pointsPerMetre: ppm))
            marker.side.isEnabled = true
            marker.side.position = at
            // The ring's arrow turns about local +y; for clockwise spin flip it upside down (half turn about x).
            marker.side.orientation = wz >= 0 ? simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
                                               : simd_quatf(angle: Float.pi, axis: SIMD3<Float>(1, 0, 0))
            marker.side.scale = SIMD3(repeating: r)
            marker.side.components.set(OpacityComponent(opacity: Float(sideOpacity)))
        } else if marker.side.isEnabled {
            marker.side.isEnabled = false
        }
    }

    // MARK: Contact geometry (0.7.4)

    /// Builds the contact drawing's parts once (from init): two lines, the tangent's dotted twin, three arrows and the
    /// right-angle mark, all hidden. Only their poses change (poseContact, every frame they show since 0.7.6, for the
    /// screen floors) and the fade.
    private func buildContact() {
        /// One flat part lying on the cloth, with its own peak opacity (the parent's fade multiplies it).
        func part(_ mesh: MeshResource, _ material: UnlitMaterial, order: Int32, peak: Float) -> ModelEntity {
            let e = ModelEntity(mesh: mesh, materials: [material])
            e.components.set(ModelSortGroupComponent(group: sortGroup, order: order))
            e.components.set(OpacityComponent(opacity: peak))
            contactRoot.addChild(e)
            return e
        }
        // Dash counts are per line (the meshes are a unit long and scaled to the line), so on any table the line of
        // centres has seven long dashes, the tangent twelve shorter ones, and the dotted tangent twenty dots about as
        // long as they are wide: shapes that never need colour to tell them apart.
        centresLine = part(Self.strip(dashes: 7, halfWidth: Self.contactCentresHalf), markMaterial, order: 26, peak: 0.8)
        tangentDashed = part(Self.strip(dashes: 12, halfWidth: Self.contactTangentHalf), tangentMaterial, order: 26, peak: 0.7)
        tangentDotted = part(Self.strip(dashes: 20, halfWidth: Self.contactCentresHalf), tangentMaterial, order: 26, peak: 0.7)
        squareMark = part(Self.cornerMark(halfWidth: Self.contactMarkHalf), markMaterial, order: 27, peak: 0.9)

        let shaftMesh = Self.strip(dashes: 0, halfWidth: Self.contactShaftHalf)
        let headMesh = Self.triangle(length: Self.contactHeadLength, halfWidth: 0.011)
        let p = Theme.paperRGB, c = Theme.cyanRGB
        var paperHead = UnlitMaterial(color: rgba(p.0, p.1, p.2))
        paperHead.faceCulling = .none
        var cyanHead = UnlitMaterial(color: rgba(c.0, c.1, c.2))
        cyanHead.faceCulling = .none
        // Incoming in paper white, both outgoing arrows in cyan (the plan's colours for in and out).
        let looks: [(shaft: UnlitMaterial, head: UnlitMaterial)] = [(markMaterial, paperHead), (outgoingMaterial, cyanHead),
                                                                    (outgoingMaterial, cyanHead)]
        for look in looks {
            let root = Entity()
            let shaft = ModelEntity(mesh: shaftMesh, materials: [look.shaft])
            shaft.components.set(ModelSortGroupComponent(group: sortGroup, order: 28))
            let head = ModelEntity(mesh: headMesh, materials: [look.head])
            head.components.set(ModelSortGroupComponent(group: sortGroup, order: 29))
            root.addChild(shaft); root.addChild(head)
            root.components.set(OpacityComponent(opacity: 0.95))
            contactRoot.addChild(root)
            contactArrows.append(ContactArrow(root: root, shaft: shaft, head: head))
        }
        contactRoot.isEnabled = false
    }

    /// Shows the tangent as dots with Differentiate Without Colour on and as finer dashes otherwise, if it shows at all.
    private func pickTangent() {
        let shown = tangentDashed.isEnabled || tangentDotted.isEnabled
        let dotted = LensTextures.differentiateWithoutColor
        tangentDotted.isEnabled = shown && dotted
        tangentDashed.isEnabled = shown && !dotted
    }

    /// One frame of the contact drawing, in four cases (0.7.5 adds the fade-out):
    ///   - the Lens is out: cut at once;
    ///   - a guided hold on a ball-to-ball hit: laid out for that hit, faded in over `contactFadeIn` real
    ///     seconds, starting from whatever opacity it shows now (zero when hidden, part-way through a fade-out);
    ///   - a hold on anything else: cut at once (the drawing would explain the wrong moment);
    ///   - no hold any more (the replay moved on with the Lens still in): kept on its hit and faded from its
    ///     current opacity to zero over `contactFadeIn` real seconds, then switched off, so it leaves with the camera
    ///     instead of vanishing.
    /// While it shows it is posed again every frame (0.7.6): the hit's place and directions never change, but its
    /// screen-floored sizes follow the camera, which glides in on the held moment and back out as it ends.
    /// Real time, not the clock, throughout: the clock stands still while a beat is held. None of this is in
    /// fingerprint(), which covers only what the clock decides.
    private func applyContact(melt m: Float, timeline: Timeline, frame: TableFrame) {
        // 0.7.7 bullet-time: a frozen hit (or its fade-out) shows with any melt; the Lens's own drawing still needs it.
        guard m > 0.02 || bulletEvent != nil || contactIsBullet else { cutContact(); return }
        let now = ProcessInfo.processInfo.systemUptime
        // 0.7.7 bullet-time: the guided hold owns the drawing when it holds a hit, else a frozen hit does.
        if let i = heldEvent ?? bulletEvent, timeline.events.indices.contains(i),
           let g = ContactGeometry.at(timeline.events[i]) {
            contactIsBullet = (heldEvent == nil)
            if contactShown?.event != i || contactFadingOut != nil {
                if contactShown?.event != i { contactSource = (g, timeline.events[i]) }
                // Back-date the fade-in's start so it carries on from the opacity on screen now: from zero that is
                // `now`, as before; part-way through a fade-out it is that much earlier, so nothing jumps.
                contactShown = (i, now - Double(contactOpacity) * Self.contactFadeIn)
                contactFadingOut = nil
            }
            let since = contactShown?.since ?? now
            setContactOpacity(Float(min(1, max(0, (now - since) / Self.contactFadeIn))), melt: m)
            if let source = contactSource { poseContact(source.geometry, event: source.event, frame: frame) }
            return
        }
        // Held on something that is not a hit, or nothing was showing: off at once.
        // 0.7.7 bullet-time: the fade-out keeps the owner it had (contactIsBullet is left alone here).
        guard (heldEvent ?? bulletEvent) == nil, contactShown != nil, contactRoot.isEnabled else { cutContact(); return }
        // The hold ended with the drawing up: fade it out where it is.
        if contactFadingOut == nil { contactFadingOut = (from: contactOpacity, since: now) }
        let fading = contactFadingOut ?? (from: contactOpacity, since: now)
        let left = fading.from * Float(max(0, 1 - (now - fading.since) / Self.contactFadeIn))
        if left <= 0.001 {
            cutContact()
        } else {
            setContactOpacity(left, melt: m)
            if let source = contactSource { poseContact(source.geometry, event: source.event, frame: frame) }
        }
    }

    /// Shows the contact drawing at `opacity` and remembers it, so a fade that starts next can carry on from it.
    /// 0.7.7 bullet-time: the drawing no longer sits under root, so the Lens's own drawing is multiplied by the melt
    /// here, as root's opacity multiplied it before; a frozen hit's is not (the Lens is off). contactOpacity keeps the
    /// bare fade, so the fade arithmetic is unchanged.
    private func setContactOpacity(_ opacity: Float, melt m: Float) {
        contactRoot.isEnabled = true
        contactRoot.components.set(OpacityComponent(opacity: opacity * (contactIsBullet ? 1 : m)))
        contactOpacity = opacity
    }

    /// Switches the contact drawing off at once and forgets its pose and fades: the Lens left, the recording was
    /// rebuilt, a hold moved to a moment that is not a hit, or a fade-out finished.
    private func cutContact() {
        if contactRoot.isEnabled { contactRoot.isEnabled = false }
        contactShown = nil
        contactSource = nil
        contactFadingOut = nil
        contactOpacity = 0
        // 0.7.7 bullet-time: the next drawing's owner is set afresh.
        contactIsBullet = false
    }

    /// Lays the contact drawing out for one hit (see CONTACT GEOMETRY in the header for what shows when).
    private func poseContact(_ g: ContactGeometry, event e: LensEvent, frame: TableFrame) {
        // Screen floors (0.7.6, #15), read once at the contact: the whole drawing is small next to a phone's view of
        // the table, so one figure serves every part.
        // 0.7.7 bullet-time: a frozen hit's drawing hangs at the balls' centres instead of a centimetre above the cloth;
        // every height below is lifted by this (the screen floors are then measured where the drawing is).
        let contactLift: Float = contactIsBullet ? bulletLift - 0.01 : 0
        let ppm = pointsPerMetre(at: frame.world(g.point, height: 0.01 + contactLift))
        // The two lines grow together, longer and wider by one factor, so the tangent's dashes and dots keep their
        // shapes (a dot stretched only across would read as a dash): enough for the thinnest line (the tangent's
        // dashes) to be 2 points wide and for each line to reach 40 points either side of the contact, clear of the
        // caption ring round the ball.
        let natural = Self.contactLineReach * 2 * frame.ballRadius
        let lineScale = max(
            LensMarkFloor.scale(natural: 2 * Self.contactTangentHalf, points: LensMarkFloor.line, pointsPerMetre: ppm),
            LensMarkFloor.scale(natural: natural, points: LensMarkFloor.contactReach, pointsPerMetre: ppm))
        let reach = natural * lineScale
        /// Turns a part about the vertical so its local +x runs along `d` (table plan): the yaw rule used throughout.
        func yaw(_ d: Vec2) -> simd_quatf {
            let w = frame.direction(d.normalized)
            return simd_quatf(angle: -atan2(w.z, w.x), axis: SIMD3<Float>(0, 1, 0))
        }
        /// A unit strip laid through the contact along `d`, `reach` either side of it, `lineScale` times its own width.
        func through(_ entity: ModelEntity, along d: Vec2, height: Float) {
            entity.orientation = yaw(d)
            entity.position = frame.world(g.point, height: height) - frame.direction(d.normalized) * reach
            entity.scale = SIMD3<Float>(2 * reach, 1, lineScale)
        }
        // The throw lines already draw this hit's line of centres (from the struck ball); never a second one.
        // 0.7.7 bullet-time: with the Lens off there are no throw lines, so a frozen hit always draws its own.
        centresLine.isEnabled = contactIsBullet || CaptionEngine.throwFacts(e) == nil
        if centresLine.isEnabled { through(centresLine, along: g.normal, height: 0.0095 + contactLift) }
        through(tangentDashed, along: g.tangent, height: 0.0094 + contactLift)
        through(tangentDotted, along: g.tangent, height: 0.0094 + contactLift)
        tangentDashed.isEnabled = true
        pickTangent()

        // The momentum triangle and the square mark only when the struck ball was at rest.
        let triangle = !g.objectWasMoving
        let longest = max(g.incoming.length, g.objectOut.length, g.strikerOut.length)
        let k = longest > 1e-9 ? min(Self.contactArrowScale, Self.contactArrowMax / longest) : Self.contactArrowScale
        let legs: [(from: Vec2, vector: Vec2)] = [(g.point, g.incoming * k), (g.point, g.objectOut * k),
                                                  (g.point + g.objectOut * k, g.strikerOut * k)]
        // The arrows keep their lengths (they are the speeds, one scale for all three, so the triangle closes); only
        // their shafts widen to 2 points and their heads grow to 8 points (0.7.6).
        let shaftWide = LensMarkFloor.scale(natural: 2 * Self.contactShaftHalf, points: LensMarkFloor.line, pointsPerMetre: ppm)
        // The shortest head the screen allows, metres (zero with no camera, so the table-size rule below stands alone).
        let headFloor: Float = LensMarkFloor.usable(ppm).map {
            min(LensMarkFloor.head / $0, Self.contactHeadLength * LensMarkFloor.maxScale)
        } ?? 0
        for (arrow, leg) in zip(contactArrows, legs) {
            let length = Float(leg.vector.length)
            // An arrow a few millimetres long (a ball left almost still) would be only a head: leave it out.
            guard triangle, length > 0.004 else { arrow.root.isEnabled = false; continue }
            arrow.root.isEnabled = true
            arrow.root.position = frame.world(leg.from, height: 0.011 + contactLift)
            arrow.root.orientation = yaw(leg.vector)
            // The head takes at most a little under half of a short arrow, shrinking with it; the screen floor may
            // take more, up to the whole arrow (its tip always stays at the arrow's true end, so the triangle closes).
            let head = min(length, max(min(Self.contactHeadLength, length * 0.45), headFloor))
            let h = head / Self.contactHeadLength
            arrow.head.scale = SIMD3<Float>(h, 1, h)
            arrow.head.position = SIMD3<Float>(length - head, 0.0003, 0)
            let shaft = length - head
            arrow.shaft.isEnabled = shaft > 1e-4
            if arrow.shaft.isEnabled { arrow.shaft.scale = SIMD3<Float>(shaft, 1, shaftWide) }
        }

        squareMark.isEnabled = triangle && g.rightAngle
        if squareMark.isEnabled {
            // The mark's corner sits on the contact with one side along the struck ball's way out (local +x) and the
            // other along the striking ball's (local +z), mirrored across when that lies on the other side.
            let q = yaw(g.objectOut)
            let strikerWay = frame.direction(g.strikerOut.normalized)
            let side: Float = simd_dot(q.act(SIMD3<Float>(0, 0, 1)), strikerWay) >= 0 ? 1 : -1
            // Its bars are a share of its side, so the whole mark grows until they are 2 points wide (0.7.6).
            let natural = Self.contactMarkSize * frame.ballRadius
            let size = natural * LensMarkFloor.scale(natural: 2 * Self.contactMarkHalf * natural, points: LensMarkFloor.line,
                                                     pointsPerMetre: ppm)
            squareMark.position = frame.world(g.point, height: 0.0105 + contactLift)
            squareMark.orientation = q
            squareMark.scale = SIMD3<Float>(size, 1, size * side)
        }
    }

    /// A right-angle mark lying on the table: the two far sides of a unit square whose near corner is the origin, from
    /// (1, 0, 0) to (1, 0, 1) and from (0, 0, 1) to (1, 0, 1), each `halfWidth` either side (unit scale). The square's
    /// other two sides lie along the lines it marks, so they are not drawn. UV v runs across each bar.
    private static func cornerMark(halfWidth w: Float) -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        let bars: [(start: SIMD3<Float>, end: SIMD3<Float>, across: SIMD3<Float>)] = [
            (SIMD3<Float>(1, 0, 0), SIMD3<Float>(1, 0, 1 + w), SIMD3<Float>(w, 0, 0)),
            (SIMD3<Float>(0, 0, 1), SIMD3<Float>(1 + w, 0, 1), SIMD3<Float>(0, 0, w)),
        ]
        for bar in bars {
            let base = UInt32(positions.count)
            positions += [bar.start + bar.across, bar.start - bar.across, bar.end + bar.across, bar.end - bar.across]
            uvs += [SIMD2<Float>(0.5, 0), SIMD2<Float>(0.5, 1), SIMD2<Float>(0.5, 0), SIMD2<Float>(0.5, 1)]
            indices += [base, base + 1, base + 2, base + 1, base + 3, base + 2]
        }
        var d = MeshDescriptor(name: "rightAngle")
        d.positions = MeshBuffers.Positions(positions)
        d.textureCoordinates = MeshBuffers.TextureCoordinates(uvs)
        d.primitives = .triangles(indices)
        return try! MeshResource.generate(from: [d])
    }

    // MARK: Self-check (launch with -lensSelfTest)

    /// A fingerprint of everything the Lens shows that depends on the clock: the trail picture offsets, every ring,
    /// every arrow and the layer's own opacity. Two calls with the same clock must give the same fingerprint.
    /// The contact geometry of a held hit (0.7.4) is deliberately left out: it depends on the held beat and fades in
    /// over real time, not on the clock, and the scrub check never sets heldEvent, so it is hidden there anyway.
    /// Folding it in would make the check depend on wall time.
    func fingerprint() -> UInt64 {
        var h = StableHasher()
        for phase in [MotionPhase.sliding, .rolling, .airborne] { h.combine(Double(trailOffsets[phase] ?? 0)) }
        // The jump rings under flying balls (the rings loop below covers the throw lines and the jam crosses too). Their
        // size follows the ball's height since 0.7.6, so it is part of the picture.
        for dot in dots {
            h.combine(dot.isEnabled ? 1 : 0)
            guard dot.isEnabled else { continue }
            h.combine(Double(dot.position.x)); h.combine(Double(dot.position.z)); h.combine(Double(dot.scale.x))
            h.combine(Double(dot.components[OpacityComponent.self]?.opacity ?? -1))
        }
        for r in rings {
            // A hidden ring keeps its last size and opacity; they are not visible, so they are not part of the picture.
            h.combine(r.entity.isEnabled ? 1 : 0)
            guard r.entity.isEnabled else { continue }
            h.combine(Double(r.entity.scale.x))
            h.combine(Double(r.entity.components[OpacityComponent.self]?.opacity ?? -1))
        }
        for a in arrows {
            h.combine(a.root.isEnabled ? 1 : 0)
            guard a.root.isEnabled else { continue }
            h.combine(Double(a.root.position.x)); h.combine(Double(a.root.position.z))
            h.combine(Double(a.root.orientation.angle)); h.combine(Double(a.shaft.scale.x))
        }
        for marker in spinMarkers {
            for e in [marker.slip, marker.side] {
                h.combine(e.isEnabled ? 1 : 0)
                guard e.isEnabled else { continue }
                h.combine(Double(e.position.x)); h.combine(Double(e.position.z)); h.combine(Double(e.scale.x))
                h.combine(Double(e.orientation.vector.x)); h.combine(Double(e.orientation.vector.y))
                h.combine(Double(e.components[OpacityComponent.self]?.opacity ?? -1))
            }
        }
        h.combine(Double(root.components[OpacityComponent.self]?.opacity ?? -1))
        return h.value
    }
}
