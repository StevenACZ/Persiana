import Foundation

enum AppLanguage: String, CaseIterable {
  case system
  case spanish = "es"
  case english = "en"

  static var defaults: UserDefaults {
    ProcessInfo.processInfo.environment["PERSIANA_DEFAULTS_SUITE"]
      .flatMap(UserDefaults.init(suiteName:)) ?? .standard
  }

  static var current: AppLanguage {
    AppLanguage(rawValue: defaults.string(forKey: "language") ?? "") ?? .system
  }

  var label: String {
    switch self {
    case .system: localized("System", "Sistema")
    case .spanish: "Español"
    case .english: "English"
    }
  }

  static var usesSpanish: Bool {
    let selection = current
    return selection == .spanish
      || (selection == .system && Locale.preferredLanguages.first?.hasPrefix("es") == true)
  }
}

func localized(_ english: String, _ spanish: String) -> String {
  AppLanguage.usesSpanish ? spanish : english
}
