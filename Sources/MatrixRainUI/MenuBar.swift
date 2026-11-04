import AppKit
import RainCore

@MainActor
final class MenuBar: NSObject {
    private let status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let modeItem = NSMenuItem(title: "Unlock", action: nil, keyEquivalent: "")
    private let visibilityItem = NSMenuItem(title: "Hide Overlay", action: nil, keyEquivalent: "")
    private var mode = OverlayMode.locked
    var onEvent: ((OverlayEvent) -> Void)?
    var onQuit: (() -> Void)?
    var items: [NSMenuItem] { status.menu?.items ?? [] }

    override init() {
        super.init()
        status.button?.image = NSImage(systemSymbolName: "terminal", accessibilityDescription: "Matrix Rain")
        status.button?.toolTip = "Matrix Rain — desktop overlay"
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "MATRIX RAIN", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        modeItem.target = self
        modeItem.action = #selector(changeMode)
        menu.addItem(modeItem)
        visibilityItem.target = self
        visibilityItem.action = #selector(changeVisibility)
        menu.addItem(visibilityItem)
        menu.addItem(.separator())
        let quit = menu.addItem(withTitle: "Quit Matrix Rain", action: #selector(quit), keyEquivalent: "")
        quit.target = self
        status.menu = menu
    }
    func apply(_ state: OverlayState) {
        mode = state.mode
        modeItem.title = state.mode.actionLabel
        visibilityItem.title = state.visibilityLabel
    }
    func remove() { NSStatusBar.system.removeStatusItem(status) }
    @objc private func changeMode() { onEvent?(mode.isLocked ? .unlock : .lock) }
    @objc private func changeVisibility() { onEvent?(.toggleVisibility) }
    @objc private func quit() { onQuit?() }
}
