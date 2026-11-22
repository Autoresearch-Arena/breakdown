#!/opt/homebrew/bin/python3.13
# Author: Claude Opus 5.5 High
# Date: 21-November-2026
# PURPOSE: Draws the layers of Breakdown's app icon (bug plan item 37) as 1024 x 1024 PNGs with transparency, for the
#          layered icon document App/AppIcon.icon. One idea that reads at the smallest size: the white cue ball with
#          the Lens's own trail behind it, amber where the ball slid off the tip and cyan once the cloth turned the
#          slide into a roll, the way the game draws every path. No text. Three layers, top to bottom:
#            ball.png   the cue ball, a plain white disc (the icon's glass and light come from the system, not the art);
#            trail.png  the trail: a straight path (a ball struck without side spin travels in a straight line, so a
#                       bend would be a physics lie on the icon of a game about honest physics), wider and amber where
#                       it slides, narrow and cyan where it rolls, brightest at the ball and fading towards the start,
#                       with a soft glow, as LensLayer draws trails;
#            grid.png   the Lens's faint grid, one line per eighth of the icon.
#          The background is not a layer: it is the document's fill (icon.json), the game's dark ground, with a darker
#          fill for the dark look; the tinted and clear looks the system makes from these layers.
#          Writes the PNGs into App/AppIcon.icon/Assets/, the same art flattened onto the fill as one opaque square into
#          App/Assets.xcassets/AppIcon.appiconset/icon.png, and previews under /Volumes/Team 4TB/breakdown-build/icon/
#          (big output stays off the internal drive). The flat copy is a fallback only: when a layered icon document
#          and an asset-catalog icon set share the name AppIcon, the document wins on every platform this app targets
#          (checked by compiling both with actool for the Mac and for iPhone and iPad: the output is the same with or
#          without the set). It is kept so that if the document were ever left out of the build, iPhone, iPad and
#          the Mac would still show this icon, not the old one or none.
#          Needs: Python 3.13 from Homebrew (it has numpy and Pillow; the system python3 has neither).
#          Run: /opt/homebrew/bin/python3.13 Tools/icon/render_icon_layers.py
#          Then check every look (Default, Dark, TintedLight, TintedDark, ClearLight, ClearDark, iOS and macOS) with
#          Icon Composer's command-line renderer, inside Xcode at
#          Contents/Applications/Icon Composer.app/Contents/Executables/ictool
#            ictool App/AppIcon.icon --export-image --output-file out.png --platform iOS --rendition Dark
#                   --width 1024 --height 1024 --scale 1
#          and open App/AppIcon.icon in Icon Composer to see it with the system's glass.
# SRP/DRY check: Pass - the only icon drawing code. The two path colours are the game's own (Theme.amberRGB,
#          Theme.cyanRGB in App/Theme.swift), copied here because this script cannot read Swift; change both together.
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent.parent
ASSETS = ROOT / "App" / "AppIcon.icon" / "Assets"
# The flat fallback picture in the asset catalog's icon set of the same name (see the header).
FALLBACK = ROOT / "App" / "Assets.xcassets" / "AppIcon.appiconset" / "icon.png"
PREVIEW = Path("/Volumes/Team 4TB/breakdown-build/icon")

SIZE = 1024
# The document's light fill, top and bottom of its gradient (icon.json "fill-specializations", the default look): the
# game's dark ground (the launch colour, App/Assets.xcassets/LaunchGround) lifted towards blueprint blue at the top.
FILL_TOP = np.array([0.04706, 0.10196, 0.16471])
FILL_BOTTOM = np.array([0.01961, 0.04314, 0.07451])
# Theme.amberRGB and Theme.cyanRGB (App/Theme.swift): sliding and rolling in the Lens.
AMBER = np.array([1.0, 0.62, 0.20])
CYAN = np.array([0.30, 0.88, 1.0])
# The cue ball: a warm white, a touch off pure white so the glass highlight the system adds still reads on it.
BALL = np.array([0.97, 0.97, 0.95])

# Geometry, in pixels of the 1024 canvas (y down). The system masks the icon to a rounded square (and to a circle
# nowhere we ship), so everything that matters sits inside the middle 80 percent, as the icon brief asks.
BALL_CENTRE = np.array([628.0, 404.0])
# A radius of 150 makes the ball 29 percent of the icon's width: at the smallest size the system draws an icon
# (16 points on the Mac) it is still about 5 points across, a clear white dot.
BALL_RADIUS = 150.0
# The trail starts at the lower left and runs straight into the ball's centre (the ball covers its end).
TRAIL_START = np.array([182.0, 860.0])
# Half-widths of the trail's bright core: wide where it slides, narrow where it rolls (the Lens's rule), at most two
# thirds of the ball's radius so the ball still reads as the head of the trail.
SLIDE_HALF = 44.0
ROLL_HALF = 26.0
# Where along the path (0 at the start, 1 at the ball) the slide turns into a roll, and over how long the colour
# blends. Real skid lengths are a few ball widths at most; this one is drawn longer so both colours read at icon size.
TURN_AT = 0.50
TURN_SPAN = 0.40
# Grid spacing: eight cells across, the same one-cell-per-diamond feel as the Lens's grid without becoming noise.
GRID_STEP = SIZE / 8
GRID_HALF = 2.5          # half the line width in pixels
GRID_ALPHA = 0.11        # faint: it is decoration under the trail, never the subject


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def coords():
    ys, xs = np.mgrid[0:SIZE, 0:SIZE].astype(np.float64)
    # Pixel centres.
    return xs + 0.5, ys + 0.5


def save(rgb, alpha, name):
    """Write straight (not premultiplied) RGBA, the way PNG stores it."""
    rgba = np.dstack([np.clip(rgb, 0, 1), np.clip(alpha, 0, 1)])
    image = Image.fromarray((rgba * 255 + 0.5).astype(np.uint8), "RGBA")
    ASSETS.mkdir(parents=True, exist_ok=True)
    image.save(ASSETS / name)
    return image


def ball_layer():
    xs, ys = coords()
    d = np.hypot(xs - BALL_CENTRE[0], ys - BALL_CENTRE[1])
    # One pixel of anti-aliasing at the edge.
    alpha = 1.0 - smoothstep(BALL_RADIUS - 1.0, BALL_RADIUS + 1.0, d)
    rgb = np.broadcast_to(BALL, (SIZE, SIZE, 3)).copy()
    return save(rgb, alpha, "ball.png")


def trail_layer():
    xs, ys = coords()
    axis = BALL_CENTRE - TRAIL_START
    length = np.hypot(*axis)
    unit = axis / length
    rx, ry = xs - TRAIL_START[0], ys - TRAIL_START[1]
    # t: how far along the path (0 start, 1 the ball's centre); d: distance across it.
    t = (rx * unit[0] + ry * unit[1]) / length
    # Distance to the path as a segment (clamped at both ends), so the glow rounds off at the start instead of
    # stopping in a straight cut.
    tc = np.clip(t, 0.0, 1.0)
    d = np.hypot(rx - tc * axis[0], ry - tc * axis[1])
    # Rolling share: 0 while sliding, 1 once rolling, blended over TURN_SPAN.
    rolling = smoothstep(TURN_AT - TURN_SPAN / 2, TURN_AT + TURN_SPAN / 2, t)
    half = SLIDE_HALF + (ROLL_HALF - SLIDE_HALF) * rolling
    colour = AMBER[None, None, :] * (1 - rolling)[..., None] + CYAN[None, None, :] * rolling[..., None]
    # Age fade, as LensLayer's trail picture: full strength at the ball (the newest part), easing to half at the
    # start, so the eye runs along the path to the ball (half, not less: amber dimmer than that turns brown).
    strength = 0.50 + 0.50 * smoothstep(0.0, 1.0, tc) ** 0.8
    # A white-hot centre line inside the coloured core, then the soft halo outside it (LensLayer's "thin bright core
    # inside a wider soft halo").
    core = 1.0 - smoothstep(half - 1.5, half + 1.5, d)
    hot = (1.0 - smoothstep(half * 0.18, half * 0.42, d)) * 0.55 * rolling ** 0.5
    halo = np.exp(-((d / (half * 1.9)) ** 2)) * 0.55
    alpha = np.maximum(core, halo) * strength
    rgb = colour * (1 - hot[..., None]) + hot[..., None]
    return save(rgb, alpha, "trail.png")


def grid_layer():
    xs, ys = coords()
    def lines(v):
        # Distance to the nearest grid line, lines at multiples of GRID_STEP inside the canvas.
        k = np.round(v / GRID_STEP)
        return np.abs(v - k * GRID_STEP)
    d = np.minimum(lines(xs), lines(ys))
    alpha = (1.0 - smoothstep(GRID_HALF - 0.75, GRID_HALF + 0.75, d)) * GRID_ALPHA
    rgb = np.broadcast_to(CYAN, (SIZE, SIZE, 3)).copy()
    return save(rgb, alpha, "grid.png")


def flatten(layers):
    """The layers composited on the document's light fill (the top-to-bottom gradient in icon.json), opaque: the
    flat picture the old icon set holds, and a quick look at the art before the system's glass is added."""
    _, ys = coords()
    t = (ys / SIZE)[..., None]
    ground = FILL_TOP * (1 - t) + FILL_BOTTOM * t
    alpha = np.ones((SIZE, SIZE))
    out = Image.fromarray((np.dstack([ground, alpha]) * 255 + 0.5).astype(np.uint8), "RGBA")
    for layer in layers:
        out = Image.alpha_composite(out, layer)
    return out.convert("RGB")


def main():
    grid, trail, ball = grid_layer(), trail_layer(), ball_layer()
    flat = flatten([grid, trail, ball])
    # The fallback in the asset catalog: one opaque square (no transparency, as the store requires of a flat icon).
    FALLBACK.parent.mkdir(parents=True, exist_ok=True)
    flat.save(FALLBACK)
    PREVIEW.mkdir(parents=True, exist_ok=True)
    flat.save(PREVIEW / "flat-1024.png")
    # The smallest sizes the system shows: a quick check that the idea survives.
    for px in (16, 32, 58, 120):
        flat.resize((px, px), Image.LANCZOS).save(PREVIEW / f"flat-{px}.png")
    print(f"Layers in {ASSETS}; flat fallback {FALLBACK}; previews in {PREVIEW}")


if __name__ == "__main__":
    sys.exit(main())
