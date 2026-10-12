import AppKit
import ApplicationServices
import PersianaCore

enum MenuBarInventory {
  private struct Target: Sendable {
    let pid: pid_t
    let bundleIdentifier: String?
    let canStayVisible: Bool
  }

  @MainActor
  static func snapshot() async -> [StatusItemSnapshot] {
    let ownPID = ProcessInfo.processInfo.processIdentifier
    let flipY = NSScreen.screens.first?.frame.maxY ?? 0
    let targets = NSWorkspace.shared.runningApplications.compactMap { app -> Target? in
      guard app.processIdentifier != ownPID, let url = app.bundleURL, url.pathExtension == "app"
      else { return nil }
      return Target(
        pid: app.processIdentifier, bundleIdentifier: app.bundleIdentifier,
        canStayVisible: MenuBarLayout.canStayVisible(appPath: url.standardizedFileURL.path))
    }
    return await Task.detached(priority: .userInitiated) {
      targets.flatMap { statusItems(of: $0, flipY: flipY) }
    }.value
  }

  private static func statusItems(of target: Target, flipY: CGFloat) -> [StatusItemSnapshot] {
    let element = AXUIElementCreateApplication(target.pid)
    AXUIElementSetMessagingTimeout(element, 0.1)
    var bar: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, "AXExtrasMenuBar" as CFString, &bar) == .success,
      let bar, CFGetTypeID(bar) == AXUIElementGetTypeID()
    else { return [] }
    var children: CFTypeRef?
    guard
      AXUIElementCopyAttributeValue(
        bar as! AXUIElement, kAXChildrenAttribute as CFString, &children) == .success,
      let items = children as? [AXUIElement]
    else { return [] }
    return items.compactMap { item in
      frame(of: item).map {
        StatusItemSnapshot(
          bundleIdentifier: target.bundleIdentifier,
          frame: CGRect(x: $0.minX, y: flipY - $0.maxY, width: $0.width, height: $0.height),
          canStayVisible: target.canStayVisible)
      }
    }
  }

  private static func frame(of element: AXUIElement) -> CGRect? {
    var positionValue: CFTypeRef?
    var sizeValue: CFTypeRef?
    guard
      AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue)
        == .success,
      AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue) == .success,
      let positionValue, let sizeValue
    else { return nil }
    var position = CGPoint.zero
    var size = CGSize.zero
    guard AXValueGetValue(positionValue as! AXValue, .cgPoint, &position),
      AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
    else { return nil }
    return CGRect(origin: position, size: size)
  }
}
