import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: OverlayController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = OverlayController(store: PlacementStore(defaults: .standard),
            statusWriter: .applicationDefault, seed: UInt64.random(in: .min ... .max))
        self.controller = controller
        controller.start()
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        controller?.send(.unlock)
        return false
    }
    func applicationWillTerminate(_ notification: Notification) { controller?.stop() }
}

@MainActor
public enum MatrixRainApplication {
    public static func run() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let identifier = Bundle.main.bundleIdentifier ?? "local.pac.matrix-rain"
        if NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
            .contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            exit(0)
        }
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}
