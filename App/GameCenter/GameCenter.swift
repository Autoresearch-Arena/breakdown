// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: Everything the game does with Game Center (0.7.10, Shot of the day plan stage 3 items 3 to 7,
//          plans/25-Nov-2026-shot-of-the-day-plan.md, and the "Hide the board" option of
//          plans/25-Nov-2026-everyone-can-play-plan.md Part E item 2). The only file in the app that imports GameKit.
//          What it does:
//          - Signs the player in only when they ask: the first press of Board (showBoard). Never at the first launch.
//            Once a sign-in has worked, later launches sign in quietly (launch, from BreakdownApp); a quiet sign-in
//            never shows Game Center's sign-in screen, so a player who declined is never asked again by the game
//            itself. Board keeps asking only when pressed.
//          - Never shows Game Center's corner badge (the access point): it is kept off at every sign-in, so nothing
//            covers the table. The board itself is opened through the access point's trigger, which shows the Game
//            Center screen without the badge being switched on (the replacement Apple names for the old Game Center
//            view controller, deprecated in the 26 systems this app targets).
//          - Posts today's score (postDaily) to the daily board and the streak (postStreak) to the streak board. Every
//            score first goes into GameCenterQueue (saved), then is sent while signed in, once; a daily score not sent
//            by the end of its day is dropped. So a make before the first sign-in is posted the moment Board signs in.
//          - Reports achievements: each one as it is earned (AchievementBook.earn calls reportAchievement), and at
//            every sign-in every earned achievement not yet reported (so the first sign-in reports all already
//            earned, and one earned offline goes later). Game Center's own completion banner is off: the game has its
//            own quiet note, and nothing may cover the table.
//          - With "Hide the board" on (GameSettings.boardHidden) every entry point does nothing: no sign-in, no
//            posting, no reporting, no board. The daily shot, its score and its streak are the daily mode's and still
//            work. Wave 2 can call these entry points freely without checking the option itself.
//          Nothing happens under a test launch (the store scenes, the scripted-strike flags, the unit test host).
//          Reads and writes UserDefaults.standard: the queue (GameCenterQueue.storageKey), whether a sign-in has ever
//          worked (signedInBeforeKey) and the achievement ids already reported (reportedKey); reads the achievements
//          save (AchievementRecord) for what is earned. GameKit calls: GKLocalPlayer.local.authenticateHandler and
//          isAuthenticated, GKLeaderboard.submitScore(_:context:player:leaderboardIDs:), GKAchievement.report(_:),
//          GKAccessPoint.shared.isActive and trigger(leaderboardID:playerScope:timeScope:handler:), names checked
//          against the installed iOS and macOS 27 SDK headers. Needs the Game Center entitlement
//          (App/Breakdown.entitlements) and, on the Mac, outgoing connections in the app sandbox.
// SRP/DRY check: Pass - checked AchievementBook (it decides what is earned; this only passes the ids on),
//          AchievementRecord (read, never written), GameSettings (the option lives there with every other option) and
//          App/Daily (written in parallel; it calls postDaily and postStreak, nothing here reads it). The queue and the
//          ids are the pure GameCenterQueue.swift; the Board button is GameCenterViews.swift.
import Foundation
import GameKit
import Observation
#if os(iOS)
import UIKit
#else
import AppKit
#endif

@MainActor
@Observable
final class GameCenter {
    static let shared = GameCenter()

    /// Where the sign-in stands, for the Board button.
    enum SignIn: Equatable, Sendable {
        /// Not signed in, nothing under way (a fresh install, a quiet sign-in that did not work, a sign-out).
        case idle
        /// A sign-in is under way.
        case signingIn
        /// Signed in: scores and achievements go straight out.
        case signedIn
        /// The player pressed Board and the sign-in did not work (declined, signed out of the system's service, or
        /// turned off there). The Board button shows a short line saying where to sign in.
        case unavailable
    }

    private(set) var state: SignIn = .idle

    /// Set once a sign-in has worked: later launches sign in quietly.
    static let signedInBeforeKey = "gameCenterSignedInBefore"
    /// The achievement ids Game Center has accepted, so a sign-in reports only the ones still missing.
    static let reportedKey = "gameCenterReported"

    /// False under a test launch: the store scenes and every scripted-strike flag (AchievementBook's own list), and
    /// the unit test host. Nonisolated (a plain value), so views and tests can read it from anywhere.
    nonisolated static let enabled: Bool = {
        guard AchievementBook.enabled else { return false }
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil
    }()

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var queue: GameCenterQueue
    /// The sign-in under way was asked for by the player (Board), so Game Center's sign-in screen may show.
    @ObservationIgnored private var askedByPlayer = false
    /// Open the board as soon as the sign-in under way works.
    @ObservationIgnored private var boardAfterSignIn = false

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        queue = GameCenterQueue.load(from: defaults)
    }

    /// True when the player may see the board at all: not a test launch and "Hide the board" off.
    var boardAllowed: Bool { Self.enabled && !GameSettings.boardHidden }

    // MARK: Entry points

    /// At launch (BreakdownApp): sign in quietly, only if a sign-in has worked before. A first launch does nothing.
    func launch() {
        guard boardAllowed, defaults.bool(forKey: Self.signedInBeforeKey) else { return }
        // A turn later, so the window is up first; the quiet sign-in never shows anything either way.
        Task { @MainActor [weak self] in self?.authenticate(askedByPlayer: false) }
    }

    /// The Board button: open today's board, signing in first if needed (the only sign-in the player is asked for).
    func showBoard() {
        guard boardAllowed else { return }
        if state == .signedIn, GKLocalPlayer.local.isAuthenticated {
            openBoard()
            return
        }
        boardAfterSignIn = true
        authenticate(askedByPlayer: true)
    }

    /// Today's score, from the daily mode after a make. `playedAt` decides which day's board it belongs to (the day in
    /// Coordinated Universal Time, as the board's own day); kept and sent once signed in, dropped if that day ends
    /// first.
    func postDaily(score: Int, playedAt: Date = Date()) {
        guard boardAllowed else { return }
        if queue.add(board: .daily, value: score, day: GameCenterQueue.utcDay(of: playedAt)) { queue.save(to: defaults) }
        flush()
    }

    /// The player's current streak of days with a make, from the daily mode after a make. The streak board keeps each
    /// player's best, so posting the current streak every day is all it needs.
    func postStreak(_ days: Int) {
        guard boardAllowed else { return }
        if queue.add(board: .streak, value: days, day: nil) { queue.save(to: defaults) }
        flush()
    }

    /// One achievement just earned (AchievementBook.earn). Reported at once while signed in. Otherwise nothing happens
    /// now: the next sign-in reads the saved achievements record (AchievementBook saves it right after earning) and
    /// reports every earned id Game Center has not accepted yet, this one included.
    func reportAchievement(_ id: String) {
        guard boardAllowed, state == .signedIn, Achievements.achievement(id: id) != nil else { return }
        report([id])
    }

    // MARK: Sign-in

    /// Start a sign-in. Setting GameKit's handler is what starts it; GameKit may call the handler again later (the
    /// player signs out or in from the system's settings), and each call lands in handleAuthentication.
    private func authenticate(askedByPlayer asked: Bool) {
        if asked { askedByPlayer = true }
        if GKLocalPlayer.local.isAuthenticated {
            didSignIn()
            return
        }
        state = .signingIn
        GKLocalPlayer.local.authenticateHandler = Self.makeAuthenticateHandler()
    }

    #if os(iOS)
    /// Built outside the main actor on purpose: GameKit may call its handler on any thread, and a closure made inside
    /// this main-actor class would be checked for the main thread when called and stop the app. This one only hops to
    /// the main actor, carrying the sign-in screen in a box (UIViewController is not Sendable; it is only touched again
    /// on the main actor). Marked Sendable so it fits the handler however the SDK types it.
    nonisolated private static func makeAuthenticateHandler() -> @Sendable (UIViewController?, (any Error)?) -> Void {
        return { screen, error in
            let box = UncheckedBox(value: screen)
            Task { @MainActor in GameCenter.shared.handleAuthentication(screen: box.value, error: error) }
        }
    }
    #else
    /// As on iOS, with the Mac's NSViewController.
    nonisolated private static func makeAuthenticateHandler() -> @Sendable (NSViewController?, (any Error)?) -> Void {
        return { screen, error in
            let box = UncheckedBox(value: screen)
            Task { @MainActor in GameCenter.shared.handleAuthentication(screen: box.value, error: error) }
        }
    }
    #endif

    #if os(iOS)
    private typealias SignInScreen = UIViewController
    #else
    private typealias SignInScreen = NSViewController
    #endif

    /// One answer from GameKit: a sign-in screen to show, signed in, or not signed in.
    private func handleAuthentication(screen: SignInScreen?, error: (any Error)?) {
        if let screen {
            // Game Center wants the player to sign in. Shown only when the player pressed Board; a quiet launch
            // sign-in never puts anything on screen.
            if askedByPlayer {
                present(screen)
            } else {
                state = .idle
            }
            return
        }
        if GKLocalPlayer.local.isAuthenticated {
            didSignIn()
            return
        }
        // Not signed in: declined, cancelled, offline, signed out, or turned off in the system's settings.
        if let error { NSLog("GameCenter: not signed in: %@", error.localizedDescription) }
        state = askedByPlayer ? .unavailable : .idle
        askedByPlayer = false
        boardAfterSignIn = false
    }

    private func didSignIn() {
        state = .signedIn
        askedByPlayer = false
        defaults.set(true, forKey: Self.signedInBeforeKey)
        // Never the corner badge: nothing covers the table.
        GKAccessPoint.shared.isActive = false
        reportEarnedAchievements()
        flush()
        if boardAfterSignIn {
            boardAfterSignIn = false
            openBoard()
        }
    }

    /// Put Game Center's sign-in screen over the game, from the front-most screen of the game's window.
    private func present(_ screen: SignInScreen) {
        #if os(iOS)
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let active = scenes.filter { $0.activationState == .foregroundActive }
        let windows = (active.isEmpty ? scenes : active).flatMap(\.windows)
        var top = (windows.first(where: { $0.isKeyWindow }) ?? windows.first)?.rootViewController
        while let next = top?.presentedViewController { top = next }
        guard let top else {
            // No window to show it from: count it as not signed in, so Board can be pressed again.
            state = .unavailable
            boardAfterSignIn = false
            askedByPlayer = false
            return
        }
        top.present(screen, animated: true)
        #else
        let app = NSApplication.shared
        let window = app.keyWindow ?? app.mainWindow ?? app.windows.first(where: { $0.isVisible })
        if let host = window?.contentViewController {
            host.presentAsSheet(screen)
        } else {
            // A window with no content controller: the sign-in gets a window of its own.
            let own = NSWindow(contentViewController: screen)
            own.makeKeyAndOrderFront(nil)
        }
        #endif
    }

    // MARK: The board

    /// Game Center's own screen on today's board, everyone's scores (the player can switch to friends there). The
    /// trigger is GameKit's way to open that screen from the game's own button (made for games that hide the badge and
    /// open Game Center from a controller); nothing in the SDK header ties it to the badge being on, so the badge stays
    /// off. If a device ever shows nothing on Board, the fix is to set isActive true just before the trigger and false
    /// again in its handler.
    private func openBoard() {
        GKAccessPoint.shared.isActive = false
        GKAccessPoint.shared.trigger(leaderboardID: GameCenterBoard.daily.rawValue, playerScope: .global,
                                     timeScope: .today, handler: nil)
    }

    // MARK: Scores

    /// Send every waiting score, while signed in. Each is handed out once (GameCenterQueue.begin); a send that fails
    /// stays waiting for the next sign-in, launch or post.
    private func flush() {
        guard state == .signedIn else { return }
        let before = queue
        let due = queue.begin(today: GameCenterQueue.utcDay(of: Date()))
        if queue != before { queue.save(to: defaults) }
        for entry in due {
            Task { @MainActor [weak self] in
                let sent = await Self.submit(entry)
                guard let self else { return }
                self.queue.finish(entry.id, sent: sent)
                if sent { self.queue.save(to: self.defaults) }
            }
        }
    }

    /// One score to its board. Off the main actor: only the Sendable entry crosses, and GameKit's objects stay here.
    nonisolated private static func submit(_ entry: GameCenterQueue.Entry) async -> Bool {
        do {
            try await GKLeaderboard.submitScore(entry.value, context: 0, player: GKLocalPlayer.local,
                                                leaderboardIDs: [entry.board.rawValue])
            return true
        } catch {
            NSLog("GameCenter: a score for %@ was not sent: %@", entry.board.rawValue, error.localizedDescription)
            return false
        }
    }

    // MARK: Achievements

    /// At sign-in: every earned achievement (the saved record) that Game Center has not accepted yet. Ids no longer
    /// in the catalogue (a removed trick shot's) are left out.
    private func reportEarnedAchievements() {
        let reported = Set(defaults.stringArray(forKey: Self.reportedKey) ?? [])
        let missing = AchievementRecord.load(from: defaults).earned.keys
            .filter { !reported.contains($0) && Achievements.achievement(id: $0) != nil }
            .sorted()
        report(missing)
    }

    private func report(_ ids: [String]) {
        guard !ids.isEmpty else { return }
        Task { @MainActor [weak self] in
            let accepted = await Self.send(achievements: ids)
            guard accepted, let self else { return }
            var reported = Set(self.defaults.stringArray(forKey: Self.reportedKey) ?? [])
            reported.formUnion(ids)
            self.defaults.set(reported.sorted(), forKey: Self.reportedKey)
        }
    }

    /// Report achievements as complete, in one call. Off the main actor, like submit.
    nonisolated private static func send(achievements ids: [String]) async -> Bool {
        let achievements = ids.map { id -> GKAchievement in
            let achievement = GKAchievement(identifier: GameCenterIDs.achievement(id))
            achievement.percentComplete = 100
            // The game's own note says it was earned; Game Center's banner would cover the table.
            achievement.showsCompletionBanner = false
            return achievement
        }
        do {
            try await GKAchievement.report(achievements)
            return true
        } catch {
            NSLog("GameCenter: achievements were not reported: %@", error.localizedDescription)
            return false
        }
    }
}

/// Carries a value GameKit hands over on another thread to the main actor, where alone it is used. Only for the
/// sign-in screen above.
private struct UncheckedBox<Value>: @unchecked Sendable {
    let value: Value
}
