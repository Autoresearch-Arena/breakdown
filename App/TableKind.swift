// Author: Claude Opus 5.5 High
// Edited: GPT 6.2 Astra High, 21-November-2026, shared higher player launch-speed limits.
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 polish P2: five-pin's menu symbol is a cluster of dots, not a
//          bowling figure.)
// Date: 21-November-2026
// PURPOSE: Which table the game is played on: the standard nine-foot pool table, bumper pool, Italian five-pin
//          billiards (cinque birilli) or bar billiards. Picked from the Surface menu's "Tables" section and kept in
//          UserDefaults under "optionTable". A table is, like a surface, a set of numbers written into PoolParameters
//          before a shot is solved (size, ball size, pockets on or off, posts, pins, holes in the bed) plus a start
//          layout, a default shot and the extra 3D props drawn on it. The standard table changes nothing (so every pool
//          shot hashes exactly as before). Each other table lives in its own file under App/Tables/ as an enum that
//          conforms to TableDefinition; this file only dispatches to it. Order of application in
//          ShowpieceModel.solve: the table first, then the surface (which only changes friction and bounce numbers).
//          The contract for the table files is App/Tables/README.md.
// SRP/DRY check: Pass - checked PlaySurface.swift (same pattern: an enum of choices that writes numbers into the
//          parameters); the table geometry itself stays in the solver and TableBuilder, the per-table data in App/Tables.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import RealityKit

/// What every table file in App/Tables/ must provide (all static: a table is a fixed description, not a value).
/// Units are metres, kilograms, metres per second and degrees; positions are in the solver's table plan (x along the
/// length from 0 to L, y across from 0 to W, origin at a corner of the playing surface, between the cushion noses).
protocol TableDefinition {
    /// Playing surface between the cushion noses.
    static var tableSize: (length: Double, width: Double) { get }
    /// The balls this game uses (all sixteen slots use the same size).
    static var ballRadius: Double { get }
    static var ballMass: Double { get }
    /// False when the table has no edge pockets: the cushions then run the full length of every side.
    static var pocketsEnabled: Bool { get }
    static var posts: [Post] { get }
    static var pins: [Pin] { get }
    static var bedHoles: [BedHole] { get }
    /// Exactly sixteen positions: index 0 is the cue ball, balls the game does not use are NextShot.offTable.
    static var startLayout: [Vec2] { get }
    /// The shot the aim starts on, and the shot "Watch the break" plays on this table: aim in degrees counter-clockwise
    /// from the +x (length) axis, power as launch speed in m/s, clamped to the player’s shot range when loaded.
    static var defaultShot: (aimDegrees: Double, power: Double) { get }
    /// Material for each named part of the props (the names the props builder and the Blender model use).
    static var partLooks: [String: TablePartLook] { get }
    /// Any other number this table changes (cushion bounce, for example). Runs after everything above is written.
    static func tune(_ p: inout PoolParameters)
    /// The table's extra 3D props (posts, pins, hole rims, markings, the model from Blender). Built once per table;
    /// returned as one entity that TableScene puts under the warm table group, so it fades with the table in the Lens.
    @MainActor static func makeProps(_ context: TablePropsContext) -> Entity
}

/// What a props builder gets: the frame that maps table plan to world, the table as solved (TableSpec carries the
/// posts, pins and bed holes), and the entity that carries the scene's lamp reflection, for models loaded later.
struct TablePropsContext {
    let frame: TableFrame
    let table: TableSpec
    let lightSource: Entity
}

/// A part's finish, in the same terms TableBuilder and CueRig use: colour (0 to 1), roughness, metal, clear coat.
struct TablePartLook: Sendable {
    var color: (r: Double, g: Double, b: Double)
    var roughness: Float
    var metallic: Float = 0
    var clearcoat: Float = 0
    var clearcoatRoughness: Float = 0.1
}

enum TableKind: String, CaseIterable, Identifiable, Sendable {
    case standard, bumperPool, fivePin, barBilliards

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: return String(localized: "Pool table")
        case .bumperPool: return String(localized: "Bumper pool")
        case .fivePin: return String(localized: "Five-pin billiards")
        case .barBilliards: return String(localized: "Bar billiards")
        }
    }

    /// One plain sentence for the picker, without figures.
    var summary: String {
        switch self {
        case .standard: return String(localized: "The nine-foot table with six pockets.")
        case .bumperPool: return String(localized: "A small table with rubber bumpers and a cup at each end.")
        case .fivePin: return String(localized: "No pockets: knock down the little pins in the middle.")
        case .barBilliards: return String(localized: "Holes in the bed, and pegs that must not fall.")
        }
    }

    /// SF Symbol for menus. Each is a plain shape, never a figure or a person. Five-pin's is a small cluster of dots
    /// for the pins (SF Symbols 3, so on every iOS 26 and macOS 26 system); the closer five-dot cross is the menu's
    /// Play button (TitleScreen) and the square grids are bumper pool's and the cork surface's, so it is not reused.
    var symbol: String {
        switch self {
        case .standard: return "rectangle"
        case .bumperPool: return "circle.grid.2x2"
        case .fivePin: return "circle.hexagongrid"
        case .barBilliards: return "smallcircle.filled.circle"
        }
    }

    /// The table file behind this kind; nil for the standard pool table, which is the solver's own default.
    var definition: (any TableDefinition.Type)? {
        switch self {
        case .standard: return nil
        case .bumperPool: return BumperPoolTable.self
        case .fivePin: return FivePinTable.self
        case .barBilliards: return BarBilliardsTable.self
        }
    }

    /// Write this table into the parameters. The standard table leaves them untouched.
    func apply(to p: inout PoolParameters) {
        guard let d = definition else { return }
        p.tableLength = d.tableSize.length
        p.tableWidth = d.tableSize.width
        p.ballRadius = d.ballRadius
        p.ballMass = d.ballMass
        p.pocketsEnabled = d.pocketsEnabled
        p.posts = d.posts
        p.pins = d.pins
        p.bedHoles = d.bedHoles
        d.tune(&p)
    }

    /// Default parameters with this table written in (no surface): for layouts, respotting and reading numbers.
    var parameters: PoolParameters {
        var p = PoolParameters()
        apply(to: &p)
        return p
    }

    /// The table's own start layout (sixteen positions); nil for the standard table, which racks instead.
    var startLayout: [Vec2]? {
        guard let d = definition else { return nil }
        let l = d.startLayout
        // The aim and shoot paths all need sixteen balls; a short or long list is padded or cut, never trusted.
        if l.count == 16 { return l }
        return Array((l + [Vec2](repeating: NextShot.offTable, count: 16)).prefix(16))
    }

    var defaultShot: (aimDegrees: Double, power: Double) { definition?.defaultShot ?? (0, 3) }

    /// The opening shot for this table: the showpiece break on the pool table, the default shot from the start layout
    /// on any other.
    var openingShot: ShotInput {
        guard let start = startLayout else { return Rack.showpieceBreak() }
        let a = defaultShot.aimDegrees * Double.pi / 180
        return NextShot.shot(from: start, direction: Vec2(cos(a), sin(a)), speed: defaultShot.power, tipUp: 0, tipSide: 0,
                             seed: 2026, parameters: PoolParameters())
    }

    /// The table's props, or nil for the standard table.
    @MainActor func makeProps(_ context: TablePropsContext) -> Entity? {
        definition?.makeProps(context)
    }

    static let storageKey = "optionTable"

    /// The table last chosen on this device; the pool table when none has been chosen (or the value is unknown).
    static var stored: TableKind {
        UserDefaults.standard.string(forKey: storageKey).flatMap(TableKind.init(rawValue:)) ?? .standard
    }
}

extension TableDefinition {
    /// Most tables change nothing beyond the fields above.
    static func tune(_ p: inout PoolParameters) {}
}

/// Shared placeholder values for table files that are not filled in yet: a standard-size table, regulation balls, the
/// cue ball on the head spot and one object ball on the foot spot. Table builders replace every use of these.
enum TablePlaceholder {
    static let size = (length: 2.54, width: 1.27)
    static let ballRadius = 0.028575
    static let ballMass = 0.170
    static var layout: [Vec2] {
        var l = [Vec2](repeating: NextShot.offTable, count: 16)
        l[0] = Vec2(size.length * 0.25, size.width * 0.5)
        l[1] = Vec2(size.length * 0.75, size.width * 0.5)
        return l
    }
}
