// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 2: one meaning per colour. Fouls, misses and
//          refusals take Palette.warning; headings, try counts, tags and difficulty take paper or paper2; the sliding
//          magenta is left for sliding and friction.)
// PURPOSE: Make it again (0.7.7, plans/23-Nov-2026-make-it-again-plan.md, new file 5): every view of the feature.
//          MakeItAgainButton - the button on free play's worth-watching card (HighlightCard's CardButtonRow, hook F1):
//            Make it again while the shot on screen can be saved, Play it now once it is saved, and Make it again
//            disabled (its hint says to delete one) when the shelf is full; nothing otherwise. Its blurbButton is the
//            same as a small blurb button for the upright phone (HighlightPhoneBlurb, hook F2; a blurb cannot show a
//            disabled button, so the full state gives none there).
//          MakeItAgainMenuItem - the same three states in Shot options, after Undo last shot (ShotOptionsItems, hook
//            S1), for every saveable shot, remarkable or not.
//          MakeItAgainCommand - the Mac (and iPad keyboard) Playback menu item, Shift-Command-S (MacChrome, hook C1).
//          OwnShotsSection - "Your shots", the second section of the Trick shots list (TrickShotList, hook V1), newest
//            first; an empty shelf still shows its section with one line on how to fill it. Each row (OwnShotRow)
//            plays the shot on a tap, shows its made mark, name, goal, cloth and table when not the defaults, the
//            stroke's check this run and the small drawing of the line that worked; Rename and Delete are in the row's
//            options menu, its context menu, a swipe and VoiceOver's actions, and all of them happen inside the row
//            (a name field in place, or the delete question with its two buttons in place). No system alert or
//            confirmation dialog: the app has none, and on the open Duo one would be centred on the whole window and
//            cover the table's half.
//          No sound and no haptic anywhere (CardButtonRow builds its content twice, so a haptic there could fire twice;
//          the button's change of words is the feedback, and VoiceOver hears where the shot went).
// SRP/DRY check: Pass - views only. The rules and actions are OwnShotShelf's, the words OwnShotWords', the drawing
//          TrickPathThumb's; the row lays out exactly as TrickShotList.row lays out its authored rows (the drawing
//          beside the text, above it at accessibility sizes); the in-place name field follows the match card's
//          PlayerNamesEditor; the card button is styled as HighlightCard's own buttons.
import BreakdownLensModel
import SwiftUI

// MARK: The highlight card's button

struct MakeItAgainButton: View {
    let model: ShowpieceModel
    /// Read in body (computed, not stored), so a test's swapped shelf and the app's are both observed.
    private var shelf: OwnShotShelf { OwnShotShelf.shared }

    var body: some View {
        let shelf = self.shelf
        if let saved = shelf.savedShot(for: model) {
            button(OwnShotWords.playItNow, symbol: "play.fill", hint: OwnShotWords.playHint) {
                shelf.play(saved, model: model)
            }
        } else if shelf.canSave(model) {
            button(OwnShotWords.makeItAgain, symbol: "bookmark", hint: OwnShotWords.saveHint) {
                _ = shelf.save(from: model)
            }
        } else if shelf.isFull(for: model) {
            button(OwnShotWords.makeItAgain, symbol: "bookmark", hint: OwnShotWords.fullHint) {}
                .disabled(true)
        }
    }

    /// Styled as the card's other buttons (HighlightCard.details).
    private func button(_ title: String, symbol: String, hint: String,
                        action: @escaping @MainActor () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol).font(.headline)
                .lineLimit(1).frame(minHeight: CallMetrics.buttonHeight)
        }
        .buttonStyle(.glass)
        .accessibilityHint(hint)
    }
}

extension MakeItAgainButton {
    /// The same as a small button on the upright phone's blurb: Play it now, or Make it again, or nil (nothing to
    /// offer, or the shelf is full: a blurb cannot show a disabled button; Shot options still shows it).
    @MainActor static func blurbButton(_ model: ShowpieceModel) -> BlurbButton? {
        let shelf = OwnShotShelf.shared
        if let saved = shelf.savedShot(for: model) {
            return BlurbButton(OwnShotWords.playItNow, hint: OwnShotWords.playHint) { shelf.play(saved, model: model) }
        }
        if shelf.canSave(model) {
            return BlurbButton(OwnShotWords.makeItAgain, hint: OwnShotWords.saveHint) { _ = shelf.save(from: model) }
        }
        return nil
    }
}

// MARK: Shot options

/// Make it again / Play it now in Shot options (the shot panel's More menu on every layout and the upright phone's
/// Shot options menu), after Undo last shot.
struct MakeItAgainMenuItem: View {
    let model: ShowpieceModel

    var body: some View {
        let shelf = OwnShotShelf.shared
        if let saved = shelf.savedShot(for: model) {
            Button { shelf.play(saved, model: model) } label: {
                Label(OwnShotWords.playItNow, systemImage: "play.fill")
            }
            .accessibilityHint(OwnShotWords.playHint)
        } else if shelf.canSave(model) {
            Button { _ = shelf.save(from: model) } label: {
                Label(OwnShotWords.makeItAgain, systemImage: "bookmark")
            }
            .accessibilityHint(OwnShotWords.saveHint)
        } else if shelf.isFull(for: model) {
            Button {} label: { Label(OwnShotWords.makeItAgain, systemImage: "bookmark") }
                .disabled(true)
                .accessibilityHint(OwnShotWords.fullHint)
        }
    }
}

// MARK: The Mac menu

/// Playback > Make It Again (Shift-Command-S), after Watch It in the Lens: enabled when the shot on screen can be
/// saved; once saved it reads Play It Now. The menu bar reaches the front window's model, which may be absent.
struct MakeItAgainCommand: View {
    let model: ShowpieceModel?

    var body: some View {
        let shelf = OwnShotShelf.shared
        let saved = model.flatMap { shelf.savedShot(for: $0) }
        let canSave = model.map { shelf.canSave($0) } ?? false
        Button(saved != nil ? OwnShotWords.playItNowMac : OwnShotWords.makeItAgainMac) {
            guard let model else { return }
            if let saved {
                shelf.play(saved, model: model)
            } else {
                _ = shelf.save(from: model)
            }
        }
        .keyboardShortcut("s", modifiers: [.command, .shift])
        .disabled(saved == nil && !canSave)
    }
}

// MARK: The shelf in the Trick shots list

/// "Your shots": the player's saved challenges, newest first, at the end of the Trick shots list (a sheet on the phone,
/// a notebook page on iPad, Mac and the open Duo).
struct OwnShotsSection: View {
    let mode: TrickShotMode

    var body: some View {
        let shelf = OwnShotShelf.shared
        Section {
            ForEach(Array(shelf.shots.reversed())) { own in
                OwnShotRow(own: own, mode: mode)
            }
        } header: {
            Text(OwnShotWords.shelfTitle)
        } footer: {
            Text(shelf.shots.isEmpty ? OwnShotWords.emptyFooter : OwnShotWords.footer)
                // The checks and drawings start when the shelf is first seen (a no-op after the first call). The
                // footer is always there, so an empty shelf calls it too; the rows call it as well, in case a long
                // shelf shows rows before its footer.
                .onAppear { shelf.startChecks() }
        }
    }
}

/// One saved shot in the list, in one of three forms: the row (tap to play), its name field (Rename), or its delete
/// question (Delete). Rename and Delete from every route only switch the form; nothing covers the table.
struct OwnShotRow: View {
    let own: OwnShot
    let mode: TrickShotMode
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var editing = false
    @State private var draft = ""
    @State private var askingDelete = false
    @FocusState private var nameFocused: Bool
    @AccessibilityFocusState private var questionFocused: Bool

    private var shelf: OwnShotShelf { OwnShotShelf.shared }

    var body: some View {
        if editing {
            editor
        } else if askingDelete {
            question
        } else {
            normal
        }
    }

    // MARK: The row

    private var normal: some View {
        let playable = own.trickShot != nil
        let proof = shelf.proof[own.id]
        // Two siblings, never a menu inside the play button's label: a parent button swallows a nested menu's taps.
        return HStack(alignment: .center, spacing: 8) {
            Button { shelf.play(own, model: mode.model) } label: { content(proof: proof) }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .disabled(!playable)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(OwnShotWords.spokenRow(own, proof: proof))
                .accessibilityHint(playable ? OwnShotWords.playHint : "")
                .accessibilityAction(named: OwnShotWords.rename) { startRename() }
                .accessibilityAction(named: OwnShotWords.delete) { askDelete() }
            Menu {
                actions
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .menuIndicator(.hidden)
            .accessibilityLabel(OwnShotWords.options(own.name))
        }
        .contextMenu { actions }
        .swipeActions(edge: .trailing) {
            // Not the destructive role: that animates the row away at once, before the question has been answered.
            Button { askDelete() } label: { Label(OwnShotWords.delete, systemImage: "trash") }
                .tint(.red)
        }
        .onAppear { shelf.startChecks() }
    }

    /// Rename and Delete, for the options menu and the context menu.
    @ViewBuilder private var actions: some View {
        Button { startRename() } label: { Label(OwnShotWords.rename, systemImage: "pencil") }
        Button(role: .destructive) { askDelete() } label: { Label(OwnShotWords.delete, systemImage: "trash") }
    }

    /// The text and the drawing beside it (above it, full width, at accessibility text sizes), as the authored rows.
    @ViewBuilder private func content(proof: OwnShotCheck?) -> some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                thumb(fullWidth: true, proof: proof)
                text(proof: proof)
            }
        } else {
            HStack(alignment: .center, spacing: 12) {
                text(proof: proof)
                thumb(fullWidth: false, proof: proof)
            }
        }
    }

    private func text(proof: OwnShotCheck?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            ZStack {
                if own.made {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(palette.accent)
                } else {
                    Image(systemName: "bookmark").foregroundStyle(.secondary)
                }
            }
            .font(.title3)
            .frame(minWidth: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: own.name).font(Theme.heading)
                Text(OwnShotWords.goalLine(own))
                    .font(Theme.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(own.made ? OwnShotWords.madeAgain : OwnShotWords.notMadeYet)
                    .font(Theme.label)
                    .foregroundStyle(palette.paper2)
                if let detail = OwnShotWords.detail(own) {
                    Text(detail)
                        .font(Theme.label)
                        .foregroundStyle(palette.paper2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let note = OwnShotWords.proofLine(own, proof: proof) {
                    Text(note)
                        .font(Theme.label)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }

    /// The saved stroke's drawing, or the room for it while it is being solved, or nothing.
    @ViewBuilder private func thumb(fullWidth: Bool, proof: OwnShotCheck?) -> some View {
        if let path = shelf.paths[own.id] {
            if fullWidth {
                TrickPathThumb(path: path).frame(maxWidth: .infinity)
            } else {
                TrickPathThumb(path: path).frame(width: 96, height: 48)
            }
        } else if proof == .checking {
            Color.clear
                .aspectRatio(2, contentMode: .fit)
                .frame(width: fullWidth ? nil : 96, height: fullWidth ? nil : 48)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .accessibilityHidden(true)
        }
    }

    // MARK: Rename, in place

    private var editor: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(OwnShotWords.nameField, text: $draft)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($nameFocused)
                .accessibilityLabel(OwnShotWords.rename)
                .onSubmit { commitRename() }
            HStack(spacing: 8) {
                Spacer(minLength: 0)
                Button(OwnShotWords.cancel) { editing = false }
                    .buttonStyle(.bordered)
                Button(OwnShotWords.save) { commitRename() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 6)
        // The field takes focus as it appears, so the keyboard and VoiceOver land in it.
        .onAppear { nameFocused = true }
    }

    private func startRename() {
        draft = own.name
        askingDelete = false
        editing = true
    }

    private func commitRename() {
        shelf.rename(id: own.id, to: draft)
        editing = false
    }

    // MARK: Delete, in place

    private var question: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: own.name).font(Theme.heading)
            Text(OwnShotWords.deleteQuestion)
                .font(Theme.body)
                .accessibilityFocused($questionFocused)
            Text(OwnShotWords.deleteDetail)
                .font(Theme.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Spacer(minLength: 0)
                Button(OwnShotWords.cancel) { askingDelete = false }
                    .buttonStyle(.bordered)
                Button(OwnShotWords.delete, role: .destructive) { shelf.delete(id: own.id) }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 6)
        // VoiceOver moves to the question, so the choice is heard before the buttons.
        .onAppear { questionFocused = true }
    }

    private func askDelete() {
        editing = false
        askingDelete = true
    }
}
