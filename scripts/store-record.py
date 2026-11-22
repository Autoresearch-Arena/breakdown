#!/usr/bin/env python3
# Author: Claude Opus 5.5 High
# Date: 21-November-2026
# PURPOSE: Fills in Breakdown's App Store record from the repo, for every language and both platforms, so a version is
#          ready to submit apart from what only the web page takes (App Privacy answers, the reviewer's phone number):
#          - the store text from store/listing/<language>.json: name and subtitle on the app info, description,
#            keywords and promotional text on the iPhone/iPad version and on the Mac version;
#          - the Privacy Policy URL (app info) and the Support and Marketing URLs (each version), the pages on the
#            studio site (markbarney.net/breakdown/privacy, /support, /breakdown);
#          - the version string of the iPhone/iPad version, set to the project's MARKETING_VERSION;
#          - the age rating answers: nothing in the game needs a rating above the lowest (no violence, no gambling,
#            no web access, no chat, no user content, no ads, no purchases), so every answer is NONE or false;
#          - the category: Games, with Sports and Simulation as its subcategories;
#          - availability: every territory, and new territories as Apple adds them.
#          Reads ~/.appstoreconnect/config.json and its key (never in the repo), through scripts/store-upload.py's
#          sign-in helpers. Safe to run again: it updates what exists and creates only what is missing.
#          Usage: ~/.appstoreconnect/venv/bin/python scripts/store-record.py
# SRP/DRY check: Pass - the only script that writes the record's text and settings; screenshots stay with
#          scripts/store-upload.py (whose token, call, APP_ID and LOCALES this one reuses) and builds with
#          scripts/testflight.py.
import importlib.util
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
_spec = importlib.util.spec_from_file_location("store_upload", ROOT / "scripts" / "store-upload.py")
su = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(su)
call, APP_ID, LOCALES = su.call, su.APP_ID, su.LOCALES

SITE = "https://markbarney.net/breakdown"
PRIVACY_URL, SUPPORT_URL, MARKETING_URL = f"{SITE}/privacy", f"{SITE}/support", SITE


def project_version():
    """MARKETING_VERSION from the project file: the version the uploaded builds carry."""
    text = (ROOT / "Breakdown.xcodeproj" / "project.pbxproj").read_text()
    versions = set(re.findall(r"MARKETING_VERSION = ([0-9.]+);", text))
    assert len(versions) == 1, f"the project carries more than one version: {versions}"
    return versions.pop()


def listing(lang):
    return json.loads((ROOT / "store" / "listing" / f"{lang}.json").read_text())


def editable_versions():
    """The record's versions still being prepared, one per platform (iOS covers iPhone and iPad)."""
    found = call("GET", f"/v1/apps/{APP_ID}/appStoreVersions?limit=20")["data"]
    return {v["attributes"]["platform"]: v for v in found if v["attributes"]["appStoreState"] == "PREPARE_FOR_SUBMISSION"}


def upsert_localizations(list_path, create_type, parent_key, parent_id, values_for):
    """Update each language's localization under a parent (an app info or a version), creating the missing ones."""
    existing = {x["attributes"]["locale"]: x for x in call("GET", f"{list_path}?limit=50")["data"]}
    for lang, locale in LOCALES.items():
        attributes = values_for(lang)
        if locale in existing:
            loc = existing[locale]
            call("PATCH", f"/v1/{create_type}/{loc['id']}",
                 {"data": {"type": create_type, "id": loc["id"], "attributes": attributes}})
        else:
            call("POST", f"/v1/{create_type}", {"data": {"type": create_type,
                 "attributes": {"locale": locale, **attributes},
                 "relationships": {parent_key: {"data": {"type": parent_key + "s", "id": parent_id}}}}})
        print(f"  {locale}: done", flush=True)


def main():
    version = project_version()
    info = next(x for x in call("GET", f"/v1/apps/{APP_ID}/appInfos?limit=5")["data"]
                if x["attributes"].get("state") != "READY_FOR_DISTRIBUTION")

    print("Name, subtitle and privacy policy address, every language")
    upsert_localizations(f"/v1/appInfos/{info['id']}/appInfoLocalizations", "appInfoLocalizations", "appInfo",
                         info["id"], lambda lang: {"name": listing(lang)["name"], "subtitle": listing(lang)["subtitle"],
                                                   "privacyPolicyUrl": PRIVACY_URL})

    for platform, v in editable_versions().items():
        if v["attributes"]["versionString"] != version:
            call("PATCH", f"/v1/appStoreVersions/{v['id']}",
                 {"data": {"type": "appStoreVersions", "id": v["id"], "attributes": {"versionString": version}}})
        print(f"{platform} version {version}: description, keywords, promotional text, support and marketing pages")
        upsert_localizations(f"/v1/appStoreVersions/{v['id']}/appStoreVersionLocalizations",
                             "appStoreVersionLocalizations", "appStoreVersion", v["id"],
                             lambda lang: {"description": listing(lang)["description"],
                                           "keywords": listing(lang)["keywords"],
                                           "promotionalText": listing(lang)["promotional_text"],
                                           "supportUrl": SUPPORT_URL, "marketingUrl": MARKETING_URL})

    # Age rating: every content answer is NONE and every yes/no is false (see the header for why). The answers are
    # read from the record first, so a question Apple adds later is answered on the same rule without a code change:
    # enum questions take NONE, yes/no questions false; the override fields and the kids band are left alone.
    declaration = call("GET", f"/v1/appInfos/{info['id']}/ageRatingDeclaration")["data"]
    skip = {"ageRatingOverride", "ageRatingOverrideV2", "koreaAgeRatingOverride", "kidsAgeBand",
            "gracRatingClassificationNumber", "developerAgeRatingInfoUrl"}
    # Questions Apple asks as yes/no; every other content question takes a frequency (NONE, INFREQUENT_OR_MILD, ...).
    yes_no = {"advertising", "ageAssurance", "gambling", "healthOrWellnessTopics", "lootBox", "messagingAndChat",
              "parentalControls", "unrestrictedWebAccess", "userGeneratedContent", "socialMedia",
              "socialMediaAgeRestricted", "sharedLocation", "datingAndRelationships"}
    answers = {k: (False if k in yes_no else "NONE") for k in declaration["attributes"] if k not in skip}
    call("PATCH", f"/v1/ageRatingDeclarations/{declaration['id']}",
         {"data": {"type": "ageRatingDeclarations", "id": declaration["id"], "attributes": answers}})
    print("Age rating answered: no content that needs a rating")

    call("PATCH", f"/v1/appInfos/{info['id']}", {"data": {"type": "appInfos", "id": info["id"], "relationships": {
        "primaryCategory": {"data": {"type": "appCategories", "id": "GAMES"}},
        "primarySubcategoryOne": {"data": {"type": "appCategories", "id": "GAMES_SPORTS"}},
        "primarySubcategoryTwo": {"data": {"type": "appCategories", "id": "GAMES_SIMULATION"}}}}})
    print("Category: Games (Sports, Simulation)")

    # Availability: every territory Apple lists, and new ones as they come.
    territories = []
    path = "/v1/territories?limit=200"
    while path:
        page = call("GET", path)
        territories += [t["id"] for t in page["data"]]
        nxt = page.get("links", {}).get("next")
        path = nxt.replace(su.API, "") if nxt else None
    included = [{"type": "territoryAvailabilities", "id": f"${{t{i}}}", "attributes": {"available": True},
                 "relationships": {"territory": {"data": {"type": "territories", "id": t}}}}
                for i, t in enumerate(territories)]
    call("POST", "/v2/appAvailabilities", {"data": {"type": "appAvailabilities",
         "attributes": {"availableInNewTerritories": True},
         "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}},
                           "territoryAvailabilities": {"data": [{"type": "territoryAvailabilities", "id": x["id"]}
                                                                for x in included]}}},
         "included": included})
    print(f"Available in {len(territories)} territories and in new ones")


if __name__ == "__main__":
    main()
