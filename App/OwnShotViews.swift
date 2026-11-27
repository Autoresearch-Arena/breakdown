// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (UI rethink package 5, the mode frame: "Your shots" is a section of
//          the Trick shots sheet page (section label, the kit's list rows, a caption) instead of a system list section;
//          each row is the kit's ListRow (tick once made again, name and goal, the made state, cloth, table and check
//          on the meta line, the drawing); Rename's and Delete's in-place forms use the kit's buttons. The swipe went
//          with the system list; the options menu, the context menu and VoiceOver's actions remain.)
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
//            options menu, its context menu and VoiceOver's actions, and all of them happen inside the row
//            (a name field in place, or the delete question with its two buttons in place). No system alert or
//            confirmation dialog: the app has none, and on the open Duo one would be centred on the whole window and
//            cover the table's half.
//          No sound and no haptic anywhere (CardButtonRow builds its content twice, so a haptic there could fire twice;
//          the button's change of words is the feedback, and VoiceOver hears where the shot went).
// SRP/DRY check: Pass - views only. The rules and actions are OwnShotShelf's, the words OwnShotWords', the drawing
//          TrickPathThumb's; the row is the kit's ListRow, as TrickShotList's authored rows; the in-place name field follows the match card's
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
/// a notebook page on iPad, Mac and the open Duo). UI rethink package 5: a section of the kit's sheet page (the section
/// label, the kit's list rows, a caption under them) rather than a section of a system list.
struct OwnShotsSection: View {
    let mode: TrickShotMode
    @Environment(\.palette) private var palette

    var body: some View {
        let shelf = OwnShotShelf.shared
        VStack(alignment: .leading, spacing: Theme.Space.sectionToContent) {
            SectionLabel(OwnShotWords.shelfTitle)
            VStack(alignment: .leading, spacing: Theme.Space.xs) {
                ForEach(Array(shelf.shots.reversed())) { own in
                    OwnShotRow(own: own, mode: mode)
                }
            }
            Text(verbatim: shelf.shots.isEmpty ? OwnShotWords.emptyFooter : OwnShotWords.footer)
                .font(Theme.caption)
                .foregroundStyle(palette.paper2)
                .fixedSize(horizontal: false, vertical: true)
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
        return HStack(alignment: .center, spacing: Theme.Space.xs) {
            Button { shelf.play(own, model: mode.model) } label: { row(proof: proof) }
                .buttonStyle(.plain)
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
                    .font(Theme.heading)
                    .foregroundStyle(palette.paper2)
                    .frame(width: Theme.Size.minHit, height: Theme.Size.minHit)
                    .contentShape(Rectangle())
            }
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .menuIndicator(.hidden)
            .accessibilityLabel(OwnShotWords.options(own.name))
        }
        // Rename and Delete: the row's options menu beside it, its context menu, and VoiceOver's actions. (The system
        // list's swipe went with the list; the other three routes are unchanged.)
        .contextMenu { actions }
        .onAppear { shelf.startChecks() }
    }

    /// Rename and Delete, for the options menu and the context menu.
    @ViewBuilder private var actions: some View {
        Button { startRename() } label: { Label(OwnShotWords.rename, systemImage: "pencil") }
        Button(role: .destructive) { askDelete() } label: { Label(OwnShotWords.delete, systemImage: "trash") }
    }

    /// The kit's list row, as the authored shots above it: a tick once made again (no mark before), the name and goal
    /// in paper and paper2, then the made state, the cloth and table when not the defaults, and this run's check of
    /// the stroke on the meta line; the drawing of the line that worked on the right. The options menu draws its own
    /// trailing mark, so the row has no chevron.
    private func row(proof: OwnShotCheck?) -> some View {
        let meta = [own.made ? OwnShotWords.madeAgain : OwnShotWords.notMadeYet,
                    OwnShotWords.detail(own), OwnShotWords.proofLine(own, proof: proof)]
            .compactMap { $0 }.joined(separator: " · ")
        let leading: ListRow<EmptyView, AnyView>.Leading = own.made ? .done : .none
        return ListRow(leading: leading, title: own.name, line: OwnShotWords.goalLine(own),
                       best: meta, showsChevron: false, picture: { thumb(proof: proof) })
    }

    /// The saved stroke's drawing, or an empty room for it while it is being solved or when there is none.
    private func thumb(proof: OwnShotCheck?) -> AnyView {
        if let path = shelf.paths[own.id] { return AnyView(TrickPathThumb(path: path)) }
        return AnyView(Color.clear)
    }

    // MARK: Rename, in place

    private var editor: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            TextField(OwnShotWords.nameField, text: $draft)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($nameFocused)
                .accessibilityLabel(OwnShotWords.rename)
                .onSubmit { commitRename() }
            KitButtonRow(primary: KitAction(OwnShotWords.save) { commitRename() },
                         secondary: KitAction(OwnShotWords.cancel) { editing = false })
        }
        .padding(Theme.Space.tilePadding)
        .background(palette.panelSunken, in: Theme.Corner.tileShape)
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

    /// The question in place of the row: Cancel and Delete, the destructive one in warning words on a secondary
    /// button (design language, "Buttons").
    private var question: some View {
        VStack(alignment: .leading, spacing: Theme.Space.xs) {
            Text(verbatim: own.name).font(Theme.heading).foregroundStyle(palette.paper)
            Text(verbatim: OwnShotWords.deleteQuestion)
                .font(Theme.body)
                .foregroundStyle(palette.paper)
                .accessibilityFocused($questionFocused)
            Text(verbatim: OwnShotWords.deleteDetail)
                .font(Theme.body)
                .foregroundStyle(palette.paper2)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Theme.Space.sm) {
                Spacer(minLength: 0)
                SecondaryButton(OwnShotWords.cancel) { askingDelete = false }
                SecondaryButton(OwnShotWords.delete, destructive: true) { shelf.delete(id: own.id) }
            }
        }
        .padding(Theme.Space.tilePadding)
        .background(palette.panelSunken, in: Theme.Corner.tileShape)
        // VoiceOver moves to the question, so the choice is heard before the buttons.
        .onAppear { questionFocused = true }
    }

    private func askDelete() {
        editing = false
        askingDelete = true
    }
}
