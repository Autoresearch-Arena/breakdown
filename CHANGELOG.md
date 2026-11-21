<!--
Author: Claude Sonnet 5.5 High
Date: 13-November-2026
PURPOSE: Record project changes, including documentation and licensing readiness without altering gameplay.
SRP/DRY check: Pass — checked existing README, specification and history; links retain one source for detailed design.
-->
# Changelog

All notable changes to this project are listed here, newest first. Versions follow SemVer.

## [Unreleased]

Author: Claude Sonnet 5.5 Medium

- What: The opening music is now one of three takes chosen at random each launch: the Pool Table Take, or one of two new thirty-second jazz-funk clips (electric piano, and wah guitar with organ), each opening on a pool break with ball clacks through it.
- Why: The Boss did not like the old opening track and approved these two new ones as alternatives.
- How: The clips are Google Lyria clips made 21-November-2026 and stored beside the original in App/Audio; TitleMusic picks one per launch. All other rules are unchanged: once per launch, Sound setting honoured, faded out when play starts.
- Checked: the iPhone build passes and all three tracks are inside the built app; not yet listened to in the app.

## [0.6.5] - 21-November-2026

Author: Claude Sonnet 5.5 Medium

- What: The open iPhone Duo has its own layout now. The table fills one whole half with nothing over it, and the other half is a full-height notebook: the shot's explanation runs live as a list of every explained moment (the one on the table lit, a thin line from it to the ball, tap any row to jump the replay there), under the cards for what you are playing, with the numbers of the shot (cue speed, ball hits, rail hits, pocketed), the surface and its four constants, and the controls. Trick shots show how forgiving each shot is (how far aim, power and tip can stray) and, once you have seen the answer, the idea and its equation; Behind the 8-Ball shows your balls and, after a shot, the lesson and the trick shots that teach it. The main menu, the trick-shot and 8-ball lists, How to play, Options and the fine controls are pages of that panel instead of sheets, so nothing ever covers the table. Propped open like a laptop, the table goes on top and the notebook splits in two columns beneath it. Everything else (iPhone, iPad, Mac, the closed Duo) looks as before, apart from card buttons that no longer fit on one row now wrapping onto two rows instead of one each.
- Why: The Boss, looking at the first Duo layout, wanted the whole right side used for rich text and full information, no menu or sheet covering the table, and a layout special to the Duo.
- How: New files DuoPanel (the panel, its pages and top bar), DuoStory (the live commentary, built from the same captions the Physics Lens uses, with a probe so the list redraws only when the lit caption changes), DuoInfo (the numbers and the mode details); ShowpieceView lays the screen out as the table panel plus DuoPanel on a hinge, and tells the sheet-hosting views, through a new environment value, to stay out of sheets. TitleScreen takes optional How to play and Options hooks, ShotPanel opens its fine controls inside the panel, PlaybackControls has a compact size, and a new WrappingRow wraps the trick-shot and 8-ball card buttons. Nine new strings in all eleven other languages.
- Checked: on the Duo simulator open, upright (propped like a laptop) and closed: free play with the Lens, a trick shot at each stage, an 8-ball situation before and after a shot, the menu, the trick-shot list, a shot picked from it, and Arabic (mirrored, table on the right), German and Russian; the iPhone, iPad-width and Mac builds pass.

## [0.6.4] - 21-November-2026

Author: Claude Opus 5.5 Medium

- What: On the iPhone Duo opened up, the screen now splits at the fold: the table fills the whole left half and everything you read or tap (the menu, the aiming card, the trick-shot and 8-Ball cards, the captions and the Physics Lens, Ride and Your shot buttons) sits on the right half, with nothing on the hinge. Propped open like a laptop, the table goes on the upright half and the rest on the flat half. Closed, the phone plays as before. The main menu's one-line description is never cut off with "…" any more, and How to play and Options never shrink to "How to p…".
- Why: Testing on the Duo simulator showed the open phone using the ordinary sideways layout, with the table and the menu card running across the fold and a narrow empty column beside them. The Boss asked for the table on one whole side and all the text on the other.
- How: ScreenLayout.fold reads the hinge the system reports as a division region (iOS 27.1 and later), including when the phone lies flat and the system marks it inactive. ShowpieceView lays every layout out in one switchable stack, so the 3D table keeps its built scene while the phone turns, folds and unfolds; on a fold it sizes the table to the panel before the hinge, leaves the hinge empty and gives the other panel to the column, with the controls and the main menu there; while that menu is up the table panel takes no touches, so nothing can be aimed behind it. The menu card is centred by its scroll view instead of being forced to the screen's height, which had squeezed the description to one line, and its two small buttons drop their icons, then stack, rather than truncate.
- Checked: on the Duo simulator closed, half open and flat open, at the menu and while aiming, including folding and unfolding with the game running, turned upright (table on the top half, menu below), dragging on the table behind an open menu (nothing moves) and opening a trick shot from the list; on an ordinary iPhone running iOS 26.5, upright and sideways look as before; the iPhone and Mac builds pass.

## [0.6.3] - 21-November-2026

Author: Claude Opus 5.5 Medium

- What: Behind the 8-Ball no longer freezes after a shot. When the balls stop, the card says "Scoring…" while the judge works, and the scorecard follows; the table and buttons stay live meanwhile. A verdict that arrives after the player has already moved on (Try again, Next, another situation, leaving the mode) is dropped instead of covering what came next. Scoring is also much quicker on point-blank's steep jump, which took about five seconds even in a Release build.
- Why: Recording the App Store video showed the screen frozen for several seconds before each scorecard: the judge re-solves the shot many times on the main thread.
- How: EightBallMode starts the judgement on a background task in a new Scoring phase, counts the try at once, and applies the verdict only if it is still the latest judgement for the same situation and the card is still waiting for it. The judge was already a pure function with lock-guarded caches. Its window sweep now solves with an event budget (a new PoolSolver.simulate(_:eventBudget:) in the package; the normal solve is unchanged): in a narrow band of speeds point-blank's jump wedges the cue ball against a ball and the solver ground through its full event guard, so such a solve now counts as a miss after a small budget. It was never a make, so no score changes. The escape check prints each judgement's time.
- Checked: the escape check passes every line with every escape scoring exactly as before; the slowest Release judgement is now under a fifth of a second (was about five seconds); package tests (with a new event-budget test) and the iPhone and Mac builds pass; in the simulator the massé escape played as a try shows "Scoring…" and then its scorecard with no freeze.

## [0.6.2] - 21-November-2026

Author: Claude Opus 5.5 High

- What: New App Store screenshots and a gameplay video, in all twelve languages, plus a refreshed store listing. Ten framed screenshots per language for 6.9-inch iPhone and 13-inch iPad (Behind the 8-Ball's jump, the call, the gold-medal scorecard, the real-table card, the Physics Lens, the bridge shot, the surfaces, the new tables and both lists), and a 29-second gameplay video per language with the title music, as an App Store preview and a larger copy for sharing. In the game, six trick-shot strings that were never translated ("Watch it", "Watch again", "Made it!", "Missed", "Hide the maths" and a VoiceOver hint) are now in every language, a piece of English slang left in six translations of a Behind the 8-Ball story is gone, and a Spanish typo in eight trick-shot strings is fixed.
- Why: The Boss asked for new marketing material showing the best of the game, localized, and a good video of the most impressive gameplay.
- How: scripts/store-shots.sh and store-shot.sh open the app straight into each moment with its own launch flags (new test-only flags: -pauseAt, -trickAim, -eightAim, -eightWatch, -eightRide, -eightRealTable, -rackShoot; -trickList and -eightList now open over a shot's table when given with -trick or -eight), with stored settings pinned on the launch line so no scene leaks into the next. store/screenshots/compose.swift frames the shots with translated headlines at App Store sizes. scripts/store-video.sh records clips and store-video-cut.sh cuts them. Raw and finished files live on the Team 4TB drive; store/screenshots/README.md explains it all. Nothing is uploaded.
- Checked: one reviewer per language looked at every iPhone frame, every iPad frame and every video beat; the fixes they called for (untranslated buttons, headline wording, beats starting inside a fade) are in. The listing checker passes for all twelve languages. No Mac set yet: capturing it means opening game windows over the Mac's desktop.

## [0.6.1] - 21-November-2026

Author: Claude Opus 5.5 High

- What: Behind the 8-Ball, a new mode under Trick shots. Twelve real eight-ball spots where you are hooked, each on a full table: call your ball and pocket (tap them on the table or on the card) or call Safety, then get out with a kick, bank, jump, massé, swerve, combination or a shot off the bridge. The scorecard gives 5 for making it as called, up to 5 for difficulty and up to 5 for style, with bronze, silver and gold medals and a running total. After each shot "On a real table" gives the aim in diamonds, the cue angle, the speed, the tip and the common miss in plain words beside the solver's numbers, plus the cloth's friction and cushion numbers when it is not standard cloth. Watching a way out is there as a hint and caps style at 2. Every string is in all eleven languages.
- Why: The Boss wanted real game situations that show off the trick shots, so a player feels they could step up to a table and make them, with the numbers kept as part of the appeal.
- How: App/EightBall holds the types, the twelve situations (each escape found and checked with the physics solver, in BreakProbe's eightball command), the judge (fouls, made as called, difficulty from how wide the window of working strokes is, named style points) and the screens. A jump or massé stroke is treated as a short punch, so the judge does not call the authored jumps double hits. The -eightJudgeCheck launch flag runs the judge's own checks and judges every authored escape; -eightPlay plays one escape as a scored try.
- Checked: in the app every authored escape is made as called with no foul and all the judge's checks pass; in the simulator the list, calling by tap, the hint, a foul, a made kick (silver), a made massé on tournament cloth (gold) and both real-table cards work; package tests and the iPhone and Mac builds pass.

## [0.6.0] - 21-November-2026

Author: Claude Opus 5.5 High

- What: Three new tables in the Surface menu, under Tables: bumper pool (a small table with rubber posts and a cup at each end), five-pin billiards (no pockets, five small pins in the middle that fall when hit) and bar billiards (holes in the bed and pegs that must not fall). Each has its real size, ball size and layout, an opening shot, and props modelled in Blender. Also the Behind the 8-Ball design is in docs.
- Why: The Boss asked for these games as new tables, built in parallel and shipped as one bundle at version 0.6.
- How: The solver gained fixed round posts, pins that are knocked down once (with an unequal-mass impulse and a "pin down" event), holes anywhere in the bed, and a no-pockets table; pool-table recordings are unchanged. TableKind picks the table; each table fills its own file in App/Tables; the scene rebuilds the table when it changes, draws bed holes and topples pins as a pure function of the clock; the Lens has captions for post rebounds and falling pins. Trick shots stay on the pool table.
- Checked: package tests pass; iPhone and Mac builds pass; in the simulator all three tables draw, the five-pin opening knocks over three pins, the bumper-pool shot banks off the posts and the bar-billiards shot drops into a 50 hole.

## [0.5.13] - 21-November-2026

Author: Claude Opus 5.5 High

- What: The Surface menu now works in trick shots: the chosen surface is the one the shot is played on.
- Why: The Boss could not switch surfaces in his build. Trick shots silently stayed on cloth while the menu showed the new choice, so it looked broken.
- How: ShowpieceModel.physicsSurface is always the chosen surface, and setSurface re-solves the shot on screen in trick-shot mode too. A trick's answer was authored on cloth, so on other surfaces it may miss, and the Physics Lens explains why.
- Checked: in the simulator, Stop Dead switched to ice and to dive-bar felt and played on them, with the friction and cushion numbers in the caption; free play switching still works.

## [0.5.12] - 21-November-2026

Author: Claude Opus 5.5 High

- What: Two real pool cloths join the Surface menu: Tournament cloth (new worsted cloth in tournament blue, slick and fast, with lively cushions) and Dive-bar felt (old napped felt, faded with a bald break lane and faint chalk, grabby and slow, with dead cushions).
- Why: The Boss wanted regulation cloth compared with worn bar felt, with the real friction numbers, as groundwork for the Behind the Eight Ball mode.
- How: Each is a set of PoolParameters at the ends of the measured ranges (sliding friction 0.15 and 0.3, rolling resistance 0.005 and 0.015, spin deceleration 5 and 14, cushion restitution 0.9 and 0.65, bar cushion friction 0.22); their pictures are drawn in code; their cushions wear the same cloth as the bed; the strike caption also says how much speed their rails give back. The felt is worn but not damaged: no burns or stains that would look like bumps.
- Checked: both surfaces seen in the simulator; iPhone and Mac builds pass; the new strings are translated in all eleven languages.

## [0.5.11] - 21-November-2026

Author: Claude Opus 5.5 High

- What: The approved opening music, Pool Table Take, plays under the main menu, and the 3D cue and bridge now actually appear while aiming (in 0.5.10 they never showed).
- Why: The other session delivered the music for this build; and testing 0.5.10 in the simulator showed the cue and bridge were loaded but never placed, because the scene was not told when the shot panel was open.
- How: TitleMusic plays an unchanged copy of docs/audio/pool-table-take.mp3 once per launch while the menu is up, only with Sound on, never looping, and fades it when the menu closes or Sound is switched off. The shot panel's open state now reaches the scene (SceneBridge.showCue) so CueRig gets the aim. The cue keeps a slight rise so it clears the rail; the bridge head is satin chrome so it no longer reads as black; the Bridge label moved clear of the head.
- Checked: in the simulator, the Long Bridge Draw shows the cue resting in the bridge notch, Jump the Blocker shows the raised cue and its follow-through, the break shows the cue behind the cue ball, and the music starts on the menu and fades when Free play starts. The iPhone and Mac builds pass, with the music and both models in each app.

## [0.5.10] - 21-November-2026

Author: Claude Opus 5.5 High

- What: The cue and the mechanical bridge are real 3D objects on the table: a pro cue (blue tip, ivory ferrule, maple shaft, steel joint, ebony forearm, linen wrap) that pulls back with the power, tilts up for the massé and the jump, and follows through when the shot is played; and a chrome bridge whose notch carries the cue on the Long Bridge Draw.
- Why: The Boss asked for the cue and bridge in 3D, so the jump and massé show the raised cue and the bridge shot shows the rest it needs.
- How: Both are modelled in Blender by scripts in Tools/blender (make_cue.py, make_bridge.py) that export geometry-only USDZ files to App/Models and check them on read-back; CueRig.swift loads them, paints them with materials in the table's style and places them from the aim (power, tip offsets, elevation, bridge) and, for the first half second of a replay, from the cue ball's recorded start. The flat 2D stick and bridge in the aim layer are gone; the "Bridge" label stays.
- Checked: the iPhone and Mac builds pass; both models are in the app bundle.

## [0.5.9] - 21-November-2026

Author: Claude Opus 5.5 High

- What: The app has its new icon: the cue ball driving into the red ball, the struck balls' arrows, and the momentum equation p = m·v on the blueprint cloth.
- Why: The Boss approved this artwork (added to the repo by the other assistant) and asked for it to be the icon.
- How: The approved 1024-pixel artwork replaces the old icon picture in the app icon set; it has no transparency, as the App Store requires.
- Checked: the iPhone build passes.

## [0.5.8] - 21-November-2026

Author: Claude Opus 5.5 High

- What: Two new surfaces, Moon and Cork, and the surfaces now explain themselves. The Moon keeps the cloth's friction but has one sixth of Earth's gravity, so everything skids and rolls about six times farther and jumps fly high. Cork is soft and grippy. Off cloth, the opening explanation names the surface, gives its sliding friction and rolling resistance next to cloth's, and says how many times farther a ball skids and rolls because of them; the skid-to-roll explanation gives the surface's friction, the gravity and how long that skid really took. Each surface in the picker has a one-line description under its name. Ice and glass no longer show a blown-out white disc from the lamp: ice is pale blue-grey with a soft sheen, glass a soft polished reflection.
- Why: The Boss asked for a Moon surface with low gravity and a cork board, asked that the effect of each surface's friction be really explained when it is shown, and found the light on the ice reflected very weirdly.
- How: Every number in the new sentences is read from the surface's own solver settings and the recorded shot (a skid's time is the length of the ball's recorded sliding stretch). Friction pushes back with the friction number times the ball's weight, so skid and roll distances scale with one over friction times gravity, which is how the "times as far" figures are worked out. The glare came from a near-mirror finish reflecting the one small, very bright lamp; a little roughness and a softer coat spread it. New text is translated into all eleven languages.
- Checked: the iPhone and Mac builds pass; ice, glass, cork and moon were looked at in the iPhone 17 Pro Max simulator, and the Moon explanation read on screen. Not checked: how long a full Moon break takes to watch (roughly six times a cloth break).

## [0.5.7] - 21-November-2026

Author: Claude Opus 5.5 High

- What: Play on different surfaces. A new round glass button at the top right picks the playing surface: Cloth, Ice, Glass, Sand, Carpet or Rubber. The shot on screen replays on the new surface right away. On ice the break skids everywhere and keeps rolling; on sand the balls plough to a stop near the rack; rubber grabs, so a skid turns to a roll almost at once. The Physics Lens now shows spin: an amber band round a ball that is skidding (spin that does not match rolling, such as draw or follow), and a blue ring on the cloth for side spin, both fading with how much there is.
- Why: The Boss asked to see the physics on ice, glass and other crazy surfaces, and asked about ball rotation and spin.
- How: Each surface sets the solver's own friction, rolling, spin-decay and bounce numbers; cushions, ball contact and gravity stay the same. Each bed is drawn in code and made only when it is picked; only the bed changes, because the cushion is the rail rubber. Trick shots always play on cloth, since they were worked out on cloth. The spin markers read the recorded spin at the playback time, so scrubbing shows the same thing either way. New words: Surface and the six surface names, translated into all eleven languages.
- Checked: the iPhone and Mac builds pass; the break was watched on ice and one frame on each other surface in the iPhone 17 Pro Max simulator, and the spin band seen on the struck ball over the Lens. Not checked: how long the longest ice shot runs; the caption wording still says "cloth" on other surfaces.

## [0.5.6] - 21-November-2026

Author: Claude Opus 5.5 High

- What: Ride is now a chase view of the cue ball. The camera sits behind and above the cue ball for the whole shot instead of hugging it at rail height and then jumping to the ball it hits. After the first hit it lifts up and back, so on the break you see the whole rack open, and on a pot you watch the ball run into the pocket. The explanation card under the table is now plain Apple glass that is only as big as its words, and it is gone when there is nothing to say. Replay moved into the scrub bar, so the Physics Lens, Ride and Your shot buttons share one row.
- Why: The Boss found the ride view weird: the cue ball filled half the screen, the rack was a wall of giant balls, and it switched to riding the yellow ball. He wants to be the cue ball, in a chase view. He also found the explanation box covering the table with a lot of empty glass, and Your shot sitting alone on its own row.
- How: The ride camera's height, distance and look point were changed, the hand-over to the struck ball was removed, the cue ball's heading only turns after the hit when the cue ball really travels on, and the lift is a smooth blend timed from the hit, so scrubbing still gives the same view for the same moment. The strip still keeps its room so the table does not jump, but the glass now hugs the text and sits on the controls. No new text to translate (the Ride button's old hint was dropped because it described the hand-over).
- Checked: the iPhone and Mac builds pass; the straight pot and the full break were watched with Ride on in the iPhone 17 Pro Max simulator.

## [0.5.5] - 20-November-2026

Author: Claude Opus 5.5 High

- What: The break replay now stops at each important moment of the break, starting with the cue ball hitting the rack and the energy running through it, and holds there long enough to read before moving on. It speeds through the quiet stretches. A Continue button skips ahead. On a phone held upright the explanation sits in a fixed strip below the table instead of over it. On the table, a short label by the ball names what is happening. The Lens is now named the Physics Lens on its button and its colour key.
- Why: The Boss found the opening rushed past the interesting physics, and the explanation card covered the top of the table. He also found the Lens unclear.
- How: Every caption is now kept (before, all but one per quarter second were dropped, which threw away most of the rack). A new pace plan picks the moments worth stopping on from the shot's own events and sets a reading pause for each. The pause is a real-time hold, not a slowed clock. Guided pacing runs on the slow replay and whenever the Lens is up with the speed left on Auto; picking a speed or riding the shot turns it off. The strip keeps one height from caption to caption, so the table does not jump. No new text to translate: the labels reuse caption titles, and the button reuses "Continue" and "Physics Lens".
- Checked: the iPhone build, the Mac build and the physics package tests pass. Not checked: anything on a device (the Boss tests it himself).

## [0.5.4] - 20-November-2026

Author: Claude Opus 5.5 High

- What: All ten trick shots are playable. New: The Called Break (break a short rack and call the 3 into the top-right corner), Throw It In (two touching balls lined up to miss; side spin drags the 8 in anyway), The Massé (a raised cue bends the cue ball round the 4 onto the 9) and Jump the Blocker (a raised cue hops the cue ball over the 6 to sink the 11). The massé and the jump raise the cue for you on Watch it and on Your turn. The trick-shot text from the last pass is now translated into the eleven languages.
- Why: The Boss asked for ten trick shots including a trick break, the jump and where you strike the ball.
- Localization finish (Claude Sonnet 5.5, with Claude Haiku 5.5 High earlier): the last untranslated screen text is now in the String Catalog in all eleven languages (the menu entries, the trick-shot list and card buttons, the Ride camera labels, the Bridge label, the Vibration switch, the how-to trick-shot step and the Lens colour description). Every language now speaks to the player informally (tu, du, ты, tú and so on), including the Russian store listing line.
- How: Each answer was found with the physics solver and kept only if it still works within a measured window of aim, power and spin; the throw, massé and jump were also kept only if they fail without the thing they teach (no side spin or no ball friction; a level cue). The search tool now uses at most three threads (it once took every core of the shared Mac). Trick settings carry the cue elevation as the solver's sine, and the table takes it from the shot.
- Checked: the iPhone build succeeds. Not checked: anything on a device or simulator (the Boss tests it himself), the Mac build and package tests this round, translations for the four new shots' text (wrapped, awaiting the next translation pass).
- Also (Claude Opus 5.5 Low): Breakdown now ships itself to TestFlight. Every push to main that changes the app is built on the Mac Mini's own build runner and uploaded; older builds are retired so testers only see the newest, the new one joins the public link's group with its "What to Test" note taken from the newest changelog entry, and Apple's beta review is requested. Pushes that only touch notes or docs do not build. The repo is public, so the build runs only on pushes to main, and outside pull requests need approval before any workflow runs. Files: scripts/testflight.py and .github/workflows/testflight.yml.

## [0.5.3] - 20-November-2026

Author: Claude Haiku 5.5 High

- What: Breakdown is localized. Every line the player reads (menus, buttons, tips, the how-to steps, options, the shot panel, playback, the Mac menus and tooltips, the shot captions and the retry comparison) now has a translation into the same eleven languages the dog game ships in: Spanish, French, German, Italian, Portuguese, Brazilian Portuguese, Japanese, Korean, Simplified Chinese, Russian and Arabic. English stays the source.
- Why: The Boss wants the next build to ship in the same languages as the dog game, and wants all new player text written so it can be translated from the start.
- How: All translations live in one Apple String Catalog in the App folder. Text built in ordinary code (captions, the retry comparison, stage titles, the how-to steps, the tip words) is wrapped in the catalog's own lookup so whole sentences reach translators and can be reordered. Numbers are placeholders and are formatted with the player's own decimal style. Translation was done by six subagents, two languages each, and each translation must keep the same placeholders as its English line. The project lists the eleven languages as known regions. The rule for future work is written into the coding standards as section 13. Build number moves to 8 for the next TestFlight upload.
- Checked: Not compiled or tested in this session, by the Boss's instruction; the TestFlight session builds and checks the Mac and iPhone targets and the physics package tests.
- Not checked: Arabic needs a right-to-left check on the phone; the drawn labels in the Lens colour key and the table text are drawn in code and may need a look in each language.

- Also in 0.5.3 (Claude Opus 5.5 High, trick-shot pass):
  - Trick shots are now what the game is for. Trick shots is the first choice on the menu and opens a list: Stop Dead, The Long Bridge Draw (played off the mechanical bridge), Follow-Through Train, Two-Rail Kick, Cross-Side Bank and Combination Chain are playable; The Massé and Jump the Blocker show as coming next. Each shot has Watch it (the answer, replayed) and Your turn (the same table, your own aim and spin); a miss gets one line on what to change, a make gets a glow and a tick that stays. Every answer was found with the physics solver and still works within a small window of aim, power and spin, so it can be learned, not lucked.
  - Ride the shot: a Ride camera sits low behind the cue ball, follows it into the first ball it hits, then rides the struck ball toward the pocket before rising to the full table, easing into slow motion around the contact. Watch it uses it; a Ride toggle sits in the playback controls (Command-E on the Mac). Scrubbing gives the same camera for the same moment. Under Reduce Motion it cuts instead of flying.
  - The table fills the screen: no reserved explanation box (the card floats over the top edge only while there is something to say), the colour key is a small chip beside the back button, the warm table is framed lower and closer, and the rails may tuck under the glass controls.
  - Raised-cue physics: a strike can come from a raised cue, so the cue ball can curve (massé) or leave the cloth, fly, bounce and land (jump), clearing a ball in its way; a ball that flies off the table is out. Level shots are exactly as before.
  - Not yet: The Called Break and Throw It In are not authored, and the massé and jump trick shots are waiting on their settings; they come in the next build.
  - Localized (Claude Haiku 5.5 High): the trick-shot text (shot titles, hooks, goals, the ideas and maths, the praise, the miss advice, the list and card lines) is wrapped for translation and translated into the same eleven languages as the rest of the game.

## [0.5.2] - 20-November-2026

Author: Claude Opus 5.5 High

- What: Real pocket edges. Every pocket now has a mouth between two rounded knuckles where the cushion ends, and two angled jaw faces leading back into the hole. A ball that clips a knuckle or a jaw bounces off it instead of being swallowed, so near misses rattle and spit out the way they do on a real table, and only balls that really get into the throat drop. The table you see is built from exactly the same numbers: the cushions stop at the knuckles, their ends are cut along the jaw lines, and the holes are sized to the drop circles. When a ball is turned away by the pocket, the explanation says "Off the jaw" or "Clipped the point" instead of calling it a cushion.
- Why: The Boss asked for the pocket edges next. Before this a pocket was only a circle that swallowed anything touching it, so players could not trust what the Lens taught them about a near miss.
- How: Pocket model version two in the physics package: corner mouths a little under five inches between knuckles with jaws cut at 142 degrees to the cushion, side mouths a little over five inches with jaws at 104 degrees (regulation nine-foot practice), drop circles centred on the cushion lines. Jaw faces are straight contact segments and knuckles are rounded points, both exact events like every other contact and both using the existing cushion impact. Cushion events now say whether they hit the rail, a jaw or a knuckle. The table description carries the jaws, so the drawn table and the Lens read the solver's own geometry; the old hard-coded pocket sizes are gone.
- Checked: physics tests all pass, including new ones: slow straight balls drop in all six pockets; a ball that clips a corner knuckle hits the knuckle first and stays out; firm off-centre shots rattle between the jaws; a seeded sweep of about three thousand random shots ends with no impossible state (nothing inside rubber, nothing off the table unless dropped, no cushion contact adding energy) and repeats exactly. The opening break still drops balls. iPhone simulator and Mac builds succeed; close-ups of a corner and a side pocket on an iPhone 17 Pro simulator show the jaws leading into the hole.
- Not checked: a real device; the side pocket looks a little lopsided from the low camera angle; how often real players now see rattles in normal play.

## [0.5.1] - 20-November-2026

Author: Claude Opus 5.5 High

- What: A real main menu, options, a way back, a table with room to breathe, and Try again and compare.
  - Main menu: the game opens on Play, Watch the break, How to play and Options, over the dimmed table. A back button at the top left of the table opens it again at any time (Escape on a Mac or keyboard); the table freezes behind it and Continue picks up exactly where you were, or New game racks again. Play goes straight to a fresh rack with the aiming controls open, so your own break is one tap away; Watch the break plays the showpiece opening with the slow-motion Physics Lens.
  - Options: Sound, Vibration, Shot explanations, Show the maths, Aim guide (turn off the ghost ball and follow-on lines to judge the angle yourself), show the aiming tips again, and the version.
  - Less text over the table: the wordmark and the "Table" status label are gone from play (the status only shows while the opening tells its story); the explanation slot under the header takes no room unless the Lens is up with explanations on, so the warm table gets the whole screen; the explanation card leads with words and keeps the equation behind Show the maths; play and pause sit in the scrub row and speed is a small menu there instead of four segments; while aiming the scrub row steps aside for the shot panel, so the controls are two rows instead of four; the Lens colour key is just Sliding and Rolling (its third phrase ran out of the box).
  - Try again and compare: once a shot of yours (or your own break) has played out, Try again puts every ball back where it started with the same aim, power and spin. Your last try stays on the table as a faint dashed path for the cue ball and the first ball it hit, with a "Last try" ring where the cue ball stopped, while you line up, while the retry plays and in the Lens. When the retry finishes a short card says what you changed and what happened differently. Command-T on the Mac.
- Why: The Boss played the TestFlight build: no proper menu, no options, no way back, and the table crowded by text. Try again is the moment the game is built around: rewind your own miss, change the spin, see why. Version steps by patch (the earlier 0.6.0 label was wrong).
- How: New files GameSettings (options and the Options sheet), ShotAttempt (one attempt, the plain-words comparison, the ghost paths sampled once so they never depend on the playback clock), GhostOverlay (the faint paths and the comparison card). TitleScreen is now the main menu plus a How to play sheet. The model's one-way title hold became an open-and-close menu that freezes the table. Sound and haptics read their options when they play. Launch flag -retryDemo runs a shot, an identical retry and a retry with the spin changed, and logs both comparisons.
- Checked: iPhone simulator and Mac builds succeed, the physics tests pass. On an iPhone 17 Pro simulator: the menu, Play to a fresh rack with the controls on one row, the Lens with the shorter card and two rows of controls, back to the menu and Continue, the Options sheet. A retry with identical settings gave an identical recording, and the comparison said so; with the spin changed it described the change.
- Not checked: a real device, iPad and the Mac window by eye, the largest text size, VoiceOver on the new menu and card, landscape.

## [0.5.0] - 20-November-2026

Author: Claude Opus 5.5 Low (title screen by Claude Haiku 5.5 Medium, 18-November-2026)

- What: The app now opens on a proper title screen over the dimmed table: the name, a short plain description of what Breakdown is, three steps (watch the break, read the Lens, take the cue) and a Start button. The break waits until Start is tapped. This is also the first TestFlight build since the early builds of 11 November, so it carries everything since then: the new table look, the Lens, the camera framing and touch aiming.
- Why: The Boss had never seen the app on his phone. The TestFlight builds were from before all the glow-up work, and the title screen had been written but never committed.
- How: New TitleScreen file; the model holds the opening at the title until Start is pressed; launch switches that open a specific screen skip it (and -noTitle skips it outright). The project's version fields were far behind the changelog, so they now match this entry, with build number 4.
- Checked: iPhone simulator build succeeds; screenshot of the title screen on an iPhone 17 Pro simulator, then a tap on Start, which started the break. Not checked: a real device, iPad and Mac, the largest text size (the Start button sits just below the fold on a phone and is reached by scrolling).

## [0.4.2] - 13-November-2026

Author: Claude Sonnet 5.5 High

- What: You now aim by touching the table. Open Your shot, drag anywhere on the table and the aim line swings to follow your finger. Put your finger on the white ball and pull back to set the power; a bar beside the table fills as you pull, a percentage shows by the ball, and the cue stick on screen draws back. Let go and the power stays; tap Shoot (or Break on a fresh rack). A small picture of the cue ball sets the tip: touch it for follow, draw, or left and right spin. The table also shows what the shot will do before you take it: the first ball the cue ball will hit, a ghost ball where they touch, and short lines for where each ball heads next (or the line to the cushion when nothing is in the way). The old sliders did not go away: More, then Fine controls, opens them in a sheet with spoken values, so VoiceOver and keyboard users have a full route. The panel is now one short row under the table instead of a stack of sliders, so the table stays whole above it. The first time the panel opens, a short hint explains the gestures and can be dismissed. On the Mac the pointer works the same way and the arrow keys fine-tune (left and right turn the aim, up and down change power, Return shoots). The break works the same way (drag chooses how far off the front ball you hit, now up to nearly a full ball width either side instead of about half, and the break has side spin too).
- Why: The Boss judged the old look awful. Three sliders in a panel that covered the table you were aiming at was the worst of it. A new player should be able to break without instructions.
- How: New files AimGeometry (the first-contact calculation and the screen-to-table camera maths), AimOverlay (the touch layer: gestures, keys, drawing), AimGauges (cue-ball picture and power bar). The touch is turned into a table position through the live camera, so it is right in portrait, landscape and mid-melt, with no copy of the camera numbers. The ghost is a plain geometric check against ball centres, not the solver, and it is a guide: the solver still decides what really happens, and the physics package is untouched. ShowpieceModel gained "active" power and tip values that point at the break values while racked and the shot values afterwards, so the gauges and the sliders always agree. The old fixed-length aim line in the 3D scene is switched off while the new overlay is up (its code in the Lens layer is left as it was). New launch flags for testing: -aimDemo and -aimDemoRack open the aiming panel without tapping, -aimDemoSheet opens the fine controls, and -aimScript break, shots or scratch drives a scripted aim, pull and shot through the same handlers a finger uses; -aimHintSeen NO shows the hint again. All stay silent with -muteSound. Also fixed: the left and right labels on the fine-aim nudge buttons were the wrong way round.
- Checked: iPhone simulator (iOS 27.2) and Mac builds succeed, the 15 physics tests pass. On the iPhone simulator and an iPad simulator I looked at screenshots of: the aim line and ghost over a long shot, pulling back with the percentage showing, a shot playing (guide hidden, Shoot greyed until the balls stop), a second shot, a scratch (the cue ball dropped and came back on the head spot, aim ready again), a break from the full rack, the fine-controls sheet, and the largest text size. The scripted run checked that a pull of 55 percent gave 4.6 metres a second as the gauge says.
- Not checked: real finger touches. The tool that sends taps to the simulator was not allowed in this run, so every drag in the screenshots came from the scripted run, which calls the same handlers but skips the system's touch delivery. A phone turned sideways (the wide layout was checked on iPad instead), the Mac window by eye (it builds and launches and stays up, but no screenshot was taken), real VoiceOver, Reduce Motion and Increase Contrast, haptic ticks on hardware. Whether the one-time hint is enough for a stranger to break unaided cannot be judged from screenshots; it needs a person who has never seen the game. The fine-controls sheet, at half height, covers the lower half of the table while open.

## [0.4.1] - 13-November-2026

Author: Claude Sonnet 5.5 Medium

- What: The app opens faster and dark. The launch screen is now the room's dark colour instead of white, and a dark cover over the window fades away once the table is built, so the table lights up instead of popping in. The pockets look right up close: every pocket now has a complete metal rim (the side pockets only showed part of a ring), and the cushion ends follow the pocket's round mouth with a rounded jaw face instead of a flat slanted block. The cloth hole is now exactly the size of the physics capture radius, so a ball taken near the pocket edge is no longer cut by cloth.
- Why: The Boss judged the first glow-up slow to appear, with a blank first frame; wave one's review also listed the pocket flaws above.
- How: A new StartupAssets file draws cloth, wood, floor, pocket wall, all sixteen ball faces, the Lens grid and the reflection environment on background threads the moment the app launches; the main thread only turns finished pictures into textures. The picture functions now return plain images and touch nothing shared. The launch colour comes from a colour asset plus a one-key Info.plist fragment (Config/Launch-Info.plist), because the generated settings cannot name a launch background. Launch argument -logStartup prints timings. Measured on a simulator (Apple silicon Mac, machine under heavy load, so rough): main-thread scene building in a Debug build fell from about 2.0 s to about 0.26 s (pictures now finish on background threads about 0.55 s after launch, before the table needs them); in a Release build it was already about 0.22 s and is now about 0.19 s, so Release gains little on this Mac. A real iPhone was not measured. Physics untouched; the 15 physics tests pass; iPhone simulator and Mac builds succeed.
- Not checked: a real device, landscape or iPad screenshots, a ball caught mid-drop in a screenshot (the hole size follows the capture radius by construction), the Mac window launched, Increase Contrast launch colour (the launch screen is the standard dark). The cushion end still reads as a small angular face from some angles.

## [0.4.0] - 13-November-2026

Author: Claude Sonnet 5.5 High

- What: The table is now framed in the space that is really free. On a phone held upright the caption card has its own slot under the title, so it no longer sits on the top rail, the pockets and the balls, and the table fills everything between that slot and the controls. On iPad, in landscape and on the Mac the table is framed inside the table area beside the caption column, centred and clear of the title and controls (before, it was framed against the whole window and slid under the column, and the colour key was cut off at the left edge). The colour key is one short row and only takes room from the table when there is no spare room above it. The Lens trails now fade properly: the newest second is bright, older path drops quickly to a faint, thinner line, so a frame late in the break reads clearly instead of looking like a scribble. The camera pushes in a little on the break and settles back as the balls stop (and eases in from slightly further back when the app opens); with Reduce Motion on, none of that happens and the camera holds one steady angle. The opening title now fades up with the system's smooth motion and leaves the same way, and the app no longer flashes white before the dark table appears.
- Why: The Boss called the look awful. The caption hid the table, the table used a small part of the screen, the trails were still a dense scribble by the end of the break, and the first moments were a hard cut from a white screen.
- How: The screen now measures the real edges of the title row, the caption slot and the control strip and hands them, with the safe areas, to the camera (new StageChrome and FramingRequest), replacing a guessed fraction of the height and the window read. The caption slot is as tall as the tallest caption of the shot, found by laying every caption out invisibly. Framing, the push-in and the settle live in the camera as a scale on the fitted distance, so they cannot fight the framing; the push is a function of the playback clock, so scrubbing either way shows the same camera. The free rectangle eases over a tenth of a second when layout changes. Trail brightness and width are baked into the one trail picture as functions of age, so the fade is still a pure function of the playback clock. Extra launch switches for checking: -frameDebug (prints the measured space), -noPushIn (turns off the push, settle and opening pull-back), -forceLandscape (iPhone). New small files: Breakdown-Info.plist and a LaunchGround colour for the dark launch screen. Touched outside the package list, minimally: ShowpieceView (measuring, caption slot, opening title), TableScene (hands the clock to the camera), the project file (points at the new plist).
- Checked: iPhone simulator (iOS 27.2) portrait and landscape, iPad simulator portrait, and the Mac app window (one picture of the Lens at the end of the break, taken of that window only), launched with the sound muted every time; 15 physics tests pass; a scratch sweep of 2400 shape, margin, angle and orientation cases (iPhone, iPad, Mac shapes) puts every table corner inside the free space and touches its edge (as large as it can be); scrubbing a tour of clock times and back gave a pixel-identical frame to going straight there, both with the camera push off (Lens up) and with it on (warm table), and the Lens self-test passes. Largest text size on a phone upright shows a small table because the control strip fills most of the screen (not changed here). In portrait on a phone the Lens table is a little smaller than before, because it now sits below the caption instead of under it. Not checked: a real device, the Mac window with the warm table, iPad sideways (the simulator ignored the forced turn), Increase Contrast and Reduce Transparency screenshots for the new legend, VoiceOver, and the push-in as motion (only still frames at its start and end were compared).
## [0.3.1] - 13-November-2026

Author: Claude Sonnet 5.5 High

- What: The Physics Lens now fits and glows. The whole table sits inside the screen, clear of the status bar, the title and the controls, in portrait and landscape on iPhone, iPad and Mac window shapes. Trails glow (a bright core inside a soft halo, with the system bloom added where the system has it), fade with age so the newest second or two is bright and older path stays as a faint trace, and stay exact when you scrub back and forth. Impact rings and velocity arrows glow and sit above the trails. The grid is quieter and now shows the cushion line, the rail outline and a ring at every pocket. A small legend (amber is sliding, cyan is rolling, thicker is faster, older fades) appears the first time trails show. With Reduce Motion on, the table and Lens cross-fade under one steady near-overhead camera instead of swinging.
- Why: The Boss called the look awful: the table ran off the screen and behind the title in portrait, the trails were thin flat scribbles that all stayed on screen, and nobody could read a paused frame.
- How: Camera framing is now exact maths (new CameraFraming file) fed by the window's real size and safe areas; trails are two meshes whose vertices carry the time the ball was there, with a generated picture slid along by the playback clock, so the fade is a pure function of the clock and no trail piece is ever switched on or off; rings use a fixed span of clock time. Bloom is behind an availability check (iOS 27 and macOS 27 only; the app targets 26). Checked: iPhone simulator (iOS 27.2 and 26.5) and Mac builds succeed, the 15 physics tests pass, a 170-case framing sweep passes, scrub exactness passes by fingerprint and by identical screenshots after a forward-and-back tour. Not checked: a launched Mac window, a real device, the largest text size. Physics untouched.

## [0.3.0] - 13-November-2026

Author: Claude Sonnet 5.5 High

- What: Every control is now a standard Apple control. Buttons are Liquid Glass, play and pause morph with the system symbol effect, speed is a segmented control (a menu at the largest text sizes), and Lens and Your shot are toggle buttons whose label never changes, so the buttons beside them no longer jump. The caption has moved off the action: under the title on a phone held upright, in a side column on iPad, Mac and any sideways screen, with a ring around the ball it describes and a thin line back to the card. The shot panel (break, then shot after shot) works exactly as before but is built from standard sliders and buttons, and the table now moves up to clear it instead of being covered. The status label at the top right wraps instead of running off the edge. The scrub bar has a full-size touch area, a light haptic tick at each impact as you drag, and speaks its position to VoiceOver. On the Mac there is a real window toolbar, a Playback menu (space play or pause, Command-R replay, Command-L Lens, Command-1 to 4 speed, Command-Y your shot), pointer hover feedback and a minimum window size.
- Why: The Boss judged the old look awful. The glow-up plan (package 3) asks for standard parts, one palette, text that scales, safe areas, 44 point touch targets and VoiceOver support, and a Mac build that has been looked at.
- How: ShowpieceView was split into ShowpieceView (layout), TableStage (hosts the 3D scene), PlaybackControls, ScrubBar, CaptionViews, ShotPanel, Surfaces, MacChrome and Theme. Colours live once in Theme with light, dark and increased-contrast values. All text uses system text styles. The controls get their room from a measurement, so large text pushes the table up instead of hiding it. The ring is found by projecting the ball's table position (from the recorded timeline) through the camera; no model change. Not changed: the physics package, ShowpieceModel, the table, Lens, camera and sound files. Checked: iPhone simulator and Mac builds succeed, the physics tests pass, and screenshots on an iPhone 17 Pro simulator (portrait, landscape, largest text size, Increase Contrast, and Reduce Transparency compared on against off), an iPad Pro simulator and the Mac build were looked at, and the Mac Playback menu was clicked through. When the ball a caption describes is hidden behind the caption card (phone portrait puts the card across the top of the table) the ring is left out; the camera needs a top margin to fix that properly. Not checked: a real device, a real VoiceOver run, haptics on hardware, the look with Reduce Motion on (the setting is honoured in the code, but no motion was compared), light appearance (the app stays dark because the table is a dark room).

## [0.2.5] - 13-November-2026

Author: Claude Sonnet 5.5 Medium

- What: The break now has a proper sound and, on phones with a haptic motor, a feel. A sharp crack when the rack bursts, soft clicks for light contacts and brighter ones for hard hits, a weighty thump on the rail (heavier for harder hits), a short tock for the cue tip, and a thud followed by a rattle when a ball drops. The phone taps along with the same events, harder for stronger impacts. Nothing changes on a Mac or in the simulator, which have no haptic motor, and the mute launch switch still silences everything.
- Why: The break should feel like something hit something. Before, thirty contacts at the same instant were played as a pile of identical clicks, and nothing was felt.
- How: A new mapping file turns the impacts crossed in a frame into a few cues (one crack plus a few scatter clicks, not thirty sounds), scaled by each impact's recorded strength. Sound and haptics both read those cues. Haptics only fire while the clock plays forward live, so dragging the scrubber stays quiet and still. Haptics stay on under Reduce Motion, since that setting is about on-screen movement; the system's own haptics switch is still respected. A new launch switch, log feel, prints each cue for checking against the recording. Checked: builds and physics tests (see the work report). Not judged by ear or by hand: the actual sound and feel were not heard or felt, only checked through the cue log.

## [0.2.4] - 13-November-2026

Author: Claude Sonnet 5.5 High

- What: The table now looks like a real pool table in a real room. The cloth stops exactly at the cushions (no more green sheet sticking out), the cushions have a rounded sloped nose, the wooden rails have a rounded edge, a real wood grain and pearl diamond sights, and each pocket is a proper well with a metal rim that a ball visibly drops into. There are head and foot spots on the cloth, legs under the table, and a dark floor with a warm pool of lamplight and a soft table shadow. The lamp is now a spotlight hung over the middle that casts shadows under every ball. Ball numbers are now real-sized discs at both ends of each ball's stripe line, drawn crisp and turned toward the camera, so in the resting rack nearly every number can be read on a phone.
- Why: The Boss judged the old look awful. This is package 1 of the Apple showcase glow-up plan: a still of the resting table should pass for a product photo at a glance.
- How: Lighting route confirmed against the installed Xcode 27.2 SDK: a SpotLight with shadows (available since iOS 18) as the key light, and the existing generated lamp picture kept as image-based light and retuned. New files for custom mesh building (TableMeshes), and for cloth, wood and floor pictures drawn in code (SurfaceTextures); the table builder and ball pictures were rebuilt. Everything new sits under the one table group, so the melt into the Lens still fades it all, and the Lens view shows none of it. Physics code is untouched. Checked: iPhone simulator stills at rest, mid-break and at four points of the melt; iPhone and Mac builds; physics tests. Not checked on a real device. Known gaps: no soft penumbra control on shadows (RealityKit offers none), the felt weave is drawn into the colour rather than a normal map, and the Lens still shows the old trails (package 2).

## [0.2.3] - 13-November-2026

Author: Claude Sonnet 5.5 Medium

- What: Nothing changes on screen. The drawing code is now split into separate files for the table, the Lens, and the camera, with a short coordinator on top.
- Why: The glow-up plan has three people changing the table look, the Lens, and the camera at once. One big file would have made them collide.
- How: The old single scene file became four files, each with a header saying what belongs in it. Checked: iPhone and Mac builds succeed, the physics tests all pass, and screenshots from the iPhone 17 Pro simulator match the old build (the title and table frames are identical to the pixel; the Lens frames show the same grid, trails, rings, arrows and caption). Not checked on a real device.

## [0.2.2] - 11-November-2026

Author: Claude Sonnet 5.5 Medium

- What: First look pass. The balls now reflect a warm lamp so they look glossy, the table is lit warmer, trails are wider where a ball is faster and have a soft glow strip, and all text uses Apple's own fonts (New York serif for titles and equations, the standard system font for labels, its monospaced cut for numbers) under one shared colour set. Controls are a solid dark strip instead of frosted glass. A new launch argument, -muteSound, silences the game for testing.
- Why: The game looked generic and janky. This is the first slice of the plan to make it worth featuring on iPhone Duo. Gameplay and physics are unchanged.
- How: New Theme file shared by the screen and the 3D scene; a lamp reflection image drawn in code and applied as image-based light; trail pieces get per-point width from the recorded speed plus a wider faint child strip. Still to do: trail pieces still appear in small steps (a shader-driven trail is the next rendering job), no bloom (iOS 27 only, needs an availability check), rails are still plain boxes, pockets are still flat discs. Checked: iPhone and Mac builds succeed, physics tests unchanged, and screenshots on the iPhone 17 Pro simulator before and after the Lens melts in. Not checked on a real device or the Duo.

## [0.2.1] - 11-November-2026

Author: Claude Sonnet 5.5 Medium

- What: The game now builds for iPhone, iPad and Mac, and the TestFlight build runs on iPad as well as iPhone.
- Why: The earlier build was set to iPhone only to get past Apple's first checks. The Boss wants all devices.
- How: Turned iPad support back on and allowed all four screen orientations, which Apple requires for iPad. Checked clean builds for Mac, iPhone and iPad hardware and the simulator. Build number 3.

## [0.2.0] - 11-November-2026

Author: Claude Sonnet 5.5 Medium

- What: You can now keep playing after the break. Take shot after shot from wherever the balls stopped: aim with a slider and nudge buttons, set power, cue-tip height (follow and draw) and side spin, then shoot. A scratched cue ball goes back on the head spot, pocketed balls stay gone, and Re-rack starts a fresh game. The new app icon (drawn by the other assistant) is in this build.
- Why: Until now the game was one break and a replay. This turns it into something you can play, which is the next milestone on the roadmap.
- How: A small new piece of the physics package carries the resting layout from one recorded shot to the next, with tests for the layout, the scratch respot and repeatability. The app panel switches from break controls to shot controls after the first shot. Pocket jaws and knuckles are still not built. Build number 2.

## [0.1.3] - 11-November-2026

Author: Claude Opus 5.5 High

- What: Recorded the Boss's decision to ship the pool launch natively in Swift for iPhone Duo and keep Unreal for the later smashing phase. Corrected the Duo research note against Apple's own pages.
- Why: Apple counts an app as optimized for iPhone Duo only when built with the iOS 27.1 SDK or later, and Unreal does not yet target it; the Duo simulator, needed for pose testing and store screenshots, also favours the native app.
- How: Updated the Duo research note (new decision section and corrections: no second live display through scene accessories, hinge as a smoothed control only, confirmed screenshot sizes), spec section 14, README and roadmap. No code changed.

## [0.1.2] - 11-November-2026

Author: Claude Sonnet 5.5 Medium

- What: Added the app version (0.1.1), build number 1, the no-special-encryption declaration, a placeholder app icon, and made the iOS build iPhone-only.
- Why: App Store Connect refused the first TestFlight uploads: empty version fields, no app icon, and iPad orientation rules.
- How: Build settings in both configurations plus an asset catalog with a generated 1024-pixel icon; no gameplay code changed.

## [0.1.1] - 10-November-2026

Author: GPT-6.1 Sol (inherited reasoning)

- What: Added the MIT license, clear setup and project scope, roadmap, dependency/research notices and repository-readiness review. Expanded exclusions for local credentials and build folders.
- Why: Prepare the original game repository for review without overstating finished work, ownership or program acceptance.
- How: Preserved the original history and private visibility, reviewed all published historical files, and checked existing tests and both platform builds. No gameplay code changed; see the readiness review for exact evidence and remaining decisions.

## [0.1.0] - 03-November-2026

Author: Claude Sonnet 5.5 Medium

- What: First running app. Hand-written Xcode project (iPhone and Mac, deployment targets 26), the BreakdownCore package (event-driven pool solver, recorded timeline, event model, twelve passing tests), the table scene, the cold open (break, freeze, melt, rewind, slow motion), the Physics Lens (grid, phase-coloured trails, velocity arrows, impact rings, captions with equations), replay controls and generated sound.
- Why: The spec's milestone one: a running app that shows the break and the table melting into the physics.
- How: Solver finds exact contact times with a quartic root finder, uses closed-form segments per motion phase, and records everything; playback only reads the timeline. Deviations from the spec: the cushion uses the flat-normal Level A model with no tilt yet; equations and captions are a SwiftUI card, not billboards in the scene; rack jitter is a fifth of the gap so no ball pair starts overlapping; the iPhone cold open was checked in the simulator, the Mac build compiles and launches but was not looked at yet.

## [0.0.2] - 03-November-2026

Author: Claude Opus 5.5 Medium

- What: Finalized the product and build spec after three reviews (Apple API check, physics check, fit with the Boss's ask).
- Why: Reviews found physics test errors, a determinism rule that contradicted itself, missing pocket and audio work in the first milestone, and a Part One question that was not a real decision.
- How: Applied the findings that held up; deployment targets moved to 26 so everything is testable here; milestone one split into 1a and 1b with a Step Zero.

## [0.0.1] - 02-November-2026

Author: Claude Opus 5.5 Medium

- What: Created the repository with the README, this change log, a Swift/Xcode ignore file, and the product and build spec in docs.
- Why: The Boss wants a native iPhone and Mac physics game. Pool comes first, with the table "melting" into the physics. Scan-and-smash with the iPhone's depth scanner comes later. The spec settles what we are building before any code is written.
- How: Four research passes (pool physics, Apple SDKs checked against the copies installed on this Mac along with a test build in the Simulator, game and physics-view design, scan-to-smash). One writer drafted the spec. Three reviewers checked it for Apple API accuracy, physics correctness, and fit with what the Boss asked for. A final pass applied their fixes.
