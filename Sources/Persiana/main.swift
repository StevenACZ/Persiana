import AppKit
import MenuBarVisibility

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var toggleItem: NSStatusItem!
    private var testItem: NSStatusItem?
    private var assertion: AnyObject?
    private var signalSource: DispatchSourceSignal?

    private var keptBundleIdentifiers: [String] {
        let arguments = CommandLine.arguments
        guard let index = arguments.firstIndex(of: "--keep"), index + 1 < arguments.count else { return [] }
        return arguments[index + 1].split(separator: ",").map(String.init)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        toggleItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        toggleItem.autosaveName = "persiana.toggle"
        toggleItem.button?.target = self
        toggleItem.button?.action = #selector(toggle)

        if CommandLine.arguments.contains("--test-item") {
            testItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            testItem?.button?.title = "TEST"
        }

        signal(SIGUSR1, SIG_IGN)
        let source = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
        source.setEventHandler { [weak self] in self?.toggle() }
        source.resume()
        signalSource = source

        print("available:", MBVIsAvailable(), "bundle:", Bundle.main.bundleIdentifier ?? "none")
        render()
    }

    @objc private func toggle() {
        if let assertion {
            MBVInvalidate(assertion)
            self.assertion = nil
            print("expanded")
            render()
            return
        }
        let allowedApps = [Bundle.main.bundleIdentifier].compactMap { $0 } + keptBundleIdentifiers
        let systemItems = (0..<64).map { NSNumber(value: $0) }
        MBVActivate(systemItems, allowedApps) { [weak self] assertion, error in
            guard let self else { return }
            if let error {
                print("collapse failed:", error.localizedDescription)
            } else {
                self.assertion = assertion as AnyObject?
                print("collapsed, allowed:", allowedApps)
            }
            self.render()
        }
    }

    private func render() {
        let symbol = assertion == nil ? "chevron.right" : "chevron.left"
        toggleItem.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Toggle hidden items")
    }
}

setvbuf(stdout, nil, _IOLBF, 0)
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
