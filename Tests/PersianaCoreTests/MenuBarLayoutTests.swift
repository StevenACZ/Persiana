import CoreGraphics
import Testing

@testable import PersianaCore

struct MenuBarLayoutTests {
  private let boundary = CGRect(x: 500, y: 0, width: 28, height: 24)

  private func item(_ bundle: String?, x: CGFloat, width: CGFloat = 24) -> StatusItemSnapshot {
    StatusItemSnapshot(
      bundleIdentifier: bundle, frame: CGRect(x: x, y: 0, width: width, height: 24))
  }

  @Test func appsLeftOfTheBoundaryAreHidden() {
    let sides = MenuBarLayout.sides(
      of: [item("left.app", x: 400), item("right.app", x: 600)], boundary: boundary,
      ownBundle: "own.app")
    #expect(sides == ["left.app": .hidden, "right.app": .visible])
  }

  @Test func anyVisibleIconKeepsTheWholeAppVisible() {
    let sides = MenuBarLayout.sides(
      of: [item("multi.app", x: 300), item("multi.app", x: 650), item("multi.app", x: 200)],
      boundary: boundary, ownBundle: nil)
    #expect(sides == ["multi.app": .visible])
  }

  @Test func systemOwnersOwnAppAndUnknownOwnersAreIgnored() {
    let sides = MenuBarLayout.sides(
      of: [
        item("com.apple.MenuBarAgent", x: 100), item("com.apple.controlcenter", x: 700),
        item("own.app", x: 100), item(nil, x: 100),
      ], boundary: boundary, ownBundle: "own.app")
    #expect(sides.isEmpty)
  }

  @Test func rightToLeftMenuBarsMirrorTheSides() {
    let sides = MenuBarLayout.sides(
      of: [item("left.app", x: 400), item("right.app", x: 600)], boundary: boundary,
      ownBundle: nil, isLeftToRight: false)
    #expect(sides == ["left.app": .visible, "right.app": .hidden])
  }

  @Test func framesOnDifferentDisplaysCompareFromTheirOwnEdge() {
    let screens = [
      CGRect(x: 0, y: 0, width: 1440, height: 900),
      CGRect(x: 1440, y: 0, width: 2560, height: 1440),
    ]
    let own = MenuBarLayout.anchored(
      CGRect(x: 1190, y: 876, width: 28, height: 24), screens: screens)
    let other = MenuBarLayout.anchored(
      CGRect(x: 3700, y: 1416, width: 24, height: 24), screens: screens)
    let sides = MenuBarLayout.sides(
      of: [StatusItemSnapshot(bundleIdentifier: "other.app", frame: other)], boundary: own,
      ownBundle: nil)
    #expect(sides == ["other.app": .hidden])
  }

  @Test func rememberedAppsSurviveWhenTheyAreNotRunning() {
    let visible = MenuBarLayout.visibleApps(
      remembered: ["quit.app", "moved.app"],
      updatedWith: ["moved.app": .hidden, "new.app": .visible])
    #expect(visible == ["quit.app", "new.app"])
  }

  @Test func allowListPutsTheOwnAppFirstOnce() {
    let allowed = MenuBarLayout.allowList(
      ownBundle: "own.app", visibleApps: ["b.app", "own.app", "a.app"])
    #expect(allowed == ["own.app", "a.app", "b.app"])
  }
}

struct AutoHideCountdownTests {
  @Test func countsDownOnlyWhileNotHolding() {
    var countdown = AutoHideCountdown(delay: 5)
    countdown.advance(by: 2, holding: false)
    #expect(countdown.remaining == 3)
    countdown.advance(by: 1, holding: true)
    #expect(countdown.remaining == 5)
    countdown.advance(by: 6, holding: false)
    #expect(countdown.isFinished)
    #expect(countdown.progress == 1)
  }

  @Test func neverHasNoSeconds() {
    #expect(AutoHideDelay.never.seconds == nil)
    #expect(AutoHideDelay.short.seconds == 2.5)
  }
}
