// Author: GPT 6.2 Astra High
// Date: 21-November-2026
// PURPOSE: The selectable launch speeds, in metres per second, for ordinary shots and rack breaks.
// SRP/DRY check: Used by the shot controls and the eight-ball judge's speed sweep.

enum PlayerShotSpeed {
    static let ordinary = 0.5...13.0
    static let rackBreak = 7.0...16.0
}
