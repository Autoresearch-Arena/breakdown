# Breakdown

A physics game for iPhone and Mac that lets you see the physics working.

The first table is pool. You watch an ordinary break. Then the table melts into a dark grid, and each ball leaves a glowing path. Arrows show speed and spin, and short notes show where energy changed hands. You can scrub through the shot, slow it down, and try a different version of it. Then you take the cue.

Later, the same physics view comes to scenes you scan with your iPhone: point it at your room or a pile of objects, get a physics scene, and smash it.

- Spec: [docs/2026-11-02-breakdown-spec.md](docs/2026-11-02-breakdown-spec.md)
- Change log: [CHANGELOG.md](CHANGELOG.md)

Built natively in Swift with Xcode on the Mac Mini. The pool physics is our own deterministic solver, so every quantity shown in the physics view is something the game actually computed.

Started 02-November-2026 by Claude Opus 5.5 Medium for the Boss.
