import Foundation
import Observation
import PersianaCore
import ServiceManagement

@MainActor
@Observable
final class Preferences {
  private enum Key {
    static let autoHideDelay = "autoHideDelay"
    static let hideOnLaunch = "hideOnLaunch"
    static let tutorialCompleted = "tutorialCompleted"
    static let visibleApps = "visibleApps"
    static let language = "language"
  }

  private let defaults = AppLanguage.defaults

  var autoHideDelay: AutoHideDelay {
    didSet { defaults.set(autoHideDelay.rawValue, forKey: Key.autoHideDelay) }
  }

  var hideOnLaunch: Bool {
    didSet { defaults.set(hideOnLaunch, forKey: Key.hideOnLaunch) }
  }

  var tutorialCompleted: Bool {
    didSet { defaults.set(tutorialCompleted, forKey: Key.tutorialCompleted) }
  }

  var language: AppLanguage {
    didSet {
      defaults.set(language.rawValue, forKey: Key.language)
      onLanguageChange?()
    }
  }

  private(set) var visibleApps: Set<String>
  private(set) var launchAtLogin = false
  private(set) var loginNeedsApproval = false

  @ObservationIgnored var onLanguageChange: (() -> Void)?

  init() {
    autoHideDelay =
      (defaults.object(forKey: Key.autoHideDelay) as? Double).flatMap(AutoHideDelay.init(rawValue:))
      ?? .standard
    hideOnLaunch = defaults.object(forKey: Key.hideOnLaunch) as? Bool ?? true
    tutorialCompleted = defaults.bool(forKey: Key.tutorialCompleted)
    language = AppLanguage.current
    visibleApps = Set(defaults.stringArray(forKey: Key.visibleApps) ?? [])
  }

  func rememberVisibleApps(_ apps: Set<String>) {
    guard apps != visibleApps else { return }
    visibleApps = apps
    defaults.set(apps.sorted(), forKey: Key.visibleApps)
  }

  func refreshLoginState() {
    let status = SMAppService.mainApp.status
    launchAtLogin = status == .enabled || status == .requiresApproval
    loginNeedsApproval = status == .requiresApproval
  }

  func setLaunchAtLogin(_ enabled: Bool) {
    do {
      if enabled {
        try SMAppService.mainApp.register()
      } else {
        try SMAppService.mainApp.unregister()
      }
    } catch {
      NSLog("Persiana: launch at login change failed: \(error.localizedDescription)")
    }
    refreshLoginState()
  }

  func openLoginItemsSettings() {
    SMAppService.openSystemSettingsLoginItems()
  }
}
