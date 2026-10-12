import AppKit

@MainActor
enum AppArtwork {
  static let icon: NSImage = {
    guard let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
      let source = NSImage(contentsOf: url)
    else {
      return NSWorkspace.shared.icon(forFile: Bundle.main.bundleURL.path)
    }
    return NSImage(size: NSSize(width: 256, height: 256), flipped: false) { rect in
      NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.225, yRadius: rect.height * 0.225)
        .addClip()
      source.draw(in: rect)
      return true
    }
  }()
}
