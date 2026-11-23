// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 coordinator: what steps aside for the what-if now also steps
//          aside for the every-surface fan, through model.otherFutureShowing.)
// PURPOSE: The live achievements object the model owns (plans/23-Nov-2026-achievements-plan.md, new file 6). It:
//          - hears who struck each stroke (strikeStarted, from ShowpieceModel.strike) and reads every shot the player
//            struck, in any mode (noteShot, from finishStrike): the shot achievements, the table and surface played,
//            and free play's run of the rack. Shots the game plays for the player (a trick's or lesson's answer, a hint,
//            the computer's turn) never count;
//          - sweeps the progress the game already keeps (lessons, trick shots, medals, wins against the computer, tables,
//            surfaces) whenever it changes, keeping the player's own shot on screen as the replay of a collection it
//            finished. The first launch of 0.7.7 earns a returning player's old progress quietly, dated that day;
//          - owns the small note that says one was earned and the end note after its replay (the views only draw what
//            it says is showing): it waits for calm (balls at rest, the clock at the end, no held beat, nothing being
//            placed, no what-if, the computer not lining up, the menu closed, the opening over), shows one at a time for
//            four seconds of calm, fades, and speaks its line to VoiceOver once. No sound, no vibration, nothing to
//            dismiss. Anything earned during the first-launch opening is kept quietly, already seen;
//          - saves the record (AchievementRecord) only when something changed, and solves the kept shots again off the
//            main thread for the list's drawings and for "Watch it in the Lens".
//          Nothing happens under a test launch (the store scenes and every scripted-strike flag): no earning, no note, no
//          save. Made on first use by ShowpieceModel.achievements (the trickMode pattern); read by AchievementViews and
//          TitleScreen's menu row.
// SRP/DRY check: Pass - checked HighlightOffer and ShowpieceModel's highlight card (an offer to replay one shot, not a
//          record of things done), TrickPathCache (the off-main-thread solve-then-draw pattern, followed), ShotNarration
//          (VoiceOver lines, reused) and the modes' own progress (read through their public accessors, never written).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import Foundation
import Observation

@MainActor
@Observable
final class AchievementBook {
    /// The model this book reads. The model owns the book, so this does not keep the model alive.
    @ObservationIgnored unowned let model: ShowpieceModel
    /// Where the record is saved: .standard in the app, a throwaway suite in tests.
    @ObservationIgnored let defaults: UserDefaults
    /// True in the app. Tests pass false, so no sweep ever reads the machine's own lesson, trick or medal lists.
    @ObservationIgnored let readsProgress: Bool

    /// The save, as loaded and as changed since.
    private(set) var record: AchievementRecord
    /// Ids earned and waiting for their note, oldest first.
    private(set) var toasts: [String] = []
    /// The note on screen (an id), and the end note after an achievement's replay (an id). Stored and written only
    /// when they change, so no view re-renders every frame.
    private(set) var shownToast: String?
    private(set) var shownReplayEnd: String?
    /// The list's small drawings by achievement id, filled in as each kept shot is solved again.
    private(set) var drawings: [String: TrickPath] = [:]
    /// Ids whose kept shot could not be drawn (an unknown table or surface): their rows keep no blank room.
    private(set) var drawingFailed: Set<String> = []
    /// Ids whose kept shot, solved again, no longer plays out as it was recorded (the physics changed since).
    private(set) var changedPhysics: Set<String> = []
    /// Bumped by the end note's button: ShowpieceView turns each bump into the Achievements page.
    private(set) var pageRequests = 0

    /// Free play's run of the rack (not saved: a run is one sitting's).
    @ObservationIgnored var run = RunTracker()
    /// Who struck the stroke being solved: the player (true) or the game (the computer, a demonstration, a hint).
    @ObservationIgnored var strikeByPerson = true
    /// The player's last shot as a recipe, its drawing, and the recording version it was loaded as: kept as the replay
    /// of a collection only while that very recording is the one on screen.
    @ObservationIgnored var lastPersonShot: (shot: AchievementShot, version: Int)?
    @ObservationIgnored private var lastPersonDrawing: TrickPath?
    /// The model's progress fingerprint (ShowpieceModel.achievementStamp) as last seen.
    @ObservationIgnored var stamp: [Int] = []
    /// Seconds of calm the note on screen has had.
    @ObservationIgnored var toastClock = 0.0
    @ObservationIgnored var drawingsStarted = false
    /// The note last spoken to VoiceOver, and the replay whose end note was spoken, so neither is said twice when calm
    /// comes and goes.
    @ObservationIgnored private var announcedToast: String?
    @ObservationIgnored private var announcedReplayVersion: Int?

    /// Calm seconds each note stays.
    static let toastSeconds = 4.0
    /// The most one frame may add to the note's clock (a long stall must not skip a note unseen).
    static let toastFrameLimit = 0.25

    /// The launch flags that strike without a person: the store scenes and every scripted-strike test flag. Under any
    /// of them nothing is earned, shown or saved (-rackShoot, for the store video, above all). Not the model's
    /// strokeDue: a calm keyboard or controller stroke does not set it, and real shots would stop earning.
    /// Nonisolated (plain Sendable values), so the tests and the flag below can read them from anywhere.
    nonisolated static let scriptedFlags = ["-retryCases", "-retryDemo", "-yourBreakDemo", "-yourShotDemo", "-aimDemo",
                                            "-aimDemoRack", "-rackShoot", "-aimScript", "-jumpDemo", "-rideDemo",
                                            "-eightPlay", "-eightJudgeCheck"]

    /// False under a test launch. Read once.
    nonisolated static let enabled: Bool = {
        guard StoreScene.requested == nil else { return false }
        let args = ProcessInfo.processInfo.arguments
        return !scriptedFlags.contains { args.contains($0) }
    }()

    init(model: ShowpieceModel, defaults: UserDefaults = .standard, readsProgress: Bool = true) {
        self.model = model
        self.defaults = defaults
        self.readsProgress = readsProgress
        record = AchievementRecord.load(from: defaults)
        guard Self.enabled, readsProgress else { return }
        // The first sweep waits a turn: the book is often made while a view reads the menu's mark, and nothing may
        // change during a view update. On the first launch of 0.7.7 it is quiet: a returning player's lessons, tricks,
        // medals and wins are earned at once, with no notes, dated today and marked new.
        Task { @MainActor [weak self] in
            guard let self else { return }
            let first = !self.record.seeded
            self.sweep(quiet: first)
            if first {
                self.record.seeded = true
                self.record.save(to: self.defaults)
            }
        }
    }

    // MARK: Strokes

    /// Called first thing in ShowpieceModel.strike: whose stroke this is. Captured there, because free play and
    /// matches solve on a background task and the computer's flag is cleared before the shot lands.
    func strikeStarted(byPerson: Bool) {
        strikeByPerson = byPerson
    }

    /// Read one shot the model has just put on screen (finishStrike, every mode). `version` is the recording's
    /// timelineVersion; `quiet` (the first-launch opening) earns without a note.
    func noteShot(_ c: AchievementShotContext, version: Int, quiet: Bool) {
        guard Self.enabled, strikeByPerson else { return }
        let found = AchievementJudge.shotAchievements(c)
        // The shot's own recipe, holding its first detected moment: the replay a collection it finishes keeps.
        let firstSignature = found.first?.signature ?? []
        guard let base = AchievementShot(attempt: c.attempt, signature: firstSignature) else { return }
        let drawing = TrickPath.traced(c.timeline, start: c.attempt.start, striker: c.attempt.cueBall)
        lastPersonShot = (base, version)
        lastPersonDrawing = drawing
        var changed = record.notePlayed(table: c.attempt.table.rawValue, surface: c.attempt.surface.rawValue)

        var earnedNow = found
        // Free play's run of the rack: object balls that dropped, a scratch, and object balls still on the table.
        let facts = c.facts
        let left = facts.resting.indices.filter { $0 != facts.cueBall && ShotFacts.isOnTable(facts.resting[$0]) }.count
        if run.note(isBreak: c.isBreak, poolRack: c.freePlay && c.table == .standard,
                    dropped: facts.objectBallsPocketed.count, scratched: facts.cueBallScratched, objectBallsLeft: left) {
            earnedNow.append((id: "run-rack", signature: firstSignature))
        }
        for f in earnedNow where earn(f.id, shot: base.with(signature: f.signature), quiet: quiet) {
            changed = true
            if let drawing { drawings[f.id] = drawing }
        }
        if changed { record.save(to: defaults) }
        // A lesson passed or a trick made by this very shot may already be counted; the frame's stamp catches the rest.
        if readsProgress, record.seeded { sweep(quiet: quiet) }
    }

    // MARK: Collections

    /// The progress the game keeps, gathered. Without readsProgress (tests) only the record's own tables and surfaces.
    func currentProgress() -> AchievementProgress {
        var p = AchievementProgress()
        p.tablesPlayed = Set(record.tablesPlayed)
        p.surfacesPlayed = Set(record.surfacesPlayed)
        guard readsProgress else { return p }
        // The public accessors: ShowpieceView already builds all three modes at launch, so this makes nothing new.
        p.lessonsDone = model.lessonMode.doneIDs
        p.tricksDone = model.trickMode.doneIDs
        p.escapesWon = Set(model.eightBallMode.medals.keys)
        let matches = MatchRecord.load(from: defaults)
        p.levelsBeaten = Set(ComputerLevel.allCases.filter { matches.tally($0).won > 0 }.map(\.rawValue))
        return p
    }

    /// Earn every collection the progress has finished and is not yet earned. The player's own shot is kept as its
    /// replay only when it is the recording on screen (the lesson's passing shot, the trick's make, a game's winning
    /// pot); otherwise the collection keeps no shot and its page shows its progress picture.
    func sweep(quiet: Bool) {
        guard Self.enabled else { return }
        let done = AchievementProgress.earned(currentProgress())
        let onScreen = lastPersonShot.flatMap { $0.version == model.timelineVersion ? $0.shot : nil }
        var changed = false
        for a in Achievements.all where done.contains(a.id) && earn(a.id, shot: onScreen, quiet: quiet) {
            changed = true
            if onScreen != nil, let drawing = lastPersonDrawing { drawings[a.id] = drawing }
        }
        if changed { record.save(to: defaults) }
    }

    /// Write one achievement into the record. Earned during the first-launch opening it is already seen (the first
    /// menu a new player sees carries no "new" sign); the first launch's quiet sweep of old progress stays new. Unless
    /// quiet, it waits for its note.
    @discardableResult
    private func earn(_ id: String, shot: AchievementShot?, quiet: Bool) -> Bool {
        let seen = quiet && model.openingStage != .none
        guard record.earn(id, on: Date(), shot: shot, seen: seen) else { return false }
        if !quiet { toasts.append(id) }
        return true
    }

    // MARK: Every frame

    /// Every frame from ShowpieceModel.advance (never behind the menu: advance returns before it). Sweeps when the
    /// progress fingerprint moves, and decides which note shows.
    func frame(_ rawDt: Double) {
        guard Self.enabled else { return }
        let s = model.achievementStamp
        if s != stamp {
            stamp = s
            // Not before the first quiet sweep has run, or a first launch's old progress would come with notes.
            if readsProgress, record.seeded { sweep(quiet: model.openingStage != .none) }
        }

        // Calm: the balls at rest and the clock at the shot's end (aimReady, which also means no replay is playing and
        // nothing is solving), no held beat, nothing being placed, no what-if, the computer not lining up, the menu
        // closed, the opening over. Not "not guided": a finished Lens replay stays guided until something else loads.
        let calm = model.openingStage == .none && !model.menuOpen && model.aimReady && !model.holding
            && !model.placingCueBall && !model.otherFutureShowing && model.computerTurnStage == .none

        // The end note after an achievement's replay, while that replay's recording is on screen.
        var replayEnd: String?
        if calm, let id = model.achievementReplayID, let v = model.achievementReplayVersion, v == model.timelineVersion {
            replayEnd = id
        }
        if replayEnd != shownReplayEnd {
            shownReplayEnd = replayEnd
            if let id = replayEnd, announcedReplayVersion != model.achievementReplayVersion,
               let a = Achievements.achievement(id: id) {
                announcedReplayVersion = model.achievementReplayVersion
                ShotNarration.announce(AchievementWords.replayEnded(name: a.name))
            }
        }

        // The note, one at a time, only while no end note shows. Out of calm it hides and its clock waits, so the same
        // note comes back and finishes its time, without being spoken again.
        guard shownReplayEnd == nil, calm, let next = toasts.first else {
            if shownToast != nil { shownToast = nil }
            return
        }
        if shownToast != next {
            shownToast = next
            if announcedToast != next {
                announcedToast = next
                toastClock = 0
                if let a = Achievements.achievement(id: next) {
                    ShotNarration.announce(AchievementWords.toastSpoken(name: a.name))
                }
            }
        }
        toastClock += min(max(rawDt, 0), Self.toastFrameLimit)
        if toastClock >= Self.toastSeconds {
            // Gone; the next one shows on a later frame.
            toasts.removeFirst()
            shownToast = nil
            toastClock = 0
        }
    }

    // MARK: The list

    /// The end note's "Achievements": the menu opens first (the list is reached from the menu, which stays open behind
    /// it as it does behind Tables), then ShowpieceView opens the page.
    func openList() {
        model.openMenu()
        pageRequests += 1
    }

    /// The list has opened: count anything just finished (a game won just before the menu opened), return the ids that
    /// were new, then mark everything seen and save. The list keeps the returned ids for this visit, so their dots show
    /// now and go next time. Starts the drawings.
    func listOpened() -> Set<String> {
        if Self.enabled, readsProgress, record.seeded { sweep(quiet: true) }
        let fresh = Set(record.earned.filter { !$0.value.seen }.keys)
        if Self.enabled, record.markAllSeen() { record.save(to: defaults) }
        startDrawings()
        return fresh
    }

    /// Solve every kept shot without a drawing yet, one after another off the main thread (the TrickPathCache
    /// pattern), the first time only; rows fill in as each arrives. Each solve also says whether the shot still plays
    /// out as it was recorded.
    func startDrawings() {
        guard !drawingsStarted else { return }
        drawingsStarted = true
        var jobs: [(id: String, shot: AchievementShot)] = []
        for a in Achievements.all where drawings[a.id] == nil {
            if let shot = record.earned[a.id]?.shot { jobs.append((id: a.id, shot: shot)) }
        }
        guard !jobs.isEmpty else { return }
        let work = jobs
        Task { [weak self] in
            for job in work {
                let shot = job.shot
                // Only Sendable values cross back: the drawing and the match flag, never the attempt.
                let result = await Task.detached(priority: .utility) { () -> (path: TrickPath?, same: Bool)? in
                    guard let tl = shot.solvedTimeline(), let attempt = shot.attempt(with: tl) else { return nil }
                    return (TrickPath.traced(tl, start: shot.start, striker: shot.ballIndex),
                            attempt.motionHash == shot.motionHash)
                }.value
                guard let self else { return }
                if let path = result?.path { self.drawings[job.id] = path } else { self.drawingFailed.insert(job.id) }
                if let same = result?.same, !same { self.changedPhysics.insert(job.id) }
            }
        }
    }

    /// True while a row's drawing is still being solved (it keeps its room meanwhile).
    func drawingPending(_ id: String) -> Bool {
        record.earned[id]?.shot != nil && drawings[id] == nil && !drawingFailed.contains(id)
    }

    // MARK: Counts

    var total: Int { Achievements.all.count }
    var earnedCount: Int { Achievements.all.filter { record.earned[$0.id] != nil }.count }
    var newCount: Int { Achievements.all.filter { record.earned[$0.id]?.seen == false }.count }

    func earned(_ id: String) -> AchievementRecord.Earned? { record.earned[id] }

    /// "4 of 6" for a collection's row: nil for a single thing (a shot, one lesson, one trick) and for a level, which is
    /// beaten or not.
    func progress(of a: Achievement, in p: AchievementProgress) -> (done: Int, total: Int)? {
        switch a.progress {
        case .none, .levels: return nil
        case .lessons, .tricks, .escapes, .tables, .surfaces: return p.count(a.progress)
        }
    }

    // MARK: Replaying a kept shot

    /// The kept shot solved again, ready for ShowpieceModel.watchAchievementShot: the attempt, the events to hold
    /// (the stored ones when the recording matches; when the physics changed, the same achievement read again from the
    /// new recording, with the captions ShowpieceModel.load will make, so the indices agree; else none) and whether it
    /// matched. The solve runs off the main thread; only its Timeline comes back.
    func replayShot(_ id: String) async -> (attempt: ShotAttempt, signature: [Int], sameAsEarned: Bool)? {
        guard let shot = record.earned[id]?.shot else { return nil }
        let solved = await Task.detached(priority: .userInitiated) { shot.solvedTimeline() }.value
        guard let tl = solved, let attempt = shot.attempt(with: tl) else { return nil }
        if attempt.motionHash == shot.motionHash { return (attempt, shot.signature, true) }
        changedPhysics.insert(id)
        let input = shot.input()
        let facts = ShotFacts(timeline: tl, start: shot.start, cueBall: shot.ballIndex)
        let captions = CaptionEngine.make(from: tl, surface: attempt.surface, strike: input.strike, table: attempt.table,
                                          striker: shot.ballIndex)
        let context = AchievementShotContext(timeline: tl, facts: facts, captions: captions, table: attempt.table,
                                             isBreak: shot.isBreak, freePlay: false, attempt: attempt)
        let found = AchievementJudge.shotAchievements(context)
        // A shot achievement holds its own moment; a collection holds the shot's first one, as when it was kept.
        let own = found.first { $0.id == id } ?? (Achievements.shotIDs.contains(id) ? nil : found.first)
        return (attempt, own?.signature ?? [], false)
    }
}
