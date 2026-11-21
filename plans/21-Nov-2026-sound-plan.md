<!--
Author: Claude Fable 5.2 High
Date: 21-November-2026
PURPOSE: Plan for lifting Breakdown's sound from simple generated beeps and thumps to something that sounds like a
         pool table in a room. Written for junior developers: what exists, what to build in order, and how it is
         checked (by ear, by the Boss).
SRP/DRY check: Pass - checked SoundBoard.swift, FeelMapping.swift, Haptics.swift, TitleMusic.swift and the glow-up
         plan's rule that sound is made in code. This plan keeps that rule.
Edited: Claude Opus 5.5 High, 21-November-2026 (answered the audio-session question before starting, as asked;
         recorded the Boss's decision on the Moon; noted how each package was built).
-->
# Sound that matches the physics

## In plain words

Every sound in the game is a short tone mixed with hiss, built in code when the app starts. It is driven by the
real impact strengths, which is the right idea, but the sounds themselves are thin: one voice per kind of hit, all
coming from the middle of the screen, in silence. Balls roll without a sound. A game whose point is that you can
feel the physics should let you hear it: where on the table a hit happened, how hard, what was hit, and the hum of
a ball rolling across cloth. This is polish, so it comes after the rules and physics plans, but it is the kind of
polish award judges notice in the first ten seconds.

Rule kept from the glow-up plan: sound is made in code with Apple's audio framework. No sample packs.

## What exists today

- SoundBoard.swift builds seven buffers at launch (break crack, soft and hard clicks, cue tock, light and heavy
  rail thump, pocket) from sines and noise, and plays them through a small pool of players, one channel, centred.
- FeelMapping.swift turns the events crossed in a frame into at most a few cues with a strength from the impulse.
- No rolling sound, no room, no position, no sound for pins, posts, a ball leaving the table or landing from a jump.
- The Sound option and the mute launch flag are honoured.
- Audio session (checked 21-Nov-2026, before any change): on iPhone and iPad both SoundBoard and TitleMusic set the
  shared session to the "ambient" category and make it active. Ambient means the phone's silent switch IS respected
  (switch on silent and the game makes no sound), and the player's own music or podcast keeps playing underneath
  instead of being stopped. The Mac has no audio session; the game simply plays through the system output. This plan
  keeps the ambient category unchanged.

## Package 1: better voices

1. Replace each one-tone voice with several ringing partials that fade at different rates, plus a very short noise
   burst for the contact itself. A struck ball rings at a few high, closely spaced pitches that die in a few
   hundredths of a second; a rail is a low, dull, quickly damped thud; the slate landing of a jump is a hard knock
   with a low body. Keep each recipe as a small table of partials (pitch, level, fade) at the top of SoundBoard so
   it can be tuned without touching the code below it.
2. Strength changes the sound, not only the volume: a harder hit is brighter (louder upper partials, shorter
   contact burst). Build each voice at four strengths and pick or blend by the cue's strength.
3. Never the same twice: small seeded changes in pitch and level per play.
4. New voices: pin knocked down, post, ball landing from a jump, ball leaving the table, a rim skip and a miscue
   (those two events come from the physics plans; add the voices when the events exist).
5. Pocket: a drop, then two or three knocks as the ball settles, with timing that depends on entry speed.

## Package 2: where the sound is

1. Play each cue from the position of its event on the table. The event has a point in table coordinates; map it
   to left and right across the screen as the table is drawn (the table turns between portrait and landscape, so
   take the mapping from the same frame the drawing uses, TableFrame.swift). Keep the effect gentle.
2. Add a little room: one shared reverb at a low level so hits do not sound like they happen in a void. Off when
   the system's Reduce Motion is on is not required; off with the Sound option is.

## Package 3: rolling and the quiet between hits

1. A continuous soft rolling sound per moving ball, as filtered noise whose loudness and pitch follow the ball's
   speed, read from the timeline at the playback clock. Cap it at the three fastest balls. It must follow slow
   motion (lower and slower), stop while paused, and make sense when scrubbing backwards (silent while scrubbing is
   acceptable; a wrong sound is not).
2. Sliding sounds different from rolling: a ball in its sliding phase gets a slightly harsher voice. The phase is
   in the timeline. This is the Lens in sound: you can hear the moment a ball stops skidding.
3. Surfaces: ice, glass, sand and the other surfaces each change the rolling voice and the rail thud. Sand is nearly
   silent and dull; glass is bright. The Moon: decided by the Boss (21-Nov-2026), no special sound at all. No rumble
   and no silence gimmick; the Moon uses the ordinary cloth voices, and only its physics (longer rolls, higher
   jumps) changes what is heard.

## Package 4: the mix

1. A limiter on the output so a break does not clip, and levels set so the break is the loudest thing in the game
   and a soft safety is clearly quieter.
2. Title music ducks under play and never overlaps a shot (TitleMusic.swift already fades; check it).
3. Haptics stay in step: every sound cue with a haptic fires both from the same strength (Haptics.swift).

## How it was built (21-Nov-2026, sound stream)

- Package 1: every voice is a small table of ringing partials plus a short contact burst, kept at the top of
  SoundBoard.swift and built at four strengths with two or three seeded variants each, on a background task so
  launch does not wait. New voices: pin down, post, jump landing, ball off the table (a floor thud after the fall
  time), rim skip, miscue, balls settling in contact, pocket settling knocks, and three match moments (foul, turn
  change, win) that match screens call with one line. The pocket drop is followed by knocks timed from the entry
  speed: a fast ball hits the back of the pocket first, then every ball lands and bounces on the pocket bottom.
- Package 2: each hit is panned gently from where it happened, using the camera's own left-right direction over the
  table frame, so it follows the table turning between portrait and landscape and the Ride camera. A light shared
  room reverb sits on everything.
- Package 3: up to three rolling voices follow the three fastest balls at the playback clock: louder and brighter
  with speed, lower in slow motion, harsher while a ball skids, silent when paused, scrubbing, rewinding or behind the
  menu. Every surface has its own rolling and rail colour; the Moon uses cloth's.
- Package 4: a peak limiter on the output, the break set as the loudest voice, title music fading out fast at the
  first shot sound and dipping under match moments, and haptics drawn from the very same cue strengths and timing.

## How this is checked

Sound cannot be checked by a build. Each package ends with a TestFlight build and a short list for the Boss of what
to listen for: a soft roll, a hard break, a bank shot with the phone held sideways, a jump, a pocket at slow and
fast speed, slow motion with the Lens on. Use the existing launch flag that prints every cue to confirm in the log
that each event produced the cue expected. Performance: building voices must not slow launch (measure before and
after; build them on a background task if it does), and playback must never drop frames on the oldest supported
iPhone.

## Done when

The Boss has listened to each package on his phone with headphones and through the speaker and said yes.
