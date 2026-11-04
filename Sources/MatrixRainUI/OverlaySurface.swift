import AppKit
import RainCore

final class RainWindow: NSWindow {
    var mode: OverlayMode = .locked
    override var canBecomeKey: Bool { !mode.isLocked }
    override var canBecomeMain: Bool { !mode.isLocked }
    override func zoom(_ sender: Any?) {}
    override func toggleFullScreen(_ sender: Any?) {}
}

final class FirstClickButton: NSButton {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

@MainActor
final class OverlaySurface: NSObject {
    let window: RainWindow
    let rain: RainView
    let unlockPanel: NSPanel
    let unlockButton: NSButton
    let lockButton: NSButton
    var onEvent: ((OverlayEvent) -> Void)?
    static let desktopLevel = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) - 1)
    private static let desktopBehavior: NSWindow.CollectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]

    init(frame: OverlayFrame, seed: UInt64) {
        window = RainWindow(contentRect: frame.rect, styleMask: .borderless, backing: .buffered, defer: false)
        rain = RainView(size: frame.rect.size, seed: seed)
        unlockPanel = NSPanel(contentRect: OverlayLayout.controlRect(in: frame),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        unlockButton = FirstClickButton(title: "Unlock", target: nil, action: nil)
        lockButton = FirstClickButton(title: "Lock", target: nil, action: nil)
        super.init()

        window.title = "Matrix Rain"
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.isOpaque = false
        window.contentMinSize = OverlayLayout.minimumSize
        window.collectionBehavior = Self.desktopBehavior
        window.contentView = rain
        rain.onRightClick = { [weak self] in self?.onEvent?(.rightClick) }

        unlockPanel.title = "Unlock Matrix Rain"
        unlockPanel.isReleasedWhenClosed = false
        unlockPanel.isOpaque = false
        unlockPanel.backgroundColor = .clear
        unlockPanel.hasShadow = true
        unlockPanel.hidesOnDeactivate = false
        unlockPanel.isFloatingPanel = false
        unlockPanel.becomesKeyOnlyIfNeeded = true
        unlockPanel.collectionBehavior = Self.desktopBehavior
        // Finder can cover the rain's event surface. Only the small Unlock control
        // sits above that layer; the animation remains below desktop icons.
        unlockPanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        unlockButton.bezelStyle = .rounded
        unlockButton.frame = CGRect(origin: .zero, size: OverlayLayout.controlSize)
        unlockButton.autoresizingMask = [.width, .height]
        unlockButton.target = self
        unlockButton.action = #selector(unlock)
        unlockPanel.contentView = unlockButton

        lockButton.bezelStyle = .rounded
        lockButton.target = self
        lockButton.action = #selector(lock)
        lockButton.isHidden = true
        rain.addSubview(lockButton)

    }

    var contentFrame: OverlayFrame { OverlayFrame(window.convertToScreen(rain.bounds))! }

    func setContentFrame(_ frame: OverlayFrame) {
        window.setFrame(window.frameRect(forContentRect: frame.rect), display: true)
    }

    func apply(_ state: OverlayState, previous: OverlayState?) {
        window.mode = state.mode
        if previous?.mode.isLocked != state.mode.isLocked {
            let frame = contentFrame
            window.ignoresMouseEvents = state.mode.isLocked
            window.styleMask = state.mode.isLocked ? .borderless : [.borderless, .resizable]
            window.isMovableByWindowBackground = !state.mode.isLocked
            setContentFrame(frame)
            window.level = state.mode.isLocked ? Self.desktopLevel : .floating
            window.hasShadow = !state.mode.isLocked
        }
        if previous?.isVisible != state.isVisible || previous?.mode.isLocked != state.mode.isLocked {
            if !state.isVisible {
                window.orderOut(nil)
            } else if state.mode.isLocked {
                window.orderFrontRegardless()
            } else {
                NSApp.activate(ignoringOtherApps: true)
                window.makeKeyAndOrderFront(nil)
            }
        }
        rain.setAnimating(state.animationActive)
        refreshControls(for: state)
    }

    func refreshControls(for state: OverlayState) {
        // Both controls use the same screen rectangle. Explicit conversion avoids
        // NSButton's alignment-rectangle insets shifting Auto Layout's frame.
        let rect = OverlayLayout.controlRect(in: contentFrame)
        lockButton.frame = rain.convert(window.convertFromScreen(rect), from: nil)
        lockButton.isHidden = !state.showsLock
        if state.showsUnlock {
            if unlockPanel.frame != rect { unlockPanel.setFrame(rect, display: true) }
            if !unlockPanel.isVisible { unlockPanel.orderFrontRegardless() }
        } else if unlockPanel.isVisible {
            unlockPanel.orderOut(nil)
        }
    }

    func stop() {
        rain.setAnimating(false)
        unlockPanel.orderOut(nil)
        window.orderOut(nil)
    }
    @objc private func unlock() { onEvent?(.unlock) }
    @objc private func lock() { onEvent?(.lock) }
}
