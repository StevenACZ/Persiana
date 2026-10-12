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
      let thickness = 2.6 - 1.5 * open
      for index in 0..<4 {
        let center = 6 + CGFloat(index) * 3.15
        let inset = 0.6 * open
        NSBezierPath(
          roundedRect: NSRect(
            x: 2.5 + inset, y: center - thickness / 2, width: 13 - inset * 2, height: thickness),
          xRadius: thickness / 2, yRadius: thickness / 2
        ).fill()
      }
      return true
    }
    image.isTemplate = true
    image.accessibilityDescription = "Persiana"
    cache[step] = image
    return image
  }
}
