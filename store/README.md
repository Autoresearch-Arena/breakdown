<!--
Author: Claude Haiku 5.5 High
Date: 20-November-2026
PURPOSE: The App Store listing text for Breakdown, one file per language in the listing folder. The English file is the
         source; the other eleven are translations of it. Each file holds the name, subtitle, promotional text, keywords and
         description exactly as they should be pasted into App Store Connect, for the same eleven languages the game ships in.
         Nothing here has been uploaded. Apple's limits: name and subtitle 30 characters, promotional text 170, keywords 100,
         description 4000. The file checks happen in the listing merge step, not by hand.
Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, plans/21-Nov-2026-bugs-after-0-6-6-plan.md items 39 and 41:
         the listing is rewritten in all twelve languages around the game as it is now, and the privacy policy and
         support page texts are in store/pages.)
SRP/DRY check: Pass - this folder holds only store copy. The game's own words are in App/Localizable.xcstrings; the
         screenshot framing and headlines are in store/screenshots.
-->
# Store listing

The English file is the source. The eleven language files are translations of it, one per language the game speaks,
in the same informal voice as the game (tu, du, ты). Apple shows each one on the App Store page of its own language.
Any language on the page needs its own screenshots; nothing falls back to English.

What the listing says, in order (version 0.7.0): a pool table that shows its physics (the Lens), six lessons (stop,
follow, draw, cut, curve, jump), real games of eight-ball and nine-ball against a friend or the computer at three
levels, the stroke (power is swing speed), the eleven trick shots and Behind the 8-Ball's twelve spots, the three other
tables, the ten surfaces. Counts come from the game's own lists (TrickShots, EightBallSituations, Lessons, PlaySurface);
change them here in the same change that changes a list. The colour words are the Lens legend's: amber for sliding,
cyan for rolling. The closing line claims exact physics with no exception: since 0.7.0 even a miscue's turn follows from the
stroke, so the same shot always plays out the same way.

Check every file against Apple's limits with `python3 scripts/store-listing-check.py` (it only reads the files).

The listing is uploaded to App Store Connect (the Boss signed off on 21-November-2026 for 0.7.0).

## Privacy policy and support page

`pages/privacy.md` and `pages/support.md` are the texts for the two pages App Store Connect asks for (Privacy Policy
URL and Support URL). They are published on the studio site in the same style as its other game's store pages; the
addresses then go into the app record. The privacy page must stay true to `App/PrivacyInfo.xcprivacy` and to the App
Privacy answer "Data Not Collected": the app has no network code, no account, no ads and no purchases.
