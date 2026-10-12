import PersianaCore
import SwiftUI

struct TutorialView: View {
  @Bindable var preferences: Preferences
  let finish: () -> Void

  @State private var step = TutorialScene.click
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    VStack(spacing: 20) {
      StepIndicator(current: step.rawValue, count: TutorialScene.allCases.count)
      MenuBarDemo(scene: step, delayLabel: preferences.autoHideDelay.shortLabel)
        .id(step)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: Theme.accentDeep.opacity(0.28), radius: 18, y: 10)
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
      VStack(spacing: 8) {
        Text(title)
          .font(.system(size: 22, weight: .bold))
        Text(message)
          .font(.callout)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(width: 470)
      .id("caption-\(step.rawValue)")
      .transition(.opacity.combined(with: .offset(y: 8)))
      if step == .autoHide {
        options
          .transition(.opacity.combined(with: .offset(y: 8)))
      }
      HStack {
        if step != .click {
          Button(localized("Back", "Atrás")) { go(by: -1) }
            .buttonStyle(.glass)
            .controlSize(.large)
            .transition(.opacity)
        }
        Spacer()
        Button(step == .autoHide ? localized("Start", "Empezar") : localized("Next", "Siguiente")) {
          if step == .autoHide { finish() } else { go(by: 1) }
        }
        .buttonStyle(.glassProminent)
        .tint(Theme.accent)
        .controlSize(.large)
        .keyboardShortcut(.defaultAction)
      }
    }
    .padding(.horizontal, 30)
    .padding(.top, 34)
    .padding(.bottom, 26)
    .frame(width: 580)
    .fixedSize(horizontal: false, vertical: true)
    .background(
      LinearGradient(
        colors: [
          Color(nsColor: .windowBackgroundColor),
          Color(nsColor: .controlBackgroundColor).opacity(0.6),
        ], startPoint: .top, endPoint: .bottom
      )
      .ignoresSafeArea())
  }

  private var options: some View {
    VStack(spacing: 12) {
      HStack(spacing: 12) {
        Text(localized("Hide again after", "Ocultar de nuevo tras"))
          .fixedSize()
        Spacer(minLength: 0)
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
        .fixedSize()
      }
      Divider()
      Toggle(
        localized("Open Persiana at login", "Abrir Persiana al iniciar sesión"),
        isOn: Binding(
          get: { preferences.launchAtLogin },
          set: { enabled in preferences.setLaunchAtLogin(enabled) })
      )
      .toggleStyle(.settingSwitch)
    }
    .padding(14)
    .frame(width: 520)
    .card()
    .tint(Theme.accent)
  }

  private var title: String {
    switch step {
    case .click: localized("One click hides them", "Un clic y se esconden")
    case .arrange: localized("You choose which ones", "Tú eliges cuáles")
    case .autoHide: localized("They hide again on their own", "Se vuelven a esconder solos")
    }
  }

  private var message: String {
    switch step {
    case .click:
      localized(
        "Click Persiana to show the icons on its left, and click again to hide them. macOS always keeps its own icons, like Wi‑Fi and the clock.",
        "Haz clic en Persiana para ver los iconos de su izquierda y otro clic para esconderlos. Los iconos de macOS, como el Wi‑Fi y el reloj, siempre se ven."
      )
    case .arrange:
      localized(
        "Hold ⌘ and drag an icon to the left of Persiana to hide it, or to its right to keep it always visible.",
        "Mantén ⌘ y arrastra un icono a la izquierda de Persiana para esconderlo, o a su derecha para que siempre se vea."
      )
    case .autoHide:
      localized(
        "After you look at them, Persiana hides the icons again once the pointer leaves the menu bar. Right-click Persiana for settings.",
        "Cuando ya los viste, Persiana vuelve a esconderlos en cuanto el puntero sale de la barra de menús. Clic derecho en Persiana para la configuración."
      )
    }
  }

  private func go(by offset: Int) {
    guard let next = TutorialScene(rawValue: step.rawValue + offset) else { return }
    withAnimation(reduceMotion ? nil : Theme.Anim.step) { step = next }
  }
}

private struct StepIndicator: View {
  let current: Int
  let count: Int

  var body: some View {
    HStack(spacing: 6) {
      ForEach(0..<count, id: \.self) { index in
        Capsule()
          .fill(index == current ? Theme.accent : Color.primary.opacity(0.16))
          .frame(width: index == current ? 26 : 8, height: 8)
      }
    }
    .animation(Theme.Anim.step, value: current)
    .accessibilityElement()
    .accessibilityLabel(
      localized("Step \(current + 1) of \(count)", "Paso \(current + 1) de \(count)"))
  }
}

extension AutoHideDelay {
  var label: String {
    switch self {
    case .short: localized("2.5 s", "2,5 s")
    case .medium: "5 s"
    case .long: "10 s"
    case .veryLong: "30 s"
    case .never: localized("Never", "Nunca")
    }
  }

  var shortLabel: String { self == .never ? "∞" : label }
}
