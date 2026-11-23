// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// Edited: Claude Opus 5.5 High, 23-November-2026 (-clipShape picks the shape, for the App Store previews.)
// PURPOSE: The launch check for Lens clips (0.7.7, plans/23-Nov-2026-clips-plan.md, Step 10). Launched with
//          -clipSelfTest, the app makes an upright clip of the shot on screen at launch (the opening's break) through
//          the real maker, renderer, mixer and writer, then opens the finished file and logs one line:
//            CLIP-SELFTEST frames=<n> duration=<s> bytes=<n> tracks=<n> size=<w>x<h> -> PASS or FAIL
//          PASS needs one video track of 1080 by 1920, one audio track, and a duration within a frame or two of the
//          script's. Log only, no screenshots. It is the first run that shows the colour-format and upside-down risks
//          (see ClipRenderer), so the coordinator runs it once after the merge.
//          Hooked by ClipCard and ClipPhoneBlurb (one of them is mounted on every layout) through ClipSelfTestAnchor,
//          which adds its task only when the flag is set; the test runs once per launch whichever mounts first.
// SRP/DRY check: Pass - drives the real ClipMaker; nothing here makes a clip its own way.
import AVFoundation
import Foundation
import SwiftUI

@MainActor
enum ClipSelfTest {
    static let requested = ProcessInfo.processInfo.arguments.contains("-clipSelfTest")
    /// The shape to film: "-clipShape store" makes the App Store preview size, "-clipShape wide" the wide one.
    static var shape: ClipShape {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-clipShape"), i + 1 < args.count else { return .upright }
        switch args[i + 1] {
        case "store": return .storePreview
        case "wide": return .wide
        default: return .upright
        }
    }
    private static var started = false

    /// Makes the self-test clip once per launch, when the flag is set; logs the result.
    static func runIfAsked(_ model: ShowpieceModel) async {
        guard requested, !started else { return }
        started = true
        // Let the live table finish building first (its pictures are what the clip's table borrows).
        try? await Task.sleep(for: .seconds(2))
        let source = ClipSource(timeline: model.timeline, surface: model.physicsSurface, table: model.solvedTable,
                                title: nil)
        guard let script = ClipScript.make(timeline: source.timeline, captions: source.captions,
                                           signature: source.signature, replayBudget: shape.replayBudget) else {
            NSLog("CLIP-SELFTEST no moments to hold in the shot on screen -> FAIL")
            return
        }
        let maker = ClipMaker.shared
        maker.start(source, shape: shape)
        // Wait for the maker to finish (a clip renders in about its own length; allow ten times that).
        var waited = 0.0
        while maker.isMaking, waited < script.duration * 10 + 30 {
            try? await Task.sleep(for: .milliseconds(250))
            waited += 0.25
        }
        guard case .ready(let result) = maker.phase else {
            NSLog("CLIP-SELFTEST frames=%d the clip was not made (%@) -> FAIL", script.frames.count,
                  String(describing: maker.phase))
            return
        }
        let asset = AVURLAsset(url: result.url)
        let video = (try? await asset.loadTracks(withMediaType: .video)) ?? []
        let audio = (try? await asset.loadTracks(withMediaType: .audio)) ?? []
        var size = CGSize.zero
        if let track = video.first, let natural = try? await track.load(.naturalSize) { size = natural }
        let duration = (try? await asset.load(.duration)).map { CMTimeGetSeconds($0) } ?? 0
        let bytes = ((try? FileManager.default.attributesOfItem(atPath: result.url.path)[.size]) as? NSNumber)?
            .int64Value ?? 0
        let pass = video.count == 1 && audio.count == 1 && Int(size.width) == Int(shape.pixelSize.width)
            && Int(size.height) == Int(shape.pixelSize.height)
            && abs(duration - script.duration) < 0.1
        NSLog("CLIP-SELFTEST frames=%d duration=%.2f bytes=%lld tracks=%d size=%dx%d -> %@", script.frames.count,
              duration, bytes, video.count + audio.count, Int(size.width), Int(size.height), pass ? "PASS" : "FAIL")
        // Keep a copy in Caches before close() deletes the clip, so the coordinator can look at its pictures (upside
        // down, too dark) without a device: <app data>/Library/Caches/clip-selftest.mov.
        if let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let copy = caches.appendingPathComponent("clip-selftest.mov")
            try? FileManager.default.removeItem(at: copy)
            try? FileManager.default.copyItem(at: result.url, to: copy)
        }
        maker.close()
    }
}

/// Adds the self-test's task to a view only when -clipSelfTest is set (ClipCard and ClipPhoneBlurb wear it).
struct ClipSelfTestHook: ViewModifier {
    let model: ShowpieceModel

    func body(content: Content) -> some View {
        if ClipSelfTest.requested {
            content.task { await ClipSelfTest.runIfAsked(model) }
        } else {
            content
        }
    }
}

/// A one-point, invisible view that carries the self-test hook, so the hook sits on something that actually appears.
struct ClipSelfTestAnchor: View {
    let model: ShowpieceModel

    var body: some View {
        Color.clear.frame(width: 1, height: 1)
            .accessibilityHidden(true)
            .modifier(ClipSelfTestHook(model: model))
    }
}
