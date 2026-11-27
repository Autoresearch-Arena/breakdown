// Author: Claude Opus 5.5 Medium
// Date: 27-November-2026
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 10, "Achievements and sharing": new file.)
// PURPOSE: The one share picture for every result (plans/26-Nov-2026-ui-rethink-plan.md, package 10): one design, drawn
//          from the real table the shot was played on.
//            SharePicture     - what one picture says: the mode and its corner word ("Day 12", a trick's title), the
//                               verdict and its tone, the mode's one real-unit figure and its caption (NumberStyle, so
//                               the same precision as the result card), the status figures (score, streak), the
//                               drawing (TrickPath: the shot's own table, its real size, its balls and pockets) with an
//                               optional mark, and the date in the game's number locale.
//            SharePictureCard - the picture itself, a fixed 600 points wide on the ground: the serif wordmark (the
//                               display role with its wordmark tracking) and the date; the mode and its corner word;
//                               the table; then the verdict, the figure at the lead size with its grey unit, and on the
//                               right an optional accessory (the shot of the day's try dots) over the status line.
//                               Always dark, always the standard text size, so a picture looks the same whoever made it.
//            ResultShare      - the result cards' Share: the last shot on the table (ShowpieceModel.currentAttempt)
//                               traced over its own table, the card's figure (or, for a card without one, the shot's
//                               speed), handed to the one share sheet. Every result card passes ResultShare.action as
//                               its quiet Share; the shot of the day keeps its own route (DailyShare), which builds the
//                               same picture without the answer's path.
//          Nothing here plays a sound, and nothing names a person, brand or source.
// SRP/DRY check: Pass - checked DailyShareCard (replaced by this one design; DailyShare now builds a SharePicture),
//          ClipEndCardView (the clip's end card: the same wordmark; it lives in ClipOverlay, another owner),
//          TrickPathThumb and TrickPath.traced (the drawing, reused), KitFigure and KitStatusLine (the figure face and
//          the status line, reused), ModeResultCard's verdict colours (the same tone rule) and ClipSharePresenter (the one
//          share sheet and the only place a picture is drawn to a file).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import SwiftUI

/// What one share picture says.
struct SharePicture {
    /// The mode's name ("Shot of the day", "Trick shots", "Free play"), already translated.
    let mode: String
    /// A short word on the right of the mode ("Day 12", the trick's title), paper2; nil for none.
    var corner: String? = nil
    /// The result's verdict ("Made it on try 2.", "Missed").
    let verdict: String
    var tone: ResultTone = .plain
    /// The mode's one real-unit figure and its caption ("4.5 cm", "From the mark").
    var figure: NumberStyle.Reading? = nil
    var figureCaption: String? = nil
    /// Score, streak and the like, on the status line.
    var status: [KitStatusItem] = []
    /// The table drawn from its real size, with the balls and (for a played shot) their paths.
    let path: TrickPath
    /// A mark on the cloth (the shot of the day's stopping mark); nil for none.
    var mark: Vec2? = nil
    /// The date, already written in the game's number locale.
    let date: String
}

/// The picture itself: one design for every result.
struct SharePictureCard<Accessory: View>: View {
    let picture: SharePicture
    let accessory: Accessory
    @Environment(\.palette) private var palette

    /// The picture's width in points; drawn at three pixels a point, 1800 pixels across.
    static var width: CGFloat { 600 }

    init(picture: SharePicture, @ViewBuilder accessory: () -> Accessory) {
        self.picture = picture
        self.accessory = accessory()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.sm) {
                // The game's own wordmark: the serif display role with its wordmark tracking, never translated.
                Text(verbatim: "Breakdown")
                    .font(Theme.display)
                    .tracking(Theme.displayTracking)
                    .foregroundStyle(palette.paper)
                Spacer(minLength: 0)
                Text(verbatim: picture.date)
                    .font(Theme.caption)
                    .foregroundStyle(palette.paper2)
            }
            HStack(alignment: .firstTextBaseline, spacing: Theme.Space.sm) {
                Text(verbatim: picture.mode)
                    .font(Theme.heading)
                    .foregroundStyle(palette.paper)
                Spacer(minLength: 0)
                if let corner = picture.corner {
                    Text(verbatim: corner)
                        .font(Theme.label)
                        .foregroundStyle(palette.paper2)
                }
            }
            // The table, at its own proportions (TrickPathThumb keeps the bed's aspect).
            TrickPathThumb(path: picture.path, mark: picture.mark)
                .frame(maxWidth: .infinity)
                .clipShape(Theme.Corner.tileShape)
            HStack(alignment: .bottom, spacing: Theme.Space.md) {
                VStack(alignment: .leading, spacing: Theme.Space.figureToLabel) {
                    Text(verbatim: picture.verdict)
                        .font(Theme.heading)
                        .foregroundStyle(verdictColour)
                        .fixedSize(horizontal: false, vertical: true)
                    if let figure = picture.figure {
                        KitFigure(figure, size: .lead)
                        if let caption = picture.figureCaption {
                            Text(verbatim: caption)
                                .font(Theme.caption)
                                .foregroundStyle(palette.paper2)
                        }
                    }
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: Theme.Space.xs) {
                    accessory
                    if !picture.status.isEmpty {
                        KitStatusLine(items: picture.status)
                            .fixedSize()
                    }
                }
            }
        }
        .padding(Theme.Space.xl)
        .frame(width: Self.width)
        .background(palette.ground)
        .kitDevice(.big)
        // The same picture whoever made it: the game is always dark, and the reader's own text size is for the screen,
        // not for a picture sent to someone else.
        .environment(\.colorScheme, .dark)
        .environment(\.dynamicTypeSize, .large)
    }

    /// The verdict's colour, the result card's rule: warning for a foul or a miss, pocket gold for a pot or a pass,
    /// paper otherwise.
    private var verdictColour: Color {
        switch picture.tone {
        case .foul: return palette.warning
        case .pocketed, .passed: return palette.pocket
        case .plain: return palette.paper
        }
    }
}

extension SharePictureCard where Accessory == EmptyView {
    init(picture: SharePicture) {
        self.init(picture: picture) { EmptyView() }
    }
}

// MARK: The result cards' Share

@MainActor
enum ResultShare {
    /// The button's word (the game's existing "Share").
    static var title: String { String(localized: "Share") }
    static var hint: String {
        String(localized: "Shares a picture of this result, drawn from the table.",
               comment: "VoiceOver hint of a result card's Share button")
    }

    /// The quiet Share for a result card (ModeResultCard's `share:`), or nil while there is no shot on the table to
    /// draw. `figure` is the card's own figure; a card without one shares the shot's speed.
    static func action(model: ShowpieceModel, mode: String, corner: String? = nil, verdict: String,
                       tone: ResultTone = .plain, figure: NumberStyle.Reading? = nil, figureCaption: String? = nil,
                       status: [KitStatusItem] = []) -> KitAction? {
        guard model.currentAttempt != nil else { return nil }
        return KitAction(title, systemImage: "square.and.arrow.up") {
            share(model: model, mode: mode, corner: corner, verdict: verdict, tone: tone, figure: figure,
                  figureCaption: figureCaption, status: status)
        }
    }

    /// Draw the last shot over its own table with the result's words and figure, and open the share sheet. Does
    /// nothing when there is no shot (logged when the picture cannot be drawn or written).
    static func share(model: ShowpieceModel, mode: String, corner: String? = nil, verdict: String,
                      tone: ResultTone = .plain, figure: NumberStyle.Reading? = nil, figureCaption: String? = nil,
                      status: [KitStatusItem] = []) {
        guard let attempt = model.currentAttempt else { return }
        // A card with no figure of its own still carries one real-unit figure: the speed the cue sent the ball off at.
        let reading = figure ?? NumberStyle.speed(metresPerSecond: attempt.power)
        let caption = figure == nil ? String(localized: "Speed") : figureCaption
        let picture = SharePicture(mode: mode, corner: corner, verdict: verdict, tone: tone, figure: reading,
                                   figureCaption: caption, status: status, path: drawing(of: attempt), date: today())
        ClipSharePresenter.sharePicture(SharePictureCard(picture: picture), fileName: fileName())
    }

    /// The shot traced over its own table (the struck ball's path in colour, the others thin); a struck ball that
    /// never moved gives the balls where they started.
    static func drawing(of attempt: ShotAttempt) -> TrickPath {
        TrickPath.traced(attempt.timeline, start: attempt.start, striker: attempt.cueBall)
            ?? DailyShare.startOnly(attempt.start, table: attempt.table)
    }

    /// Today, written short in the game's number locale.
    static func today() -> String {
        Date().formatted(Date.FormatStyle(date: .abbreviated, time: .omitted).locale(AppLocale.numbers))
    }

    /// "Breakdown-result-20261127-142501": a plain name with no locale in it, so every share sheet takes it.
    private static func fileName() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd-HHmmss"
        return "Breakdown-result-" + f.string(from: Date())
    }
}
