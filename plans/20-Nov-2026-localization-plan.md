<!--
Author: Claude Haiku 5.5 High
Date: 20-November-2026
PURPOSE: The working plan for localizing Breakdown into the same languages the dog game ships in, and for making
         sure every new piece of player-facing text is written so it can be translated. Says what is being
         translated, how the translations are kept, which languages, and how the work is checked.
SRP/DRY check: Pass - checked the dog game's language list and its localization tool first; this plan reuses its
         language list and its rules (every line translated, placeholders kept, nothing shipped half-done) and
         uses Apple's own String Catalog for the text, because Breakdown is a Swift app and not Unreal.
-->
# Localization for Breakdown

## Why this plan exists

Breakdown speaks English only. The Boss wants the next build to ship in the same languages the dog game does, and
wants every new line of player text written with translation in mind from now on. This plan is the record of how
that is done.

## What is being translated

- Every line the player can read: menus, buttons, tips, the how-to steps, the options screen, the shot panel, the
  playback controls, the Mac menus and tooltips, the caption cards that explain each shot, and the comparison text
  shown after a retry.
- The English stays the source. The app keeps its English text as the fallback.

## Languages

The target languages come from the dog game's own list (its language file, Content/Data/Languages.json in the dog
game). They are Spanish, French, German, Italian, Portuguese, Brazilian Portuguese, Japanese, Korean, Simplified
Chinese, Russian and Arabic. Arabic is on that list but was not yet finished in the dog game, so it is included here
and flagged as needing a right-to-left check.

## How the text is kept

- All Breakdown translations live in one Apple String Catalog file in the App folder. Xcode reads and updates it.
- Text that is written directly in a view is already translatable once it is in the catalog.
- Text that is built in ordinary strings (the caption cards, the retry comparison, the stage titles, the how-to
  steps) is wrapped so the catalog can find it. Numbers stay as placeholders, never typed into the translation.
- Units such as metres per second and the symbol for seconds stay as they are; the words around them are
  translated.
- The physics package does not show words to the player, so it is left alone.

## Rules going forward

- Every new piece of player-facing text goes through the catalog. No new plain English strings in views or captions.
- Any sentence that includes a number, a name or a changing value uses a placeholder, not string joining.
- The coding standards file carries this rule, so every later session reads it.
- A change to English text means the translations for that line are updated in the same change.

## Steps

1. Add the empty catalog and set the list of languages the app knows.
2. Build once so Xcode lists every view string in the catalog.
3. Wrap the text that lives in ordinary strings.
4. Have translators (one subagent per pair of languages) write translations of every line, keeping placeholders.
5. Merge the translations into the catalog and check that nothing is missing.
6. Build for Mac and for iPhone and run the package tests.
7. Record the change in the changelog as version 0.5.3, with the build number moved on for TestFlight.

## How it is checked

- The catalog must have every line in every language, with none missing and none left in English by accident.
- Each translation must keep the same placeholders as its English line.
- Both the Mac and the iPhone builds must pass.
- The physics package tests must still pass.
- Arabic is marked as not yet checked for right-to-left layout on a phone.
