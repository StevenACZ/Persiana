import AppKit
import SwiftUI

@MainActor
final class AppWindows: NSObject, NSWindowDelegate {
  var onGrantPermission: (() -> Void)?
  var onTutorialFinish: (() -> Void)?

  private let preferences: Preferences
  private let hiding: HidingController
  private var settings: NSWindowController?
  private var about: NSWindowController?
  private var tutorial: NSWindowController?

  init(preferences: Preferences, hiding: HidingController) {
    self.preferences = preferences
    self.hiding = hiding
  }

  func showSettings() {
    if settings == nil {
      settings = makeController(
        title: localized("Persiana Settings", "Configuración de Persiana"),
        rootView: SettingsView(
          preferences: preferences, hiding: hiding,
          actions: SettingsActions(
            grantPermission: { [weak self] in self?.onGrantPermission?() },
            revealApp: Self.revealApp)))
    }
    show(settings)
  }

  func showAbout() {
    if about == nil {
      about = makeController(
        title: localized("About Persiana", "Acerca de Persiana"), rootView: AboutView())
    }
    show(about)
  }

  func showTutorial() {
    if tutorial == nil {
      tutorial = makeController(
        title: localized("How Persiana works", "Cómo funciona Persiana"),
        rootView: TutorialView(preferences: preferences) { [weak self] in self?.finishTutorial() })
    }
    show(tutorial)
  }

  func closeAll() {
    for controller in [settings, about, tutorial] { controller?.close() }
  }

  func windowWillClose(_ notification: Notification) {
    guard let window = notification.object as? NSWindow else { return }
    if window === tutorial?.window {
      preferences.tutorialCompleted = true
      release { $0.tutorial = nil }
    } else if window === settings?.window {
      release { $0.settings = nil }
    } else if window === about?.window {
      release { $0.about = nil }
    }
  }

  static func revealApp() {
    NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
  }

  private func finishTutorial() {
    preferences.tutorialCompleted = true
    tutorial?.close()
    onTutorialFinish?()
  }

  private func release(_ change: @escaping @MainActor (AppWindows) -> Void) {
    DispatchQueue.main.async { [weak self] in
      MainActor.assumeIsolated {
        if let self { change(self) }
      }
    }
  }

  private func show(_ controller: NSWindowController?) {
    guard let window = controller?.window else { return }
    if !window.isVisible { window.center() }
    NSApp.activate()
    controller?.showWindow(nil)
    window.orderFrontRegardless()
    window.makeKey()
  }

  private func makeController<Content: View>(title: String, rootView: Content) -> NSWindowController
  {
    let window = NSWindow(
      contentRect: .zero, styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered,
      defer: false)
    window.title = title
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.titlebarSeparatorStyle = .none
    window.isReleasedWhenClosed = false
    window.standardWindowButton(.miniaturizeButton)?.isHidden = true
    window.standardWindowButton(.zoomButton)?.isHidden = true
    window.delegate = self
    let host = NSHostingController(rootView: rootView)
    window.contentViewController = host
    window.setContentSize(host.view.fittingSize)
    return NSWindowController(window: window)
  }
}
