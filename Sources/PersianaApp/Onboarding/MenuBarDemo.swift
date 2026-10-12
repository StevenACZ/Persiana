import SwiftUI

enum TutorialScene: Int, CaseIterable {
  case click
  case arrange
  case autoHide

  var cycle: Double {
    switch self {
    case .click: 5.6
    case .arrange: 8.0
    case .autoHide: 6.4
    }
  }
}

struct DemoFrame {
  var collapse: Double = 0
  var dragged: Double = 0
  var lift: Double = 0
  var cursor = CGPoint(x: 260, y: 140)
  var press: Double = 0
  var glyphPress: Double = 0
  var ripple: Double?
  var commandShown: Double = 0
  var commandPressed: Double = 0
  var countdown: Double?
  var countdownShown: Double = 0
  var fade: Double = 0
}

struct DemoLayout {
  static let size = CGSize(width: 520, height: 200)
  static let barHeight: CGFloat = 40
  static let slot: CGFloat = 40
  static let hiddenSymbols = ["music.note", "cloud", "bubble.left"]
  static let movableSymbol = "timer"

  struct Item: Identifiable {
    let id: String
    let center: CGFloat
    let width: CGFloat
  }

  let items: [Item]
  let glyphX: CGFloat
  let movableX: CGFloat

  init(collapse: Double, dragged: Double) {
    var right = Self.size.width - 14
    var items: [Item] = []
    func place(_ id: String, _ width: CGFloat) {
      items.append(Item(id: id, center: right - width / 2, width: width))
      right -= width
    }
    place("clock", 78)
    place("battery.75percent", Self.slot + 6)
    place("wifi", Self.slot)
    let movableWidth = Self.slot * (1 - dragged)
    place("gap.right", movableWidth)
    let rightGap = items.last!.center
    place("persiana", Self.slot + 4)
    let glyph = items.last!.center
    let hiddenWidth = Self.slot * (1 - collapse)
    place("gap.left", hiddenWidth * dragged)
    let leftGap = items.last!.center
    for symbol in Self.hiddenSymbols.reversed() { place(symbol, hiddenWidth) }
    self.items = items
    glyphX = glyph
    movableX = dragged < 0.5 ? rightGap : leftGap
  }

  func center(of id: String) -> CGFloat? { items.first { $0.id == id }?.center }
}

enum DemoScript {
  static let rest = CGPoint(x: 260, y: 140)
  static let barY: CGFloat = 22

  static func frame(_ scene: TutorialScene, at time: Double, reduceMotion: Bool) -> DemoFrame {
    let ease: (Double, Double, Double) -> Double = { t, a, b in
      reduceMotion ? (t >= (a + b) / 2 ? 1 : 0) : smooth(t, a, b)
    }
    switch scene {
    case .click: return click(time, ease)
    case .arrange: return arrange(time, ease)
    case .autoHide: return autoHide(time, ease)
    }
  }

  private static func click(_ t: Double, _ ease: (Double, Double, Double) -> Double) -> DemoFrame {
    var frame = DemoFrame()
    let glyph = CGPoint(x: DemoLayout(collapse: 0, dragged: 0).glyphX, y: barY)
    let aside = CGPoint(x: glyph.x - 80, y: 100)
    frame.collapse = ease(t, 1.05, 1.55) - ease(t, 3.15, 3.65)
    frame.cursor = path(
      t,
      [
        (0, rest), (0.95, glyph), (1.6, glyph), (2.3, aside), (2.6, aside), (3.05, glyph),
        (3.7, glyph), (4.7, rest),
      ],
      ease)
    frame.press = pulse(t, 1.0) + pulse(t, 3.1)
    frame.glyphPress = frame.press
    frame.ripple = ripple(t, [1.0, 3.1])
    return frame
  }

  private static func arrange(_ t: Double, _ ease: (Double, Double, Double) -> Double) -> DemoFrame
  {
    var frame = DemoFrame()
    let start = DemoLayout(collapse: 0, dragged: 0)
    let moved = DemoLayout(collapse: 0, dragged: 1)
    let movable = CGPoint(x: start.movableX, y: barY)
    let dropped = CGPoint(x: moved.movableX, y: barY)
    let glyph = CGPoint(x: moved.glyphX, y: barY)
    let reset = t >= 7.65
    frame.dragged = reset ? 0 : ease(t, 1.95, 2.45)
    frame.lift = ease(t, 1.15, 1.3) - ease(t, 2.7, 2.85)
    frame.commandShown = ease(t, 0.55, 0.85) - ease(t, 3.4, 3.7)
    frame.commandPressed = ease(t, 0.95, 1.08) - ease(t, 2.95, 3.08)
    frame.collapse = reset ? 0 : ease(t, 4.05, 4.55) - ease(t, 6.55, 7.05)
    frame.cursor = path(
      t,
      [
        (0, rest), (0.9, movable), (1.3, movable), (2.6, dropped), (2.9, dropped), (3.9, glyph),
        (4.1, glyph), (5.0, rest), (5.8, rest), (6.4, glyph), (7.1, glyph), (8.0, rest),
      ], ease)
    frame.glyphPress = pulse(t, 4.0) + pulse(t, 6.5)
    frame.press = frame.glyphPress + frame.lift * 0.6
    frame.ripple = ripple(t, [4.0, 6.5])
    frame.fade = bump(t, 7.35, 7.65, 7.95)
    return frame
  }

  private static func autoHide(_ t: Double, _ ease: (Double, Double, Double) -> Double) -> DemoFrame
  {
    var frame = DemoFrame()
    let glyph = CGPoint(x: DemoLayout(collapse: 0, dragged: 0).glyphX, y: barY)
    frame.cursor = path(
      t, [(0, glyph), (0.3, glyph), (1.1, rest), (4.9, rest), (5.6, glyph), (6.4, glyph)], ease)
    frame.countdown = t < 5.7 ? linear(t, 1.1, 3.4) : 0
    frame.countdownShown = ease(t, 0.9, 1.15) - ease(t, 3.4, 3.7)
    frame.collapse = ease(t, 3.4, 3.9) - ease(t, 5.75, 6.25)
    frame.press = pulse(t, 5.7)
    frame.glyphPress = frame.press
    frame.ripple = ripple(t, [5.7])
    return frame
  }

  static func smooth(_ t: Double, _ a: Double, _ b: Double) -> Double {
    guard b > a else { return t >= b ? 1 : 0 }
    let x = max(0, min(1, (t - a) / (b - a)))
    return x * x * x * (x * (x * 6 - 15) + 10)
  }

  private static func linear(_ t: Double, _ a: Double, _ b: Double) -> Double {
    max(0, min(1, (t - a) / (b - a)))
  }

  private static func pulse(_ t: Double, _ at: Double) -> Double {
    bump(t, at - 0.06, at, at + 0.16)
  }

  private static func bump(_ t: Double, _ a: Double, _ peak: Double, _ b: Double) -> Double {
    if t <= a || t >= b { return 0 }
    return t < peak ? smooth(t, a, peak) : 1 - smooth(t, peak, b)
  }

  private static func ripple(_ t: Double, _ clicks: [Double]) -> Double? {
    clicks.lazy.map { t - $0 }.first { $0 >= 0 && $0 < 0.45 }.map { $0 / 0.45 }
  }

  private static func path(
    _ t: Double, _ points: [(Double, CGPoint)], _ ease: (Double, Double, Double) -> Double
  ) -> CGPoint {
    guard let first = points.first else { return rest }
    var current = first.1
    for (previous, next) in zip(points, points.dropFirst()) where t > previous.0 {
      let p = ease(t, previous.0, next.0)
      current = CGPoint(
        x: previous.1.x + (next.1.x - previous.1.x) * p,
        y: previous.1.y + (next.1.y - previous.1.y) * p)
    }
    return current
  }
}

struct MenuBarDemo: View {
  private static let loops = 3.0

  let scene: TutorialScene
  let delayLabel: String
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var start = Date()
  @State private var isFinished = false

  var body: some View {
    TimelineView(.animation(minimumInterval: reduceMotion ? 0.4 : nil, paused: isFinished)) {
      context in
      let elapsed = isFinished ? 0 : context.date.timeIntervalSince(start)
      DemoCanvas(
        frame: DemoScript.frame(
          scene, at: elapsed.truncatingRemainder(dividingBy: scene.cycle),
          reduceMotion: reduceMotion),
        delayLabel: delayLabel)
    }
    .frame(width: DemoLayout.size.width, height: DemoLayout.size.height)
    .accessibilityElement()
    .accessibilityLabel(
      localized("Animated menu bar example", "Ejemplo animado de la barra de menús")
    )
    .overlay(alignment: .bottomTrailing) {
      if isFinished {
        Button {
          isFinished = false
          start = Date()
        } label: {
          Label(localized("Play again", "Ver de nuevo"), systemImage: "arrow.counterclockwise")
        }
        .buttonStyle(.glass)
        .controlSize(.small)
        .padding(12)
        .transition(.opacity)
      }
    }
    .task(id: start) {
      try? await Task.sleep(for: .seconds(scene.cycle * Self.loops))
      guard !Task.isCancelled else { return }
      withAnimation(Theme.Anim.content) { isFinished = true }
    }
  }
}

private struct DemoCanvas: View {
  let frame: DemoFrame
  let delayLabel: String

  var body: some View {
    let layout = DemoLayout(collapse: frame.collapse, dragged: frame.dragged)
    ZStack(alignment: .topLeading) {
      wallpaper
      menuBar(layout)
      if frame.commandShown > 0.01 { commandKey }
      cursor
    }
    .frame(width: DemoLayout.size.width, height: DemoLayout.size.height, alignment: .topLeading)
    .environment(\.colorScheme, .dark)
  }

  private var wallpaper: some View {
    ZStack {
      LinearGradient(
        colors: [Theme.accentDeep, Theme.accent, Color(red: 0.86, green: 0.45, blue: 0.55)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
      Circle()
        .fill(Theme.sunlight.opacity(0.45))
        .frame(width: 260, height: 260)
        .blur(radius: 70)
        .offset(x: 150, y: 90)
      Circle()
        .fill(Color.white.opacity(0.18))
        .frame(width: 200, height: 200)
        .blur(radius: 60)
        .offset(x: -170, y: -40)
    }
    .frame(width: DemoLayout.size.width, height: DemoLayout.size.height)
  }

  private func menuBar(_ layout: DemoLayout) -> some View {
    ZStack(alignment: .topLeading) {
      Rectangle()
        .fill(Color.white.opacity(0.16))
        .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1) }
        .frame(width: DemoLayout.size.width, height: DemoLayout.barHeight)
      HStack(spacing: 16) {
        Image(systemName: "apple.logo").font(.system(size: 17, weight: .medium))
        Text("Finder").font(.system(size: 15, weight: .bold))
      }
      .foregroundStyle(.white.opacity(0.92))
      .frame(height: DemoLayout.barHeight)
      .padding(.leading, 18)
      Group {
        ForEach(layout.items) { item in
          barItem(item, layout: layout)
        }
        if frame.lift < 0.5 || frame.dragged >= 1 {
          symbol(DemoLayout.movableSymbol)
            .opacity(movableOpacity)
            .scaleEffect(1 - 0.4 * (frame.dragged >= 1 ? frame.collapse : 0))
            .position(x: layout.movableX, y: DemoLayout.barHeight / 2)
        }
      }
      .opacity(1 - frame.fade)
      if frame.lift >= 0.5 && frame.dragged < 1 || frame.lift > 0.01 {
        symbol(DemoLayout.movableSymbol)
          .scaleEffect(1 + 0.18 * frame.lift)
          .shadow(color: .black.opacity(0.35 * frame.lift), radius: 6, y: 3)
          .position(
            x: frame.cursor.x + 2, y: DemoLayout.barHeight / 2 + 2 * frame.lift
          )
          .opacity(frame.lift)
      }
    }
  }

  private var movableOpacity: Double {
    let hidden = frame.dragged >= 1 ? frame.collapse : 0
    return (1 - frame.lift) * (1 - hidden)
  }

  @ViewBuilder
  private func barItem(_ item: DemoLayout.Item, layout: DemoLayout) -> some View {
    let y = DemoLayout.barHeight / 2
    switch item.id {
    case "gap.left", "gap.right":
      EmptyView()
    case "clock":
      Text("9:41").font(.system(size: 15, weight: .medium)).foregroundStyle(.white)
        .position(x: item.center, y: y)
    case "persiana":
      ZStack {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(Color.white.opacity(0.28 * frame.glyphPress))
          .frame(width: 40, height: 30)
        if let countdown = frame.countdown, frame.countdownShown > 0.01 {
          Circle()
            .trim(from: 0, to: countdown)
            .stroke(Theme.sunlight, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .frame(width: 34, height: 34)
            .opacity(frame.countdownShown)
        }
        Image(nsImage: PersianaGlyph.image(openness: 1 - max(frame.collapse, frame.countdown ?? 0)))
          .renderingMode(.template)
          .resizable()
          .frame(width: 24, height: 24)
          .foregroundStyle(.white)
      }
      .overlay(alignment: .bottom) {
        if frame.countdownShown > 0.01 {
          Text(delayLabel)
            .font(.system(size: 13, weight: .semibold).monospacedDigit())
            .foregroundStyle(Theme.sunlight)
            .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
            .fixedSize()
            .offset(y: 30)
            .opacity(frame.countdownShown)
        }
      }
      .position(x: item.center, y: y)
    default:
      let hidden = DemoLayout.hiddenSymbols.contains(item.id)
      let amount = hidden ? frame.collapse : 0
      symbol(item.id)
        .opacity(1 - amount)
        .scaleEffect(1 - 0.4 * amount)
        .position(x: item.center, y: y)
    }
  }

  private func symbol(_ name: String) -> some View {
    Image(systemName: name)
      .font(.system(size: 19, weight: .medium))
      .foregroundStyle(.white)
      .frame(width: 34, height: 30)
  }

  private var commandKey: some View {
    HStack(spacing: 10) {
      Text("⌘")
        .font(.system(size: 26, weight: .semibold))
        .foregroundStyle(.white)
        .frame(width: 54, height: 54)
        .background(
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.white.opacity(0.16))
            .overlay(
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.sunlight.opacity(0.85 * frame.commandPressed))
            )
            .overlay(
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.45), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
        )
        .scaleEffect(1 - 0.08 * frame.commandPressed)
      Text(localized("hold", "mantén"))
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(.white.opacity(0.9))
    }
    .opacity(frame.commandShown)
    .position(x: 150, y: 128)
  }

  private var cursor: some View {
    ZStack(alignment: .topLeading) {
      if let ripple = frame.ripple {
        Circle()
          .stroke(Color.white.opacity(0.75 * (1 - ripple)), lineWidth: 2)
          .frame(width: 10 + 36 * ripple, height: 10 + 36 * ripple)
          .offset(x: -(5 + 18 * ripple), y: -(5 + 18 * ripple))
      }
      CursorShape()
        .fill(Color.black)
        .overlay(
          CursorShape().stroke(Color.white, style: StrokeStyle(lineWidth: 1.3, lineJoin: .round))
        )
        .frame(width: 15, height: 22)
        .scaleEffect(1 - 0.12 * frame.press, anchor: .topLeading)
        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
    }
    .offset(x: frame.cursor.x, y: frame.cursor.y)
  }
}

private struct CursorShape: Shape {
  func path(in rect: CGRect) -> Path {
    let sx = rect.width / 12
    let sy = rect.height / 18
    var path = Path()
    path.move(to: CGPoint(x: 0, y: 0))
    path.addLine(to: CGPoint(x: 0, y: 16 * sy))
    path.addLine(to: CGPoint(x: 4 * sx, y: 12.4 * sy))
    path.addLine(to: CGPoint(x: 6.6 * sx, y: 17.8 * sy))
    path.addLine(to: CGPoint(x: 9 * sx, y: 16.8 * sy))
    path.addLine(to: CGPoint(x: 6.5 * sx, y: 11.6 * sy))
    path.addLine(to: CGPoint(x: 11.6 * sx, y: 11.6 * sy))
    path.closeSubpath()
    return path
  }
}
