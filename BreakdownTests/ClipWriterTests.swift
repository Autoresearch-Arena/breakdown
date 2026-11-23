// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Checks for writing a Lens clip's file (App/Clips/ClipWriter.swift, 0.7.7), with no 3D drawing at all: ten
//          solid-colour frames through ClipVideoWriter at the upright size, one second of a test tone through
//          ClipAudioWriter, then ClipMuxer with a shot record. The file must open with one video track of 1080 by
//          1920 and one audio track, last about a third of a second (the pictures' length), and give the same shot
//          record back from its metadata. The final file is a .mov: an .mp4 passthrough export dropped the record (0.7.7 test run), which was the plan's
//          fallback (see the plan's risks).
// SRP/DRY check: Pass - checks only.
@testable import Breakdown
import AVFoundation
import CoreImage
import XCTest

@MainActor
final class ClipWriterTests: XCTestCase {
    func testTenFramesAToneAndARecordMakeAPlayableClip() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ClipWriterTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let video = folder.appendingPathComponent("video.mp4")
        let audio = folder.appendingPathComponent("sound.m4a")
        let final = folder.appendingPathComponent("clip.mov")
        let size = ClipShape.upright.pixelSize

        // Ten solid-colour frames.
        let writer = try ClipVideoWriter(url: video, pixelSize: size)
        try writer.start()
        let context = CIContext()
        for i in 0..<10 {
            let shade = CGFloat(i) / 10
            let image = CIImage(color: CIColor(red: shade, green: 0.3, blue: 1 - shade))
                .cropped(to: CGRect(origin: .zero, size: size))
            let buffer = try writer.nextBuffer()
            context.render(image, to: buffer)
            try await writer.append(buffer, frame: i)
        }
        try await writer.finish()

        // One second of a quiet tone.
        let n = 44_100
        let tone = (0..<n).map { Float(0.2 * sin(2 * Double.pi * 440 * Double($0) / 44_100)) }
        try ClipAudioWriter.write(left: tone, right: tone, to: audio)

        // The final file, with the straight pot's record.
        let attempt = ClipShotRecordTests.attempt(RideDemo.straightPot(), timeline: TestShots.straightPot(),
                                                  isBreak: false)
        let record = ClipShotRecord(attempt: attempt)
        try await ClipMuxer.mux(video: video, audio: audio, record: record, to: final)

        let asset = AVURLAsset(url: final)
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        XCTAssertEqual(videoTracks.count, 1)
        XCTAssertEqual(audioTracks.count, 1)
        let natural = try await XCTUnwrap(videoTracks.first).load(.naturalSize)
        XCTAssertEqual(natural.width, 1080)
        XCTAssertEqual(natural.height, 1920)
        let duration = CMTimeGetSeconds(try await asset.load(.duration))
        XCTAssertEqual(duration, 1.0 / 3, accuracy: 0.05)
        let back = await ClipShotRecord.read(from: final)
        XCTAssertEqual(back, record, "the shot record did not survive the export")
    }
}
