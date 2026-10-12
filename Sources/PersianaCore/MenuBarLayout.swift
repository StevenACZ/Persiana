import CoreGraphics

public struct StatusItemSnapshot: Equatable, Sendable {
  public let bundleIdentifier: String?
  public let frame: CGRect
  public let canStayVisible: Bool

  public init(bundleIdentifier: String?, frame: CGRect, canStayVisible: Bool = true) {
    self.bundleIdentifier = bundleIdentifier
    self.frame = frame
    self.canStayVisible = canStayVisible
  }
}

public enum MenuBarSide: Equatable, Sendable {
  case visible
  case hidden
}

public enum MenuBarLayout {
  public static let systemOwners: Set<String> = [
    "com.apple.MenuBarAgent", "com.apple.controlcenter", "com.apple.systemuiserver",
  ]

  // macOS ignores the allow list for apps outside /Applications: their icons hide wherever they sit.
  public static func canStayVisible(appPath: String) -> Bool {
    appPath.hasPrefix("/Applications/")
  }

  public static func stranded(_ items: [StatusItemSnapshot], sides: [String: MenuBarSide])
    -> Set<String>
  {
    Set(
      items.compactMap { item in
        guard !item.canStayVisible, let bundle = item.bundleIdentifier, sides[bundle] == .visible
        else { return nil }
        return bundle
      })
  }

  public static func sides(
    of items: [StatusItemSnapshot], boundary: CGRect, ownBundle: String?,
    isLeftToRight: Bool = true
  ) -> [String: MenuBarSide] {
    var sides: [String: MenuBarSide] = [:]
    for item in items {
      guard let bundle = item.bundleIdentifier, bundle != ownBundle,
        !systemOwners.contains(bundle)
      else { continue }
      let offset =
        isLeftToRight ? item.frame.midX - boundary.midX : boundary.midX - item.frame.midX
      if sides[bundle] != .visible { sides[bundle] = offset > 0 ? .visible : .hidden }
    }
    return sides
  }

  public static func anchored(_ frame: CGRect, screens: [CGRect], isLeftToRight: Bool = true)
    -> CGRect
  {
    let center = CGPoint(x: frame.midX, y: frame.midY)
    guard let screen = screens.first(where: { $0.contains(center) }) else { return frame }
    return frame.offsetBy(dx: -(isLeftToRight ? screen.maxX : screen.minX), dy: 0)
  }

  public static func visibleApps(
    remembered: Set<String>, updatedWith sides: [String: MenuBarSide]
  ) -> Set<String> {
    var visible = remembered
    for (bundle, side) in sides {
      if side == .visible { visible.insert(bundle) } else { visible.remove(bundle) }
    }
    return visible
  }

  public static func allowList(ownBundle: String?, visibleApps: Set<String>) -> [String] {
    var allowed = visibleApps.sorted()
    if let ownBundle {
      allowed.removeAll { $0 == ownBundle }
      allowed.insert(ownBundle, at: 0)
    }
    return allowed
  }
}
