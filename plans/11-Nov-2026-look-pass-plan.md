<!--
Author: Claude Sonnet 5.5 Medium
Date: 11-November-2026
PURPOSE: Plan for the first look pass on Breakdown: one set of colours and Apple fonts, shinier balls under real reflections, and trails whose width follows speed with a soft glow. Written for the Boss first, build detail below.
SRP/DRY check: Pass - checked the existing plan, spec section 14 and the ideas page; this plan only covers the look pass and defers every other idea.
-->
# Look pass, first slice

**What it means for the Boss:** the game stops looking like a tech demo. Balls get a lamp reflection so they read as shiny, trails get wider where the ball is fast and gain a soft glow, and all the text moves to Apple's own fonts under one colour scheme. Nothing about how the game plays or how the physics works changes. Testing is on an iPhone 17 Pro, with the sound switched off while testing.

## Scope (three code areas, one commit)

1. A new theme file holding the colours and font choices, so the screens and the 3D scene share one source.
2. The table scene: a generated reflection image of a warm lamp in a dark room so the balls and rails have something to reflect, and a warmer key light.
3. The trails: width follows speed, plus a wider, fainter halo strip under each trail piece.
4. The screen: replace the mixed rounded fonts with New York (titles and equations), the standard system font (labels) and its monospaced cut (live numbers); square off the controls into a solid dark strip with a thin border.
5. A switch to silence the game's sound for testing.

## Deliberately left for later

- Smooth shader-driven trails (the trail still reveals in small steps), rounded rail edges, pocket holes, the melt dissolve, bloom (needs the newest system and an availability check), camera moves, and the Duo layouts, which need a real device.

## Done when

- The iPhone and Mac builds succeed and the existing physics tests still pass.
- A screenshot after the Lens melts in shows glowing trails of varied width, and a screenshot of the warm table shows reflections on the balls, both compared with the screenshot taken before the change.
