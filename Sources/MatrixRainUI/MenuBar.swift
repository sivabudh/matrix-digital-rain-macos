import AppKit
import RainCore

@MainActor
final class MenuBar: NSObject {
    private let status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let modeItem = NSMenuItem(title: "Unlock", action: nil, keyEquivalent: "")
    private let visibilityItem = NSMenuItem(title: "Hide Overlay", action: nil, keyEquivalent: "")
    private var speedItems: [NSMenuItem] = []
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
        let speedMenu = NSMenu(title: "Speed")
        for speed in RainSpeed.allCases {
            let item = NSMenuItem(title: speed.label, action: #selector(changeSpeed(_:)), keyEquivalent: "")
            item.target = self
            item.tag = speed.rawValue
            speedMenu.addItem(item)
            speedItems.append(item)
        }
        let speedItem = NSMenuItem(title: "Speed", action: nil, keyEquivalent: "")
        speedItem.submenu = speedMenu
        menu.addItem(speedItem)
        menu.addItem(.separator())
        let quit = menu.addItem(withTitle: "Quit Matrix Rain", action: #selector(quit), keyEquivalent: "")
        quit.target = self
        status.menu = menu
    }
    func apply(_ state: OverlayState) {
        for item in speedItems { item.state = item.tag == state.speed.rawValue ? .on : .off }
        mode = state.mode
        modeItem.title = state.mode.actionLabel
        visibilityItem.title = state.visibilityLabel
    }
    func remove() { NSStatusBar.system.removeStatusItem(status) }
    @objc private func changeMode() { onEvent?(mode.isLocked ? .unlock : .lock) }
    @objc private func changeVisibility() { onEvent?(.toggleVisibility) }
    @objc private func changeSpeed(_ sender: NSMenuItem) {
        guard let speed = RainSpeed(rawValue: sender.tag) else { return }
        onEvent?(.speedChanged(speed))
    }
    @objc private func quit() { onQuit?() }
}
