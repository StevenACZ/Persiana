import AppKit

@MainActor
enum PersianaGlyph {
  private static var cache: [Int: NSImage] = [:]

  static func image(openness: CGFloat) -> NSImage {
    let step = Int((max(0, min(1, openness)) * 20).rounded())
    if let cached = cache[step] { return cached }
    let open = CGFloat(step) / 20
    let image = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { _ in
      NSColor.black.setFill()
      NSBezierPath(roundedRect: NSRect(x: 2, y: 1.5, width: 14, height: 2), xRadius: 1, yRadius: 1)
        .fill()
      let thickness = mix(2, 1.1, open)
      let radius = mix(0.6, thickness / 2, open)
      for index in 0..<4 {
        let center = 6 + CGFloat(index) * mix(3, 3.15, open)
        NSBezierPath(
          roundedRect: NSRect(
            x: mix(2, 3.1, open), y: center - thickness / 2, width: mix(14, 11.8, open),
            height: thickness),
          xRadius: radius, yRadius: radius
        ).fill()
      }
      if open < 1 {
        NSBezierPath(
          roundedRect: NSRect(x: 7.5, y: 16, width: 3, height: 1.5 * (1 - open)),
          xRadius: 0.5, yRadius: 0.5
        ).fill()
      }
      return true
    }
    image.isTemplate = true
    image.accessibilityDescription = "Persiana"
    cache[step] = image
    return image
  }

  private static func mix(_ closed: CGFloat, _ opened: CGFloat, _ open: CGFloat) -> CGFloat {
    closed + (opened - closed) * open
  }
}
