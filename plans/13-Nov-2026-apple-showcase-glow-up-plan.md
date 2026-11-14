<!--
Author: Claude Fable 5.2 Low
Date: 13-November-2026
PURPOSE: The working plan for making Breakdown look and feel like a showcase of Apple design. Written for the
         junior developers who will do the work: what is wrong today, the rules, the work packages in order, and
         how each one is checked.
SRP/DRY check: Pass - checked README, ROADMAP, the spec and the existing plans; this plan covers presentation and
         feel only and links to the spec for game design instead of repeating it.
Edited: Claude Sonnet 5.5 High, 13-November-2026 (package 2: recorded the glow route and the framing hand-offs under Open items).
-->
# Apple showcase glow-up

## Why this plan exists

The Boss looked at the running game on 12 and 13 November 2026 and called it awful. He is right. Breakdown was
meant to show how well we can do Apple design using only what Apple ships. Today it shows the opposite. The
physics underneath is sound and stays as it is. Everything the player sees and touches gets redone.

Read this whole plan before you touch a file. If something here is unclear, ask before you build.

## What is wrong today (seen in the iPhone simulator)

Table view
- The table is brown boxes on a green sheet floating in a black void. The felt sticks out past the rails.
- Rails have square ends and no shape. Pockets are flat black discs with no depth. No diamond sights.
- The light is flat. No room, no lamp, no reflections worth the name. Shadows are tiny smudges.

Physics Lens view
- The table frame runs off the left, right and top of the screen in portrait, and sits behind the title and the
  status bar.
- Trails are thin flat lines. Nothing glows. By the end of a shot every trail is still on screen and the result
  is a scribble nobody can read.
- The caption card sits on top of the balls it is describing.

Controls
- Every control is hand-made: custom chips, custom round buttons, a custom scrub bar. None of them look or
  behave like Apple controls. Touch targets are smaller than Apple's minimum.
- The Lens button changes width when its label changes, so the buttons beside it jump. A tap aimed at
  "Your break" lands on the Lens button. This happened during the review.
- "Your break" is three sliders in a panel that covers the bottom half of the table you are aiming at.
- Colours and font sizes are typed in by hand. Nothing follows the system text size, contrast or motion settings.
- The status label on the top right is clipped at the screen edge.
- Nothing is labelled for VoiceOver. There are no haptics. The Mac build has never been looked at.

## The rules

1. Apple frameworks only: SwiftUI, RealityKit, AVFoundation, Core Haptics, SF Symbols. No third-party packages,
   no purchased art, no downloaded models. Textures and sound are made in code, as they are now.
2. Use the standard control before you invent one. Button, Slider, Picker, Toggle, Menu, toolbar, sheet. A custom
   control needs a written reason in the pull request.
3. Follow the Human Interface Guidelines for the system the app targets (iOS 26 and macOS 26). That means the
   current system look, including Liquid Glass on controls that float over content. Read the guideline page for
   a component before you build it, and link the page in your pull request.
4. Content first. The table is the content. Controls float over it, stay small, and get out of the way.
5. Respect every system setting: Dynamic Type, Bold Text, Increase Contrast, Reduce Motion, Reduce Transparency,
   light and dark appearance, VoiceOver. Test each one. "It works at default settings" is not done.
6. Touch targets are at least 44 by 44 points. Layout must not shift when a label changes.
7. Respect safe areas. Nothing important under the status bar, the Dynamic Island or the home indicator.
8. The physics package is not to be changed by this plan. Rendering reads the recorded timeline and never
   changes it. If you think the solver is wrong, write it up; do not patch it in a design pull request.
9. Do not guess at an API. Check it exists in the installed Xcode before you plan around it. If it does not,
   use the fallback named in the work package and say so.
10. Coding standards apply to every file: header, real comments, changelog entry. See CODING_STANDARDS.md.
11. Build output goes on the Team 4TB drive, never the internal drive.

## How every piece of work is checked

A work package is done only when all of these are true. Compiling is not evidence.

- Screenshots from the iPhone simulator in portrait, and from the Mac build, attached to the pull request,
  before and after, for each state the package touches.
- The same screens checked at the largest Dynamic Type size, with Increase Contrast on, with Reduce Motion on,
  and with Reduce Transparency on.
- VoiceOver can reach and name every control the package touches.
- The twelve physics tests still pass.
- Scrubbing backwards and forwards shows the same picture at the same time. The Lens is exact; keep it exact.
- One reviewer who did not write the code runs it and signs off in the pull request.

## Work packages, in order

Each package is one branch and one pull request. Packages 1 and 2 touch the same file (TableScene), so they
run one after the other. Package 3 can run alongside either. Do not start 4 until 3 is merged.

### 0. Split the renderer first (small, do before anything else)

TableScene does the table, the Lens, the camera and the per-frame update in one file, which will make two
people collide. Split it into the table build, the Lens layer, and the camera, with no change in behaviour.
Done when before and after screenshots match and the tests pass.

### 1. A real table in a real room

Files: the table build half of the renderer, BallTextures.
- Felt stops at the cushions. Nothing overhangs.
- Rails with rounded edges and shaped ends at the pockets. Cushions with a sloped nose, not a box.
- Pockets that go down: a dark well with a visible rim, so a dropping ball visibly falls in.
- Diamond sights on the rails. A head spot and foot spot on the cloth.
- Cloth with a fine woven texture and wood with grain, both generated in code like the ball textures.
- A lit scene: an overhead lamp as the key light, soft shadows under every ball, an environment for the balls
  to reflect (image-based lighting generated in code or a system-provided one), a dark floor that fades out.
  The table should sit in a pool of light, not float in black.
- Balls: keep the clear coat, sharpen the number textures, make sure stripes and numbers read at phone size.
Done when a still of the resting table could pass for a product photo at a glance.

### 2. A Lens that glows and can be read

Files: the Lens half of the renderer, the grid texture.
- The whole table fits on screen in portrait and landscape, inside the safe area, clear of the title and the
  controls. Fix the camera framing; do not shrink the controls to hide the problem.
- Trails glow. First check whether RealityKit in the installed Xcode offers a bloom or post-processing step for
  RealityView. If it does, use it. If not, build each trail as a bright thin core with a wider soft additive
  halo.
- Trails fade with age. The last second or two of each path is bright; older path dims to a faint trace. Fading
  is a function of the playback clock, so scrubbing stays exact in both directions.
- Keep the meaning of the colours (sliding versus rolling) and add a small legend the first time they appear.
- Keep a faint outline of the cushions and pockets in the Lens so the player always knows where the table is.
- Impact rings and arrows get the same glow treatment and sit above the trails.
- The melt from table to Lens is the signature moment. Make it smooth, and give it a Reduce Motion version
  that cross-fades instead of swinging the camera.
Done when a paused frame mid-break is readable by someone who has never seen the game.

### 3. Controls rebuilt from standard parts

Files: ShowpieceView, split into smaller views as you go.
- Replace the custom chips, round buttons and panel backgrounds with system buttons and the system glass
  treatment for floating controls. Use SF Symbols with the standard symbol effects for play and pause.
- Speed becomes a standard segmented picker or a menu. Lens becomes a toggle-style button whose width never
  changes.
- All colours come from one small palette defined once, with light, dark and high-contrast values. All text
  uses system text styles so it scales.
- The scrub bar may stay custom because the impact ticks are the point, but it gets a 44 point hit area, a
  VoiceOver adjustable value, and haptic ticks as the playhead crosses an impact.
- Captions move off the action: anchored near the top under the title on iPhone, in a side column on Mac and
  in landscape. A thin leader line or a highlight ring ties the caption to the ball it describes.
- Mac: a real toolbar, menu commands with keyboard shortcuts for play, replay, Lens and speed, pointer hover
  states, and a sensible minimum window size.
- Every control has an accessibility label and value.
Done when the screen survives the largest text size and VoiceOver can drive a full replay.

### 4. Aim by touching the table

Files: ShowpieceView, ShowpieceModel, the aim line in the renderer.
- Drag on the table to swing the aim line. Pull back and release to set power, with the line and a power
  gauge showing the value as you pull.
- A small picture of the cue ball: touch it to place the tip (follow, centre, draw).
- A ghost preview of the first contact so the player sees what the shot will do.
- On Mac the same thing works with the pointer, and with arrow keys for fine aim.
- VoiceOver users keep an accessible version using standard sliders in a sheet. The sliders do not disappear;
  they stop being the main way in.
Done when a new player can break without reading any instructions.

### 5. Feel

Files: SoundBoard, a new haptics file, the camera.
- Haptics scaled by each impact, using Core Haptics, played from the same recorded events that drive sound.
- Sound: a sharper crack for the break, softer clicks for light contacts, a thud and rattle for a pocket.
- Camera: a gentle push-in on the break, a slow settle as the balls stop. All of it off under Reduce Motion.
- A proper opening: the title appears with the system's standard motion, not a hard cut.
Done when the break feels like something hit something.

### 6. Make it a game (links to the roadmap, not designed here)

Working pocket jaws, shot after shot, and the lessons in the spec. This is game work, not presentation, and
follows the roadmap and spec. It is listed so nobody thinks the glow-up is the finish line.

## Layout after the split (package 0, done 13-Nov-2026)

The renderer is now four files in App, so three people can work at once without touching the same lines.

- TableScene.swift: the thin coordinator. Owns the root, the shared state, loading a new shot, and the per-frame
  step that fades the table and places the balls. Keep it short; do not add table or Lens detail back.
- TableBuilder.swift: the static warm table. Felt, rails, cushions, corner blocks, pockets, the balls and their
  materials, the lights and the lamp reflection. Package 1 and package 3 live here.
- LensLayer.swift: the cold Lens. Grid, trails, rings, arrows, the aim line, their materials and their per-frame
  reveal. Also holds the aim preview type. Package 2 lives here.
- TableCamera.swift: the camera rig, framing and the melt swing. Package 3 camera work lives here.

The split changed no behaviour: the title and table frames are byte-for-byte the same as before, and the Lens
frames match.

## What this plan does not cover

- The Unreal port and scan-and-smash. Both stay as later decisions in the roadmap.
- Changes to the physics solver.
- A physical iPhone check needs the Boss's device and signing; flag it when packages 1 to 3 are merged.

## Open items for whoever picks this up

- DONE (package 2, Claude Sonnet 5.5 High, 13-Nov-2026) Glow route. Checked in the installed Xcode 27.2 SDK: RealityKit has
  a system bloom (BloomComponent with a hierarchical or unbounded scope, plus BloomOptionsComponent for strength,
  threshold and blur radius) but it is marked iOS 27 / macOS 27 only; the old ARView post-process hook is not available
  to RealityView. The app deploys to iOS 26 / macOS 26, so the glow is built into the pictures first on every device
  (each trail is a thin bright core inside a wider soft halo, drawn into one generated texture) and the system bloom is
  added only behind an availability check, on the Lens layer alone (hierarchical scope), with the halo turned down so the
  two do not stack. Tested both ways: the iOS 27.2 simulator with bloom on, the same build with the -noBloom launch flag,
  and an iOS 26.5 simulator (bloom correctly off). Additive blending is not offered by RealityKit's unlit material, which
  is why the halo is ordinary alpha-blended and the picture carries the glow.
- Package 2 hand-offs for package 3 (ShowpieceView): (a) the 3D view fills the whole window but the screen passes the
  camera only the size inside the safe area, so the camera now asks the window for its real size and safe-area insets
  itself; if package 3 changes the control strip, keep passing its height as the bottom inset (a share of the view
  height, as now) or pass real points. (b) TableScene.updateCamera takes an optional topInset in points: pass the height of
  the caption column there once captions move to the top, and the table will frame itself below it. (c) The Lens colour
  legend is drawn inside the 3D scene as a baked picture, so it does not follow Dynamic Type and VoiceOver cannot read it;
  give the 3D view an accessibility label that says what the colours mean (sliding amber, rolling cyan, thicker is
  faster, older path fades). (d) The Lens is readable except where the caption card still sits on top of the bottom of
  the table; package 3 moves the card.
- Package 2 launch flags for checks (no effect in normal use): -noBloom, -forceReduceMotion, -lensDebugTime <s>,
  -lensDebugMelt <0..1>, -lensDebugTour a,b,c, -lensSelfTest (prints PASS or FAIL for scrub exactness).
- Package 2 framing check: CameraFraming.swift is pure maths; a scratch harness (kept on the build drive, not in the repo,
  under breakdown-build/p2-lens-harness) sweeps ten window shapes (iPhone and iPad portrait and landscape, a narrow iPad
  split, five Mac window shapes) and camera angles from 40 to 89 degrees and checks with an independent matrix projection
  that every outer table corner lands inside the usable rectangle: all 170 cases pass.
- Not verified by package 2: the Mac window itself (the Mac build compiles and the framing maths is checked for Mac shapes,
  but a launched Mac window would not appear in this session, so no Mac screenshot was taken and the Mac window-inset
  read in TableCamera has not been seen working), a real device, Dynamic Type at the largest size (the legend is a picture),
  and Increase Contrast and Reduce Transparency were coded (stronger grid, solid legend card) but not screenshotted.
- Confirm the environment lighting route for package 1 the same way.
- The Mac build has not been looked at by anyone. The first person on package 3 takes Mac screenshots of the
  current state before changing anything.
