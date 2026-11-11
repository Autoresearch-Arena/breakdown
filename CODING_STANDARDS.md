<!--
Author: GPT-6.1 Sol (inherited reasoning)
Date: 10-November-2026
PURPOSE: Define the shared coding and documentation standards for Breakdown, with a local section for its Swift app, physics package, tests, assets and build output.
SRP/DRY check: Pass - one standards file per repo, same core text in all four contest repos; the last section differs.
-->
# Coding standards

The Boss's rules for every code file in this repo. The full original covers a TypeScript web app (Windows
shell rules, UI components, one vendor's API); none of that is repeated here.

## In plain words

Five things matter most. Every code file starts with a header saying who wrote it, when, and what it is for.
Code carries comments that explain the parts that are not obvious. Anything a person reads (README, plans,
changelog, ledgers, commit messages) is written in plain words for a non-technical executive, with what happened
and what it means first. Every change in behaviour gets a changelog entry. File and folder names stay short and
safe on Windows and Linux. The numbered sections below are the details.

## 1. File header

Every code file you create or edit starts with this header. Update it each time you touch the file.

```
Author: Claude Opus 5.5 Medium        (your exact model name and effort level)
Date: DD-Month-YYYY
PURPOSE: verbose: what it does, what it reads and writes, how it plugs into the rest, dependencies
SRP/DRY check: Pass/Fail - did you check that this does not duplicate something that already exists?
```

- Python: at the top of the file, in the module docstring or a comment block. Shell: comment lines right after the shebang.
- Never on JSON, CSV, SQL or any format that cannot hold comments. A notebook (.ipynb) is JSON: put the same
  four lines in its first Markdown cell instead.
- Markdown we write (plans, READMEs, ledgers) carries the same four lines as an HTML comment at the top.

## 2. Credit yourself

Name yourself by model name AND effort level, for example "Claude Opus 5.5 Medium", in file headers,
CHANGELOG entries, plans, ledger and log entries, and commit trailers.

## 3. Comment the non-obvious

Comment each step of a pipeline, why a fallback exists, every integration point (what reads this, what it
writes, which service or file it depends on) and the failure modes. A one-line header over uncommented code
does not meet the bar.

## 4. SRP and DRY

One reason to change per function or module. Search the repo before you create anything new and reuse what is
there. Use clear names and handle errors explicitly; never swallow them.

## 5. Real work only

No stubs, mock data, placeholder values or invented numbers. A reported result is one that was measured, and
the report says how: local check, prediction, upload, or scored board result.

## 6. CHANGELOG

A behaviour change gets a top entry in `CHANGELOG.md` (newest first): version, date, what, why, how, and your
name with effort level. Update any doc the change touches in the same commit. Use proper semver. 

## 7. Plan before you build

Write `plans/DD-Mon-YYYY-goal-plan.md` (scope, objectives, steps) before substantive work.

## 8. Shell scripts on a machine where they run

Never overwrite a bash script on a remote box while it runs just to fix comments: bash reads the file as it
goes. Update the repo copy and say so in the changelog.

## 9. Do not guess

Read the library's own documentation before using an unfamiliar or recently changed library. Commit only
finished, checked work, with a message that says what and why.

## 10. Big files stay out of Git

Anything that can grow past a few MB (datasets, weights, checkpoints, compiled artifacts, caches) lives on the
Mac Mini's SSDs, never in Git and never on the internal drive. Record its logical path, origin, size,
checksum and how to rebuild it in the README or a manifest.

## 11. File and folder names: short and portable

A checkout must work on Windows, Linux and macOS. A colon in a timestamp already broke a Windows checkout of the
quantum leaderboard snapshots (26-Oct-2026).

- Each file or folder name under 100 characters, and the whole path from the repo root under 150. Windows stops
  near 260 characters counting the folder the repo is checked out into, and zip tools and sync clients fail
  earlier. Linux and macOS stop at 255 bytes per name.
- Letters, digits, dot, dash and underscore only. No spaces. None of `< > : " | ? * \`. No trailing dot or
  space. Write times as `20261026` or `2026-10-26`, never `10:26`.
- No two names in one folder that differ only by upper or lower case; Windows and macOS see them as one.
- Never use a Windows reserved name, with or without an extension: CON, PRN, AUX, NUL, COM1 to COM9, LPT1 to LPT9.
- Put the detail in the file header or the README, not in a long name. Do not nest a folder just to repeat a
  label its parent already carries.
- On a Windows machine run `git config core.longpaths true` as a safety net. It is never the plan.
- Check before you commit, from the repo root. Both commands should print nothing:
  `git ls-files | awk 'length($0) > 150'` and `git ls-files | grep -E '[<>:"|?*\\]|[. ]$'`

## 12. Write for a non-technical executive

The Boss is a non-technical executive. Everything reply and documentation artifact must make sense to someone who does not write code.

- README, plans, CHANGELOG entries, ledger entries, status notes, commit messages and pull request descriptions
  lead with a plain sentence or two: what happened, what it means for the contest (score, rank, deadline, cost),
  and what is next. Technical detail follows below it, never instead of it.
- Plain words. Spell out an acronym or term of art the first time it appears in a file, or leave it out. Short
  paragraphs and short lists, no walls of text. Say in words whether a result is good or bad; keep the raw numbers
  in the table or ledger line that backs it.
- A real decision for the Boss goes at the top, marked DECISION, one sentence per option. Anything that is not
  essential for the humans to decide, decide yourself and record why. Remember, the goal is to increase our score, not to run endless tests. 
- The header's PURPOSE line is written for the next person, in plain words: what the file does, what it reads
  and writes, where it plugs in. Someone who has never seen the repo should understand the file from its header
  and comments alone.
- Never make the reader read code to learn a result. Report it in words, then point to the evidence file.  Do not mix numbers or code snippets with prose writing. 

## Applies here: breakdown

- Swift app code lives in `App`; the solver, timeline and existing tests live in `Packages/BreakdownCore`.
- Keep the physics independent of Apple user-interface frameworks; run existing package tests when changing it.
- Check both Mac and iPhone simulator builds when changing platform-facing code. Rendering changes also need visual inspection.
- Geometry, textures and audio are currently generated in code. Record source and redistribution terms before importing assets or dependencies.
- Keep signing material, environment files and build products out of Git. New large output belongs on the Team 4TB drive.
