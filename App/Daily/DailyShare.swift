// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2: one meaning per colour. Fouls, misses and
//          refusals take Palette.warning; headings, try counts, tags and difficulty take paper or paper2; the sliding
//          magenta is left for sliding and friction.)
// PURPOSE: The shot of the day's share picture (plans/25-Nov-2026-shot-of-the-day-plan.md, stage 2 item 5): the date
//          (the day's own date in Coordinated Universal Time, written in the game's number locale), the day number, the
//          table with the balls at their starting places and the mark (TrickPathThumb, given a path with no strokes in
//          it, so no answer's path is ever drawn), the five dots for the tries, the score and the streak. Nothing in it
//          shows the answer or its settings. It is drawn with SwiftUI's ImageRenderer at three times its size, written
//          as a PNG to the temporary folder, handed to the one share sheet (ClipSharePresenter, App/Clips/ClipShare.swift)
//          and removed when the sheet closes.
//          Called by the result card's Share (DailyCard, DailyPhoneBlurbs), only once the day is finished.
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 bank: the picture draws the shot's own table, its holes
//          in the bed among the pockets, for a shot of the day on another table.)
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 10, "Achievements and sharing": the day's
//          picture is the one share picture every result now uses (SharePictureCard, App/SharePicture.swift): the
//          serif wordmark and the date, "Shot of the day" and the day number, the shot's own table with the balls at
//          their starting places and the mark, the verdict in its tone, the distance from the mark at the lead size
//          (the mode's real-unit figure, when made), the five try dots over the score and the streak. Drawing and
//          writing the PNG moved to ClipSharePresenter.sharePicture, the one share route. Still never the answer.)
// SRP/DRY check: Pass - checked SharePictureCard (the one picture design, reused), ClipSharePresenter (the only share
//          sheet and the only place a picture is drawn to a file), TrickPathThumb (the small table drawing, reused with
//          its optional mark) and DailyTryDots (the dots, reused as the picture's accessory).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import SwiftUI

@MainActor
enum DailyShare {
    /// Draw the finished day on the table and open the share sheet. Does nothing before the day is finished or when
    /// the picture cannot be drawn or written (logged by the share route).
    static func share(model: ShowpieceModel) {
        let daily = model.dailyMode
        guard let shot = daily.shot, let day = daily.result(forDay: shot.day), day.finished else { return }
        let picture = SharePicture(
            mode: DailyWords.title, corner: DailyWords.day(shot.dayLabel), verdict: DailyWords.resultTitle(day),
            tone: day.made ? .passed : .foul,
            // The mode's real-unit figure: how far from the mark the white ball stopped on the make.
            figure: day.made ? day.distance.map { NumberStyle.distance(metres: $0) } : nil,
            figureCaption: DailyWords.markLabel,
            status: [KitStatusItem(DailyWords.scoreLabel, figure: DailyWords.number(day.score)),
                     KitStatusItem(DailyWords.streakLabel, figure: DailyWords.number(daily.streak(asOf: shot.day)))],
            path: startOnly(shot.start, table: shot.table), mark: daily.mark, date: date(ofDay: shot.day))
        let card = SharePictureCard(picture: picture) {
            DailyTryDots(tries: day.tries, madeOnTry: day.madeOnTry)
                .font(Theme.controlFigure)
        }
        ClipSharePresenter.sharePicture(card, fileName: "shot-of-the-day-\(shot.dayLabel)")
    }

    /// The day's own date, midnight in Coordinated Universal Time, written short in the game's number locale.
    static func date(ofDay day: Int) -> String {
        let start = DailyBank.startDate.addingTimeInterval(Double(day) * DailyBank.secondsPerDay)
        let style = Date.FormatStyle(date: .abbreviated, time: .omitted, locale: AppLocale.numbers, timeZone: .gmt)
        return start.formatted(style)
    }

    /// The shot's table with the balls at their starting places and no strokes at all (no cue path, no other ball's
    /// path), for TrickPathThumb. 0.7.10 bank: the shot's own table (its size and balls); on a table with holes in the
    /// bed (bumper pool's cups, bar billiards' holes) those are drawn where the pockets would be. Also the result
    /// share's drawing when the struck ball never moved (ResultShare.drawing).
    static func startOnly(_ start: [Vec2], table kind: TableKind = .standard) -> TrickPath {
        let table = kind.parameters.tableSpec
        let balls = start.indices.filter { NextShot.isOnTable(start[$0]) }
            .map { TrickPath.StartBall(ball: $0, position: start[$0]) }
        return TrickPath(length: table.length, width: table.width, ballRadius: table.ballRadius,
                         pockets: table.pockets + table.bedHoles.map(\.center), balls: balls, cue: [], objects: [])
    }
}
