# Other tables: the contract for the table files

Author: Claude Opus 5.5 High, 21-November-2026

Purpose: what a table builder fills in to bring bumper pool, five-pin billiards (Italian, *cinque birilli*) or bar
billiards to life. The shared groundwork (solver features, menu, storage, scene rebuild, pin toppling, captions) is
done. Each table is one Swift file here, filled in by one builder. Scoring rules come later: do not build scoring.

## 1. What you may edit (and nothing else)

| Table | Swift file | Blender script | Model |
|---|---|---|---|
| Bumper pool | `App/Tables/BumperPoolTable.swift` | `Tools/blender/make_bumper_pool.py` | `App/Models/BumperPool.usdz` |
| Five-pin billiards | `App/Tables/FivePinTable.swift` | `Tools/blender/make_five_pin.py` | `App/Models/FivePin.usdz` |
| Bar billiards | `App/Tables/BarBilliardsTable.swift` | `Tools/blender/make_bar_billiards.py` | `App/Models/BarBilliards.usdz` |

Edit ONLY your own three paths. Not `TableKind.swift`, `TableProps.swift`, `TableBuilder.swift`, `TableScene.swift`,
BreakdownCore, the string catalog, the CHANGELOG or the version. If you need something from shared code, say so in your
report instead of editing it. Three builders work at the same time; touching a shared file breaks the merge.

Do not run `xcodebuild` or boot a simulator: the app is compiled once after all three tables are merged. Write code that
compiles against the types below exactly as they are. You may run the Blender script (it is how the model is made).

House rules: every file you write or edit starts with the CODING_STANDARDS header (Author / Date / PURPOSE / SRP-DRY
check, and an `Edited:` line on a file you change; Python as `#` comments). Credit yourself by model and effort, e.g.
"Claude Opus 5.5 High". New player-facing text goes through `String(localized:)`, in English only, few and short
(a later step translates). Big files never go on the internal drive; build output only under
`/Volumes/Team 4TB/breakdown-build/`.

## 2. Coordinates and units

- Metres, kilograms, seconds, metres per second, degrees.
- **Table plan** (everything in your Swift file except the props' world placement): origin at one corner of the playing
  surface, measured between the cushion noses. `x` runs along the length from `0` to `L`, `y` across from `0` to `W`.
  This is the solver's frame (`Vec2(x, y)`).
- **World** (RealityKit, for props): `context.frame.world(planPoint, height: h)` gives the world point. The table is
  centred on the origin, `+Y` is up, the cloth is at `y = 0`, world `x = plan x - L/2`, world `z = -(plan y - W/2)`
  (plan `+y` is world `-z`). `context.frame.direction(planVector)` turns a plan direction into a world one.
- **Edge pockets**, when `pocketsEnabled` is true, are pocket indices 0 to 5: corners `(0,0)`, `(L,0)`, `(0,W)`,
  `(L,W)`, then sides `(L/2,0)`, `(L/2,W)`. **Bed hole `j`** is always pocket index `6 + j`, with or without the edge
  pockets (`TableSpec.holeCenter(pocket:)` finds either).
- `TableBuilder` draws the warm table at your `tableSize` for you: cloth, cushions (cushion depth 0.045 m, nose top
  0.040 m), the wooden rail (0.155 m wide, top at 0.060 m), legs and floor. With `pocketsEnabled = false` the cushions
  run each whole side with mitred corners and no pockets are cut. Your bed holes are already cut through the cloth, with
  a well wall and black floor 0.12 m deep. Do not draw any of that again: your props are what sits on or in it.

## 3. The members your enum must fill (protocol `TableDefinition`, in `App/TableKind.swift`)

Every member is `static`. Replace every `TablePlaceholder` use; the placeholders are a standard pool table.

| Member | Type | Meaning |
|---|---|---|
| `tableSize` | `(length: Double, width: Double)` | Playing surface between the cushion noses, metres. Real dimensions of the real game. |
| `ballRadius`, `ballMass` | `Double` | The game's balls (all sixteen slots use the same size). Drawn balls are scaled to it. |
| `pocketsEnabled` | `Bool` | `false` for a table with no edge pockets (all three of these games, as far as we know). |
| `posts` | `[Post]` | Fixed round obstacles: `Post(center:radius:restitution:friction:height:)`. Bumpers, mushroom bases. |
| `pins` | `[Pin]` | Standing pins: `Pin(center:radius:mass:restitution:height:)`. Five-pin skittles, bar-billiards pegs. |
| `bedHoles` | `[BedHole]` | Holes in the bed: `BedHole(center:radius:captureRadius:)`. Bar-billiards holes, bumper-pool cups. |
| `startLayout` | `[Vec2]` | Exactly 16 positions. Index 0 is the cue ball (the ball the cue strikes). Unused balls at `NextShot.offTable`. |
| `defaultShot` | `(aimDegrees: Double, power: Double)` | The shot ready to play: aim counter-clockwise from plan `+x`, launch speed 0.5 to 8 m/s. "Watch the break" plays it. |
| `partLooks` | `[String: TablePartLook]` | Finish per named part (colour 0 to 1, roughness, metallic, clear coat). |
| `tune(_:)` | `(inout PoolParameters)` | Optional; a default that does nothing exists. Any other number, e.g. `p.cushionRestitution`. Runs after the fields above. |
| `makeProps(_:)` | `@MainActor (TablePropsContext) -> Entity` | The table's extra 3D props as one entity. See section 5. |

How the solver treats each feature (all exact, event-driven, scrubbable):

- **Post**: a ball's centre may not come closer than `ballRadius + radius` to the post's centre. The ball rebounds with
  the post's own `restitution` and `friction` (the cushion model with the post's normal). A ball flying higher than
  `height` (its lowest point above the post's top) passes over. Recorded as a cushion event with edge `.post` and
  `feature` = post index; the Lens captions it "The post throws it back".
- **Pin**: `radius` is the contact radius at the height of a ball's centre (for a shaped skittle, its radius at height
  `ballRadius`). The first ball to touch it knocks it down: the ball loses `(1 + e) * v_n * m_pin / (m + m_pin)` along
  the line of centres, the pin is out of play for the rest of the shot, and a `pinDown` event records pin, time and ball.
  Default `mass` is 0.017 kg (a tenth of a pool ball). A ball flying higher than `height` passes over.
  `Timeline.pinFalls`, `pinDownTime` and `pinIsDown(_:at:)` say which pins fell and when.
- **BedHole**: works like a pocket. A ball on the cloth whose centre comes within `captureRadius` of `center` drops
  in. `radius` is the drawn hole; make `captureRadius` smaller than `radius` when the ball must be over the hole rather
  than just touching its edge.
- Balls only ever rest and roll on the bed; nothing models a ball rolling back out of a hole or a pin falling onto a
  ball.

Notes that bite:

- The chosen surface (ice, sand...) is applied after your table and changes friction numbers; two surfaces (tournament,
  dive bar) also change `cushionRestitution` and `cushionFriction`. Posts keep their own numbers.
- A scratched cue ball is put back at `(L/4, W/2)`, stepped toward `x = 0` if a ball is there. If that spot is inside a
  post or over a hole on your table, put your posts and holes elsewhere or report it.
- Trick shots always use the pool table; your table is never used for them.
- Keep posts, pins and holes inside the playing surface and apart from each other.
- The shared table code that draws no-pocket cushions, bed holes, the rebuilt table and pin toppling has only been
  compiled, never run with real data (the stubs were empty). If the bed or a hole draws wrong, report it with your
  numbers; do not work around it in your file.
- A toppled pin is lifted by its `radius` as it lies down. For a shaped skittle whose contact radius is smaller than its
  belly, it may sit a little into the cloth; fine for now, mention it if it shows.
- The aim guide line is a fixed 1.4 m long (shared code); on a small table it runs past the far end. Known, not yours.
- A pin knocked down has no sound or haptic yet; a post rebound sounds like a cushion.
- This file is kept out of the app bundle by a membership exception in the project file; do not move it.

## 4. Coding the members (example shape)

```swift
static let tableSize = (length: 1.2, width: 0.6)              // real numbers, with the source in a comment
static let pocketsEnabled = false
static let posts: [Post] = [Post(center: Vec2(0.3, 0.3), radius: 0.02, restitution: 0.8, friction: 0.15, height: 0.04)]
static var startLayout: [Vec2] {
    var l = [Vec2](repeating: NextShot.offTable, count: 16)
    l[0] = Vec2(0.2, 0.3)                                     // cue ball
    l[1] = Vec2(0.9, 0.3)
    return l
}
```

Put the source of every real dimension (rule book, manufacturer, federation) in a comment next to it.

## 5. Props: how to build and name them

`makeProps(_ context: TablePropsContext) -> Entity` runs once each time your table is built (when the player picks it,
or the shot on screen moves onto it). `context.frame` maps plan to world, `context.table` is the solved `TableSpec`
(it carries `posts`, `pins`, `bedHoles` exactly as the solver used them, so build from these), `context.lightSource`
carries the lamp reflection for models loaded later. Return one entity; everything visible goes under it.

Rules:

- **Pins** must be entities named `"pin-<k>"` (k = index in `pins`), with the origin at the pin's base centre on the
  cloth and the pin standing along `+Y`, the geometry as children above the origin. `TableScene` finds them by name
  (also when added later, after a model loads) and topples each one flat over 0.15 s from its recorded time, along the
  direction it was pushed. Do not animate pins yourself.
- Name posts `"post-<k>"` and anything else after your part names. Nothing reads post names yet; they help debugging.
- Props sit on or above the cloth (`y >= 0`) or inside your bed holes (down to `-0.12`).
- Helpers in `App/TableProps.swift` (use, do not edit):
  - `TableProps.plainPost(index:_:frame:look:)` and `TableProps.plainPin(index:_:frame:look:)`: plain cylinders that
    already follow the naming and origin rules. Good as a first pass or a fallback.
  - `TableProps.loadModel(named:looks:into:lightSource:place:)`: loads `<name>.usdz` from the bundle in the
    background, dresses named parts from `looks`, calls `place` (position it, or clone parts out of it), adds it under
    the parent and hooks up the reflection. A missing model is logged and skipped, so the table still works.
  - `TableProps.dress(_:looks:)` and `TableProps.material(_:)` for your own code.
- Typical pattern for pins from a model: export one pin as a part named e.g. `"FivePinPin"` with its base centre at the
  origin; in `place`, for each `k` clone it (`clone(recursive: true)`), wrap it in an `Entity` named `"pin-<k>"`
  positioned at `context.frame.world(pins[k].center)`, add that under the props entity, then remove the original.

## 6. Making the model in Blender

Read `Tools/blender/make_cue.py` and `make_bridge.py` first and follow the same pattern:

- Run headless: `/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup --python Tools/blender/make_<table>.py`.
  Deterministic: same code, same file.
- Build geometry directly in final coordinates: RealityKit frame, `+Y` up, metres, cloth at `y = 0`. Either author the
  whole set in table-world coordinates (table centred on the origin, as section 2), or author each reusable part at its
  own origin and place copies in Swift; say which in the script header.
- Every part is a named object (object and mesh share the name, so the USD prim carries it). Prefix part names with
  the table (`BumperPool...`, `FivePin...`, `BarBilliards...`) and list the same names in `partLooks`.
- Export geometry only (no materials, cameras or lights): write a `.usdc`, stamp it Y-up and metres with pxr, pack the
  `.usdz` to `App/Models/<Name>.usdz` (file name without extension is what `loadModel(named:)` takes).
- Read the file back with pxr and check every contract number (sizes, base on `y = 0`, part names present); exit
  non-zero if any check fails.
- Keep it light: a few thousand triangles at most. `App/Models` is bundled automatically.

## 7. What the shared groundwork already does (do not redo)

- Solver: posts, pins, bed holes, `pocketsEnabled` (BreakdownCore, tested).
- `TableKind` (menu entry, title, summary, symbol, storage under `optionTable`), the Tables section in the Surface menu
  on iPhone and Mac, switching re-solves and resets the layout to your `startLayout` with your `defaultShot` ready.
- The scene rebuilds the warm table at your size, cuts your bed holes, scales the balls, redraws the Lens grid with
  your holes, adds your props under the table group (so they fade in the Lens) and topples fallen pins.
- Captions for a post rebound and a pin knocked down. A future pool-only mode (Behind the 8-ball) must use the pool
  table the way trick shots do (`ShowpieceModel.physicsTable`).
