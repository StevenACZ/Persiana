import Foundation

public enum AutoHideDelay: Double, CaseIterable, Sendable {
  case short = 2.5
  case medium = 5
  case long = 10
  case veryLong = 30
  case never = 0

  public var seconds: TimeInterval? { self == .never ? nil : rawValue }

  public static let standard = AutoHideDelay.short
}

public struct AutoHideCountdown: Equatable, Sendable {
  public let delay: TimeInterval
  public private(set) var remaining: TimeInterval

  public init(delay: TimeInterval) {
    self.delay = delay
    remaining = delay
  }

  public var progress: Double { delay > 0 ? max(0, min(1, 1 - remaining / delay)) : 1 }
  public var isFinished: Bool { remaining <= 0 }

  public mutating func advance(by elapsed: TimeInterval, holding: Bool) {
    if holding {
      remaining = delay
    } else {
      remaining = max(0, remaining - elapsed)
    }
  }
}
