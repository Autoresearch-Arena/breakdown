#!/usr/bin/env python3
# Author: Claude Haiku 5.5 High
# Date: 20-November-2026
# PURPOSE: Merges translated Breakdown strings into App/Localizable.xcstrings, the String Catalog Xcode reads.
#          Input: a JSON file holding {"translations": [{"culture", "key", "text"}, ...]}, which is the output of the
#          translation step (one translator per language pair). Output: the catalog, with every English key present
#          and a translated entry for every language the translators returned. A translation is refused, and the
#          key is reported, when its placeholders (%@ and %lld) do not match the English line exactly, because the
#          app would then show a broken sentence or crash on the number. The English text is the key itself, as
#          Xcode writes it; nothing here changes the English.
#          Usage: python3 scripts/localization-merge.py <translations.json> [--keys <keys_en.json>]
# SRP/DRY check: Pass - the only script that writes translations into the catalog. The catalog itself is still
#          maintained by Xcode when someone builds in Xcode; this script only adds translated entries.
# Note: JSON cannot hold a header comment, so this header lives in the script instead.
import json
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "App" / "Localizable.xcstrings"
PLACEHOLDER = re.compile(r"%(?:lld|@)")
ALL_LANGS = ["es", "fr", "de", "it", "pt", "pt-BR", "ja", "ko", "zh-Hans", "ru", "ar"]


def placeholders(text):
    """The placeholders in a line, as a sorted list, so the English and the translation can be compared exactly."""
    return sorted(PLACEHOLDER.findall(text))


def main(argv):
    if not argv:
        print("usage: localization-merge.py <translations.json> [--keys <keys_en.json>]")
        return 2
    translations_path = Path(argv[0])
    keys_path = None
    if "--keys" in argv:
        keys_path = Path(argv[argv.index("--keys") + 1])
    data = json.loads(translations_path.read_text(encoding="utf-8"))
    rows = data["translations"] if isinstance(data, dict) else data

    english = None
    if keys_path:
        english = set(json.loads(keys_path.read_text(encoding="utf-8")))

    catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    strings = catalog.setdefault("strings", {})
    # Every English line gets its own entry, even before a translation arrives, so the catalog lists the whole set.
    for key in sorted(english or []):
        strings.setdefault(key, {})

    accepted = Counter()
    refused = []
    for row in rows:
        culture, key, text = row["culture"], row["key"], row["text"]
        if english is not None and key not in english:
            refused.append((culture, key, "key is not in the English list"))
            continue
        if culture not in ALL_LANGS:
            refused.append((culture, key, "language is not one of the target languages"))
            continue
        if placeholders(text) != placeholders(key):
            refused.append((culture, key, f"placeholders differ: English {placeholders(key)}, translation {placeholders(text)}"))
            continue
        entry = strings.setdefault(key, {"localizations": {}})
        entry.setdefault("localizations", {})[culture] = {
            "stringUnit": {"state": "translated", "value": text}
        }
        accepted[culture] += 1

    CATALOG.write_text(json.dumps(catalog, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    print("accepted per language:")
    for lang in ALL_LANGS:
        print(f"  {lang}: {accepted.get(lang, 0)}")
    if refused:
        print(f"refused {len(refused)} translations:")
        for culture, key, why in refused:
            print(f"  {culture} | {key!r}: {why}")
    missing = []
    if english is not None:
        for lang in ALL_LANGS:
            got = {k for k, v in strings.items() if lang in v.get("localizations", {})}
            gap = sorted(english - got)
            if gap:
                missing.append((lang, len(gap)))
    if missing:
        print("missing translations (language, count):", missing)
    return 0 if not refused and not missing else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
