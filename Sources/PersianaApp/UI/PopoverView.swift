import AppKit
import SwiftUI

struct PopoverActions {
  let toggle: () -> Void
  let settings: () -> Void
  let tutorial: () -> Void
  let about: () -> Void
  let grantPermission: () -> Void
  let revealApp: () -> Void
}

struct PopoverView: View {
  let hiding: HidingController
  let preferences: Preferences
  let actions: PopoverActions

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    VStack(spacing: 0) {
      header
      VStack(spacing: 12) {
        if let blocker = hiding.blocker {
          banner(blocker)
        } else if !hiding.strandedApps.isEmpty {
          strandedBanner
        }
        if UpdateManager.shared.available, UpdateManager.shared.phase != .idle {
          UpdateCard()
        }
        PrimaryButton(
          title: hiding.isHidden
            ? localized("Show hidden icons", "Mostrar iconos ocultos")
            : localized("Hide icons", "Ocultar iconos"),
          icon: hiding.isHidden ? "blinds.horizontal.open" : "blinds.horizontal.closed",
          isEnabled: hiding.blocker == nil && hiding.phase != .hiding,
          action: actions.toggle)
      }
      .padding(Theme.Layout.padding)
      Divider()
        .padding(.horizontal)
      VStack(spacing: 2) {
        ActionRow(
          icon: "gearshape", title: localized("Settings", "Configuración"),
          subtitle: autoHideSummary, action: actions.settings)
        ActionRow(
          icon: "play.circle", title: localized("How it works", "Cómo funciona"),
          action: actions.tutorial)
        ActionRow(
          icon: "info.circle", title: localized("About Persiana", "Acerca de Persiana"),
          action: actions.about)
        ActionRow(
          icon: "power", title: localized("Quit Persiana", "Salir de Persiana"), isDestructive: true
        ) {
          NSApp.terminate(nil)
        }
      }
      .padding(8)
    }
    .frame(width: Theme.Layout.panelWidth)
    .fixedSize(horizontal: false, vertical: true)
    .background(Color(nsColor: .windowBackgroundColor))
    .tint(Theme.accent)
    .animation(reduceMotion ? nil : Theme.Anim.content, value: hiding.phase)
    .animation(reduceMotion ? nil : Theme.Anim.content, value: hiding.blocker)
    .animation(reduceMotion ? nil : Theme.Anim.content, value: UpdateManager.shared.phase)
  }

  private var header: some View {
    HStack(spacing: 12) {
      ZStack {
        Circle()
          .fill(Theme.accent.opacity(0.2))
          .frame(width: 44, height: 44)
        Image(nsImage: AppArtwork.icon)
          .resizable()
          .scaledToFit()
          .frame(width: 34, height: 34)
      }
      .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 2) {
        Text("Persiana")
          .font(.headline)
          .fontWeight(.semibold)
        Text(status)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .minimumScaleFactor(0.85)
          .contentTransition(.opacity)
      }
      Spacer(minLength: 8)
      Image(systemName: hiding.isHidden ? "eye.slash" : "eye")
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(hiding.blocker == nil ? Theme.accentText : Color.secondary)
        .frame(width: 30, height: 30)
        .glassSurface(Circle())
        .contentTransition(.symbolEffect(.replace))
        .accessibilityHidden(true)
    }
    .padding([.top, .horizontal], Theme.Layout.padding)
    .padding(.bottom, 4)
  }

  private var status: String {
    switch hiding.blocker {
    case .unsupported: return localized("Needs macOS 27", "Requiere macOS 27")
    case .permission:
      return localized("Accessibility permission needed", "Falta el permiso de Accesibilidad")
    case .location:
      return localized("Move it to Applications to start", "Muévela a Aplicaciones para empezar")
    case nil: break
    }
    switch hiding.phase {
    case .hiding: return localized("Hiding…", "Ocultando…")
    case .hidden:
      let count = hiding.hiddenApps
      if count == 0 { return localized("Nothing to hide yet", "Aún no hay nada que esconder") }
      return count == 1
        ? localized("1 app hidden", "1 app oculta")
        : localized("\(count) apps hidden", "\(count) apps ocultas")
    case .shown:
      return localized("All icons in view", "Todos los iconos a la vista")
    }
  }

  private var autoHideSummary: String {
    preferences.autoHideDelay == .never
      ? localized("Auto-hide off", "Sin ocultar solo")
      : localized(
        "Hides again after \(preferences.autoHideDelay.label)",
        "Se esconden solos tras \(preferences.autoHideDelay.label)")
  }

  private var strandedBanner: some View {
    let formatter = ListFormatter()
    formatter.locale = Locale(identifier: AppLanguage.usesSpanish ? "es" : "en")
    let names = formatter.string(from: hiding.strandedApps.compactMap(\.localizedName)) ?? ""
    return Banner(
      icon: "folder.fill",
      text: localized(
        "macOS only keeps icons visible for apps in the Applications folder, so these hide too: \(names).",
        "macOS solo deja visibles los iconos de apps que están en la carpeta Aplicaciones, así que estos también se esconden: \(names)."
      ),
      actionTitle: localized("Show in Finder", "Mostrar en Finder")
    ) {
      NSWorkspace.shared.activateFileViewerSelecting(hiding.strandedApps.compactMap(\.bundleURL))
    }
  }

  @ViewBuilder
  private func banner(_ blocker: HidingController.Blocker) -> some View {
    switch blocker {
    case .unsupported:
      Banner(
        icon: "exclamationmark.triangle.fill",
        text: localized(
          "This version of macOS doesn't offer the menu bar control Persiana needs. Your icons stay visible.",
          "Esta versión de macOS no ofrece el control de la barra de menús que Persiana necesita. Tus iconos siguen visibles."
        ))
    case .permission:
      Banner(
        icon: "hand.raised.fill",
        text: localized(
          "Persiana needs Accessibility to see where each icon sits. It never reads your screen or what you type.",
          "Persiana necesita Accesibilidad para ver dónde está cada icono. No lee tu pantalla ni lo que escribes."
        ),
        tint: .blue, actionTitle: localized("Grant permission", "Dar permiso"),
        action: actions.grantPermission)
    case .location:
      Banner(
        icon: "folder.fill",
        text: localized(
          "macOS only lets Persiana hide icons when it lives in the Applications folder. Drag it there and open it again.",
          "macOS solo deja que Persiana esconda iconos si está en la carpeta Aplicaciones. Arrástrala ahí y ábrela de nuevo."
        ),
        actionTitle: localized("Show in Finder", "Mostrar en Finder"), action: actions.revealApp)
    }
  }
}
