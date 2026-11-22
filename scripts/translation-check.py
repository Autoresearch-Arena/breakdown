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
# Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 item 44: the register check. The game talks to the player as a
#          friend would, in one informal register per language: tu in French, ты in Russian, du in German, tú in
#          Spanish, tu in Italian and European Portuguese, você in Brazilian Portuguese. French and Russian had drifted
#          between formal and informal from one screen to the next. A line that addresses the player formally now fails
#          the check, naming the word that gave it away: French vous, votre and vos, the -ez verb forms and faites or
#          dites; Russian вы and ваш in every form, the -те imperatives and the -ёте verb forms; German Sie, Ihr and
#          Ihnen with a capital in mid-sentence; Spanish usted; Italian Lei and Suo with a capital in mid-sentence;
#          European Portuguese o senhor and a senhora. Ordinary words that only look like a formal form (French assez,
#          Russian полёте) are listed in REGISTER_ALLOW; a new one that trips the check is added there, with care.)
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

# The formal register, per language: (pattern, what it is). A pattern either matches anywhere ("any") or only when the
# word is capitalised in mid-sentence ("mid"), where a capital can only mean the polite form (German Sie, not sie;
# Italian Lei, not lei). Russian words are matched whole, since Python's \b does treat Cyrillic letters as word letters.
CYR = "А-Яа-яЁё"
REGISTER = {
    "fr": [
        ("any", re.compile(r"\b(vous|votre|vos)\b", re.IGNORECASE), "formal vous"),
        ("any", re.compile(r"\b(\w+ez)\b", re.IGNORECASE), "a formal -ez verb form"),
        ("any", re.compile(r"\b(faites|dites)\b", re.IGNORECASE), "a formal verb form"),
    ],
    "ru": [
        ("any", re.compile(rf"(?<![{CYR}])(вы|вас|вам|вами|ваш[{CYR}]*)(?![{CYR}])", re.IGNORECASE), "formal вы"),
        ("any", re.compile(rf"(?<![{CYR}])([{CYR}]+(?:ите|йте|ьте))(?![{CYR}])", re.IGNORECASE), "a formal -те imperative"),
        ("any", re.compile(rf"(?<![{CYR}])([{CYR}]+ёте)(?![{CYR}])", re.IGNORECASE), "a formal -ёте verb form"),
    ],
    "de": [("mid", re.compile(r"\b(Sie|Ihr|Ihre|Ihren|Ihrem|Ihrer|Ihres|Ihnen)\b"), "formal Sie")],
    "es": [("any", re.compile(r"\b(usted|ustedes)\b", re.IGNORECASE), "formal usted")],
    "it": [("mid", re.compile(r"\b(Lei|Suo|Sua|Suoi|Sue)\b"), "formal Lei")],
    "pt": [("any", re.compile(r"\b(o senhor|a senhora)\b", re.IGNORECASE), "formal o senhor")],
}
# Words that only look formal. French: adverbs and nouns ending in -ez. Russian: nouns whose locative or dative ends
# like an imperative or a -ёте verb (on a site, under protection, in flight, on the bill).
REGISTER_ALLOW = {
    "fr": {"assez", "nez", "chez", "rez", "lez"},
    "ru": {"сайте", "защите", "лимите", "орбите", "граните", "визите", "кредите", "элите", "свите",
           "полёте", "отчёте", "счёте", "расчёте", "учёте", "самолёте", "переплёте"},
}


def register_problem(lang, text):
    """None when a line keeps the language's informal register, otherwise a plain sentence naming the formal word."""
    allow = REGISTER_ALLOW.get(lang, set())
    for where, pattern, what in REGISTER.get(lang, []):
        for m in pattern.finditer(text):
            word = m.group(1)
            if word.lower() in allow:
                continue
            if where == "mid":
                # A capital at the start of the line or of a sentence is just a capital.
                before = text[:m.start()].rstrip()
                if not before or before[-1] in ".!?:;«\"“(":
                    continue
            return f"{what} ({word!r}); the game uses the informal register"
    return None

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
                formal = register_problem(lang, value)
                if formal:
                    problems.append((key, lang + label, formal))
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
