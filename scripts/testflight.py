#!/usr/bin/env python3
# Author: Claude Opus 5.5 Low
# Date: 20-November-2026
# PURPOSE: Builds Breakdown for iPhone, iPad and the Mac and puts both apps on TestFlight, start to finish, so every
#          change that lands on main reaches the Boss's phone, his Mac and the public link without anyone doing it by
#          hand. Run by the GitHub workflow .github/workflows/testflight.yml on this Mac Mini's own build runner; it can
#          also be run by hand from the repo.
#          Steps: run the checks (the translation check, the physics tests, the authored-shot check, the app's own
#          tests on one iPhone simulator) and stop, uploading nothing, if any fails; read the app's version from the
#          Xcode project; ask App Store Connect for the highest build number uploaded so far and use the next one
#          (passed to Xcode on the command line, so nothing is committed back); archive and upload the iPhone and iPad
#          app with the team's App Store Connect key; archive and upload the Mac app with the same number, key and
#          export options; wait for Apple to finish processing both; for each, retire every older build of that
#          platform so testers only ever see the newest; add the new one to the public link's group; set its "What to
#          Test" note from the newest CHANGELOG entry's "What:" line; ask Apple for beta review (a refusal, such as
#          "already approved for this version", is fine). The internal group "Mark" gets every build itself.
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
# Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, plans/21-Nov-2026-bugs-after-0-6-6-plan.md items 37 and 38.
#          The Mac ships with the same push: after the iPhone and iPad upload, the same source is archived for
#          generic/platform=macOS with the same build number, key and export options and uploaded. Both are then waited
#          for together and published the same way, each platform on its own (older builds are retired per platform,
#          and a just-uploaded build is never retired, since both platforms share the build number). The Mac's steps
#          never undo the iPhone release: a Mac failure is reported at the end and the run exits non-zero so it shows.
#          The app record is given its macOS platform the first time, because Apple refuses a Mac upload without it.
#          The upload gate gains two checks, one after the other with the others: scripts/translation-check.py on the
#          string catalog (first, because it takes a second), and the app's own tests (the shared scheme's Test
#          action, the BreakdownTests target) on one iPhone simulator, last. Either failing stops the release with
#          the failing names, and nothing is uploaded.)
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

# The two apps one push ships. "api" is App Store Connect's platform name (a build's pre-release version carries it),
# "destination" the archive destination, "folder" where that platform's archive, export and logs go inside the build's
# work folder ("" keeps the iPhone files where earlier runs put them), "dd" its own derived data so the two builds never
# overwrite each other's products.
IOS = {"name": "iPhone and iPad", "api": "IOS", "destination": "generic/platform=iOS", "folder": "", "dd": "dd"}
MAC = {"name": "Mac", "api": "MAC_OS", "destination": "generic/platform=macOS", "folder": "mac", "dd": "dd-mac"}

# The app tests run on this phone: the game targets iPhone 17 Pro and later, so its oldest supported phone is the one
# whose layout and speed the tests should see. Any other available iPhone is the fallback when the runner lacks it.
TEST_PHONE = "iPhone 17 Pro"


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


def builds(platform=None):
    """The app's newest builds, newest first; only one platform's when `platform` (IOS or MAC_OS) is given. Both
    platforms share build numbers, so anything that matches a build by number must name the platform."""
    # The platform lives on each build's pre-release version, so ask for those alongside and match here, rather than
    # rely on a server-side filter: a refused filter would stop the run after the iPhone build was already uploaded.
    found = call("GET", f"/v1/builds?filter[app]={APP_ID}&sort=-uploadedDate&limit=50&include=preReleaseVersion")
    if not platform:
        return found["data"]
    platforms = {item["id"]: item["attributes"].get("platform") for item in found.get("included", [])
                 if item["type"] == "preReleaseVersions"}

    def platform_of(build):
        link = (build.get("relationships", {}).get("preReleaseVersion", {}).get("data") or {})
        return platforms.get(link.get("id"))

    return [build for build in found["data"] if platform_of(build) == platform]


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


def last_lines(log):
    return "Last lines of " + str(log) + ":\n" + "\n".join(Path(log).read_text().splitlines()[-40:])


def run(command, log):
    if execute(command, log) != 0:
        sys.exit("Failed; " + last_lines(log))


def refuse_upload(what, names, log):
    """Stop the release: say what failed, by name, and that nothing was uploaded."""
    lines = [f"Nothing was uploaded: {what} failed."]
    if names:
        lines += ["Failing:"] + [f"  {name}" for name in names]
    else:
        # No names to show (a compile error, for instance): the end of the log says why.
        lines += [last_lines(log)]
    lines.append(f"Full log: {log}")
    sys.exit("\n".join(lines))


def failing_tests(log):
    """The names of the failed tests in an XCTest or Swift Testing log."""
    text = Path(log).read_text()
    # XCTest prints "Test Case '-[Module.Class testName]' failed (...)"; Swift Testing prints "✘ Test name() ... failed".
    names = re.findall(r"Test Case '-\[([^\]]+)\]' failed", text)
    names += re.findall(r"✘ Test (\S+).* failed", text)
    return sorted(set(names))


def test_simulator():
    """The id of the simulator the app tests run on: an available iPhone 17 Pro on the newest iOS runtime, else the
    newest available iPhone of any kind. An id rather than a name, because the same name exists once per runtime."""
    listing = json.loads(subprocess.run(["xcrun", "simctl", "list", "devices", "available", "-j"],
                                        capture_output=True, text=True, check=True).stdout)

    def runtime_version(runtime):
        # Runtime keys look like "com.apple.CoreSimulator.SimRuntime.iOS-27-2"; its major and minor order them. Only
        # those two: a device-specific runtime ("iOS-27-2-iPhone19-4", the folding phone's) carries more numbers that
        # are a device model, not a newer iOS.
        found = re.search(r"\.iOS-(\d+)-(\d+)", runtime)
        return [int(found.group(1)), int(found.group(2))] if found else [0, 0]

    phones = sorted(((runtime_version(runtime), device) for runtime, devices in listing["devices"].items()
                     if ".iOS-" in runtime for device in devices
                     if device.get("isAvailable", True) and "iPhone" in device["name"]),
                    key=lambda pair: pair[0], reverse=True)
    if not phones:
        sys.exit("Nothing was uploaded: no iPhone simulator is installed on this Mac for the app tests.")
    # The exact phone by name ("iPhone 17 Pro", not the Pro Max), or one named for it ("Breakdown iPhone 17 Pro ..."),
    # before any other iPhone.
    for _, device in phones:
        if device["name"] == TEST_PHONE or re.search(re.escape(TEST_PHONE) + r"(\s|$)(?!Max)", device["name"]):
            return device["udid"], device["name"]
    return phones[0][1]["udid"], phones[0][1]["name"]


def check_before_upload():
    """The checks every build must pass before it is numbered, archived or uploaded (release-safety plan, package 1;
    bug plan item 38). One after the other, on the one runner, cheapest first: the string catalog's translations, the
    physics package's tests, every authored trick shot and Behind the 8-Ball escape played on the physics the app
    ships, then the app's own tests on one iPhone simulator. Tests marked as expected failures (the real-table cases
    still waiting on tuning) report but do not fail."""
    logs = OUT / "checks" / time.strftime("%Y%m%d-%H%M%S")
    logs.mkdir(parents=True, exist_ok=True)
    SCRATCH.mkdir(parents=True, exist_ok=True)

    # Every string in all twelve languages, with placeholders that match English. Run with this same Python: the
    # check uses only the standard library.
    translation_log = logs / "translation-check.log"
    if execute([sys.executable, str(ROOT / "scripts" / "translation-check.py")], translation_log) != 0:
        # One line per problem ("<language> <why>: '<key>'"); the summary and "stale" notes are not problems.
        lines = translation_log.read_text().splitlines()
        names = [line for line in lines if line and not line.startswith("stale") and " strings, " not in line]
        refuse_upload("the translation check", names, translation_log)
    say("Every string is translated in all twelve languages")

    tests_log = logs / "package-tests.log"
    if execute(["swift", "test", "--package-path", str(PACKAGE), "--scratch-path", str(SCRATCH)], tests_log) != 0:
        refuse_upload("the physics package tests", failing_tests(tests_log), tests_log)
    say("Physics package tests pass")

    content_log = logs / "authored-shots.log"
    # Release build: the check plays dozens of full shots and the release solver is many times faster.
    if execute(["swift", "run", "-c", "release", "--package-path", str(PACKAGE), "--scratch-path", str(SCRATCH),
                "BreakProbe", "verify"], content_log) != 0:
        # BreakProbe prints "FAIL trick <id>: <why>" or "FAIL eightball <situation> <escape>: <why>" per broken shot.
        names = [line[5:] for line in content_log.read_text().splitlines() if line.startswith("FAIL ")]
        refuse_upload("the authored trick shot and Behind the 8-Ball check", names, content_log)
    say("Every authored trick shot and Behind the 8-Ball escape still works")

    # The app's own tests: the shared scheme's Test action runs the BreakdownTests target hosted in the app. One
    # simulator, tests one after the other (no clones), derived data on the big drive. They take several minutes,
    # mostly the escape sweeps and the full-rack caption checks on slow surfaces; slow is not a hang.
    udid, phone = test_simulator()
    app_tests_log = logs / "app-tests.log"
    if execute(["xcodebuild", "-project", "Breakdown.xcodeproj", "-scheme", "Breakdown",
                "-destination", f"platform=iOS Simulator,id={udid}", "-parallel-testing-enabled", "NO",
                "-derivedDataPath", str(OUT / "test-dd"), "-jobs", "4", "test"], app_tests_log) != 0:
        refuse_upload(f"the app tests (on {phone})", failing_tests(app_tests_log), app_tests_log)
    say(f"App tests pass on {phone}")


def ensure_mac_platform(version):
    """The app record must list macOS before Apple accepts a Mac upload. Adding the platform is making the record's
    first macOS version, so do that once, with the app's own version number. Soft: if Apple refuses, the Mac upload
    that follows says why."""
    found = call("GET", f"/v1/apps/{APP_ID}/appStoreVersions?filter[platform]=MAC_OS&limit=1", soft=True)
    if found.get("data"):
        return
    made = call("POST", "/v1/appStoreVersions",
                {"data": {"type": "appStoreVersions", "attributes": {"platform": "MAC_OS", "versionString": version},
                          "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}}}}, soft=True)
    if made.get("data"):
        say(f"Added the Mac to the app record (macOS version {version})")


def archive_and_upload(platform, build, work, key):
    """Archive one platform's app and upload it. Returns None when it is on its way to Apple, or the reason it is not
    (the end of the failing log). The caller decides whether a failure stops the run."""
    folder = work / platform["folder"] if platform["folder"] else work
    folder.mkdir(parents=True, exist_ok=True)
    archive = folder / "Breakdown.xcarchive"
    archive_log = folder / "archive.log"
    if execute(["xcodebuild", "-project", "Breakdown.xcodeproj", "-scheme", "Breakdown", "-configuration", "Release",
                "-destination", platform["destination"], "-archivePath", str(archive),
                # The app's entitlements need a development identity at archive time; export re-signs it for the
                # App Store (on the Mac, with the distribution and installer certificates the key's account manages).
                "-derivedDataPath", str(OUT / platform["dd"]), "-jobs", "4", f"DEVELOPMENT_TEAM={TEAM}",
                "CODE_SIGN_IDENTITY=Apple Development", f"CURRENT_PROJECT_VERSION={build}", "archive"] + key,
               archive_log) != 0:
        return last_lines(archive_log)

    # The same export options serve both platforms: an App Store Connect upload, signed automatically.
    options = folder / "Upload.plist"
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
    upload_log = folder / "upload.log"
    if execute(["xcodebuild", "-exportArchive", "-archivePath", str(archive), "-exportOptionsPlist", str(options),
                "-exportPath", str(folder / "export")] + key, upload_log) != 0:
        return last_lines(upload_log)
    say(f"Uploaded the {platform['name']} app")
    return None


def wait_for_processing(build, platforms):
    """Wait until Apple has finished processing this build number on every platform given. Returns each platform's
    build record by its api name ({} for one that never finished)."""
    done = {}
    # Apple usually takes a few minutes; give it up to an hour before calling a platform failed.
    for _ in range(120):
        for platform in platforms:
            if platform["api"] in done:
                continue
            found = [b for b in builds(platform["api"]) if b["attributes"]["version"] == str(build)]
            if found and found[0]["attributes"]["processingState"] in ("VALID", "INVALID", "FAILED"):
                done[platform["api"]] = found[0]
        if len(done) == len(platforms):
            break
        time.sleep(30)
    return done


def publish(platform, new, keep_ids, version, soft):
    """Give testers this platform's new build: retire its older builds, add it to the public group, set the note and
    ask for beta review. `keep_ids` are every build this run uploaded, never retired whatever the platform filter
    returns. `soft` makes the group step optional (the Mac's), so a refusal there cannot stop the run."""
    # Testers see only the newest build; older ones of this platform leave TestFlight and the review queue.
    for old in builds(platform["api"]):
        if old["id"] not in keep_ids and not old["attributes"]["expired"]:
            call("PATCH", f"/v1/builds/{old['id']}",
                 {"data": {"type": "builds", "id": old["id"], "attributes": {"expired": True}}}, soft=True)
            say(f"Retired {platform['name']} build {old['attributes']['version']}")

    set_whats_new(new["id"], whats_new(version))
    call("POST", f"/v1/betaGroups/{PUBLIC_GROUP}/relationships/builds",
         {"data": [{"type": "builds", "id": new["id"]}]}, soft=soft)
    review = call("POST", "/v1/betaAppReviewSubmissions",
                  {"data": {"type": "betaAppReviewSubmissions",
                            "relationships": {"build": {"data": {"type": "builds", "id": new["id"]}}}}}, soft=True)
    state = review.get("data", {}).get("attributes", {}).get("betaReviewState", "not needed or already approved")
    say(f"Breakdown {version} build {new['attributes']['version']} for {platform['name']} is on TestFlight; "
        f"public link review: {state}")


def main():
    if not DRIVE.is_dir():
        sys.exit("The Team 4TB drive is not mounted; build output must not go on the internal drive.")
    check_before_upload()
    version = marketing_version()
    # Both platforms' builds count: they share one sequence of build numbers.
    numbers = [int(b["attributes"]["version"]) for b in builds() if b["attributes"]["version"].isdigit()]
    local = int(re.search(r"CURRENT_PROJECT_VERSION = (\d+);", PROJECT.read_text()).group(1))
    build = max(numbers + [local]) + 1
    say(f"Building Breakdown {version} build {build} for iPhone, iPad and the Mac")

    work = OUT / str(build)
    work.mkdir(parents=True, exist_ok=True)
    key = ["-allowProvisioningUpdates", "-authenticationKeyPath", CFG["key_path"],
           "-authenticationKeyID", CFG["key_id"], "-authenticationKeyIssuerID", CFG["issuer_id"]]

    # The iPhone and iPad app first, as before: if it fails, the run stops with nothing published.
    failure = archive_and_upload(IOS, build, work, key)
    if failure:
        sys.exit("The iPhone and iPad archive or upload failed; " + failure)
    uploaded = [IOS]

    # Then the Mac app, from the same source and build number. A failure here is kept for the end, so the iPhone
    # build still reaches testers.
    ensure_mac_platform(version)
    mac_failure = archive_and_upload(MAC, build, work, key)
    if mac_failure is None:
        uploaded.append(MAC)
    say("Waiting for Apple to process " + " and ".join(p["name"] for p in uploaded))

    processed = wait_for_processing(build, uploaded)
    new_ios = processed.get(IOS["api"])
    if not new_ios or new_ios["attributes"]["processingState"] != "VALID":
        sys.exit(f"Build {build} for {IOS['name']} did not finish processing as valid: "
                 f"{new_ios and new_ios['attributes']['processingState']}")
    keep_ids = {record["id"] for record in processed.values()}
    publish(IOS, new_ios, keep_ids, version, soft=False)

    if MAC in uploaded:
        new_mac = processed.get(MAC["api"])
        if new_mac and new_mac["attributes"]["processingState"] == "VALID":
            publish(MAC, new_mac, keep_ids, version, soft=True)
        else:
            mac_failure = (f"build {build} did not finish processing as valid: "
                           f"{new_mac and new_mac['attributes']['processingState']}")
    if mac_failure:
        # The iPhone build is out; say plainly that the Mac one is not, and fail the run so the workflow shows it.
        sys.exit(f"The iPhone and iPad build is on TestFlight, but the Mac build is not: {mac_failure}")


if __name__ == "__main__":
    main()
