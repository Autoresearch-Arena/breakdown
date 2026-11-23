// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Makes a Lens clip, start to finish, while the game keeps playing (0.7.7, plans/23-Nov-2026-clips-plan.md,
//          Step 8). One shared maker (ClipMaker.shared), observed by the clip card, the phone's clip blurb, the start
//          buttons (hidden while a clip is being made) and the controller.
//          The steps of one clip, after a tap on a start:
//            1. the script (ClipScript.make): a recording with no moment to hold makes no clip, and says so;
//            2. the pictures (ClipRenderer) into a temporary silent video, the progress bar following the frames;
//            3. off the main actor: the sound plan (ClipSound.plan), the voices (built once per launch), the mix and
//               the sound file (ClipAudioWriter); and the settings record's check (re-solved on a background task and
//               kept only when it moves exactly as the shot did);
//            4. the final file (ClipMuxer), named Breakdown-clip-yyyyMMdd-HHmmss.mov in the temporary Clips folder;
//            5. "Your clip is ready", with Share (the system's share sheet, ClipSharePresenter) and Close.
//          Cancel stops it at the next frame and deletes everything. A failure says so in one line, with Try again.
//          On iPhone and iPad, sending the game to the background stops a clip being made (the GPU may not draw there)
//          and says why; the Mac keeps going. VoiceOver hears "Making your clip" and "Your clip is ready".
//          Files: the Clips folder in the temporary directory is emptied the first time the maker is used after
//          launch; a closed clip's file is deleted at once unless the share sheet still has it open.
//          A stopped clip's task only notices at its next frame; a generation count makes sure that late task never
//          touches the card, the files or the task of a clip started after it.
// SRP/DRY check: Pass - orchestration only; each step lives in its own file in App/Clips. The words go through
//          String(localized:) for the catalog (localization/pending/v077-clips.json).
import Foundation
import Observation
import simd
#if canImport(UIKit)
import UIKit
#endif

/// A finished clip.
struct ClipResult: Equatable {
    let url: URL
    let shape: ClipShape
    let title: String?
    let duration: Double
}

/// Why a clip could not be made.
enum ClipFailure: Equatable {
    case leftScreen
    case couldNotMake

    /// The one line the card and blurb show.
    var sentence: String {
        switch self {
        case .leftScreen: return String(localized: "The clip stopped because the game left the screen.")
        case .couldNotMake: return String(localized: "The clip could not be made.")
        }
    }
}

@MainActor
@Observable
final class ClipMaker {
    static let shared = ClipMaker()

    enum Phase: Equatable {
        case idle
        case making(progress: Double)
        case ready(ClipResult)
        case failed(ClipFailure)
    }

    private(set) var phase: Phase = .idle
    /// True while a clip is being made (every start hides meanwhile).
    var isMaking: Bool { if case .making = phase { return true } else { return false } }
    /// True when nothing is up (the card and blurb show whenever this is false).
    var isIdle: Bool { phase == .idle }
    /// True while the system's share sheet has the clip open (its file is kept until it closes).
    private(set) var sharing = false

    @ObservationIgnored private var task: Task<Void, Never>?
    /// Counts clips started (and stopped), so a stopped clip's late task can tell it is no longer the current one.
    @ObservationIgnored private var generation = 0
    /// The last request, for Try again.
    @ObservationIgnored private var lastRequest: (source: ClipSource, shape: ClipShape)?
    @ObservationIgnored private var cleanedUp = false
    #if canImport(UIKit)
    @ObservationIgnored private var backgroundObserver: (any NSObjectProtocol)?
    #endif

    private init() {
        #if canImport(UIKit)
        // The GPU may not draw in the background: a clip being made stops, and says why.
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { ClipMaker.shared.leftScreen() }
        }
        #endif
    }

    // MARK: Files

    /// The temporary folder every clip is written in.
    private static var folder: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("Clips", isDirectory: true)
    }

    /// Empties the folder the first time the maker is used after launch (clips shared before the last quit).
    private func cleanUpOnce() {
        guard !cleanedUp else { return }
        cleanedUp = true
        try? FileManager.default.removeItem(at: Self.folder)
    }

    /// The final file's name: letters, digits and dashes only, digits always 0 to 9 whatever the device's region.
    private static func finalName(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyyMMdd-HHmmss"
        return "Breakdown-clip-" + f.string(from: date) + ".mov"
    }

    // MARK: Starting and stopping

    /// Makes a clip of `source` in `shape`. Ignored while one is being made; a ready or failed clip is closed first.
    func start(_ source: ClipSource, shape: ClipShape) {
        guard !isMaking else { return }
        if !isIdle { close() }
        cleanUpOnce()
        lastRequest = (source, shape)
        generation += 1
        // A recording with no moment to hold makes no clip; a tap never silently does nothing.
        guard let script = ClipScript.make(timeline: source.timeline, captions: source.captions,
                                           signature: source.signature) else {
            phase = .failed(.couldNotMake)
            return
        }
        phase = .making(progress: 0)
        ShotNarration.announce(String(localized: "Making your clip"))
        let mine = generation
        task = Task { [weak self] in
            await self?.make(source, shape: shape, script: script, generation: mine)
        }
    }

    /// Stops the clip being made: its task stops at the next frame and deletes its own files; nothing is left up.
    func cancel() {
        stopTask()
        phase = .idle
    }

    /// Puts the card or blurb away. A finished clip's file goes with it unless the share sheet still has it open
    /// (the next launch's clean-up removes that one).
    func close() {
        if isMaking { cancel(); return }
        if case .ready(let result) = phase, !sharing { try? FileManager.default.removeItem(at: result.url) }
        phase = .idle
    }

    /// Try again after a failure: the same shot, the same shape.
    func retry() {
        guard let last = lastRequest else { close(); return }
        phase = .idle
        start(last.source, shape: last.shape)
    }

    /// Opens the system's share sheet for a ready clip.
    func share() {
        guard case .ready(let result) = phase, !sharing else { return }
        sharing = true
        ClipSharePresenter.present(result.url) { [weak self] in self?.sharing = false }
    }

    /// The game went to the background (iPhone and iPad): a clip being made stops and says why.
    private func leftScreen() {
        guard isMaking else { return }
        stopTask()
        phase = .failed(.leftScreen)
    }

    /// Cancels the running task and retires its generation, so nothing it does afterwards reaches the maker.
    private func stopTask() {
        task?.cancel()
        task = nil
        generation += 1
    }

    /// True while `mine` is still the clip the maker is making.
    private func isCurrent(_ mine: Int) -> Bool { mine == generation }

    // MARK: Making one

    private func make(_ source: ClipSource, shape: ClipShape, script: ClipScript, generation mine: Int) async {
        try? FileManager.default.createDirectory(at: Self.folder, withIntermediateDirectories: true)
        let stamp = UUID().uuidString
        let videoURL = Self.folder.appendingPathComponent("video-\(stamp).mp4")
        let audioURL = Self.folder.appendingPathComponent("sound-\(stamp).m4a")
        let finalURL = Self.folder.appendingPathComponent(Self.finalName(Date()))
        // This clip's own files: deleted here whenever it does not finish, whoever stopped it.
        let files = [videoURL, audioURL, finalURL]
        do {
            // The pictures, on the main actor between frames (the game keeps playing).
            let renderer = ClipRenderer(source: source, shape: shape, script: script)
            let rights = try await renderer.renderVideo(to: videoURL) { p in
                if isCurrent(mine) { phase = .making(progress: p) }
            }
            try Task.checkCancellation()

            // The sound, off the main actor: only plain values cross.
            let bank = await ClipVoiceBank.bank()
            let frames = script.frames
            let timeline = source.timeline
            let surface = source.surface
            let duration = script.duration
            try await Task.detached(priority: .userInitiated) {
                let sounds = ClipSound.plan(frames: frames, timeline: timeline, surface: surface, rights: rights,
                                            variants: { voice, layer in
                                                let layers = bank.voices[voice] ?? []
                                                return layers.indices.contains(layer) ? layers[layer].count : 0
                                            },
                                            layers: { voice in bank.voices[voice]?.count ?? 0 })
                let mixed = ClipSound.mix(sounds, bank: bank, duration: duration)
                try ClipAudioWriter.write(left: mixed.left, right: mixed.right, to: audioURL)
            }.value
            try Task.checkCancellation()
            if isCurrent(mine) { phase = .making(progress: 0.95) }

            // The settings record, kept only when re-solving it moves exactly as the shot did.
            let record = await Self.checkedRecord(source)
            try Task.checkCancellation()

            // The final file.
            try await ClipMuxer.mux(video: videoURL, audio: audioURL, record: record, to: finalURL)
            try Task.checkCancellation()
            try? FileManager.default.removeItem(at: videoURL)
            try? FileManager.default.removeItem(at: audioURL)
            guard isCurrent(mine) else {
                try? FileManager.default.removeItem(at: finalURL)
                return
            }
            task = nil
            phase = .ready(ClipResult(url: finalURL, shape: shape, title: source.title, duration: duration))
            ShotNarration.announce(String(localized: "Your clip is ready"))
        } catch {
            for url in files { try? FileManager.default.removeItem(at: url) }
            // Cancelled or sent to the background: whoever stopped it has already set the phase and retired this
            // clip's generation. Any other error on the current clip says so in one line, with Try again.
            guard isCurrent(mine) else { return }
            task = nil
            phase = .failed(.couldNotMake)
        }
    }

    /// The candidate record when it re-solves to exactly the shot's motion, else nil (the clip then carries none).
    /// The solve runs on a background task (only the record and the recording cross); the fingerprint is the
    /// attempt's own (ShotAttempt.motionHash of the attempt with the re-solved recording put in).
    private static func checkedRecord(_ source: ClipSource) async -> ClipShotRecord? {
        guard let record = source.record, let want = source.motionHash, let attempt = source.attempt else { return nil }
        let solved = await Task.detached(priority: .utility) { record.solve() }.value
        guard let solved else { return nil }
        return attempt.resolved(on: solved, surface: attempt.surface).motionHash == want ? record : nil
    }
}
