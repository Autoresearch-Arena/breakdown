#!/usr/bin/env python3
# Author: Claude Opus 5.5 High
# Date: 21-November-2026
# PURPOSE: Fails (exit 1) if the string catalog the app ships, App/Localizable.xcstrings, is not complete in all twelve
#          languages the game speaks: English plus es, fr, de, it, pt, pt-BR, ja, ko, zh-Hans, ru and ar. For every
#          string it checks that each of the eleven translations is present, marked translated, and not empty, and that
#          its placeholders match the English line exactly: the same number of each kind (%@ for text, %lld for a whole
#          number, and the other printf kinds), in the same order, unless the translation numbers them (%1$@ %2$@ ...),
#          in which case every number must point at an English placeholder of the same kind and every one must be used.
#          A wrong placeholder makes the app show a broken sentence or crash on a number, which is why it fails the check.
#          English is the key itself (the catalog's source language), unless the catalog carries its own "en" entry, which
#          is then checked like a translation. Plural and device variations are checked case by case.
#          Strings marked "do not translate" (shouldTranslate false) need no translations, and stale strings Xcode no
#          longer finds in the code are reported but do not fail the check (the next build in Xcode removes them).
#          Reads only the catalog; writes nothing. Usage: python3 scripts/translation-check.py [path to .xcstrings]
#          Prints one line per problem and a summary; exit 0 when there are none.
# SRP/DRY check: Pass - checking only. scripts/localization-merge.py writes translations into the catalog and refuses a
#          mismatched one as it goes; this reads the finished catalog as a whole, so a gap or a hand edit cannot slip
#          through. The language list matches the merge script's and the project's knownRegions.
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "App" / "Localizable.xcstrings"
SOURCE = "en"
TRANSLATIONS = ["es", "fr", "de", "it", "pt", "pt-BR", "ja", "ko", "zh-Hans", "ru", "ar"]

# A printf placeholder: "%", an optional argument number "N$", optional flags, width and precision, an optional length
# (l, ll, h, hh, q, z, t, j), then the conversion. "%%" is a literal percent sign, not a placeholder, and is matched
# first so it is skipped.
PLACEHOLDER = re.compile(
    r"%%|%(?:(?P<pos>\d+)\$)?[-+ #0']*(?:\d+|\*)?(?:\.(?:\d+|\*))?(?P<len>hh|h|ll|l|q|z|t|j|L)?(?P<conv>[@dDiuUxXoOfFeEgGcCsSpaA])"
)


def kinds(text):
    """The placeholders in a line as (argument number or None, kind) pairs in reading order. The kind is the length
    and the conversion (lld, @, f...) so %lld and %d, which take different argument sizes, never count as the same."""
    out = []
    for m in PLACEHOLDER.finditer(text):
        if m.group(0) == "%%":
            continue
        pos = int(m.group("pos")) if m.group("pos") else None
        out.append((pos, (m.group("len") or "") + m.group("conv")))
    return out


def placeholder_problem(english, translated):
    """None when the translation's placeholders fit the English line, otherwise a plain sentence saying why."""
    want = [k for _, k in kinds(english)]
    got = kinds(translated)
    numbered = [p for p, _ in got if p is not None]
    if numbered and len(numbered) != len(got):
        return "mixes numbered and unnumbered placeholders"
    if not numbered:
        have = [k for _, k in got]
        if have != want:
            return f"placeholders {have} do not match English {want}"
        return None
    # Numbered: each number names an English argument (1-based) of the same kind, and every argument is used.
    for p, k in got:
        if p < 1 or p > len(want):
            return f"placeholder %{p}$ points past the {len(want)} English arguments"
        if want[p - 1] != k:
            return f"placeholder %{p}$ is {k!r} but English argument {p} is {want[p - 1]!r}"
    if set(numbered) != set(range(1, len(want) + 1)):
        return f"uses arguments {sorted(set(numbered))} but English has {len(want)}"
    return None


def units(localization):
    """Every (label, stringUnit) in one language's entry: the plain unit, or each case of its plural or device
    variations (nested variations included)."""
    if "stringUnit" in localization:
        yield "", localization["stringUnit"]
    for axis, cases in localization.get("variations", {}).items():
        for case, inner in cases.items():
            for label, unit in units(inner):
                yield f" [{axis} {case}{label}]", unit


def check(catalog):
    """All problems in the catalog as (key, language, why), and the stale keys."""
    problems, stale = [], []
    for key, entry in sorted(catalog.get("strings", {}).items()):
        if entry.get("extractionState") == "stale":
            stale.append(key)
            continue
        if entry.get("shouldTranslate") is False:
            continue
        locs = entry.get("localizations", {})
        # English: the key, unless the catalog stores its own English line for it.
        english = key
        if SOURCE in locs:
            found = list(units(locs[SOURCE]))
            if not found or not any(u.get("value") for _, u in found):
                problems.append((key, SOURCE, "English entry is empty"))
            plain = [u for label, u in found if label == ""]
            if plain and plain[0].get("value"):
                english = plain[0]["value"]
        if not english.strip():
            problems.append((key, SOURCE, "English line is empty"))
        for lang in TRANSLATIONS:
            if lang not in locs:
                problems.append((key, lang, "missing"))
                continue
            found = list(units(locs[lang]))
            if not found:
                problems.append((key, lang, "entry holds no text"))
                continue
            for label, unit in found:
                value = unit.get("value", "")
                if not value.strip():
                    problems.append((key, lang + label, "empty"))
                    continue
                state = unit.get("state", "translated")
                if state not in ("translated", "reviewed"):
                    problems.append((key, lang + label, f"marked {state!r}, not translated"))
                why = placeholder_problem(english, value)
                if why:
                    problems.append((key, lang + label, why))
    return problems, stale


def main(argv):
    path = Path(argv[0]) if argv else CATALOG
    catalog = json.loads(path.read_text(encoding="utf-8"))
    if catalog.get("sourceLanguage", SOURCE) != SOURCE:
        print(f"{path}: source language is {catalog.get('sourceLanguage')!r}, expected {SOURCE!r}")
        return 1
    problems, stale = check(catalog)
    for key, lang, why in problems:
        print(f"{lang:10} {why}: {key!r}")
    for key in stale:
        print(f"stale (not failing; Xcode drops it on the next build): {key!r}")
    total = len(catalog.get("strings", {}))
    print(f"{total} strings, {len(TRANSLATIONS) + 1} languages: {len(problems)} problems, {len(stale)} stale")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
