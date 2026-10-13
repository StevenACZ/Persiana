import AppKit
import SwiftUI

@MainActor
final class StatusItemController: NSObject, NSPopoverDelegate {
  static let autosaveName = "persiana"
  private static let firstRunPosition = 190.0

  private let item: NSStatusItem
  private let popover = NSPopover()
  private let hiding: HidingController
  private let preferences: Preferences
  private let actions: PopoverActions
  private let glyph = GlyphAnimator()
  private var monitors: [Any] = []
  private var previousApp: NSRunningApplication?

  init(hiding: HidingController, preferences: Preferences, actions: PopoverActions) {
    let key = "NSStatusItem Preferred Position \(Self.autosaveName)"
    if UserDefaults.standard.object(forKey: key) == nil {
      UserDefaults.standard.set(Self.firstRunPosition, forKey: key)
    }
    item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    item.autosaveName = Self.autosaveName
    self.hiding = hiding
    self.preferences = preferences
    self.actions = actions
    super.init()
    popover.behavior = .transient
    popover.animates = true
    popover.delegate = self
    if let button = item.button {
      button.image = PersianaGlyph.image(openness: 1)
      button.imagePosition = .imageOnly
      button.target = self
      button.action = #selector(clicked)
      button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    glyph.apply = { [weak self] openness in
      self?.item.button?.image = PersianaGlyph.image(openness: openness)
    }
    render()
  }

  var anchor: CGRect? {
    guard let button = item.button, let window = button.window else { return nil }
    return window.convertToScreen(button.convert(button.bounds, to: nil))
  }

  var isPopoverShown: Bool { popover.isShown }

  func render() {
    let openness = hiding.phase == .shown ? 1 - CGFloat(hiding.autoHideProgress) : 0
    glyph.move(to: openness, animated: !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
    guard let button = item.button else { return }
    button.appearsDisabled = hiding.blocker != nil
    button.toolTip =
      if hiding.blocker != nil {
        localized("Persiana needs your attention", "Persiana necesita tu atención")
      } else if hiding.isHidden {
        localized("Persiana: click to show icons", "Persiana: clic para mostrar iconos")
      } else {
        localized("Persiana: click to hide icons", "Persiana: clic para ocultar iconos")
      }
    button.setAccessibilityLabel(button.toolTip)
  }

  @objc private func clicked() {
    guard let button = item.button else { return }
    bounce(button)
    if popover.isShown {
      popover.performClose(nil)
      return
    }
    let event = NSApp.currentEvent
    let wantsPanel =
      event?.type == .rightMouseUp
      || event?.modifierFlags.contains(.control) == true
      || event?.modifierFlags.contains(.option) == true
    hiding.refreshBlocker()
    if wantsPanel || hiding.blocker != nil {
      showPopover()
    } else {
      hiding.toggle()
    }
  }

  func showPopover() {
    guard let button = item.button, !popover.isShown else { return }
    UpdateManager.shared.surfaceDidOpen()
    let host = NSHostingController(
      rootView: PopoverView(hiding: hiding, preferences: preferences, actions: panelActions))
    host.sizingOptions = [.preferredContentSize]
    popover.contentViewController = host
    let front = NSWorkspace.shared.frontmostApplication
    previousApp = front == NSRunningApplication.current ? nil : front
    NSApp.activate()
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    popover.contentViewController?.view.window?.makeKey()
    installMonitors()
  }

  func closePopover() {
    if popover.isShown { popover.performClose(nil) }
  }

  func popoverDidClose(_ notification: Notification) {
    popover.contentViewController = nil
    monitors.forEach(NSEvent.removeMonitor)
    monitors = []
    DispatchQueue.main.async {
      MainActor.assumeIsolated {
        let previous = self.previousApp
        self.previousApp = nil
        if let previous, !previous.isTerminated, NSApp.isActive,
          !NSApp.windows.contains(where: { $0.isVisible && $0.canBecomeMain })
        {
          previous.activate(options: [])
        }
      }
    }
  }

  private var panelActions: PopoverActions {
    PopoverActions(
      toggle: actions.toggle,
      settings: closing(actions.settings),
      tutorial: closing(actions.tutorial),
      about: closing(actions.about),
      grantPermission: closing(actions.grantPermission),
      revealApp: closing(actions.revealApp))
  }

  private func closing(_ action: @escaping () -> Void) -> () -> Void {
    { [weak self] in
      self?.closePopover()
      action()
    }
  }

  private func installMonitors() {
    if let local = NSEvent.addLocalMonitorForEvents(
      matching: .keyDown,
      handler: { [weak self] event in
        let closeKey =
          event.keyCode == 53
          || (event.charactersIgnoringModifiers == "w"
            && event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command)
        guard closeKey, let self, self.popover.isShown else { return event }
        self.popover.performClose(nil)
        return nil
      })
    {
      monitors.append(local)
    }
    if let global = NSEvent.addGlobalMonitorForEvents(
      matching: [.leftMouseDown, .rightMouseDown],
      handler: { [weak self] _ in
        MainActor.assumeIsolated { self?.closePopover() }
      })
    {
      monitors.append(global)
    }
  }

  private func bounce(_ button: NSStatusBarButton) {
    guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
    button.wantsLayer = true
    let animation = CAKeyframeAnimation(keyPath: "transform.scale")
    animation.values = [1.0, 0.86, 1.08, 1.0]
    animation.keyTimes = [0, 0.35, 0.75, 1]
    animation.duration = 0.28
    animation.timingFunctions = [
      CAMediaTimingFunction(name: .easeOut),
      CAMediaTimingFunction(name: .easeOut),
      CAMediaTimingFunction(name: .easeInEaseOut),
    ]
    button.layer?.add(animation, forKey: "persianaStatusPress")
  }
}

@MainActor
private final class GlyphAnimator {
  private static let duration = 0.32

  var apply: ((CGFloat) -> Void)?
  private var openness: CGFloat = 1
  private var start: CGFloat = 1
  private var target: CGFloat = 1
  private var began: CFTimeInterval = 0
  private var timer: Timer?

  func move(to newTarget: CGFloat, animated: Bool) {
    guard newTarget != target else { return }
    timer?.invalidate()
    timer = nil
    target = newTarget
    guard animated, abs(newTarget - openness) > 0.1 else {
      openness = newTarget
      apply?(newTarget)
      return
    }
    start = openness
    began = CACurrentMediaTime()
    let timer = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated { self?.step() }
    }
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  private func step() {
    let elapsed = min(1, (CACurrentMediaTime() - began) / Self.duration)
    let eased = elapsed < 0.5 ? 2 * elapsed * elapsed : 1 - pow(-2 * elapsed + 2, 2) / 2
    openness = start + (target - start) * eased
    apply?(openness)
    if elapsed >= 1 {
      timer?.invalidate()
      timer = nil
    }
  }
}
