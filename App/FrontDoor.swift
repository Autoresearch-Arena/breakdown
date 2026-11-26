// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: What the game opens on from the second launch on (0.7.10, plans/25-Nov-2026-front-door-and-table-view-plan.md,
//          "Decisions already made"). The very first launch is untouched: it still puts a new player at the racked pool
//          table with one line on how to shoot (ShowpieceModel.startOpeningIfFirstLaunch). Every later launch opens on
//          the main menu, and behind it the table last played is set up and still: nothing is pushed, no card, no
//          lesson. Until 0.7.10 every launch put the pool table up whatever had been played (0.7.1), so a player who
//          last played bar billiards met a pool table.
//          Two parts:
//            - FrontDoor.noteTablePlayed: ShowpieceView calls it whenever a new recording goes on screen; when that
//              recording is a shot the player (or the computer, in the player's game) struck, its table is remembered
//              on the device. A trick shot, a lesson and Behind the 8-Ball are played on the pool table, so they
//              remember the pool table; a bumper pool match remembers bumper pool.
//            - ShowpieceModel.openOnLastTableIfLaterLaunch: the model's init calls it once, after the first-launch
//              check. On a later launch with the menu up and no launch flag asking for a screen, a remembered table
//              other than the pool table is put up behind the menu through setTable (its start layout, still, ready to
//              shoot, the menu left open). The pool table needs nothing: init already racks it.
//          The marked spot in openOnLastTableIfLaterLaunch is where wave 2 makes a later launch open on today's shot
//          instead, when today's shot is not yet played and no game is in progress.
//          Reads and writes one UserDefaults key (lastTableKey). Reads the model's menuOpen, hasSeenOpening,
//          playerShotOnScreen and solvedTable; changes it only through setTable.
// SRP/DRY check: Pass - checked ShowpieceModel (tableKind and TableKind.storageKey hold the table CHOSEN from the
//          Tables list, which a match on another table never changes, so a separate memory of the table PLAYED is
//          needed), TitleScreen.launchSkipsTitle and StoreScene.requested (reused as the same guards the first-launch
//          check uses).
import Foundation

enum FrontDoor {
    /// UserDefaults key: the raw value of the TableKind of the last shot played on this device.
    static let lastTableKey = "frontDoorLastTable"

    /// The table of the last shot played on this device; the pool table when nothing has been played yet.
    static var lastTablePlayed: TableKind {
        UserDefaults.standard.string(forKey: lastTableKey).flatMap(TableKind.init(rawValue:)) ?? .standard
    }

    /// A new recording is on screen: when it is a shot struck at the table (not the opening, not a still table),
    /// remember the table it was solved on. Written only when it changed, so a run of shots costs nothing.
    @MainActor static func noteTablePlayed(_ model: ShowpieceModel) {
        guard model.playerShotOnScreen else { return }
        let kind = model.solvedTable
        guard UserDefaults.standard.string(forKey: lastTableKey) != kind.rawValue else { return }
        UserDefaults.standard.set(kind.rawValue, forKey: lastTableKey)
    }
}

extension ShowpieceModel {
    /// From the second launch on: put the last table played up behind the menu (see the file header). Called once, from
    /// init, after the first-launch check (which closes the menu on a first launch, so this then does nothing).
    func openOnLastTableIfLaterLaunch() {
        let args = ProcessInfo.processInfo.arguments
        guard hasSeenOpening, menuOpen, !TitleScreen.launchSkipsTitle, StoreScene.requested == nil,
              !args.contains("-retryCases") else { return }
        // 0.7.10 frontdoor: wave 2 hook. When today's shot exists, is not yet played and no game is in progress (no saved
        // match: hasSavedMatch is false), set today's shot up here instead and return; otherwise fall through to the
        // last table played. Nothing is pushed either way: the menu stays open over a still table.
        let last = FrontDoor.lastTablePlayed
        // The pool table is already racked by init (every launch starts there), so only another table needs setting up.
        guard last != .standard else { return }
        setTable(last)
    }
}
