// Author: Claude Opus 5.5 High
// Edited: Claude Opus 5.5 High, 21-November-2026 (review fix: the replay cue follows the ball the recording says was
//          struck, not always ball 0).
// Date: 21-November-2026
// PURPOSE: The 3D cue and the swan-neck rest on the table. Owns one root entity (a child of the warm table group, so it
//          fades out with the table as the Physics Lens melts in) holding every cue model and the rest, loaded from the
//          app bundle: CueHouse, CueBreak, CueJump, CueMasse, CueRosewood and CueCobalt (one per cue in art/equipment)
//          and SwanNeckRest, all written by Tools/blender/export_equipment.py from the other developer's art. The
//          models carry geometry only, one mesh per finish; each is dressed here with its own physically based material
//          found by the part's name (OilFinishedMaple, SatinBrass, ChalkedLeather, ...: the finish table below, read
//          from the art). If a model fails to load, nothing breaks: a missing cue falls back to the house cue, a
//          missing rest is simply not drawn.
//          Model frames (the contract with the export script): metres, +Y up. A cue's tip face centre is at the origin
//          and its axis runs along +Z to the butt (1.47 m for the house cue; CueProfile.length for each). The rest
//          stands on the cloth (y = 0) with the bottom of its V cradle straight over the origin, the cradle across X,
//          and its handle running back along +Z; its brass neck reaches forward from the feet over any ball between.
//          Which cue: the one the game picked for the shot (ShowpieceModel.cueChoice, CueProfile.choice), handed in on
//          the aim preview; the follow-through of a shot shows the cue last drawn at the aim, the one it was struck
//          with, unless the stroke names one.
//          Two poses, both decided every frame by update():
//            Aiming: the cue lies on the aim line behind the cue ball, its axis through the tip's contact point (the
//            ball centre moved by tipSide to the right and tipUp up), its tip short of that point by the same gap the
//            old flat cue used (1.7 ball radii plus the power's pull-back), pitched up by the strike's elevation (the
//            model's strikeElevation: the player's angle or the least angle that clears every ball under the cue,
//            whichever is larger, plan item 23), so it never passes through a ball. On the rest (whenever the model uses
//            it: the stance is Rest or the mode shows it, plan items 10, 23 and 57) the cue lies in the rest's cradle:
//            the rest stands 0.30 m behind the ball and the cue is raised just enough to lie in its cradle, or, for a
//            strike steeper than that, the rest moves in along the line until its cradle meets the raised cue. The
//            drawn pull-back is scaled so that at full power the tip stops just in front of its support (the bridge
//            hand at the model's bridge length, or the rest's cradle): a tip never slides back past what holds it.
//            Strike: for the first half second of a recorded shot, the follow-through: at clock 0 the tip touches the
//            ball where it was struck, then drives on 8 cm, holds, and fades. A pure function of the playback clock and
//            the recorded timeline, so scrubbing shows the same cue for the same time.
//          Hidden otherwise, and during the strike while the Ride camera flies (it sits on the cue's line).
//          Integration: TableScene owns one rig, parents it to the table group, and calls update() from apply() with
//          the aim preview (TableStage builds it, with the cue's gate in AimPreview.showsCue, the picked cue in
//          AimPreview.cue, the bridge's length in AimPreview.bridgeLength, the strike's elevation and whether the rest
//          is in use), the CueStroke of the shot on screen,
//          the clock, the timeline and whether Ride is on.
// Edited: Claude Opus 5.5 High, 21-November-2026 (look plan package 5: a soft shadow on the cloth under the cue, a long
//          soft see-through ellipse under the front of the cue, paler the higher the cue rides above the cloth (a raised
//          cue throws a weaker shadow); it comes and goes with the cue, so it shows while aiming and through the
//          follow-through. The material is TableBuilder.shadowMaterial, shared with the balls' contact shadows.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 equipment, plan items 10, 23 and 57: the other developer's six
//          cues and the swan-neck rest replace the code-built Cue.usdz and Bridge.usdz. The cue drawn is the picked
//          cue; the rest is drawn whenever the model uses it, in every mode; on the rest the cue's pitch is the larger
//          of the strike's own and the one that lays it in the cradle (the rest slides in for a steeper strike), so the
//          drawn cue never passes through a ball; the drawn pull-back stops in front of the bridge hand or the cradle.
//          The materials are the art's finishes.)
// SRP/DRY check: Pass - checked AimOverlay (now only labels the bridge), TableBuilder (its pbr() helper is private to
//          the table; the small one here mirrors it with clearcoat added), TableProps (the same dress, paint and
//          receive-light steps for its own props), ShotCamera (reads the same first segment of the cue ball for its
//          start), CueProfile (the cue kinds and lengths; this file only draws them) and StartupAssets (pictures only;
//          the models load here, once, in the background). This file only places and dresses the cue and the rest.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import RealityKit
import simd

/// How the shot now on screen was struck, for the follow-through: the tip's contact offsets (metres; up is follow, right
/// is side spin as the player sees it), the sine of the cue's raise, whether the cue rested on the rest, and which cue.
struct CueStroke {
    var tipUp: Double = 0
    var tipSide: Double = 0
    var elevation: Double = 0
    var usesBridge = false
    /// The cue the shot was struck with; nil means the cue last drawn at the aim, which is the one the shot was
    /// struck with, since the follow-through starts the moment the aimed cue strikes.
    var cue: CueKind? = nil
}

@MainActor
final class CueRig {
    // MARK: Tunables

    /// How far behind the cue ball's centre the rest's cradle stands for an ordinary rest shot, metres: the bridge
    /// length StrokeModel.mechanicalBridge, the bridge readout and EightBallJudge all use for the rest.
    static let bridgeSetback: Float = 0.30
    /// The nearest the rest's cradle comes to the cue ball's centre when it moves in to meet a steeply raised cue,
    /// metres: StrokeModel.bridgeRange's shortest bridge, a hand's width. Nearer than that the cradle (3.6 cm across)
    /// and the cue's tip and ferrule crowd the ball. A strike steeper than the cradle can carry from here rides just
    /// above the cradle instead.
    static let restClosest: Float = 0.10
    /// The least the cue's butt is raised off a hand bridge, radians (about 4 degrees): enough to clear the rail
    /// behind a ball near it. The rest needs none: its cradle already holds the cue up.
    static let restingPitch: Float = 0.07
    /// The house cue's shaft radius 0.30 m from its tip, metres, measured on the exported model (export_equipment.py's
    /// MEASURE line: 0.00832; the art's shaft tapers straight from 6.4 mm at the tip to 11 mm at the joint).
    /// Reach.shaftRadius restates the shaft's radius for its own geometry.
    static let cueRadiusAtBridge: Float = 0.00832
    /// Height of the cue's axis above the cloth when it lies in the rest's cradle, metres, for each cue: measured by
    /// export_equipment.py (MEASURE lines) from the exported rest and each cue's shaft radius 0.30 m from its tip (the
    /// lowest a circle of that radius sits in the cradle's V without touching it). The swan neck carries the cue high,
    /// so it can reach over a ball; the thicker shafts of the short cues ride a little higher. The cue's slight tilt
    /// through the cradle lifts it by under half a millimetre more at the rest's shallow angles, which is left out.
    static func restSeat(_ kind: CueKind) -> Float {
        switch kind {
        case .house, .breakCue, .rosewoodFourPoint, .cobalt: return 0.08884
        case .jump: return 0.09042
        case .masse: return 0.09084
        }
    }
    /// How far in front of its support (the bridge hand, or the rest's cradle) the tip stays at the end of the
    /// pull-back, metres along the cue: the ferrule's length (1.6 cm on the art's cues) plus the cradle tube's 3 mm
    /// and a hair, so the tip and ferrule never slide back into the hand or the cradle.
    static let bridgeTipClearance: Float = 0.02
    /// Pull-back at full power, metres: the same 0.35 m the flat cue used, 0.20 m on the rest. Either is scaled down
    /// when the support is nearer (TipPlacement.pulledBack), so the tip always stays in front of it.
    static let pullReach: Float = 0.35
    static let bridgePullReach: Float = 0.20
    /// The follow-through: how far the tip drives on past the contact, over how long (clock seconds), and when the
    /// cue fades away.
    static let followDistance: Float = 0.08
    static let driveTime = 0.12
    static let fadeStart = 0.28
    static let fadeEnd = 0.45

    /// The bundle name of each cue's model (export_equipment.py's PIECES).
    static func modelName(_ kind: CueKind) -> String {
        switch kind {
        case .house: return "CueHouse"
        case .breakCue: return "CueBreak"
        case .jump: return "CueJump"
        case .masse: return "CueMasse"
        case .rosewoodFourPoint: return "CueRosewood"
        case .cobalt: return "CueCobalt"
        }
    }

    // MARK: Parts

    /// Parent of the cues and the rest; TableScene adds it to the table group.
    let root = Entity()
    /// Moved and turned each frame; holds every loaded cue model, only the one in use enabled.
    private let cueHolder = Entity()
    private let restHolder = Entity()
    /// The loaded cue models by kind. Every cue loads once at start (about a megabyte in all), so switching cues is a
    /// matter of which child is enabled, never a load in the middle of a frame.
    private var cueModels: [CueKind: Entity] = [:]
    /// The cue drawn at the last aim: the follow-through's cue when the stroke does not name one.
    private var lastAimedCue: CueKind = .house
    /// The cue's soft shadow on the cloth (a unit plane, scaled and turned under the cue each frame).
    private let shadow: ModelEntity
    /// Length of the shadow along the cue, metres: the front of the cue, the part close enough to the cloth to throw a
    /// visible soft shadow under an overhead lamp (further back the cue is high enough for its shadow to wash out).
    static let shadowLength: Float = 0.80
    /// The scene root that carries the lamp reflection (ImageBasedLightComponent); the loaded parts point at it.
    private weak var lightSource: Entity?

    init(lightSource: Entity) {
        self.lightSource = lightSource
        shadow = ModelEntity(mesh: .generatePlane(width: 1, depth: 1), materials: [TableBuilder.shadowMaterial(opacity: 0.45)])
        root.name = "CueRig"
        root.addChild(cueHolder)
        root.addChild(restHolder)
        root.addChild(shadow)
        restHolder.isEnabled = false
        root.isEnabled = false
        // Load in the background of the main actor; the table shows at once and the cue appears when it is ready.
        Task { [weak self] in await self?.loadModels() }
    }

    /// The house cue first (it is the one almost every shot shows), then the other cues, then the rest. Each one is
    /// dressed and added disabled; show(cue:) enables the one in use.
    private func loadModels() async {
        for kind in CueKind.allCases {
            do {
                let cue = try await Entity(named: Self.modelName(kind), in: Bundle.main)
                Self.dress(cue, Self.finishes)
                cue.isEnabled = false
                cueHolder.addChild(cue)
                cueModels[kind] = cue
            } catch {
                NSLog("CueRig: the %@ model did not load: %@", Self.modelName(kind), String(describing: error))
            }
        }
        do {
            let rest = try await Entity(named: "SwanNeckRest", in: Bundle.main)
            Self.dress(rest, Self.finishes)
            restHolder.addChild(rest)
        } catch { NSLog("CueRig: the rest model did not load: %@", String(describing: error)) }
        // TableBuilder.installEnvironment walks the tree once; parts that arrive after it would miss the reflection.
        if let light = lightSource { Self.receiveLight(root, from: light) }
    }

    // MARK: Per frame

    /// Place, show or hide the cue and the rest for this frame.
    /// - aim: the live aim while the shot panel is open; the cue shows for it only when `aim.showsCue`.
    /// - stroke: how the shot on screen was struck; shown as the follow-through for the first moments of the clock.
    /// - clock: the playback clock (after any test pinning), the same one the balls use.
    /// - ride: true while the Ride camera may fly; it sits behind the cue ball, so the follow-through is hidden then.
    func update(aim: AimPreview?, stroke: CueStroke?, clock t: Double, timeline: Timeline, frame: TableFrame, ride: Bool) {
        let R = frame.ballRadius
        if let aim, aim.showsCue {
            lastAimedCue = aim.cue
            let pull = Pull(fraction: Float(min(max(aim.powerFraction, 0), 1)),
                            reach: aim.usesBridge ? Self.bridgePullReach : Self.pullReach,
                            handBridge: Float(aim.bridgeLength ?? StrokeModel.automaticBridge))
            place(ball: aim.from, direction: aim.direction, tipUp: Float(aim.tipUp), tipSide: Float(aim.tipSide),
                  elevation: Float(aim.elevation), rest: aim.usesBridge, cue: aim.cue, tip: .pulledBack(pull),
                  frame: frame)
            show(opacity: 1)
            return
        }
        guard let stroke, !ride, t >= 0, t < Self.fadeEnd, let start = Self.strikeStart(timeline) else {
            root.isEnabled = false
            return
        }
        let up = Float(stroke.tipUp), side = Float(stroke.tipSide)
        // At the contact the tip sits on the ball's surface. Its axis passes through the offset point (centre plus the
        // side and up offsets), and the surface is sqrt(R^2 - side^2 - up^2) back from that point along the axis.
        let onSurface = max(0, R * R - side * side - up * up).squareRoot()
        let k = Float(min(1, t / Self.driveTime))
        let drive = Self.followDistance * (1 - (1 - k) * (1 - k))          // ease-out
        place(ball: start.position, direction: start.direction, tipUp: up, tipSide: side, elevation: Float(stroke.elevation),
              rest: stroke.usesBridge, cue: stroke.cue ?? lastAimedCue, tip: .behindContact(onSurface - drive),
              frame: frame)
        let fade = t <= Self.fadeStart ? 1 : 1 - (t - Self.fadeStart) / (Self.fadeEnd - Self.fadeStart)
        show(opacity: Float(max(0, fade)))
    }

    private func show(opacity: Float) {
        root.components.set(OpacityComponent(opacity: opacity))
        root.isEnabled = opacity > 0.001
    }

    /// Enable the model of `kind`, or the house cue while that one has not loaded (or failed to), and no other.
    private func showCue(_ kind: CueKind) {
        let shown = cueModels[kind] != nil ? kind : .house
        for (k, model) in cueModels { model.isEnabled = k == shown }
    }

    /// Where the struck ball started and the way it was sent, from its first recorded segment; nil when the shot did
    /// not move it (the re-rack records a zero-speed strike so the rack shows) or it is not on the table. The struck
    /// ball is the one the recording's cue-strike event names (five-pin and bumper pool strike a ball other than 0);
    /// ball 0 when a recording has no strike event.
    private static func strikeStart(_ timeline: Timeline) -> (position: Vec2, direction: Vec2)? {
        let struck = timeline.events.first { $0.kind == .cueStrike }?.balls.first?.ball ?? 0
        guard struck < timeline.ballCount, let first = timeline.segments[struck].first else { return nil }
        let v = first.velocity0
        guard v.length > 1e-4, NextShot.isOnTable(first.position0) else { return nil }
        return (first.position0, v.normalized)
    }

    /// The cue's pitch (radians, butt up) and, on the rest, how far behind the ball's centre the rest's cradle stands.
    /// - Hand bridge: the strike's own angle, never below the resting pitch a player lifts the butt by.
    /// - Rest: the cue lies in the cradle. At the rest's usual 0.30 m that takes the pitch from the contact height up
    ///   to the cradle's seat; a strike already steeper than that keeps its own pitch and the rest moves in along the
    ///   line until its cradle meets the cue (never nearer than restClosest; past that the cue rides just above the
    ///   cradle). Either way the pitch is at least the strike's, which already clears every ball under the cue.
    static func pose(elevation: Float, contactHeight: Float, rest: Bool, cue: CueKind) -> (pitch: Float, restDistance: Float) {
        let strike = asin(min(max(elevation, 0), 0.995))
        guard rest else { return (max(strike, restingPitch), bridgeSetback) }
        // The seat is far above the contact (about 9 cm against a ball's 2.9 cm centre), so the rise is positive.
        let rise = max(0.001, restSeat(cue) - contactHeight)
        let cradlePitch = atan2(rise, bridgeSetback)
        if strike <= cradlePitch { return (cradlePitch, bridgeSetback) }
        return (strike, max(rise / tan(strike), restClosest))
    }

    /// The aim's pull-back: the power's share of the full pull, the full pull's length, and the hand bridge's distance
    /// behind the ball's centre (metres), which the pulled-back tip must stay in front of.
    struct Pull {
        var fraction: Float
        var reach: Float
        var handBridge: Float
    }

    /// Where the tip sits along the cue's axis.
    enum TipPlacement {
        /// Aiming: 1.7 radii behind the contact point plus the power's share of the pull, the whole pull scaled down
        /// so that at full power the tip still stops bridgeTipClearance in front of the bridge hand or the rest's
        /// cradle: a real tip never slides back past the hand or the cradle that holds it (plan item 23).
        case pulledBack(Pull)
        /// The follow-through: this far behind the contact offset point, along the cue's axis (negative is past it).
        case behindContact(Float)
    }

    /// Put the cue (and the rest, when used) in place for a ball at `ball` (table plan), struck along `direction`.
    private func place(ball: Vec2, direction: Vec2, tipUp: Float, tipSide: Float, elevation: Float, rest: Bool,
                       cue: CueKind, tip: TipPlacement, frame: TableFrame) {
        let R = frame.ballRadius
        let worldUp = SIMD3<Float>(0, 1, 0)
        let centre = frame.world(ball, height: R)
        let along = simd_normalize(frame.direction(direction))
        // Right as the player sees it from behind the cue, the same right the solver uses for tipSide: (d.y, -d.x).
        let right = simd_normalize(frame.direction(Vec2(direction.y, -direction.x)))

        let (pitch, restDistance) = Self.pose(elevation: elevation, contactHeight: R + tipUp, rest: rest, cue: cue)
        // Forward is the way the cue drives (down toward the cloth when raised); back runs from the tip to the butt.
        let back = -(along * cos(pitch)) + worldUp * sin(pitch)
        // The tip's "up" leans with the cue, as in the solver's raised strike, so the contact point matches it.
        let cueUp = along * sin(pitch) + worldUp * cos(pitch)
        let contact = centre + right * tipSide + cueUp * tipUp

        let distance: Float
        switch tip {
        case .behindContact(let d):
            distance = d
        case .pulledBack(let pull):
            // The support (the rest's cradle, or the bridge hand) is this far behind the centre on the cloth plan, so
            // support / cos(pitch) along the cue's axis; the tip's furthest point stops bridgeTipClearance short of
            // it, and never comes nearer the ball than the 1.7-radius gap of a cue at rest.
            let support = rest ? restDistance : pull.handBridge
            let nearest = R * 1.7
            let furthest = max(nearest, support / max(cos(pitch), 0.05) - Self.bridgeTipClearance)
            distance = nearest + pull.fraction * min(pull.reach, furthest - nearest)
        }
        cueHolder.position = contact + back * distance
        cueHolder.orientation = Self.facing(back)
        showCue(cue)
        placeShadow(tip: cueHolder.position, back: back, frame: frame)

        restHolder.isEnabled = rest
        if rest {
            // Centred under the cue's line (the side offset moves the cue sideways), standing on the cloth, its handle
            // running straight back under the cue.
            var cradle = centre - along * restDistance + right * tipSide
            cradle.y = 0
            restHolder.position = cradle
            restHolder.orientation = Self.facing(-along)
        }
    }

    /// Lay the soft shadow on the cloth under the front of the cue: centred under the middle of its first
    /// `shadowLength`, as wide as a cue near the tip plus the lamp's soft spread, and paler the higher that stretch of
    /// cue rides above the cloth (a raised cue throws a weaker, broader shadow).
    private func placeShadow(tip: SIMD3<Float>, back: SIMD3<Float>, frame: TableFrame) {
        var flat = SIMD3<Float>(back.x, 0, back.z)
        guard simd_length(flat) > 1e-4 else { shadow.isEnabled = false; return }
        flat = simd_normalize(flat)
        shadow.isEnabled = true
        let middle = tip + back * (Self.shadowLength * 0.5)
        shadow.position = SIMD3(middle.x, 0.0009, middle.z)
        shadow.orientation = Self.facing(flat)
        // 3.5 cm wide: the cue's 13 mm plus the soft spread either side under a broad lamp.
        shadow.scale = SIMD3(0.035, 1, Self.shadowLength)
        let height = max(0, middle.y)
        shadow.components.set(OpacityComponent(opacity: 1 / (1 + height / 0.06)))
    }

    /// The rotation that turns a model's +Z to `back` while keeping its +Y as close to world up as possible. Built from
    /// a basis rather than simd_quatf(from:to:), which is undefined when `back` is exactly opposite +Z (a real aim).
    private static func facing(_ back: SIMD3<Float>) -> simd_quatf {
        let z = simd_normalize(back)
        var x = simd_cross(SIMD3<Float>(0, 1, 0), z)
        if simd_length_squared(x) < 1e-8 { x = SIMD3(1, 0, 0) }        // straight up or down: never for a cue
        x = simd_normalize(x)
        let y = simd_cross(z, x)
        return simd_quatf(simd_float3x3(columns: (x, y, z)))
    }

    // MARK: Materials

    /// A physically based material in the table's style (see TableBuilder.pbr), with an optional clear lacquer coat.
    private static func pbr(_ c: PlatformColor, rough: Float, metal: Float = 0, coat: Float = 0, coatRough: Float = 0.1) -> PhysicallyBasedMaterial {
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: c)
        m.roughness = .init(floatLiteral: rough)
        m.metallic = .init(floatLiteral: metal)
        if coat > 0 {
            m.clearcoat = .init(floatLiteral: coat)
            m.clearcoatRoughness = .init(floatLiteral: coatRough)
        }
        return m
    }

    /// Every finish on the cues and the rest, by part name. Colour, roughness and metalness are the art's own, as
    /// export_equipment.py prints them (FINISH lines): the Principled colour turned from linear light into sRGB, and
    /// for a grained wood the mean of its grain's two colours (the grain itself is a Blender texture that does not
    /// export). The clear coat is added here, as the old cue had it: the woods and the enamel are lacquered (a full,
    /// glassy coat on the dark woods, a lighter one on the oiled maple), so they catch the lamp as a real cue does;
    /// leather, linen, rubber and the satin metals are left bare. Built on each call (once per model at load), as the
    /// old cue's and bridge's material tables were.
    private static var finishes: [String: PhysicallyBasedMaterial] { [
        "OilFinishedMaple": pbr(rgba(0.812, 0.650, 0.437), rough: 0.30, coat: 0.6, coatRough: 0.16),
        "Rosewood": pbr(rgba(0.433, 0.217, 0.131), rough: 0.30, coat: 1, coatRough: 0.07),
        "OxbloodMaple": pbr(rgba(0.525, 0.126, 0.203), rough: 0.30, coat: 1, coatRough: 0.07),
        "FiguredAmber": pbr(rgba(0.715, 0.463, 0.183), rough: 0.30, coat: 1, coatRough: 0.07),
        "BlackPlum": pbr(rgba(0.450, 0.211, 0.297), rough: 0.26, coat: 1, coatRough: 0.07),
        "Ebony": pbr(rgba(0.093, 0.112, 0.128), rough: 0.30, coat: 1, coatRough: 0.07),
        "SatinCarbon": pbr(rgba(0.195, 0.212, 0.236), rough: 0.31, coat: 0.4, coatRough: 0.2),
        "CobaltEnamel": pbr(rgba(0.128, 0.313, 0.742), rough: 0.20, metal: 0.40, coat: 1, coatRough: 0.05),
        "IvoryComposite": pbr(rgba(0.931, 0.891, 0.780), rough: 0.30),
        "CreamInlay": pbr(rgba(0.921, 0.843, 0.687), rough: 0.22, metal: 0.12),
        "ChalkedLeather": pbr(rgba(0.323, 0.506, 0.547), rough: 0.83),
        "ForestLinen": pbr(rgba(0.201, 0.377, 0.284), rough: 0.68),
        "SatinBrass": pbr(rgba(0.843, 0.650, 0.357), rough: 0.27, metal: 0.83),
        "Rubber": pbr(rgba(0.143, 0.147, 0.147), rough: 0.75),
    ] }

    /// Give every named part its material. The name may sit on the mesh itself or on a parent transform with the mesh
    /// below it, so the material goes to every model at or under the named entity (stopping at another named part).
    private static func dress(_ model: Entity, _ materials: [String: PhysicallyBasedMaterial]) {
        let names = Set(materials.keys)
        for (name, material) in materials {
            guard let part = model.findEntity(named: name) else { continue }
            paint(part, material, skipping: names.subtracting([name]))
        }
    }

    private static func paint(_ entity: Entity, _ material: PhysicallyBasedMaterial, skipping others: Set<String>) {
        if var model = entity.components[ModelComponent.self] {
            // One copy per material slot, so a part exported with several sub-meshes keeps them all.
            model.materials = [any Material](repeating: material, count: max(1, model.materials.count))
            entity.components.set(model)
        }
        for child in entity.children where !others.contains(child.name) {
            paint(child, material, skipping: others)
        }
    }

    /// Point every model under `entity` at the scene's lamp reflection, as TableBuilder.installEnvironment does.
    private static func receiveLight(_ entity: Entity, from light: Entity) {
        if entity.components.has(ModelComponent.self) {
            entity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: light))
        }
        for child in entity.children { receiveLight(child, from: light) }
    }
}
