# Breakdown: Product and Build Spec

Author: Claude Opus 5.5 Medium
Date: 02-November-2026
PURPOSE: This document decides what "Breakdown" is and how we build it. Part One is the short plain-language pitch for the Boss. Part Two is the build spec for whoever writes the code: pillars, architecture, physics design, the Physics Lens, controls, modes, feel, platform setup, tests, milestones, risks, and the later scan-and-smash phase. It merges four research notes (billiards physics, Apple platform verification, game and Lens design, scan-to-smash) and settles every conflict between them.
Status: final draft for the Boss
Reviewed: API check against local SDKs, physics check, Boss-fit check

---

# PART ONE: For the Boss

## What you are really asking for

You are not asking for a pool game. You are asking for a physics engine you can watch thinking. Pool is simply the cleanest place to show that: a handful of balls, crisp collisions, and real skill that comes from real physics. So pool is scene one.

The signature move is the melt. You watch a normal break, then the table dissolves into arrows, paths and equations, and you see why the balls did what they did. We call that layer the Lens. On the pool table, every number it shows is one the engine actually computed. Later, on scanned rooms, some numbers are estimates and are labelled that way. Some of the glow and motion is decoration, and the game says so in its own notes.

The scan-and-smash idea is the same Lens pointed somewhere else. Instead of a pool table, it looks at a model of your own room built from the phone's depth scanner, and you throw things at it while the arrows and equations show what happens. Learn the Lens on a pool table, then point it at the world. That continuity is the product.

This Mac builds and runs real iPhone and Mac apps, so there is no web detour. We are making the real thing from the first day.

## What the first minute feels like

The app opens into a quiet room. A lamp comes on over a table. A cue strokes once and the rack explodes, loud and beautiful, and at least one ball drops into a pocket.

Then time catches. The sound drops underwater, the light cools, and the balls hang in the air. The felt does not fade; it runs off the table like ink, leaving glowing spheres on a dark grid. A break is chaos, so the Lens picks a hero: it follows the cue ball and the first two balls it strikes, and quiets the rest. Time resumes slowly and the math blooms one idea at a time: the cue ball gives its push away, and trails change colour as balls stop sliding and start rolling.

Then everything runs backwards, the table rebuilds itself, and the screen says "Now you." Right away comes one short, clean shot, a draw shot where the cue ball comes back, as the first thing you can actually learn from. Then you take your own break, and afterward the Lens offers to take apart your shot.

## What makes it a game

You learn techniques one at a time: stopping the cue ball dead, rolling it forward, pulling it back, bending a shot, jumping a ball. Each lesson is a few minutes: watch a perfect shot melt into its math, try guided shots with less and less help, then try one with none. Every control is open in free play from the very start. Passing a lesson earns badges, cosmetics and guided help, never access to the controls.

Beyond the lessons there are trick-shot puzzles, a daily challenge that is the same for everyone, and a break challenge. The best loop is predict the shot: you guess where the balls will end up, then the engine plays it and the Lens lays your guess over the truth. After any shot you can nudge your aim a hair and see a ghost of the alternate future.

Rewards are cosmetic and about understanding. Nothing for sale changes the physics.

## What comes later

Once the table is solid, we add scan and smash. You point your phone at a corner of your room or a few objects, the game turns them into things with weight and material, and you throw a ball or swing a hammer at them. Your living room melts into arrows and equations the same way the table did. We build nothing for scanning until the table is done.

## What you will see, and in what order

The first build opens on the cold open: the break, the freeze, the melt, the rewind, and a simple drag-to-aim, release-to-strike break of your own, on iPhone and on this Mac, with sound. The next builds add full shot control with spin, then deeper Lens tools and the ghost futures, then the lessons.

## Nothing to decide right now

We assume you play on a Pro phone, since only those have the depth scanner, and we will confirm when scanning is near. To put the app on your own phone we will eventually need access to your Apple developer account; that is a task for later, not a decision.

You can stop reading here. Everything below is for the builders.

---

# PART TWO: Build spec

## 1. Pillars

1. On the pool table the Lens draws only what the solver computed, or values it labels as derived from solver-computed fields. Decorative effects (glow, grid warp, rising grid) are marked as decoration in the visual language. Every arrow, caption and equation traces to a recorded event.
2. Deterministic, recorded, scrubbable. A shot is simulated once into a timeline. Playback, slow motion, reverse and the Lens all read the timeline.
3. Math appears at the moment it matters, then leaves. One hero ball, one equation, one caption at a time.
4. Teach by consequence. The game never draws the perfect line; it shows why your line did what it did.
5. One number drives sight, sound and touch. An impact's impulse feeds the burst ring, the click and the haptic.
6. Original. Warm world, cold truth: teal felt and ceramic balls under one lamp; the Lens is a dark blueprint layer. No borrowed names or art.
7. Real Apple app, one codebase for iPhone and Mac.

## 2. Architecture

### 2.1 Decisions

- We own the billiards solver in pure Swift. Generic rigid-body engines cannot give believable spin, throw, cloth friction and cushion behaviour, and the Lens can only annotate quantities we computed.
- RealityKit is used for rendering only. RealityKit physics stays off: no physics body components on balls. Our own component carries each ball's identity, and our own system sets entity transforms from the timeline each frame.
- The Lens is built in-scene (conflict resolved: the game note preferred a separate overlay layer, the Apple note preferred in-scene meshes). Decision: in-scene dynamic meshes, because depth and occlusion are correct and it behaves the same on iPhone and Mac. Each Lens layer is a separate entity subtree so it can be toggled and composited independently, and SwiftUI is used only for chrome (buttons, scrubber strip, ball-face widget, captions).
- Playback never re-simulates. Everything downstream reads the recorded timeline.

### 2.2 Modules

Pure-Swift modules live in one local Swift package named BreakdownCore, with no UI or RealityKit imports, so they run under the package test command on the Mac. The app target holds everything that touches Apple frameworks. Milestone one needs only the first three package modules; the rest are added when their milestone arrives.

- BreakdownPhysics (package): the event-driven billiards solver. Single responsibility: given a shot input, produce a timeline. Double only, no libm anywhere in the module (see 3.5), no threads inside a shot.
- BreakdownLensModel (package): the engine-agnostic event model. Single responsibility: define the versioned stream of bodies, poses, contacts, forces, quantity annotations and energy ledger entries, each tagged with its producer. The pool solver emits it directly.
- BreakdownTimeline (package): recorder and playback. Single responsibility: store outcomes (segments, events, orientation checkpoints, and for pool also the input), evaluate state at any time, hash the timeline, and read and write a versioned file.
- BreakdownLens (app target): turns the event stream plus a playback time into Lens visuals and chooses what to show under the density rules. It owns caption templates and the layer budget.
- BreakdownScene (app target): the renderer. Builds the table and balls, owns the ball component and the playback system, owns the camera.
- BreakdownInput (app target): touch and Mac controls, aim, power, tip offset, elevation, and the assist levels.
- BreakdownFeel (app target): audio and haptics, driven by impact events.
- BreakdownApp (app target): the app shell, scene flow (cold open, lessons, free play), settings, persistence.

Deferred to milestone seven, on purpose: the shared materials package, the scene description type, the simulation-backend protocol and the capability object that answers whether depth-scanner features exist. The Lens depending only on the event stream is the one door we keep open now.

### 2.3 Data flow (text diagram)

```
 Input (aim direction, power, tip offset, elevation, seed)
        |
        v
 ShotInput  --->  BreakdownPhysics  (background queue, runs full shot in milliseconds)
                        |
                        v
                  Timeline (segments + events + orientation checkpoints + input + parameter hash)
                        |
          +-------------+----------------+-----------------+
          v             v                v                 v
   Playback clock   Lens event      Recorder/file     What-if runs
   (rate, scrub,    stream          (Physics Journal,  (perturb input,
    freeze)         (LensModel)      clips, challenges) run again, ghost)
          |             |
          v             v
   Scene system    Lens layers (trails, arrows, spin rings,
   sets ball       bursts, equations, captions)
   transforms           |
          \            /
           v          v
        RealityKit view  -->  Feel (sound, haptics) fires on impact events
                              as the playback clock crosses them
```

Aiming preview reuses the same solver with a short horizon. The replay clock is the only moving part at runtime.

### 2.4 Contracts that keep the door open

1. The Lens depends only on the event stream, never on pool types.
2. The recorder stores outcomes, not just inputs. Pool additionally stores its input because it is deterministic; smash scenes cannot rely on that.
3. Time is seconds with an explicit time base, and every event names its producer so the Lens knows how far to trust a number.

## 3. Physics design

This section is the decision record. The numbers below are the ones we commit to. Confidence labels: verified (derived and checked), sourced (published, check original before hard-coding), calibrate (a guess to tune against the validation suite in 9.1b).

### 3.1 Model

- Event-driven, not fixed timestep. A shot is a list of closed-form polynomial segments per ball plus a list of events with exact impulse data. Position, velocity and angular velocity are evaluated in closed form at any time, so scrubbing, reverse and slow motion are exact for those, tunnelling is impossible, and every contact has an exact time for the Lens.
- State per ball: position, velocity, angular velocity in three dimensions, orientation (a unit quaternion), a phase tag, and segment start time. The table plane is horizontal and up is the third axis.
- Orientation is not available in simple closed form: during sliding the angular acceleration has a fixed direction but the initial angular velocity generally does not, so the rotation axis changes through the segment and rotations do not commute. Decision: the timeline records the orientation at each segment start, and a deterministic orientation evaluator integrates angular velocity with a fixed substep count from the segment start (documented small-angle approximation allowed for rolling). Orientation is continuous across segment boundaries, affects rendering and the Lens spin ring only, never feeds back into the solver, and so does not need bit-exact determinism.
- Phases: sliding, rolling, spinning in place, stationary, airborne.
- Spin, throw, squirt, masse and jump are not special cases. They fall out of one state vector, one sliding equation and one impact routine.

Phase transition table (R ball radius, m mass, mu cloth sliding friction, g gravity, z the up axis):

| Transition | Condition and time | Notes |
|---|---|---|
| Contact-point slip | u = v + omega x (-R z) | slip velocity at the cloth |
| Sliding | slip decelerates at 7 mu g / 2 along minus u-hat; sliding time t = 2 abs(u0) / (7 mu g) | centre path is a parabola; angular acceleration 5 mu g / (2 R) about the axis z x u-hat |
| Sliding to rolling | abs(u) reaches zero | final rolling speed = (5/7) v_tangent + (2/7) R times the contact-aligned spin component; the no-spin case gives five sevenths of the original speed (verified) |
| Rolling | constant deceleration c_r g of the centre, spin follows velocity | see 3.4 for c_r |
| Rolling to spinning in place | speed reaches zero | |
| Spinning to rest | vertical spin reaches zero | |
| Any state to airborne | vertical velocity positive after an impact | |
| Airborne to sliding | landing, a quadratic root, uses the ball-table impact | |

Vertical-axis spin decays at constant angular deceleration continuously through all non-airborne phases, including while sliding and rolling. Position, velocity and spin must be continuous at every segment boundary (test 17).

### 3.2 Events

Event kinds, each carrying time, balls involved, pre- and post-state, contact point, normal and tangent, normal and friction impulses, slip velocity and energy split:

- phase transition (slide to roll, roll to spin, to rest)
- ball-ball impact
- cushion impact, including knuckles and pocket jaw tips
- ball-table landing
- pocket capture (with entry speed and angle)
- cue strike (including miscue flag)

### 3.3 Impacts

- Single-contact sphere: normal and tangential parts decouple. The slip direction stays constant through the impact for a sphere (no cross-coupling), which is why the Coulomb friction closed form is exact (verified). One routine serves ball-ball, cushion baseline and table landings.
- Oracle formulas for equal-mass solid spheres, used as test oracles. Ball-ball normal impulse: (1 + e) m v_n / 2. Tangential impulse needed to cancel slip: m abs(u) / 7 for ball-ball and 2 m abs(u) / 7 for a ball against a fixed surface (because 1/m + R^2/I = 7/(2m)). Stick or slide rule: the friction impulse is the smaller of that needed impulse and mu times the normal impulse; if the needed impulse is smaller the impact sticks and leaves zero slip, otherwise it slides and the friction impulse equals mu J_n.
- Ball-ball: restitution about 0.95 (sourced). Ball-ball friction from the published Alciatore-style fit as used by an open-source pool simulator (sourced; units and range to be confirmed against the original proof before hard-coding). The fit contains an exponential in slip speed; it is replaced in the solver by a fixed rational or polynomial approximation with a stated maximum error against the published curve (see 3.5). While both balls are on the table, the vertical part of the ball-ball friction impulse is dropped, because the table's reaction to it is not modelled; this keeps vertical momentum conserved. When both balls are airborne, all three components are kept.
- Cushion: two levels behind one protocol.
  - Level A, built first: single-contact impact with the normal tilted by the nose geometry. The nose sits at 0.635 of the ball diameter, so the contact point is 0.27 R above the ball centre (sin of tilt 0.27, about 15.7 degrees). The ball centre is at horizontal distance R cos(theta) = R sqrt(1 - 0.27^2), about 0.963 R, from the nose line at contact, not R. The normal is (cos theta horizontal, sin theta downward). Speed-dependent restitution (start at 0.85, calibrate), friction in the 0.14 to 0.2 range (calibrate), plus a second no-bounce table impact if the post-impact vertical speed would drive the ball into the cloth. An airborne ball that clears the nose height passes over.
  - Level B, later: the incremental-impulse coupled cushion-and-cloth model from the published literature, fixed step count so it stays deterministic. The Lens and tests depend only on the protocol.
  - The cushion nose line, not the rail, defines the playing surface; ball-centre limits derive from it.
- Ball-table landing: restitution e_table about 0.5 above a small vertical-speed threshold, zero below it (calibrate).
- Pockets: two knuckle circles, two jaw wall segments and a capture disk per pocket (numbers in 3.4). Capture means the ball centre is inside the capture disk with vertical-drop speed below a limit. Hits on knuckles and jaws use the cushion impact. A fast ball that is not captured is rejected with the jaw impact recorded. Capture records entry speed and angle so the Lens can say "too fast for the pocket."
- Cue strike: for a horizontal strike with tip offsets a (vertical) and b (side), measured in the plane perpendicular to the cue axis, ball speed is (1 + e) M v / (M + m + 5 M (a^2 + b^2) / (2 R^2)), with cue mass M, ball mass m, tip restitution e and tip speed v. Elevation adds a vertical component; the strike impulse follows the contact normal, which points from the tip contact point to the ball centre. The strike formula also gives the speed loss with offset and is a test oracle.
- Miscue: the offset is measured perpendicular to the cue axis (the right frame for an elevated cue), and the spin widget ring is a circle in that frame. A miscue happens when tan(angle between the contact normal and the cue axis) exceeds tip friction mu_tip (about 0.58), equivalently when offset magnitude / R exceeds mu_tip / sqrt(1 + mu_tip^2), about 0.5. A miscue is resolved as a reduced noisy strike with seeded deflection.
- Squirt: lateral impulse with an effective shaft-end mass. Default tuned to about two to three degrees at half-radius offset for a standard shaft (calibrate), with shaft stiffness exposed as a parameter; one to two degrees is typical of low-deflection shafts.
- Jump: the ball jumps when the vertical impulse component of the strike, after tip offset and elevation, is downward and the resulting table impact with restitution e_table gives positive upward speed. Jump potential is highest for a centre or slightly above-centre hit with a steeply elevated cue; a tip below centre tilts the normal upward relative to the cue axis and reduces the downward component. The model applies the strike and then the table impact sequentially, although the real table reaction is simultaneous. This is an approximation; e_table tunes jump height and is calibrated against a known jump height versus elevation.

### 3.4 Parameters

All parameters live in one versioned, hashed parameters value that is stored in every recorded shot.

- Ball: radius 0.028575 m, mass 0.170 kg, solid sphere (sourced, regulation spec).
- Table: nine-foot playing surface about 2.54 by 1.27 m is the default; eight foot (about 2.24 by 1.12 m) and seven foot (about 1.98 by 0.99 m) playing surfaces available. Playing surface is measured between cushion nose lines.
- Pockets (sourced from regulation ranges; verify against the specification before tuning): corner mouth about 4.5 to 4.625 inches, side mouth about 5 to 5.125 inches; knuckle radii, jaw angles and capture disk radius are set from the same specification and stored in the parameters value.
- Cloth sliding friction 0.2 (range 0.15 to 0.4). Rolling resistance c_r 0.01 (range 0.005 to 0.015), defined as a = c_r g, a constant deceleration of the ball centre (an offset-force coefficient would be 7/5 times c_r). A rolling ball at speed v stops in v^2 / (2 c_r g). Spin decay about 9 rad/s squared (calibrate).
- Cue mass 0.54 kg, tip restitution 0.7 to 0.85 (calibrate). The break range of 8 to 13 m/s (sourced) is cue-ball speed, not tip speed; with M 0.54 kg, m 0.17 kg and e 0.75 the tip speed is about three quarters of the cue-ball speed.
- Gravity 9.81 m/s squared.

Anything marked calibrate is tuned against the validation suite in 9.1b and then frozen under a parameter version.

### 3.5 Numerics and determinism

- Double only. Allowed operations: add, subtract, multiply, divide, square root. One rule for the whole BreakdownPhysics module: no libm, no Foundation math, no Accelerate, no companion-matrix solvers, no closed-form quartic formula. Exponential fits (ball-ball friction, speed-dependent restitution) are replaced by fixed rational or polynomial approximations, or an in-house exp built from add, multiply and divide with a fixed iteration count, with the maximum error against the published curve stated. Cue direction, elevation and offsets enter as unit vectors or sine-cosine pairs supplied by the caller; the cushion tilt uses sqrt(1 - s^2). A lint test greps the physics module for libm and Foundation math imports.
- Contact detection. Ball-ball: smallest approaching root of a quartic in time, found by isolating roots through derivatives (quadratic, then cubic, then quartic pieces) and then safeguarded bisection to a fixed iteration count plus two fixed Newton polish steps, each clamped to the bracket so it cannot jump out near a double root. Horner evaluation, coordinates shifted to the pair separation. Ball-cushion segments: quadratic root. Ball-knuckle circles: quartic root (squared distance to a fixed point), same solver as ball-ball. Jaw segments: quadratic root.
- Roots must lie within the shorter segment duration and must be approaching; this rejects departing roots and resting contact. Grazing rule on the gap in metres: a hit only if the minimum gap is below 1e-12 m and the approach speed exceeds a tiny threshold, so there is always exactly one decision.
- After an impact a pair is not tested again before a minimal time, and positions are nudged apart by a tiny fixed amount if closer than 2R, so repeated zero-time collisions cannot occur.
- Event ordering key: time, event-kind rank, lowest ball id, second ball id. Never dictionary or set order. Arrays indexed by ball id.
- Event invalidation: each ball carries a version counter; after any event, every queued event involving the affected balls is discarded and recomputed.
- Simultaneous events inside a tiny window that share a ball resolve as a cluster by sequential binary impacts in key order, repeated until nothing approaches, with a pass cap that logs when hit. This is deliberately not symmetric for symmetric clusters; the break is therefore tested on aggregate invariants (test 11), not exact symmetry.
- The rack has a one-micrometre gap between neighbours, optionally jittered by the seeded generator, so the break is a deterministic cascade of binary collisions and avoids the infinite-collision rack problem. Rack geometry is version-stamped because the break result is sensitive to it.
- Zeno guards: cap events per ball per millisecond, snap to rest in contact when exceeded and log it; stop bouncing below a small vertical speed; same guard for pocket-mouth rattling.
- Randomness: only a seeded generator stored in the shot input. No system random, no clock.
- Repeatability scope. Milestone one requires same-machine, same-build repeatability only. Bit-for-bit equality across processes, debug and release, and simulator and Mac, plus the fused-multiply pin, is promoted to a hard requirement at milestone five, when the daily challenge needs shared scores. Supported architecture for the determinism guarantee: arm64 only. Cross-architecture replay relies on the stored timeline, not on re-simulation.
- One code path for iPhone, Mac and tests: no platform conditionals inside the solver, no unsafe optimization flags in any target that builds it, no threads within a shot.
- Timeline as truth: a recorded shot stores its input (table spec version, parameters, ball states, cue strike, seed) and its output timeline with Doubles stored as bit patterns. A hash of the timeline is the replay-equality check. Playback reads the timeline, so old recordings stay correct after solver changes.
- Cost: sixteen balls, a few hundred events, milliseconds. The whole shot is solved before playback begins.

## 4. Physics Lens design

### 4.1 Visual language

Base: a faint grid at one-diamond spacing that rises under the balls during the melt. Dark ink-blue, thin luminous lines. Cosmetic gentle warp near very fast balls. The grid rise, the warp and the glow are decoration, not data, and are marked as such in the source and in any help text.

Layers, each toggleable and auto-managed:

- Path trails coloured by motion phase (the signature): sliding amber and wider with a frayed edge; rolling cyan, narrow and smooth; spinning in place violet as a widening spiral; airborne white and dashed with a shadow dot on the cloth. Trails fade along their length. Hue change along one ribbon (amber to cyan) is the sliding-to-rolling lesson. Cushion contacts get a tick whose hue shifts with energy lost.
- Velocity arrows on a soft length curve, anchored at ball centres, coloured by phase.
- Spin indicators: a thin ring with an orbiting marker whose speed shows spin rate, tilted to show the axis, driven by the recorded orientation.
- Contact normals and tangents at each collision, plus a small momentum triangle on the strongest impacts so the ninety-degree rule is visible in one picture.
- Energy hand-off bursts: a ring pulse sized by impulse with two comet shapes for what each ball keeps. This is the exact signal that drives sound and haptics.
- Equations, typeset, one at a time. Decision: RealityKit text components cannot lay out fractions, superscripts or Greek symbols, so equations are rendered as SwiftUI text (or hand-laid glyph images) offscreen to a texture and placed as billboard planes in the scene. A small set of equation layouts is pre-authored, with numbers slotted in from event data. They fade in near the thing described, light terms as numbers appear, then dissolve. Tapping an equation in freeze opens a short "why" card.
- Captions: one short plain sentence, sentence case; the proper term appears second in small type and only the first time.

Rendering: trails and arrows as dynamic low-level meshes; labels as text components; unlit materials so lines glow; bloom through the custom post-process hook (26 and later, which is our deployment target) with the built-in bloom as an optional upgrade at 27 (see section 8). Lens HUD chrome in SwiftUI.

Cold-open ordering of reveal (melt): felt dissolves from the cushions inward, rails go to outline, textures peel off as a ripple leaving wireframe spheres with a faint coloured core, table goes near-black, grid rises. Technique (decided now, since it is the signature moment): a custom surface-shader material on the felt, rails and balls, driven by a time parameter and radial distance from the cold-open origin, dissolving into the dark grid; the fallback is an animated opacity-mask texture cross-fading felt into the grid. The first rendering task is a throwaway melt prototype, judged by screenshots and a short screen recording. Reduced Motion swaps the melt for a short dissolve.

Cold open focus: the melt follows a hero set, the cue ball and the first two balls struck, and dims the rest. The hero set is chosen from recorded events.

### 4.2 Density rules (hard budgets)

- At most one equation, one caption, and three annotated balls at a time. Everything not the hero drops to low contrast and shows only a thin trail.
- A new concept gets full annotation once, then quiets down.
- A Clarity setting lets the player lower the ceiling; the default is deliberately sparse.
- The Lens is a conductor, not a checklist: it chooses the hero per event from impulse size, novelty and the lesson context.

### 4.3 Interactions

- Timeline strip with ticks at each event, drag to scrub both directions, pinch to zoom a crowded half-second, haptic tick on each crossed event.
- Playback rate detents from real time to heavy slow motion; automatic ease into collisions during replay (it is only the playback rate).
- Tap to freeze; orbit slightly; arrows and spin glyphs stay live; tap a ball for a plain-words card.
- Tap a ball to follow: camera eases to it, its layers go full, others dim.
- What-if ghost: nudge aim, spin or power, the solver reruns instantly, the alternate future draws as a translucent ghost in a distinct colour, a fork marker shows where futures diverge, and a caption names the difference. Cap at two ghosts. "Keep this one" promotes the ghost to a retry. This is a second solver run with a changed input.
- After each shot, a quiet debrief highlights the first moment your prediction and the simulation differ.

### 4.4 Caption templates

Plain language, parameters in braces filled from event data:

- The cue ball handed almost all its speed to the {ball}.
- The cue ball kept rolling forward after the hit.
- The cue ball stopped dead and the {ball} took everything.
- Backspin pulled the cue ball back after the hit.
- The spin on the cue ball nudged the {ball} slightly off the line of centres.
- Friction between the balls pulled the {ball} slightly toward the cue ball's sideways motion. (selected from the direction of the recorded friction impulse)
- The cloth grabbed the ball and turned its slide into a roll.
- Side spin changed how the ball left the cushion.
- Too fast for the pocket: the ball hit the jaw and came back out.
- Most of the energy went into heat and sound at this hit.
- The cue ball gives its push away. One push becomes many. Sliding, then rolling. Watch the colour change. (cold-open beats)

Each template is selected by a rule over event fields (post-impact cue ball speed fraction, spin sign, throw angle, friction impulse direction, energy loss fraction) so captions are derived from computed data and never hand-timed. The cold-open beats are fixed in wording but pick their moments from real events: the first strongest impact, and the first slide-to-roll change.

### 4.5 What the Lens can derive from each event

Momentum before and after (per ball and total); translational and rotational energy before and after; the energy ledger; contact normal; throw angle (object ball direction versus line of centres); spin vectors before and after; the slide-to-roll moment; cushion incoming versus mirror angle. Energy ledger definition: sliding dissipation is mu m g times the integral of slip speed (the contact-point relative displacement, not the centre-of-mass path), which equals m abs(u0)^2 / 7 for a slide to roll and equals the kinetic energy drop; rolling dissipation is c_r m g times distance. A test checks that the sum of ledger entries equals total mechanical energy lost, to tolerance. Where a value is derived by the Lens rather than emitted by the engine, the UI labels it as derived and computes it only from recorded fields.

## 5. Controls and camera

Principles: one hand if possible, no tiny precision targets, nothing hidden in menus mid-shot. Everything is unlocked in free play from the first launch; lessons never gate controls.

### 5.1 iPhone

- Orientation: landscape.
- Aim: one-finger drag on the table rotates the aim around the cue ball. Fine aim with a second finger or an edge dial. Pinch zooms only when two fingers touch.
- Power: a separate pull handle or vertical slider at the screen edge, not the same drag as aiming; release to strike. Thumbs never need to cover the cue ball.
- Tip offset (spin): a ball-face widget in a corner. Drag a dot; centre is stun, up is follow, down is draw, sideways is side spin. A faint ring marks the miscue limit. Haptic detent at centre.
- Elevation: a vertical slider beside the ball face, from level to steep; the cue ghost tilts in the scene. Haptic detent at level.
- Aim help is assist-levelled: Full Lens (path through first collision), Training (ghost ball only), Bare (cue line only), Blind (nothing, Lens only after the shot). The default aid shows the cue ball's first path as a dotted line to first contact and stops there. More assist means a lower score multiplier. It can change mid-session. Lessons may offer guided help, never lock controls.
- Camera: top-down aim view; a smooth tilt to a three-quarter view on strike; free orbit only during freeze.

### 5.2 Mac

Default scheme, shipped with the first playable shot in milestone two:

- Move the pointer to aim; scroll for fine aim.
- Hold and drag back to pull the cue; release to strike.
- One key toggles the Lens, one key freezes, arrow keys scrub the timeline.
- Spin widget in the corner dragged by mouse; scroll with a modifier adjusts elevation.
- Full keyboard path, VoiceOver labels and Switch Control. Game controller: stick aims, trigger powers, second stick spins.
- Mac window is resizable; the layout switches between a compact and a regular arrangement of the same widgets.

## 6. Game modes and progression

- Cold open (first launch), then a skippable shorter cut afterward (break, freeze, melt, one beat, rewind). "Replay intro" in settings.
- Free play: open table, any rack, any assist, every control open, Lens one tap away.
- Lesson path (the spine): stun, follow, draw, throw, masse, jump. Each is about three minutes: watch a perfect example melt into math; three guided shots with reducing aid; one unaided pass shot. Passing earns badges, cosmetics and the guided help; it never unlocks controls.
- Trick-shot challenges: authored goals the solver can check exactly (stop the cue ball on a mark, two-cushion bank, split two balls onto targets, finish in a ring). Par and three medals. Daily challenge from a shared seeded layout, deterministic so scores compare (requires the milestone five determinism guarantee).
- Predict the shot: setup shown, play hidden; the player places where they think the balls end up, then the engine runs and the Lens overlays prediction against truth, scoring closeness.
- Break challenge: fixed rack, one break, scored on balls pocketed, spread, and cue ball position; the Lens shows the energy-split diagram afterward.
- Eight-ball against an opponent: later. Opponents are characterised by physical skill (speed control, over-spinning, safe play) and choose shots with the same solver, with a show-your-thinking replay.
- Rewards: cosmetic cues, balls, cloth colours, Lens themes (blueprint, chalkboard, neon), insight badges earned by correct predictions. A Physics Journal stores best shots as small replay cards labelled by technique. Gentle streaks with a rest day.
- Sharing: in milestone one, a screen recording of the cold open (Mac screen capture or the system recorder) so a video can be sent right away. Later, export a clip by re-rendering the timeline with RealityRenderer (not recording the screen) with start and end, a speed curve, and a Lens preset; a still shot card; challenge links that first use a custom link scheme plus a pasted code, with no web hosting needed until later. System share sheet, no account.

## 7. Feel

- Rule: one impact record drives burst ring, sound and haptic.
- Sound: a bank of ball-click sounds chosen by impulse and contact angle, with small pitch and variation; rail thuds; a rolling hiss following roll speed with a scratchy layer during sliding (audible proof of the amber trail); pocket drop; cue strike pitched by power and tip offset with a distinct miscue sound. In Lens mode the ambience drops through a low-pass filter sweep at the freeze, and a quiet musical bed arrives, with collision tones tied to the burst rings.
- Asset source: synthesised first (audio source nodes in the audio engine); the licence is recorded in the repo for anything bought or downloaded. Nothing is borrowed from existing games.
- Minimal audio ships in milestone one: click, rail thud, rolling hiss and the freeze filter sweep. The rest arrives in milestone two.
- iPhone haptics through the Core Haptics engine: strike tap scaled by power; big collisions a sharp thump, small ones a tick; soft rumble under fast rolling; rail ticks; a tick on each event crossed while scrubbing; detents on the spin widget and elevation slider. Haptic support is queried at runtime (capabilities check) and everything degrades silently.
- Mac: a Mac has no tactile motor, so expect the engine to report no support at runtime. Fallback is trackpad feedback through the AppKit haptic feedback manager (verified: NSHapticFeedbackManager, macOS 10.11 and later in the SDK, called from AppKit-only code behind a macOS compile check) plus controller rumble through the game controller framework. The SwiftUI sensory feedback modifier also compiles on both platforms and is a no-op on Mac.
- Audio engine: AVAudioEngine with player nodes for samples and source nodes for synthesis (rolling and ambient layers); verified on both platforms. Spatial audio is not needed in the first version.
- Everything is quiet-able and respects system haptic and Reduce Motion settings.

## 8. Platforms and project setup

### 8.1 Targets

- One multiplatform app target supporting iPhone (device and simulator) and Mac, with the SDK root set to automatic. Mac Catalyst is not used. A native Mac build from the same sources.
- A local Swift package, BreakdownCore, with the modules in section 2.2. Package tests run with the package test command on the Mac.
- A simulator-driven UI smoke test target later (milestone three).

### 8.2 Minimum OS and setup facts

- Verified here: Xcode 27.1, Swift 6.4, iOS 27.1, macOS 27.0 and visionOS 27.0 SDKs, a single simulator runtime (iOS 26.5), iPhone 17 Pro and Pro Max simulators, no project generator installed.
- Deployment targets: iOS 26 and macOS 26. Decision: everything is testable on this Mac's 26.5 simulator, and the post-process hook for bloom works directly with no fallback path. The scene view, low-level meshes, image-based lighting, text components, camera controls and grounding shadows are all verified in the SDK (available from iOS 18 and macOS 15, so they are covered).
- 27-only features (built-in bloom and tone mapping components, cloth simulation components) cannot run in the 26.5 simulator, so v1 does not use them. Any later use sits behind an availability check for iOS 27 and macOS 27. Revisit when a simulator runtime for 27 is installed.

### 8.3 Project generation

No project generator tool is installed and we do not add one. The Xcode project file is hand-written: object version 77 with a file-system-synchronized root group, so any Swift file dropped into the app folder compiles automatically. It is short (about eighty lines) and the list command accepts it. The first iPhone build proved the pipeline (see 8.5). Set ALWAYS_SEARCH_USER_PATHS to NO, because Xcode otherwise warns about the traditional headermap style for a hand-written project.

Gotcha, hit in the build check: when a file imports both SwiftUI and RealityKit, the name Scene is ambiguous. The app declaration must say SwiftUI.Scene, and the same qualification applies to a system's initialiser taking a scene (System init(scene: RealityKit.Scene)). This applies to every such file.

Camera content may fill only part of the screen: the real app sets an explicit background and ignores the safe area.

### 8.4 Rendering stack (SDK-verified names only)

- Scene view and camera: the RealityKit SwiftUI view (RealityView) with RealityViewCameraContent (unavailable on visionOS, irrelevant here); virtual camera mode; perspective and orthographic camera components; stock orbit camera controls are available on iPhone and Mac if we want them.
- Aiming: on the SwiftUI content, ray(through:in:to:) and unproject(_:from:to:ontoPlane:) take a coordinate space and a RealityCoordinateSpace argument. The simpler forms without those arguments belong to ARView, not to the SwiftUI content; do not look for them.
- Materials: physically based material (clearcoat for ball gloss; roughness and sheen for cloth); unlit material for Lens lines. A custom surface-shader material (CustomMaterial, unavailable on visionOS, irrelevant here) is used for the melt dissolve (see 4.1); exact names are confirmed at the start of the melt prototype.
- Light: one directional light with shadow plus image-based light from an environment resource; grounding shadows for cheap contact shadows. Set shadow reach through shadowProjection (automatic with a maximum distance); the old maximumDistance property is deprecated since iOS 18 and macOS 15.
- Scene driving: our own component and system; the system's update reads the playback clock and sets transforms.
- Lens meshes: low-level mesh for trails and arrows (byte-level replace each frame), text components for simple labels, opacity and sort-group components for fades. Equations are texture-backed billboard planes (see 4.1).
- Post-process: PostProcessEffect (postProcess(context:) taking a PostProcessEffectContext) is iOS 26, macOS 26, unavailable on visionOS, and is installed only through the view content: content.renderingEffects.customPostProcessing = .effect(...) (type RealityViewPostProcessEffect). It cannot be used from a non-SwiftUI route. At our targets of 26 no availability guard is needed. Built-in BloomComponent (scope hierarchical or unbounded), BloomOptionsComponent (strength, threshold, blur radius) and ToneMappingComponent are 27 only on iOS, macOS and visionOS; using them at a lower deployment target without a guard is a compile error, so they need an availability check for iOS 27 and macOS 27 and are not used in v1.
- Offscreen: RealityRenderer (iOS 18, macOS 15) for clip export, with CameraSettings.isToneMappingEnabled and a colour background option. It must be created on the main actor. There is no type named OffscreenRenderer.
- Audio: audio file resources and audio buffer resources, with the audio engine for generated layers. Haptics: Core Haptics engine, pattern and capabilities check (compiles on Mac; hardware support is expected false there), with SwiftUI sensory feedback as a trivial fallback.
- Not available and not assumed: attachment views (ViewAttachmentComponent) on iPhone or Mac, which are visionOS only; compute systems (no public compute-system API exists, and the underscore-prefixed compute-graph module is private and not importable through RealityKit); cloth simulation components (ClothBodyComponent, ClothColliderComponent) exist only from iOS 27 and macOS 27, are not usable at our deployment targets without availability guards, and are not assumed in v1. The Lens and rendering design is unaffected by any of these.

### 8.5 What the build check proved

A hand-written project with a plane, a sphere, a directional light and a perspective camera built for the iPhone 17 Pro simulator, installed, launched, and rendered a lit, shaded sphere with a specular highlight. It also built for Mac. The build check ran at deployment target 18 and 15; the real project targets 26 and 26 and the first task is to confirm it builds and launches at that setting. Not tried: running on the Mac, a physical device, the iOS 27 simulator runtime, or the physics package. That project lived only in a session scratchpad, so it is recreated in the repo as Step Zero of milestone one.

### 8.6 Data and storage rule

All large data (scan captures, depth captures, reconstructed models, model weights, recordings beyond tiny fixtures) lives on the Team 4TB drive under data/breakdown, with models in a models subfolder. Nothing large goes in the repo or on the internal drive. If the drive is not mounted, stop and say so. Only tiny synthetic fixtures for unit tests live in the repo. Any helper agent doing data work must be told this in its task text.

## 9. Testing plan

### 9.1 Unit tests (package test command on the Mac)

Each test names a property, an expectation and a tolerance. Priority list from the physics design:

1. Stun shot: with frictionless, perfectly elastic impact the cue ball leaves exactly perpendicular to the object ball's path.
2. Rolling cue ball departure: the analytic formula is the oracle, tight tolerance: v_final = (5/7) v_perp + (2/7) v_original-direction, with e = 1, zero ball-ball friction and cloth slide only. The thirty-degree rule is a loose sanity band (25 to 40 degrees over cut angles of about 15 to 50 degrees), measured as the cue ball's direction after it has finished sliding and is rolling, from its original line of travel (a half-ball hit gives about 34 degrees).
3. Cushion, two tests. (a) Mirror test: set cushion restitution to 1, friction to 0 and nose height to ball-centre height (normal horizontal); the tangential velocity is unchanged and the normal velocity reversed, to 1e-12 relative. (b) With the real Level A parameters and a natural-roll ball, the exit angle measured from the rail is larger than the entry angle (a steeper, more perpendicular, shorter rebound) and the tangential speed drops.
4. Cushion side spin: running side spin widens the rebound, reverse side spin narrows it; monotonic non-strict, because the rebound saturates once friction sticks.
5. Energy: total mechanical energy (kinetic plus rotational plus gravitational potential) after the cue strike never increases by more than 1e-12 relative, at every event and every sampled time between events; the cue strike is excluded. Includes a stress sweep over cushion friction, restitution, spin and angle. If any case gains energy, switch the impact routine to an energetic restitution rule or clamp post-impact energy to the pre-impact value.
6. Linear momentum is conserved at each ball-ball event, in the horizontal components while both balls are on the table, and in all three components when both are airborne.
7. Mirror symmetry: the mirror plane passes through the coordinate origin, ball ids are mirrored through a fixed permutation that keeps the ordering key stable (or results are compared as sorted sets). Angular velocity is a pseudovector: under reflection across a vertical plane its component normal to the plane keeps its sign and the in-plane components flip, so vertical-axis spin flips. Equality within about 1e-12, not bitwise, except the exact sign-flip case on the symmetry axis.
8. Sliding-to-rolling closed form agrees with tiny-step numeric integration; the sliding parabola matches the closed form; the rolling stop distance is v^2 / (2 c_r g).
9. Quartic solver: random polynomials against a brute-force sign-change search; constructed cases with known double roots and near-double roots (a sign-change search cannot find even-multiplicity roots, which are the grazing cases); near-segment-end and tolerance-edge cases; cushion quadratic and knuckle quartic roots.
10. Repeatability: same input twice in-process gives an equal timeline hash (milestone one). From milestone five: across separate processes, debug versus release, Mac versus simulator, bit for bit on arm64, pinning the no-fused-multiply behaviour.
11. Rack break (jitter on): momentum, ball count conserved, no event-count blowup, and over many seeds the distribution of outcomes is symmetric within a statistical tolerance. No exact mirror symmetry is claimed, because clusters resolve in key order (3.5).
12. Cue strike: draw, follow, left and right each give the physically expected spin sign; centre hit gives zero spin; ball speed matches the strike formula in 3.3 at several offsets; the miscue threshold sits at offset / R = mu_tip / sqrt(1 + mu_tip^2), tested at several elevations.
13. Jump: for a given elevation, a centre or above-centre hit produces a jump; a below-centre hit with the same elevation produces less jump or none; a level cue produces none. Jump height versus elevation is checked against a known reference.
14. Golden shots, regression only: a small library of the solver's own reference shots with expected pocketed balls and final positions. It detects change, not correctness, and is labelled that way.
15. Timeline file round trip: write, read, hash equal; unknown future version is rejected cleanly.
16. Lens event model: every caption template fires only on events meeting its rule, and never on events without the needed fields.
17. Continuity: position, velocity, spin and orientation are continuous at every phase boundary.
18. Spin-down: vertical spin decays to rest in the expected time.
19. Energy ledger closes: the sum of ledger entries equals total mechanical energy lost.
20. Event-queue invalidation: a ball deflected by an earlier event drops its stale later events.
21. Frozen-ball and resting-contact starts behave (no spurious events).
22. Airborne path: landing, and a ball clearing a cushion.
23. Event-order permutation: relabel ball ids and the physics outcome is unchanged apart from documented tie-breaks.
24. Impacts: a sticking impact leaves zero slip; a sliding impact leaves friction impulse equal to mu J_n; the oracle formulas in 3.3 hold. Pockets: a slow centred ball is captured, a fast ball at a jaw is rejected with the jaw impact recorded, a rattle triggers the Zeno guard.
25. Lint: the physics module contains no libm or Foundation math use (3.5).

### 9.1b Validation suite (published or measured data, pass bands stated)

The calibrate values have outside references here, not only the solver's own output: cut-induced throw versus cut angle and speed; spin-induced throw; cushion rebound angle and speed loss versus incidence; stop-shot and follow-shot distances; roll distance versus initial speed; spin-down time; squirt versus offset; break speed to cue-ball speed ratio. Each case lists its source and a pass band before it is used to freeze a parameter version.

### 9.2 Simulator runs with screenshots

Every milestone ends with a simulator run on the iPhone 17 Pro and a captured screenshot at each key moment (table, mid-break, frozen, melted, each Lens beat, scrub, slow motion). Screenshots are reviewed by looking at them, not just by exit codes. A repeat run after every rendering change checks for regressions in framing, safe area, and Lens density.

### 9.3 Device-only list

Real haptic feel; real audio mix on speakers and headphones; frame rate and thermal behaviour under sustained play; touch ergonomics for aim, power and the spin widget; battery cost; and later everything depth-scanner related (live scene mesh, depth quality, room capture, object capture, real-world scale).

### 9.4 Mac checks

Build and launch on this Mac for every milestone from one onward; keyboard, scroll and trackpad paths from milestone two; window resize behaviour.

## 10. Milestones

Estimates are deliberately omitted; each milestone is done when its acceptance list is demonstrably true.

1. Showpiece, split in two so scope stays honest. Runs on the iPhone simulator and on this Mac.
   - Step Zero: recreate the hand-written project and the empty package in the repo at deployment targets 26 and 26, commit it, and record the exact build, install and launch steps in the README. Acceptance: from a clean checkout the simulator shows the lit sphere again.
   - 1a, solver and plain playback (no Lens). Package with a solver good enough to break a rack: phases, cushions, ball-ball with the root solver, a simplified deterministic pocket (a capture disk per pocket, the ball drops out of play, and a pocket-capture event is recorded; jaws, knuckles and spit-out behaviour wait for milestone two), rack, timeline recording, event stream. A fixed break strike chosen so at least one ball drops. A minimal drag-to-aim, release-to-strike break (no spin, no elevation) through the same solver. Table, balls, lighting, camera, playback at normal speed from the recorded timeline, with minimal audio (click, rail thud, rolling hiss). Tests 1, 3, 5, 6, 8, 9, 10 (repeatability), 11, 17 passing. Acceptance: screenshots on iPhone and Mac; same-machine rerun gives an equal timeline hash.
   - 1b, melt and Lens. The melt prototype first (4.1), then the freeze and the melt into the Lens: grid, wireframe spheres, trails by phase, velocity arrows, contact bursts, one equation, one caption, hero-set focus, the draw-shot follow-up beat, freeze filter sweep, slow motion, scrubbing strip with event ticks, rewind that restores the table, and the user's own melt after their break. Acceptance: screenshots of each stage on both platforms; Lens density budget respected; a short screen recording of the cold open reviewed by looking at it, frame by frame, to judge whether the melt feels good.
2. Playable shots. Aim, power, tip offset and elevation on touch and the default Mac scheme; cue strike and spin (tests 2, 12, 13); full pockets with jaws and knuckles; aiming preview; assist levels; full sounds and haptics; install and launch on the Boss's own phone (needs signing through his Apple developer account, or a cable install).
3. Lens depth and what-if. Spin rings, momentum triangles, equations system, captions from rules, follow and freeze, ghost shots. Simulator UI smoke tests.
4. Lessons. Stun, follow, draw, throw; badges and guided help; debrief frame.
5. Challenges. Trick-shot set, predict-the-shot, break challenge, daily seed (cross-platform bit equality required from here), Physics Journal, validation suite complete.
6. Mac and polish. Controller support, accessibility, Reduced Motion, Level B cushion model, masse and jump lessons, timeline-based clip export and share, challenge links.
7. Scan-and-smash spikes (section 12), including the materials package, scene description, simulation-backend protocol and capability object. Opponent play follows after.

Milestone one's cold open is built from the finished Lens pieces, not a canned movie; its beats pick their moments from real events (4.4), even though the wording is fixed.

## 11. Risks and how we retire them

- Solver edge cases (clusters, grazing, rack). Retire with the test list in 9.1, run early; event-count and pass caps log instead of looping.
- Calibration feels wrong (cushion, cloth, squirt). Keep every constant in the versioned parameters value; compare against the validation suite in 9.1b; the ghost and what-if features make tuning visible; we are not trying to be a certified simulator, only believable.
- Citations from memory (cushion restitution fit, two published impact models, the ball-ball friction fit constants). Verify against original papers before hard-coding; until then those values are marked calibrate.
- Rendering the Lens at frame rate on an iPhone. Budget density in the Lens conductor; reuse mesh buffers; profile on device in milestone two.
- Melt looks cheap. Prototype it first, build it from the actual Lens layers and iterate by screenshot and screen recording; keep Reduced Motion fallback.
- Cross-platform determinism. Same-machine repeatability from milestone one; full cross-platform bit equality from milestone five; store timelines so replay never depends on re-running.
- Playing on an older simulator runtime. Deployment target 26 and 26 so everything runs here; 27 features are optional upgrades behind availability checks.
- Mac haptics. Expect none; fallbacks are non-blocking.
- Scan-and-smash determinism differs from pool (generic physics is not reproducible across devices). Record outcomes, not inputs, and share smash challenges as recorded timelines. Flagged now (section 12).
- Scope creep. The Lens is the product; do not start scanning code or its supporting modules before milestone seven.

## 12. Later: scan-and-smash design

### 12.1 What the SDK offers (verified on disk)

- Depth-scanner scene mesh with optional per-face classification (exactly none, wall, floor, ceiling, table, seat, window, door), plus per-frame depth and confidence maps. Classification covers room structure only, not arbitrary objects. The capability check should wrap ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification).
- Room capture returns a parametric room with box furniture from a fixed category list. RoomPlan has no macOS module, so the Mac build of any scan code needs a canImport(RoomPlan) check and a fixture-based path; the capture session has its own supported check.
- The vision framework has a foreground instance mask for tap-to-lift object selection (compiles on iOS 18 and macOS 15). There is no public single-photo depth estimation; non-depth phones would need a bundled model (a recommendation, not an SDK fact).
- RealityKit physics can collide virtual bodies with the reconstructed mesh, reports collision impulses and impulse directions, and has joints and force effects. It has no fracture, and its solver is not ours or deterministic across devices.
- Guided object capture is iPhone and iPad only. Photogrammetry reconstruction exists on macOS 12 and later, so reconstructing on the Mac is a real route; on-device reconstruction is also in the SDK on iOS 17 and later but unproven here.
- No convex decomposition in the SDK; only a single hull per mesh. Voxel arrays exist in the model I/O framework.

### 12.2 Pipeline

1. Input becomes one scan bundle type: live mesh plus frames, room capture, a photo with depth, or an object capture model.
2. Segmentation by the foreground mask lifted through depth, with a manual add and remove tap. Structure classes become static colliders and are never smashed.
3. Collision proxies: static triangle meshes for the room; one convex hull per object first, then voxel-based approximate decomposition capped at a handful of pieces. Decide later whether to write our own or bring in an outside tool.
4. Mass and material: voxel volume times density; material guess from a small classifier with a one-tap override. Shown in the Lens with uncertainty, never false precision.
5. Pre-fracture at load time by material (brittle breaks into chunk shapes, wood splits along a plane, soft materials bounce). Chunks start welded and release when a reported impulse exceeds a threshold. Cap live bodies and sleep small chunks.
6. Placement: augmented-reality overlay mode, or a virtual copy in a plain virtual room. The virtual room is the testing and sharing surface and works in the simulator.
7. Play: throw, swing, drop. A throw is an initial velocity and spin, the same input idea as the break.
8. Lens: each collision becomes a Lens event; on scanned scenes the numbers come from a generic engine and estimated masses, so energy numbers are our own bookkeeping from reported velocities and estimated masses, labelled derived or estimated.

### 12.3 What we build now to keep the door open

Only the engine-agnostic event model and recorder (outcomes plus optional input), and the physics core as a UI-free package. The materials package, scene description, simulation backend protocol and capability object are built at milestone seven, not before. We write no scanning code until then.

### 12.4 Phase order after pool

1. Mac and simulator spike: a virtual room of fixture meshes, RealityKit bodies, a thrown ball, collision impulses into the Lens, basic fracture. Proves the Lens on a second engine with no camera.
2. Device spike on a Pro iPhone: live mesh with physics, room capture, depth captured to a saved scan bundle.
3. Segmentation and proxies from a photo plus depth.
4. Object capture for single-object quality, reconstructing on the Mac.
5. Non-depth fallback with a bundled depth model, only if the audience justifies it.

A scan file format and fixture player let the whole pipeline run from saved scans on the Mac and in the simulator; only the capture screens are device-only. Scan data lives on the Team 4TB drive per section 8.6.

## 13. References

- Billiards physics design note (Claude Opus 5.5 Medium, 02-Nov-2026), basis for sections 3 and 9.
- Apple platform verification note (Claude Opus 5.5 Medium, 03-Nov-2026): SDK-verified names read from the local interfaces for iPhoneOS 27.1, MacOSX 27.0 and XROS 27.0; Xcode 27.1; Swift 6.4; build check in the session scratchpad.
- Game and Lens design note (Claude Opus 5.5 Medium, 02-Nov-2026), basis for sections 1, 4, 5, 6 and 7.
- Scan-to-smash lane note (Claude Opus 5.5 Medium, 02-Nov-2026), basis for section 12.
- Open-source pool simulator by Evan Kiefl (repository, theory blog, journal paper) and its ball-ball friction module citing Alciatore's technical proofs.
- Dave Alciatore, technical proofs on cue ball deflection and ball-ball friction (original not retrieved).
- Leckie and Greenspan, event-based pool physics simulator.
- Mathavan, Jackson and Parkin (2010), cushion impact; Han (2005); Marlow, The Physics of Pocket Billiards. The last three cited from memory; check before hard-coding.
- Regulation ball and table dimensions from the world pool-billiard association specification.

## 14. iPhone Duo: the lead device (added 03-November-2026, Claude Sonnet 5.5 Medium)

The Boss decided to lead with and design for the iPhone Duo. What the press and Apple's own pages say (checked by web search on 03-November-2026; the Apple developer talk was not read in full, so treat items marked "unconfirmed" as open):

- Two screens: an outer 5.4 inch display, and an inner 7.6 inch display that is Apple's largest on an iPhone, aspect ratio about 1.42 to 1. Pixel sizes (outer about 1398 by 2034, inner about 2007 by 2853) come from one developer blog and are unconfirmed.
- Chip A20 Pro, ships with iOS 27.1, Touch ID instead of Face ID, dual 48 megapixel rear cameras.
- LiDAR scanner: unconfirmed. One spec listing says yes, Apple's own spec pages were not read. This gates the scan-and-smash phase and must be checked on Apple's US spec page before any scan work starts.
- Apple's Tech Talk guidance, as reported: the outer display is compact width, regular height in portrait like other iPhones; the inner display is regular in both directions; the inner display ignores supported-orientation settings, so layout must follow size classes, never orientation or fixed screen sizes. Apps built with older SDKs do not extend under the status bar and camera area.

What this means for Breakdown:

1. The table is the hero on the inner display: nearly square, so the whole table can show large with the Lens beside it, instead of the narrow portrait strip we frame today. The camera framing already fits the view by its aspect; add a layout that puts captions and controls beside the table when the width allows, driven by size class.
2. The outer display is the one-hand mode: replay, slow motion and a quick break, using the current portrait layout.
3. Folding and unfolding mid-shot must keep the clock and the recorded timeline untouched. The timeline is the source of truth, so only the view changes; test this explicitly.
4. A fun idea to try once the basics hold: use both halves as teacher and student, the Lens on one side and the felt on the other, if the fold exposes two usable halves in a posture mode. Unconfirmed until the SDK posture APIs are read on disk.
5. No iOS 27 simulator runtime is installed here yet, and only an iOS 26.5 runtime exists. Download the iOS 27 runtime and look for a Duo simulator profile before building Duo-specific layout; until then the layout is tested on iPad-shaped and iPhone-shaped windows.

Sources: Apple newsroom (apple.com/newsroom/2026/09/apple-unveils-iphone-duo), Apple Tech Talk 111461, MacRumors, Macworld, a developer blog on the aspect ratio (blakecrosley.com).
