<!--
Author: Claude Opus 5.5 High
Date: 21-November-2026
Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 Game Center, plans/25-Nov-2026-shot-of-the-day-plan.md stage 3
        item 8: the game itself still sends nothing, but a player who signs in to Game Center has their daily score,
        streak and achievements handled by Apple under Apple's terms; a section says when the game signs in (only when
        Board is pressed, never at launch) and how to stop it (Hide the board). Also corrected while here: sharing a
        clip or a result card through the device's own share sheet, and saving a clip to the photo library, which
        0.7.7 added.)
PURPOSE: The words of Breakdown's privacy policy, for the page on the studio site whose address goes into App Store
         Connect as the Privacy Policy URL (plans/21-Nov-2026-bugs-after-0-6-6-plan.md item 41). The coordinator
         publishes it in the same style as the studio's other game pages. It must stay true to what the app does:
         App/PrivacyInfo.xcprivacy declares no tracking, no tracking domains and no collected data, and the only
         system interfaces it names are the app's own saved settings and the clock it uses to ease the camera. The
         game's own code sends nothing off the device (no web requests of its own, no server, no analytics, no cloud
         sync), and it has no account of its own, no ads and no purchases. The one thing that can leave the device is
         Game Center (App/GameCenter/GameCenter.swift): only after the player chooses to sign in, Apple's own service
         carries their daily score, streak and achievements, under Apple's terms. Data collected by Apple's Game Center
         is Apple's, not the developer's, so the App Privacy answer in App Store Connect stays "Data Not Collected". If
         the game itself ever sends anything off the device, this page, the privacy manifest and that answer change in
         the same change.
SRP/DRY check: Pass - the only privacy text for this game; the support page is store/pages/support.md.
-->
# Breakdown: See the Physics. Privacy policy

Last updated 26 November 2026.

Breakdown is a pool game for iPhone, iPad and Mac. The short version of this page: it collects nothing about you, the
game itself sends nothing anywhere, and it does not track you. The one exception is a choice you make: if you sign in
to Apple's Game Center to see the daily board, Apple carries your scores, under Apple's own terms.

## What stays on your device

The game has no account of its own. Your settings (sound, haptics, the aim guide, the surface and table you chose),
the lessons you have passed, the trick shots you have made, your daily shot results and streak, your achievements,
your Behind the 8-Ball scores and medals, your record against the computer and a game of pool you left halfway are all
saved on your device, inside the game's own storage. The game does not copy them to any server. If you delete the
game, they go with it.

## The daily board (Game Center)

The shot of the day has a board of scores, and the board is Apple's Game Center. The game never signs you in when it
starts for the first time. It asks only when you press Board. If you sign in, your score for the day, your longest
streak and the achievements you earn are sent to Game Center and shown there under your Game Center name, to the
players Game Center shows them to. Apple handles them under Apple's own terms and privacy policy; the developer
receives nothing about you from it. Once you have signed in, the game signs in again quietly when it starts, so your
scores reach the board without asking each time. If you decline, the game does not ask again by itself.

If you never sign in, nothing is sent. To turn the board off altogether, switch on Hide the board in Options: the game
then never signs in and shows no Board button. The daily shot, its score and your streak still work.

## What the game does not do

The game itself makes no internet connections: apart from Game Center, when you have signed in to it, nothing leaves
your device. It has no ads, no analytics, no tracking across other apps or websites, no in-app purchases and no chat.
It does not ask for your name, your email address, your contacts, your location, your camera or your microphone. A
two-player game is played by two people on the same device, so nothing is sent between devices either.

When you share a clip or a result picture, it goes through your device's own share sheet, only when you choose to and
only where you send it. Saving a clip to your photo library asks your permission to add to it; the game never reads
your photos.

A game controller, if you connect one, is read only to move the cue and press buttons in the game.

## Crash reports and beta testing

If you have chosen to share crash reports and app analytics with app developers in your device's settings, Apple may
pass anonymous crash reports for this game to its developer. If you play a test version through Apple's TestFlight,
Apple handles the installation and passes on any feedback, screenshots or crash reports you choose to send. Apple's
own privacy policy covers what Apple collects through Game Center, TestFlight and the App Store.

## Children

The game is for everyone. Because it collects no personal information from anyone, there is nothing about a child to
collect, share or delete. A child's device can keep Game Center off through the device's own parental settings, or
the board can be hidden in the game's Options.

## Changes to this page

If the game ever changes what it does with information, this page changes first and the date at the top moves.

## Questions

Write to the developer at mark@markbarney.net.
