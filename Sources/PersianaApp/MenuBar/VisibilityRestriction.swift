import Foundation
import MenuBarVisibility

@MainActor
final class VisibilityRestriction {
  static let keptSystemItems = (0..<64).map { NSNumber(value: $0) }

  private var assertion: AnyObject?
  private var generation = 0

  var isAvailable: Bool { MBVIsAvailable() }
  var isActive: Bool { assertion != nil }

  func activate(allowing bundles: [String], completion: @escaping @MainActor (Bool) -> Void) {
    generation += 1
    let expected = generation
    MBVActivate(Self.keptSystemItems, bundles) { [weak self] newAssertion, error in
      MainActor.assumeIsolated {
        guard let self, expected == self.generation else {
          if let newAssertion { MBVInvalidate(newAssertion) }
          return
        }
        guard let newAssertion, error == nil else {
          NSLog("Persiana: hiding failed: \(error?.localizedDescription ?? "unknown error")")
          self.release()
          completion(false)
          return
        }
        let previous = self.assertion
        self.assertion = newAssertion as AnyObject
        if let previous { MBVInvalidate(previous) }
        completion(true)
      }
    }
  }

  func release() {
    generation += 1
    if let assertion { MBVInvalidate(assertion) }
    assertion = nil
  }
}
