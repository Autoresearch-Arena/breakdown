// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: The three store scenes that lead the 0.7.10 store page (plans/25-Nov-2026-front-door-and-table-view-plan.md
//          stage 5 step 1), each opened by its own launch flag (StoreScene in App/ShowpieceModel.swift, which also
//          keeps achievements and Game Center quiet for any store scene) and taken by scripts/store-shots.sh:
//          - -storeLensBumper: bumper pool's first shot, struck at the nearest ball with the table's own power, then
//            held a moment after its first ball contact with the Physics Lens up (the Lens's own bumper pool plan).
//          - -storeStrike: free play on the pool table after the break: a shot lined up on the nearest ball with a
//            little draw, a little right side and a slightly raised cue, and "Your shot" open, so the strike panel
//            shows its planned figures (beside the table on iPad, the Mac and the open folding phone; on the upright
//            phone App/Phone/PhoneAimPanel.swift opens its sheet for this scene).
//          - -storeDaily: today's shot of the day, its answer struck as the player's own try (the same stroke Watch the
//            answer strikes), so the day is made and the result card shows the score and the streak. Played on a
//            throwaway record (StoreScene.dailyDefaults, cleared at each such launch), never the device's own, so the
//            scene can be retaken and a real player's day is never touched.
//          Each waits with the model's own storeWait, as the other scenes do, and touches the model only through its
//          ordinary methods.
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.8.1 store: the daily scene holds at the start of the made try, so
//          the picture shows the cue, the balls and the mark beside the result, not a bare table; the strike scene has a
//          little less draw, so its back spin tile fits its figure.)
// SRP/DRY check: Pass - checked ShowpieceModel's store scenes (the scene list, the waiting and the scripted person's
//          stroke are theirs; these follow storePersonStroke's power rule rather than calling it, as it needs a match)
//          and TrickShotMode.lineUpAnswer (reused to line up the daily answer).
import BreakdownPhysics
import BreakdownTimeline
import Foundation

extension StoreScene {
    /// The record suite the daily store scene plays on.
    static let dailySuiteName = "BreakdownStoreSceneDaily"

    /// Where the daily mode keeps its record: a cleared throwaway suite for -storeDaily, the device's own otherwise.
    /// Called once, when the model makes its daily mode.
    static func dailyDefaults() -> UserDefaults {
        guard requested == .daily, let suite = UserDefaults(suiteName: dailySuiteName) else { return .standard }
        suite.removePersistentDomain(forName: dailySuiteName)
        return suite
    }
}

extension ShowpieceModel {
    /// -storeLensBumper: bumper pool's opening shot, held just after its first contact under the Lens.
    func storeLensBumperScene() async {
        playTable(.bumperPool)
        await storeWait { !isSolving && aimReady }
        if placingCueBall { _ = confirmCueBallPlacement() }
        if racked {
            breakNow()
        } else {
            aimAtNearestBall()
            shotPower = min(max(physicsTable.defaultShot.power, 0.5), 8)
            shootNow()
        }
        await storeWait { !isSolving && aimReady }
        // A moment past the first ball contact: the balls are moving and the Lens has its arrows to draw. Without a
        // contact (it should not happen at the nearest ball) a third of the way through the shot.
        let contact = timeline.events.first { $0.kind == .ballBall }?.time
        setLens(true)
        scrub(to: contact.map { $0 + 0.05 } ?? duration * 0.3)
    }

    /// -storeStrike: the strike panel's planned figures for an interesting shot after the break.
    func storeStrikeScene() async {
        startGame()
        breakNow()
        await storeWait { !isSolving && aimReady }
        if placingCueBall { _ = confirmCueBallPlacement() }
        aimAtNearestBall()
        // A firm stroke with a little draw and a little right side, the cue raised about five degrees (the sine of the
        // angle, as the solver takes it), so every figure in the panel has something to say.
        let radius = physicsTable.parameters.ballRadius
        shotPower = 3.2
        shotTipUp = -0.22 * radius  // 0.8.1 store: under ten turns a second, so the back spin tile fits its figure
        shotTipSide = 0.2 * radius
        activeElevation = sin(5 * Double.pi / 180)
        setLens(false)
        requestShotPanel(.open)
    }

    /// -storeDaily: today's shot made with the answer's own stroke, tried again (as the player would) should a try
    /// ever miss, until the day is finished; the result card is the picture.
    func storeDailyScene() async {
        let daily = dailyMode
        daily.begin()
        for _ in 0..<DailyRecord.maxTries where !daily.finished {
            guard let shot = trickMode.current else { return }
            trickMode.lineUpAnswer()
            if shot.isBreak { breakNow() } else { shootNow() }
            await storeWait { !isSolving && aimReady }
            // The table layer judges the try too; judging twice is refused by the trick mode, so this only makes sure
            // the card does not wait on the view.
            trickMode.update()
        }
        // 0.8.1 store: a made day leaves a bare table (every ball down). The picture shows the shot itself instead:
        // the clock is put back to the start of the made try, so the cue, the balls and the mark are on the cloth
        // beside the result card (scrubbing never re-judges a try). Tried and dropped: the Lens part way through,
        // where its own callout covered the table and most balls were already down.
        // -storeDailyAt <fraction of the shot> and -storeDailyLens YES/NO tune it from the launch line.
        guard daily.finished else { return }
        let args = UserDefaults.standard
        let at = args.object(forKey: "storeDailyAt") != nil ? args.double(forKey: "storeDailyAt") : 0.02
        setLens(args.object(forKey: "storeDailyLens") != nil ? args.bool(forKey: "storeDailyLens") : false)
        scrub(to: duration * min(max(at, 0), 1))
    }
}
