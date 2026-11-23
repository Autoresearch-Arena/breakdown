#!/usr/bin/env python3
# Author: Claude Opus 5.5 High
# Date: 23-November-2026
# PURPOSE: Puts the App Store preview videos (up to three per language) for current iPhones into App Store Connect,
#          replacing what each language's iPhone 6.9-inch preview set held. The videos are Lens clips the game made of
#          its own trick shots in the store size (886 by 1920, under 30 s), filmed with the self-test launch
#          (-clipSelfTest -clipShape store -trickPlay <shot>) in each language and re-encoded to Apple's preview
#          settings by scripts/store-preview-encode.sh.
#          Reads: ~/.appstoreconnect/config.json and its key (never in the repo), through scripts/store-upload.py's own
#          helpers; videos from /Volumes/Team 4TB/breakdown-build/store-previews/final/<language>/<n>-<shot>.mov, sent in
#          file-name order.
#          Usage: ~/.appstoreconnect/venv/bin/python scripts/store-preview-upload.py [language ...]  (default: all twelve)
# SRP/DRY check: Pass - the token, the API call and the language list come from scripts/store-upload.py (loaded by path,
#          since its name has a dash); only the preview-set and preview calls are new here.
import hashlib
import importlib.util
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("store_upload", ROOT / "store-upload.py")
su = importlib.util.module_from_spec(spec)
spec.loader.exec_module(su)

VIDEOS = Path("/Volumes/Team 4TB/breakdown-build/store-previews/final")
# The 6.9-inch iPhone previews go in the 6.7-inch preview type, as the screenshots do (store-upload.py).
PREVIEW_TYPE = "IPHONE_67"


def upload(set_id, path):
    """Reserve the preview, send its bytes in the parts Apple names, then confirm with the file's checksum."""
    data = path.read_bytes()
    reserved = su.call("POST", "/v1/appPreviews", {"data": {"type": "appPreviews",
        "attributes": {"fileName": f"{path.parent.name}-{path.name}", "fileSize": len(data), "mimeType": "video/quicktime"},
        "relationships": {"appPreviewSet": {"data": {"type": "appPreviewSets", "id": set_id}}}}})["data"]
    for op in reserved["attributes"]["uploadOperations"]:
        headers = {h["name"]: h["value"] for h in op["requestHeaders"]}
        part = urllib.request.Request(op["url"], method=op["method"], data=data[op["offset"]:op["offset"] + op["length"]],
                                      headers=headers)
        urllib.request.urlopen(part, timeout=300).read()
    su.call("PATCH", f"/v1/appPreviews/{reserved['id']}", {"data": {"type": "appPreviews", "id": reserved["id"],
        "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
    return reserved["id"]


def main():
    languages = sys.argv[1:] or list(su.LOCALES)
    versions = su.call("GET", f"/v1/apps/{su.APP_ID}/appStoreVersions?filter[platform]=IOS&limit=10")["data"]
    if not versions:
        sys.exit("The app record has no iOS version to put previews on.")
    version = versions[0]["id"]
    print(f"version {versions[0]['attributes'].get('versionString')} ({versions[0]['attributes'].get('appStoreState')})",
          flush=True)
    existing = {x["attributes"]["locale"]: x["id"] for x in
                su.call("GET", f"/v1/appStoreVersions/{version}/appStoreVersionLocalizations?limit=50")["data"]}
    for lang in languages:
        locale = su.LOCALES[lang]
        videos = sorted((VIDEOS / lang).glob("*.mov"))[:3]
        if not videos:
            print(f"{lang}: no videos; left as it was", flush=True)
            continue
        if locale not in existing:
            print(f"{lang}: the version has no {locale} entry; skipped", flush=True)
            continue
        sets = su.call("GET", f"/v1/appStoreVersionLocalizations/{existing[locale]}/appPreviewSets")["data"]
        set_id = next((s["id"] for s in sets if s["attributes"]["previewType"] == PREVIEW_TYPE), None)
        if set_id is None:
            set_id = su.call("POST", "/v1/appPreviewSets", {"data": {"type": "appPreviewSets",
                "attributes": {"previewType": PREVIEW_TYPE}, "relationships": {"appStoreVersionLocalization":
                {"data": {"type": "appStoreVersionLocalizations", "id": existing[locale]}}}}})["data"]["id"]
        for old in su.call("GET", f"/v1/appPreviewSets/{set_id}/appPreviews?limit=10")["data"]:
            su.call("DELETE", f"/v1/appPreviews/{old['id']}")
        for path in videos:
            upload(set_id, path)
        print(f"{lang}: {len(videos)} previews", flush=True)


if __name__ == "__main__":
    main()
