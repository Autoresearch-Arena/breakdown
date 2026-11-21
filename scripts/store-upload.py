#!/usr/bin/env python3
# Author: Claude Sonnet 5.5 Medium
# Date: 21-November-2026
# PURPOSE: Puts the finished App Store frames of ONE device size into App Store Connect for every language, replacing
#          what the screenshot set held. Currently used for the iPhone Duo (display type APP_IPHONE_DUO).
#          Apple allows ten screenshots per language in a set, and the Duo set takes either screen's size, so the ten
#          are a choice: PICKS below says which frames (device folder + file prefix) go in, in order. The first upload
#          (21-November-2026) sent the ten open-screen frames only; marketing is to pick a mix of open and closed ones.
#          Creates the version's language entries that are missing (locale only; no listing text is sent).
#          Reads: ~/.appstoreconnect/config.json and its .p8 key (never in the repo); frames from
#          /Volumes/Team 4TB/breakdown-build/store-shots/final/<device>/<language>/ (see store/screenshots/README.md).
#          Usage: ~/.appstoreconnect/venv/bin/python scripts/store-upload.py [language ...]   (default: all twelve)
# SRP/DRY check: Pass - the only screenshot uploader; scripts/testflight.py keeps its own few calls for builds.
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
FRAMES = Path("/Volumes/Team 4TB/breakdown-build/store-shots/final")
DISPLAY_TYPE = "APP_IPHONE_DUO"
# Our language folder -> App Store locale.
LOCALES = {"en": "en-US", "de": "de-DE", "es": "es-ES", "fr": "fr-FR", "it": "it", "pt-BR": "pt-BR", "pt": "pt-PT",
           "ru": "ru", "ja": "ja", "ko": "ko", "zh-Hans": "zh-Hans", "ar": "ar-SA"}
# At most ten, in the order shown. (device folder, file-name prefix such as "01"; None = every frame of that device)
PICKS = [("duo-inner", None)]


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
    """Reserve the screenshot, send its bytes in the parts Apple names, then confirm with the file's checksum."""
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


def main():
    languages = sys.argv[1:] or list(LOCALES)
    version = call("GET", f"/v1/apps/{APP_ID}/appStoreVersions?limit=10")["data"][0]["id"]
    existing = {x["attributes"]["locale"]: x["id"] for x in
                call("GET", f"/v1/appStoreVersions/{version}/appStoreVersionLocalizations?limit=50")["data"]}
    for lang in languages:
        locale = LOCALES[lang]
        if locale not in existing:
            existing[locale] = call("POST", "/v1/appStoreVersionLocalizations", {"data": {"type": "appStoreVersionLocalizations",
                "attributes": {"locale": locale}, "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version}}}}})["data"]["id"]
        sets = call("GET", f"/v1/appStoreVersionLocalizations/{existing[locale]}/appScreenshotSets")["data"]
        set_id = next((s["id"] for s in sets if s["attributes"]["screenshotDisplayType"] == DISPLAY_TYPE), None)
        if set_id is None:
            set_id = call("POST", "/v1/appScreenshotSets", {"data": {"type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": DISPLAY_TYPE}, "relationships": {"appStoreVersionLocalization":
                {"data": {"type": "appStoreVersionLocalizations", "id": existing[locale]}}}}})["data"]["id"]
        for old in call("GET", f"/v1/appScreenshotSets/{set_id}/appScreenshots")["data"]:
            call("DELETE", f"/v1/appScreenshots/{old['id']}")
        count = 0
        for device, prefix in PICKS:
            for frame in sorted((FRAMES / device / lang).glob(f"{prefix or ''}*.png")):
                upload(set_id, frame)
                count += 1
        print(f"{lang}: {count} frames", flush=True)


if __name__ == "__main__":
    main()
