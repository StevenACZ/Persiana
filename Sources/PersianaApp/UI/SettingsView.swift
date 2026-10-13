import AppKit
import ApplicationServices
import PersianaCore
import SwiftUI

struct SettingsActions {
  let grantPermission: () -> Void
  let revealApp: () -> Void
}

struct SettingsView: View {
  @Bindable var preferences: Preferences
  let hiding: HidingController
  let actions: SettingsActions

  private static let menuBarSettings = URL(
    string: "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension")

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      header
      if hiding.blocker == .unsupported {
        Banner(
          icon: "exclamationmark.triangle.fill",
          text: localized(
            "This version of macOS doesn't offer the menu bar control Persiana needs.",
            "Esta versión de macOS no ofrece el control de la barra de menús que Persiana necesita."
          ))
      }
      hidingCard
      startupCard
      SettingsCard(
        icon: "menubar.rectangle", title: localized("System icons", "Iconos del sistema")
      ) {
        Text(
          localized(
            "macOS always keeps its own icons, like the clock, Wi‑Fi and Control Center, in view. Turn off the ones you don't need in System Settings.",
            "macOS siempre muestra sus propios iconos, como el reloj, el Wi‑Fi y el Centro de control. Apaga los que no uses en Configuración del Sistema."
          )
        )
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        Button(localized("Open Menu Bar settings", "Abrir la configuración de la barra de menús")) {
          if let url = Self.menuBarSettings { NSWorkspace.shared.open(url) }
        }
        .buttonStyle(.glass)
      }
      permissionsCard
      SettingsCard(icon: "globe", title: localized("Language", "Idioma")) {
        Picker(localized("Language", "Idioma"), selection: $preferences.language) {
          ForEach(AppLanguage.allCases, id: \.self) { language in
            Text(language.label).tag(language)
          }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
      }
      UpdateSettingsCard()
    }
    .padding(.horizontal, 20)
    .padding(.top, 8)
    .padding(.bottom, 20)
    .frame(width: 460)
    .fixedSize(horizontal: false, vertical: true)
    .background(Color(nsColor: .windowBackgroundColor))
    .tint(Theme.accent)
    .animation(Theme.Anim.content, value: preferences.loginNeedsApproval)
    .animation(Theme.Anim.content, value: hiding.blocker)
    .onChange(of: preferences.autoHideDelay) { hiding.restartAutoHide() }
    .onAppear {
      hiding.refreshBlocker()
      preferences.refreshLoginState()
    }
    .id(preferences.language)
  }

  private var header: some View {
    HStack(spacing: 12) {
      Image(nsImage: AppArtwork.icon)
        .resizable()
        .frame(width: 40, height: 40)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 2) {
        Text(localized("Settings", "Configuración"))
          .font(.title3.weight(.bold))
        Text(
          localized(
            "Persiana keeps your menu bar tidy.", "Persiana mantiene tu barra de menús ordenada.")
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
    .padding(.bottom, 2)
  }

  private var hidingCard: some View {
    SettingsCard(icon: "timer", title: localized("Hide again", "Volver a ocultar")) {
      Picker(
        localized("Hide again after", "Ocultar de nuevo tras"),
        selection: $preferences.autoHideDelay
      ) {
        ForEach(AutoHideDelay.allCases, id: \.self) { delay in
          Text(delay.label).tag(delay)
        }
      }
      .pickerStyle(.segmented)
      .labelsHidden()
      Text(
        localized(
          "The countdown starts once the pointer leaves the menu bar and no menu is open.",
          "La cuenta empieza cuando el puntero sale de la barra de menús y no hay un menú abierto.")
      )
      .font(.caption)
      .foregroundStyle(.secondary)
      .fixedSize(horizontal: false, vertical: true)
      Divider()
      Toggle(
        localized("Hide icons when Persiana opens", "Ocultar iconos al abrir Persiana"),
        isOn: $preferences.hideOnLaunch
      )
      .toggleStyle(.settingSwitch)
    }
  }

  private var startupCard: some View {
    SettingsCard(icon: "power", title: localized("Startup", "Inicio")) {
      Toggle(
        localized("Open Persiana at login", "Abrir Persiana al iniciar sesión"),
        isOn: Binding(
          get: { preferences.launchAtLogin },
          set: { enabled in preferences.setLaunchAtLogin(enabled) })
      )
      .toggleStyle(.settingSwitch)
      .disabled(!InstallLocation.isApplicationsFolder)
      if preferences.loginNeedsApproval {
        Banner(
          icon: "exclamationmark.circle.fill",
          text: localized(
            "macOS is waiting for your approval in Login Items.",
            "macOS espera tu aprobación en Ítems de inicio."),
          actionTitle: localized("Open Login Items", "Abrir Ítems de inicio"),
          action: preferences.openLoginItemsSettings)
      }
    }
  }

  private var permissionsCard: some View {
    let trusted = hiding.blocker != .permission && AXIsProcessTrusted()
    let installed = InstallLocation.isApplicationsFolder
    return SettingsCard(icon: "hand.raised", title: localized("Permissions", "Permisos")) {
      StatusRow(
        isReady: trusted,
        title: localized("Accessibility", "Accesibilidad"),
        detail: trusted
          ? localized("Granted", "Concedido")
          : localized(
            "Needed to see where each icon sits", "Necesario para ver dónde está cada icono"),
        actionTitle: localized("Grant", "Dar permiso"),
        action: actions.grantPermission)
      StatusRow(
        isReady: installed,
        title: localized("Applications folder", "Carpeta Aplicaciones"),
        detail: installed
          ? localized("Installed in the right place", "Instalada en el lugar correcto")
          : localized(
            "macOS only lets Persiana hide icons from there",
            "macOS solo deja esconder iconos desde ahí"),
        actionTitle: localized("Show in Finder", "Mostrar en Finder"),
        action: actions.revealApp)
    }
  }
}

private struct StatusRow: View {
  let isReady: Bool
  let title: String
  let detail: String
  let actionTitle: String
  let action: () -> Void

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: isReady ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(isReady ? Theme.granted : Theme.warning)
        .contentTransition(.symbolEffect(.replace))
      VStack(alignment: .leading, spacing: 1) {
        Text(title).font(.callout)
        Text(detail)
          .font(.caption)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      Spacer(minLength: 8)
      if !isReady {
        Button(actionTitle, action: action)
          .buttonStyle(.glass)
          .controlSize(.small)
      }
    }
  }
}
