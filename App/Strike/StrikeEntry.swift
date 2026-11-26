// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: Typing an exact value into the strike panel (plans/25-Nov-2026-strike-panel-and-controls-plan.md, stage 2
//          item 4, and stage 3 item 6). A tap on the Swing, Tip, Cue angle, Cut or Bridge tile opens a small number field
//          with a stepper, so a player can enter 2.60 or step by a hundredth. Each field writes the same model values the
//          gauges, the dial and the bridge finger write, through the same setters (activePower, activeTipUp,
//          activeTipSide, activeElevation, strokeBridge, aim(toward:)), so every lock applies and the gauges move with it.
//          - StrikeEntryField: the field itself (a name, the number in the game's number style, the unit, a stepper).
//          - StrikeEntry.Kind: which value a tile edits, its range, step, decimals and unit, and its binding.
//          - StrikeEntry.setCut: aims so the launch line meets the first ball in line at the typed cut, keeping the
//            ball on the side of the line it is on now, with the side-spin push undone (AimGeometry.cueAim), so the
//            ball itself leaves along the line that gives that cut.
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (aiming panel redesign, plans/26-Nov-2026-aiming-panel-redesign-plan.md
//          step 7: BridgeControl, the bridge's figure and a minus and plus pill for the What-you-set band, writing
//          through Kind.bridge's own range and binding.)
// SRP/DRY check: Pass - checked FineControls (sliders for the same values, the same setters; kept for the upright phone
//          and VoiceOver), AimGeometry (guideLine, cueAim reused) and CueAngleMenu (sine conversion reused).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import SwiftUI

enum StrikeEntry {
    /// The values a tile can be typed into.
    enum Kind: String, Identifiable {
        case swing, tipUp, tipSide, cueAngle, cut, bridge
        var id: String { rawValue }

        /// The field's name.
        var name: String {
            switch self {
            case .swing: return StrikeWords.swingLabel
            case .tipUp: return StrikeWords.heightWord
            case .tipSide: return StrikeWords.sideWord
            case .cueAngle: return StrikeWords.cueAngleLabel
            case .cut: return StrikeWords.cutLabel
            case .bridge: return StrikeWords.bridgeLabel
            }
        }

        /// The unit printed after the field (the symbols the panel's tiles use).
        var unit: String {
            switch self {
            case .swing: return UnitSymbol.shown("m/s")
            case .tipUp, .tipSide: return String(localized: "mm")
            case .cueAngle, .cut: return "°"
            case .bridge: return UnitSymbol.shown("cm")
            }
        }

        /// Decimals shown and the stepper's step: a hundredth of a metre per second for the swing (the plan's 2.60),
        /// a tenth of a millimetre for the tip, a whole degree for the cue angle (the dial's own step), a tenth of a
        /// degree for the cut, half a centimetre for the bridge.
        var decimals: Int {
            switch self {
            case .swing: return 2
            case .tipUp, .tipSide, .cut, .bridge: return 1
            case .cueAngle: return 0
            }
        }

        var step: Double {
            switch self {
            case .swing: return 0.01
            case .tipUp, .tipSide, .cut: return 0.1
            case .cueAngle: return 1
            case .bridge: return 0.5
            }
        }

        /// The range the model allows, in the field's units.
        @MainActor
        func range(_ model: ShowpieceModel) -> ClosedRange<Double> {
            switch self {
            case .swing:
                return CueProfile.swing(forPower: model.powerRange.lowerBound)...CueProfile.swing(forPower: model.powerRange.upperBound)
            case .tipUp, .tipSide: return (-model.tipLimit * 1000)...(model.tipLimit * 1000)
            case .cueAngle: return 0...Double(CueAngleMenu.angles.last ?? 80)
            case .cut: return 0...89
            case .bridge: return (StrokeModel.bridgeRange.lowerBound * 100)...(StrokeModel.bridgeRange.upperBound * 100)
            }
        }

        /// True while the model lets the player change this value now (the setters refuse anyway; this greys the tile).
        @MainActor
        func isOpen(_ model: ShowpieceModel) -> Bool {
            guard model.personControlsLive else { return false }
            let open = model.openControls
            switch self {
            case .swing: return open.contains(.power)
            case .tipUp: return open.contains(.tipUp)
            case .tipSide: return open.contains(.tipSide)
            case .cueAngle: return model.elevationAllowed && model.cueAngleIsPlayers
            case .cut: return !model.racked && open.contains(.aim) && AimGeometry.guideContact(for: model) != nil
            case .bridge: return !model.restInUse
            }
        }

        /// The value, in the field's units, read from and written to the model's own setters.
        @MainActor
        func binding(_ model: ShowpieceModel) -> Binding<Double> {
            switch self {
            case .swing:
                return Binding(get: { CueProfile.swing(forPower: model.activePower) },
                               set: { model.activePower = CueProfile.power(forSwing: $0) })
            case .tipUp:
                return Binding(get: { model.activeTipUp * 1000 }, set: { model.activeTipUp = $0 / 1000 })
            case .tipSide:
                return Binding(get: { model.activeTipSide * 1000 }, set: { model.activeTipSide = $0 / 1000 })
            case .cueAngle:
                return Binding(get: { asin(min(max(model.activeElevation, 0), 0.995)) * 180 / .pi },
                               set: { model.activeElevation = $0 < 0.5 ? 0 : sin($0 * .pi / 180) })
            case .cut:
                return Binding(get: { model.plannedStrike?.cut ?? 0 }, set: { StrikeEntry.setCut(model, degrees: $0) })
            case .bridge:
                return Binding(get: { (model.strokeBridge ?? StrokeModel.automaticBridge) * 100 },
                               set: { model.strokeBridge = $0 / 100 })
            }
        }
    }

    /// Aim so the ball leaves along a line that meets the first ball in line at `degrees` of cut (0 full ball). The
    /// line passes the object ball's centre at 2R sin(cut) (two touching balls' centres are 2R apart), so it is the
    /// line to the ball's centre turned by asin(2R sin(cut) / distance), toward the side that keeps the ball where it
    /// is now relative to the line. The cue is then turned back by side spin's push (AimGeometry.cueAim), so the ball,
    /// not the cue, leaves along that line. Nothing happens for a break, with no ball in line, or when the ball is so
    /// close that the cut cannot be reached.
    @MainActor
    static func setCut(_ model: ShowpieceModel, degrees: Double) {
        guard !model.racked, let guide = AimGeometry.guideLine(for: model), let contact = guide.contact else { return }
        let origin = model.aimOrigin
        let toBall = contact.target - origin
        let distance = toBall.length
        let offset = 2 * model.timeline.table.ballRadius * sin(min(max(degrees, 0), 89) * .pi / 180)
        guard distance > 0, offset < distance else { return }
        // Positive cross product: the ball sits to the left of the launch line (counter-clockwise of it).
        let cross = guide.direction.x * toBall.y - guide.direction.y * toBall.x
        let side: Double = cross >= 0 ? 1 : -1
        // Turn the line to the ball's centre clockwise (ball on the left) or counter-clockwise (ball on the right).
        let turn = -side * asin(offset / distance)
        let u = toBall.normalized
        let launch = Vec2(u.x * cos(turn) - u.y * sin(turn), u.x * sin(turn) + u.y * cos(turn))
        model.aim(toward: origin + AimGeometry.cueAim(forLaunch: launch, for: model))
    }
}

/// One typed value: its name, a number field in the game's number style, its unit and a stepper. Used inside a popover
/// from the strike panel's tiles. The field commits on Return (or on leaving it); the stepper writes at once.
struct StrikeEntryField: View {
    let model: ShowpieceModel
    let kind: StrikeEntry.Kind
    @FocusState private var focused: Bool

    var body: some View {
        let range = kind.range(model)
        let value = kind.binding(model)
        // The field shows and takes the value in the game's number style, and anything typed outside the range is
        // brought back inside it before it reaches the model.
        let clamped = Binding<Double>(get: { value.wrappedValue },
                                      set: { value.wrappedValue = min(max($0, range.lowerBound), range.upperBound) })
        VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: kind.name).font(Theme.label).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                TextField(kind.name, value: clamped,
                          format: .number.locale(AppLocale.numbers).precision(.fractionLength(kind.decimals)))
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .focused($focused)
                    .frame(minWidth: 96, maxWidth: 140)
                    #if os(iOS)
                    .keyboardType(.numbersAndPunctuation)
                    #endif
                Text(verbatim: kind.unit).font(Theme.body).foregroundStyle(.secondary)
                Stepper(kind.name, value: clamped, in: range, step: kind.step)
                    .labelsHidden()
            }
        }
        .padding(16)
        .frame(minWidth: 260)
        .onAppear { focused = true }
        .accessibilityElement(children: .contain)
    }
}

// MARK: The bridge on the big screens

/// Aiming panel redesign (step 7): the bridge as a control of its own in the What-you-set band: "Bridge", its figure in
/// whole centimetres (typeable, the same StrikeEntryField), and a minus and plus pill that move it a centimetre a tap
/// through the same setter (model.strokeBridge, via Kind.bridge's binding). The rest fixes its own length, so the
/// control waits while it is in use.
struct BridgeControl: View {
    let model: ShowpieceModel
    var figureSize: CGFloat = 26
    /// The pill beside the figure (one row, the Mac's button row) instead of under it.
    var inline = false
    @Environment(\.palette) private var palette

    var body: some View {
        let layout = inline ? AnyLayout(HStackLayout(alignment: .center, spacing: 14))
                            : AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
        layout {
            TypeableFigure(model: model, kind: .bridge, spokenLabel: StrikeWords.bridgeLabel,
                           spokenValue: StrikeSpoken.centimetres(model.strokeBridgeLength)) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: StrikeWords.bridgeLabel)
                        .font(.system(size: max(13, figureSize * 0.55), weight: .semibold))
                        .foregroundStyle(.secondary)
                    FigureLine(figure: StrikeWords.centimetresFigure(model.strokeBridgeLength), size: figureSize,
                               role: .set, editable: StrikeEntry.Kind.bridge.isOpen(model))
                        .padding(.bottom, 4)
                }
            }
            pill
        }
    }

    /// Minus and plus in one pill, a centimetre a tap, each at least 44 points.
    private var pill: some View {
        HStack(spacing: 0) {
            step(-1, systemImage: "minus", label: StrikeWords.shorterBridge)
            Rectangle().fill(palette.rule).frame(width: 1, height: 28).accessibilityHidden(true)
            step(1, systemImage: "plus", label: StrikeWords.longerBridge)
        }
        .background(Color.white.opacity(0.06), in: .capsule)
        .overlay(Capsule().strokeBorder(palette.rule, lineWidth: 1))
        .disabled(!StrikeEntry.Kind.bridge.isOpen(model))
    }

    private func step(_ direction: Double, systemImage: String, label: String) -> some View {
        Button {
            let range = StrikeEntry.Kind.bridge.range(model)
            let binding = StrikeEntry.Kind.bridge.binding(model)
            // Whole centimetres: from the shown figure, one up or down, inside the bridge's range.
            let now = (model.strokeBridgeLength * 100).rounded()
            binding.wrappedValue = min(max(now + direction, range.lowerBound), range.upperBound)
        } label: {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(palette.accent)
                .frame(width: InstrumentSize.stepperWidth, height: InstrumentSize.stepperHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverHighlight(.fill(cornerRadius: 24))
        .accessibilityLabel(Text(verbatim: label))
        .accessibilityValue(Text(verbatim: StrikeSpoken.centimetres(model.strokeBridgeLength)))
    }
}
