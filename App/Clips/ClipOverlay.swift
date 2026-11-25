// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// Edited: Claude Opus 5.5 Medium, 25-November-2026 (0.7.9, the jump replay plan's "Next": the jump's side view in clips.
//          While the replay is on a jump (ClipFlight decides the frames and the fade, from the jump's own clock, not the
//          note's), the game's FlightSideView is drawn in its dark film style beside the flight, placed by
//          ClipFlight.place, under the ring and the note and under the end card. frameImage takes the frame's index
//          (optional; without it the overlay follows the frames in order, as ClipRenderer draws them).)
// PURPOSE: The words, the ring and the end card drawn onto each frame of a Lens clip (0.7.7,
//          plans/23-Nov-2026-clips-plan.md, Step 5). The 3D table is rendered by ClipRenderer; this lays over it, in
//          the film's pixels:
//            - while a moment is held, a small dark rounded note at the bottom of the frame (the caption band the
//              camera leaves free): the moment's title with its lead figure ("Throw · 2.1°") and its first sentence,
//              whole (up to five lines upright, four wide, drawn smaller rather than cut off), fading in as the hold
//              starts and out after it ends. Not glass: glass cannot be drawn into a video;
//            - a thin white ring on the ball the moment is about, the same ball the game rings (LeaderState's anchor:
//              the thrown ball for a Throw caption, else the faster ball of a hit, at its place at the held clock),
//              sized from the ball's size on screen, with a thin line down to the note when the ring is above it;
//            - the end card: the ground colour, the shot's name, the game's name and a short line half magenta, half
//              cyan (the Lens colours). No web address, no slogan;
//            - (0.7.9) while the replay is on a jump, the jump seen side on (FlightSideView, film style) beside the
//              flight, from the strike or take-off until the ball has landed, fading in and out (ClipFlight).
//          The note and the end card are SwiftUI views rendered once each with ImageRenderer at three pixels a point,
//          in the game's language and reading direction; the ring is drawn per frame into a small bitmap. Everything
//          is composed with Core Image on the GPU (ClipRenderer renders the result straight into the video's buffer).
//          Points are canvas points (ClipShape.canvas), origin top left, y down; Core Image counts pixels from the
//          bottom left, so every placement converts.
// SRP/DRY check: Pass - reuses LeaderState.anchor (the ring's ball), CameraFraming.project (the camera's own projection),
//          TableCamera.pointsPerMetre (the ball's size on screen), Theme fonts and the Palette colours; the words are
//          the captions' own, prepared by ClipScript. The side view is the game's own FlightSideView and FlightSketch
//          (never a copy), its frames and place ClipFlight's.
import BreakdownLensModel
import BreakdownTimeline
import CoreGraphics
import CoreImage
import Foundation
import SwiftUI
import simd

/// A held moment's note: title and lead figure, then the first sentence, white on a dark rounded card.
struct ClipCaptionView: View {
    let beat: ClipBeat
    let shape: ClipShape

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(verbatim: beat.title).font(Theme.heading).lineLimit(2)
                if let figure = beat.figure {
                    Text(verbatim: "·").font(Theme.heading).foregroundStyle(.white.opacity(0.6))
                    Text(verbatim: figure).font(Theme.blurbFigure).lineLimit(1).fixedSize()
                }
            }
            // The whole sentence: it shrinks to three quarters before it would ever be cut off.
            Text(verbatim: beat.sentence)
                .font(Theme.body)
                .lineLimit(shape.captionLines)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(.white)
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.black.opacity(0.62))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(.white.opacity(0.12)))
        }
    }
}

/// The quiet end card: the shot's name, the game's name, the Lens colours' line, on the ground colour.
struct ClipEndCardView: View {
    let title: String?
    let shape: ClipShape
    @Environment(\.palette) private var palette

    var body: some View {
        ZStack {
            palette.ground
            VStack(spacing: 10) {
                if let title {
                    Text(verbatim: title)
                        .font(Theme.heading)
                        .foregroundStyle(palette.paper.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                // The game's name, never translated.
                Text(verbatim: "Breakdown")
                    .font(Theme.display)
                    .foregroundStyle(palette.paper)
                HStack(spacing: 0) {
                    palette.slide.frame(width: 36, height: 3)
                    palette.accent.frame(width: 36, height: 3)
                }
                .clipShape(Capsule())
            }
            .padding(24)
        }
        .frame(width: shape.canvas.width, height: shape.canvas.height)
    }
}

@MainActor
final class ClipOverlay {
    private let shape: ClipShape
    private let title: String?
    /// The notes, rendered once per kept beat, and the end card, rendered once.
    private var captionImages: [Int: CIImage] = [:]
    private var endCardImage: CIImage?
    private let sRGB = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()

    /// What a script's side-view track is built from, cheap to compare on every frame: its length and its kept beats.
    /// (One overlay draws one script, so this only has to tell a new script from the last.)
    private struct TrackKey: Equatable {
        let frames: Int
        let events: [Int]
        let times: [Double]

        init(_ script: ClipScript) {
            frames = script.frames.count
            events = script.beats.map(\.beat.caption.id)
            times = script.beats.map(\.beat.time)
        }
    }

    /// What changes the side view's picture: the jump, the part in focus, the clock (in the jump's steps), which way it
    /// runs and the panel's size. Its place on the frame does not.
    private struct FlightPictureKey: Equatable {
        let story: FlightStoryKey
        let focus: FlightFocus
        let now: Double
        let leftward: Bool
        let width: CGFloat
        let height: CGFloat
    }

    /// The side view on every frame of the script being drawn (ClipFlight.track), built once per script.
    private var flightTrack: (key: TrackKey, cues: [ClipFlightCue?])?
    /// The index the next frame is expected at, when frameImage is not given one: ClipRenderer draws every frame once,
    /// in order.
    private var nextFrame = 0
    /// The last side view rendered. Only the last is kept: a hold repeats it frame after frame, and as the ball flies
    /// each frame needs a new one, so older pictures are never asked for again.
    private var flightPicture: (key: FlightPictureKey, image: CIImage?)?

    /// TableCamera's vertical field of view in degrees (TableCamera.fov, private there). The clip never rides, so the
    /// field of view never changes from it.
    nonisolated static let fovDegrees: Float = 45
    /// Space kept under the note, points.
    private static let noteMargin: CGFloat = 12

    init(shape: ClipShape, title: String?) {
        self.shape = shape
        self.title = title
    }

    // MARK: Projection

    /// Where a world point lands on the canvas (points, origin top left), with the camera at `eye` looking along
    /// `forward`; nil when the point is at or behind the eye (which CameraFraming.project does not guard against).
    nonisolated static func project(_ world: SIMD3<Float>, eye: SIMD3<Float>, forward: SIMD3<Float>,
                                    canvas: CGSize) -> CGPoint? {
        guard simd_dot(world - eye, forward) > 0.01 else { return nil }
        return CameraFraming.project(world, position: eye, target: eye + forward, size: canvas, fovDegrees: fovDegrees)
    }

    // MARK: Rendering the views

    /// The reading direction of the language the game is showing (Arabic reads right to left).
    private static var layoutDirection: LayoutDirection {
        let code = Bundle.main.preferredLocalizations.first ?? "en"
        return Locale.Language(identifier: code).characterDirection == .rightToLeft ? .rightToLeft : .leftToRight
    }

    /// A SwiftUI view as a Core Image image at the film's scale, in the game's palette, text size and direction.
    private func render<V: View>(_ view: V, proposedWidth: CGFloat?) -> CIImage? {
        let content = view
            .environment(\.palette, Palette(contrast: .standard))
            .environment(\.dynamicTypeSize, .large)
            .environment(\.colorScheme, .dark)
            .environment(\.layoutDirection, Self.layoutDirection)
        let renderer = ImageRenderer(content: content)
        renderer.scale = ClipShape.pixelsPerPoint
        renderer.proposedSize = ProposedViewSize(width: proposedWidth, height: nil)
        guard let cg = renderer.cgImage else { return nil }
        return CIImage(cgImage: cg)
    }

    private func captionImage(_ index: Int, script: ClipScript) -> CIImage? {
        if let cached = captionImages[index] { return cached }
        guard script.beats.indices.contains(index) else { return nil }
        let image = render(ClipCaptionView(beat: script.beats[index], shape: shape), proposedWidth: shape.captionMaxWidth)
        captionImages[index] = image
        return image
    }

    private func endCard() -> CIImage? {
        if let endCardImage { return endCardImage }
        let image = render(ClipEndCardView(title: title, shape: shape), proposedWidth: shape.canvas.width)
        endCardImage = image
        return image
    }

    // MARK: One frame

    /// The frame as the film shows it: the rendered table, then the jump's side view while the replay is on a jump,
    /// then (while a moment is held) the ring and its line, then the note, then the end card at its fade. All in
    /// pixels, origin bottom left. `index` is the frame's place in the script; without it the overlay takes the frames
    /// to come in order, once each, as ClipRenderer draws them.
    func frameImage(base: CIImage, frame f: ClipFrame, script: ClipScript, camera: TableCamera,
                    timeline: Timeline, index frameIndex: Int? = nil) -> CIImage {
        let scale = ClipShape.pixelsPerPoint
        let height = shape.pixelSize.height
        var image = base

        // The jump's side view. Its own block, not the note's: it stays up while the ball flies on after the hold,
        // when the note has gone (ClipFlight). Asked on every frame, so the overlay keeps step with the script.
        if let cue = flightCue(f, index: frameIndex, script: script, timeline: timeline),
           let panel = flightImage(cue, frame: f, camera: camera, timeline: timeline) {
            image = panel.composited(over: image)
        }

        // The note: centred across the caption band, centred in it when it fits, else resting on its bottom margin
        // and reaching up over the table.
        if let index = f.caption, f.captionOpacity > 0.001, let note = captionImage(index, script: script) {
            let w = note.extent.width / scale, h = note.extent.height / scale
            let band = shape.captionBand
            let top = h <= band.height - 2 * Self.noteMargin ? band.midY - h / 2 : band.maxY - Self.noteMargin - h
            let left = band.midX - w / 2
            // The ring and its line go under the note, so draw them first.
            if f.heldEvent != nil, script.beats.indices.contains(index),
               let ring = ringImage(script.beats[index].beat.caption, frame: f, camera: camera, timeline: timeline,
                                    noteTop: top, noteSpan: (left, left + w)) {
                image = ring.composited(over: image)
            }
            let placed = note
                .transformed(by: CGAffineTransform(translationX: left * scale - note.extent.minX,
                                                   y: height - (top + h) * scale - note.extent.minY))
            image = Self.fade(placed, opacity: f.captionOpacity).composited(over: image)
        }

        // The end card over everything, at its fade.
        if f.endCard > 0, let card = endCard() {
            let placed = card.transformed(by: CGAffineTransform(translationX: -card.extent.minX, y: -card.extent.minY))
            image = Self.fade(placed, opacity: f.endCard).composited(over: image)
        }
        return image.cropped(to: CGRect(origin: .zero, size: shape.pixelSize))
    }

    // MARK: The jump's side view

    /// The side view this frame carries (ClipFlight.track, built once per script), or nil.
    private func flightCue(_ f: ClipFrame, index: Int?, script: ClipScript, timeline: Timeline) -> ClipFlightCue? {
        let key = TrackKey(script)
        if flightTrack?.key != key {
            flightTrack = (key, ClipFlight.track(script: script, timeline: timeline))
            nextFrame = 0
        }
        guard let cues = flightTrack?.cues else { return nil }
        let frames = script.frames
        // The track is by frame index, and frames repeat exactly during a hold, so a frame cannot be found by its
        // value alone: follow the given index, else the expected next one, checked against the frame itself.
        var i = index ?? nextFrame
        if !(frames.indices.contains(i) && frames[i] == f) {
            // Out of step (ClipRenderer never is): the first frame like this one. Within a hold that may be an earlier
            // copy of it, which shows the same panel; the next moving frame brings the cursor back in step.
            guard let found = frames.firstIndex(of: f) else { return nil }
            i = found
        }
        nextFrame = i + 1
        return cues.indices.contains(i) ? cues[i] : nil
    }

    /// The side view for one frame, placed in film pixels and faded to the cue's opacity. Nil when the part in focus is
    /// behind the camera: nothing on screen to draw it beside.
    private func flightImage(_ cue: ClipFlightCue, frame f: ClipFrame, camera: TableCamera,
                             timeline: Timeline) -> CIImage? {
        // Cloth points lifted by a ball's radius, as the game lifts them (LeaderState.flightSketch), through the clip's
        // camera on the clip's canvas.
        let table = TableFrame(timeline.table)
        let lift = table.ballRadius
        let eye = camera.eye, forward = camera.forward, canvas = shape.canvas
        guard let sketch = FlightSketch.make(captionID: cue.captionID, shape: cue.shape, focus: cue.focus,
                                             clock: f.clock, project: { p in
            Self.project(table.world(p, height: lift), eye: eye, forward: forward, canvas: canvas)
        }) else { return nil }
        // Clear of the flying ball as well as of the stretch in focus: as the camera follows the ball on, the stretch
        // falls behind and the panel would otherwise sit on the ball's way.
        let now = cue.shape.ball(at: f.clock)
        var avoid: [CGRect] = []
        if let b = Self.project(table.world(now.cloth, height: Float(now.centre)), eye: eye, forward: forward,
                                canvas: canvas) {
            let r = CaptionLeader.ringRadius
            avoid.append(CGRect(x: b.x - r, y: b.y - r, width: 2 * r, height: 2 * r))
        }
        let rect = ClipFlight.place(flight: sketch.screen, in: shape, avoid: avoid)

        let key = FlightPictureKey(story: sketch.key, focus: sketch.focus, now: sketch.now, leftward: sketch.leftward,
                                   width: rect.width, height: rect.height)
        let picture: CIImage?
        if let cached = flightPicture, cached.key == key {
            picture = cached.image
        } else {
            // Laid out left to right whatever the language, as the game's panel is (CaptionLeader): the drawing is
            // placed in screen points and mirrored by the sketch itself when the jump runs right to left.
            let view = FlightSideView(sketch: sketch, accent: Palette(contrast: .standard).color(for: CaptionAccent.impact),
                                      size: rect.size, style: .film)
                .environment(\.layoutDirection, .leftToRight)
            picture = render(view, proposedWidth: rect.width)
            flightPicture = (key, picture)
        }
        guard let picture else { return nil }

        // Placed as the note is: centred on its rect, from the rendered image's own size, in pixels from the bottom left.
        let scale = ClipShape.pixelsPerPoint
        let w = picture.extent.width / scale, h = picture.extent.height / scale
        let left = rect.midX - w / 2, top = rect.midY - h / 2
        let placed = picture
            .transformed(by: CGAffineTransform(translationX: left * scale - picture.extent.minX,
                                               y: shape.pixelSize.height - (top + h) * scale - picture.extent.minY))
        return Self.fade(placed, opacity: cue.opacity)
    }

    /// An image with its alpha scaled (Core Image works on unpremultiplied colour here, so the colours stay right).
    private static func fade(_ image: CIImage, opacity: Double) -> CIImage {
        guard opacity < 0.999 else { return image }
        return image.applyingFilter("CIColorMatrix", parameters: [
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(max(0, opacity))),
        ])
    }

    /// The ring on the moment's ball and, when the ring sits above the note, a thin line from the ring down to the
    /// note's top edge. Drawn into a bitmap covering just their bounding box, placed in film pixels. Nil when the ball
    /// is behind the camera or off the canvas.
    private func ringImage(_ caption: Caption, frame f: ClipFrame, camera: TableCamera, timeline: Timeline,
                           noteTop: CGFloat, noteSpan: (minX: CGFloat, maxX: CGFloat)) -> CIImage? {
        guard let world = LeaderState.anchor(of: caption, timeline: timeline, time: f.clock),
              let p = Self.project(world, eye: camera.eye, forward: camera.forward, canvas: shape.canvas) else {
            return nil
        }
        let canvas = shape.canvas
        guard p.x > -20, p.y > -20, p.x < canvas.width + 20, p.y < canvas.height + 20 else { return nil }
        let ballRadius = TableFrame(timeline.table).ballRadius
        let radius = max(14, CGFloat(1.7 * ballRadius * camera.pointsPerMetre(at: world)))
        let line: CGFloat = 2
        // The line, only when the ring's bottom is above the note's top.
        let leaderFrom = CGPoint(x: p.x, y: p.y + radius)
        let leaderX = min(max(p.x, noteSpan.minX + 12), noteSpan.maxX - 12)
        let leader: (CGPoint, CGPoint)? = leaderFrom.y + 4 < noteTop
            ? (leaderFrom, CGPoint(x: leaderX, y: noteTop)) : nil

        // The bounding box in points, then in whole pixels.
        var box = CGRect(x: p.x - radius - line, y: p.y - radius - line, width: 2 * (radius + line),
                         height: 2 * (radius + line))
        if let leader {
            box = box.union(CGRect(x: min(leader.0.x, leader.1.x) - line, y: leader.0.y - line,
                                   width: abs(leader.1.x - leader.0.x) + 2 * line,
                                   height: leader.1.y - leader.0.y + 2 * line))
        }
        let scale = ClipShape.pixelsPerPoint
        let pixelBox = CGRect(x: box.minX * scale, y: box.minY * scale, width: box.width * scale,
                              height: box.height * scale).integral
        let w = Int(pixelBox.width), h = Int(pixelBox.height)
        guard w > 0, h > 0, w < 4096, h < 4096,
              let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: sRGB,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        // Draw in canvas points with y down, like the canvas: flip the bitmap's bottom-left space once.
        ctx.translateBy(x: 0, y: CGFloat(h))
        ctx.scaleBy(x: scale, y: -scale)
        ctx.translateBy(x: -pixelBox.minX / scale, y: -pixelBox.minY / scale)
        ctx.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.9))
        ctx.setLineWidth(line)
        ctx.strokeEllipse(in: CGRect(x: p.x - radius, y: p.y - radius, width: 2 * radius, height: 2 * radius))
        if let leader {
            ctx.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.6))
            ctx.move(to: leader.0)
            ctx.addLine(to: leader.1)
            ctx.strokePath()
        }
        guard let cg = ctx.makeImage() else { return nil }
        // Into film pixels: the bitmap's top edge is the box's top (pixelBox.minY from the top of the film).
        let filmHeight = shape.pixelSize.height
        let placed = CIImage(cgImage: cg)
            .transformed(by: CGAffineTransform(translationX: pixelBox.minX, y: filmHeight - pixelBox.maxY))
        return Self.fade(placed, opacity: f.captionOpacity)
    }
}
