import SwiftUI

struct UpdateCard: View {
  private var updates: UpdateManager { .shared }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .top, spacing: 10) {
        Image(systemName: symbol)
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(Theme.accentText)
          .contentTransition(.symbolEffect(.replace))
          .frame(width: 22)
        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.callout.weight(.semibold))
          if let subtitle {
            Text(subtitle)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        Spacer(minLength: 0)
      }
      controls
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .card(tint: Theme.accent)
    .animation(Theme.Anim.content, value: updates.phase)
  }

  private var version: String {
    switch updates.phase {
    case .available(let version), .readyToInstall(let version), .failed(let version):
      version
    case .idle, .downloading, .installing:
      updates.pendingVersion ?? ""
    }
  }

  private var symbol: String {
    switch updates.phase {
    case .idle, .available: "arrow.down.circle.fill"
    case .downloading: "arrow.down.circle"
    case .readyToInstall: "checkmark.circle.fill"
    case .installing: "arrow.triangle.2.circlepath"
    case .failed: "exclamationmark.arrow.circlepath"
    }
  }

  private var title: String {
    switch updates.phase {
    case .idle, .available:
      version.isEmpty
        ? localized("A new version is available", "Hay una versión nueva")
        : localized("Version \(version) is available", "Versión \(version) disponible")
    case .downloading:
      version.isEmpty
        ? localized("Downloading the update…", "Descargando la actualización…")
        : localized("Downloading \(version)…", "Descargando \(version)…")
    case .readyToInstall:
      version.isEmpty
        ? localized("Update ready to install", "Actualización lista para instalar")
        : localized("\(version) is ready to install", "\(version) está lista para instalar")
    case .installing:
      version.isEmpty
        ? localized("Installing the update…", "Instalando la actualización…")
        : localized("Installing \(version)…", "Instalando \(version)…")
    case .failed:
      localized("The update failed", "No se pudo actualizar")
    }
  }

  private var subtitle: String? {
    switch updates.phase {
    case .idle, .available:
      localized("Downloads and installs in one click", "Se descarga e instala en un clic")
    case .downloading:
      nil
    case .readyToInstall:
      localized(
        "Persiana will quit and open again by itself", "Persiana se cerrará y volverá a abrir sola")
    case .installing:
      localized("Persiana opens again in a moment", "Persiana vuelve a abrir en un momento")
    case .failed:
      localized("Check your connection and try again", "Revisa tu conexión e inténtalo de nuevo")
    }
  }

  @ViewBuilder private var controls: some View {
    switch updates.phase {
    case .idle:
      EmptyView()
    case .available:
      prominent(localized("Update", "Actualizar")) { updates.installPendingUpdate() }
    case .downloading(let fraction):
      UpdateProgress(fraction: fraction)
    case .readyToInstall:
      HStack(spacing: 8) {
        prominent(localized("Install now", "Instalar ahora")) { updates.installNow() }
        Button {
          updates.installLater()
        } label: {
          Text(localized("Later", "Más tarde")).frame(maxWidth: .infinity)
        }
        .buttonStyle(.glass)
        .controlSize(.large)
      }
    case .installing:
      UpdateProgress(fraction: nil)
    case .failed:
      prominent(localized("Retry", "Reintentar")) { updates.retryPendingUpdate() }
    }
  }

  private func prominent(_ title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title).frame(maxWidth: .infinity)
    }
    .buttonStyle(.glassProminent)
    .tint(Theme.accent)
    .controlSize(.large)
  }
}

struct UpdateSettingsCard: View {
  private var updates: UpdateManager { .shared }

  var body: some View {
    SettingsCard(icon: "arrow.down.circle", title: localized("Updates", "Actualizaciones")) {
      if updates.available {
        Toggle(
          localized("Check for updates automatically", "Buscar actualizaciones solo"),
          isOn: Binding(
            get: { updates.autoCheckEnabled }, set: { updates.setAutoCheckEnabled($0) })
        )
        .toggleStyle(.settingSwitch)
        Divider()
        status
          .font(.callout)
          .frame(height: 26)
      } else {
        Text(
          localized(
            "Development builds are updated through the development installer.",
            "Las versiones de desarrollo se actualizan con su instalador.")
        )
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
      }
    }
  }

  @ViewBuilder private var status: some View {
    HStack(spacing: 8) {
      switch updates.phase {
      case .idle:
        switch updates.manualCheckStatus {
        case .idle:
          Text(localized("Version \(UpdateText.version)", "Versión \(UpdateText.version)"))
            .foregroundStyle(.secondary)
          Spacer(minLength: 8)
          small(localized("Check now", "Buscar ahora")) { updates.checkForUpdatesManually() }
        case .checking:
          ProgressView().controlSize(.small)
          Text(localized("Checking for updates…", "Buscando actualizaciones…"))
            .foregroundStyle(.secondary)
          Spacer(minLength: 0)
        case .upToDate:
          Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.granted)
          Text(localized("You're up to date", "Tienes la última versión"))
          Spacer(minLength: 8)
          Text(UpdateText.version).foregroundStyle(.secondary)
        case .failed:
          Image(systemName: "exclamationmark.circle.fill").foregroundStyle(Theme.warning)
          Text(localized("Could not check", "No se pudo comprobar"))
          Spacer(minLength: 8)
          small(localized("Try again", "Reintentar")) { updates.checkForUpdatesManually() }
        }
      case .available(let version):
        Text(localized("Version \(version) is available", "Versión \(version) disponible"))
        Spacer(minLength: 8)
        small(localized("Update", "Actualizar"), prominent: true) { updates.installPendingUpdate() }
      case .downloading(let fraction):
        Text(localized("Downloading…", "Descargando…")).foregroundStyle(.secondary)
        UpdateProgress(fraction: fraction)
      case .readyToInstall:
        Text(localized("Ready to install", "Lista para instalar"))
        Spacer(minLength: 8)
        small(localized("Later", "Más tarde")) { updates.installLater() }
        small(localized("Install now", "Instalar ahora"), prominent: true) { updates.installNow() }
      case .installing:
        ProgressView().controlSize(.small)
        Text(localized("Installing and reopening…", "Instalando y reabriendo…"))
          .foregroundStyle(.secondary)
        Spacer(minLength: 0)
      case .failed:
        Image(systemName: "exclamationmark.circle.fill").foregroundStyle(Theme.warning)
        Text(localized("The update failed", "No se pudo actualizar"))
        Spacer(minLength: 8)
        small(localized("Retry", "Reintentar")) { updates.retryPendingUpdate() }
      }
    }
  }

  private func small(_ title: String, prominent: Bool = false, action: @escaping () -> Void)
    -> some View
  {
    Group {
      if prominent {
        Button(title, action: action).buttonStyle(.glassProminent).tint(Theme.accent)
      } else {
        Button(title, action: action).buttonStyle(.glass)
      }
    }
    .controlSize(.small)
  }
}

struct AboutUpdateStatus: View {
  private var updates: UpdateManager { .shared }

  var body: some View {
    HStack(spacing: 8) {
      switch updates.phase {
      case .idle:
        switch updates.manualCheckStatus {
        case .idle:
          link(localized("Check for updates", "Buscar actualizaciones")) {
            updates.checkForUpdatesManually()
          }
        case .checking:
          ProgressView().controlSize(.mini)
          Text(localized("Checking for updates…", "Buscando actualizaciones…"))
            .foregroundStyle(.secondary)
        case .upToDate:
          Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.granted)
          Text(localized("You're up to date", "Tienes la última versión"))
            .foregroundStyle(.secondary)
        case .failed:
          link(localized("Could not check. Try again", "No se pudo comprobar. Reintentar")) {
            updates.checkForUpdatesManually()
          }
        }
      case .available(let version):
        Button(localized("Install \(version)", "Instalar \(version)")) {
          updates.installPendingUpdate()
        }
        .buttonStyle(.glassProminent)
        .tint(Theme.accent)
        .controlSize(.small)
        if updates.releasePageURL != nil {
          link(localized("What's new", "Novedades")) { updates.openReleasePage() }
        }
      case .downloading(let fraction):
        ProgressView().controlSize(.mini)
        Text(localized("Downloading the update…", "Descargando la actualización…"))
          .foregroundStyle(.secondary)
        if let fraction {
          Text(UpdateText.percent(fraction)).monospacedDigit().foregroundStyle(.secondary)
        }
      case .readyToInstall(let version):
        Button(localized("Install \(version) now", "Instalar \(version) ahora")) {
          updates.installNow()
        }
        .buttonStyle(.glassProminent)
        .tint(Theme.accent)
        .controlSize(.small)
        link(localized("Later", "Más tarde")) { updates.installLater() }
      case .installing:
        ProgressView().controlSize(.mini)
        Text(localized("Installing and reopening…", "Instalando y reabriendo…"))
          .foregroundStyle(.secondary)
      case .failed:
        link(localized("The update failed. Retry", "No se pudo actualizar. Reintentar")) {
          updates.retryPendingUpdate()
        }
      }
    }
    .font(.caption)
    .frame(height: 24)
    .animation(Theme.Anim.content, value: updates.phase)
  }

  private func link(_ title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title).underline().contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .foregroundStyle(.secondary)
  }
}

private struct UpdateProgress: View {
  let fraction: Double?

  var body: some View {
    HStack(spacing: 8) {
      if let fraction {
        ProgressView(value: fraction)
        Text(UpdateText.percent(fraction))
          .font(.caption.monospacedDigit())
          .foregroundStyle(.secondary)
      } else {
        ProgressView()
      }
    }
    .progressViewStyle(.linear)
    .tint(Theme.accent)
  }
}

private enum UpdateText {
  static var version: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
  }

  static func percent(_ fraction: Double) -> String {
    "\(Int((fraction * 100).rounded())) %"
  }
}
