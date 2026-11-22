#!/usr/bin/env python3
# Author: Claude Sonnet 5.5 Medium
# Date: 21-November-2026
# PURPOSE: Puts the finished App Store frames of ONE device size into App Store Connect for every language, replacing
#          what the screenshot set held, or replaces a single frame in place.
#          Apple allows ten screenshots per language in a set. The frames go in the order of the frame list, which is
#          the key order of store/screenshots/captions/en.json (the same names compose.swift writes), so a frame file
#          left over from an older frame list in the same folder is never sent.
#          The Duo set (display type APP_IPHONE_DUO) takes either screen's size, so its ten are a choice: DUO_PICKS
#          says which device folders go in, in order. The first upload (21-November-2026) sent the ten open-screen
#          frames only; marketing is to pick a mix of open and closed ones.
#          Creates the version's language entries that are missing (locale only; no listing text is sent).
#          Reads: ~/.appstoreconnect/config.json and its .p8 key (never in the repo); frames from
#          /Volumes/Team 4TB/breakdown-build/store-shots/final/<device>/<language>/ (see store/screenshots/README.md).
#          Usage: ~/.appstoreconnect/venv/bin/python scripts/store-upload.py <device> [--frame <name>] [language ...]
#                 <device>: iphone-6.9, ipad-13, mac or duo (default languages: all twelve)
#                 --frame 04-real-table: replace only that frame in each language's set, keeping its place and the
#                 other nine as they are.
# Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, bug plan items 40 and 54: every device, not only the Duo, by
#          its display type; the Mac's frames go to the app record's macOS version and the others to the iOS version
#          (the record has both once scripts/testflight.py has added the Mac), where before it took whichever version
#          came first; frames are chosen by the frame list instead of every PNG in the folder; and --frame replaces one
#          frame in place, so the folding-phone "On a real table" frame, which states numbers from before the physics
#          retune, can be replaced before the rest of the set is re-shot.)
# SRP/DRY check: Pass - the only screenshot uploader; scripts/testflight.py keeps its own few calls for builds. The
#          frame names are read from the captions file compose.swift uses, not listed again here.
import hashlib
import json
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

import jwt

CFG = json.loads((Path.home() / ".appstoreconnect" / "config.json").read_text())
API = "https://api.appstoreconnect.apple.com"
APP_ID = "6833700596"
ROOT = Path(__file__).resolve().parent.parent
FRAMES = Path("/Volumes/Team 4TB/breakdown-build/store-shots/final")
# The frame list, in order: the caption keys (one per frame, the names compose.swift writes).
FRAME_NAMES = list(json.loads((ROOT / "store" / "screenshots" / "captions" / "en.json").read_text()))
# Our language folder -> App Store locale.
LOCALES = {"en": "en-US", "de": "de-DE", "es": "es-ES", "fr": "fr-FR", "it": "it", "pt-BR": "pt-BR", "pt": "pt-PT",
           "ru": "ru", "ja": "ja", "ko": "ko", "zh-Hans": "zh-Hans", "ar": "ar-SA"}
# Device argument -> (App Store Connect display type, the record's platform that holds it, device folders in order).
# The 6.9-inch iPhone frames (1320 x 2868) go in the 6.7-inch display type, which Apple uses for both sizes; the
# 13-inch iPad frames (2064 x 2752) in the 12.9-inch one, likewise.
DUO_PICKS = ["duo-inner"]
DEVICES = {
    "iphone-6.9": ("APP_IPHONE_67", "IOS", ["iphone-6.9"]),
    "ipad-13": ("APP_IPAD_PRO_3GEN_129", "IOS", ["ipad-13"]),
    "mac": ("APP_DESKTOP", "MAC_OS", ["mac"]),
    "duo": ("APP_IPHONE_DUO", "IOS", DUO_PICKS),
}


def token():
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
        sys.exit(f"Apple said {error.code} for {method} {path}: {error.read().decode()[:500]}")


def upload(set_id, path):
    """Reserve the screenshot, send its bytes in the parts Apple names, then confirm with the file's checksum. Returns
    the new screenshot's id."""
    data = path.read_bytes()
    reserved = call("POST", "/v1/appScreenshots", {"data": {"type": "appScreenshots",
        "attributes": {"fileName": f"{path.parent.name}-{path.name}", "fileSize": len(data)},
        "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}})["data"]
    for op in reserved["attributes"]["uploadOperations"]:
        headers = {h["name"]: h["value"] for h in op["requestHeaders"]}
        part = urllib.request.Request(op["url"], method=op["method"], data=data[op["offset"]:op["offset"] + op["length"]], headers=headers)
        urllib.request.urlopen(part, timeout=120).read()
    call("PATCH", f"/v1/appScreenshots/{reserved['id']}", {"data": {"type": "appScreenshots", "id": reserved["id"],
        "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
    return reserved["id"]


def frames_for(folders, lang):
    """The finished frames to send for one language, in order: each device folder in turn, its frames in the frame
    list's order, at most ten in all. A frame not composed yet is skipped with a warning."""
    picked = []
    for folder in folders:
        for name in FRAME_NAMES:
            path = FRAMES / folder / lang / f"{name}.png"
            if path.exists():
                picked.append(path)
            else:
                print(f"warning: {folder}/{lang}/{name}.png not found; skipped", flush=True)
    return picked[:10]


def replace_one(set_id, path, name):
    """Swap the screenshot of frame `name` in a set for the new file, at the same place in the order. If the set has no
    such frame (it was never uploaded), the new one goes at the end."""
    current = call("GET", f"/v1/appScreenshotSets/{set_id}/appScreenshots?limit=50")["data"]
    order = [shot["id"] for shot in current]
    # Uploaded names are "<language>-<frame>.png" (see upload).
    old = next((shot for shot in current if shot["attributes"].get("fileName", "").endswith(f"-{name}.png")), None)
    if old is None:
        upload(set_id, path)
        return
    # Delete first: a full set holds ten, so the new one could not be added beside the old.
    call("DELETE", f"/v1/appScreenshots/{old['id']}")
    order[order.index(old["id"])] = upload(set_id, path)
    call("PATCH", f"/v1/appScreenshotSets/{set_id}/relationships/appScreenshots",
         {"data": [{"type": "appScreenshots", "id": shot_id} for shot_id in order]})


def main():
    args = sys.argv[1:]
    if not args or args[0] not in DEVICES:
        sys.exit(f"Usage: store-upload.py <{'|'.join(DEVICES)}> [--frame <name>] [language ...]")
    display_type, platform, folders = DEVICES[args.pop(0)]
    only = None
    if args[:1] == ["--frame"]:
        if len(args) < 2 or args[1] not in FRAME_NAMES:
            sys.exit(f"--frame takes one of: {', '.join(FRAME_NAMES)}")
        only = args[1]
        args = args[2:]
    languages = args or list(LOCALES)

    # The record's newest version on this platform (iPhone and iPad frames on the iOS one, Mac frames on the macOS one).
    versions = call("GET", f"/v1/apps/{APP_ID}/appStoreVersions?filter[platform]={platform}&limit=10")["data"]
    if not versions:
        sys.exit(f"The app record has no {platform} version to put {display_type} frames on.")
    version = versions[0]["id"]
    existing = {x["attributes"]["locale"]: x["id"] for x in
                call("GET", f"/v1/appStoreVersions/{version}/appStoreVersionLocalizations?limit=50")["data"]}
    for lang in languages:
        locale = LOCALES[lang]
        if locale not in existing:
            existing[locale] = call("POST", "/v1/appStoreVersionLocalizations", {"data": {"type": "appStoreVersionLocalizations",
                "attributes": {"locale": locale}, "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version}}}}})["data"]["id"]
        sets = call("GET", f"/v1/appStoreVersionLocalizations/{existing[locale]}/appScreenshotSets")["data"]
        set_id = next((s["id"] for s in sets if s["attributes"]["screenshotDisplayType"] == display_type), None)
        if set_id is None:
            set_id = call("POST", "/v1/appScreenshotSets", {"data": {"type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": display_type}, "relationships": {"appStoreVersionLocalization":
                {"data": {"type": "appStoreVersionLocalizations", "id": existing[locale]}}}}})["data"]["id"]

        if only:
            # One frame, in place: the first device folder that has it.
            path = next((FRAMES / folder / lang / f"{only}.png" for folder in folders
                         if (FRAMES / folder / lang / f"{only}.png").exists()), None)
            if path is None:
                print(f"{lang}: no {only}.png composed; nothing changed", flush=True)
                continue
            replace_one(set_id, path, only)
            print(f"{lang}: replaced {only}", flush=True)
            continue

        picked = frames_for(folders, lang)
        if not picked:
            print(f"{lang}: no frames composed; the set was left as it was", flush=True)
            continue
        for old in call("GET", f"/v1/appScreenshotSets/{set_id}/appScreenshots?limit=50")["data"]:
            call("DELETE", f"/v1/appScreenshots/{old['id']}")
        for path in picked:
            upload(set_id, path)
        print(f"{lang}: {len(picked)} frames", flush=True)


if __name__ == "__main__":
    main()
