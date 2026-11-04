import AppKit
import OSLog
import RainCore

/// This is the only boundary that knows the legacy preference format.
struct PlacementStore {
    let defaults: UserDefaults
    private let key = "overlayContentRect"
    func load(screens: [CGRect]) -> OverlayFrame {
        let saved = defaults.string(forKey: key).flatMap { OverlayFrame(NSRectFromString($0)) }
        return OverlayLayout.restore(saved, screens: screens)
    }
    func save(_ frame: OverlayFrame) { defaults.set(NSStringFromRect(frame.rect), forKey: key) }
    func flush() { defaults.synchronize() }
}

struct StatusWriter {
    let directory: URL
    private let logger = Logger(subsystem: "local.pac.matrix-rain", category: "Diagnostics")

    static var applicationDefault: Self {
        Self(directory: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Matrix Rain"))
    }

    @MainActor
    func write(state: OverlayState, surface: OverlaySurface) {
        let rect = surface.contentFrame.rect
        let snapshot: [String: Any] = [
            "pid": ProcessInfo.processInfo.processIdentifier,
            "editing": !state.mode.isLocked, "clickThrough": surface.window.ignoresMouseEvents,
            "visible": state.isVisible, "animationActive": state.animationActive,
            "unlockButtonVisible": surface.unlockPanel.isVisible, "lockButtonVisible": state.showsLock,
            "windowLevel": surface.window.level.rawValue,
            "iconLevel": CGWindowLevelForKey(.desktopIconWindow),
            "wallpaperLevel": CGWindowLevelForKey(.desktopWindow),
            "frame": ["x": rect.minX, "y": rect.minY, "width": rect.width, "height": rect.height]
        ]
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONSerialization.data(withJSONObject: snapshot, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: directory.appendingPathComponent("status.json"), options: .atomic)
        } catch {
            // Diagnostic failure is not a state transition and must not stop the rain.
            logger.error("Could not save local diagnostic snapshot: \(error.localizedDescription, privacy: .public)")
        }
    }
}
