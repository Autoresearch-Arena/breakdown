// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
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
// SRP/DRY check: Pass - checked ClipShare (the only share sheet, reused, not copied), TrickPathThumb (the small table
//          drawing, reused with its new optional mark) and DailyTryDots (the dots, reused).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

@MainActor
enum DailyShare {
    /// Draw the finished day on the table and open the share sheet. Does nothing before the day is finished or when
    /// the picture cannot be drawn or written (logged).
    static func share(model: ShowpieceModel) {
        let daily = model.dailyMode
        guard let shot = daily.shot, let day = daily.result(forDay: shot.day), day.finished else { return }
        let card = DailyShareCard(dayLabel: shot.dayLabel, date: date(ofDay: shot.day), path: startOnly(shot.start, table: shot.table),
                                  mark: daily.mark, tries: day.tries, madeOnTry: day.madeOnTry, score: day.score,
                                  streak: daily.streak(asOf: shot.day))
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        guard let image = renderer.cgImage else {
            NSLog("DailyShare: the picture could not be drawn")
            return
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("shot-of-the-day-\(shot.dayLabel).png")
        guard write(image, to: url) else {
            NSLog("DailyShare: the picture could not be written to %@", url.path)
            return
        }
        ClipSharePresenter.present(url) {
            // The sheet has closed: the file is no longer in use.
            do { try FileManager.default.removeItem(at: url) } catch {
                NSLog("DailyShare: the shared picture could not be removed: %@", error.localizedDescription)
            }
        }
    }

    /// The day's own date, midnight in Coordinated Universal Time, written short in the game's number locale.
    static func date(ofDay day: Int) -> String {
        let start = DailyBank.startDate.addingTimeInterval(Double(day) * DailyBank.secondsPerDay)
        let style = Date.FormatStyle(date: .abbreviated, time: .omitted, locale: AppLocale.numbers, timeZone: .gmt)
        return start.formatted(style)
    }

    /// The shot's table with the balls at their starting places and no strokes at all (no cue path, no other ball's
    /// path), for TrickPathThumb. 0.7.10 bank: the shot's own table (its size and balls); on a table with holes in the
    /// bed (bumper pool's cups, bar billiards' holes) those are drawn where the pockets would be.
    static func startOnly(_ start: [Vec2], table kind: TableKind = .standard) -> TrickPath {
        let table = kind.parameters.tableSpec
        let balls = start.indices.filter { NextShot.isOnTable(start[$0]) }
            .map { TrickPath.StartBall(ball: $0, position: start[$0]) }
        return TrickPath(length: table.length, width: table.width, ballRadius: table.ballRadius,
                         pockets: table.pockets + table.bedHoles.map(\.center), balls: balls, cue: [], objects: [])
    }

    /// Write a picture as a PNG file. False when it could not be written.
    private static func write(_ image: CGImage, to url: URL) -> Bool {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        else { return false }
        CGImageDestinationAddImage(destination, image, nil)
        return CGImageDestinationFinalize(destination)
    }
}

/// The picture itself, a fixed 600 points wide on the game's dark ground.
struct DailyShareCard: View {
    let dayLabel: Int
    let date: String
    let path: TrickPath
    let mark: Vec2?
    let tries: Int
    let madeOnTry: Int?
    let score: Int
    let streak: Int
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                // The game's own wordmark, as on the title screen.
                Text(verbatim: "BREAKDOWN")
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(palette.paper)
                Spacer(minLength: 0)
                Text(verbatim: date).font(.headline).foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: DailyWords.title).font(.title3.weight(.semibold)).foregroundStyle(palette.paper)
                Spacer(minLength: 0)
                Text(verbatim: DailyWords.day(dayLabel)).font(.headline).foregroundStyle(palette.slide)
            }
            TrickPathThumb(path: path, mark: mark)
                .frame(maxWidth: .infinity)
            HStack(alignment: .center, spacing: 18) {
                DailyTryDots(tries: tries, madeOnTry: madeOnTry)
                    .font(.title2)
                Spacer(minLength: 0)
                figure(DailyWords.number(score), DailyWords.scoreLabel)
                figure(DailyWords.number(streak), DailyWords.streakLabel)
            }
        }
        .padding(28)
        .frame(width: 600)
        .background(palette.ground)
        .environment(\.colorScheme, .dark)
    }

    private func figure(_ value: String, _ label: String) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(verbatim: value).font(.system(.title, design: .rounded, weight: .bold).monospacedDigit())
                .foregroundStyle(palette.paper)
            Text(verbatim: label).font(.caption.weight(.medium)).foregroundStyle(.secondary)
        }
    }
}
