// Author: Claude Opus 5.5 High
// Date: 20-November-2026
// PURPOSE: The player's options, stored on the device: sound, vibration, shot explanations (the caption card in the
//          Physics Lens), the aim guide (ghost ball and where the balls head after contact), and whether the
//          explanation card shows its maths. One key per option, read by the views with @AppStorage and by the sound
//          and haptics players at the moment they play, so a change in Options applies at once. Also the Options sheet
//          itself, opened from the main menu.
// SRP/DRY check: Pass - checked ShotPanel (aimHintSeen key, reused here for "show the aiming tips again") and
//          SoundBoard/Haptics (the -muteSound launch switch stays for testing; these options sit on top of it).
import SwiftUI

enum GameSettings {
    static let soundKey = "optionSound"
    static let hapticsKey = "optionHaptics"
    static let explanationsKey = "optionExplanations"
    static let aimGuideKey = "optionAimGuide"
    static let mathsKey = "optionShowMaths"

    /// Options default to on; reading a missing key as "on" keeps a fresh install fully featured.
    private static func flag(_ key: String) -> Bool { UserDefaults.standard.object(forKey: key) as? Bool ?? true }
    static var soundOn: Bool { flag(soundKey) }
    static var hapticsOn: Bool { flag(hapticsKey) }
}

struct OptionsSheet: View {
    @Binding var isOpen: Bool
    @AppStorage(GameSettings.soundKey) private var sound = true
    @AppStorage(GameSettings.hapticsKey) private var haptics = true
    @AppStorage(GameSettings.explanationsKey) private var explanations = true
    @AppStorage(GameSettings.aimGuideKey) private var aimGuide = true
    @AppStorage(GameSettings.mathsKey) private var maths = false
    @AppStorage("aimHintSeen") private var hintSeen = false

    private var version: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? ""
        let b = info?["CFBundleVersion"] as? String ?? ""
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Feel") {
                    Toggle("Sound", systemImage: "speaker.wave.2", isOn: $sound)
                    #if os(iOS)
                    Toggle("Vibration", systemImage: "iphone.radiowaves.left.and.right", isOn: $haptics)
                    #endif
                }
                Section {
                    Toggle("Shot explanations", systemImage: "text.bubble", isOn: $explanations)
                    Toggle("Show the maths", systemImage: "function", isOn: $maths)
                        .disabled(!explanations)
                } header: {
                    Text("Physics Lens")
                } footer: {
                    Text("Explanations say what happened at each moment of the shot. The maths adds the equation behind it.")
                }
                Section {
                    Toggle("Aim guide", systemImage: "scope", isOn: $aimGuide)
                    Button("Show the aiming tips again", systemImage: "questionmark.circle") { hintSeen = false }
                        .disabled(!hintSeen)
                } header: {
                    Text("Aiming")
                } footer: {
                    Text("The guide shows the first ball you will hit and where both balls head next. Turn it off to judge the angle yourself.")
                }
                Section {
                    LabeledContent("Version", value: version)
                }
            }
            .navigationTitle("Options")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { isOpen = false } }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 460)
        #endif
    }
}
