#!/usr/bin/env python3
# Author: Claude Opus 5.5 Low
# Date: 20-November-2026
# PURPOSE: Builds Breakdown for iPhone and puts it on TestFlight, start to finish, so every change that lands on main
#          reaches the Boss's phone and the public link without anyone doing it by hand. Run by the GitHub workflow
#          .github/workflows/testflight.yml on this Mac Mini's own build runner; it can also be run by hand from the repo.
#          Steps: run the physics tests and the authored-shot check and stop, uploading nothing, if either fails; read
#          the app's version from the Xcode project; ask App Store Connect for the highest build number
#          uploaded so far and use the next one (passed to Xcode on the command line, so nothing is committed back);
#          archive and upload with the team's App Store Connect key; wait for Apple to finish processing; retire every
#          older build so testers only ever see the newest; add the new one to the public link's group; set its
#          "What to Test" note from the newest CHANGELOG entry's "What:" line; ask Apple for beta review (a refusal,
#          such as "already approved for this version", is fine). The internal group "Mark" gets every build itself.
#          Reads: the key settings in ~/.appstoreconnect/config.json and its .p8 key file (never in the repo).
#          Writes: archives and logs under /Volumes/Team 4TB/breakdown-build/ci/ (big data stays off the internal drive);
#          refuses to run when that drive is not mounted.
#          Needs: Xcode, and PyJWT (run with ~/.appstoreconnect/venv/bin/python, which has it).
# Edited: Claude Opus 5.5 Medium, 21-November-2026 (the "What to Test" note is now updated when Apple has already made
#          an empty one for the build; before, the second note was refused every run and testers saw no note).
# Edited: Claude Opus 5.5 High, 21-November-2026 (checks before upload, plans/21-Nov-2026-release-safety-plan.md
#          package 1: before anything is numbered, archived or sent to Apple, the physics package's tests run, then
#          BreakProbe plays every authored trick shot and Behind the 8-Ball escape ("BreakProbe verify"). If either
#          fails the script stops, uploads nothing and prints the names of what failed. Both use a package scratch
#          folder on the Team 4TB drive (/Volumes/Team 4TB/breakdown-build/spm) and run one after the other, never in
#          parallel; their logs go under /Volumes/Team 4TB/breakdown-build/ci/checks/.)
# SRP/DRY check: Pass - the only release script in this repo. It talks to App Store Connect on its own (a few calls)
#          instead of importing the dog game's helper, so this repo does not depend on another checkout.
import json
import os
import re
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path

import jwt

ROOT = Path(__file__).resolve().parent.parent
PROJECT = ROOT / "Breakdown.xcodeproj" / "project.pbxproj"
CHANGELOG = ROOT / "CHANGELOG.md"
DRIVE = Path("/Volumes/Team 4TB")
OUT = DRIVE / "breakdown-build" / "ci"
PACKAGE = ROOT / "Packages" / "BreakdownCore"
# The physics package's build folder for the checks, kept between runs so each run only rebuilds what changed.
SCRATCH = DRIVE / "breakdown-build" / "spm"
API = "https://api.appstoreconnect.apple.com"
APP_ID = "6833700596"                                  # Breakdown: See the Physics
TEAM = "4VTS722U8L"
PUBLIC_GROUP = "7cfbd7c5-a4ae-4024-a023-7a5f7a13b381"  # the external group that owns the public link
CFG = json.loads((Path.home() / ".appstoreconnect" / "config.json").read_text())


def say(text):
    print(text, flush=True)


def token():
    now = int(time.time())
    return jwt.encode({"iss": CFG["issuer_id"], "iat": now, "exp": now + 600, "aud": "appstoreconnect-v1"},
                      Path(CFG["key_path"]).read_text(), algorithm="ES256",
                      headers={"kid": CFG["key_id"], "typ": "JWT"})


def call(method, path, body=None, soft=False):
    request = urllib.request.Request(API + path, method=method,
                                     data=None if body is None else json.dumps(body).encode(),
                                     headers={"Authorization": f"Bearer {token()}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            raw = response.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as error:
        detail = error.read().decode()[:400]
        if soft:
            say(f"Apple declined an optional step ({error.code}): {detail}")
            return {}
        sys.exit(f"Apple said {error.code} for {method} {path}: {detail}")


def builds():
    return call("GET", f"/v1/builds?filter[app]={APP_ID}&sort=-uploadedDate&limit=50")["data"]


def marketing_version():
    found = set(re.findall(r"MARKETING_VERSION = ([0-9.]+);", PROJECT.read_text()))
    if len(found) != 1:
        sys.exit(f"Expected one app version in the Xcode project, found {sorted(found)}")
    return found.pop()


def whats_new(version):
    """The 'What:' line of the newest CHANGELOG entry, as plain text for testers."""
    text = CHANGELOG.read_text()
    match = re.search(r"^- What: (.+)$", text, re.M)
    note = match.group(1).strip() if match else f"Breakdown {version}."
    return note[:3900]


def set_whats_new(build_id, note):
    """Put the tester note on a build. Apple often makes an empty en-US note for a new build by itself, and a second
    one for the same language is refused, so an existing note is updated and a new one made only when there is none."""
    existing = [loc for loc in call("GET", f"/v1/builds/{build_id}/betaBuildLocalizations").get("data", [])
                if loc["attributes"].get("locale") == "en-US"]
    if existing:
        call("PATCH", f"/v1/betaBuildLocalizations/{existing[0]['id']}",
             {"data": {"type": "betaBuildLocalizations", "id": existing[0]["id"], "attributes": {"whatsNew": note}}},
             soft=True)
    else:
        call("POST", "/v1/betaBuildLocalizations",
             {"data": {"type": "betaBuildLocalizations", "attributes": {"locale": "en-US", "whatsNew": note},
                       "relationships": {"build": {"data": {"type": "builds", "id": build_id}}}}}, soft=True)
    say("Set the What to Test note")


def execute(command, log):
    """Run a command with its output in a log file; return its exit status."""
    say("$ " + " ".join(command))
    with open(log, "w") as handle:
        # nice keeps the shared Mac responsive while Xcode and Swift compile.
        result = subprocess.run(["nice", "-n", "10"] + command, stdout=handle, stderr=subprocess.STDOUT, cwd=ROOT)
    return result.returncode


def run(command, log):
    if execute(command, log) != 0:
        tail = Path(log).read_text().splitlines()[-40:]
        sys.exit("Failed; last lines of " + str(log) + ":\n" + "\n".join(tail))


def refuse_upload(what, names, log):
    """Stop the release: say what failed, by name, and that nothing was uploaded."""
    lines = [f"Nothing was uploaded: {what} failed."]
    if names:
        lines += ["Failing:"] + [f"  {name}" for name in names]
    else:
        # No names to show (a compile error, for instance): the end of the log says why.
        lines += [f"Last lines of {log}:"] + Path(log).read_text().splitlines()[-40:]
    lines.append(f"Full log: {log}")
    sys.exit("\n".join(lines))


def check_before_upload():
    """The checks every build must pass before it is numbered, archived or uploaded (release-safety plan, package 1).
    One after the other, on the one runner: the physics package's tests, then every authored trick shot and Behind the
    8-Ball escape played on the physics the app ships. Tests marked as expected failures (the real-table cases still
    waiting on tuning) report but do not fail."""
    logs = OUT / "checks" / time.strftime("%Y%m%d-%H%M%S")
    logs.mkdir(parents=True, exist_ok=True)
    SCRATCH.mkdir(parents=True, exist_ok=True)

    tests_log = logs / "package-tests.log"
    if execute(["swift", "test", "--package-path", str(PACKAGE), "--scratch-path", str(SCRATCH)], tests_log) != 0:
        text = tests_log.read_text()
        # XCTest prints "Test Case '-[Module.Class testName]' failed (...)"; Swift Testing prints "✘ Test name() ... failed".
        names = re.findall(r"Test Case '-\[([^\]]+)\]' failed", text)
        names += re.findall(r"✘ Test (\S+).* failed", text)
        refuse_upload("the physics package tests", sorted(set(names)), tests_log)
    say("Physics package tests pass")

    content_log = logs / "authored-shots.log"
    # Release build: the check plays dozens of full shots and the release solver is many times faster.
    if execute(["swift", "run", "-c", "release", "--package-path", str(PACKAGE), "--scratch-path", str(SCRATCH),
                "BreakProbe", "verify"], content_log) != 0:
        # BreakProbe prints "FAIL trick <id>: <why>" or "FAIL eightball <situation> <escape>: <why>" per broken shot.
        names = [line[5:] for line in content_log.read_text().splitlines() if line.startswith("FAIL ")]
        refuse_upload("the authored trick shot and Behind the 8-Ball check", names, content_log)
    say("Every authored trick shot and Behind the 8-Ball escape still works")


def main():
    if not DRIVE.is_dir():
        sys.exit("The Team 4TB drive is not mounted; build output must not go on the internal drive.")
    check_before_upload()
    version = marketing_version()
    numbers = [int(b["attributes"]["version"]) for b in builds() if b["attributes"]["version"].isdigit()]
    local = int(re.search(r"CURRENT_PROJECT_VERSION = (\d+);", PROJECT.read_text()).group(1))
    build = max(numbers + [local]) + 1
    say(f"Building Breakdown {version} build {build}")

    work = OUT / str(build)
    work.mkdir(parents=True, exist_ok=True)
    archive = work / "Breakdown.xcarchive"
    key = ["-allowProvisioningUpdates", "-authenticationKeyPath", CFG["key_path"],
           "-authenticationKeyID", CFG["key_id"], "-authenticationKeyIssuerID", CFG["issuer_id"]]
    run(["xcodebuild", "-project", "Breakdown.xcodeproj", "-scheme", "Breakdown", "-configuration", "Release",
         "-destination", "generic/platform=iOS", "-archivePath", str(archive),
         # The app's entitlements need a development identity at archive time; export re-signs it for the App Store.
         "-derivedDataPath", str(OUT / "dd"), "-jobs", "4", f"DEVELOPMENT_TEAM={TEAM}", "CODE_SIGN_IDENTITY=Apple Development",
         f"CURRENT_PROJECT_VERSION={build}", "archive"] + key, work / "archive.log")

    options = work / "Upload.plist"
    options.write_text(f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>method</key><string>app-store-connect</string>
<key>destination</key><string>upload</string>
<key>teamID</key><string>{TEAM}</string>
<key>signingStyle</key><string>automatic</string>
<key>manageAppVersionAndBuildNumber</key><false/>
<key>uploadSymbols</key><true/>
</dict></plist>
""")
    run(["xcodebuild", "-exportArchive", "-archivePath", str(archive), "-exportOptionsPlist", str(options),
         "-exportPath", str(work / "export")] + key, work / "upload.log")
    say("Uploaded; waiting for Apple to process it")

    # Apple usually takes a few minutes; give it up to an hour before calling the run failed.
    new = None
    for _ in range(120):
        found = [b for b in builds() if b["attributes"]["version"] == str(build)]
        if found and found[0]["attributes"]["processingState"] in ("VALID", "INVALID", "FAILED"):
            new = found[0]
            break
        time.sleep(30)
    if not new or new["attributes"]["processingState"] != "VALID":
        sys.exit(f"Build {build} did not finish processing as valid: {new and new['attributes']['processingState']}")

    # Testers see only the newest build; older ones leave TestFlight and the review queue.
    for old in builds():
        if old["id"] != new["id"] and not old["attributes"]["expired"]:
            call("PATCH", f"/v1/builds/{old['id']}",
                 {"data": {"type": "builds", "id": old["id"], "attributes": {"expired": True}}}, soft=True)
            say(f"Retired build {old['attributes']['version']}")

    set_whats_new(new["id"], whats_new(version))
    call("POST", f"/v1/betaGroups/{PUBLIC_GROUP}/relationships/builds",
         {"data": [{"type": "builds", "id": new["id"]}]})
    review = call("POST", "/v1/betaAppReviewSubmissions",
                  {"data": {"type": "betaAppReviewSubmissions",
                            "relationships": {"build": {"data": {"type": "builds", "id": new["id"]}}}}}, soft=True)
    state = review.get("data", {}).get("attributes", {}).get("betaReviewState", "not needed or already approved")
    say(f"Breakdown {version} build {build} is on TestFlight; public link review: {state}")


if __name__ == "__main__":
    main()
