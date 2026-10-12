import AppKit
import SwiftUI

enum Theme {
  static let accent = Color(red: 0x5A / 255, green: 0x4C / 255, blue: 0xE6 / 255)
  static let accentDeep = Color(red: 0x3B / 255, green: 0x3B / 255, blue: 0xBF / 255)
  static let sunlight = Color(red: 0xFF / 255, green: 0xC2 / 255, blue: 0x4D / 255)
  static let granted = Color(red: 0x34 / 255, green: 0xC7 / 255, blue: 0x59 / 255)
  static let warning = Color(red: 0xFF / 255, green: 0x98 / 255, blue: 0x00 / 255)
  static let accentText = Color(
    nsColor: NSColor(name: nil) { appearance in
      appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        ? NSColor(red: 0x9A / 255, green: 0x90 / 255, blue: 0xFF / 255, alpha: 1)
        : NSColor(red: 0x44 / 255, green: 0x36 / 255, blue: 0xC9 / 255, alpha: 1)
    })

  enum Layout {
    static let panelWidth: CGFloat = 320
    static let padding: CGFloat = 16
    static let cardRadius: CGFloat = 12
    static let rowRadius: CGFloat = 8
    static let buttonHeight: CGFloat = 44
    static let cardFill = Color.primary.opacity(0.04)
    static let cardStroke = Color.primary.opacity(0.08)
  }

  enum Anim {
    static let content = Animation.spring(response: 0.28, dampingFraction: 0.86)
    static let hover = Animation.easeOut(duration: 0.2)
    static let morph = Animation.spring(duration: 0.35, bounce: 0.2)
    static let step = Animation.spring(response: 0.42, dampingFraction: 0.82)
  }
}

private struct CardChrome: ViewModifier {
  var tint: Color?

  func body(content: Content) -> some View {
    content.background(
      RoundedRectangle(cornerRadius: Theme.Layout.cardRadius, style: .continuous)
        .fill(tint.map { $0.opacity(0.1) } ?? Theme.Layout.cardFill)
        .overlay(
          RoundedRectangle(cornerRadius: Theme.Layout.cardRadius, style: .continuous)
            .strokeBorder(tint.map { $0.opacity(0.22) } ?? Theme.Layout.cardStroke, lineWidth: 1)))
  }
}

extension View {
  func card(tint: Color? = nil) -> some View {
    modifier(CardChrome(tint: tint))
  }

  func glassSurface<S: Shape>(_ shape: S, tint: Color? = nil, interactive: Bool = false)
    -> some View
  {
    glassEffect(Glass.regular.tint(tint).interactive(interactive), in: shape)
  }
}

struct SettingsCard<Content: View>: View {
  let icon: String
  let title: String
  @ViewBuilder let content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        Image(systemName: icon)
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(Theme.accentText)
          .frame(width: 18, alignment: .leading)
        Text(title)
          .font(.system(size: 13, weight: .semibold))
      }
      content()
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .card()
  }
}

struct ActionRow: View {
  let icon: String
  let title: String
  var subtitle: String?
  var isDestructive = false
  let action: () -> Void

  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        Image(systemName: icon)
          .frame(width: 20)
        VStack(alignment: .leading, spacing: 1) {
          Text(title)
          if let subtitle {
            Text(subtitle)
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
        }
        Spacer(minLength: 0)
        if !isDestructive {
          Image(systemName: "chevron.right")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.tertiary)
        }
      }
      .font(.callout)
      .foregroundStyle(isDestructive ? Color.red : Color.primary)
      .padding(.horizontal, 10)
      .padding(.vertical, 7)
      .background(
        RoundedRectangle(cornerRadius: Theme.Layout.rowRadius, style: .continuous)
          .fill(Color.primary.opacity(isHovered ? 0.07 : 0))
      )
      .contentShape(RoundedRectangle(cornerRadius: Theme.Layout.rowRadius, style: .continuous))
    }
    .buttonStyle(.plain)
    .onHover { hovering in
      withAnimation(Theme.Anim.hover) { isHovered = hovering }
    }
  }
}

struct PrimaryButton: View {
  let title: String
  let icon: String
  var tint: Color = Theme.accent
  var isEnabled = true
  let action: () -> Void

  @State private var presses = 0

  var body: some View {
    Button {
      presses += 1
      action()
    } label: {
      HStack(spacing: 10) {
        Image(systemName: icon)
          .font(.system(size: 17, weight: .semibold))
          .contentTransition(.symbolEffect(.replace.downUp))
          .symbolEffect(.bounce.down, options: .speed(1.3), value: presses)
        Text(title)
          .font(.headline)
          .contentTransition(.interpolate)
      }
      .frame(maxWidth: .infinity)
      .frame(height: Theme.Layout.buttonHeight)
      .foregroundStyle(.white)
      .contentShape(Capsule())
      .glassEffect(
        Glass.regular.tint(tint.opacity(isEnabled ? 0.92 : 0.4)).interactive(isEnabled),
        in: Capsule())
    }
    .buttonStyle(.plain)
    .disabled(!isEnabled)
  }
}

struct Banner: View {
  let icon: String
  let text: String
  var tint: Color = Theme.warning
  var actionTitle: String?
  var action: (() -> Void)?

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: icon)
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(tint)
      VStack(alignment: .leading, spacing: 6) {
        Text(text)
          .font(.caption)
          .foregroundStyle(.primary)
          .fixedSize(horizontal: false, vertical: true)
        if let actionTitle, let action {
          Button(actionTitle, action: action)
            .buttonStyle(.borderless)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
        }
      }
      Spacer(minLength: 0)
    }
    .padding(10)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(tint.opacity(0.1)))
  }
}

struct SettingSwitchToggleStyle: ToggleStyle {
  func makeBody(configuration: Configuration) -> some View {
    OutlinedSwitch(configuration: configuration)
  }

  private struct OutlinedSwitch: View {
    @Environment(\.colorScheme) private var colorScheme
    let configuration: Configuration

    var body: some View {
      HStack(spacing: 12) {
        configuration.label
        Spacer(minLength: 0)
        Toggle(configuration).toggleStyle(.switch).labelsHidden()
          .overlay(
            Capsule().strokeBorder(
              Color.primary.opacity(colorScheme == .dark ? 0.22 : 0.45), lineWidth: 1
            )
            .opacity(configuration.isOn ? 0 : 1)
            .allowsHitTesting(false))
      }
    }
  }
}

extension ToggleStyle where Self == SettingSwitchToggleStyle {
  static var settingSwitch: SettingSwitchToggleStyle { SettingSwitchToggleStyle() }
}
