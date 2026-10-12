import AppKit
import ApplicationServices
import Observation
import PersianaCore

@MainActor
@Observable
final class HidingController {
  enum Phase: Equatable {
    case shown
    case hiding
    case hidden
  }

  enum Blocker: Equatable {
    case unsupported
    case permission
    case location
  }

  private(set) var phase: Phase = .shown
  private(set) var hiddenApps = 0
  private(set) var strandedApps: [NSRunningApplication] = []
  private(set) var blocker: Blocker?
  private(set) var autoHideProgress: Double = 0

  @ObservationIgnored var boundary: (() -> CGRect?)?
  @ObservationIgnored var onChange: (() -> Void)?
  @ObservationIgnored var isHoldingOpen: (() -> Bool)?

  @ObservationIgnored private let preferences: Preferences
  @ObservationIgnored private let restriction = VisibilityRestriction()
  @ObservationIgnored private var hideTask: Task<Void, Never>?
  @ObservationIgnored private var monitor: AutoHideMonitor?

  init(preferences: Preferences) {
    self.preferences = preferences
    refreshBlocker()
  }

  var isHidden: Bool { phase == .hidden }

  func refreshBlocker() {
    let current: Blocker?
    if !restriction.isAvailable {
      current = .unsupported
    } else if !AXIsProcessTrusted() {
      current = .permission
    } else if !InstallLocation.isApplicationsFolder {
      current = .location
    } else {
      current = nil
    }
    guard current != blocker else { return }
    blocker = current
    onChange?()
  }

  func toggle() {
    switch phase {
    case .shown: hide()
    case .hiding: break
    case .hidden: show()
    }
  }

  func hide() {
    guard phase == .shown else { return }
    refreshBlocker()
    guard blocker == nil, let boundary = boundary?() else {
      stopAutoHide()
      return
    }
    setPhase(.hiding)
    stopAutoHide()
    let isLeftToRight = NSApp.userInterfaceLayoutDirection == .leftToRight
    let screens = NSScreen.screens.map(\.frame)
    let ownBundle = Bundle.main.bundleIdentifier
    hideTask = Task { [weak self] in
      let items = await MenuBarInventory.snapshot()
      guard let self, !Task.isCancelled, self.phase == .hiding else { return }
      let anchoredItems = items.map {
        StatusItemSnapshot(
          bundleIdentifier: $0.bundleIdentifier,
          frame: MenuBarLayout.anchored($0.frame, screens: screens, isLeftToRight: isLeftToRight),
          canStayVisible: $0.canStayVisible)
      }
      let sides = MenuBarLayout.sides(
        of: anchoredItems,
        boundary: MenuBarLayout.anchored(boundary, screens: screens, isLeftToRight: isLeftToRight),
        ownBundle: ownBundle, isLeftToRight: isLeftToRight)
      let visible = MenuBarLayout.visibleApps(
        remembered: self.preferences.visibleApps, updatedWith: sides)
      self.preferences.rememberVisibleApps(visible)
      let stranded = MenuBarLayout.stranded(anchoredItems, sides: sides)
        .compactMap { NSRunningApplication.runningApplications(withBundleIdentifier: $0).first }
        .sorted {
          ($0.localizedName ?? "").localizedStandardCompare($1.localizedName ?? "")
            == .orderedAscending
        }
      let hidden = sides.values.filter { $0 == .hidden }.count + stranded.count
      self.restriction.activate(
        allowing: MenuBarLayout.allowList(ownBundle: ownBundle, visibleApps: visible)
      ) { [weak self] succeeded in
        guard let self, self.phase == .hiding else { return }
        self.hiddenApps = hidden
        self.strandedApps = stranded
        self.setPhase(succeeded ? .hidden : .shown)
      }
    }
  }

  func show(startingAutoHide: Bool = true) {
    hideTask?.cancel()
    hideTask = nil
    restriction.release()
    guard phase != .shown else { return }
    setPhase(.shown)
    if startingAutoHide { startAutoHide() }
  }

  func restartAutoHide() {
    guard phase == .shown, monitor != nil else { return }
    stopAutoHide()
    startAutoHide()
  }

  func shutDown() {
    stopAutoHide()
    hideTask?.cancel()
    restriction.release()
  }

  private func startAutoHide() {
    guard blocker == nil, let delay = preferences.autoHideDelay.seconds else { return }
    let monitor = AutoHideMonitor(delay: delay) { [weak self] in
      self?.isHoldingOpen?() ?? false
    }
    monitor.onProgress = { [weak self] progress in self?.setProgress(progress) }
    monitor.onFinish = { [weak self] in self?.hide() }
    self.monitor = monitor
    monitor.start()
  }

  private func stopAutoHide() {
    monitor?.stop()
    monitor = nil
    setProgress(0)
  }

  private func setProgress(_ progress: Double) {
    guard autoHideProgress != progress else { return }
    autoHideProgress = progress
    onChange?()
  }

  private func setPhase(_ newPhase: Phase) {
    guard phase != newPhase else { return }
    phase = newPhase
    onChange?()
  }
}

enum InstallLocation {
  static var isApplicationsFolder: Bool {
    MenuBarLayout.canStayVisible(appPath: Bundle.main.bundleURL.standardizedFileURL.path)
  }
}
