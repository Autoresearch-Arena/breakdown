#!/usr/bin/env python3
# Author: Claude Opus 5.5 Medium
# Date: 26-November-2026
# Edited: 26-November-2026 by Claude Opus 5.5 Medium (UI rethink package 3, lint pass): also catches a corner hidden
#          in a named constant (static let corner: CGFloat = 24) or a default argument (cornerRadius: CGFloat = 24),
#          and stays quiet when its output pipe closes early (python3 scripts/design-lint.py | head).
# PURPOSE: The design drift guard for Breakdown (UI rethink package 3, "The component kit", part D; plan:
#          plans/26-Nov-2026-ui-rethink-plan.md, rules: plans/26-Nov-2026-design-language.md). It lists every place in
#          the app's Swift code that sets a look by hand instead of through the shared tokens and kit:
#            - bare colour: Color(red:...), Color(.sRGB, ...), Color(hue:...), Color(white:...), Color("asset name"),
#              UIColor / NSColor / PlatformColor literals (their red/white/hue initialisers and named colours such as
#              .systemBlue), and the SwiftUI named colours .white .black .blue .green .red .orange .yellow .pink
#              .purple .gray (also Color.white and the like), and the scene helper rgba(<literal>, ...). Anything that
#              should be a Palette role.
#            - bare font size: .system(size: <number literal>), UIFont/NSFont systemFont(ofSize: <literal>) and
#              .custom("...", size: <literal>). Anything that should be a Theme text role or figure font.
#            - bare corner radius: cornerRadius: <literal> (RoundedRectangle, .rect, .cornerRadius modifier) and the
#              per-corner radii of UnevenRoundedRectangle, plus a radius parked in a named constant or a default
#              argument (static let corner: CGFloat = 24, cornerRadius: CGFloat = 24). Anything that should be a
#              Theme.Corner value. Circle sizes named ...Radius (a ring, a tag dot) are geometry, not corners, and
#              are not listed.
#          Output: one line per hit, "file:line  kind  matched text", then a per-file count summary grouped by the
#          plan's work packages. The package of each file is read from the "Files:" lines of the plan itself, so the
#          summary follows the plan if it changes; packages 4 to 9 (the ones that must clear the list before launch)
#          come first, then any other package that names the file, then "unowned" for files no package names. A file
#          named by two packages (for example the notebook column, package 4 then 8) is shown under each of them, and
#          the grand total counts it once.
#          NOT SCANNED, and why:
#            - App/Theme.swift and App/NumberStyle.swift: they are the tokens; raw values belong there.
#            - App/Kit/: the component kit is built from the tokens and is the one sanctioned place for component
#              geometry.
#            - colours in 3D scene and texture code, where raw RGB is the real input of a material, a light, a
#              render background or a drawn texture bitmap, not an interface colour: the files in SCENE_FILES below.
#              Each was read before being listed; each builds RealityKit materials or entities, or draws the pictures
#              they wear (BallTextures, SurfaceTextures, LensTextures, TableBuilder, TableFrame, TableRoom and the
#              like). Only their colour hits are skipped: a SwiftUI corner radius in one of them (the table portrait
#              card, say) is still listed. The UI files that also import RealityKit (AimOverlay, CaptionViews,
#              TableStage, TableZoom and the like) are scanned in full, because their colours reach the player as
#              interface.
#            - cornerRadius on a generated mesh (MeshResource.generateBox(..., cornerRadius: 0.012)): that is a 3D
#              bevel in metres, not a screen corner.
#            - the game's own ball-colour enum (BallColour: white, red, yellow on bar billiards, five-pin and bumper
#              pool), which reads like a SwiftUI colour (.plain(.red), colour == .white) but names a ball.
#          A line that ends with the comment "// design-lint: allow <reason>" is left out: the way to keep a value the
#          design language itself fixes outside the tokens (the black stops of an alpha-only fade mask, say).
#          Comments are skipped (a rule quoted in a comment is not a hit); string contents are kept, so Color("Name")
#          is still seen. Read-only: it opens Swift files and the plan and writes nothing. It always exits 0, so it can
#          sit in a build log without failing the build.
#          Usage: python3 scripts/design-lint.py            (full report)
#                 python3 scripts/design-lint.py --summary  (only the grouped counts)
# SRP/DRY check: Pass - one job, listing drift; the rules it enforces live in the design language page and the
#          tokens in App/Theme.swift; the package map is parsed from the plan rather than copied here.

import os
import re
import sys
from collections import Counter, defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP = os.path.join(ROOT, "App")
PLAN = os.path.join(ROOT, "plans", "26-Nov-2026-ui-rethink-plan.md")

# Files that are the design system itself, plus the kit folder.
TOKEN_FILES = {"App/Theme.swift", "App/NumberStyle.swift"}
TOKEN_FOLDERS = ("App/Kit/",)

# 3D scene and texture code: raw RGB here is a material, light or bitmap input, not an interface colour. Decided by
# reading each file (see the header). Only colour hits are skipped in these files. Keep the reason beside each entry
# so a later reader can challenge it.
SCENE_FILES = {
    "App/BallTextures.swift": "draws the ball skins (number circles, stripes) into bitmaps for the ball materials",
    "App/SurfaceTextures.swift": "draws the cloth, felt and surface textures used as material images",
    "App/LensTextures.swift": "draws the Lens paint textures (arrows, rings, bursts) applied to scene meshes",
    "App/LensLayer.swift": "builds the Lens entities and their unlit materials (the glow tint) in the 3D scene",
    "App/TableBuilder.swift": "builds the table entities: cloth, rails, pockets and their materials",
    "App/TableFrame.swift": "holds the table's wood and metal material colours (PlatformColor) for the 3D frame",
    "App/TableRoom.swift": "builds the room, floor, lamp and light entities and their materials",
    "App/CueRig.swift": "builds the cue entity and its materials",
    "App/BridgeRing.swift": "builds the bridge ring entity and its material",
    "App/TableDetail.swift": "builds small table detail entities (diamonds, spots) and their materials",
    "App/TableProps.swift": "builds the props (chalk, rest) placed in the scene",
    "App/TableScene.swift": "assembles the RealityKit scene, its bed materials and its lights",
    "App/StartupAssets.swift": "makes every generated picture the table wears (cloth, wood, floor, ball faces)",
    "App/Clips/ClipRenderer.swift": "renders clip frames from the 3D scene (its render background colour)",
    "App/TablePortraits.swift": "renders table portraits from the 3D scene (its render background colour)",
}

# ---- patterns -----------------------------------------------------------------------------------------------------

NAMED = r"(?:white|black|blue|green|red|orange|yellow|pink|purple|gray|grey)"
PATTERNS = [
    ("bare colour", re.compile(r"\bColor\s*\(\s*(?:red|hue|white)\s*:")),
    ("bare colour", re.compile(r"\bColor\s*\(\s*\.(?:sRGB|sRGBLinear|displayP3)\b")),
    ("bare colour", re.compile(r"\bColor\s*\(\s*\"[^\"]*\"")),
    # SwiftUI wrapping a platform colour: Color(uiColor:), Color(nsColor:), Color(.systemBlue) and the like.
    ("bare colour", re.compile(r"\bColor\s*\(\s*(?:uiColor|nsColor|cgColor)\s*:")),
    ("bare colour", re.compile(r"\bColor\s*\(\s*\.(?:system[A-Z]\w*|label|secondaryLabel|tertiaryLabel|separator)\b")),
    ("bare colour", re.compile(r"\b(?:UIColor|NSColor|PlatformColor|CGColor)\s*\(\s*(?:red|white|hue|srgbRed|"
                               r"calibratedRed|calibratedWhite|deviceRed|deviceWhite|displayP3Red|genericGrayGamma2_2Gray|"
                               r"genericRGBSpace|colorSpace|named)\s*:")),
    ("bare colour", re.compile(r"\b(?:UIColor|NSColor|PlatformColor)\s*\.\s*(?:" + NAMED[3:-1] +
                               r"|system[A-Z]\w*|darkGray|lightGray|label|secondaryLabel|labelColor|"
                               r"secondaryLabelColor|windowBackgroundColor|controlAccentColor)\b")),
    ("bare colour", re.compile(r"\bColor\s*\.\s*" + NAMED + r"\b")),
    # A leading-dot named colour, ".white" in ".foregroundStyle(.white)". The character before the dot must not be
    # part of an expression (letter, digit, ")" or "]"), so "ball.red" and "Color.red" (caught above) do not match.
    ("bare colour", re.compile(r"(?<![\w\)\]\.])\.\s*" + NAMED + r"\b(?!\s*[:(])")),
    ("bare colour", re.compile(r"\brgba\s*\(\s*-?[\d.]")),
    ("bare font size", re.compile(r"\.system\s*\(\s*size\s*:\s*-?\d[\d.]*")),
    ("bare font size", re.compile(r"\bsystemFont\s*\(\s*ofSize\s*:\s*-?\d[\d.]*")),
    ("bare font size", re.compile(r"\b(?:monospacedSystemFont|monospacedDigitSystemFont|boldSystemFont)\s*\(\s*"
                                  r"ofSize\s*:\s*-?\d[\d.]*")),
    ("bare font size", re.compile(r"\.custom\s*\(\s*\"[^\"]*\"\s*,\s*size\s*:\s*-?\d[\d.]*")),
    ("bare corner radius", re.compile(r"\bcornerRadius\s*:\s*-?\d[\d.]*")),
    ("bare corner radius", re.compile(r"\.cornerRadius\s*\(\s*-?\d[\d.]*")),
    ("bare corner radius", re.compile(r"\b(?:top|bottom)(?:Leading|Trailing)Radius\s*:\s*-?\d[\d.]*")),
    # A radius parked behind a name: a default argument "cornerRadius: CGFloat = 24", or a constant such as
    # "static let corner: CGFloat = 24" / "let cornerRadius = 12" that a shape reads later.
    ("bare corner radius", re.compile(r"\bcornerRadius\s*:\s*CGFloat\s*=\s*-?\d[\d.]*")),
    ("bare corner radius", re.compile(r"\b(?:let|var)\s+corner(?:Radius)?\w*\s*(?::\s*CGFloat)?\s*=\s*-?\d[\d.]*")),
]

# Lines where a leading-dot colour name is an enum case of the game's own, not a colour: a switch case, or the ball
# colour enum (BallColour in App/TableBallSet.swift) built into a ball look or compared.
CASE_LINE = re.compile(r"^\s*(?:case|default)\b|\bcase\s+\.")
BALL_COLOUR_LINE = re.compile(r"\bBallColour\b|\.plain\s*\(|\.spotted\s*\(|\bspot\s*:|[=!]=\s*\.(?:white|red|yellow)\b|"
                              r"\bColours?\s*\[|\bcolour\s*==|\bBallTextures\s*\.")
# The marker that keeps one line out of the report: "// design-lint: allow <reason>", for a value the design
# language itself fixes outside the tokens (an alpha-only mask stop, say). Use it rarely; the reason is required by
# review, not by the script.
ALLOW_MARK = "design-lint: allow"
# A corner radius on a generated 3D mesh is a bevel in metres, not a screen corner.
MESH_LINE = re.compile(r"\.generate[A-Z]\w*\s*\(")


def strip_comments(text):
    """Blanks out // and /* */ comments, keeping line breaks and string contents (including multi-line strings)."""
    out = []
    i, n = 0, len(text)
    in_block = 0
    in_string = None  # '"' or '"""'
    while i < n:
        c = text[i]
        if in_block:
            if text.startswith("*/", i):
                in_block -= 1
                i += 2
                continue
            if text.startswith("/*", i):
                in_block += 1
                i += 2
                continue
            out.append("\n" if c == "\n" else " ")
            i += 1
            continue
        if in_string:
            if c == "\\" and i + 1 < n:
                out.append(text[i:i + 2])
                i += 2
                continue
            if text.startswith(in_string, i):
                out.append(in_string)
                i += len(in_string)
                in_string = None
                continue
            out.append(c)
            i += 1
            continue
        if text.startswith('"""', i):
            in_string = '"""'
            out.append('"""')
            i += 3
            continue
        if c == '"':
            in_string = '"'
            out.append(c)
            i += 1
            continue
        if text.startswith("//", i):
            j = text.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i))
            i = j
            continue
        if text.startswith("/*", i):
            in_block = 1
            i += 2
            out.append("  ")
            continue
        out.append(c)
        i += 1
    return "".join(out)


def blank_strings(line):
    """Replaces the inside of string literals with spaces, so words like "red" inside a sentence are not hits."""
    return re.sub(r'"(?:\\.|[^"\\])*"', lambda m: '"' + " " * (len(m.group(0)) - 2) + '"', line)


def scan_file(path, rel, scene=False):
    try:
        with open(path, encoding="utf-8") as f:
            text = f.read()
    except (OSError, UnicodeDecodeError) as err:
        print(f"{rel}: could not read ({err})")
        return []
    hits = []
    raw_lines = text.split("\n")
    for number, line in enumerate(strip_comments(text).split("\n"), start=1):
        if not line.strip():
            continue
        # A deliberate exception carries the marker in a comment on its own line, with its reason after it.
        if number <= len(raw_lines) and ALLOW_MARK in raw_lines[number - 1]:
            continue
        plain = blank_strings(line)
        seen = set()
        for kind, pattern in PATTERNS:
            # Color("asset") and .custom("Font", size:) need the string; the rest look at string-free text.
            source = line if '\\"' in pattern.pattern or '"' in pattern.pattern else plain
            if scene and kind == "bare colour":
                continue
            if kind == "bare corner radius" and MESH_LINE.search(plain):
                continue
            for match in pattern.finditer(source):
                if kind == "bare colour" and match.group(0).lstrip().startswith(".") and (
                        CASE_LINE.search(plain) or BALL_COLOUR_LINE.search(plain)):
                    continue
                key = (kind, match.start())
                if key in seen:
                    continue
                seen.add(key)
                hits.append((rel, number, kind, match.group(0).strip()))
    return hits


# ---- the package map ----------------------------------------------------------------------------------------------

def read_packages():
    """Returns [(number, title, [path or folder prefix])] from the plan's '### N. Title' sections and their Files:."""
    try:
        with open(PLAN, encoding="utf-8") as f:
            lines = f.read().split("\n")
    except OSError:
        return []
    packages = []
    current = None
    in_files = False
    for line in lines:
        heading = re.match(r"^###\s+(\d+)\.\s+(.*?)\s*(?:\(.*\))?\s*$", line)
        if heading:
            current = (int(heading.group(1)), heading.group(2), [])
            packages.append(current)
            in_files = False
            continue
        if current is None:
            continue
        if line.startswith("Files:"):
            in_files = True
        elif in_files and (not line.strip() or line.startswith("-") or line.startswith("Done when")):
            in_files = False
        if in_files:
            for path in re.findall(r"App/[\w/.]*", line):
                path = path.rstrip(".")
                if path.endswith(".swift") or path.endswith("/"):
                    current[2].append(path)
    return packages


def packages_for(rel, packages):
    owners = []
    for number, title, paths in packages:
        for path in paths:
            if rel == path or (path.endswith("/") and rel.startswith(path)):
                owners.append((number, title))
                break
    return owners


# ---- main ---------------------------------------------------------------------------------------------------------

def main():
    summary_only = "--summary" in sys.argv[1:]
    hits = []
    for folder, _, files in os.walk(APP):
        for name in sorted(files):
            if not name.endswith(".swift"):
                continue
            path = os.path.join(folder, name)
            rel = os.path.relpath(path, ROOT).replace(os.sep, "/")
            if rel in TOKEN_FILES or rel.startswith(TOKEN_FOLDERS):
                continue
            hits.extend(scan_file(path, rel, scene=rel in SCENE_FILES))
    hits.sort(key=lambda h: (h[0], h[1]))

    print("Breakdown design lint: bare colours, font sizes and corner radii outside Theme, NumberStyle and Kit")
    print(f"Colours not checked in {len(SCENE_FILES)} 3D scene and texture files (named in the script's SCENE_FILES).")
    print()
    if not summary_only:
        for rel, number, kind, text in hits:
            print(f"{rel}:{number}  {kind}  {text}")
        print()

    per_file = defaultdict(Counter)
    for rel, _, kind, _ in hits:
        per_file[rel][kind] += 1

    packages = read_packages()
    titles = {number: title for number, title, _ in packages}
    groups = defaultdict(list)
    for rel in sorted(per_file):
        owners = packages_for(rel, packages)
        if not owners:
            groups["unowned"].append((rel, []))
        for number, _ in owners:
            groups[number].append((rel, [n for n, _ in owners if n != number]))

    def print_group(label, entries):
        total = sum(sum(per_file[rel].values()) for rel, _ in entries)
        print(f"{label}: {total} hits in {len(entries)} files")
        for rel, others in entries:
            counts = per_file[rel]
            detail = ", ".join(f"{counts[k]} {k}" for k in ("bare colour", "bare font size", "bare corner radius")
                               if counts[k])
            shared = f"  (also package {', '.join(str(o) for o in others)})" if others else ""
            print(f"  {rel}: {sum(counts.values())} ({detail}){shared}")
        print()

    print("Summary by package (plans/26-Nov-2026-ui-rethink-plan.md)")
    print()
    ordered = [n for n in range(4, 10) if n in groups] + sorted(n for n in groups if n != "unowned" and not 4 <= n <= 9)
    for number in ordered:
        tag = "" if 4 <= number <= 9 else " (outside the before-launch clean-up, packages 4 to 9)"
        print_group(f"Package {number}, {titles.get(number, '')}{tag}", groups[number])
    if "unowned" in groups:
        print_group("Unowned (no package names the file)", groups["unowned"])

    kinds = Counter(kind for _, _, kind, _ in hits)
    print(f"Total: {len(hits)} hits in {len(per_file)} files ("
          + ", ".join(f"{kinds[k]} {k}" for k in ("bare colour", "bare font size", "bare corner radius")) + ")")
    return 0


if __name__ == "__main__":
    # Exit 0 whatever happens: the report belongs in a build log and must never fail the build.
    try:
        main()
    except BrokenPipeError:
        # The reader (head, a pager) closed the pipe; point stdout at nothing so the exit flush cannot fail.
        try:
            sys.stdout = open(os.devnull, "w")
        except OSError:
            pass
    except Exception as err:  # noqa: BLE001 - any failure is reported as a line, not raised
        try:
            print(f"design-lint stopped early: {type(err).__name__}: {err}")
        except Exception:  # noqa: BLE001 - even the report line must not change the exit code
            pass
    sys.exit(0)
