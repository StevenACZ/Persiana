import AppKit
import ApplicationServices
import ServiceManagement
import SwiftUI

@main
struct PersianaMain {
  @MainActor static func main() {
    if CommandLine.arguments.contains("--diagnostics") {
      printDiagnostics()
      return
    }
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    withExtendedLifetime(delegate) { app.run() }
  }

  @MainActor private static func printDiagnostics() {
    let info = Bundle.main.infoDictionary ?? [:]
    let report: [String: Any] = [
      "version": info["CFBundleShortVersionString"] as? String ?? "",
      "build": info["CFBundleVersion"] as? String ?? "",
      "accessibility": AXIsProcessTrusted(),
      "menuBarControl": VisibilityRestriction().isAvailable,
      "applicationsFolder": InstallLocation.isApplicationsFolder,
      "loginEnabled": SMAppService.mainApp.status == .enabled,
    ]
    if let data = try? JSONSerialization.data(withJSONObject: report, options: [.sortedKeys]),
      let text = String(data: data, encoding: .utf8)
    {
      print(text)
    }
  }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private let preferences = Preferences()
  private var hiding: HidingController!
  private var windows: AppWindows!
  private var statusItem: StatusItemController!
  private var permissionFlow: PermissionFlow!
  private var didFinishSetup = false

  func applicationDidFinishLaunching(_ notification: Notification) {
    preferences.refreshLoginState()
    UpdateManager.shared.start()
    hiding = HidingController(preferences: preferences)
    windows = AppWindows(preferences: preferences, hiding: hiding)
    statusItem = StatusItemController(
      hiding: hiding, preferences: preferences,
      actions: PopoverActions(
        toggle: { [weak self] in self?.hiding.toggle() },
        settings: { [weak self] in self?.windows.showSettings() },
        tutorial: { [weak self] in self?.windows.showTutorial() },
        about: { [weak self] in self?.windows.showAbout() },
        grantPermission: { [weak self] in self?.permissionFlow.present() },
        revealApp: AppWindows.revealApp))
    hiding.boundary = { [weak self] in self?.statusItem.anchor }
    hiding.isHoldingOpen = { [weak self] in self?.statusItem.isPopoverShown ?? false }
    hiding.onChange = { [weak self] in self?.statusItem.render() }
    windows.onGrantPermission = { [weak self] in self?.permissionFlow.present() }
    windows.onTutorialFinish = { [weak self] in self?.hide(after: 0.6) }
    preferences.onLanguageChange = { [weak self] in
      self?.configureMainMenu()
      self?.statusItem.render()
    }
    permissionFlow = makePermissionFlow()
    configureMainMenu()
    if !permissionFlow.presentIfNeeded() { finishSetup() }
    presentQAHooks()
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool
  {
    statusItem.showPopover()
    return true
  }

  func applicationDidBecomeActive(_ notification: Notification) {
    hiding?.refreshBlocker()
  }

  func applicationWillTerminate(_ notification: Notification) {
    hiding.shutDown()
  }

  private func finishSetup() {
    hiding.refreshBlocker()
    guard !didFinishSetup else { return }
    didFinishSetup = true
    if hiding.blocker == .location {
      statusItem.showPopover()
    } else if !preferences.tutorialCompleted {
      windows.showTutorial()
    } else if preferences.hideOnLaunch {
      hide(after: 2)
    }
  }

  private func hide(after delay: TimeInterval) {
    Task { [weak self] in
      try? await Task.sleep(for: .seconds(delay))
      self?.hiding.hide()
    }
  }

  private func makePermissionFlow() -> PermissionFlow {
    let flow = PermissionFlow(
      configuration: PermissionFlowConfiguration(
        appName: "Persiana",
        icon: AppArtwork.icon,
        accent: Theme.accent,
        items: [
          PermissionFlowItem(
            .accessibility,
            reason: PermissionFlowText(
              "See where each menu bar icon sits, so Persiana knows which ones to hide.",
              "Ver dónde está cada icono de la barra de menús, para saber cuáles esconder."))
        ],
        defaults: AppLanguage.defaults,
        language: { AppLanguage.usesSpanish ? .spanish : .english },
        tagline: PermissionFlowText(
          "A tidy menu bar. One click shows everything.",
          "Una barra de menús ordenada. Un clic y aparece todo."),
        welcomeDuration: 4,
        note: PermissionFlowText(
          "Persiana only reads where menu bar icons sit. It never reads your screen or what you type.",
          "Persiana solo lee dónde están los iconos de la barra de menús. Nunca lee tu pantalla ni lo que escribes."
        ),
        menuBarAnchor: { [weak self] in self?.statusItem?.anchor }))
    flow.model.onGranted = { [weak self] _ in self?.hiding.refreshBlocker() }
    flow.onFinish = { [weak self] _ in self?.finishSetup() }
    return flow
  }

  private func presentQAHooks() {
    let environment = ProcessInfo.processInfo.environment
    if environment["PERSIANA_SHOW_TUTORIAL"] == "1" { windows.showTutorial() }
    if environment["PERSIANA_SHOW_SETTINGS"] == "1" { windows.showSettings() }
    if environment["PERSIANA_SHOW_ABOUT"] == "1" { windows.showAbout() }
    if environment["PERSIANA_SHOW_POPOVER"] == "1" {
      Task { [weak self] in
        try? await Task.sleep(for: .seconds(1))
        self?.statusItem.showPopover()
      }
    }
  }

  private func configureMainMenu() {
    let main = NSMenu()
    let application = NSMenuItem()
    let applicationMenu = NSMenu()
    applicationMenu.addItem(
      item(localized("About Persiana", "Acerca de Persiana"), #selector(showAbout)))
    applicationMenu.addItem(.separator())
    applicationMenu.addItem(
      item(localized("Settings…", "Configuración…"), #selector(showSettings), key: ","))
    applicationMenu.addItem(.separator())
    applicationMenu.addItem(
      item(localized("Quit Persiana", "Salir de Persiana"), #selector(quit), key: "q"))
    application.submenu = applicationMenu
    main.addItem(application)
    let window = NSMenuItem(title: localized("Window", "Ventana"), action: nil, keyEquivalent: "")
    let windowMenu = NSMenu(title: window.title)
    windowMenu.addItem(
      NSMenuItem(
        title: localized("Close Window", "Cerrar ventana"),
        action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
    window.submenu = windowMenu
    main.addItem(window)
    NSApp.windowsMenu = windowMenu
    NSApp.mainMenu = main
  }

  private func item(_ title: String, _ selector: Selector, key: String = "") -> NSMenuItem {
    let entry = NSMenuItem(title: title, action: selector, keyEquivalent: key)
    entry.target = self
    return entry
  }

  @objc private func showAbout() { windows.showAbout() }
  @objc private func showSettings() { windows.showSettings() }
  @objc private func quit() { NSApp.terminate(nil) }
}
