// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// Edited: Claude Opus 5.5 High, 23-November-2026 (App Store previews: a third shape, storePreview, 886 by 1920, the
//          size the store takes for current iPhones, with a shorter replay so the film stays under the store's 30 s.)
// PURPOSE: The two shapes a Lens clip comes in (0.7.7, plans/23-Nov-2026-clips-plan.md, Step 3): upright (1080 by 1920
//          pixels, for a phone's photo library and the social apps that show video upright) and wide (1920 by 1080).
//          Each shape also says how the table is framed inside it: the clip's scene is laid out on a canvas in points
//          at three pixels a point (upright 360 by 640, wide 640 by 360), so the Lens drawings' size floors, which are
//          in screen points (LensMarkFloor), come out as large as on a phone; and a band at the bottom is kept for the
//          words, which the camera's framing request leaves free (header and controls edges), exactly as the game's
//          own camera frames the table between its title row and its controls.
//          Read by ClipRenderer (pixel size, framing request), ClipOverlay (canvas, caption band, line limit), ClipMaker
//          and the start buttons (standard and other shape).
// SRP/DRY check: Pass - checked CameraFraming (FramingRequest and FramingInsets are reused, not copied); no other file
//          knows about video sizes.
import CoreGraphics
import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum ClipShape: Equatable, Sendable {
    /// storePreview: the App Store's preview size for current iPhones (886 by 1920), upright, only ever made by the
    /// self-test launch (-clipShape store) for the store page; players get upright or wide.
    case upright, wide, storePreview

    /// The film's size in pixels.
    var pixelSize: CGSize {
        switch self {
        case .upright: return CGSize(width: 1080, height: 1920)
        case .wide: return CGSize(width: 1920, height: 1080)
        case .storePreview: return CGSize(width: 886, height: 1920)
        }
    }

    /// Seconds the explained replay may take. The store's previews must be 30 s at most, so its replay is shorter.
    var replayBudget: Double {
        self == .storePreview ? 16 : ClipScript.replayBudget
    }

    /// Pixels per canvas point: the canvas is a phone-sized screen drawn at a phone's own scale.
    static let pixelsPerPoint: CGFloat = 3

    /// The canvas the scene and the words are laid out on, in points (pixelSize / pixelsPerPoint).
    var canvas: CGSize {
        CGSize(width: pixelSize.width / Self.pixelsPerPoint, height: pixelSize.height / Self.pixelsPerPoint)
    }

    /// Where the camera may put the table: no safe-area insets (a film has none), a thin top margin (the "title row"
    /// edge), and the controls edge at the top of the caption band, so the table is framed above the words.
    var framingRequest: FramingRequest {
        switch self {
        case .upright:
            return FramingRequest(size: canvas, safe: FramingInsets(), headerBottom: 24, controlsTop: 490)
        case .wide:
            return FramingRequest(size: canvas, safe: FramingInsets(), headerBottom: 16, controlsTop: 264)
        case .storePreview:
            return FramingRequest(size: canvas, safe: FramingInsets(), headerBottom: 24, controlsTop: 490)
        }
    }

    /// The band the words sit in, in canvas points (origin top left): everything below the controls edge.
    var captionBand: CGRect {
        switch self {
        case .upright: return CGRect(x: 0, y: 490, width: 360, height: 150)
        case .wide: return CGRect(x: 0, y: 264, width: 640, height: 96)
        case .storePreview: return CGRect(x: 0, y: 490, width: canvas.width, height: 150)
        }
    }

    /// The widest a moment's note may be, in points.
    var captionMaxWidth: CGFloat {
        switch self {
        case .upright: return 320
        case .wide: return 440
        case .storePreview: return 270
        }
    }

    /// The most lines a moment's sentence takes before it is drawn smaller (never cut off: see ClipCaptionView).
    var captionLines: Int {
        switch self {
        case .upright: return 5
        case .wide: return 4
        case .storePreview: return 6
        }
    }

    /// The shape a tap makes: upright on an iPhone (the Duo included), wide on an iPad and on the Mac.
    @MainActor static var standard: ClipShape {
        #if canImport(UIKit)
        return UIDevice.current.userInterfaceIdiom == .phone ? .upright : .wide
        #else
        return .wide
        #endif
    }

    /// The other shape, for the "Share wide clip" / "Share upright clip" choice.
    var other: ClipShape { self == .upright ? .wide : .upright }
}
