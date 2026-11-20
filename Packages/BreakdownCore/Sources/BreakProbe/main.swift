// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 ("tricks" runs the trick-shot authoring search; with no argument it
//          still runs the original break sweep).
// PURPOSE: Dev tool. With no argument: sweeps candidate breaks (aim offset, speed, tip height) and prints the ones that
//          drop at least two object balls while keeping the cue ball, so the showpiece break is chosen with evidence.
//          With "tricks [id ...]": authors the app's trick shots (TrickAuthoring) and prints each one's layout, strike
//          and measured skill windows, ready to copy into the app's TrickShots file.
// SRP/DRY check: Pass - single-purpose command line probe, not shipped in the app.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline

import Foundation

// Print as we go: a long search should show its progress even when its output goes to a file.
setvbuf(stdout, nil, _IOLBF, 0)
let args = Array(CommandLine.arguments.dropFirst())
if args.first == "tricks" {
    runTrickAuthoring(only: Set(args.dropFirst()))
} else {
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
}
