#!/usr/bin/env python3
# Author: Claude Haiku 5.5 High
# Date: 20-November-2026
# PURPOSE: Checks the App Store listing copy in store/listing/*.json against Apple's limits and the language list. Each
#          file is one language and holds name, subtitle, promotional_text, keywords and description. The script counts
#          characters of each field, reports anything over its limit or missing, and confirms all eleven languages plus
#          English are present. It only reads files and never uploads anything to App Store Connect.
#          Usage: python3 scripts/store-listing-check.py   (exit 0 when everything fits, 1 otherwise)
# SRP/DRY check: Pass - the only checker for listing copy; the limits live in LIMITS below and nowhere else in the repo.
# Note: the limits are Apple's character limits for App Store Connect as of this file's date. Recheck them if Apple changes them.
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LISTING = ROOT / "store" / "listing"
LANGS = ["en", "es", "fr", "de", "it", "pt", "pt-BR", "ja", "ko", "zh-Hans", "ru", "ar"]
# Apple's limits: name and subtitle 30 characters, promotional text 170, keywords 100, description 4000.
LIMITS = {"name": 30, "subtitle": 30, "promotional_text": 170, "keywords": 100, "description": 4000}


def main():
    problems = []
    for lang in LANGS:
        path = LISTING / f"{lang}.json"
        if not path.exists():
            problems.append(f"{lang}: file missing")
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        for field, limit in LIMITS.items():
            text = data.get(field)
            if not text:
                problems.append(f"{lang}: {field} is empty")
                continue
            if len(text) > limit:
                problems.append(f"{lang}: {field} is {len(text)} characters, over the limit of {limit}")
    if problems:
        print("problems:")
        for p in problems:
            print("  " + p)
        return 1
    print("all eleven languages and English fit every limit")
    return 0


if __name__ == "__main__":
    sys.exit(main())
