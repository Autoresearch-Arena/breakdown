<!--
Author: Claude Fable 5.2 Medium
Date: 25-November-2026
PURPOSE: Build plan for three small things a reviewer notices in the first minute of Breakdown 0.7.9: rough edges seen
         on screen in this review, too many words on screen while things move, and store claims we cannot back up.
         Written for a junior developer; each item names the file and says what done looks like.
         Read plans/25-Nov-2026-award-scores-order-plan.md first.
SRP/DRY check: Pass - checked App/Captions.swift (one caption per event, by design), App/PacePlan.swift (chooses which
         captions the replay stops on), App/NotebookStory.swift and App/NotebookInfo.swift (the notebook's commentary and
         tiles), App/Match/MatchViews.swift and MatchWords.swift (the ruling card), store/listing (the twelve listing
         files) and the memory note that the plain sentence stays and the phone may fold text behind a tap.
-->
# Fewer words, honest claims, and the rough edges

## In plain words

The game explains itself well and far too much. On the iPad a single caption runs to six lines of small type, and
during a break the list scrolls faster than anyone can read. The store page says things like "Nothing is faked" that
a reviewer cannot check and will not take on trust. And a few plain mistakes show within minutes. This plan fixes all
three. It is the smallest of the five plans and goes first.

The rule from the Boss stands: keep the plain sentence. Nothing is deleted from the game's knowledge. Long text moves
behind a tap.

## Part A: rough edges found on screen (do these first)

| # | What was seen | Where | The fix |
|---|---|---|---|
| 1 | The ruling card says "Foul" as its heading and then starts its sentence with "Foul:". | `App/Match/MatchViews.swift` (the heading) and `App/Match/MatchWords.swift` (the sentence) | When the heading is "Foul", the sentence under it starts with what happened: "No ball reached a rail after the hit." Keep "Foul:" only where the sentence stands with no heading. |
| 2 | Two captions in a row with the same heading and almost the same paragraph ("The path bends", five-pin and Behind the 8-Ball). | `App/NotebookStory.swift` | When the next caption has the same heading and the same ball, show it as a short second line under the first ("then 5° more, now rolling at 0.4 m/s"), not as a new block. Captions.swift still makes one caption per event; only the drawing merges them. |
| 3 | The Cloth card is drawn twice in the notebook on a table game before the first shot. | `App/NotebookStory.swift` line near `NotebookSurfaceCard(model: model, detailed: true)` and `App/NotebookInfo.swift` | Draw the detailed card or the short one, never both. |
| 4 | Four tiles of zeros ("0.0 m/s, 0, 0, 0") before any shot has been played. | `NotebookNumbers` in `App/NotebookInfo.swift` | Do not draw the tiles until there is a shot. The strike panel plan puts the planned strike there. |
| 5 | A caption cut off with an ellipsis on the upright phone ("the cloth pulls along the slip of the…"). | `App/CaptionViews.swift` | Part B's short form removes the cause. Until then, never end a caption in an ellipsis; let it wrap. |
| 6 | The main menu's first row is drawn in the system's blue, not the game's own accent colour. | `MenuRow` in `App/TitleScreen.swift` | Tint the prominent row with the palette's accent, as the Shoot button is. |
| 7 | "Player 1 to shoot" on bumper pool and five-pin in the store scenes, in a game the listing says is against the computer. | `App/Match/MatchWords.swift`, the store scene in `App/ShowpieceModel.swift` | Check whether a real game against the computer ever says "Player 1". If only the store scene does, fix the scene so the screenshots say "Your shot". |

Done when each row has been fixed or shown not to happen in a real game, with a line in the change log for each.

## Part B: fewer words, never moving fast

### The short form

Every caption gets a short form, made from what it already has:

- its **heading**, six words at most ("The path bends");
- **one figure** as a chip (the angle, the speed or the share of energy that the heading is about);
- **one sentence** of at most fourteen words, the plain one.

Everything else the caption says today (the second and third sentences, the surface's numbers, the comparison with
the standard table) stays in the caption and is shown only when the player taps it.

Steps:

1. In `App/Captions.swift`, give each caption a `short` sentence beside its full text. Write it from the same event
   and the same numbers. This is new text for every caption kind, so it goes to `localization/pending` in all twelve
   languages.
2. In `App/NotebookStory.swift`, draw the lit row as heading, chip and short sentence. A tap on the row opens the
   full text in place. The dimmed rows show the heading and chip only.
3. In `App/CaptionViews.swift` (the upright phone) and `App/Phone/PhoneExplanation.swift`, the same: short form by
   default, the full text on a tap.
4. The surface's numbers that were repeated inside captions ("On Tournament cloth the sliding friction is 0.1 and…")
   are already on the surface card. Remove them from the short form.

### Never faster than a person can read

1. A caption stays lit for at least as long as it takes to read its short form: allow a third of a second per word,
   and never less than two seconds.
2. `App/PacePlan.swift` already chooses the moments the replay stops on. While the replay runs at speed between
   those moments, the list does not scroll and no caption changes. Captions for the moments in between stay in the
   list, dimmed, for anyone who scrubs to them.
3. A break makes dozens of hits at once. The list shows one row for it ("The break: 41 ball hits") that opens to the
   full list on a tap.
4. With Reduce Motion on, the list never scrolls by itself at all.

Done when: on an iPad, during the opening break replay, no text on screen changes more often than once every two
seconds, and the lit caption is three lines or fewer.

## Part C: claims we can back up

The test for every sentence in the store page, the menu and the README: could a reviewer check it on the device in
five minutes? If not, it goes or it is reworded to what they can check.

| Today | Problem | Replace with |
|---|---|---|
| "Nothing is faked." | Cannot be checked; invites doubt. | "Every path and number on screen is worked out by the game's own solver. None is drawn by hand." |
| "worked out by a real physics solver" | "Real" is a boast. | "worked out by the game's own physics solver" |
| "drifts off line, just as it does on a real table" | We have not measured it against a real table. | "a rushed or crooked stroke drifts off line" |
| "twelve real eight-ball spots" | "Real" again. | "twelve eight-ball spots" |
| "a card that tells you how to play it on a real table" | Advice we have not tested on a table. | Keep the card's name; in the listing say "a card with the aim, speed and spin the escape used" |
| "There is no chance in it: the same shot always plays out the same way" | True and checkable. | Keep. This is the best claim we have. |
| "Screen reader support" | True. | Keep. |

Steps:

1. Change `store/listing/en.json` first, then the eleven other files in `store/listing` to match. Run
   `python3 scripts/store-listing-check.py` to check Apple's length limits.
2. Search the game's own words for the same phrases (`App/Localizable.xcstrings`, the intro line in
   `App/TitleScreen.swift`, How to play) and change them the same way.
3. Change the same lines in `README.md`.
4. `store/README.md` records what the listing says. Update its summary paragraph.
5. The listing is uploaded only after the Boss has read the English file.

Done when a search of the repository for "faked" and for "real table" in player-facing text finds only the card's
own name.

## What not to do

- Do not delete any caption's full text. It moves behind a tap.
- Do not skimp on the pictures to make room for words. When space is short the words fold, the graphics stay.
- Do not rewrite captions' numbers. Every figure still comes from the recorded shot.
