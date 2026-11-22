<!--
Author: Claude Opus 5.5 High
Date: 22-November-2026
PURPOSE: The menus-entries stream's part of the 0.7.4 changelog entry (the computer's way in on every table, the menu's
         new order, How to play's ending and the Mac's Watch It in the Lens), for the coordinator to fold into
         CHANGELOG.md [0.7.4] and then delete.
SRP/DRY check: Pass - only this stream's changes; the computer player itself, the highlight card and the Lens work are
         in the other streams' fragments.
-->
### Menus and ways in (menus-entries stream, Claude Opus 5.5 High)

- **What:** The main menu's Play list now offers four games against the computer: Eight-ball, Nine-ball, Bumper pool
  and Five-pin billiards, each with its won-of-played mark at the chosen level. The bumper-pool and five-pin pages in
  Tables gain "Against the computer": the same Easy / Medium / Hard choice, what that level plays like, and "Play the
  computer" (with your record at that level once you have one), then Practice. Bar billiards stays a game played alone.
  The level is one shared choice: pick it in the menu or on a Tables page and the other shows it. Trick shots moves directly under Play, with the line "Watch a shot that looks impossible, see why it works,
  then make it."; the Play line and the menu's intro say four games against the computer. How to play no longer opens
  with the lessons: it starts with taking your shot and ends with "Watch the trick shots", where the lessons are
  mentioned as an option. The Tables lines for bumper pool and five-pin name the computer, and so does the first step
  of each game's rules ("You and the computer..."), which used to open with "Two players". On the Mac (and an iPad
  with a keyboard) New Game lists bumper pool and five-pin against the computer at each level, and Playback gains
  "Watch It in the Lens" (Shift-Command-R), available while a remarkable shot is on offer.
- **Why:** The computer now plays every table, so every table should offer it where people look; and the trick shots,
  the coolest thing the table shows, belong where people look first. Nothing pushes anyone into the lessons.
- **How:** TitleScreen's level picker became ComputerLevelPicker, bound to the model's computerLevel and shared with
  TableGamePage; both start games through MatchStartRequest, the route the Mac's Game menu already used, so a saved
  match is always asked about first. TableGamePage holds the whole request while it asks instead of a player count.
  MacChrome's New Game covers five kinds and its Playback item calls the model's highlight offer. The first launch is
  unchanged: the menu is still skipped on it.
- **Checked:** Code only, not compiled in this stream (the coordinator compiles once after the merge). Every API used was
  read in the source: MatchStartRequest, ShowpieceModel.computerLevel / highlightOnOffer / watchHighlight,
  MatchRecord.record, NotebookWords.gameName, TableKind.symbol, FivePinRules.standardTarget. TableGameWordsTests gains
  testGameLinesNameTheComputer. Thirteen new strings, translated into the eleven languages in
  localization/pending/v074-menus-entries.json; no key duplicates one already in the catalog.
