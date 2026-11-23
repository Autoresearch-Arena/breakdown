// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Opens the system's own share sheet for a finished Lens clip (0.7.7, plans/23-Nov-2026-clips-plan.md, Step
//          8): on iPhone and iPad the activity sheet (save to the photo library, send in a message, pass to a nearby
//          device and the rest; on iPad a popover from the bottom middle of the window, no arrow), on the Mac the
//          sharing picker anchored the same way. Saving to the photo library is the sheet's own option (the app
//          declares the photo library add permission line for it). onDone runs when the sheet closes, whatever was
//          picked, so ClipMaker knows the file is no longer in use.
//          Presented from the top-most presented view controller of the foreground scene's key window (iOS) or the
//          key window's content view (macOS); if there is none, onDone runs at once.
// SRP/DRY check: Pass - the only share sheet in the app.
import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
enum ClipSharePresenter {
    #if canImport(UIKit)
    static func present(_ url: URL, onDone: @escaping @MainActor () -> Void) {
        guard let root = topController() else { onDone(); return }
        let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        sheet.completionWithItemsHandler = { _, _, _, _ in
            MainActor.assumeIsolated { onDone() }
        }
        if let popover = sheet.popoverPresentationController {
            // iPad: a popover from the bottom middle of the window, with no arrow.
            popover.sourceView = root.view
            popover.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.maxY - 1, width: 1, height: 1)
            popover.permittedArrowDirections = []
        }
        root.present(sheet, animated: true)
    }

    /// The controller to present from: the key window of the foreground scene, then whatever it already presents.
    private static func topController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        let window = scene?.windows.first { $0.isKeyWindow } ?? scene?.windows.first
        var top = window?.rootViewController
        while let next = top?.presentedViewController { top = next }
        return top
    }
    #elseif canImport(AppKit)
    /// The picker's delegate, kept alive while the picker is up.
    private static var delegate: PickerDelegate?

    static func present(_ url: URL, onDone: @escaping @MainActor () -> Void) {
        guard let view = NSApplication.shared.keyWindow?.contentView ?? NSApplication.shared.mainWindow?.contentView else {
            onDone()
            return
        }
        let picker = NSSharingServicePicker(items: [url])
        let d = PickerDelegate(onDone: onDone)
        delegate = d
        picker.delegate = d
        // A small rectangle at the bottom middle of the window's content (AppKit views count up from the bottom unless
        // flipped; either way this sits on the bottom edge).
        let y = view.isFlipped ? view.bounds.maxY - 2 : view.bounds.minY
        picker.show(relativeTo: NSRect(x: view.bounds.midX - 1, y: y, width: 2, height: 2), of: view, preferredEdge: .minY)
    }

    /// Calls onDone once: when a service finishes sharing, or when the picker closes without one. On the main actor
    /// (AppKit calls its delegates there); the picker's protocol is not annotated, hence the preconcurrency conformance.
    @MainActor
    private final class PickerDelegate: NSObject, @preconcurrency NSSharingServicePickerDelegate,
                                        NSSharingServiceDelegate {
        private let onDone: @MainActor () -> Void
        private var done = false

        init(onDone: @escaping @MainActor () -> Void) { self.onDone = onDone }

        private func finish() {
            guard !done else { return }
            done = true
            onDone()
            ClipSharePresenter.delegate = nil
        }

        func sharingServicePicker(_ picker: NSSharingServicePicker, delegateFor sharingService: NSSharingService)
            -> (any NSSharingServiceDelegate)? { self }

        func sharingServicePicker(_ picker: NSSharingServicePicker, didChoose service: NSSharingService?) {
            // No service picked: the picker closed.
            if service == nil { finish() }
        }

        func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) { finish() }

        func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: any Error) {
            finish()
        }
    }
    #endif
}
