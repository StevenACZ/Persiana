import AppKit
import CoreGraphics
import PersianaCore

@MainActor
final class AutoHideMonitor {
  private static let tick: TimeInterval = 0.2

  var onProgress: ((Double) -> Void)?
  var onFinish: (() -> Void)?

  private var countdown: AutoHideCountdown
  private let isHeldByApp: () -> Bool
  private var timer: Timer?

  init(delay: TimeInterval, isHeldByApp: @escaping () -> Bool) {
    countdown = AutoHideCountdown(delay: delay)
    self.isHeldByApp = isHeldByApp
  }

  func start() {
    timer?.invalidate()
    let timer = Timer(timeInterval: Self.tick, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated { self?.advance() }
    }
    timer.tolerance = 0.05
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  func stop() {
    timer?.invalidate()
    timer = nil
  }

  private func advance() {
    countdown.advance(
      by: Self.tick, holding: isHeldByApp() || Self.pointerIsInMenuBar() || Self.menuIsOpen())
    onProgress?(countdown.progress)
    if countdown.isFinished {
      stop()
      onFinish?()
    }
  }

  private static func pointerIsInMenuBar() -> Bool {
    let point = NSEvent.mouseLocation
    guard let screen = NSScreen.screens.first(where: { NSMouseInRect(point, $0.frame, false) })
    else {
      return false
    }
    let barHeight = max(screen.frame.maxY - screen.visibleFrame.maxY, NSStatusBar.system.thickness)
    return point.y >= screen.frame.maxY - barHeight - 2
  }

  private static func menuIsOpen() -> Bool {
    guard
      let windows = CGWindowListCopyWindowInfo(
        [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
        as? [[String: Any]]
    else { return false }
    let popUpLevel = Int(CGWindowLevelForKey(.popUpMenuWindow))
    let statusLevel = Int(CGWindowLevelForKey(.statusWindow))
    return windows.contains { window in
      guard let layer = window[kCGWindowLayer as String] as? Int,
        let bounds = window[kCGWindowBounds as String] as? [String: Double]
      else { return false }
      let height = bounds["Height"] ?? 0
      if layer == popUpLevel { return height > 4 }
      return layer == statusLevel && (bounds["Y"] ?? 999) < 60 && height > 40
    }
  }
}
