#!/usr/bin/env python3
# Author: Claude Opus 5.5 Medium
# Date: 26-November-2026
# PURPOSE: Sets up Game Center for Breakdown in App Store Connect (0.7.10, Shot of the day plan stage 3 item 2,
#          plans/25-Nov-2026-shot-of-the-day-plan.md), so the boards and achievements the game sends to exist:
#          - turns Game Center on for the app record (its Game Center detail);
#          - the daily board, id breakdown.daily: a recurring board that starts again every day at midnight
#            Coordinated Universal Time, highest score first, scores 0 to 1199 (the daily score's whole range). Ties are
#            Game Center's own rule; nothing here promises players a tie-break;
#          - the streak board, id breakdown.streak: all-time, highest first;
#          - one achievement per entry of the game's catalogue (App/Achievements/Achievement.swift), id "breakdown."
#            plus the game's own permanent id, the same ids App/GameCenter/GameCenterQueue.swift builds (GameCenterIDs);
#          - for every achievement and all twelve languages its name, its sentence (after it is earned) and its hint
#            (before), taken from the game's own translated words: App/Localizable.xcstrings, then the
#            localization/pending files not merged yet. Board names and their unit words are store copy, in
#            store/gamecenter/leaderboards.json;
#          - a picture for each achievement, drawn by store/gamecenter/achievement-art.swift (its symbol on the game's
#            dark ground) into the Team 4TB drive, and uploaded for every language.
#          Points: 800 of Game Center's 1000 are shared out now (a collection counts double a single achievement), so
#          200 stay for achievements added in later versions. Points cannot change once an achievement is live.
#          SAFE BY DEFAULT: with no flag it is a dry run that makes no network call and writes nothing; it reads the
#          game's files and prints every board, achievement, word and picture it would send, with warnings for any
#          missing translation or symbol. --draw also draws the pictures (no network). --apply does the real calls:
#          it draws the pictures, then creates only what is missing (anything already there, matched by its id and
#          language, is left as it is), so it can be run again after a refusal. A missing translation stops --apply.
#          If Apple refuses a step, the script stops and prints Apple's answer; store/README.md has the steps to do
#          that part by hand once.
#          Reads: ~/.appstoreconnect/config.json and its .p8 key (only with --apply; never in the repo), the Swift files
#          named below, the string catalog and the pending translation files.
#          Usage: ~/.appstoreconnect/venv/bin/python scripts/gamecenter-setup.py [--draw | --apply]
# SRP/DRY check: Pass - the only Game Center setup. The request and token helpers follow scripts/store-upload.py (copied,
#          as each store script keeps its own few calls). DELIBERATE DUPLICATION: the game builds its achievement list
#          and words in Swift (Achievements.build, AchievementWords), which a Python script cannot run, so this script
#          reads those Swift files with patterns that follow their present shape. An achievement whose words or symbol
#          cannot be found that way is reported, never invented; if the Swift files change shape, the patterns here
#          change in the same change.
import json
import math
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "App"
CATALOG = APP / "Localizable.xcstrings"
PENDING = ROOT / "localization" / "pending"
LEADERBOARDS = ROOT / "store" / "gamecenter" / "leaderboards.json"
ART_SCRIPT = ROOT / "store" / "gamecenter" / "achievement-art.swift"
# Pictures are build output: they go on the Team 4TB drive, never into the repo or the internal drive.
DRIVE = Path("/Volumes/Team 4TB")
ART_OUT = DRIVE / "breakdown-build" / "gamecenter-art"

API = "https://api.appstoreconnect.apple.com"
APP_ID = "6833700596"
PREFIX = "breakdown."  # GameCenterIDs.prefix in App/GameCenter/GameCenterQueue.swift
# Our language -> App Store Connect locale (the same table as scripts/store-upload.py).
LOCALES = {"en": "en-US", "de": "de-DE", "es": "es-ES", "fr": "fr-FR", "it": "it", "pt-BR": "pt-BR", "pt": "pt-PT",
           "ru": "ru", "ja": "ja", "ko": "ko", "zh-Hans": "zh-Hans", "ar": "ar-SA"}
TRANSLATED = [lang for lang in LOCALES if lang != "en"]
POINTS_NOW = 800      # of Game Center's 1000; the rest waits for later achievements
POINTS_MAX_EACH = 100  # Game Center's limit for one achievement
NAME_LIMIT = 30  # characters, for an achievement's name (Apple refused 32 on 26-Nov-2026)
DESCRIPTION_LIMIT = 120  # characters, for each description (Apple refused 125 on 26-Nov-2026; 255 was wrong)

# The two boards (GameCenterBoard in App/GameCenter/GameCenterQueue.swift).
BOARDS = [
    {"id": PREFIX + "daily", "reference": "Shot of the day", "rangeEnd": "1199", "daily": True},
    {"id": PREFIX + "streak", "reference": "Longest streak", "rangeEnd": "100000", "daily": False},
]


# ---------------------------------------------------------------------------------------------------------------------
# Reading the game's own files


def read(path):
    return path.read_text(encoding="utf-8")


def swift_literal(text):
    """A Swift string literal's contents as the string it makes (only the escapes the game's words use)."""
    return (text.replace('\\"', '"').replace("\\n", "\n").replace("\\t", "\t").replace("\\\\", "\\"))


LITERAL = r'"((?:[^"\\]|\\.)*)"'


def function_body(source, name):
    """The text of one `static func <name>(` in a Swift file, up to the next `static func` or MARK."""
    start = source.index(f"static func {name}(")
    rest = source[start + 1:]
    end = min([i for i in (rest.find("static func "), rest.find("// MARK:")) if i >= 0] or [len(rest)])
    return source[start:start + 1 + end]


def constants(source):
    """`static let name = "value"` pairs of a Swift file."""
    return dict(re.findall(r'static let (\w+) = ' + LITERAL, source))


def achievements():
    """The game's achievements in the list's order: id, symbol and whether it is a collection (for its points).
    Follows Achievements.build() in App/Achievements/Achievement.swift line by line."""
    source = read(APP / "Achievements" / "Achievement.swift")
    consts = constants(source)
    shot_ids = re.findall(LITERAL, re.search(r"static let shotIDs: \[String\] = \[(.*?)\]", source, re.S).group(1))
    shot_symbols = dict(re.findall(r'case ' + LITERAL + r': return ' + LITERAL, function_body(source, "shotSymbol")))
    levels = re.findall(r"case (\w+(?:, \w+)*)$", read(ROOT / "Packages" / "BreakdownCore" / "Sources" /
                                                   "BreakdownRules" / "MatchTypes.swift").split(
        "enum ComputerLevel", 1)[1].split("}", 1)[0], re.M)[0].split(", ")
    build = function_body(source, "build")
    out = []
    for expr, symbol_expr, progress in re.findall(
            r"Achievement\(id: ([^,]+), group: \.\w+,\s*symbol: ([^,]+),\s*progress: \.(\w+)\)", build):
        expr, symbol_expr = expr.strip(), symbol_expr.strip()
        collection = progress != "none"
        if symbol_expr == "shotSymbol(id)":
            symbol = None
        else:
            m = re.fullmatch(LITERAL, symbol_expr)
            symbol = swift_literal(m.group(1)) if m else consts.get(symbol_expr)
        if expr == "id":
            ids = shot_ids
        elif expr.startswith("levelAchievementID"):
            ids = [consts["levelPrefix"] + level for level in levels]
        elif expr.startswith("lessonAchievementID"):
            ids = [consts["lessonPrefix"] + lesson_id for lesson_id, _ in lessons()]
        elif expr.startswith("trickAchievementID"):
            ids = [consts["trickPrefix"] + trick_id for trick_id, _ in tricks()]
        elif re.fullmatch(LITERAL, expr):
            ids = [swift_literal(re.fullmatch(LITERAL, expr).group(1))]
        elif expr in consts:
            ids = [consts[expr]]
        else:
            print(f"warning: cannot read the id {expr!r} in Achievements.build(); left out", flush=True)
            continue
        for gid in ids:
            sym = shot_symbols.get(gid, "star.circle") if symbol is None else symbol
            if sym is None:
                print(f"warning: no symbol found for {gid}; star.circle used", flush=True)
                sym = "star.circle"
            out.append({"id": gid, "symbol": sym, "collection": collection})
    return out


def lessons():
    """(lesson id, English title) in Lessons.all's order (App/Lessons/Lessons.swift, ids from AuthoredLessons)."""
    source = read(APP / "Lessons" / "Lessons.swift")
    authored = read(ROOT / "Packages" / "BreakdownCore" / "Sources" / "BreakdownAuthored" / "AuthoredLessons.swift")
    ids = dict(re.findall(r'public static let (\w+) = AuthoredLesson\(\s*id: ' + LITERAL, authored))
    titles = {name: (authored_name, swift_literal(title)) for name, authored_name, title in re.findall(
        r'static let (\w+) = make\(\s*AuthoredLessons\.(\w+), title: String\(localized: ' + LITERAL, source)}
    order = re.findall(r"\w+", re.search(r"static let all: \[Lesson\] = \[(.*?)\]", source, re.S).group(1))
    return [(ids[titles[n][0]], titles[n][1]) for n in order]


def tricks():
    """(trick id, English title) for every playable trick shot (App/TrickShots.swift, ids from AuthoredTricks)."""
    source = read(APP / "TrickShots.swift")
    authored = read(ROOT / "Packages" / "BreakdownCore" / "Sources" / "BreakdownAuthored" / "AuthoredTricks.swift")
    ids = dict(re.findall(r'public static let (\w+) = AuthoredTrick\(\s*id: ' + LITERAL, authored))
    titles = {name: (authored_name, swift_literal(title)) for name, authored_name, title in re.findall(
        r'static let (\w+) = make\(\s*AuthoredTricks\.(\w+), title: String\(localized: ' + LITERAL, source)}
    order = re.findall(r"\w+", re.search(r"static let authored: \[TrickShot\] = \[(.*?)\]", source, re.S).group(1))
    # make() always builds a playable shot (pending: false); a pending shot would be built another way and is left out.
    return [(ids[titles[n][0]], titles[n][1]) for n in order if n in titles]


def words(items):
    """English name, sentence and hint for each achievement, read from App/Achievements/AchievementWords.swift the way
    its three functions decide them (and HighlightWords.line for the sentences it reuses)."""
    source = read(APP / "Achievements" / "AchievementWords.swift")
    consts = constants(read(APP / "Achievements" / "Achievement.swift"))

    def cases(body):
        """`case X: return String(localized: "...")` pairs, X resolved to an id ("Achievements.everyTable" too)."""
        found = {}
        for key, text in re.findall(r'case ([^:\n]+):\s*return String\(localized: ' + LITERAL, body):
            key = key.strip()
            m = re.fullmatch(LITERAL, key)
            if m:
                found[swift_literal(m.group(1))] = swift_literal(text)
            elif key.startswith("Achievements.") and key.split(".", 1)[1] in consts:
                found[consts[key.split(".", 1)[1]]] = swift_literal(text)
            elif key.startswith("."):
                found[key] = swift_literal(text)  # a ComputerLevel or HighlightKind case, kept as ".easy"
        return found

    def guarded(body, condition):
        m = re.search(re.escape(condition) + r'.*?String\(localized: ' + LITERAL, body, re.S)
        return swift_literal(m.group(1)) if m else None

    name_body, sentence_body, hint_body = (function_body(source, f) for f in ("name", "sentence", "hint"))
    names, sentences, hints = cases(name_body), cases(sentence_body), cases(hint_body)
    highlight = cases(function_body(read(APP / "HighlightWords.swift"), "line"))
    from_highlight = dict((gid, "." + kind) for kind, gid in re.findall(
        r'\(\.(\w+), ' + LITERAL + r'\)', read(APP / "Achievements" / "Achievement.swift")))
    lesson_titles = {consts["lessonPrefix"] + i: t for i, t in lessons()}
    trick_titles = {consts["trickPrefix"] + i: t for i, t in tricks()}

    out = {}
    for item in items:
        gid = item["id"]
        level = gid[len(consts["levelPrefix"]):] if gid.startswith(consts["levelPrefix"]) else None
        if gid in lesson_titles:
            entry = (lesson_titles[gid], guarded(sentence_body, "a.lessonID != nil"), guarded(hint_body, "a.lessonID != nil"))
        elif gid in trick_titles:
            entry = (trick_titles[gid], guarded(sentence_body, "a.trickID != nil"), guarded(hint_body, "a.trickID != nil"))
        elif level is not None:
            entry = (names.get(gid), guarded(sentence_body, "a.level != nil"), hints.get("." + level))
        else:
            sentence = highlight.get(from_highlight[gid]) if gid in from_highlight else sentences.get(gid)
            entry = (names.get(gid), sentence, hints.get(gid))
        out[gid] = dict(zip(("name", "sentence", "hint"), entry))
    return out


def translations():
    """English key -> {language: text}: the string catalog first, then the pending files not merged into it yet."""
    table = {}
    for key, entry in json.loads(read(CATALOG)).get("strings", {}).items():
        for lang, loc in entry.get("localizations", {}).items():
            value = loc.get("stringUnit", {}).get("value")
            if value:
                table.setdefault(key, {})[lang] = value
    for path in sorted(PENDING.glob("*.json")):
        data = json.loads(read(path))
        # Some older files are a bare list of English keys with no translations; only translation rows count.
        for row in data.get("translations", []) if isinstance(data, dict) else data:
            if isinstance(row, dict) and {"key", "culture", "text"} <= row.keys():
                table.setdefault(row["key"], {}).setdefault(row["culture"], row["text"])
    return table


def localized(english, lang, table):
    """One line in one language; English is the key itself. None when the translation is missing."""
    if english is None:
        return None
    if lang == "en":
        return table.get(english, {}).get("en", english)
    return table.get(english, {}).get(lang)


def points(items):
    """POINTS_NOW shared out by weight (a collection 2, a single achievement 1), rounded down, at most 100 each."""
    weights = [2 if item["collection"] else 1 for item in items]
    total = sum(weights) or 1
    return [max(1, min(POINTS_MAX_EACH, math.floor(POINTS_NOW * w / total))) for w in weights]


# ---------------------------------------------------------------------------------------------------------------------
# App Store Connect (only with --apply)

CFG = None


def token():
    import jwt  # only --apply needs it (run with ~/.appstoreconnect/venv/bin/python, which has PyJWT)
    now = int(time.time())
    return jwt.encode({"iss": CFG["issuer_id"], "iat": now, "exp": now + 600, "aud": "appstoreconnect-v1"},
                      Path(CFG["key_path"]).read_text(), algorithm="ES256", headers={"kid": CFG["key_id"], "typ": "JWT"})


def call(method, path, body=None):
    request = urllib.request.Request(API + path, method=method, data=None if body is None else json.dumps(body).encode(),
                                     headers={"Authorization": f"Bearer {token()}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            raw = response.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as error:
        if method == "GET" and error.code == 404:
            return None
        sys.exit(f"Apple said {error.code} for {method} {path}: {error.read().decode()[:800]}\n"
                 "Nothing after this step was sent. store/README.md has the steps to finish by hand.")


def create(kind, attributes, relationships):
    """POST one resource; returns its id."""
    body = {"data": {"type": kind, "attributes": attributes,
                     "relationships": {name: {"data": {"type": t, "id": i}} for name, (t, i) in relationships.items()}}}
    return call("POST", f"/v1/{kind}", body)["data"]["id"]


def listing(path):
    """Every item of a list request, following Apple's next-page links."""
    items, url = [], path
    while url:
        page = call("GET", url)
        if not page:
            break
        items.extend(page.get("data", []))
        nxt = page.get("links", {}).get("next")
        url = nxt[len(API):] if nxt else None
    return items


def upload_image(localization_id, picture):
    """Reserve the achievement picture for one language, send its bytes in Apple's parts, then mark it uploaded."""
    data = picture.read_bytes()
    reserved = call("POST", "/v1/gameCenterAchievementImages", {"data": {"type": "gameCenterAchievementImages",
        "attributes": {"fileName": picture.name, "fileSize": len(data)},
        "relationships": {"gameCenterAchievementLocalization": {"data": {
            "type": "gameCenterAchievementLocalizations", "id": localization_id}}}}})["data"]
    for op in reserved["attributes"]["uploadOperations"]:
        headers = {h["name"]: h["value"] for h in op["requestHeaders"]}
        part = urllib.request.Request(op["url"], method=op["method"],
                                      data=data[op["offset"]:op["offset"] + op["length"]], headers=headers)
        urllib.request.urlopen(part, timeout=120).read()
    call("PATCH", f"/v1/gameCenterAchievementImages/{reserved['id']}", {"data": {
        "type": "gameCenterAchievementImages", "id": reserved["id"], "attributes": {"uploaded": True}}})


# ---------------------------------------------------------------------------------------------------------------------
# The plan, the pictures and the calls


def next_midnight_utc():
    """The first midnight Coordinated Universal Time after now: when the daily board's first day starts."""
    now = datetime.now(timezone.utc)
    return (now + timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)


def plan():
    """Everything to send, read from the game's files, with a list of problems (missing words or translations)."""
    items = achievements()
    english = words(items)
    table = translations()
    problems = []
    for item, pts in zip(items, points(items)):
        item["points"] = pts
        item["locales"] = {}
        for lang in LOCALES:
            texts = {}
            for field in ("name", "sentence", "hint"):
                text = localized(english[item["id"]][field], lang, table)
                # A store-only shorter line where the game's own is past Apple's limit (STORE_SHORTER, below).
                text = STORE_SHORTER.get((item["id"], lang, field), text)
                if text is None:
                    what = "English words" if english[item["id"]][field] is None else f"{lang} translation"
                    problems.append(f"{item['id']}: no {what} for its {field}")
                elif field == "name" and len(text) > NAME_LIMIT:
                    problems.append(f"{item['id']}: {lang} name is over {NAME_LIMIT} characters")
                elif field != "name" and len(text) > DESCRIPTION_LIMIT:
                    problems.append(f"{item['id']}: {lang} {field} is over {DESCRIPTION_LIMIT} characters")
                texts[field] = text
            item["locales"][lang] = texts
    boards = json.loads(read(LEADERBOARDS))
    for board in BOARDS:
        for lang in LOCALES:
            for field in ("name", "suffix", "suffixSingular"):
                if lang not in boards.get(board["id"], {}).get(field, {}):
                    problems.append(f"{board['id']}: no {lang} {field} in {LEADERBOARDS.relative_to(ROOT)}")
    seen = {}
    for item in items:
        if item["id"] in seen:
            problems.append(f"{item['id']}: the id appears twice in the catalogue")
        seen[item["id"]] = True
    return items, boards, problems


def draw(items):
    """Draw every achievement's picture on the Team 4TB drive with the Swift picture script. Returns the folder."""
    if not DRIVE.is_dir():
        sys.exit(f"{DRIVE} is not mounted: the pictures go there, never on the internal drive. Mount it and run again.")
    ART_OUT.mkdir(parents=True, exist_ok=True)
    manifest = ART_OUT / "achievements.json"
    manifest.write_text(json.dumps([{"id": i["id"], "symbol": i["symbol"]} for i in items], indent=1), encoding="utf-8")
    result = subprocess.run(["swift", str(ART_SCRIPT), str(manifest), str(ART_OUT)])
    if result.returncode != 0:
        sys.exit("The picture script failed; nothing was sent to Apple.")
    return ART_OUT


def describe(items, boards, problems):
    """The dry run's report: every board, achievement and word that would be sent."""
    start = next_midnight_utc()
    print("Game Center setup for Breakdown (dry run: nothing is sent; --apply sends it)\n")
    print("Turn on Game Center for the app record, then these two boards:")
    for board in BOARDS:
        kind = (f"recurring every day from {start:%Y-%m-%d %H:%M} UTC" if board["daily"] else "all-time")
        print(f"  {board['id']}: {kind}, highest first, best score kept, scores 0 to {board['rangeEnd']}")
        for lang, locale in LOCALES.items():
            b = boards.get(board["id"], {})
            print(f"    {locale:8} {b.get('name', {}).get(lang)!r}, unit {b.get('suffix', {}).get(lang)!r}")
    print(f"\n{len(items)} achievements, {sum(i['points'] for i in items)} points of 1000 "
          f"({1000 - sum(i['points'] for i in items)} kept for later ones):")
    for item in items:
        print(f"  {PREFIX}{item['id']}: {item['points']} points, symbol {item['symbol']}, picture "
              f"{ART_OUT / (item['id'] + '.png')}")
        for lang, locale in LOCALES.items():
            texts = fit_store_limits(item["id"], lang, item["locales"][lang])
            print(f"    {locale:8} {texts['name']!r} | before: {texts['hint']!r} | after: {texts['sentence']!r}")
    if problems:
        print(f"\n{len(problems)} problems (--apply refuses to run until they are fixed):")
        for p in problems:
            print(f"  {p}")
    else:
        print("\nNo problems found.")


# App Store Connect caps an achievement's descriptions at 120 characters (refused on 26-Nov-2026). The game's own
# sentences are longer in a few languages, so these store-only lines are used there instead. The game keeps its own
# full sentence; only the Game Center copy is shorter. fit_store_limits refuses anything still too long, so a new
# over-long sentence stops the dry run instead of a half-finished --apply.
STORE_SHORTER = {
    ("masse-curve", "es", "sentence"): "Mientras se deslizaba, el paño la llevó hacia donde giraba su efecto, no hacia donde iba.",
    ("run-rack", "de", "hint"): "Im freien Spiel: anstoßen, dann mit jedem Stoß eine Kugel versenken, bis der Tisch leer ist.",
    ("thrown-in", "fr", "name"): "Bille entraînée dedans",
    ("trick-draw-masse-carom", "es", "name"): "Carambola massé con retroceso",
    ("run-rack", "it", "hint"): "In gioco libero: break, poi una palla in buca a ogni colpo finché il tavolo è vuoto.",
}

def fit_store_limits(game_id, lang, texts):
    """The achievement's words for App Store Connect: the game's own, with the store-only shorter lines above where
    a description would pass Apple's limit. Raises when a description is still too long."""
    out = dict(texts)
    for field in ("name", "hint", "sentence"):
        out[field] = STORE_SHORTER.get((game_id, lang, field), out[field])
        if field == "name":
            continue
        if len(out[field]) > DESCRIPTION_LIMIT:
            raise SystemExit(f"{game_id} {lang} {field} is {len(out[field])} characters; Apple allows "
                             f"{DESCRIPTION_LIMIT}. Add a shorter store line to STORE_SHORTER.")
    return out


def apply(items, boards):
    """The real calls. Creates only what is missing; anything already in App Store Connect is left as it is."""
    global CFG
    CFG = json.loads((Path.home() / ".appstoreconnect" / "config.json").read_text())
    art = draw(items)

    # 1. Game Center on for the app record.
    detail = call("GET", f"/v1/apps/{APP_ID}/gameCenterDetail")
    detail_id = detail["data"]["id"] if detail and detail.get("data") else None
    if detail_id is None:
        detail_id = create("gameCenterDetails", {}, {"app": ("apps", APP_ID)})
        print("Game Center turned on for the app record", flush=True)

    # 2. The two boards and their words.
    existing = {lb["attributes"]["vendorIdentifier"]: lb["id"]
                for lb in listing(f"/v1/gameCenterDetails/{detail_id}/gameCenterLeaderboards?limit=200")}
    for board in BOARDS:
        board_id = existing.get(board["id"])
        if board_id is None:
            attributes = {"referenceName": board["reference"], "vendorIdentifier": board["id"],
                          "defaultFormatter": "INTEGER", "submissionType": "BEST_SCORE", "scoreSortType": "DESC",
                          "scoreRangeStart": "0", "scoreRangeEnd": board["rangeEnd"]}
            if board["daily"]:
                # Every twenty-four hours, starting at a midnight Coordinated Universal Time. Apple refuses a
                # day-only duration ("P1D", 409 on 26-Nov-2026) and asks for time parts, so it is "PT24H".
                attributes.update({"recurrenceStartDate": next_midnight_utc().strftime("%Y-%m-%dT%H:%M:%SZ"),
                                   "recurrenceDuration": "PT24H", "recurrenceRule": "FREQ=DAILY;INTERVAL=1"})
            board_id = create("gameCenterLeaderboards", attributes, {"gameCenterDetail": ("gameCenterDetails", detail_id)})
            print(f"{board['id']}: created", flush=True)
        have = {loc["attributes"]["locale"] for loc in listing(f"/v1/gameCenterLeaderboards/{board_id}/localizations?limit=50")}
        words_for = boards[board["id"]]
        for lang, locale in LOCALES.items():
            if locale in have:
                continue
            create("gameCenterLeaderboardLocalizations",
                   {"locale": locale, "name": words_for["name"][lang], "formatterSuffix": words_for["suffix"][lang],
                    "formatterSuffixSingular": words_for["suffixSingular"][lang]},
                   {"gameCenterLeaderboard": ("gameCenterLeaderboards", board_id)})
        print(f"{board['id']}: words in all twelve languages", flush=True)

    # 3. The achievements, their words in every language and their pictures.
    existing = {a["attributes"]["vendorIdentifier"]: a["id"]
                for a in listing(f"/v1/gameCenterDetails/{detail_id}/gameCenterAchievements?limit=200")}
    for item in items:
        # Apple takes only letters, digits, underscores and full stops; the game's ids use dashes, so each dash
        # becomes an underscore here and in GameCenterIDs.achievement.
        vendor = PREFIX + item["id"].replace("-", "_")
        achievement_id = existing.get(vendor)
        if achievement_id is None:
            achievement_id = create("gameCenterAchievements",
                                    {"referenceName": item["locales"]["en"]["name"][:64], "vendorIdentifier": vendor,
                                     "points": item["points"], "showBeforeEarned": True, "repeatable": False},
                                    {"gameCenterDetail": ("gameCenterDetails", detail_id)})
            print(f"{vendor}: created ({item['points']} points)", flush=True)
        have = {loc["attributes"]["locale"]: loc["id"]
                for loc in listing(f"/v1/gameCenterAchievements/{achievement_id}/localizations?limit=50")}
        picture = art / f"{item['id']}.png"
        for lang, locale in LOCALES.items():
            texts = fit_store_limits(item["id"], lang, item["locales"][lang])
            localization_id = have.get(locale)
            if localization_id is None:
                localization_id = create("gameCenterAchievementLocalizations",
                                         {"locale": locale, "name": texts["name"],
                                          "beforeEarnedDescription": texts["hint"],
                                          "afterEarnedDescription": texts["sentence"]},
                                         {"gameCenterAchievement": ("gameCenterAchievements", achievement_id)})
            image = call("GET", f"/v1/gameCenterAchievementLocalizations/{localization_id}/gameCenterAchievementImage")
            if not (image and image.get("data")):
                upload_image(localization_id, picture)
        print(f"{vendor}: words and picture in all twelve languages", flush=True)
    print("\nDone. In App Store Connect, add Game Center to the next app version (iOS and macOS) and pick the two boards "
          "and every achievement for it before submitting; store/README.md says where.")


def main():
    args = sys.argv[1:]
    if args not in ([], ["--draw"], ["--apply"]):
        sys.exit("Usage: gamecenter-setup.py [--draw | --apply]   (no flag: a dry run that sends nothing)")
    items, boards, problems = plan()
    if not args:
        describe(items, boards, problems)
        return
    if args == ["--draw"]:
        folder = draw(items)
        print(f"{len(items)} pictures in {folder}")
        return
    if problems:
        describe(items, boards, problems)
        sys.exit("Not sent: fix the problems listed above first.")
    apply(items, boards)


if __name__ == "__main__":
    main()
