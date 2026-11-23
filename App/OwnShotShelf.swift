// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Make it again (0.7.7, plans/23-Nov-2026-make-it-again-plan.md, new file 3): the shelf called "Your shots",
//          where the player's own saved challenges live. It decides when the shot on screen can be saved (free play, a
//          shot at rest that dropped an object ball and not the cue ball, struck with the cue ball on the default
//          physics), saves it (OwnShot.make, with the highlight judge's kind for the default name), knows when the shot
//          on screen is already saved (so the button reads Play it now), puts a saved shot on the table in the
//          trick-shot mode on its own cloth, and keeps the shelf's rules: at most sixty shots, rename (trimmed, forty
//          characters at most), delete, made-again marks and the order Next shot walks (newest first).
//          Background work, one solve at a time at utility priority and only with Sendable values: each shot's saved
//          stroke is solved and judged once per run when the list first appears (proof, and the list's drawing from
//          the same solve); a shot's window (how forgiving it is) is measured only when it is saved or played and its
//          proof holds, once per app build, never for the whole shelf at once.
//          Storage: Application Support/Breakdown/own-shots.json (MatchMode's folder), JSON with a format number,
//          written atomically on every change; a failed write is logged and play carries on. A file that will not
//          decode, or one from a newer format, is moved aside to own-shots-unreadable.json and the shelf starts empty,
//          so a later write never destroys it. A shelf made with fileURL nil never touches a file (tests).
//          Read by OwnShotViews (the button, menu items, the Mac command and the list section), ControllerInput (left
//          stick click), TrickShotMode (hooks T3 and T4), OwnShotProof.arm and NotebookDossier (hook N1).
// SRP/DRY check: Pass - checked MatchMode (the save-file pattern is the same, written here for this file),
//          TrickPathCache (the same once-per-run serial background solving), TrickShotMode.doneIDs (the authored
//          progress; saved shots' makes are kept here, never there) and HighlightOffer (which shots get a card; this
//          only reads the judged kind for a name). The words are OwnShotWords; the data and its rules are OwnShot.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import Observation

/// The shelf's file on disk: a format number, so a newer format is never misread, and the shots oldest first.
/// Internal (not private) only so the tests can round-trip it.
struct OwnShotFile: Codable, Equatable, Sendable {
    var format: Int
    var shots: [OwnShot]
}

@MainActor
@Observable
final class OwnShotShelf {
    /// The app's shelf. A var (main-actor isolated, as the class is) only so tests can swap in a memory shelf and put
    /// this one back; nothing in the app assigns it.
    static var shared = OwnShotShelf(fileURL: OwnShotShelf.defaultURL)
    /// The most shots the shelf holds; when full, Make it again is disabled and its hint says to delete one.
    static let capacity = 60
    /// The longest name a rename keeps.
    static let nameLimit = 40
    /// The file format this build writes and reads.
    static let format = 1

    /// Saved shots, oldest first (the list shows them newest first).
    private(set) var shots: [OwnShot] = []
    /// This run's check of each shot (never stored: a new build may change it). Nil: not checked this run, or a shot
    /// this version cannot set up.
    private(set) var proof: [String: OwnShotCheck] = [:]
    /// This run's drawing of each shot's saved stroke, from the same solve as its check.
    private(set) var paths: [String: TrickPath] = [:]

    /// Where the shelf is kept; nil keeps everything in memory (tests, or a file that could not be moved aside).
    @ObservationIgnored private var fileURL: URL?
    @ObservationIgnored private var checksStarted = false
    /// Shots whose window is being measured now, so one is never measured twice at once.
    @ObservationIgnored private var measuring: Set<String> = []
    /// Shots to measure once their check comes back holding (saved this run, or played while still being checked).
    @ObservationIgnored private var measureAfterCheck: Set<String> = []

    /// nil keeps everything in memory and never reads or writes a file.
    init(fileURL: URL?) {
        self.fileURL = fileURL
        if let loaded = Self.load(from: fileURL) {
            shots = loaded
        } else {
            // The file could not be read and could not be moved aside either: run from memory so no write replaces it.
            self.fileURL = nil
        }
    }

    /// Application Support/Breakdown/own-shots.json, beside MatchMode's saved games.
    static var defaultURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Breakdown", isDirectory: true)
            .appendingPathComponent("own-shots.json")
    }

    /// The app build a window was measured on (CFBundleVersion); a new build measures again.
    static var currentBuild: String { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "" }

    func shot(id: String) -> OwnShot? { shots.first { $0.id == id } }

    /// The TrickShot for a saved shot, with the card's "no longer makes it" note when this run's check found so.
    func trickShot(id: String) -> TrickShot? { shot(id: id).flatMap { challenge(for: $0) } }

    private func challenge(for own: OwnShot) -> TrickShot? {
        own.challenge(note: proof[own.id] == .changed ? OwnShotWords.changed : nil)
    }

    // MARK: Saving

    /// The attempt on screen when it is free play's own shot, at rest and on screen, with nothing else going on (no
    /// menu, no solve in flight, no best-shot replay), and saveable (OwnShot.refusal). The cheap checks come first:
    /// views and the Mac menu read this on every evaluation.
    private func saveableAttempt(_ model: ShowpieceModel) -> ShotAttempt? {
        guard model.freePlayUp, model.playerShotOnScreen, model.aimReady, !model.isSolving, !model.menuOpen,
              !model.replayingBest, let a = model.currentAttempt, OwnShot.refusal(for: a) == nil else { return nil }
        return a
    }

    /// The saved shot an attempt already is: the same input seed (not the attempt's serial seed, which after a kept
    /// strike is a different number), the same start, and only then (it walks the whole recording) the same motion.
    private func savedShot(matching a: ShotAttempt) -> OwnShot? {
        let candidates = shots.filter { $0.strike.seed == a.input.seed && $0.start == a.start }
        guard !candidates.isEmpty else { return nil }
        let hash = String(a.motionHash, radix: 16)
        return candidates.first { $0.motionHash == hash }
    }

    /// True when the shot on screen can be saved now (Decision 1), is not saved yet, and the shelf has room.
    func canSave(_ model: ShowpieceModel) -> Bool {
        guard let a = saveableAttempt(model) else { return false }
        return shots.count < Self.capacity && savedShot(matching: a) == nil
    }

    /// The saved shot that the shot on screen already is, if any.
    func savedShot(for model: ShowpieceModel) -> OwnShot? {
        saveableAttempt(model).flatMap { savedShot(matching: $0) }
    }

    /// True when the shot on screen could be saved but the shelf is full.
    func isFull(for model: ShowpieceModel) -> Bool {
        guard shots.count >= Self.capacity, let a = saveableAttempt(model) else { return false }
        return savedShot(matching: a) == nil
    }

    /// Save the shot on screen. Returns the new shot, or nil when it cannot be saved. Its check starts at once and its
    /// window is measured once the check comes back holding. No sound and no haptic: the button's new words are the
    /// feedback, and VoiceOver hears where the shot went.
    @discardableResult func save(from model: ShowpieceModel) -> OwnShot? {
        guard canSave(model), let a = model.currentAttempt else { return nil }
        // The captions are the on-screen recording's (saveableAttempt needs playerShotOnScreen), as the highlight
        // judge needs. The kind only names the shot; the goal is read from the recording.
        let kind = ShotHighlightJudge.judge(timeline: a.timeline, facts: a.facts, captions: model.captions,
                                            table: a.table, isBreak: false)?.kind
        guard let own = OwnShot.make(from: a, kind: kind, number: shots.count + 1), add(own, measure: true) else {
            return nil
        }
        ShotNarration.announce(OwnShotWords.savedAnnouncement)
        return own
    }

    /// Put a made shot on the shelf (false when full or already there): append, write, start its check. `measure`
    /// asks for its window once the check holds (a save); tests add shots without it.
    @discardableResult func add(_ own: OwnShot, measure: Bool = false) -> Bool {
        guard shots.count < Self.capacity, shot(id: own.id) == nil else { return false }
        shots.append(own)
        write()
        if measure { measureAfterCheck.insert(own.id) }
        if own.trickShot != nil {
            proof[own.id] = .checking
            Task { [weak self] in await self?.runCheck(own.id) }
        }
        return true
    }

    /// True for a saved shot's TrickShot built before its window was measured (its window is the fallback): the
    /// notebook's How forgiving block is not shown for it (hook N1).
    func isUnmeasured(_ shot: TrickShot) -> Bool {
        let f = OwnWindow.fallback
        return OwnShot.isOwnID(shot.id)
            && shot.window == TrickWindow(aim: f.aim, power: f.power, tipUp: f.tipUp, tipSide: f.tipSide)
    }

    // MARK: The shelf

    /// Rename: trimmed, at most nameLimit characters; an empty name keeps the old one.
    func rename(id: String, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let i = shots.firstIndex(where: { $0.id == id }) else { return }
        let kept = String(trimmed.prefix(Self.nameLimit))
        guard shots[i].name != kept else { return }
        shots[i].name = kept
        write()
    }

    /// Delete: the shot, its check and its drawing go, and the file is written.
    func delete(id: String) {
        guard let i = shots.firstIndex(where: { $0.id == id }) else { return }
        shots.remove(at: i)
        proof[id] = nil
        paths[id] = nil
        measureAfterCheck.remove(id)
        write()
    }

    /// A saved shot was made again (TrickShotMode.markDone's hook T4). Kept on the shelf, never in the authored
    /// progress (doneIDs), so the menu's made count and the highlight card's trick link see only authored shots.
    func noteMade(id: String) {
        guard let i = shots.firstIndex(where: { $0.id == id }), !shots[i].made else { return }
        shots[i].made = true
        write()
    }

    /// The shot after this one in the list's order (newest first), or nil after the last (TrickShotMode.next, T3).
    func next(after id: String) -> OwnShot? {
        let order = Array(shots.reversed())
        guard let i = order.firstIndex(where: { $0.id == id }), i + 1 < order.count else { return nil }
        return order[i + 1]
    }

    /// Put a saved shot on the table in trick-shot mode, on its own cloth (Decision 6). The surface is set after begin,
    /// on a still table, so nothing is solved again; it stays chosen afterwards, like any Surface menu choice. A shot
    /// this version cannot set up does nothing (its row says so and is disabled).
    func play(_ own: OwnShot, model: ShowpieceModel) {
        guard let shot = challenge(for: own), let surface = own.surface else { return }
        model.trickMode.begin(shot)
        if model.surface != surface { model.setSurface(surface) }
        // Measure how forgiving it is, once per build, when its stroke is known to hold.
        switch proof[own.id] {
        case nil:
            measureAfterCheck.insert(own.id)
            proof[own.id] = .checking
            Task { [weak self] in await self?.runCheck(own.id) }
        case .checking?:
            measureAfterCheck.insert(own.id)
        case .holds?:
            measureIfDue(own.id)
        case .changed?:
            break
        }
    }

    /// The checks and drawings, once per run, when the list first appears (a shot saved this run is already being
    /// checked). One shot after another in one task, as TrickPathCache does.
    func startChecks() {
        guard !checksStarted else { return }
        checksStarted = true
        let ids = shots.filter { proof[$0.id] == nil && $0.trickShot != nil }.map(\.id)
        guard !ids.isEmpty else { return }
        for id in ids { proof[id] = .checking }
        Task { [weak self] in
            for id in ids {
                guard let self else { return }
                await self.runCheck(id)
            }
        }
    }

    // MARK: Background work

    /// Solve one shot's saved stroke off the main actor, judge it, and trace its drawing from that same solve (the
    /// tracing samples the whole recording, so it stays off the main actor too). Back here, the result is kept only if
    /// the shot is still on the shelf.
    private func runCheck(_ id: String) async {
        guard let own = shot(id: id) else { return }
        let result = await Task.detached(priority: .utility) { () -> (holds: Bool, path: TrickPath?) in
            let c = OwnShotProof.check(own)
            return (c.holds, c.timeline.flatMap { TrickPath.traced($0, start: own.start) })
        }.value
        guard shot(id: id) != nil else { return }
        proof[id] = result.holds ? .holds : .changed
        if let path = result.path { paths[id] = path }
        if measureAfterCheck.remove(id) != nil, result.holds { measureIfDue(id) }
    }

    /// Measure a shot's window when its proof holds and it was not measured on this build, unless that is already
    /// running. Stored by id: a shot deleted meanwhile simply drops the result.
    private func measureIfDue(_ id: String) {
        let build = Self.currentBuild
        guard let own = shot(id: id), proof[id] == .holds, own.window?.build != build, !measuring.contains(id)
        else { return }
        measuring.insert(id)
        Task { [weak self] in
            let window = await Task.detached(priority: .utility) { OwnShotProof.measureWindow(own, build: build) }.value
            guard let self else { return }
            self.measuring.remove(id)
            guard let i = self.shots.firstIndex(where: { $0.id == id }) else { return }
            self.shots[i].window = window
            self.write()
        }
    }

    // MARK: The file

    /// Write the shelf (JSON, atomically). Not fatal on failure: the shots stay on the shelf for this run; logged so
    /// it is never silent.
    private func write() {
        guard let url = fileURL else { return }
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(OwnShotFile(format: Self.format, shots: shots)).write(to: url, options: .atomic)
        } catch {
            NSLog("OwnShotShelf: could not save the shots to %@: %@", url.path, error.localizedDescription)
        }
    }

    /// The saved shots: empty when there is no file (or no URL); nil when the file could not be read and could not be
    /// moved aside either (the shelf then runs from memory, so nothing overwrites it). An unreadable file, or one
    /// from a newer format, is moved to own-shots-unreadable.json. Shots whose table or surface this build does not
    /// know are kept and listed (never hidden), with a line saying this version cannot set them up.
    private static func load(from url: URL?) -> [OwnShot]? {
        guard let url, FileManager.default.fileExists(atPath: url.path) else { return [] }
        do {
            let file = try JSONDecoder().decode(OwnShotFile.self, from: Data(contentsOf: url))
            guard file.format <= Self.format else {
                return moveAside(url, reason: "format \(file.format) is newer than \(Self.format)") ? [] : nil
            }
            return file.shots
        } catch {
            return moveAside(url, reason: error.localizedDescription) ? [] : nil
        }
    }

    /// Move an unreadable shelf file aside (replacing an older unreadable copy). True when it was moved.
    private static func moveAside(_ url: URL, reason: String) -> Bool {
        let target = url.deletingLastPathComponent().appendingPathComponent("own-shots-unreadable.json")
        do {
            if FileManager.default.fileExists(atPath: target.path) { try FileManager.default.removeItem(at: target) }
            try FileManager.default.moveItem(at: url, to: target)
            NSLog("OwnShotShelf: the saved shots at %@ could not be read (%@) and were moved to %@", url.path, reason,
                  target.path)
            return true
        } catch {
            NSLog("OwnShotShelf: the saved shots at %@ could not be read (%@) or moved aside: %@", url.path, reason,
                  error.localizedDescription)
            return false
        }
    }
}
