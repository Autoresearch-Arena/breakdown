// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Writing a Lens clip's file (0.7.7, plans/23-Nov-2026-clips-plan.md, Step 7), in three small pieces:
//          - ClipVideoWriter: the pictures. H.264 High profile, about 6 megabits a second, a key frame every 30 frames,
//            standard high-definition colour, 30 frames a second, at the clip's pixel size, into an .mp4 file with no
//            sound. It hands out Metal-compatible pixel buffers from its own pool (ClipRenderer has Core Image draw
//            each composed frame straight into one on the GPU) and appends them one by one, waiting politely (5 ms
//            sleeps, never a busy loop) whenever the encoder is not ready.
//          - ClipAudioWriter: the sound. The mixed stereo samples (ClipSound.mix) as AAC, 44.1 kHz stereo, 128
//            kilobits, into an .m4a file, in chunks. Runs off the main actor.
//          - ClipMuxer: the final file. The pictures and the sound put side by side in one composition and exported
//            with the passthrough preset (nothing is encoded twice), with the shot's settings record as metadata.
//          Why two passes rather than one writer with a video and an audio input: an asset writer whose inputs are not
//          real time waits for them to interleave, and the sound cannot be written before the pictures (its pan needs
//          each frame's camera, which only exists once the frame is drawn).
//          Used by ClipMaker (and checked by ClipWriterTests without any 3D drawing).
// SRP/DRY check: Pass - the only code in the app that writes video or audio files; nothing here decides what is in the
//          clip.
import AVFoundation
import CoreImage
import CoreMedia
import CoreVideo
import Foundation

enum ClipWriterError: Error {
    case noPixelBufferPool
    case couldNotCreateBuffer
    case writerFailed(Error?)
    case audioFormat
    case missingTrack
    case exportUnavailable
}

/// The pictures of a clip, one frame at a time.
@MainActor
final class ClipVideoWriter {
    let url: URL
    let pixelSize: CGSize
    private let writer: AVAssetWriter
    private let input: AVAssetWriterInput
    private let adaptor: AVAssetWriterInputPixelBufferAdaptor

    init(url: URL, pixelSize: CGSize) throws {
        self.url = url
        self.pixelSize = pixelSize
        try? FileManager.default.removeItem(at: url)
        writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let width = Int(pixelSize.width), height = Int(pixelSize.height)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 6_000_000,
                AVVideoMaxKeyFrameIntervalKey: 30,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoExpectedSourceFrameRateKey: 30,
            ] as [String: Any],
            // Standard high-definition colour (Rec. 709), which every phone, computer and site plays as intended.
            AVVideoColorPropertiesKey: [
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2,
            ] as [String: Any],
        ]
        input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false
        // Buffers Core Image can render into on the GPU: 32-bit BGRA, Metal-compatible, backed by IOSurface.
        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [String: Any](),
        ]
        adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: attributes)
        guard writer.canAdd(input) else { throw ClipWriterError.writerFailed(writer.error) }
        writer.add(input)
    }

    /// Starts the file. The adaptor's buffer pool exists only after both of these have run.
    func start() throws {
        guard writer.startWriting() else { throw ClipWriterError.writerFailed(writer.error) }
        writer.startSession(atSourceTime: .zero)
    }

    /// An empty buffer from the writer's pool, for the next frame.
    func nextBuffer() throws -> CVPixelBuffer {
        guard let pool = adaptor.pixelBufferPool else { throw ClipWriterError.noPixelBufferPool }
        var buffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &buffer)
        guard status == kCVReturnSuccess, let buffer else { throw ClipWriterError.couldNotCreateBuffer }
        return buffer
    }

    /// Appends frame `frame` (at frame / 30 s), waiting while the encoder is busy. Throws the writer's own error if
    /// it has failed, and stops waiting when the task is cancelled.
    func append(_ buffer: CVPixelBuffer, frame: Int) async throws {
        while !input.isReadyForMoreMediaData {
            if writer.status == .failed { throw ClipWriterError.writerFailed(writer.error) }
            try Task.checkCancellation()
            try await Task.sleep(for: .milliseconds(5))
        }
        let time = CMTime(value: CMTimeValue(frame), timescale: 30)
        guard adaptor.append(buffer, withPresentationTime: time) else {
            throw ClipWriterError.writerFailed(writer.error)
        }
    }

    /// Closes the file once every frame is in.
    func finish() async throws {
        input.markAsFinished()
        // The completion-handler form, wrapped: the writer stays on the main actor (it is not Sendable), and only the
        // continuation crosses into the handler.
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            writer.finishWriting { done.resume() }
        }
        if writer.status != .completed { throw ClipWriterError.writerFailed(writer.error) }
    }

    /// Abandons the file and deletes it.
    func cancel() {
        if writer.status == .writing { writer.cancelWriting() }
        try? FileManager.default.removeItem(at: url)
    }
}

/// The sound of a clip, written once the whole mix is known.
enum ClipAudioWriter {
    static let sampleRate = 44_100.0
    /// Frames per chunk written to the file.
    static let chunk = 32_768

    /// Writes the two channels (equal length) as AAC stereo into `url` (an .m4a file).
    static func write(left: [Float], right: [Float], to url: URL) throws {
        try? FileManager.default.removeItem(at: url)
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 128_000,
        ]
        let file = try AVAudioFile(forWriting: url, settings: settings, commonFormat: .pcmFormatFloat32,
                                   interleaved: false)
        let format = file.processingFormat
        guard format.channelCount == 2,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(chunk)) else {
            throw ClipWriterError.audioFormat
        }
        let count = min(left.count, right.count)
        var start = 0
        while start < count {
            let n = min(chunk, count - start)
            guard let channels = buffer.floatChannelData else { throw ClipWriterError.audioFormat }
            for i in 0..<n {
                channels[0][i] = left[start + i]
                channels[1][i] = right[start + i]
            }
            buffer.frameLength = AVAudioFrameCount(n)
            try file.write(from: buffer)
            start += n
        }
    }
}

/// The final file: pictures and sound side by side, plus the settings record.
enum ClipMuxer {
    /// Puts `video` (pictures only) and `audio` (sound only) into one .mp4 at `url`, over the video's duration, with
    /// the shot's settings record (when there is one) as metadata. Passthrough: nothing is encoded again. The record
    /// crosses in as a plain value and its metadata item is made here, so nothing that is not Sendable leaves the
    /// caller's actor.
    static func mux(video: URL, audio: URL, record: ClipShotRecord?, to url: URL) async throws {
        try? FileManager.default.removeItem(at: url)
        let videoAsset = AVURLAsset(url: video)
        let audioAsset = AVURLAsset(url: audio)
        let composition = AVMutableComposition()
        guard let videoSource = try await videoAsset.loadTracks(withMediaType: .video).first,
              let videoTrack = composition.addMutableTrack(withMediaType: .video,
                                                           preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw ClipWriterError.missingTrack
        }
        let length = try await videoAsset.load(.duration)
        let range = CMTimeRange(start: .zero, duration: length)
        try videoTrack.insertTimeRange(range, of: videoSource, at: .zero)
        // Keep the pictures' own colour description and orientation.
        videoTrack.preferredTransform = try await videoSource.load(.preferredTransform)
        if let audioSource = try await audioAsset.loadTracks(withMediaType: .audio).first,
           let audioTrack = composition.addMutableTrack(withMediaType: .audio,
                                                        preferredTrackID: kCMPersistentTrackID_Invalid) {
            // The sound is as long as the pictures (ClipSound.mix stops there); never run past them.
            let audioLength = try await audioAsset.load(.duration)
            let audioRange = CMTimeRange(start: .zero, duration: CMTimeMinimum(length, audioLength))
            try audioTrack.insertTimeRange(audioRange, of: audioSource, at: .zero)
        }
        guard let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
            throw ClipWriterError.exportUnavailable
        }
        session.metadata = record?.metadataItem().map { [$0] } ?? []
        session.shouldOptimizeForNetworkUse = true
        try await session.export(to: url, as: .mp4)
    }
}
