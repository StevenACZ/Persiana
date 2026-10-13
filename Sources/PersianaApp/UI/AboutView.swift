import AppKit
import SwiftUI

struct AboutView: View {
  private static let repository = "https://github.com/StevenACZ/Persiana"

  private var version: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
  }

  private var build: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
  }

  private var year: String {
    String(Calendar.current.component(.year, from: Date()))
  }

  var body: some View {
    VStack(spacing: 18) {
      VStack(spacing: 10) {
        Image(nsImage: AppArtwork.icon)
          .resizable()
          .frame(width: 96, height: 96)
          .shadow(color: Theme.accent.opacity(0.35), radius: 12, y: 6)
          .accessibilityHidden(true)
        Text("Persiana").font(.title.bold())
        Text("v\(version) · \(build)")
          .font(.caption.monospaced())
          .foregroundStyle(.secondary)
        AboutUpdateStatus()
      }
      Text(localized("A tidy menu bar, one click away.", "Una barra de menús ordenada, a un clic."))
        .font(.callout)
        .foregroundStyle(.secondary)
      Rectangle().fill(.secondary.opacity(0.18)).frame(height: 1)
      HStack(spacing: 10) {
        link(symbol: "link", label: "GitHub", url: Self.repository)
        link(
          symbol: "ladybug", label: localized("Report an issue", "Reportar un problema"),
          url: Self.repository + "/issues")
      }
      VStack(spacing: 3) {
        Text(
          localized(
            "Free and open source under the MIT license. Inspired by Hidden Bar.",
            "Libre y de código abierto con licencia MIT. Inspirada en Hidden Bar.")
        )
        .font(.caption)
        .foregroundStyle(.tertiary)
        .multilineTextAlignment(.center)
        Text("© \(year) StevenACZ").font(.caption2).foregroundStyle(.tertiary)
      }
    }
    .padding(.horizontal, 26)
    .padding(.top, 8)
    .padding(.bottom, 20)
    .frame(width: 380)
    .fixedSize(horizontal: false, vertical: true)
    .background(Color(nsColor: .windowBackgroundColor))
    .tint(Theme.accent)
  }

  private func link(symbol: String, label: String, url: String) -> some View {
    Button {
      if let target = URL(string: url) { NSWorkspace.shared.open(target) }
    } label: {
      HStack(spacing: 6) {
        Image(systemName: symbol).font(.caption)
        Text(label).font(.caption.weight(.medium))
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 7)
      .background(
        RoundedRectangle(cornerRadius: 9, style: .continuous).fill(.secondary.opacity(0.08))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 9, style: .continuous)
          .strokeBorder(.secondary.opacity(0.16), lineWidth: 1)
      )
      .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
    .buttonStyle(.plain)
  }
}
