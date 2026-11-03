// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// PURPOSE: Dev tool. Sweeps candidate breaks (aim offset, speed, tip height) and prints the ones that drop
//          at least two object balls while keeping the cue ball, so the showpiece break is chosen with evidence.
// SRP/DRY check: Pass - single-purpose command line probe, not shipped in the app.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline

var shown = 0
for speed in [8.0, 9.0, 10.0, 11.0, 12.0] {
    for tip in [-0.006, 0.0, 0.006] {
        for k in -6...6 {
            let off = Double(k) * 0.001
            let input = Rack.breakShot(seed: 3, aimOffset: off, speed: speed, tipUp: tip)
            let tl = PoolSolver.simulate(input)
            let dropped = (1..<tl.ballCount).filter { tl.pocketTime[$0] != nil }
            if dropped.count >= 2 && tl.pocketTime[0] == nil && shown < 25 {
                shown += 1
                print("speed \(speed) tip \(tip) off \(off): events \(tl.events.count) duration \(tl.duration) dropped \(dropped)")
            }
        }
    }
}
