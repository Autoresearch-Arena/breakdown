// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Checks for the Lens clip's sound (App/Clips/ClipSound.swift, 0.7.7, plans/23-Nov-2026-clips-plan.md): the
//          plan sounds the strike on the full-speed part's first frame and nothing during the melt, the rewind or the
//          end card; a held strike at clock 0 is heard as the clock leaves it, as in play; the full-speed part plays
//          exactly the cues FeelMapping gives for the events it crosses; the mix is as long as the clip, never louder
//          than its peak, silent after the last sound, and a sound panned fully right leaves the left silent; and the
//          VoiceBook helpers the live board and the clip share clamp the strength.
// SRP/DRY check: Pass - checks only; FeelMapping, VoiceBook and the script are the app's own.
@testable import Breakdown
import BreakdownLensModel
import BreakdownTimeline
import XCTest
import simd

final class ClipSoundTests: XCTestCase {
    private let right = SIMD3<Float>(1, 0, 0)

    private func plan(_ frames: [ClipFrame], _ tl: Timeline) -> [ClipSound] {
        ClipSound.plan(frames: frames, timeline: tl, surface: .cloth,
                       rights: [SIMD3<Float>](repeating: right, count: frames.count), variants: { _, _ in 3 })
    }

    private func breakScript() throws -> (ClipScript, Timeline) {
        let tl = TestShots.breakShot()
        let s = try XCTUnwrap(ClipScript.make(timeline: tl, captions: CaptionEngine.make(from: tl, surface: .cloth),
                                              signature: []))
        return (s, tl)
    }

    func testTheStrikeSoundsFirstAndTheSilentPartsStaySilent() throws {
        let (s, tl) = try breakScript()
        let sounds = plan(s.frames, tl)
        XCTAssertFalse(sounds.isEmpty)
        XCTAssertEqual(sounds.map(\.time), sounds.map(\.time).sorted())
        let firstFull = try XCTUnwrap(s.frames.firstIndex { $0.part == .fullSpeed })
        XCTAssertEqual(sounds[0].time, Double(firstFull) / 30, accuracy: 1e-9, "the strike is not the first sound")
        for x in sounds { XCTAssertLessThan(x.time, s.duration + 1) }
        // Nothing well inside the melt and rewind, or well inside the end card (a cue's small delay may run on a
        // little past the frame that sounds it).
        let meltStart = Double(try XCTUnwrap(s.frames.firstIndex { $0.part == .melt })) / 30
        let replayStart = Double(try XCTUnwrap(s.frames.firstIndex { $0.part == .replay })) / 30
        let endStart = Double(try XCTUnwrap(s.frames.firstIndex { $0.part == .endCard })) / 30
        for x in sounds {
            XCTAssertFalse(x.time > meltStart + 1 && x.time < replayStart, "a sound at \(x.time) during the melt")
            XCTAssertFalse(x.time > endStart + 1, "a sound at \(x.time) during the end card")
        }
    }

    func testAHeldStrikeSoundsAsTheClockLeavesIt() throws {
        let tl = TestShots.straightPot()
        func f(_ clock: Double, sounds: Bool, held: Int?) -> ClipFrame {
            ClipFrame(clock: clock, melt: 1, rate: sounds ? 0.1 : 0, sounds: sounds, heldEvent: held, caption: nil,
                      captionOpacity: 0, momentAllowed: true, endCard: 0, part: .replay)
        }
        let strike = try XCTUnwrap(tl.events.firstIndex { $0.kind == .cueStrike })
        let frames = [f(0, sounds: false, held: strike), f(0, sounds: false, held: strike), f(0.01, sounds: true, held: nil)]
        let sounds = plan(frames, tl)
        let first = try XCTUnwrap(sounds.first, "the strike was never heard")
        XCTAssertGreaterThanOrEqual(first.time, 2.0 / 30 - 1e-9, "the strike sounded while held")
        XCTAssertLessThan(first.time, 2.0 / 30 + 0.05)
    }

    func testTheFullSpeedPartPlaysFeelMappingsCues() throws {
        let (s, tl) = try breakScript()
        let head = Array(s.frames.prefix { $0.part == .lead || $0.part == .fullSpeed })
        var expected: [String] = []
        var a = 0.0
        for f in head {
            let b = f.clock
            defer { a = b }
            guard f.sounds, b > a else { continue }
            let crossed = tl.events.filter { ($0.time > a || (a <= 0 && $0.time <= 0)) && $0.time <= b }
            for cue in FeelMapping.cues(for: crossed) {
                expected.append(String(describing: VoiceBook.voice(for: cue.kind, surface: SurfaceSound(.cloth))))
            }
        }
        let got = plan(head, tl).map { String(describing: $0.voice) }
        XCTAssertEqual(got.sorted(), expected.sorted())
    }

    func testTheMix() {
        let bank = VoiceBank(voices: [.click: [[[0.5, 0.5, 0.5, 0.5]]]], rollSmooth: [], rollGrit: [])
        let loud = [ClipSound(time: 0, voice: .click, layer: 0, variant: 0, volume: 10, pan: 0),
                    ClipSound(time: 0.001, voice: .click, layer: 0, variant: 0, volume: 10, pan: 0)]
        let mixed = ClipSound.mix(loud, bank: bank, duration: 0.01)
        XCTAssertEqual(mixed.left.count, Int((0.01 * 44_100).rounded()))
        XCTAssertEqual(mixed.right.count, mixed.left.count)
        let peak = (mixed.left + mixed.right).map(abs).max() ?? 0
        XCTAssertLessThanOrEqual(peak, ClipSound.peak + 1e-6)
        // Silent after the last sound's samples end (the second starts at sample 44 and lasts 4 samples).
        for n in 50..<mixed.left.count { XCTAssertEqual(mixed.left[n], 0) }
        // Fully right: the left channel stays silent.
        let right = ClipSound.mix([ClipSound(time: 0, voice: .click, layer: 0, variant: 0, volume: 1, pan: 1)],
                                  bank: bank, duration: 0.01)
        XCTAssertLessThan(right.left.map(abs).max() ?? 0, 1e-6)
        XCTAssertGreaterThan(right.right.map(abs).max() ?? 0, 0.1)
    }

    func testTheSharedHelpersClampTheStrength() {
        XCTAssertEqual([0, 0.5, 1, 1.5].map { VoiceBook.layerIndex(strength: $0, count: 4) }, [0, 2, 3, 3])
        XCTAssertEqual(VoiceBook.volume(.click, strength: 1.5, jitter: 1), VoiceBook.volume(.click, strength: 1, jitter: 1))
        var random = SoundRandom(seed: 1)
        var last: Int?
        for _ in 0..<200 {
            let pick = VoiceBook.pickVariant(count: 2, last: last, random: &random)
            XCTAssertNotEqual(pick, last)
            last = pick
        }
    }
}
