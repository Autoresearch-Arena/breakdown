<!--
Author: Claude Haiku 5.5 High
Date: 20-November-2026
PURPOSE: The App Store listing text for Breakdown, one file per language in the listing folder. The English file is the
         source; the other eleven are translations of it. Each file holds the name, subtitle, promotional text, keywords and
         description exactly as they should be pasted into App Store Connect, for the same eleven languages the game ships in.
         Nothing here has been uploaded. Apple's limits: name and subtitle 30 characters, promotional text 170, keywords 100,
         description 4000. The file checks happen in the listing merge step, not by hand.
SRP/DRY check: Pass - this folder holds only listing copy. The game's own words are in App/Localizable.xcstrings; the
         screenshots, when made, will go in their own folder.
-->
# Store listing

The English file is the source. The eleven language files are translations of it, one per language the game speaks.
Apple shows each one on the App Store page of its own language. Any language on the page needs its own screenshots;
nothing falls back to English.

Nothing here is uploaded. The listing goes to App Store Connect only after the Boss signs off.
