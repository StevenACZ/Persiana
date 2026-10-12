import AppKit
import ApplicationServices
import PersianaCore

enum MenuBarInventory {
  private struct Target: Sendable {
    let pid: pid_t
    let bundleIdentifier: String?
  }

  @MainActor
  static func snapshot() async -> [StatusItemSnapshot] {
    let ownPID = ProcessInfo.processInfo.processIdentifier
    let flipY = NSScreen.screens.first?.frame.maxY ?? 0
    let targets = NSWorkspace.shared.runningApplications
      .filter { $0.processIdentifier != ownPID && $0.bundleURL?.pathExtension == "app" }
      .map { Target(pid: $0.processIdentifier, bundleIdentifier: $0.bundleIdentifier) }
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
          frame: CGRect(x: $0.minX, y: flipY - $0.maxY, width: $0.width, height: $0.height))
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
